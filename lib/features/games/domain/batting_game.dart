import 'dart:math' as math;

import 'arcade_game.dart';
import 'vec3.dart';

enum BattingPhase {
  /// The bowler is running in.
  runUp,

  /// The ball is on its way to the batter.
  inFlight,

  /// The bat met the ball and it is flying away.
  struck,

  /// The ball is dead and its result is on screen.
  done,
  over,
}

/// Where the batter aims. Seen from behind a right-hander, leg is to the
/// left of the screen and off is to the right.
enum ShotDirection { leg, straight, off }

enum BallOutcome { six, four, runs, dot, bowled, caught }

final class BallResult {
  const BallResult(this.outcome, [this.runs = 0]);

  final BallOutcome outcome;
  final int runs;

  bool get isWicket =>
      outcome == BallOutcome.bowled || outcome == BallOutcome.caught;
}

/// Gully batting: time a swing as the ball arrives.
///
/// The stumps stand at z = 0 and the bowler lets go at [releaseZ]. A swing is
/// graded by how close in time it is to the ball reaching [contactZ]:
/// perfect is a six, good a four, fair a few runs and a poor one an edge
/// that may be caught. A ball left alone or missed bowls the batter if it is
/// on the stumps. Three wickets end the game.
final class BattingGame implements ArcadeGame {
  BattingGame({math.Random? random}) : _random = random ?? math.Random() {
    _startRunUp();
  }

  static const wickets = 3;
  static const releaseZ = 16.0;
  static const contactZ = 1.3;
  static const ballRadius = 0.09;
  static const runUpTime = 1.1;
  static const stumpHalfWidth = 0.17;
  static const stumpHeight = 0.78;

  static const perfectWindow = 0.045;
  static const goodWindow = 0.09;
  static const fairWindow = 0.15;
  static const edgeWindow = 0.21;

  /// A swing this long after the ball has gone past still gets bat on it.
  static const lateLimit = 0.07;

  final math.Random _random;

  BattingPhase _phase = BattingPhase.runUp;
  Vec3 _ball = const Vec3(0, 2.1, releaseZ);
  Vec3 _velocity = Vec3.zero;
  double _phaseTime = 0;
  double _deviation = 0;
  bool _bounced = false;
  bool _passedStumps = false;
  int _score = 0;
  int _wicketsLeft = wickets;
  int _balls = 0;
  int? _pendingGrade;
  ShotDirection? _shot;
  double _swingAge = 0;
  BallResult? _lastResult;
  double _resultAge = 0;
  bool _stumpsBroken = false;

  BattingPhase get phase => _phase;
  Vec3 get ball => _ball;

  /// Seconds spent in the current [phase].
  double get phaseTime => _phaseTime;

  /// Balls bowled so far, including the one in play.
  int get balls => _balls;

  /// Every six balls the bowling gets quicker.
  int get level => math.max(0, _balls - 1) ~/ 6;

  /// The shot played at this ball, if any.
  ShotDirection? get shot => _shot;

  /// Seconds since the batter swung at this ball.
  double get swingAge => _swingAge;

  BallResult? get lastResult => _lastResult;

  /// Seconds since [lastResult] happened.
  double get resultAge => _resultAge;
  bool get stumpsBroken => _stumpsBroken;

  @override
  int get score => _score;

  @override
  int get lives => _wicketsLeft;

  @override
  bool get isOver => _phase == BattingPhase.over;

  /// Seconds until the ball reaches the bat; negative once it has gone past.
  /// Null when no ball is in flight.
  double? get timeToContact {
    if (_phase != BattingPhase.inFlight || _velocity.z >= 0) return null;
    return (_ball.z - contactZ) / -_velocity.z;
  }

  /// Plays a shot at the ball in flight. Only the first swing counts.
  void swing(ShotDirection direction) {
    final time = timeToContact;
    if (time == null || _shot != null) return;
    _shot = direction;
    _swingAge = 0;
    final error = time.abs();
    if (time < -lateLimit || error > edgeWindow) return;
    var grade = switch (error) {
      <= perfectWindow => 0,
      <= goodWindow => 1,
      <= fairWindow => 2,
      _ => 3,
    };
    // Hitting across the line costs a grade.
    final lineAtBat = _ball.x + _velocity.x * math.max(0, time);
    final across =
        (direction == ShotDirection.leg && lineAtBat > 0.15) ||
        (direction == ShotDirection.off && lineAtBat < -0.15);
    if (across) grade = math.min(3, grade + 1);
    _pendingGrade = grade;
    if (time <= 0) _connect(time);
  }

  @override
  void update(double dt) {
    var left = dt;
    while (left > 0 && _phase != BattingPhase.over) {
      final step = math.min(left, maxStep);
      _step(step);
      left -= step;
    }
  }

