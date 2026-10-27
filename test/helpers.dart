import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gully_cricket_scorer/app.dart';
import 'package:gully_cricket_scorer/core/clock.dart';
import 'package:gully_cricket_scorer/core/router.dart';
import 'package:gully_cricket_scorer/core/sharer.dart';
import 'package:gully_cricket_scorer/features/match/data/prefs_match_repository.dart';
import 'package:gully_cricket_scorer/features/match/domain/match_event.dart';
import 'package:gully_cricket_scorer/features/match/domain/match_repository.dart';
import 'package:gully_cricket_scorer/features/match/domain/match_setup.dart';
import 'package:gully_cricket_scorer/features/match/domain/saved_match.dart';

class FakeMatchRepository implements MatchRepository {
  FakeMatchRepository([List<SavedMatch> initial = const []])
    : _matches = {for (final match in initial) match.id: match};

  final Map<String, SavedMatch> _matches;
  Object? failWith;
  int saves = 0;

  SavedMatch? operator [](String id) => _matches[id];

  @override
  Future<List<SavedMatch>> fetchAll() async {
    if (failWith case final error?) throw error;
    return _matches.values.toList()
      ..sort((a, b) => b.setup.createdAt.compareTo(a.setup.createdAt));
  }

  @override
  Future<SavedMatch?> fetch(String id) async {
    if (failWith case final error?) throw error;
    return _matches[id];
  }

  @override
  Future<void> save(SavedMatch match) async {
    if (failWith case final error?) throw error;
    saves++;
    _matches[match.id] = match;
  }

  @override
  Future<void> delete(String id) async {
    if (failWith case final error?) throw error;
    _matches.remove(id);
  }
}

class FakeSharer implements Sharer {
  final shared = <String>[];
  final copied = <String>[];
  final images = <(Uint8List, String)>[];
  ShareOutcome outcome = ShareOutcome.shared;

  @override
  Future<ShareOutcome> shareText(String text, {String? subject}) async {
    shared.add(text);
    return outcome;
  }

  @override
  Future<ShareOutcome> shareImage(
    Uint8List png, {
    required String fileName,
  }) async {
    images.add((png, fileName));
    return outcome;
  }

  @override
  Future<ShareOutcome> copyText(String text) async {
    copied.add(text);
    return ShareOutcome.copied;
  }
}

MatchSetup testSetup({
  String id = 'm1',
  int overs = 1,
  int players = 3,
  bool lastManStands = false,
}) => MatchSetup(
  id: id,
  createdAt: DateTime.utc(2026, 10, 25, 10),
  teams: [
    Team(
      name: 'Lions',
      players: [for (var i = 1; i <= players; i++) 'Lion $i'],
    ),
    Team(
      name: 'Tigers',
      players: [for (var i = 1; i <= players; i++) 'Tiger $i'],
    ),
  ],
  battingFirst: 0,
  rules: MatchRules(
    oversPerInnings: overs,
    playersPerSide: players,
    lastManStands: lastManStands,
  ),
);

SavedMatch savedMatch(MatchSetup setup, [List<MatchEvent> events = const []]) =>
    SavedMatch(setup: setup, events: events);

/// Pumps the whole app on a phone-sized screen and returns its container.
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  FakeMatchRepository? repository,
  FakeSharer? sharer,
  String? location,
}) async {
  tester.view
    ..physicalSize = const Size(1080, 2340)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final container = ProviderContainer.test(
    retry: (retryCount, error) => null,
    overrides: [
      matchRepositoryProvider.overrideWithValue(
        repository ?? FakeMatchRepository(),
      ),
      sharerProvider.overrideWithValue(sharer ?? FakeSharer()),
      clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 27, 8)),
    ],
  );
  if (location != null) container.read(routerProvider).go(location);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const GullyCricketApp(),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Scrolls [finder] into view and taps it. Lazy lists build it on the way.
Future<void> tapOn(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> tapKey(WidgetTester tester, String key) =>
    tapOn(tester, find.byKey(Key(key)));

String scoreText(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('score'))).data!;
