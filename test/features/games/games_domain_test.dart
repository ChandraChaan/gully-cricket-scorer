import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:gully_cricket_scorer/features/games/domain/arcade_game.dart';
import 'package:gully_cricket_scorer/features/games/domain/batting_game.dart';
import 'package:gully_cricket_scorer/features/games/domain/catching_game.dart';
import 'package:gully_cricket_scorer/features/games/domain/direct_hit_game.dart';
import 'package:gully_cricket_scorer/features/games/domain/lane_runner_game.dart';
import 'package:gully_cricket_scorer/features/games/domain/vec3.dart';

const _frame = 1 / 60;

/// Steps [game] until [done], failing if it takes more than [limit] seconds.
void runUntil(ArcadeGame game, bool Function() done, {double limit = 60}) {
  var time = 0.0;
  while (!done()) {
    game.update(_frame);
    time += _frame;
    if (time > limit) fail('Still waiting after $limit seconds');
  }
}

void main() {
  group('Vec3', () {
    test('cross of x and y is z, and normalised vectors have length 1', () {
      expect(
        const Vec3(1, 0, 0).cross(const Vec3(0, 1, 0)),
        const Vec3(0, 0, 1),
      );
      expect(const Vec3(3, 4, 12).normalized.length, closeTo(1, 1e-9));
      expect(Vec3.zero.normalized, Vec3.zero);
    });

    test('ground distance ignores height', () {
      expect(
        const Vec3(0, 9, 0).groundDistanceTo(const Vec3(3, 0, 4)),
        closeTo(5, 1e-9),
      );
    });
  });

  group('GameId', () {
    test('keys round-trip', () {
      for (final id in GameId.values) {
        expect(GameId.fromKey(id.key), id);
      }
      expect(GameId.fromKey('nope'), isNull);
    });
  });

  group('BattingGame', () {
    /// Bowls the next ball and swings [offset] seconds away from perfect
    /// (positive is early). Returns once the ball has been dealt with.
    BallResult? play(BattingGame game, double offset) {
      final ball = game.balls;
      runUntil(game, () => game.phase == BattingPhase.inFlight);
      while (game.phase == BattingPhase.inFlight && game.shot == null) {
        if (game.timeToContact! <= offset) {
          game.swing(ShotDirection.straight);
        } else {
          game.update(1 / 600);
        }
      }
      runUntil(
        game,
        () =>
            game.isOver ||
            (game.balls == ball + 1 &&
                (game.phase == BattingPhase.done ||
                    game.phase == BattingPhase.struck)),
      );
      return game.lastResult;
    }

    test('starts with the bowler running in and three wickets', () {
      final game = BattingGame(random: math.Random(1));
      expect(game.phase, BattingPhase.runUp);
      expect(game.lives, 3);
      expect(game.score, 0);
      expect(game.timeToContact, isNull);
    });

    test('a perfectly timed straight swing is a six', () {
      final game = BattingGame(random: math.Random(1));
      final result = play(game, 0.001);
      expect(result?.outcome, BallOutcome.six);
      expect(game.score, 6);
      expect(game.lives, 3);
      expect(game.phase, BattingPhase.struck);
    });

    test('a slightly early swing is a four, an earlier one a few runs', () {
      final four = BattingGame(random: math.Random(1));
      expect(play(four, 0.07)?.outcome, BallOutcome.four);
      expect(four.score, 4);

      final runs = BattingGame(random: math.Random(1));
      final result = play(runs, 0.12);
      expect(result?.outcome, BallOutcome.runs);
      expect(result?.runs, inInclusiveRange(1, 3));
      expect(runs.score, result?.runs);
    });

    test('a swing far too early misses and scores nothing', () {
      final game = BattingGame(random: math.Random(1));
      final result = play(game, 0.5);
      expect(result?.runs ?? 0, 0);
      expect(game.score, 0);
    });

    test('only the first swing at a ball counts', () {
      final game = BattingGame(random: math.Random(1));
      runUntil(game, () => game.phase == BattingPhase.inFlight);
      game.swing(ShotDirection.leg);
      game.swing(ShotDirection.off);
      expect(game.shot, ShotDirection.leg);
    });

    test(
      'leaving every ball never scores and ends once bowled three times',
      () {
        final game = BattingGame(random: math.Random(3));
        runUntil(game, () => game.isOver, limit: 3600);
        expect(game.score, 0);
        expect(game.lives, 0);
        expect(game.lastResult?.outcome, BallOutcome.bowled);
        expect(game.stumpsBroken, isTrue);
      },
    );

    test('the bowling gets quicker with each over', () {
      final game = BattingGame(random: math.Random(5));
      expect(game.level, 0);
      for (var ball = 0; ball < 7; ball++) {
        play(game, 0.001);
        if (game.isOver) break;
      }
      expect(game.balls, 7);
      expect(game.level, 1);
    });

    test('update does nothing once the game is over', () {
      final game = BattingGame(random: math.Random(3));
      runUntil(game, () => game.isOver, limit: 3600);
      final balls = game.balls;
      game.update(5);
      expect(game.balls, balls);
      game.swing(ShotDirection.straight);
      expect(game.score, 0);
    });
  });

  group('CatchingGame', () {
    test('standing under the ball catches it', () {
      final game = CatchingGame(random: math.Random(2));
      runUntil(game, () => game.ball != null);
      game.runTo(game.landing.x, game.landing.z);
      runUntil(game, () => game.lastEvent != null);
      expect(game.lastEvent, CatchEvent.perfect);
      expect(game.score, 2);
      expect(game.catches, 1);
      expect(game.lives, 3);
    });

    test('a catch near the edge of reach scores one', () {
      final game = CatchingGame(random: math.Random(2));
      runUntil(game, () => game.ball != null);
      game.runTo(game.landing.x + 0.7, game.landing.z);
      runUntil(game, () => game.lastEvent != null);
      expect(game.lastEvent, CatchEvent.caught);
      expect(game.score, 1);
    });

    test('every ball can be reached from wherever the fielder is', () {
      final game = CatchingGame(random: math.Random(9));
      for (var ball = 0; ball < 25; ball++) {
        runUntil(game, () => game.ball != null);
        game.runTo(game.landing.x, game.landing.z);
        runUntil(game, () => game.ball == null);
        expect(game.lastEvent, isNot(CatchEvent.dropped), reason: 'ball $ball');
      }
      expect(game.lives, 3);
      expect(game.catches, 25);
    });

    test('standing still drops three and ends the game', () {
      final game = CatchingGame(random: math.Random(4))..runTo(-5, 1);
      var far = 0;
      runUntil(game, () {
        final ball = game.ball;
        // Keep away from wherever it is coming down.
        if (ball != null) {
          game.runTo(game.landing.x > 0 ? -5 : 5, game.landing.z > 7 ? 1 : 14);
          far++;
        }
        return game.isOver;
      }, limit: 600);
      expect(far, greaterThan(0));
      expect(game.lives, 0);
      expect(game.lastEvent, CatchEvent.dropped);
    });

    test('the fielder stays inside the field', () {
      final game = CatchingGame(random: math.Random(1))..runTo(99, -99);
      game.update(5);
      expect(game.fielder.x, closeTo(CatchingGame.fieldHalfWidth, 0.05));
      expect(game.fielder.z, closeTo(CatchingGame.fieldNear, 0.05));
      expect(game.isRunning, isFalse);
    });
  });

  group('DirectHitGame', () {
    /// Finds a throw that hits by trying powers at the right angle.
    (double, double)? aimAt(DirectHitGame Function() fresh) {
      final probe = fresh();
      final yaw = math.atan2(
        probe.stumps.x - DirectHitGame.release.x,
        probe.stumps.z - DirectHitGame.release.z,
      );
      for (var power = 0.0; power <= 1; power += 0.01) {
        final game = fresh()..throwBall(yaw, power);
        runUntil(
          game,
          () => game.phase != DirectHitPhase.live || game.canThrow,
        );
        if (game.phase == DirectHitPhase.out) return (yaw, power);
      }
      return null;
    }

    test('a good throw runs the batter out', () {
      DirectHitGame fresh() => DirectHitGame(random: math.Random(6));
      final aim = aimAt(fresh);
      expect(aim, isNotNull);
      final game = fresh()..throwBall(aim!.$1, aim.$2);
      expect(game.canThrow, isFalse);
      runUntil(game, () => game.phase == DirectHitPhase.out);
      expect(game.score, inInclusiveRange(1, 2));
      expect(game.score, game.lastWasFull ? 2 : 1);
      expect(game.lives, 3);
      runUntil(game, () => game.round == 2);
      expect(game.phase, DirectHitPhase.live);
    });

    test('a wide throw misses and can be followed by another', () {
      final game = DirectHitGame(random: math.Random(6))
        ..throwBall(-DirectHitGame.maxYaw, 1);
      expect(game.throws, 1);
      runUntil(game, () => game.canThrow || game.phase != DirectHitPhase.live);
      expect(game.phase, DirectHitPhase.live);
      expect(game.score, 0);
      game.throwBall(DirectHitGame.maxYaw, 1);
      expect(game.throws, 2);
    });

    test('never throwing lets the runner home three times', () {
      final game = DirectHitGame(random: math.Random(6));
      runUntil(game, () => game.phase == DirectHitPhase.safe);
      expect(game.lives, 2);
      expect(game.runnerProgress, 1);
      runUntil(game, () => game.isOver, limit: 120);
      expect(game.lives, 0);
      expect(game.score, 0);
      expect(game.round, 3);
    });

    test('the preview follows the throw it shows', () {
      final game = DirectHitGame(random: math.Random(6));
      final path = game.previewPath(0.1, 0.5);
      expect(path, isNotEmpty);
      expect(path.first.z, greaterThan(DirectHitGame.release.z));
      expect(path.last.z, lessThanOrEqualTo(game.stumps.z));
      game.throwBall(0.1, 0.5);
      game.update(1 / 30);
      expect(game.ball!.distanceTo(path.first), lessThan(0.05));
    });

    test('the runner gets quicker each round', () {
      final game = DirectHitGame(random: math.Random(6));
      var time = 0.0;
      final times = <double>[];
      var round = 1;
      while (!game.isOver) {
        game.update(_frame);
        time += _frame;
        if (game.phase == DirectHitPhase.safe && times.length < round) {
          times.add(time);
        }
        if (game.round != round) {
          round = game.round;
          time = 0;
        }
      }
      expect(times, hasLength(3));
      expect(times[1], lessThan(times[0]));
      expect(times[2], lessThan(times[1]));
    });
  });

  group('LaneRunnerGame', () {
    /// Steers into whichever lane has no obstacle in the next row.
    void steer(LaneRunnerGame game) {
      // Wait for the row alongside to pass before moving for the next.
      final ahead = game.items.where((item) => item.y > -1).toList();
      if (ahead.isEmpty) return;
      final rowY = ahead.map((item) => item.y).reduce(math.min);
      final row = ahead.where((item) => (item.y - rowY).abs() < 1);
      final blocked = {
        for (final item in row)
          if (item.kind.isObstacle) item.lane,
      };
      if (!blocked.contains(game.lane)) return;
      final clear = [
        for (var lane = 0; lane < LaneRunnerGame.lanes; lane++)
          if (!blocked.contains(lane)) lane,
      ]..sort((a, b) => (a - game.lane).abs().compareTo((b - game.lane).abs()));
      if (clear.first < game.lane) {
        game.moveLeft();
      } else {
        game.moveRight();
      }
    }

    test('starts in the middle lane and cannot leave the gully', () {
      final game = LaneRunnerGame(random: math.Random(1));
      expect(game.lane, 1);
      game
        ..moveLeft()
        ..moveLeft()
        ..moveLeft();
      expect(game.lane, 0);
      game
        ..moveRight()
        ..moveRight()
        ..moveRight();
      expect(game.lane, 2);
    });

    test('the runner slides between lanes', () {
      final game = LaneRunnerGame(random: math.Random(1))..moveRight();
      game.update(_frame);
      expect(game.playerX, inExclusiveRange(1, 2));
      game.update(0.5);
      expect(game.playerX, 2);
    });

    test('there is always a way through', () {
      final game = LaneRunnerGame(random: math.Random(8));
      for (var i = 0; i < 60 * 90; i++) {
        steer(game);
        game.update(_frame);
      }
      expect(game.lives, 3, reason: 'a careful runner is never forced to bump');
      expect(game.distance, greaterThan(900));
      expect(game.speed, LaneRunnerGame.topSpeed);
      expect(game.score, greaterThan(200));
    });

    test('running straight ends in three bumps', () {
      final game = LaneRunnerGame(random: math.Random(8));
      runUntil(game, () => game.isOver, limit: 600);
      expect(game.lives, 0);
      final distance = game.distance;
      game.update(1);
      expect(game.distance, distance);
    });

    test('a bump shields the runner for a moment', () {
      final game = LaneRunnerGame(random: math.Random(8));
      runUntil(game, () => game.lives == 2, limit: 600);
      expect(game.isShielded, isTrue);
      game.update(1.3);
      expect(game.isShielded, isFalse);
    });

    test('collecting a ball adds to the score', () {
      final game = LaneRunnerGame(random: math.Random(8));
      for (var i = 0; i < 60 * 60 && game.ballsCollected == 0; i++) {
        final ball = game.items
            .where((item) => !item.kind.isObstacle && item.y > 0)
            .firstOrNull;
        if (ball != null && ball.y < 6) {
          if (ball.lane < game.lane) game.moveLeft();
          if (ball.lane > game.lane) game.moveRight();
        } else {
          steer(game);
        }
        game.update(_frame);
      }
      expect(game.ballsCollected, 1);
      expect(
        game.score,
        (game.distance / 4).floor() + LaneRunnerGame.ballPoints,
      );
    });
  });
}
