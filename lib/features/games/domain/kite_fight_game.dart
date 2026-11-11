import 'dart:math' as math;

import 'arcade_game.dart';

/// A point in the sky. x runs 0 to 1 across the screen; y is height above
/// the rooftops, from 0 up to [KiteFightGame.skyHeight].
typedef SkyPoint = ({double x, double y});

enum RivalState { drifting, windUp, swooping, cut }

final class RivalKite {
  RivalKite(this.anchor, this.position, this.color, this.restFor);

  /// Where its string is held, down on the rooftops.
  final SkyPoint anchor;
  SkyPoint position;
  SkyPoint velocity = (x: 0, y: 0);
  SkyPoint goal = (x: 0.5, y: 1);

  /// Which of the kite colours to paint it.
  final int color;
  RivalState state = RivalState.drifting;

  /// Seconds left before it next changes its mind.
  double restFor;

  /// Seconds spent in [state].
  double stateTime = 0;
}

/// Kite Fight: cut the other kites' strings before they cut yours.
///
/// A string is cut when another string is dragged across it at speed: the
/// faster kite wins. Rivals wobble before they swoop at the player's string,
/// which is the cue to move. Three lost kites end the game.
final class KiteFightGame implements ArcadeGame {
  KiteFightGame({math.Random? random}) : _random = random ?? math.Random() {
    _rivals.add(_spawnRival());
  }

  static const kitesLost = 3;
  static const skyHeight = 1.6;
  static const maxSpeed = 2.2;

  /// A string has to be moving at least this fast to cut.
  static const cuttingSpeed = 0.9;

  /// ...and this much faster than the string it crosses.
  static const cuttingEdge = 1.15;
  static const swoopSpeed = 1.5;
  static const SkyPoint anchor = (x: 0.5, y: 0);
  static const SkyPoint _start = (x: 0.5, y: 0.8);

  final math.Random _random;

  final List<RivalKite> _rivals = [];
  SkyPoint _kite = _start;
  SkyPoint _target = _start;
  SkyPoint _velocity = (x: 0, y: 0);
  double _safeFor = 1.5;
  double _downFor = 0;
  double _respawnIn = 0;
  int _score = 0;
  int _lives = kitesLost;
  int _nextColor = 0;

  /// The player's kite.
  SkyPoint get kite => _kite;
  SkyPoint get velocity => _velocity;
  List<RivalKite> get rivals => _rivals;

  /// True while the player's string has just been cut and a new kite is
  /// going up.
  bool get isDown => _downFor > 0;

  /// True for a moment after launching, while nothing can cut the string.
  bool get isSafe => _safeFor > 0;

  @override
  int get score => _score;

  @override
  int get lives => _lives;

  @override
  bool get isOver => _lives == 0 && _downFor <= 0;

  /// Steers the kite towards a point in the sky.
  void flyTo(double x, double y) {
    _target = (x: x.clamp(0.06, 0.94), y: y.clamp(0.35, skyHeight - 0.08));
  }

  static double _length(SkyPoint v) => math.sqrt(v.x * v.x + v.y * v.y);

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
    _safeFor = math.max(0, _safeFor - dt);
    if (_downFor > 0) {
      // The cut kite drifts off; a new one goes up when it has gone.
      _kite = (x: _kite.x + 0.15 * dt, y: _kite.y + 0.5 * dt);
      _downFor -= dt;
      if (_downFor <= 0 && _lives > 0) {
        _kite = _start;
        _target = _start;
        _velocity = (x: 0, y: 0);
        _safeFor = 1.5;
      }
    } else {
      // Ease towards the finger, but no faster than a kite can go.
      var vx = (_target.x - _kite.x) * 8;
      var vy = (_target.y - _kite.y) * 8;
      final speed = math.sqrt(vx * vx + vy * vy);
      if (speed > maxSpeed) {
        vx *= maxSpeed / speed;
        vy *= maxSpeed / speed;
      }
      _velocity = (x: vx, y: vy);
      _kite = (x: _kite.x + vx * dt, y: _kite.y + vy * dt);
    }

    for (final rival in _rivals) {
      _moveRival(rival, dt);
    }
    _rivals.removeWhere(
      (rival) => rival.state == RivalState.cut && rival.stateTime > 1.5,
    );

    final wanted = math.min(3, 1 + _score ~/ 3);
    final flying = _rivals.where((r) => r.state != RivalState.cut).length;
    if (flying < wanted) {
      _respawnIn -= dt;
      if (_respawnIn <= 0) {
        _rivals.add(_spawnRival());
        _respawnIn = 1.2;
      }
    }

