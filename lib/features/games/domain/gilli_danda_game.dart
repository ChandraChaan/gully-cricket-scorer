import 'dart:math' as math;

import 'arcade_game.dart';
import 'vec3.dart';

enum GilliPhase {
  /// The gilli is on the ground, waiting to be flicked up.
  ready,

  /// It is spinning in the air and can be hit.
  rising,

  /// It has been hit and is flying down the lane.
  flying,

  /// The strike is over and its result is on screen.
  done,
  over,
}

enum GilliResult { perfect, good, fair, miss }

/// Gilli Danda: flick the gilli up, then hit it as it crosses the stick.
///
/// The first tap pops the gilli into the air. The second swings the danda:
/// the closer the gilli is to [strikeHeight] at that moment, the further it
/// goes. The score is the total distance in metres. Each turn the gilli
/// moves a little faster; three misses end the game.
final class GilliDandaGame implements ArcadeGame {
  GilliDandaGame({math.Random? random}) : _random = random ?? math.Random();

  static const missesAllowed = 3;
  static const strikeHeight = 1.1;
  static const perfectBand = 0.09;
  static const goodBand = 0.22;
  static const fairBand = 0.4;
  static const _rest = Vec3(0.25, 0.06, 0.6);

  final math.Random _random;

  GilliPhase _phase = GilliPhase.ready;
  double _phaseTime = 0;
  double _swingAge = 10;
  Vec3 _gilli = _rest;
  Vec3 _velocity = Vec3.zero;
  int _turn = 0;
  int _score = 0;
  int _lives = missesAllowed;
  GilliResult? _lastResult;
  int _lastDistance = 0;
  double _flown = 0;

  GilliPhase get phase => _phase;
  double get phaseTime => _phaseTime;

  /// Where the gilli is.
  Vec3 get gilli => _gilli;

  /// Seconds since the danda was last swung.
  double get swingAge => _swingAge;

  /// Strikes attempted so far.
  int get turn => _turn;
  GilliResult? get lastResult => _lastResult;

  /// Metres the last hit travelled.
  int get lastDistance => _lastDistance;

  /// How much quicker than the first turn everything moves.
  double get tempo => math.min(1.9, 1 + 0.06 * _turn);

  @override
  int get score => _score;

  @override
  int get lives => _lives;

  @override
  bool get isOver => _phase == GilliPhase.over;

  /// The one button: flicks the gilli up, then swings at it.
  void tap() {
    switch (_phase) {
      case GilliPhase.ready:
        _turn++;
        _velocity = Vec3(0, 5.6 + _random.nextDouble() * 1.2, 0);
        _enter(GilliPhase.rising);
      case GilliPhase.rising:
        _swingAge = 0;
        final error = (_gilli.y - strikeHeight).abs();
        if (error > fairBand) {
          _finish(GilliResult.miss, 0);
          return;
        }
        final (result, low, high) = switch (error) {
          <= perfectBand => (GilliResult.perfect, 55, 70),
          <= goodBand => (GilliResult.good, 35, 50),
          _ => (GilliResult.fair, 15, 30),
        };
        _lastResult = result;
        _lastDistance = low + _random.nextInt(high - low + 1);
        _score += _lastDistance;
        _flown = 0;
        // Sized so it lands about a second and a half later.
        const time = 1.5;
        _velocity = Vec3(
          (_random.nextDouble() - 0.5) * 3,
          0.5 * gravity * time - _gilli.y / time,
          _lastDistance / time,
        );
        _enter(GilliPhase.flying);
      case GilliPhase.flying || GilliPhase.done || GilliPhase.over:
        break;
    }
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
    _phaseTime += dt;
    _swingAge += dt;
    switch (_phase) {
      case GilliPhase.rising:
        final time = dt * tempo;
        _velocity = Vec3(0, _velocity.y - gravity * time, 0);
        _gilli += _velocity * time;
        if (_gilli.y <= _rest.y && _velocity.y < 0) {
          _finish(GilliResult.miss, 0);
        }
      case GilliPhase.flying:
        _velocity = Vec3(_velocity.x, _velocity.y - gravity * dt, _velocity.z);
        _gilli += _velocity * dt;
        _flown += dt;
        if (_gilli.y <= _rest.y || _flown > 3) _enter(GilliPhase.done);
      case GilliPhase.done:
        // A missed gilli drops back to the ground.
        if (_gilli.y > _rest.y) {
          _velocity = Vec3(0, _velocity.y - gravity * dt, 0);
          _gilli = (_gilli + _velocity * dt).withY(
            math.max(_rest.y, _gilli.y + _velocity.y * dt),
          );
        }
        if (_phaseTime >= 1) {
          if (_lives == 0) {
            _enter(GilliPhase.over);
          } else {
            _gilli = _rest;
            _velocity = Vec3.zero;
            _enter(GilliPhase.ready);
          }
        }
      case GilliPhase.ready || GilliPhase.over:
        break;
    }
  }

  void _finish(GilliResult result, int distance) {
    _lastResult = result;
    _lastDistance = distance;
    if (result == GilliResult.miss) _lives--;
    _enter(GilliPhase.done);
  }

  void _enter(GilliPhase phase) {
    _phase = phase;
    _phaseTime = 0;
  }
}
