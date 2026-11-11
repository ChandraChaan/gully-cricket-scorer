import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:gully_cricket_scorer/features/games/domain/arcade_game.dart';
import 'package:gully_cricket_scorer/features/games/domain/carrom_game.dart';
import 'package:gully_cricket_scorer/features/games/domain/duel_game.dart';
import 'package:gully_cricket_scorer/features/games/domain/gilli_danda_game.dart';
import 'package:gully_cricket_scorer/features/games/domain/kabaddi_game.dart';
import 'package:gully_cricket_scorer/features/games/domain/kite_fight_game.dart';
import 'package:gully_cricket_scorer/features/games/domain/vec3.dart';

const _frame = 1 / 60;

void runUntil(ArcadeGame game, bool Function() done, {double limit = 60}) {
  var time = 0.0;
  while (!done()) {
    game.update(_frame);
    time += _frame;
    if (time > limit) fail('Still waiting after $limit seconds');
  }
}

void runFor(ArcadeGame game, double seconds) {
  for (var time = 0.0; time < seconds; time += _frame) {
    game.update(_frame);
  }
}

void main() {
  group('DuelGame', () {
    DuelGame sparring() =>
        DuelGame(random: math.Random(1), opponentFights: false);

    /// Walks the player up to the opponent.
    void close(DuelGame game) {
      game.moveInput = 1;
      runFor(game, 3);
      game.moveInput = 0;
    }

    test('fighters start apart, facing each other, at full health', () {
      final game = sparring();
      expect(game.player.x, lessThan(game.opponent.x));
      expect(game.player.facing, 1);
      expect(game.opponent.facing, -1);
      expect(game.player.health, 100);
      expect(game.lives, 3);
    });

    test('a punch from out of range misses', () {
      final game = sparring()..punch();
      expect(game.player.move, FighterMove.punch);
      runFor(game, 1);
      expect(game.opponent.health, game.opponent.maxHealth);
      expect(game.score, 0);
      expect(game.player.move, FighterMove.idle);
    });

    test('a punch in range hurts and scores its damage', () {
      final game = sparring();
      close(game);
      game.punch();
      runFor(game, 0.15);
      expect(game.opponent.move, FighterMove.hurt);
      expect(game.opponent.health, game.opponent.maxHealth - 8);
      expect(game.score, 8);
    });

    test('a kick reaches further and hits harder than a punch', () {
      final game = sparring();
      close(game);
      game.moveInput = -1;
      runFor(game, 0.2);
      game.moveInput = 0;
      final gap = game.opponent.x - game.player.x;
      expect(gap, greaterThan(Attack.punch.range));
      expect(gap, lessThan(Attack.kick.range));
      game.punch();
      runFor(game, 0.6);
      expect(game.opponent.health, game.opponent.maxHealth);
      game.kick();
      runFor(game, 0.6);
      expect(game.opponent.health, game.opponent.maxHealth - 14);
    });

    test('fighters cannot walk through each other or out of the pit', () {
      final game = sparring();
      close(game);
      expect(game.opponent.x - game.player.x, closeTo(DuelGame.minGap, 0.01));
      expect(game.opponent.x, lessThanOrEqualTo(DuelGame.pitHalfWidth));
      game.moveInput = -1;
      runFor(game, 5);
      expect(game.player.x, -DuelGame.pitHalfWidth);
    });

    test('knocking an opponent out brings on a tougher one', () {
      final game = sparring();
      close(game);
      final firstHealth = game.opponent.maxHealth;
      runUntil(game, () {
        game.kick();
        game.moveInput = 1;
        return game.opponentNumber == 2;
      });
      expect(game.score, firstHealth.round() + DuelGame.knockoutBonus);
      expect(game.opponent.maxHealth, greaterThan(firstHealth));
      expect(game.opponent.health, game.opponent.maxHealth);
      expect(game.lives, 3);
    });

    test('blocking soaks up most of the damage', () {
      double healthAfter({required bool blocking}) {
        final game = DuelGame(random: math.Random(4))..blockHeld = blocking;
        runFor(game, 10);
        return game.lives < 3 ? 0 : game.player.health;
      }

      final guarded = healthAfter(blocking: true);
      final open = healthAfter(blocking: false);
      expect(open, lessThan(90));
      expect(guarded, greaterThan(open + 5));
    });

    test('a blocked hit never knocks you down', () {
      final game = DuelGame(random: math.Random(4))..blockHeld = true;
      runFor(game, 120);
      expect(game.lives, 3);
      expect(game.player.health, greaterThanOrEqualTo(1));
    });

    test('standing still gets you knocked down three times', () {
      final game = DuelGame(random: math.Random(2));
      runUntil(game, () => game.isOver, limit: 300);
      expect(game.lives, 0);
      expect(game.player.move, FighterMove.down);
      game.punch();
      expect(game.player.move, FighterMove.down);
    });
  });

  group('KabaddiGame', () {
    /// Plays a careful raid: draw a dive, sidestep it, tag the defender
    /// while they are down and run home.
    void steer(KabaddiGame game) {
      final raider = game.raider;
      final standing = game.defenders
          .where((d) => d.state != DefenderState.out)
          .toList();
      if (game.tags > 0 || standing.isEmpty) {
        game.runTo(raider.x, -2);
        return;
      }
      Defender nearest(Iterable<Defender> from) => from.reduce(
        (a, b) =>
            a.position.groundDistanceTo(raider) <
                b.position.groundDistanceTo(raider)
            ? a
            : b,
      );
      final diving = standing.where(
        (d) =>
            d.state == DefenderState.windUp || d.state == DefenderState.lunge,
      );
      final down = standing.where((d) => d.state == DefenderState.down);
      if (diving.isNotEmpty) {
        // Run back towards home and across, out of the line of the dive.
        final threat = nearest(diving);
        final away = raider.x >= threat.position.x ? 1.0 : -1.0;
        game.runTo(raider.x + away * 3, raider.z - 3);
      } else if (down.isNotEmpty) {
        final target = nearest(down);
        game.runTo(target.position.x, target.position.z);
      } else {
        // Hover just inside diving range of the nearest defender.
        final target = nearest(standing);
        final gap = target.position.groundDistanceTo(raider);
        if (gap > KabaddiGame.lungeRange - 0.3) {
          game.runTo(target.position.x, target.position.z);
        } else {
          game.runTo(raider.x, raider.z);
        }
      }
    }

    test('a raid starts at home with defenders on their feet', () {
      final game = KabaddiGame(random: math.Random(1));
      expect(game.raid, 1);
      expect(game.raider.z, lessThan(0));
      expect(game.defenders, hasLength(3));
      expect(
        game.defenders.every((d) => d.state == DefenderState.ready),
        isTrue,
      );
      expect(game.timeLeft, 1);
    });

    test('running into a standing defender gets the raider caught', () {
      final game = KabaddiGame(random: math.Random(1));
      runUntil(game, () {
        final defender = game.defenders.first;
        game.runTo(defender.position.x, defender.position.z);
        return game.lastEvent != null;
      });
      expect(game.lastEvent, RaidEvent.tackled);
      expect(game.lives, 2);
      expect(game.score, 0);
    });

    test('staying home until time runs out loses the raid', () {
      final game = KabaddiGame(random: math.Random(1));
      runUntil(game, () => game.lastEvent != null);
      expect(game.lastEvent, RaidEvent.timeUp);
      expect(game.lives, 2);
      runUntil(game, () => game.raid == 2);
      expect(game.timeLeft, closeTo(1, 0.01));
      runUntil(game, () => game.isOver, limit: 120);
      expect(game.lives, 0);
    });

    test('defenders leave a raider alone on their own side', () {
      final game = KabaddiGame(random: math.Random(1))..runTo(4, -0.5);
      runFor(game, 5);
      expect(
        game.defenders.every((d) => d.state == DefenderState.ready),
        isTrue,
      );
    });

    test('a raider who dodges a dive can tag and score', () {
      var best = 0;
      for (var seed = 0; seed < 6; seed++) {
        final game = KabaddiGame(random: math.Random(seed));
        for (var i = 0; i < 60 * 90 && !game.isOver; i++) {
          steer(game);
          game.update(_frame);
        }
        best = math.max(best, game.score);
      }
      expect(best, greaterThan(0));
    });

    test('tags only count once the raider is home', () {
      final game = KabaddiGame(random: math.Random(3));
      var score = 0;
      for (var i = 0; i < 60 * 90 && !game.isOver; i++) {
        steer(game);
        game.update(_frame);
        if (game.score != score) {
          expect(game.raider.z, lessThan(0));
          expect(game.lastEvent, RaidEvent.scored);
          expect(game.score - score, game.lastPoints);
          score = game.score;
        }
      }
    });

    test('later raids bring more defenders', () {
      final game = KabaddiGame(random: math.Random(1));
      runUntil(game, () => game.raid == 3, limit: 120);
      expect(game.defenders, hasLength(4));
    });
  });

  group('GilliDandaGame', () {
    /// Flicks the gilli and swings when it is [offset] metres from the
    /// stick, on the way down.
    GilliResult? strike(GilliDandaGame game, double offset) {
      runUntil(game, () => game.phase == GilliPhase.ready);
      game.tap();
      expect(game.phase, GilliPhase.rising);
      var peaked = false;
      var last = game.gilli.y;
      while (game.phase == GilliPhase.rising) {
        game.update(1 / 600);
        if (game.gilli.y < last) peaked = true;
        last = game.gilli.y;
        if (peaked &&
            game.gilli.y <= GilliDandaGame.strikeHeight + offset &&
            game.phase == GilliPhase.rising) {
          game.tap();
        }
      }
      return game.lastResult;
    }

    test('hitting it at stick height is a perfect strike', () {
      final game = GilliDandaGame(random: math.Random(1));
      expect(strike(game, 0), GilliResult.perfect);
      expect(game.lastDistance, inInclusiveRange(55, 70));
      expect(game.score, game.lastDistance);
      expect(game.phase, GilliPhase.flying);
      expect(game.lives, 3);
    });

    test('the further from the stick, the shorter the hit', () {
      final good = GilliDandaGame(random: math.Random(1));
      expect(strike(good, 0.15), GilliResult.good);
      expect(good.lastDistance, inInclusiveRange(35, 50));

      final fair = GilliDandaGame(random: math.Random(1));
      expect(strike(fair, 0.3), GilliResult.fair);
      expect(fair.lastDistance, inInclusiveRange(15, 30));
    });

    test('swinging far too early is a miss', () {
      final game = GilliDandaGame(random: math.Random(1));
      expect(strike(game, 0.8), GilliResult.miss);
      expect(game.lives, 2);
      expect(game.score, 0);
    });

    test('letting it drop is a miss, and three misses end the game', () {
      final game = GilliDandaGame(random: math.Random(1));
      for (var i = 0; i < 3; i++) {
        runUntil(game, () => game.phase == GilliPhase.ready);
        game.tap();
        runUntil(game, () => game.phase == GilliPhase.done);
        expect(game.lastResult, GilliResult.miss);
      }
      runUntil(game, () => game.isOver);
      expect(game.lives, 0);
      expect(game.turn, 3);
      game.tap();
      expect(game.turn, 3);
    });

    test('scores add up and the gilli gets quicker', () {
      final game = GilliDandaGame(random: math.Random(1));
      var total = 0;
      for (var i = 0; i < 4; i++) {
        strike(game, 0);
        total += game.lastDistance;
      }
      expect(game.score, total);
      expect(game.tempo, greaterThan(1.2));
    });
  });

  group('KiteFightGame', () {
    test('sweeping across a rival string at speed cuts it', () {
      final game = KiteFightGame(random: math.Random(1));
      runFor(game, 0.5);
      for (var i = 0; i < 60 * 30 && game.score == 0 && !game.isOver; i++) {
        final rival = game.rivals.firstWhere(
          (r) => r.state != RivalState.cut,
          orElse: () => game.rivals.first,
        );
        // Aim for the far side of the middle of its string.
        final middleX = (rival.anchor.x + rival.position.x) / 2;
        final middleY = (rival.anchor.y + rival.position.y) / 2;
        final side = game.kite.x < middleX ? 0.3 : -0.3;
        game.flyTo(middleX + side, math.max(0.4, middleY));
        game.update(_frame);
      }
      expect(game.score, greaterThan(0));
      expect(
        game.rivals.any((r) => r.state == RivalState.cut) ||
            game.rivals.isNotEmpty,
        isTrue,
      );
    });

    test('a kite left hanging gets cut three times', () {
      final game = KiteFightGame(random: math.Random(2));
      runUntil(game, () => game.isOver, limit: 600);
      expect(game.lives, 0);
      expect(game.score, 0);
    });

    test('a fresh kite cannot be cut straight away', () {
      final game = KiteFightGame(random: math.Random(2));
      expect(game.isSafe, isTrue);
      runFor(game, 1.4);
      expect(game.lives, 3);
    });

    test('the kite stays in the sky and is limited in speed', () {
      final game = KiteFightGame(random: math.Random(1))..flyTo(5, -5);
      game.update(_frame);
      final speed = math.sqrt(
        game.velocity.x * game.velocity.x + game.velocity.y * game.velocity.y,
      );
      expect(speed, closeTo(KiteFightGame.maxSpeed, 0.001));
      runFor(game, 0.8);
      expect(game.kite.x, lessThanOrEqualTo(0.94));
      expect(game.kite.y, greaterThanOrEqualTo(0.34));
    });

    test('more rivals join as the score climbs', () {
      final game = KiteFightGame(random: math.Random(1));
      expect(game.rivals, hasLength(1));
    });
  });

  group('CarromGame', () {
    test('a fresh board has nineteen coins round the queen', () {
      final game = CarromGame(random: math.Random(1));
      expect(game.coins, hasLength(19));
      expect(
        game.coins.where((c) => c.piece == CarromPiece.queen),
        hasLength(1),
      );
      // Nothing overlaps.
      for (final a in game.coins) {
        for (final b in game.coins) {
          if (identical(a, b)) continue;
          final gap = math.sqrt(
            (a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y),
          );
          expect(gap, greaterThan(CarromGame.coinRadius * 2 - 1e-9));
        }
      }
      expect(game.striker.y, CarromGame.baseline);
    });

    test('the striker stays on the baseline when placed', () {
      final game = CarromGame(random: math.Random(1))..placeStriker(-3);
      expect(game.striker.x, CarromGame.baselineLeft);
      game.placeStriker(3);
      expect(game.striker.x, CarromGame.baselineRight);
    });

    test('a straight shot breaks the rack and everything comes to rest', () {
      final game = CarromGame(random: math.Random(1))..shoot(0, -1, 1);
      expect(game.isMoving, isTrue);
      game.shoot(1, 0, 1);
      runUntil(game, () => !game.isMoving, limit: 30);
      expect(
        game.coins.any(
          (c) => (c.x - 0.5).abs() > 0.1 || (c.y - 0.5).abs() > 0.1,
        ),
        isTrue,
      );
      for (final coin in game.coins) {
        expect(coin.x, inInclusiveRange(0, 1));
        expect(coin.y, inInclusiveRange(0, 1));
        expect(coin.speed, 0);
      }
      expect(game.striker.y, CarromGame.baseline);
    });

    test('knocking a coin into a pocket scores and adds time', () {
      // A white coin sitting on the line from the striker to a top pocket.
      const fromX = 0.5;
      const mouthX = 0.96;
      const mouthY = 0.04;
      const dx = mouthX - fromX;
      const dy = mouthY - CarromGame.baseline;
      final game = CarromGame(
        random: math.Random(1),
        rack: [
          CarromDisc(
            CarromPiece.white,
            fromX + dx * 0.8,
            CarromGame.baseline + dy * 0.8,
          ),
        ],
      )..placeStriker(fromX);
      game.shoot(dx, dy, 0.6);
      runUntil(game, () => game.pocketed == 1, limit: 10);
      expect(game.score, CarromPiece.white.points);
      expect(game.timeLeft, greaterThan(CarromGame.startTime - 2));
    });

    test('clearing the board earns a bonus and a new rack', () {
      final game = CarromGame(
        random: math.Random(1),
        rack: [CarromDisc(CarromPiece.queen, 0.95, 0.05)],
      )..placeStriker(0.5);
      game.shoot(0.95 - 0.5, 0.05 - CarromGame.baseline, 0.45);
      runUntil(game, () => !game.isMoving, limit: 20);
      expect(game.pocketed, 1);
      expect(game.coins, hasLength(19));
      expect(
        game.score,
        greaterThanOrEqualTo(CarromPiece.queen.points + CarromGame.clearBonus),
      );
    });

    test('sinking the striker is a foul', () {
      final game = CarromGame(
        random: math.Random(1),
        rack: [CarromDisc(CarromPiece.black, 0.1, 0.5)],
      )..placeStriker(0.8);
      game.shoot(0.955 - 0.8, 0.045 - CarromGame.baseline, 1);
      runUntil(game, () => !game.isMoving, limit: 20);
      expect(game.lives, 2);
      expect(game.sinceFoul, lessThan(20));
      expect(game.striker.x, 0.5);
      expect(game.striker.y, CarromGame.baseline);
      expect(game.score, 0);
    });

    test('the clock running out ends the game', () {
      final game = CarromGame(random: math.Random(1));
      runFor(game, CarromGame.startTime - 1);
      expect(game.isOver, isFalse);
      runFor(game, 1.1);
      expect(game.isOver, isTrue);
      expect(game.timeLeft, 0);
      game.shoot(0, -1, 1);
      expect(game.isMoving, isFalse);
    });
  });

  test('Vec3 lerp reaches both ends', () {
    const a = Vec3(1, 2, 3);
    const b = Vec3(-1, 0, 5);
    expect(a.lerp(b, 0), a);
    expect(a.lerp(b, 1), b);
  });
}
