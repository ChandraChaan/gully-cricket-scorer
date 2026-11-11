import 'dart:math' as math;

/// A point or direction in the game world, in metres.
///
/// x runs to the right, y is up and z runs away from the camera.
final class Vec3 {
  const Vec3(this.x, this.y, this.z);

  static const zero = Vec3(0, 0, 0);
  static const up = Vec3(0, 1, 0);

  final double x;
  final double y;
  final double z;

  Vec3 operator +(Vec3 other) => Vec3(x + other.x, y + other.y, z + other.z);

  Vec3 operator -(Vec3 other) => Vec3(x - other.x, y - other.y, z - other.z);

  Vec3 operator *(double scale) => Vec3(x * scale, y * scale, z * scale);

  Vec3 operator -() => Vec3(-x, -y, -z);

  double dot(Vec3 other) => x * other.x + y * other.y + z * other.z;

  Vec3 cross(Vec3 other) => Vec3(
    y * other.z - z * other.y,
    z * other.x - x * other.z,
    x * other.y - y * other.x,
  );

  double get length => math.sqrt(dot(this));

  /// This vector scaled to length 1, or [zero] if it has no length.
  Vec3 get normalized {
    final size = length;
    return size < 1e-9 ? zero : this * (1 / size);
  }

  double distanceTo(Vec3 other) => (this - other).length;

  /// Distance ignoring height, for "is the fielder under the ball" checks.
  double groundDistanceTo(Vec3 other) {
    final dx = x - other.x;
    final dz = z - other.z;
    return math.sqrt(dx * dx + dz * dz);
  }

  Vec3 lerp(Vec3 other, double t) => this + (other - this) * t;

  Vec3 withY(double value) => Vec3(x, value, z);

  @override
  bool operator ==(Object other) =>
      other is Vec3 && other.x == x && other.y == y && other.z == z;

  @override
  int get hashCode => Object.hash(x, y, z);

  @override
  String toString() =>
      'Vec3(${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)}, '
      '${z.toStringAsFixed(2)})';
}
