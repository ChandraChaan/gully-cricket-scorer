/// One thing that happened in a match. A match is stored as its setup plus
/// the list of these events; every score, scorecard and prompt is derived by
/// replaying them, so undo is simply dropping events from the end.
sealed class MatchEvent {
  const MatchEvent();

  factory MatchEvent.fromJson(Map<String, Object?> json) => switch (json['t']) {
    'start' => InningsStarted(
      striker: json['striker'] as int,
      nonStriker: json['nonStriker'] as int,
      bowler: json['bowler'] as int,
    ),
    'bowler' => BowlerChosen(json['player'] as int),
    'batter' => BatterChosen(json['player'] as int),
    'ball' => BallBowled(
      kind: BallKind.values.byName(json['kind'] as String),
      runs: json['runs'] as int,
      dismissal: switch (json['out']) {
        final Map<String, Object?> out => Dismissal.fromJson(out),
        _ => null,
      },
    ),
    'retire' => BatterRetired(Crease.values.byName(json['crease'] as String)),
    'swap' => const StrikeSwapped(),
    'superOver' => const SuperOverStarted(),
    final type => throw FormatException('Unknown match event: $type'),
  };

  Map<String, Object?> toJson();
}

/// The two batters at the crease, from the batting side's point of view.
enum Crease { striker, nonStriker }

enum BallKind {
  /// A fair delivery. `runs` are off the bat.
  legal,

  /// `runs` are the runs taken (or the boundary) on top of the wide penalty.
  wide,

  /// `runs` are off the bat, on top of the no-ball penalty.
  noBall,
  bye,
  legBye;

  /// Whether the ball counts towards the over.
  bool get isLegal => this != wide && this != noBall;
}

enum HowOut {
  bowled,
  caught,
  lbw,
  stumped,
  hitWicket,
  runOut,
  retired;

  /// Whether the bowler gets the wicket.
  bool get creditsBowler => this != runOut && this != retired;
}

final class Dismissal {
  const Dismissal(this.how, {this.batter = Crease.striker})
    : assert(how != HowOut.retired),
      assert(how == HowOut.runOut || batter == Crease.striker);

  factory Dismissal.fromJson(Map<String, Object?> json) => Dismissal(
    HowOut.values.byName(json['how'] as String),
    batter: Crease.values.byName(json['batter'] as String),
  );

  final HowOut how;

  /// Who is out, by where they stood when the ball was bowled. Only a run
  /// out can dismiss the non-striker.
  final Crease batter;

  Map<String, Object?> toJson() => {'how': how.name, 'batter': batter.name};

  @override
  bool operator ==(Object other) =>
      other is Dismissal && other.how == how && other.batter == batter;

  @override
  int get hashCode => Object.hash(how, batter);
}

/// Opens an innings with two batters and the first bowler. Players are
/// indexes into their team's player list.
final class InningsStarted extends MatchEvent {
  const InningsStarted({
    required this.striker,
    required this.nonStriker,
    required this.bowler,
  });

  final int striker;
  final int nonStriker;
  final int bowler;

  @override
  Map<String, Object?> toJson() => {
    't': 'start',
    'striker': striker,
    'nonStriker': nonStriker,
    'bowler': bowler,
  };

  @override
  bool operator ==(Object other) =>
      other is InningsStarted &&
      other.striker == striker &&
      other.nonStriker == nonStriker &&
      other.bowler == bowler;

  @override
  int get hashCode => Object.hash(striker, nonStriker, bowler);
}

/// The bowler for the next over.
final class BowlerChosen extends MatchEvent {
  const BowlerChosen(this.player);

  final int player;

  @override
  Map<String, Object?> toJson() => {'t': 'bowler', 'player': player};

  @override
  bool operator ==(Object other) =>
      other is BowlerChosen && other.player == player;

  @override
  int get hashCode => Object.hash(BowlerChosen, player);
}

/// The batter who comes in after a wicket.
final class BatterChosen extends MatchEvent {
  const BatterChosen(this.player);

  final int player;

  @override
  Map<String, Object?> toJson() => {'t': 'batter', 'player': player};

  @override
  bool operator ==(Object other) =>
      other is BatterChosen && other.player == player;

  @override
  int get hashCode => Object.hash(BatterChosen, player);
}

final class BallBowled extends MatchEvent {
  const BallBowled({required this.kind, this.runs = 0, this.dismissal})
    : assert(runs >= 0);

  const BallBowled.runs(this.runs) : kind = BallKind.legal, dismissal = null;

  final BallKind kind;
  final int runs;
  final Dismissal? dismissal;

  @override
  Map<String, Object?> toJson() => {
    't': 'ball',
    'kind': kind.name,
    'runs': runs,
    if (dismissal case final out?) 'out': out.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is BallBowled &&
      other.kind == kind &&
      other.runs == runs &&
      other.dismissal == dismissal;

  @override
  int get hashCode => Object.hash(kind, runs, dismissal);
}

/// A batter retires between balls. Gully rules: it counts as a wicket.
final class BatterRetired extends MatchEvent {
  const BatterRetired(this.batter);

  final Crease batter;

  @override
  Map<String, Object?> toJson() => {'t': 'retire', 'crease': batter.name};

  @override
  bool operator ==(Object other) =>
      other is BatterRetired && other.batter == batter;

  @override
  int get hashCode => Object.hash(BatterRetired, batter);
}

/// The batters swap ends without a ball, to fix a strike mistake.
final class StrikeSwapped extends MatchEvent {
  const StrikeSwapped();

  @override
  Map<String, Object?> toJson() => {'t': 'swap'};

  @override
  bool operator ==(Object other) => other is StrikeSwapped;

  @override
  int get hashCode => (StrikeSwapped).hashCode;
}

/// After a tie, both teams play one more over each.
final class SuperOverStarted extends MatchEvent {
  const SuperOverStarted();

  @override
  Map<String, Object?> toJson() => {'t': 'superOver'};

  @override
  bool operator ==(Object other) => other is SuperOverStarted;

  @override
  int get hashCode => (SuperOverStarted).hashCode;
}
