import 'dart:math' as math;

import 'arcade_game.dart';

enum CarromPiece {
  black(1),
  white(2),
  queen(5),
  striker(0);

  const CarromPiece(this.points);

  final int points;
}

/// A coin or the striker. The board is one unit square, with (0, 0) at the
/// top left as on screen.
final class CarromDisc {
  CarromDisc(this.piece, this.x, this.y);

  final CarromPiece piece;
  double x;
  double y;
  double vx = 0;
  double vy = 0;

  double get radius => piece == CarromPiece.striker
      ? CarromGame.strikerRadius
      : CarromGame.coinRadius;
  double get mass => piece == CarromPiece.striker ? 1.6 : 1;
  double get speed => math.sqrt(vx * vx + vy * vy);
}

/// Carrom Strike: pocket as many coins as you can before the clock runs out.
///
/// Place the striker on the baseline, pull back and let go. Black coins are
/// worth 1, white 2 and the red queen 5, and every coin pocketed buys a few
/// more seconds. Sinking the striker is a foul: three fouls end the game
/// early. Clear the board for a bonus and a fresh rack.
final class CarromGame implements ArcadeGame {
  CarromGame({math.Random? random, List<CarromDisc>? rack})
    : _random = random ?? math.Random() {
    _coins.addAll(rack ?? _newRack());
  }

  static const fouls = 3;
  static const startTime = 60.0;
  static const secondsPerCoin = 3.0;
  static const clearBonus = 10;
  static const coinRadius = 0.027;
  static const strikerRadius = 0.04;
  static const pocketRadius = 0.09;
  static const baseline = 0.84;
  static const baselineLeft = 0.2;
  static const baselineRight = 0.8;
  static const maxShotSpeed = 2.6;

  final math.Random _random;

  final List<CarromDisc> _coins = [];
  final CarromDisc _striker = CarromDisc(CarromPiece.striker, 0.5, baseline);
  bool _moving = false;
  bool _foulThisShot = false;
  double _timeLeft = startTime;
  int _score = 0;
  int _lives = fouls;
  int _pocketed = 0;
  double _sinceFoul = 10;

  List<CarromDisc> get coins => _coins;
  CarromDisc get striker => _striker;

  /// True while anything is still sliding. No aiming until it all stops.
  bool get isMoving => _moving;

  /// Seconds left on the clock.
  double get timeLeft => math.max(0, _timeLeft);

  /// Coins pocketed so far.
  int get pocketed => _pocketed;

  /// Seconds since the striker last went down a pocket.
  double get sinceFoul => _sinceFoul;

  @override
  int get score => _score;

  @override
  int get lives => _lives;

  @override
  bool get isOver => _lives == 0 || _timeLeft <= 0;

  /// Slides the striker along the baseline before a shot.
  void placeStriker(double x) {
    if (_moving) return;
    _striker
      ..x = x.clamp(baselineLeft, baselineRight)
      ..y = baseline;
  }

  /// Flicks the striker. [dx] and [dy] give the direction and [power] runs
  /// from 0 to 1.
  void shoot(double dx, double dy, double power) {
    final length = math.sqrt(dx * dx + dy * dy);
    if (_moving || isOver || length < 1e-6) return;
    final speed = maxShotSpeed * power.clamp(0.1, 1);
    _striker
      ..vx = dx / length * speed
      ..vy = dy / length * speed;
    _moving = true;
    _foulThisShot = false;
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
    _timeLeft -= dt;
    _sinceFoul += dt;
    if (!_moving) return;

    final discs = [if (!_foulThisShot) _striker, ..._coins];
    for (final disc in discs) {
      disc
        ..x += disc.vx * dt
        ..y += disc.vy * dt;
      // The powdered board slows everything steadily.
      final speed = disc.speed;
      if (speed > 0) {
        final slowed = math.max(0, speed - (0.55 + speed * 0.5) * dt);
        disc
          ..vx *= slowed / speed
          ..vy *= slowed / speed;
      }
      _bounceOffCushions(disc);
    }
    for (var i = 0; i < discs.length; i++) {
      for (var j = i + 1; j < discs.length; j++) {
        _collide(discs[i], discs[j]);
      }
    }

    _coins.removeWhere((coin) {
      if (!_inPocket(coin)) return false;
      _score += coin.piece.points;
      _pocketed++;
      _timeLeft += secondsPerCoin;
      return true;
    });
    if (!_foulThisShot && _inPocket(_striker)) {
      _foulThisShot = true;
      _sinceFoul = 0;
      _lives--;
      _striker
        ..vx = 0
        ..vy = 0;
    }

    if (discs.every((disc) => disc.speed < 0.02)) {
      for (final disc in discs) {
        disc
          ..vx = 0
          ..vy = 0;
      }
      _moving = false;
      _striker
        ..x = _striker.x.clamp(baselineLeft, baselineRight)
        ..y = baseline;
      if (_foulThisShot) _striker.x = 0.5;
      if (_coins.isEmpty) {
        _score += clearBonus;
        _coins.addAll(_newRack());
      }
    }
  }

