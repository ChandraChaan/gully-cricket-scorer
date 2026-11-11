import 'dart:math' as math;

import 'arcade_game.dart';

enum LaneItemKind {
  scooter,
  cow,
  pothole,
  crate,
  ball;

  bool get isObstacle => this != ball;
}

/// Something lying in a lane, [y] metres ahead of the runner.
final class LaneItem {
  LaneItem(this.kind, this.lane, this.y);

  final LaneItemKind kind;
  final int lane;
  double y;
}

/// Gully Dash: sprint down a three-lane gully to make the toss in time.
///
/// The runner keeps speeding up. Parked scooters, cows, potholes and crates
/// block lanes and cost a life each; cricket balls are worth extra points.
/// There is always a clear lane within reach.
final class LaneRunnerGame implements ArcadeGame {
  LaneRunnerGame({math.Random? random}) : _random = random ?? math.Random();

  static const bumps = 3;
  static const lanes = 3;
  static const viewAhead = 28.0;
  static const viewBehind = 5.0;
  static const startSpeed = 7.0;
  static const topSpeed = 19.0;
  static const ballPoints = 5;

  final math.Random _random;

  final List<LaneItem> _items = [];
  int _lane = 1;
  double _playerX = 1;
  double _distance = 0;
  double _untilNextRow = 14;
  double _shield = 0;
  int _ballsCollected = 0;
  int _bumpsLeft = bumps;
  int _clearLane = 1;

  /// The lane the runner is in or moving to: 0 is left, 2 is right.
  int get lane => _lane;

  /// Where the runner is across the gully, in lanes. It slides between
  /// lanes rather than jumping.
  double get playerX => _playerX;

  /// Metres run.
  double get distance => _distance;

  double get speed => math.min(topSpeed, startSpeed + _distance / 60);

  List<LaneItem> get items => _items;

  int get ballsCollected => _ballsCollected;

  /// True for a moment after a bump, while nothing else can hurt.
  bool get isShielded => _shield > 0;

  @override
  int get score => (_distance / 4).floor() + _ballsCollected * ballPoints;

  @override
  int get lives => _bumpsLeft;

  @override
  bool get isOver => _bumpsLeft == 0;

  void moveLeft() {
    if (_lane > 0) _lane--;
  }

  void moveRight() {
    if (_lane < lanes - 1) _lane++;
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
    final travelled = speed * dt;
    _distance += travelled;
    _shield = math.max(0, _shield - dt);

    final slide = 9 * dt;
    final gap = _lane - _playerX;
    _playerX = gap.abs() <= slide
        ? _lane.toDouble()
        : _playerX + gap.sign * slide;

    _untilNextRow -= travelled;
    if (_untilNextRow <= 0) {
      final rowGap = math.max(8.0, speed * 0.8);
      _spawnRow(viewAhead, rowGap);
      _untilNextRow += rowGap;
    }

    for (final item in _items) {
      item.y -= travelled;
    }
    _items.removeWhere((item) {
      if (item.y < -viewBehind) return true;
      final touching =
          item.y.abs() < 0.9 && (item.lane - _playerX).abs() < 0.55;
      if (!touching) return false;
      if (!item.kind.isObstacle) {
        _ballsCollected++;
        return true;
      }
      if (_shield > 0) return false;
      _bumpsLeft--;
      _shield = 1.2;
      return true;
    });
  }

  void _spawnRow(double y, double rowGap) {
    // Keep a lane clear that is next to (or the same as) the last clear one,
    // so the way through never needs more than one move per row.
    final shift = _random.nextInt(3) - 1;
    _clearLane = (_clearLane + shift).clamp(0, lanes - 1);
    final blockTwo =
        _random.nextDouble() < math.min(0.6, 0.15 + _distance / 500);
    final others = [
      for (var lane = 0; lane < lanes; lane++)
        if (lane != _clearLane) lane,
    ]..shuffle(_random);
    final blocked = blockTwo ? others : [others.first];
    const obstacles = [
      LaneItemKind.scooter,
      LaneItemKind.cow,
      LaneItemKind.pothole,
      LaneItemKind.crate,
    ];
    for (final lane in blocked) {
      _items.add(
        LaneItem(obstacles[_random.nextInt(obstacles.length)], lane, y),
      );
    }
    if (_random.nextDouble() < 0.55) {
      _items.add(LaneItem(LaneItemKind.ball, _clearLane, y + rowGap / 2));
    }
  }
}
