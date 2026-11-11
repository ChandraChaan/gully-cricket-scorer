import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gully_cricket_scorer/core/router.dart';
import 'package:gully_cricket_scorer/features/games/domain/arcade_game.dart';
import 'package:gully_cricket_scorer/features/games/domain/best_scores_repository.dart';
import 'package:gully_cricket_scorer/features/games/presentation/best_scores_controller.dart';

import '../../helpers.dart';

/// Games animate for ever, so step time by hand instead of settling.
Future<void> play(WidgetTester tester, double seconds) async {
  for (var t = 0.0; t < seconds; t += 0.05) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

int hudScore(WidgetTester tester) =>
    int.parse(tester.widget<Text>(find.byKey(const Key('gameScore'))).data!);

void main() {
  testWidgets('the app opens on the games hub', (tester) async {
    await pumpApp(tester, location: '/');
    expect(find.text('Gully Games'), findsOneWidget);
    expect(find.text('Street games'), findsOneWidget);
    expect(find.text('Akhada Duel'), findsOneWidget);
    expect(find.text('Kabaddi Raid'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Cricket scorer'), 300);
    expect(find.text('Gully Batting'), findsOneWidget);
  });

  testWidgets('the hub opens the cricket scorer, and back returns to it', (
    tester,
  ) async {
    await pumpApp(tester, location: '/');
    await tapKey(tester, 'openScorer');
    expect(find.byKey(const Key('newMatch')), findsOneWidget);
    expect(find.text('No matches yet'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('openScorer')), findsOneWidget);
  });

  testWidgets('old links still reach the scorer and the hub', (tester) async {
    final container = await pumpApp(tester, location: '/new');
    expect(find.text('New match'), findsWidgets);
    expect(container.read(routerProvider).state.uri.path, '/scorer/new');
    container.read(routerProvider).go('/games');
    await tester.pumpAndSettle();
    expect(find.text('Street games'), findsOneWidget);
  });

  testWidgets('the list shows best scores', (tester) async {
    await pumpApp(
      tester,
      bestScores: FakeBestScoresRepository({GameId.duel: 42}),
      location: '/',
    );
    expect(find.text('Best: 42'), findsOneWidget);
  });

  testWidgets('the list still works when best scores cannot be read', (
    tester,
  ) async {
    await pumpApp(
      tester,
      bestScores: FakeBestScoresRepository()
        ..failWith = const BestScoreStorageException('nope'),
      location: '/',
    );
    expect(find.text('Akhada Duel'), findsOneWidget);
    expect(find.textContaining('Best:'), findsNothing);
  });

  for (final (id, title) in [
    (GameId.batting, 'Gully Batting'),
    (GameId.catching, 'High Catch'),
    (GameId.directHit, 'Direct Hit'),
    (GameId.laneRunner, 'Gully Dash'),
    (GameId.duel, 'Akhada Duel'),
    (GameId.kabaddi, 'Kabaddi Raid'),
    (GameId.gilliDanda, 'Gilli Danda'),
    (GameId.kiteFight, 'Kite Fight'),
    (GameId.carrom, 'Carrom Strike'),
  ]) {
    testWidgets('$title opens from the list, runs, pauses and resumes', (
      tester,
    ) async {
      await pumpApp(tester, location: '/');
      await tapKey(tester, 'game-${id.key}');
      expect(find.text(title), findsOneWidget);
      expect(find.byKey(const Key('startGame')), findsOneWidget);
      expect(find.byKey(const Key('pauseGame')), findsNothing);

      await tester.tap(find.byKey(const Key('startGame')));
      await play(tester, 3);
      expect(find.byKey(const Key('startGame')), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('pauseGame')));
      await tester.pumpAndSettle();
      expect(find.text('Paused'), findsOneWidget);

      await tester.tap(find.byKey(const Key('resumeGame')));
      await play(tester, 1);
      expect(find.text('Paused'), findsNothing);

      await tester.tap(find.byTooltip('Back to games'));
      await tester.pumpAndSettle();
      expect(find.text('Gully Games'), findsOneWidget);
    });
  }

  testWidgets('Gully Dash ends after three bumps and saves a best score', (
    tester,
  ) async {
    final bestScores = FakeBestScoresRepository();
    final container = await pumpApp(
      tester,
      bestScores: bestScores,
      location: '/games/gully-dash',
    );
    await tester.tap(find.byKey(const Key('startGame')));
    await tester.pump();

    // Dodge once each way, then run straight into things.
    final field = tester.getRect(find.byKey(const Key('dashField')));
    await tester.tapAt(field.centerLeft + const Offset(20, 0));
    await tester.tapAt(field.centerRight - const Offset(20, 0));
    for (var i = 0; i < 200 && find.text('Game over').evaluate().isEmpty; i++) {
      await play(tester, 1);
    }
    await tester.pumpAndSettle();

    expect(find.text('Game over'), findsOneWidget);
    expect(find.text('New best score!'), findsOneWidget);
    final score = int.parse(
      tester.widget<Text>(find.byKey(const Key('finalScore'))).data!,
    );
    expect(score, greaterThan(0));
    expect(bestScores.scores[GameId.laneRunner], score);
    expect(container.read(bestScoresProvider).value?[GameId.laneRunner], score);

    await tester.tap(find.byKey(const Key('playAgain')));
    await play(tester, 0.5);
    expect(find.text('Game over'), findsNothing);
    expect(hudScore(tester), lessThan(score));
  });

  testWidgets('a lower score does not replace the best', (tester) async {
    final bestScores = FakeBestScoresRepository({GameId.laneRunner: 100000});
    await pumpApp(
      tester,
      bestScores: bestScores,
      location: '/games/gully-dash',
    );
    expect(find.text('Best: 100000'), findsOneWidget);
    await tester.tap(find.byKey(const Key('startGame')));
    for (var i = 0; i < 200 && find.text('Game over').evaluate().isEmpty; i++) {
      await play(tester, 1);
    }
    await tester.pumpAndSettle();
    expect(find.text('New best score!'), findsNothing);
    expect(find.text('Best: 100000'), findsOneWidget);
    expect(bestScores.scores[GameId.laneRunner], 100000);
  });

  testWidgets('batting buttons swing the bat', (tester) async {
    await pumpApp(tester, location: '/games/batting');
    await tester.tap(find.byKey(const Key('startGame')));
    // Swing at everything as it arrives: sooner or later bat meets ball or
    // the stumps go, and either way the game carries on without errors.
    for (var i = 0; i < 400; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (i % 3 == 0) {
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(const Key('shotStraight'))),
        );
        await gesture.up();
      }
    }
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('gameScore')), findsOneWidget);
  });

  testWidgets('dragging in High Catch sends the fielder running', (
    tester,
  ) async {
    await pumpApp(tester, location: '/games/catching');
    await tester.tap(find.byKey(const Key('startGame')));
    await play(tester, 0.5);
    final field = tester.getRect(find.byKey(const Key('catchingField')));
    final gesture = await tester.startGesture(field.center);
    await play(tester, 0.5);
    await gesture.moveTo(field.center + const Offset(80, 60));
    await play(tester, 2);
    await gesture.up();
    await play(tester, 6);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dragging up and letting go throws in Direct Hit', (
    tester,
  ) async {
    await pumpApp(tester, location: '/games/direct-hit');
    await tester.tap(find.byKey(const Key('startGame')));
    await play(tester, 0.3);
    final field = tester.getRect(find.byKey(const Key('directHitField')));
    for (var attempt = 0; attempt < 6; attempt++) {
      final gesture = await tester.startGesture(field.center);
      await gesture.moveBy(Offset(attempt * 8 - 20, -60.0 - attempt * 25));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await play(tester, 1.5);
    }
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('gameScore')), findsOneWidget);
  });

  testWidgets('leaving a game mid-play stops it cleanly', (tester) async {
    final container = await pumpApp(tester, location: '/games/batting');
    await tester.tap(find.byKey(const Key('startGame')));
    await play(tester, 1);
    container.read(routerProvider).go('/scorer');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('newMatch')), findsOneWidget);
  });

  testWidgets('Akhada Duel buttons move and fight', (tester) async {
    await pumpApp(tester, location: '/games/akhada-duel');
    await tester.tap(find.byKey(const Key('startGame')));
    await play(tester, 0.2);
    final forward = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('duelRight'))),
    );
    await play(tester, 1.5);
    await forward.up();
    for (var i = 0; i < 40; i++) {
      final key = i.isEven ? 'duelPunch' : 'duelKick';
      final press = await tester.startGesture(
        tester.getCenter(find.byKey(Key(key))),
      );
      await press.up();
      await play(tester, 0.5);
    }
    final block = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('duelBlock'))),
    );
    await play(tester, 1);
    await block.up();
    expect(tester.takeException(), isNull);
    expect(hudScore(tester), greaterThan(0));
  });

  testWidgets('touching the mat sends the kabaddi raider running', (
    tester,
  ) async {
    await pumpApp(tester, location: '/games/kabaddi-raid');
    await tester.tap(find.byKey(const Key('startGame')));
    await play(tester, 0.3);
    final field = tester.getRect(find.byKey(const Key('kabaddiField')));
    final touch = await tester.startGesture(field.center);
    await play(tester, 3);
    await touch.moveTo(field.center + const Offset(60, 120));
    await play(tester, 3);
    await touch.up();
    await play(tester, 12);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('gameScore')), findsOneWidget);
  });

  testWidgets('tapping flicks and swings in Gilli Danda', (tester) async {
    await pumpApp(tester, location: '/games/gilli-danda');
    await tester.tap(find.byKey(const Key('startGame')));
    await play(tester, 0.2);
    expect(find.text('Tap to flick'), findsOneWidget);
    final field = tester.getCenter(find.byKey(const Key('gilliField')));
    await tester.tapAt(field);
    await play(tester, 0.1);
    expect(find.text('Tap to hit!'), findsOneWidget);
    for (var i = 0; i < 30; i++) {
      await tester.tapAt(field);
      await play(tester, 0.45);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('dragging flies the kite', (tester) async {
    await pumpApp(tester, location: '/games/kite-fight');
    await tester.tap(find.byKey(const Key('startGame')));
    await play(tester, 0.3);
    final field = tester.getRect(find.byKey(const Key('kiteField')));
    final touch = await tester.startGesture(field.center);
    for (var i = 0; i < 20; i++) {
      await touch.moveTo(
        field.center + Offset(i.isEven ? -120 : 120, -100.0 + i * 8),
      );
      await play(tester, 0.4);
    }
    await touch.up();
    expect(tester.takeException(), isNull);
  });

  testWidgets('pulling back and letting go shoots the carrom striker', (
    tester,
  ) async {
    await pumpApp(tester, location: '/games/carrom-strike');
    await tester.tap(find.byKey(const Key('startGame')));
    await play(tester, 0.3);
    expect(find.text('60 s'), findsOneWidget);
    final field = tester.getRect(find.byKey(const Key('carromField')));
    for (var shot = 0; shot < 4; shot++) {
      final pull = await tester.startGesture(
        field.center + const Offset(0, 150),
      );
      await pull.moveBy(Offset(shot * 10.0 - 15, 90));
      await tester.pump(const Duration(milliseconds: 50));
      await pull.up();
      await play(tester, 6);
    }
    expect(tester.takeException(), isNull);
    expect(find.text('60 s'), findsNothing);
  });
}
