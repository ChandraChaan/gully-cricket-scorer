import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../domain/vec3.dart';
import 'scene3d.dart';

/// Colours shared by the 3D games.
abstract final class GameColors {
  static const skin = Color(0xFFB98058);
  static const hair = Color(0xFF2B2320);
  static const whites = Color(0xFFF3F0E6);
  static const willow = Color(0xFFE2C48A);
  static const batHandle = Color(0xFF3F51B5);
  static const stump = Color(0xFFEFD27A);
  static const leather = Color(0xFFC62828);
  static const shadow = Color(0x55000000);
  static const chalk = Color(0xFFF5F5F0);
  static const dust = Color(0xFFBCA789);
  static const pitch = Color(0xFFDCCBA4);
  static const grass = Color(0xFF5E9E50);
  static const grassDark = Color(0xFF55934A);
  static const skyTop = Color(0xFF4FA3E3);
  static const skyLow = Color(0xFFCDE8F7);
}

/// Layers, back to front. See [Scene3].
abstract final class Layers {
  static const ground = 0;
  static const paint = 1;
  static const tint = 2;
  static const marks = 3;
  static const shadows = 4;
  static const things = 5;
}

/// The vertical field of view that shows [halfWidth] metres either side of
/// something [distance] metres away, whatever shape the screen is. Tall
/// phones get a taller view rather than a narrower one.
double fovToFit(Size viewport, double halfWidth, double distance) {
  final tanHalf = halfWidth / distance / viewport.aspectRatio;
  return (2 * math.atan(tanHalf)).clamp(0.7, 1.5);
}

/// Fills the canvas with sky above the horizon and [ground] below it.
void paintBackdrop(ui.Canvas canvas, Camera3 camera, Color ground) {
  final size = camera.viewport;
  final horizon =
      (camera.project(camera.position.withY(0) + const Vec3(0, 0, 4000))?.dy ??
              size.height / 2)
          .clamp(0.0, size.height);
  final sky = Rect.fromLTWH(0, 0, size.width, horizon);
  canvas
    ..drawRect(
      sky,
      ui.Paint()
        ..shader = ui.Gradient.linear(sky.topCenter, sky.bottomCenter, const [
          GameColors.skyTop,
          GameColors.skyLow,
        ]),
    )
    ..drawRect(
      Rect.fromLTRB(0, horizon, size.width, size.height),
      ui.Paint()..color = ground,
    );
}

/// A blocky player standing at [feet].
///
/// [yaw] is the way they face, 0 being away from the camera. [stride] swings
/// the legs from -1 to 1. Hands and feet can be placed by hand, in the
/// figure's own space: x to its right, y up, z in front. [lean] tips the
/// shoulders forward (or back, if negative) and [crouch] drops the hips.
/// Returns where the hands ended up in the world, for bats and balls.
({Vec3 left, Vec3 right}) addFigure(
  Scene3 scene, {
  required Vec3 feet,
  required Color shirt,
  double yaw = 0,
  double stride = 0,
  double lean = 0,
  double crouch = 0,
  Color trousers = GameColors.whites,
  Vec3 leftHand = const Vec3(-0.3, 0.82, 0.06),
  Vec3 rightHand = const Vec3(0.3, 0.82, 0.06),
  Vec3? leftFoot,
  Vec3? rightFoot,
}) {
  final front = Vec3(math.sin(yaw), 0, math.cos(yaw));
  final side = Vec3(math.cos(yaw), 0, -math.sin(yaw));
  Vec3 at(double x, double y, double z) =>
      feet + side * x + Vec3(0, y, 0) + front * z;
  final hips = 0.85 - crouch;

  scene.disc(feet.withY(0.01), 0.38, GameColors.shadow, segments: 10);
  for (final leg in const [-1.0, 1.0]) {
    final swing = stride * leg;
    final placed = leg < 0 ? leftFoot : rightFoot;
    scene.beam(
      at(0.1 * leg, hips, 0),
      placed == null
          ? at(0.1 * leg, math.max(0.0, swing) * 0.14, 0.34 * swing)
          : at(placed.x, placed.y, placed.z),
      0.075,
      0.075,
      trousers,
      side: side,
    );
  }
  scene.beam(
    at(0, hips - 0.03, 0),
    at(0, hips + 0.57, lean),
    0.2,
    0.11,
    shirt,
    side: side,
  );
  final left = at(leftHand.x, leftHand.y - crouch, leftHand.z + lean);
  final right = at(rightHand.x, rightHand.y - crouch, rightHand.z + lean);
  scene
    ..beam(
      at(-0.25, hips + 0.51, lean),
      left,
      0.055,
      0.055,
      GameColors.skin,
      side: side,
    )
    ..beam(
      at(0.25, hips + 0.51, lean),
      right,
      0.055,
      0.055,
      GameColors.skin,
      side: side,
    )
    ..ball(at(0, hips + 0.75, lean * 1.2), 0.14, GameColors.skin)
    ..ball(at(0, hips + 0.85, lean * 1.2 - 0.07), 0.11, GameColors.hair);
  return (left: left, right: right);
}