    if (_downFor > 0) return;
    for (final rival in _rivals) {
      if (rival.state == RivalState.cut) continue;
      if (!_crosses(anchor, _kite, rival.anchor, rival.position)) continue;
      final mine = _length(_velocity);
      final theirs = _length(rival.velocity);
      if (mine >= cuttingSpeed && mine > theirs * cuttingEdge) {
        rival
          ..state = RivalState.cut
          ..stateTime = 0;
        _score++;
        _respawnIn = 1.2;
      } else if (_safeFor <= 0 &&
          theirs >= cuttingSpeed &&
          theirs > mine * cuttingEdge) {
        _lives--;
        _downFor = 1.4;
        return;
      }
    }
  }

  void _moveRival(RivalKite rival, double dt) {
    rival.stateTime += dt;
    switch (rival.state) {
      case RivalState.drifting:
        _glide(rival, 0.28, dt);
        rival.restFor -= dt;
        final near = _length((
          x: rival.goal.x - rival.position.x,
          y: rival.goal.y - rival.position.y,
        ));
        if (near < 0.05) rival.goal = _somewhere();
        if (rival.restFor <= 0 && _downFor <= 0) {
          rival
            ..state = RivalState.windUp
            ..stateTime = 0;
        }
      case RivalState.windUp:
        rival.velocity = (x: 0, y: 0);
        if (rival.stateTime >= 0.6) {
          // Aim through the middle of the player's string and out the far
          // side.
          final middle = (
            x: (anchor.x + _kite.x) / 2,
            y: (anchor.y + _kite.y) / 2 + 0.15,
          );
          final dx = middle.x - rival.position.x;
          final dy = middle.y - rival.position.y;
          final reach = math.max(0.01, math.sqrt(dx * dx + dy * dy));
          rival
            ..goal = (
              x: (middle.x + dx / reach * 0.35).clamp(0.06, 0.94),
              y: (middle.y + dy / reach * 0.35).clamp(0.3, skyHeight - 0.08),
            )
            ..state = RivalState.swooping
            ..stateTime = 0;
        }
      case RivalState.swooping:
        final arrived = _glide(rival, swoopSpeed, dt);
        if (arrived || rival.stateTime > 2) {
          rival
            ..state = RivalState.drifting
            ..stateTime = 0
            ..goal = _somewhere()
            ..restFor = _rest();
        }
      case RivalState.cut:
        rival.position = (
          x: rival.position.x + 0.12 * dt,
          y: rival.position.y + 0.45 * dt,
        );
    }
  }

  /// Flies [rival] towards its goal. Returns true once it is there.
  bool _glide(RivalKite rival, double speed, double dt) {
    final dx = rival.goal.x - rival.position.x;
    final dy = rival.goal.y - rival.position.y;
    final far = math.sqrt(dx * dx + dy * dy);
    if (far < 0.01) {
      rival.velocity = (x: 0, y: 0);
      return true;
    }
    final step = math.min(far, speed * dt);
    rival
      ..velocity = (x: dx / far * speed, y: dy / far * speed)
      ..position = (
        x: rival.position.x + dx / far * step,
        y: rival.position.y + dy / far * step,
      );
    return false;
  }

  SkyPoint _somewhere() => (
    x: 0.1 + _random.nextDouble() * 0.8,
    y: 0.7 + _random.nextDouble() * 0.75,
  );

  /// How long a rival idles between swoops. They get keener as the score
  /// climbs.
  double _rest() =>
      math.max(1.2, 3.2 - 0.15 * _score) + _random.nextDouble() * 1.5;

  RivalKite _spawnRival() {
    final left = _random.nextBool();
    final anchorX = left
        ? 0.05 + _random.nextDouble() * 0.25
        : 0.7 + _random.nextDouble() * 0.25;
    final rival = RivalKite(
      (x: anchorX, y: 0),
      (x: anchorX, y: 0.5),
      _nextColor++ % 4,
      _rest(),
    )..goal = _somewhere();
    return rival;
  }

  /// Whether the line from [a] to [b] crosses the line from [c] to [d].
  static bool _crosses(SkyPoint a, SkyPoint b, SkyPoint c, SkyPoint d) {
    double side(SkyPoint p, SkyPoint q, SkyPoint r) =>
        (q.x - p.x) * (r.y - p.y) - (q.y - p.y) * (r.x - p.x);
    final d1 = side(c, d, a);
    final d2 = side(c, d, b);
    final d3 = side(a, b, c);
    final d4 = side(a, b, d);
    return d1 * d2 < 0 && d3 * d4 < 0;
  }
}
