import 'saved_match.dart';

/// Thrown when matches can't be read from or written to device storage.
final class MatchStorageException implements Exception {
  const MatchStorageException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'MatchStorageException: $message ($cause)';
}

/// Where matches live. Everything stays on the device.
abstract interface class MatchRepository {
  /// All saved matches, newest first. Entries that can't be read are skipped.
  Future<List<SavedMatch>> fetchAll();

  /// The match with [id], or null if there is none.
  Future<SavedMatch?> fetch(String id);

  /// Creates or replaces a match.
  Future<void> save(SavedMatch match);

  Future<void> delete(String id);
}
