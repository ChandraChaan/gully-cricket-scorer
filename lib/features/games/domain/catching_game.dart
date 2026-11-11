import 'dart:math' as math;

import 'arcade_game.dart';
import 'vec3.dart';

enum CatchEvent { caught, perfect, dropped }

/// High catches: run the fielder under a skied ball before it lands.
///
/// The fielder runs towards wherever the player points. A ball is caught if
/// the fielder is within [catchRadius] of it as it drops to hand height.
/// Every catch shortens the next ball's hang time; three drops end the game.
final class CatchingGame implements ArcadeGame {
  CatchingGame({math.Random? random}) : _random = random ?? math.Random();

  static const drops = 3;
  static const fieldHalfWidth = 5.0;
  static const fieldNear = 1.0;
  static const fieldFar = 14.0;
  static const catchHeight = 1.5;
  static const catchRadius = 1.0;
  static const perfectRadius = 0.35;
  static const runSpeed = 8.5;
  static const ballRadius = 0.11;
  static const _launchZ = 34.0;

  final math.Random _random;

  Vec3 _fielder = const Vec3(0, 0, 6);
  Vec3 _target = const Vec3(0, 0, 6);
  double _facing = 0;
  double _ran = 0;
  Vec3? _ball;
  Vec3 _velocity = Vec3.zero;
  Vec3 _landing = Vec3.zero;
  double _hangTime = 1;
  double _flightTime = 0;
  double _wait = 0.8;
  bool _beaten = false;
  int _score = 0;
  int _catches = 0;
  int _dropsLeft = drops;
  CatchEvent? _lastEvent;
  double _eventAge = 0;

  Vec3 get fielder => _fielder;

  /// The way the fielder faces, as an angle from straight up the field.
  double get facing => _facing;

  /// Metres run so far, to drive the running animation.
  double get distanceRun => _ran;

  bool get isRunning => _fielder.groundDistanceTo(_target) > 0.05;

  /// The ball in the air, or null between balls.
  Vec3? get ball => _ball;

  /// The spot on the ground under where the ball in the air comes down to
  /// hand height: where the fielder needs to be.
  Vec3 get landing => _landing;

  /// How far through its flight the ball is, from 0 to 1.
  double get flightProgress => (_flightTime / _hangTime).clamp(0, 1);

  int get catches => _catches;
  CatchEvent? get lastEvent => _lastEvent;

  /// Seconds since [lastEvent].
  double get eventAge => _eventAge;

  @override
  int get score => _score;

  @override
  int get lives => _dropsLeft;

  @override
  bool get isOver => _dropsLeft == 0;

  /// Sends the fielder towards a spot on the ground.
  void runTo(double x, double z) {
    _target = Vec3(
      x.clamp(-fieldHalfWidth, fieldHalfWidth),
      0,
      z.clamp(fieldNear, fieldFar),
    );
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
    _eventAge += dt;
    _moveFielder(dt);
    final ball = _ball;
    if (ball == null) {
      _wait -= dt;
      if (_wait <= 0) _launch();
      return;
    }
    _flightTime += dt;
    _velocity = Vec3(_velocity.x, _velocity.y - gravity * dt, _velocity.z);
    final next = ball + _velocity * dt;
    _ball = next;
    if (!_beaten && _velocity.y < 0 && next.y <= catchHeight) {
      final gap = _fielder.groundDistanceTo(next);
      if (gap <= catchRadius) {
        final perfect = gap <= perfectRadius;
        _catches++;
        _score += perfect ? 2 : 1;
        _endBall(perfect ? CatchEvent.perfect : CatchEvent.caught, 0.7);
        return;
      }
      _beaten = true;
    }
    if (next.y <= ballRadius) {
      _dropsLeft--;
      _endBall(CatchEvent.dropped, 1);
    }
  }

  void _moveFielder(double dt) {
    final gap = _target - _fielder;
    final distance = gap.length;
    if (distance < 0.01) return;
    final stride = math.min(distance, runSpeed * dt);
    _fielder += gap * (stride / distance);
    _ran += stride;
    _facing = math.atan2(gap.x, gap.z);
  }

  void _launch() {
    _hangTime =
        math.max(1.8, 3.4 - 0.1 * _catches) + _random.nextDouble() * 0.3;
    final spread = math.min(fieldHalfWidth - 0.5, 3 + _catches * 0.4);
    var landing = Vec3(
      (_random.nextDouble() * 2 - 1) * spread,
      0,
      1.5 + _random.nextDouble() * (fieldFar - 3),
    );
    // Always catchable: never further than the fielder can run in time.
    final reach = runSpeed * (_hangTime - 0.45) * 0.85;
    final gap = _fielder.groundDistanceTo(landing);
    if (gap > reach) landing = _fielder.lerp(landing, reach / gap).withY(0);
    final start = Vec3((_random.nextDouble() * 2 - 1) * 1.5, 1, _launchZ);
    _landing = landing;
    _ball = start;
    _velocity = Vec3(
      (landing.x - start.x) / _hangTime,
      (0.5 * gravity * _hangTime * _hangTime - start.y + catchHeight) /
          _hangTime,
      (landing.z - start.z) / _hangTime,
    );
    _flightTime = 0;
    _beaten = false;
  }

  void _endBall(CatchEvent event, double wait) {
    _ball = null;
    _lastEvent = event;
    _eventAge = 0;
    _wait = wait;
  }
}
