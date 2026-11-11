import 'dart:math' as math;

import 'arcade_game.dart';
import 'vec3.dart';

enum DefenderState {
  /// On their feet and watching. Run into one and you are caught.
  ready,

  /// Crouching to spring. This is the warning.
  windUp,

  /// Diving at where the raider was.
  lunge,

  /// Sprawled after a missed dive. Touch them now to tag them.
  down,

  /// Tagged and off the mat for the rest of the raid.
  out,
}

final class Defender {
  Defender(this.position, this.post, this.cooldown);

  Vec3 position;

  /// Where they like to stand.
  final Vec3 post;
  DefenderState state = DefenderState.ready;

  /// Seconds left in a timed [state].
  double timer = 0;
  double cooldown;
  Vec3 heading = const Vec3(0, 0, -1);
}

enum RaidEvent { scored, tackled, timeUp }

/// Kabaddi Raid: cross the line, tag defenders and get home in time.
///
/// Defenders on their feet catch a raider who touches them, so the trick is
/// to draw a dive, dodge it and tag the defender while they are down. Tags
/// only count once the raider is back over the midline (z = 0). Getting
/// caught, or running out of time without a tag, costs one of three lives.
final class KabaddiGame implements ArcadeGame {
  KabaddiGame({math.Random? random}) : _random = random ?? math.Random() {
    _startRaid();
  }

  static const raidsLost = 3;
  static const matHalfWidth = 4.5;
  static const matNear = -3.0;
  static const matFar = 9.0;
  static const raidTime = 15.0;
  static const raiderSpeed = 6.2;
  static const lungeRange = 2.8;
  static const lungeSpeed = 9.5;
  static const lungeTime = 0.3;
  static const catchRadius = 0.7;
  static const tagRadius = 1.0;
  static const allOutBonus = 2;
  static const _home = Vec3(0, 0, -1.6);

  final math.Random _random;

  final List<Defender> _defenders = [];
  Vec3 _raider = _home;
  Vec3 _target = _home;
  double _facing = 0;
  double _ran = 0;
  double _timeLeft = raidTime;
  double _pause = 0;
  int _raid = 0;
  int _tags = 0;
  int _score = 0;
  int _lives = raidsLost;
  RaidEvent? _lastEvent;
  int _lastPoints = 0;
  double _eventAge = 0;

  Vec3 get raider => _raider;
  double get facing => _facing;
  double get distanceRun => _ran;
  bool get isRunning => _raider.groundDistanceTo(_target) > 0.05;
  List<Defender> get defenders => _defenders;

  /// Raids started so far.
  int get raid => _raid;

  /// Defenders tagged on this raid, not yet banked.
  int get tags => _tags;

  /// The share of the raid clock left, from 1 down to 0.
  double get timeLeft => (_timeLeft / raidTime).clamp(0, 1);

  RaidEvent? get lastEvent => _lastEvent;

  /// Points banked by the last successful raid.
  int get lastPoints => _lastPoints;
  double get eventAge => _eventAge;

  @override
  int get score => _score;

  @override
  int get lives => _lives;

  @override
  bool get isOver => _lives == 0 && _pause <= 0;

  int get _level => _raid - 1;

  /// Sends the raider towards a spot on the mat.
  void runTo(double x, double z) {
    _target = Vec3(
      x.clamp(-matHalfWidth, matHalfWidth),
      0,
      z.clamp(matNear, matFar),
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
    if (_pause > 0) {
      _pause -= dt;
      if (_pause <= 0 && _lives > 0) _startRaid();
      return;
    }

    final gap = _target - _raider;
    final distance = gap.length;
    if (distance > 0.01) {
      final stride = math.min(distance, raiderSpeed * dt);
      _raider += gap * (stride / distance);
      _ran += stride;
      _facing = math.atan2(gap.x, gap.z);
    }

    for (final defender in _defenders) {
      if (_moveDefender(defender, dt)) {
        _end(RaidEvent.tackled);
        return;
      }
    }

    if (_tags > 0 && _raider.z < -0.2) {
      final everyone = _defenders.every((d) => d.state == DefenderState.out);
      _lastPoints = _tags + (everyone ? allOutBonus : 0);
      _score += _lastPoints;
      _end(RaidEvent.scored);
      return;
    }
    _timeLeft -= dt;
    if (_timeLeft <= 0) _end(RaidEvent.timeUp);
  }

  /// Returns true if this defender has caught the raider.
  bool _moveDefender(Defender defender, double dt) {
    final toRaider = _raider - defender.position;
    final gap = toRaider.length;
    final raiding = _raider.z > 0.3;
    switch (defender.state) {
      case DefenderState.ready:
        // Hold the post, swaying, and edge towards the raider.
        final sway = math.sin(_timeLeft * 1.7 + defender.post.x) * 0.8;
        final spot = raiding
            ? (defender.post + Vec3(sway, 0, 0)).lerp(_raider, 0.25)
            : defender.post + Vec3(sway, 0, 0);
        final step = spot - defender.position;
        final far = step.length;
        if (far > 0.02) {
          final speed = math.min(far, (2.2 + 0.2 * _level) * dt);
          defender.position += step * (speed / far);
        }
        if (gap > 0.01) defender.heading = toRaider * (1 / gap);
        defender.cooldown -= dt;
        if (raiding && gap <= catchRadius) return true;
        if (raiding && gap <= lungeRange && defender.cooldown <= 0) {
          defender
            ..state = DefenderState.windUp
            ..timer = math.max(0.28, 0.5 - 0.03 * _level);
        }
      case DefenderState.windUp:
        if (gap > 0.01) defender.heading = toRaider * (1 / gap);
        if (raiding && gap <= catchRadius) return true;
        defender.timer -= dt;
        if (defender.timer <= 0) {
          defender
            ..state = DefenderState.lunge
            ..timer = lungeTime;
        }
      case DefenderState.lunge:
        defender.position += defender.heading * (lungeSpeed * dt);
        if (raiding && gap <= catchRadius) return true;
        defender.timer -= dt;
        if (defender.timer <= 0) {
          defender
            ..state = DefenderState.down
            ..timer = math.max(0.6, 1.1 - 0.06 * _level);
        }
      case DefenderState.down:
        if (gap <= tagRadius) {
          defender.state = DefenderState.out;
          _tags++;
          break;
        }
        defender.timer -= dt;
        if (defender.timer <= 0) {
          defender
            ..state = DefenderState.ready
            ..cooldown = 0.8 + _random.nextDouble() * 0.8;
        }
      case DefenderState.out:
        break;
    }
    return false;
  }

  void _end(RaidEvent event) {
    _lastEvent = event;
    _eventAge = 0;
    if (event != RaidEvent.scored) _lives--;
    _pause = 1.3;
  }

  void _startRaid() {
    _raid++;
    _tags = 0;
    _timeLeft = raidTime;
    _raider = _home;
    _target = _home;
    _facing = 0;
    final count = math.min(6, 3 + _level ~/ 2);
    _defenders.clear();
    for (var i = 0; i < count; i++) {
      // A shallow arc across the far half.
      final across = count == 1 ? 0.0 : i / (count - 1) * 2 - 1;
      final post = Vec3(
        across * (matHalfWidth - 1),
        0,
        4.2 + (1 - across * across) * 2 + _random.nextDouble() * 0.8,
      );
      _defenders.add(Defender(post, post, 0.4 + _random.nextDouble() * 1.2));
    }
  }
}
