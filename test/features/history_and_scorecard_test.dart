import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gully_cricket_scorer/core/sharer.dart';
import 'package:gully_cricket_scorer/features/match/domain/match_event.dart';
import 'package:gully_cricket_scorer/features/match/domain/match_repository.dart';

import '../helpers.dart';

const open = InningsStarted(striker: 0, nonStriker: 1, bowler: 0);
const dot = BallBowled.runs(0);
const bowled = BallBowled(
  kind: BallKind.legal,
  dismissal: Dismissal(HowOut.bowled),
);

final finishedEvents = <MatchEvent>[
  open,
  const BallBowled.runs(4),
  bowled,
  const BatterChosen(2),
  const BallBowled.runs(6),
  const BallBowled(kind: BallKind.wide),
  dot,
  dot,
  dot,
  open,
  const BallBowled.runs(1),
  dot,
  dot,
  dot,
  dot,
  dot,
];

void main() {
  group('history', () {
    testWidgets('empty state', (tester) async {
      await pumpApp(tester);

      expect(find.text('No matches yet'), findsOneWidget);
      expect(find.byKey(const Key('newMatch')), findsOneWidget);
    });

    testWidgets('lists matches with their result and scores', (tester) async {
      await pumpApp(
        tester,
        repository: FakeMatchRepository([
          savedMatch(testSetup(), finishedEvents),
          savedMatch(testSetup(id: 'm2'), [open]),
        ]),
      );

      expect(find.text('Lions v Tigers'), findsNWidgets(2));
      expect(
        find.textContaining('Lions won by 10 runs\nLions 11/1 · Tigers 1/0'),
        findsOneWidget,
      );
      expect(find.textContaining('In progress'), findsOneWidget);
    });

    testWidgets('error state with retry', (tester) async {
      final repository = FakeMatchRepository()
        ..failWith = const MatchStorageException('broken');
      await pumpApp(tester, repository: repository);

      expect(find.text("Couldn't load your matches."), findsOneWidget);
      repository.failWith = null;
      await tapOn(tester, find.text('Retry'));
      expect(find.text('No matches yet'), findsOneWidget);
    });

    testWidgets('deleting asks first', (tester) async {
      final repository = FakeMatchRepository([savedMatch(testSetup())]);
      await pumpApp(tester, repository: repository);

      await tapOn(tester, find.byTooltip('Delete match'));
      expect(find.text('Delete this match?'), findsOneWidget);
      await tapOn(tester, find.text('Cancel'));
      expect(repository['m1'], isNotNull);

      await tapOn(tester, find.byTooltip('Delete match'));
      await tapKey(tester, 'confirmDelete');
      expect(repository['m1'], isNull);
      expect(find.text('No matches yet'), findsOneWidget);
    });

    testWidgets('tapping a match opens it', (tester) async {
      await pumpApp(
        tester,
        repository: FakeMatchRepository([
          savedMatch(testSetup(), [open]),
        ]),
      );

      await tapOn(tester, find.text('Lions v Tigers'));
      expect(find.byKey(const Key('score')), findsOneWidget);
    });
  });

  group('scorecard', () {
    testWidgets('shows batting, bowling, extras and fall of wickets', (
      tester,
    ) async {
      await pumpApp(
        tester,
        repository: FakeMatchRepository([
          savedMatch(testSetup(), finishedEvents),
        ]),
        location: '/match/m1/scorecard',
      );

      expect(find.text('Lions won by 10 runs'), findsOneWidget);
      expect(find.text('Lions innings'), findsOneWidget);
      expect(find.text('b Tiger 1'), findsOneWidget);
      expect(find.text('not out'), findsNWidgets(4));
      expect(
        find.textContaining('1 (wd 1, nb 0, b 0, lb 0)', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('1-4 (Lion 1, 0.2 ov)', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Tigers innings'), findsOneWidget);
      await tester.ensureVisible(find.text('Over by over').last);
      expect(find.text('Over 1 · Tiger 1 · 11 runs'), findsOneWidget);
    });

    testWidgets('shares the scorecard as WhatsApp-friendly text', (
      tester,
    ) async {
      final sharer = FakeSharer();
      await pumpApp(
        tester,
        repository: FakeMatchRepository([
          savedMatch(testSetup(), finishedEvents),
        ]),
        sharer: sharer,
        location: '/match/m1/scorecard',
      );

      await tapKey(tester, 'shareText');

      final text = sharer.shared.single;
      expect(text, startsWith('*Lions v Tigers*\nLions won by 10 runs'));
      expect(text, contains('*Lions innings*: 11/1 (1 ov)'));
      expect(text, contains('Lion 1 4 (2), b Tiger 1'));
      expect(text, contains('Lion 3 6 (4), not out'));
    });

    testWidgets('shares the whole scorecard as a PNG image', (tester) async {
      final sharer = FakeSharer();
      await pumpApp(
        tester,
        repository: FakeMatchRepository([
          savedMatch(testSetup(), finishedEvents),
        ]),
        sharer: sharer,
        location: '/match/m1/scorecard',
      );

      await tester.tap(find.byKey(const Key('shareImage')));
      // Encoding the image needs real time, not the test clock.
      await tester.runAsync(() async {
        for (var i = 0; i < 50 && sharer.images.isEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      });
      await tester.pump();

      final (png, fileName) = sharer.images.single;
      expect(fileName, 'scorecard-m1.png');
      expect(png.sublist(1, 4), 'PNG'.codeUnits);
      final view = tester.view;
      final screenHeight = view.physicalSize.height / view.devicePixelRatio;
      final imageHeight = ByteData.sublistView(png).getUint32(20) / 2;
      expect(
        imageHeight,
        greaterThan(screenHeight),
        reason: 'the part scrolled out of view is included',
      );
    });

    testWidgets('copies when there is no share sheet', (tester) async {
      final sharer = FakeSharer()..outcome = ShareOutcome.copied;
      await pumpApp(
        tester,
        repository: FakeMatchRepository([
          savedMatch(testSetup(), finishedEvents),
        ]),
        sharer: sharer,
        location: '/match/m1/scorecard',
      );

      await tapKey(tester, 'shareText');

      expect(
        find.text(
          "Sharing isn't available here, so the scorecard was copied instead.",
        ),
        findsOneWidget,
      );
    });

    testWidgets('works before the first ball', (tester) async {
      await pumpApp(
        tester,
        repository: FakeMatchRepository([savedMatch(testSetup())]),
        location: '/match/m1/scorecard',
      );

      expect(
        find.text('The scorecard fills in as the match is played.'),
        findsOneWidget,
      );
    });
  });
}
