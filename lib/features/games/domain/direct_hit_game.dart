import 'dart:math' as math;

import 'arcade_game.dart';
import 'vec3.dart';

enum DirectHitPhase {
  /// The runner is on the way and the player may throw.
  live,

  /// The stumps are down with the runner short.
  out,

  /// The runner made the crease.
  safe,
  over,
}

/// Direct hit: throw down the stumps before the runner makes the crease.
///
/// The player throws from the origin towards stumps somewhere up the field.
/// A throw is an angle left or right ([maxYaw] either way) and a power from
/// 0 to 1. The ball may bounce on the way; hitting on the full scores double.
/// Each round the runner gets quicker, and three runs conceded end the game.
final class DirectHitGame implements ArcadeGame {
  DirectHitGame({math.Random? random}) : _random = random ?? math.Random() {
    _startRound();
  }

  static const misses = 3;
  static const release = Vec3(0.3, 1.2, 0.5);
  static const maxYaw = 0.45;
  static const elevation = 0.175;
  static const ballRadius = 0.1;
  static const stumpHalfWidth = 0.2;
  static const stumpHeight = 0.8;

  /// How far behind the stumps the runner starts, and where the crease is.
  static const runnerStart = 11.0;
  static const creaseGap = 1.2;

  final math.Random _random;

  DirectHitPhase _phase = DirectHitPhase.live;
  Vec3 _stumps = const Vec3(0, 0, 10);
  Vec3? _ball;
  Vec3 _velocity = Vec3.zero;
  double _ballAge = 0;
  bool _bounced = false;
  double _runTime = 5;
  double _elapsed = 0;
  double _pause = 0;
  int _round = 0;
  int _score = 0;
  int _missesLeft = misses;
  int _throws = 0;
  bool _lastWasFull = false;

  DirectHitPhase get phase => _phase;

  /// The foot of the middle stump.
  Vec3 get stumps => _stumps;

  /// The thrown ball, or null when the player is free to throw.
  Vec3? get ball => _ball;

  bool get canThrow => _phase == DirectHitPhase.live && _ball == null;

  /// How far the runner has got, from 0 (setting off) to 1 (home).
  double get runnerProgress => (_elapsed / _runTime).clamp(0, 1);

  /// Where the runner is now.
  Vec3 get runner => Vec3(
    _stumps.x + 1.1,
    0,
    _stumps.z + runnerStart - (runnerStart - creaseGap) * runnerProgress,
  );

  /// Rounds started so far.
  int get round => _round;

  /// Throws made this round.
  int get throws => _throws;

  /// Whether the last run out was hit on the full.
  bool get lastWasFull => _lastWasFull;

  /// Seconds left in the pause after a round.
  double get pause => _pause;

  @override
  int get score => _score;

  @override
  int get lives => _missesLeft;

  @override
  bool get isOver => _phase == DirectHitPhase.over;

  static Vec3 _launchVelocity(double yaw, double power) {
    final speed = 11 + 17 * power.clamp(0, 1);
    final angle = yaw.clamp(-maxYaw, maxYaw);
    final flat = math.cos(elevation) * speed;
    return Vec3(
      math.sin(angle) * flat,
      math.sin(elevation) * speed,
      math.cos(angle) * flat,
    );
  }

  /// The first part of the path a throw would take, for the aiming dots.
  List<Vec3> previewPath(double yaw, double power, {int points = 14}) {
    var position = release;
    var velocity = _launchVelocity(yaw, power);
    const dt = 1 / 30;
    final path = <Vec3>[];
    for (var i = 0; i < points; i++) {
      velocity = Vec3(velocity.x, velocity.y - gravity * dt, velocity.z);
      position += velocity * dt;
      if (position.y < ballRadius || position.z > _stumps.z) break;
      path.add(position);
    }
    return path;
  }

  /// Throws the ball. Ignored while a ball is already in the air.
  void throwBall(double yaw, double power) {
    if (!canThrow) return;
    _ball = release;
    _velocity = _launchVelocity(yaw, power);
    _ballAge = 0;
    _bounced = false;
    _throws++;
  }

  @override
  void update(double dt) {
    var left = dt;
    while (left > 0 && !isOver) {
      final step = math.min(left, maxStep);
      _step(step);
      left -= step;
    }
  }

  void _step(double dt) {
    _moveBall(dt);
    switch (_phase) {
      case DirectHitPhase.live:
        _elapsed += dt;
        if (_phase == DirectHitPhase.live && _elapsed >= _runTime) {
          _missesLeft--;
          _phase = DirectHitPhase.safe;
          _pause = 1.1;
        }
      case DirectHitPhase.out || DirectHitPhase.safe:
        _pause -= dt;
        if (_pause <= 0) {
          if (_missesLeft == 0) {
            _phase = DirectHitPhase.over;
          } else {
            _startRound();
          }
        }
      case DirectHitPhase.over:
        break;
    }
  }

  void _moveBall(double dt) {
    final ball = _ball;
    if (ball == null) return;
    _ballAge += dt;
    _velocity = Vec3(_velocity.x, _velocity.y - gravity * dt, _velocity.z);
    var next = ball + _velocity * dt;
    if (next.y < ballRadius && _velocity.y < 0) {
      next = next.withY(ballRadius);
      _velocity = Vec3(
        _velocity.x * 0.8,
        -_velocity.y * 0.5,
        _velocity.z * 0.8,
      );
      _bounced = true;
    }
    final crossed = ball.z < _stumps.z && next.z >= _stumps.z;
    if (_phase == DirectHitPhase.live && crossed) {
      final t = (_stumps.z - ball.z) / (next.z - ball.z);
      final at = ball.lerp(next, t);
      final onTarget =
          (at.x - _stumps.x).abs() <= stumpHalfWidth + ballRadius &&
          at.y <= stumpHeight + ballRadius;
      if (onTarget) {
        _lastWasFull = !_bounced;
        _score += _bounced ? 1 : 2;
        _phase = DirectHitPhase.out;
        _pause = 1.2;
        _velocity = Vec3(_velocity.x * 0.3, 2, _velocity.z * 0.15);
        _ball = at;
        return;
      }
    }
    _ball = next;
    final dead =
        _ballAge > 3 ||
        next.z > _stumps.z + 7 ||
        next.x.abs() > 14 ||
        (_bounced && _velocity.z.abs() < 1.5);
    if (dead) _ball = null;
  }

  void _startRound() {
    _round++;
    final distance = math.min(22.0, 9 + _round * 0.9) + _random.nextDouble();
    final side = math.min(2.4, distance * 0.16);
    _stumps = Vec3((_random.nextDouble() * 2 - 1) * side, 0, distance);
    _runTime = math.max(2.4, 5.2 - 0.22 * _round);
    _elapsed = 0;
    _throws = 0;
    _ball = null;
    _phase = DirectHitPhase.live;
  }
}
