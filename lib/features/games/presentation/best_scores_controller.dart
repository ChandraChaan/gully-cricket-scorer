import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/prefs_best_scores_repository.dart';
import '../domain/arcade_game.dart';
import '../domain/best_scores_repository.dart';

/// The best score in each mini game. Games without one are missing.
class BestScoresController extends AsyncNotifier<Map<GameId, int>> {
  @override
  Future<Map<GameId, int>> build() async {
    try {
      return await ref.watch(bestScoresRepositoryProvider).fetchAll();
    } on BestScoreStorageException catch (error, stackTrace) {
      // Best scores are a nicety: play on without them.
      developer.log(
        'Could not load best scores',
        name: 'BestScoresController',
        error: error,
        stackTrace: stackTrace,
      );
      return const {};
    }
  }

  /// Records [score] if it beats the best so far. Returns whether it did.
  Future<bool> submit(GameId game, int score) async {
    final scores = await future;
    if (score <= 0 || score <= (scores[game] ?? 0)) return false;
    if (ref.mounted) state = AsyncData({...scores, game: score});
    try {
      await ref.read(bestScoresRepositoryProvider).save(game, score);
    } on BestScoreStorageException catch (error, stackTrace) {
      developer.log(
        'Could not save best score',
        name: 'BestScoresController',
        error: error,
        stackTrace: stackTrace,
      );
    }
    return true;
  }
}

final bestScoresProvider =
    AsyncNotifierProvider<BestScoresController, Map<GameId, int>>(
      BestScoresController.new,
    );

/// The dice for the mini games. Tests swap in a seeded one.
final gameRandomProvider = Provider<math.Random>((ref) => math.Random());