/// A player flat on the ground at [middle], head towards [yaw].
void addFallenFigure(
  Scene3 scene, {
  required Vec3 middle,
  required Color shirt,
  double yaw = 0,
  Color trousers = GameColors.whites,
}) {
  final front = Vec3(math.sin(yaw), 0, math.cos(yaw));
  final side = Vec3(math.cos(yaw), 0, -math.sin(yaw));
  Vec3 at(double x, double z) => middle.withY(0.14) + side * x + front * z;
  scene
    ..disc(middle.withY(0.01), 0.7, GameColors.shadow, segments: 10)
    ..beam(at(-0.1, -0.85), at(-0.1, -0.1), 0.075, 0.075, trousers, side: side)
    ..beam(at(0.1, -0.8), at(0.1, -0.1), 0.075, 0.075, trousers, side: side)
    ..beam(at(0, -0.1), at(0, 0.5), 0.2, 0.11, shirt, side: side)
    ..beam(at(-0.28, 0.45), at(-0.55, 0.1), 0.055, 0.055, GameColors.skin)
    ..beam(at(0.28, 0.45), at(0.55, 0.2), 0.055, 0.055, GameColors.skin)
    ..ball(at(0, 0.68), 0.14, GameColors.skin)
    ..ball(at(0, 0.78), 0.105, GameColors.hair);
}

/// A bat held at [hands] pointing along [direction].
void addBat(Scene3 scene, Vec3 hands, Vec3 direction, {Vec3? face}) {
  final along = direction.normalized;
  final side = face ?? const Vec3(1, 0, 0);
  scene
    ..beam(
      hands - along * 0.08,
      hands + along * 0.26,
      0.022,
      0.022,
      GameColors.batHandle,
      side: side,
    )
    ..beam(
      hands + along * 0.26,
      hands + along * 0.9,
      0.06,
      0.022,
      GameColors.willow,
      side: side,
    );
}

/// Three stumps and two bails at [base]. [broken] splays them.
void addStumps(Scene3 scene, Vec3 base, {bool broken = false}) {
  scene.disc(base.withY(0.01), 0.24, GameColors.shadow, segments: 10);
  for (var i = -1; i <= 1; i++) {
    final foot = base + Vec3(i * 0.11, 0, 0);
    final lean = broken ? Vec3(i * 0.34, -0.12, 0.3 + i * 0.1) : Vec3.zero;
    scene.beam(
      foot,
      foot + const Vec3(0, 0.72, 0) + lean,
      0.022,
      0.022,
      GameColors.stump,
    );
  }
  if (broken) return;
  for (final x in const [-0.055, 0.055]) {
    scene.beam(
      base + Vec3(x - 0.05, 0.735, 0),
      base + Vec3(x + 0.05, 0.735, 0),
      0.014,
      0.014,
      GameColors.stump,
      side: const Vec3(0, 0, 1),
    );
  }
}

/// A ball with its shadow on the ground. [radius] is how big to draw it,
/// which is a little larger than life so it can be followed on a phone.
void addBall(Scene3 scene, Vec3 ball, double radius) {
  scene
    ..disc(ball.withY(0.012), radius * 1.15, GameColors.shadow, segments: 8)
    ..ball(ball, radius, GameColors.leather);
}

