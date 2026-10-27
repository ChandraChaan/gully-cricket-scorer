/// The house rules for one match. The defaults suit a street game.
final class MatchRules {
  const MatchRules({
    required this.oversPerInnings,
    required this.playersPerSide,
    this.lastManStands = false,
    this.wideRuns = 1,
    this.noBallRuns = 1,
    this.freeHit = true,
  }) : assert(oversPerInnings > 0),
       assert(playersPerSide >= 2),
       assert(wideRuns == 0 || wideRuns == 1),
       assert(noBallRuns == 0 || noBallRuns == 1);

  factory MatchRules.fromJson(Map<String, Object?> json) => MatchRules(
    oversPerInnings: json['overs'] as int,
    playersPerSide: json['players'] as int,
    lastManStands: json['lastManStands'] as bool,
    wideRuns: json['wideRuns'] as int,
    noBallRuns: json['noBallRuns'] as int,
    freeHit: json['freeHit'] as bool,
  );

  final int oversPerInnings;
  final int playersPerSide;

  /// When on, the last batter carries on alone after everyone else is out.
  final bool lastManStands;

  /// Penalty runs for a wide: 0 or 1.
  final int wideRuns;

  /// Penalty runs for a no-ball: 0 or 1.
  final int noBallRuns;

  /// Whether the ball after a no-ball is a free hit.
  final bool freeHit;

  int get ballsPerInnings => oversPerInnings * ballsPerOver;

  /// Wickets that end an innings.
  int get wicketsPerInnings =>
      lastManStands ? playersPerSide : playersPerSide - 1;

  MatchRules copyWith({
    int? oversPerInnings,
    int? playersPerSide,
    bool? lastManStands,
    int? wideRuns,
    int? noBallRuns,
    bool? freeHit,
  }) => MatchRules(
    oversPerInnings: oversPerInnings ?? this.oversPerInnings,
    playersPerSide: playersPerSide ?? this.playersPerSide,
    lastManStands: lastManStands ?? this.lastManStands,
    wideRuns: wideRuns ?? this.wideRuns,
    noBallRuns: noBallRuns ?? this.noBallRuns,
    freeHit: freeHit ?? this.freeHit,
  );

  Map<String, Object?> toJson() => {
    'overs': oversPerInnings,
    'players': playersPerSide,
    'lastManStands': lastManStands,
    'wideRuns': wideRuns,
    'noBallRuns': noBallRuns,
    'freeHit': freeHit,
  };

  @override
  bool operator ==(Object other) =>
      other is MatchRules &&
      other.oversPerInnings == oversPerInnings &&
      other.playersPerSide == playersPerSide &&
      other.lastManStands == lastManStands &&
      other.wideRuns == wideRuns &&
      other.noBallRuns == noBallRuns &&
      other.freeHit == freeHit;

  @override
  int get hashCode => Object.hash(
    oversPerInnings,
    playersPerSide,
    lastManStands,
    wideRuns,
    noBallRuns,
    freeHit,
  );
}

const ballsPerOver = 6;

final class Team {
  Team({required this.name, required List<String> players})
    : players = List.unmodifiable(players);

  factory Team.fromJson(Map<String, Object?> json) => Team(
    name: json['name'] as String,
    players: (json['players'] as List<Object?>).cast<String>(),
  );

  final String name;

  /// Player names in batting-order slots. Players are referred to by index.
  final List<String> players;

  Map<String, Object?> toJson() => {'name': name, 'players': players};

  @override
  bool operator ==(Object other) =>
      other is Team &&
      other.name == name &&
      other.players.length == players.length &&
      Iterable<int>.generate(
        players.length,
      ).every((i) => other.players[i] == players[i]);

  @override
  int get hashCode => Object.hash(name, Object.hashAll(players));
}

/// Everything decided before the first ball.
final class MatchSetup {
  MatchSetup({
    required this.id,
    required this.createdAt,
    required List<Team> teams,
    required this.battingFirst,
    required this.rules,
  }) : assert(teams.length == 2),
       assert(battingFirst == 0 || battingFirst == 1),
       assert(teams.every((t) => t.players.length == rules.playersPerSide)),
       teams = List.unmodifiable(teams);

  factory MatchSetup.fromJson(Map<String, Object?> json) => MatchSetup(
    id: json['id'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
    teams: [
      for (final team in json['teams'] as List<Object?>)
        Team.fromJson(team as Map<String, Object?>),
    ],
    battingFirst: json['battingFirst'] as int,
    rules: MatchRules.fromJson(json['rules'] as Map<String, Object?>),
  );

  final String id;

  /// When the match was created, in UTC.
  final DateTime createdAt;

  /// Exactly two teams. Team 0 and team 1 are referred to by index.
  final List<Team> teams;

  /// Index of the team that bats first.
  final int battingFirst;
  final MatchRules rules;

  Map<String, Object?> toJson() => {
    'id': id,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'teams': [for (final team in teams) team.toJson()],
    'battingFirst': battingFirst,
    'rules': rules.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is MatchSetup &&
      other.id == id &&
      other.createdAt == createdAt &&
      other.teams[0] == teams[0] &&
      other.teams[1] == teams[1] &&
      other.battingFirst == battingFirst &&
      other.rules == rules;

  @override
  int get hashCode =>
      Object.hash(id, createdAt, teams[0], teams[1], battingFirst, rules);
}
