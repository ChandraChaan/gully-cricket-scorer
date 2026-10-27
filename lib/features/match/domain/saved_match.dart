import 'match_event.dart';
import 'match_setup.dart';

/// What gets stored for a match: its setup and every event, in order.
final class SavedMatch {
  SavedMatch({required this.setup, required List<MatchEvent> events})
    : events = List.unmodifiable(events);

  factory SavedMatch.fromJson(Map<String, Object?> json) => SavedMatch(
    setup: MatchSetup.fromJson(json['setup'] as Map<String, Object?>),
    events: [
      for (final event in json['events'] as List<Object?>)
        MatchEvent.fromJson(event as Map<String, Object?>),
    ],
  );

  final MatchSetup setup;
  final List<MatchEvent> events;

  String get id => setup.id;

  Map<String, Object?> toJson() => {
    'version': 1,
    'setup': setup.toJson(),
    'events': [for (final event in events) event.toJson()],
  };
}