const _houseColors = [
  Color(0xFFE9C46A),
  Color(0xFFE8A0A0),
  Color(0xFF8EC6C5),
  Color(0xFFF1E3C4),
  Color(0xFF9DB7E0),
  Color(0xFFD9A77A),
  Color(0xFFB8D8A0),
];

/// A narrow lane between painted houses, with a pitch chalked down the
/// middle. The batter's stumps are at z = 0 and the bowler's at [pitchEnd].
Scene3 buildGully({double pitchEnd = 16.6}) {
  final scene = Scene3();
  final random = math.Random(11);
  scene
    ..floor(-40, -14, 40, 70, GameColors.dust)
    ..floor(-1.4, -9, 1.4, pitchEnd + 2, GameColors.pitch, layer: Layers.paint)
    ..floor(-1.4, 1.2, 1.4, 1.27, GameColors.chalk, layer: Layers.marks)
    ..floor(
      -1.4,
      pitchEnd - 1.27,
      1.4,
      pitchEnd - 1.2,
      GameColors.chalk,
      layer: Layers.marks,
    );
  const street = 5.2;
  for (final side in const [-1.0, 1.0]) {
    var z = -5.0;
    while (z < 46) {
      final length = 5 + random.nextDouble() * 3;
      final height = 5 + random.nextDouble() * 5;
      final color = _houseColors[random.nextInt(_houseColors.length)];
      scene.beam(
        Vec3(side * (street + 4), 0, z + length / 2),
        Vec3(side * (street + 4), height, z + length / 2),
        4,
        length / 2 - 0.05,
        color,
        layer: Layers.marks,
      );
      // Door and windows on the wall that faces the lane.
      final wall = side * (street - 0.02);
      void panel(double from, double to, double low, double high, Color c) {
        scene.quad(
          Vec3(wall, low, z + from),
          Vec3(wall, high, z + from),
          Vec3(wall, high, z + to),
          Vec3(wall, low, z + to),
          c,
          normal: Vec3(-side, 0, 0),
          layer: Layers.shadows,
        );
      }

      final door = Color.lerp(color, const Color(0xFF3E2723), 0.7)!;
      const glass = Color(0xFF5D7C8C);
      panel(0.8, 1.9, 0, 2.1, door);
      panel(2.9, 4.1, 1.1, 2.2, glass);
      for (var low = 3.7; low + 1.6 < height; low += 2.8) {
        panel(0.9, 2.1, low, low + 1.2, glass);
        panel(2.9, 4.1, low, low + 1.2, glass);
      }
      z += length;
    }
  }
  // The wall at the end of the lane.
  scene.beam(
    const Vec3(0, 0, 50),
    const Vec3(0, 7, 50),
    street + 8,
    1,
    const Color(0xFFCDB89A),
    layer: Layers.marks,
  );
  return scene;
}

/// An open ground with mown stripes and trees along the far side.
Scene3 buildMaidan() {
  final scene = Scene3();
  final random = math.Random(5);
  scene.floor(-80, -30, 80, 110, GameColors.grass);
  for (var z = -28.0; z < 108; z += 8) {
    scene.floor(-80, z, 80, z + 4, GameColors.grassDark, layer: Layers.paint);
  }
  for (var x = -66.0; x <= 66; x += 6) {
    final tree = Vec3(
      x + random.nextDouble() * 3,
      0,
      62 + random.nextDouble() * 14,
    );
    final height = 3 + random.nextDouble() * 2;
    scene
      ..beam(
        tree,
        tree + Vec3(0, height, 0),
        0.3,
        0.3,
        const Color(0xFF6D4C41),
        layer: Layers.marks,
      )
      ..ball(
        tree + Vec3(0, height + 1.6, 0),
        2.6 + random.nextDouble(),
        Color.lerp(
          const Color(0xFF2E7D32),
          const Color(0xFF558B2F),
          random.nextDouble(),
        )!,
        layer: Layers.marks,
      );
  }
  return scene;
}
