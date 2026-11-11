import 'arcade_game.dart';

/// Thrown when best scores can't be read or written.
final class BestScoreStorageException implements Exception {
  const BestScoreStorageException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'BestScoreStorageException: $message';
}

/// The player's best score in each mini game, kept on this device.
abstract interface class BestScoresRepository {
  Future<Map<GameId, int>> fetchAll();

  Future<void> save(GameId game, int score);
}
