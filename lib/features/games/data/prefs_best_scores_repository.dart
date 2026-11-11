import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/arcade_game.dart';
import '../domain/best_scores_repository.dart';

/// Stores one integer per game in shared preferences
/// (local storage on the web).
final class PrefsBestScoresRepository implements BestScoresRepository {
  PrefsBestScoresRepository(this._prefs);

  static const _prefix = 'games.best.';

  final SharedPreferencesAsync _prefs;

  @override
  Future<Map<GameId, int>> fetchAll() async {
    try {
      final scores = <GameId, int>{};
      for (final game in GameId.values) {
        final score = await _prefs.getInt('$_prefix${game.key}');
        if (score != null) scores[game] = score;
      }
      return scores;
    } catch (error) {
      throw BestScoreStorageException('Could not read best scores', error);
    }
  }

  @override
  Future<void> save(GameId game, int score) async {
    try {
      await _prefs.setInt('$_prefix${game.key}', score);
    } catch (error) {
      throw BestScoreStorageException('Could not save best score', error);
    }
  }
}

final bestScoresRepositoryProvider = Provider<BestScoresRepository>(
  (ref) => PrefsBestScoresRepository(SharedPreferencesAsync()),
);
