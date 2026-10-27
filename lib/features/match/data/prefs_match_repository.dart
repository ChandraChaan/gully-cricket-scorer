import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/match_repository.dart';
import '../domain/saved_match.dart';

/// Stores each match as one JSON string in shared preferences
/// (local storage on the web).
final class PrefsMatchRepository implements MatchRepository {
  PrefsMatchRepository(this._prefs);

  static const _prefix = 'match.';

  final SharedPreferencesAsync _prefs;

  @override
  Future<List<SavedMatch>> fetchAll() async {
    final Map<String, Object?> all;
    try {
      all = await _prefs.getAll();
    } catch (error) {
      throw MatchStorageException('Could not read matches', error);
    }
    final matches = <SavedMatch>[];
    for (final MapEntry(:key, :value) in all.entries) {
      if (!key.startsWith(_prefix) || value is! String) continue;
      final match = _decode(key, value);
      if (match != null) matches.add(match);
    }
    matches.sort((a, b) => b.setup.createdAt.compareTo(a.setup.createdAt));
    return matches;
  }

  @override
  Future<SavedMatch?> fetch(String id) async {
    final String? value;
    try {
      value = await _prefs.getString('$_prefix$id');
    } catch (error) {
      throw MatchStorageException('Could not read match $id', error);
    }
    return value == null ? null : _decode(id, value);
  }

  @override
  Future<void> save(SavedMatch match) async {
    try {
      await _prefs.setString('$_prefix${match.id}', jsonEncode(match.toJson()));
    } catch (error) {
      throw MatchStorageException('Could not save match ${match.id}', error);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _prefs.remove('$_prefix$id');
    } catch (error) {
      throw MatchStorageException('Could not delete match $id', error);
    }
  }

  SavedMatch? _decode(String key, String value) {
    try {
      return SavedMatch.fromJson(jsonDecode(value) as Map<String, Object?>);
    } catch (error, stackTrace) {
      developer.log(
        'Skipping unreadable match $key',
        name: 'PrefsMatchRepository',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}

final matchRepositoryProvider = Provider<MatchRepository>(
  (ref) => PrefsMatchRepository(SharedPreferencesAsync()),
);