  static bool _inPocket(CarromDisc disc) {
    for (final px in const [0.0, 1.0]) {
      for (final py in const [0.0, 1.0]) {
        final dx = disc.x - px;
        final dy = disc.y - py;
        if (dx * dx + dy * dy < pocketRadius * pocketRadius) return true;
      }
    }
    return false;
  }

  static void _bounceOffCushions(CarromDisc disc) {
    const bounce = 0.75;
    final r = disc.radius;
    if (disc.x < r && disc.vx < 0) {
      disc
        ..x = r
        ..vx = -disc.vx * bounce;
    } else if (disc.x > 1 - r && disc.vx > 0) {
      disc
        ..x = 1 - r
        ..vx = -disc.vx * bounce;
    }
    if (disc.y < r && disc.vy < 0) {
      disc
        ..y = r
        ..vy = -disc.vy * bounce;
    } else if (disc.y > 1 - r && disc.vy > 0) {
      disc
        ..y = 1 - r
        ..vy = -disc.vy * bounce;
    }
  }

  static void _collide(CarromDisc a, CarromDisc b) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    final reach = a.radius + b.radius;
    final gapSquared = dx * dx + dy * dy;
    if (gapSquared >= reach * reach || gapSquared < 1e-12) return;
    final gap = math.sqrt(gapSquared);
    final nx = dx / gap;
    final ny = dy / gap;
    // Push them apart, lighter disc furthest.
    final overlap = reach - gap;
    final total = a.mass + b.mass;
    a
      ..x -= nx * overlap * b.mass / total
      ..y -= ny * overlap * b.mass / total;
    b
      ..x += nx * overlap * a.mass / total
      ..y += ny * overlap * a.mass / total;
    final closing = (b.vx - a.vx) * nx + (b.vy - a.vy) * ny;
    if (closing >= 0) return;
    const bounce = 0.92;
    final impulse = -(1 + bounce) * closing / (1 / a.mass + 1 / b.mass);
    a
      ..vx -= impulse / a.mass * nx
      ..vy -= impulse / a.mass * ny;
    b
      ..vx += impulse / b.mass * nx
      ..vy += impulse / b.mass * ny;
  }

  /// The queen in the middle with two rings of coins round her.
  List<CarromDisc> _newRack() {
    final turn = _random.nextDouble() * math.pi;
    final rack = [CarromDisc(CarromPiece.queen, 0.5, 0.5)];
    const spacing = coinRadius * 2.05;
    for (var i = 0; i < 6; i++) {
      final angle = turn + i * math.pi / 3;
      rack.add(
        CarromDisc(
          i.isEven ? CarromPiece.white : CarromPiece.black,
          0.5 + math.cos(angle) * spacing,
          0.5 + math.sin(angle) * spacing,
        ),
      );
    }
    for (var i = 0; i < 12; i++) {
      final angle = turn + i * math.pi / 6;
      // Corners of the hexagon sit further out than its sides.
      final reach = i.isEven ? spacing * 2 : spacing * math.sqrt(3);
      rack.add(
        CarromDisc(
          i % 3 == 0 ? CarromPiece.white : CarromPiece.black,
          0.5 + math.cos(angle) * reach,
          0.5 + math.sin(angle) * reach,
        ),
      );
    }
    return rack;
  }
}
