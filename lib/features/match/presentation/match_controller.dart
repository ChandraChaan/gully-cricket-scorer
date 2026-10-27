import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/prefs_match_repository.dart';
import '../domain/match_event.dart';
import '../domain/match_repository.dart';
import '../domain/match_state.dart';
import '../domain/saved_match.dart';
import 'saved_matches_controller.dart';

/// Thrown when a match id doesn't exist on this device.
final class MatchNotFoundException implements Exception {
  const MatchNotFoundException(this.id);

  final String id;
}

/// Scores one match. Every change is saved straight away.
class MatchController extends AsyncNotifier<MatchState> {
  MatchController(this.matchId);

  final String matchId;

  @override
  Future<MatchState> build() async {
    final saved = await ref.watch(matchRepositoryProvider).fetch(matchId);
    if (saved == null) throw MatchNotFoundException(matchId);
    return MatchState.replay(saved.setup, saved.events);
  }

  /// Records [event]. Returns false if the match couldn't be saved; the
  /// score still updates and is saved with the next change.
  Future<bool> record(MatchEvent event) =>
      _change((match) => match.apply(event));

  /// Takes back the last ball or action.
  Future<bool> undo() => _change((match) => match.undo());

  Future<bool> _change(MatchState Function(MatchState match) change) async {
    final current = state.value;
    if (current == null) return false;
    final updated = change(current);
    state = AsyncData(updated);
    try {
      await ref
          .read(matchRepositoryProvider)
          .save(SavedMatch(setup: updated.setup, events: updated.events));
    } on MatchStorageException catch (error, stackTrace) {
      developer.log(
        'Could not save match $matchId',
        name: 'MatchController',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
    if (ref.mounted) ref.invalidate(savedMatchesProvider);
    return true;
  }
}

final matchControllerProvider =
    AsyncNotifierProvider.family<MatchController, MatchState, String>(
      MatchController.new,
    );
