import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../data/prefs_match_repository.dart';
import '../domain/match_repository.dart';
import '../domain/match_setup.dart';
import '../domain/match_state.dart';
import '../domain/saved_match.dart';

/// Every match on this device, newest first.
class SavedMatchesController extends AsyncNotifier<List<MatchState>> {
  @override
  Future<List<MatchState>> build() async {
    final saved = await ref.watch(matchRepositoryProvider).fetchAll();
    return [for (final match in saved) ?_replay(match)];
  }

  MatchState? _replay(SavedMatch match) {
    try {
      return MatchState.replay(match.setup, match.events);
    } on InvalidEventException catch (error, stackTrace) {
      developer.log(
        'Skipping match ${match.id} that does not replay',
        name: 'SavedMatchesController',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> reload() async {
    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
      // The error is in `state`; the screen shows it with a retry button.
    }
  }

  /// Saves a new match and returns its id, or null if saving failed.
  Future<String?> create({
    required List<Team> teams,
    required int battingFirst,
    required MatchRules rules,
  }) async {
    final now = ref.read(clockProvider)().toUtc();
    final setup = MatchSetup(
      id: now.microsecondsSinceEpoch.toRadixString(36),
      createdAt: now,
      teams: teams,
      battingFirst: battingFirst,
      rules: rules,
    );
    try {
      await ref
          .read(matchRepositoryProvider)
          .save(SavedMatch(setup: setup, events: const []));
    } on MatchStorageException catch (error, stackTrace) {
      developer.log(
        'Could not create match',
        name: 'SavedMatchesController',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
    if (ref.mounted) ref.invalidateSelf();
    return setup.id;
  }

  /// Deletes a match. Returns false if storage failed.
  Future<bool> delete(String id) async {
    try {
      await ref.read(matchRepositoryProvider).delete(id);
    } on MatchStorageException catch (error, stackTrace) {
      developer.log(
        'Could not delete match $id',
        name: 'SavedMatchesController',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
    if (!ref.mounted) return true;
    state = AsyncData([
      for (final match in state.value ?? const <MatchState>[])
        if (match.setup.id != id) match,
    ]);
    return true;
  }
}

final savedMatchesProvider =
    AsyncNotifierProvider<SavedMatchesController, List<MatchState>>(
      SavedMatchesController.new,
    );
