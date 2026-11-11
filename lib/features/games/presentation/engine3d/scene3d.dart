import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../domain/vec3.dart';

/// A perspective camera looking from [position] towards a target.
final class Camera3 {
  Camera3({
    required this.position,
    required Vec3 target,
    required this.viewport,
    double fovY = 1.05,
  }) : forward = (target - position).normalized,
       focal = viewport.height / 2 / math.tan(fovY / 2) {
    right = Vec3.up.cross(forward).normalized;
    up = forward.cross(right);
  }

  /// Nothing nearer than this is drawn.
  static const near = 0.2;

  final Vec3 position;
  final Size viewport;
  final Vec3 forward;

  /// Pixels per metre at a depth of one metre.
  final double focal;

  late final Vec3 right;
  late final Vec3 up;

  /// [world] in camera space: x right, y up, z depth into the screen.
  Vec3 toCamera(Vec3 world) {
    final d = world - position;
    return Vec3(d.dot(right), d.dot(up), d.dot(forward));
  }

  Offset projectCamera(Vec3 point) => Offset(
    viewport.width / 2 + point.x / point.z * focal,
    viewport.height / 2 - point.y / point.z * focal,
  );

  /// Where [world] lands on screen, or null if it is behind the camera.
  Offset? project(Vec3 world) {
    final point = toCamera(world);
    return point.z < near ? null : projectCamera(point);
  }

  /// The spot on the ground (at height [y]) under a screen position, or null
  /// if that part of the screen shows sky.
  Vec3? groundPoint(Offset screen, {double y = 0}) {
    final ray =
        forward * focal +
        right * (screen.dx - viewport.width / 2) -
        up * (screen.dy - viewport.height / 2);
    if (ray.y > -1e-6) return null;
    final t = (y - position.y) / ray.y;
    return position + ray * t;
  }
}

/// A bag of triangles and balls to draw in 3D.
///
/// Shapes are added in world space and flat shaded by a fixed sun. Drawing
/// sorts everything back to front within a [layer]; lower layers are always
/// drawn first, which keeps the ground under shadows and shadows under
/// players without a depth buffer.
final class Scene3 {
  static final Vec3 _sun = const Vec3(-0.45, 0.8, -0.4).normalized;

  final List<_Triangle> _triangles = [];
  final List<_Ball> _balls = [];

  static int _shade(Color color, Vec3 normal) {
    final light = 0.58 + 0.42 * math.max(0.0, normal.dot(_sun));
    int channel(double value) => (value * light * 255).round().clamp(0, 255);
    return (color.a * 255).round() << 24 |
        channel(color.r) << 16 |
        channel(color.g) << 8 |
        channel(color.b);
  }

  /// A flat four-cornered face. Corners go round the edge in order.
  void quad(
    Vec3 a,
    Vec3 b,
    Vec3 c,
    Vec3 d,
    Color color, {
    Vec3? normal,
    int layer = 5,
  }) {
    final argb = _shade(color, normal ?? (b - a).cross(c - a).normalized);
    _triangles
      ..add(_Triangle(a, b, c, argb, layer))
      ..add(_Triangle(a, c, d, argb, layer));
  }

  /// A rectangle lying flat on the ground.
  void floor(
    double x0,
    double z0,
    double x1,
    double z1,
    Color color, {
    double y = 0,
    int layer = 0,
  }) {
    quad(
      Vec3(x0, y, z0),
      Vec3(x0, y, z1),
      Vec3(x1, y, z1),
      Vec3(x1, y, z0),
      color,
      normal: Vec3.up,
      layer: layer,
    );
  }

  /// A beam from [a] to [b], [halfWidth] by [halfDepth] thick. [side] says
  /// which way the width faces; it defaults to across the screen.
  void beam(
    Vec3 a,
    Vec3 b,
    double halfWidth,
    double halfDepth,
    Color color, {
    Vec3 side = const Vec3(1, 0, 0),
    int layer = 5,
  }) {
    final axis = (b - a).normalized;
    var u = side - axis * side.dot(axis);
    if (u.length < 1e-4) u = const Vec3(0, 0, 1) - axis * axis.z;
    u = u.normalized;
    final v = axis.cross(u);
    final du = u * halfWidth;
    final dv = v * halfDepth;
    final a0 = a - du - dv;
    final a1 = a + du - dv;
    final a2 = a + du + dv;
    final a3 = a - du + dv;
    final b0 = b - du - dv;
    final b1 = b + du - dv;
    final b2 = b + du + dv;
    final b3 = b - du + dv;
    quad(a0, a1, b1, b0, color, normal: -v, layer: layer);
    quad(a3, a2, b2, b3, color, normal: v, layer: layer);
    quad(a0, a3, b3, b0, color, normal: -u, layer: layer);
    quad(a1, a2, b2, b1, color, normal: u, layer: layer);
    quad(a0, a1, a2, a3, color, normal: -axis, layer: layer);
    quad(b0, b1, b2, b3, color, normal: axis, layer: layer);
  }

  /// An upright box standing on the ground at [base], the middle of its foot.
  void box(
    Vec3 base,
    double width,
    double height,
    double depth,
    Color color, {
    int layer = 5,
  }) {
    beam(
      base,
      base + Vec3(0, height, 0),
      width / 2,
      depth / 2,
      color,
      layer: layer,
    );
  }

