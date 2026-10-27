import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gully_cricket_scorer/features/match/domain/match_event.dart';
import 'package:gully_cricket_scorer/features/match/domain/match_repository.dart';

import '../helpers.dart';

const open = InningsStarted(striker: 0, nonStriker: 1, bowler: 0);
const dot = BallBowled.runs(0);

void main() {
  group('new match', () {
    testWidgets('setup creates a match and opens the openers picker', (
      tester,
    ) async {
      final repository = FakeMatchRepository();
      await pumpApp(tester, repository: repository);

      await tapKey(tester, 'newMatch');
      await tester.enterText(find.byKey(const Key('teamName-0')), 'Lions');
      await tester.enterText(find.byKey(const Key('overs')), '2');
      await tester.enterText(find.byKey(const Key('players')), '4');
      await tapKey(tester, 'lastManStands');
      await tapKey(tester, 'startMatch');

      expect(find.text('Lions v Team B'), findsOneWidget);
      expect(find.text('Lions to bat'), findsOneWidget);
      final saved = (await repository.fetchAll()).single;
      expect(saved.setup.rules.oversPerInnings, 2);
      expect(saved.setup.rules.playersPerSide, 4);
      expect(saved.setup.rules.lastManStands, isTrue);
      expect(saved.setup.teams[0].players, [
        'Player 1',
        'Player 2',
        'Player 3',
        'Player 4',
      ]);
    });

    testWidgets('setup rejects zero overs', (tester) async {
      final repository = FakeMatchRepository();
      await pumpApp(tester, repository: repository, location: '/new');

      await tester.enterText(find.byKey(const Key('overs')), '0');
      await tapKey(tester, 'startMatch');

      expect(find.text('Enter 1 to 99 overs'), findsOneWidget);
      expect(await repository.fetchAll(), isEmpty);
    });

    testWidgets('openers must be two different batters', (tester) async {
      await pumpApp(
        tester,
        repository: FakeMatchRepository([savedMatch(testSetup())]),
        location: '/match/m1',
      );

      await tapKey(tester, 'pick-nonStriker');
      await tester.tap(find.text('Lion 1').last);
      await tester.pumpAndSettle();

      expect(find.text('Pick two different batters'), findsOneWidget);
      final start = tester.widget<FilledButton>(
        find.byKey(const Key('startInnings')),
      );
      expect(start.onPressed, isNull);
    });
  });

  group('scoring', () {
    Future<FakeMatchRepository> startedMatch(
      WidgetTester tester, {
      int players = 3,
      List<MatchEvent> events = const [open],
    }) async {
      final repository = FakeMatchRepository([
        savedMatch(testSetup(players: players), events),
      ]);
      await pumpApp(tester, repository: repository, location: '/match/m1');
      return repository;
    }

    testWidgets('opening the innings shows the scoreboard', (tester) async {
      final repository = await startedMatch(tester, events: const []);

      await tapKey(tester, 'startInnings');

      expect(scoreText(tester), '0/0');
      expect(find.text('Lion 1 *'), findsOneWidget);
      expect(find.text('Lion 2'), findsOneWidget);
      expect(find.text('Tiger 1'), findsOneWidget);
      expect(repository['m1']!.events, [open]);
    });

    testWidgets('runs add up, strike rotates and every ball is saved', (
      tester,
    ) async {
      final repository = await startedMatch(tester);

      await tapKey(tester, 'runs-4');
      expect(scoreText(tester), '4/0');
      await tapKey(tester, 'runs-1');
      expect(scoreText(tester), '5/0');
      expect(find.text('Lion 2 *'), findsOneWidget);
      expect(find.text('5 (2)'), findsOneWidget);
      expect(find.text('0 (0)'), findsOneWidget);
      expect(repository['m1']!.events, hasLength(3));
    });

    testWidgets('undo takes back balls one at a time', (tester) async {
      final repository = await startedMatch(tester);

      await tapKey(tester, 'runs-6');
      await tapKey(tester, 'runs-2');
      await tapKey(tester, 'undo');
      expect(scoreText(tester), '6/0');
      await tapKey(tester, 'undo');
      expect(scoreText(tester), '0/0');
      expect(repository['m1']!.events, [open]);
    });

    testWidgets('a wide asks for runs and is not a legal ball', (tester) async {
      await startedMatch(tester);

      await tapKey(tester, 'extra-wide');
      expect(find.text('Wide: runs taken'), findsOneWidget);
      await tapKey(tester, 'sheet-runs-0');

      expect(scoreText(tester), '1/0');
      expect(find.text('0 of 1 overs'), findsOneWidget);
      expect(find.text('Wd'), findsOneWidget);
    });

    testWidgets('a no-ball sets up a free hit', (tester) async {
      await startedMatch(tester);

      await tapKey(tester, 'extra-noBall');
      await tapKey(tester, 'sheet-runs-4');

      expect(scoreText(tester), '5/0');
      expect(find.text('Free hit'), findsOneWidget);

      await tapKey(tester, 'wicket');
      expect(find.byKey(const Key('how-bowled')), findsNothing);
      expect(find.byKey(const Key('how-runOut')), findsOneWidget);
    });

    testWidgets('a wicket asks who comes in next', (tester) async {
      await startedMatch(tester);

      await tapKey(tester, 'wicket');
      await tapKey(tester, 'how-caught');

      expect(find.text('Who comes in?'), findsOneWidget);
      expect(scoreText(tester), '0/1');
      await tapKey(tester, 'pick-player-2');
      expect(find.text('Lion 3 *'), findsOneWidget);
    });

    testWidgets('run out of the non-striker after a run', (tester) async {
      await startedMatch(tester);

      await tapKey(tester, 'wicket');
      await tapKey(tester, 'how-runOut');
      await tapOn(tester, find.byKey(const Key('runout-nonStriker')));
      await tapOn(tester, find.text('1').last);
      await tapKey(tester, 'runout-confirm');

      expect(scoreText(tester), '1/1');
      expect(find.text('Who comes in?'), findsOneWidget);
    });

    testWidgets('the over ends after six balls and asks for a new bowler', (
      tester,
    ) async {
      final setup = testSetup(players: 3);
      final repository = FakeMatchRepository([
        savedMatch(testSetup(id: setup.id, overs: 2, players: 3), [
          open,
          dot,
          dot,
          dot,
          dot,
          dot,
        ]),
      ]);
      await pumpApp(tester, repository: repository, location: '/match/m1');

      await tapKey(tester, 'runs-1');

      expect(find.text('Over 2: who bowls?'), findsOneWidget);
      expect(find.byKey(const Key('pick-player-0')), findsNothing);
      await tapKey(tester, 'pick-player-2');
      expect(find.text('Tiger 3'), findsOneWidget);
      expect(find.text('Lion 1 *'), findsOneWidget);
    });

    testWidgets('swap strike from the menu', (tester) async {
      await startedMatch(tester);

      await tapOn(tester, find.byTooltip('More'));
      await tapOn(tester, find.text('Swap strike'));

      expect(find.text('Lion 2 *'), findsOneWidget);
    });

    testWidgets('retiring a batter brings in the next one', (tester) async {
      await startedMatch(tester);

      await tapKey(tester, 'wicket');
      await tapKey(tester, 'how-retired');
      await tapKey(tester, 'crease-nonStriker');

      expect(scoreText(tester), '0/1');
      expect(find.text('Who comes in?'), findsOneWidget);
    });

    testWidgets('a save failure is reported but the score updates', (
      tester,
    ) async {
      final repository = await startedMatch(tester);
      repository.failWith = const MatchStorageException('disk full');

      await tapKey(tester, 'runs-2');

      expect(scoreText(tester), '2/0');
      expect(find.text("Couldn't save to this device."), findsOneWidget);
    });
  });

  group('match result', () {
    testWidgets('innings break, chase and result', (tester) async {
      final repository = FakeMatchRepository([
        savedMatch(testSetup(players: 2), [
          open,
          const BallBowled.runs(4),
          dot,
          dot,
          dot,
          dot,
        ]),
      ]);
      await pumpApp(tester, repository: repository, location: '/match/m1');

      await tapKey(tester, 'runs-1');
      expect(
        find.text('Lions made 5/0. Tigers need 6 to win.'),
        findsOneWidget,
      );

      await tapKey(tester, 'startInnings');
      expect(find.text('Need 6 runs from 6 balls'), findsOneWidget);
      await tapKey(tester, 'runs-6');

      expect(find.text('Tigers won by 1 wicket'), findsOneWidget);
    });

    testWidgets('a tie offers a super over', (tester) async {
      final repository = FakeMatchRepository([
        savedMatch(testSetup(players: 2), [
          open,
          const BallBowled.runs(4),
          dot,
          dot,
          dot,
          dot,
          dot,
          open,
          const BallBowled.runs(4),
          dot,
          dot,
          dot,
          dot,
        ]),
      ]);
      await pumpApp(tester, repository: repository, location: '/match/m1');

      await tapKey(tester, 'runs-0');
      expect(find.text('Match tied'), findsOneWidget);

      await tapKey(tester, 'superOver');
      expect(find.text('Super over: Tigers to bat'), findsOneWidget);
    });

    testWidgets('missing match shows an error with a way back', (tester) async {
      await pumpApp(tester, location: '/match/nope');

      expect(
        find.text("This match isn't on this device any more."),
        findsOneWidget,
      );
      await tapOn(tester, find.text('Back to matches'));
      expect(find.text('No matches yet'), findsOneWidget);
    });
  });
}