  void _step(double dt) {
    _phaseTime += dt;
    _resultAge += dt;
    if (_shot != null) _swingAge += dt;
    switch (_phase) {
      case BattingPhase.runUp:
        if (_phaseTime >= runUpTime) _release();
      case BattingPhase.inFlight:
        _moveBall(dt);
        if (_pendingGrade != null) {
          if (_ball.z <= contactZ) _connect(0);
        } else if (!_passedStumps && _ball.z <= 0) {
          _passedStumps = true;
          if (_ball.x.abs() <= stumpHalfWidth && _ball.y <= stumpHeight) {
            _stumpsBroken = true;
            _velocity = Vec3(_velocity.x, 2.5, _velocity.z * 0.15);
            _finish(const BallResult(BallOutcome.bowled));
          }
        } else if (_ball.z <= -2.5) {
          _finish(const BallResult(BallOutcome.dot));
        }
      case BattingPhase.struck:
        _moveBall(dt);
        if (_phaseTime >= 1.5) _enter(BattingPhase.done);
      case BattingPhase.done:
        if (_stumpsBroken) _moveBall(dt);
        if (_phaseTime >= 0.9) {
          if (_wicketsLeft == 0) {
            _enter(BattingPhase.over);
          } else {
            _startRunUp();
          }
        }
      case BattingPhase.over:
        break;
    }
  }

  void _enter(BattingPhase phase) {
    _phase = phase;
    _phaseTime = 0;
  }

  void _startRunUp() {
    _enter(BattingPhase.runUp);
    _ball = const Vec3(0, 2.1, releaseZ);
    _velocity = Vec3.zero;
    _shot = null;
    _swingAge = 0;
    _pendingGrade = null;
    _bounced = false;
    _passedStumps = false;
    _stumpsBroken = false;
  }

  void _release() {
    _balls++;
    var speed = math.min(24.0, 14 + level * 1.2) + _spread(1);
    // The slower ball: same action, arrives late.
    if (level >= 1 && _random.nextDouble() < 0.18) speed *= 0.72;
    final start = Vec3(_spread(0.35), 2.1, releaseZ);
    final lineAtStumps = _spread(0.45);
    final bounceZ = 3.5 + _random.nextDouble() * 3.5;
    final time = (releaseZ - bounceZ) / speed;
    final bounceX =
        start.x + (lineAtStumps - start.x) * (releaseZ - bounceZ) / releaseZ;
    _ball = start;
    _velocity = Vec3(
      (bounceX - start.x) / time,
      (ballRadius - start.y + 0.5 * gravity * time * time) / time,
      -speed,
    );
    _deviation = _spread(0.5) * math.min(1, level / 3);
    _enter(BattingPhase.inFlight);
  }

  double _spread(double size) => (_random.nextDouble() * 2 - 1) * size;

  void _moveBall(double dt) {
    _velocity = Vec3(_velocity.x, _velocity.y - gravity * dt, _velocity.z);
    _ball += _velocity * dt;
    if (_ball.y < ballRadius && _velocity.y < 0) {
      _ball = _ball.withY(ballRadius);
      final seam = _bounced || _phase != BattingPhase.inFlight
          ? 0.0
          : _deviation;
      _velocity = Vec3(
        _velocity.x * 0.85 + seam,
        -_velocity.y * 0.55,
        _velocity.z * (_phase == BattingPhase.inFlight ? 0.94 : 0.8),
      );
      _bounced = true;
    }
  }

  /// Bat meets ball. [time] is how early (positive) or late the swing was.
  void _connect(double time) {
    final grade = _pendingGrade!;
    _pendingGrade = null;
    final result = switch (grade) {
      0 => const BallResult(BallOutcome.six, 6),
      1 => const BallResult(BallOutcome.four, 4),
      2 => BallResult(BallOutcome.runs, switch (_random.nextDouble()) {
        < 0.5 => 1,
        < 0.85 => 2,
        _ => 3,
      }),
      _ =>
        _random.nextDouble() < 0.35
            ? const BallResult(BallOutcome.caught)
            : const BallResult(BallOutcome.dot),
    };
    final (speed, elevation) = switch (result.outcome) {
      BallOutcome.six => (30.0, 0.56),
      BallOutcome.four => (27.0, 0.1),
      BallOutcome.runs => (14.0, 0.2),
      BallOutcome.caught => (9.0, 1.1),
      _ => (6.0, 0.15),
    };
    final aim = switch (_shot!) {
      ShotDirection.leg => -0.7,
      ShotDirection.straight => 0.0,
      ShotDirection.off => 0.7,
    };
    // Early swings drag the ball to leg, late ones squirt it to off.
    final yaw = aim + (-time * 2.6).clamp(-0.35, 0.35);
    final flat = math.cos(elevation) * speed;
    _velocity = Vec3(
      math.sin(yaw) * flat,
      math.sin(elevation) * speed,
      math.cos(yaw) * flat,
    );
    _ball = _ball.withY(math.max(_ball.y, 0.5));
    _record(result);
    _enter(BattingPhase.struck);
  }

  void _finish(BallResult result) {
    _record(result);
    _enter(BattingPhase.done);
  }

  void _record(BallResult result) {
    _lastResult = result;
    _resultAge = 0;
    _score += result.runs;
    if (result.isWicket) _wicketsLeft--;
  }
}