  /// A flat disc on the ground, or a ring if [innerRadius] is set.
  void disc(
    Vec3 centre,
    double radius,
    Color color, {
    double innerRadius = 0,
    int segments = 18,
    int layer = 4,
  }) {
    final argb = _shade(color, Vec3.up);
    Vec3 rim(int i, double r) {
      final angle = i * 2 * math.pi / segments;
      return centre + Vec3(math.cos(angle) * r, 0, math.sin(angle) * r);
    }

    for (var i = 0; i < segments; i++) {
      final outerA = rim(i, radius);
      final outerB = rim(i + 1, radius);
      if (innerRadius <= 0) {
        _triangles.add(_Triangle(centre, outerA, outerB, argb, layer));
      } else {
        final innerA = rim(i, innerRadius);
        final innerB = rim(i + 1, innerRadius);
        _triangles
          ..add(_Triangle(innerA, outerA, outerB, argb, layer))
          ..add(_Triangle(innerA, outerB, innerB, argb, layer));
      }
    }
  }

  /// A ball, drawn as a shaded circle that always faces the camera.
  void ball(Vec3 centre, double radius, Color color, {int layer = 5}) {
    _balls.add(_Ball(centre, radius, color, layer));
  }

  /// Draws [scenes] together as seen by [camera].
  static void render(ui.Canvas canvas, Camera3 camera, List<Scene3> scenes) {
    final draws = <_Draw>[];
    for (final scene in scenes) {
      for (final triangle in scene._triangles) {
        _clip(triangle, camera, draws);
      }
      for (final ball in scene._balls) {
        final centre = camera.toCamera(ball.centre);
        if (centre.z < Camera3.near + ball.radius) continue;
        draws.add(
          _Draw.ball(
            ball.layer,
            centre.z,
            camera.projectCamera(centre),
            ball.radius * camera.focal / centre.z,
            ball.color,
          ),
        );
      }
    }
    draws.sort(
      (a, b) => a.layer != b.layer
          ? a.layer.compareTo(b.layer)
          : b.depth.compareTo(a.depth),
    );

    final positions = Float32List(draws.length * 6);
    final colors = Int32List(draws.length * 3);
    final paint = ui.Paint();
    var count = 0;

    void flush() {
      if (count == 0) return;
      final vertices = ui.Vertices.raw(
        ui.VertexMode.triangles,
        Float32List.sublistView(positions, 0, count * 6),
        colors: Int32List.sublistView(colors, 0, count * 3),
      );
      canvas.drawVertices(vertices, ui.BlendMode.dst, paint);
      vertices.dispose();
      count = 0;
    }

    for (final draw in draws) {
      final points = draw.points;
      if (points != null) {
        positions.setRange(count * 6, count * 6 + 6, points);
        colors.fillRange(count * 3, count * 3 + 3, draw.argb);
        count++;
      } else {
        flush();
        _paintBall(canvas, draw);
      }
    }
    flush();
  }

  /// Cuts a triangle off at the near plane and queues what is left.
  static void _clip(_Triangle triangle, Camera3 camera, List<_Draw> out) {
    final a = camera.toCamera(triangle.a);
    final b = camera.toCamera(triangle.b);
    final c = camera.toCamera(triangle.c);
    const near = Camera3.near;
    final inside = [a, b, c].where((p) => p.z >= near).length;
    if (inside == 0) return;
    final depth = (a.z + b.z + c.z) / 3;

    void emit(Vec3 p, Vec3 q, Vec3 r) {
      final sp = camera.projectCamera(p);
      final sq = camera.projectCamera(q);
      final sr = camera.projectCamera(r);
      out.add(
        _Draw.triangle(triangle.layer, depth, [
          sp.dx,
          sp.dy,
          sq.dx,
          sq.dy,
          sr.dx,
          sr.dy,
        ], triangle.argb),
      );
    }

    if (inside == 3) {
      emit(a, b, c);
      return;
    }
    Vec3 cut(Vec3 from, Vec3 to) =>
        from.lerp(to, (near - from.z) / (to.z - from.z));
    final ring = <Vec3>[];
    final corners = [a, b, c];
    for (var i = 0; i < 3; i++) {
      final current = corners[i];
      final next = corners[(i + 1) % 3];
      if (current.z >= near) ring.add(current);
      if ((current.z >= near) != (next.z >= near)) ring.add(cut(current, next));
    }
    for (var i = 1; i + 1 < ring.length; i++) {
      emit(ring[0], ring[i], ring[i + 1]);
    }
  }

  static void _paintBall(ui.Canvas canvas, _Draw draw) {
    final radius = math.max(1.0, draw.radius);
    final color = draw.color!;
    final paint = ui.Paint()
      ..isAntiAlias = true
      ..shader = ui.Gradient.radial(
        draw.centre + Offset(-radius * 0.35, -radius * 0.35),
        radius * 1.5,
        [
          Color.lerp(color, const Color(0xFFFFFFFF), 0.55)!,
          color,
          Color.lerp(color, const Color(0xFF000000), 0.45)!,
        ],
        const [0, 0.5, 1],
      );
    canvas.drawCircle(draw.centre, radius, paint);
  }
}

final class _Triangle {
  const _Triangle(this.a, this.b, this.c, this.argb, this.layer);

  final Vec3 a;
  final Vec3 b;
  final Vec3 c;
  final int argb;
  final int layer;
}

final class _Ball {
  const _Ball(this.centre, this.radius, this.color, this.layer);

  final Vec3 centre;
  final double radius;
  final Color color;
  final int layer;
}

/// One thing to paint, already projected to the screen.
final class _Draw {
  _Draw.triangle(this.layer, this.depth, List<double> this.points, this.argb)
    : centre = Offset.zero,
      radius = 0,
      color = null;

  _Draw.ball(this.layer, this.depth, this.centre, this.radius, Color this.color)
    : points = null,
      argb = 0;

  final int layer;
  final double depth;
  final List<double>? points;
  final int argb;
  final Offset centre;
  final double radius;
  final Color? color;
}
