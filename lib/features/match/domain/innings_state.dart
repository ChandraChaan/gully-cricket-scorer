import 'match_event.dart';
import 'match_setup.dart';

/// How a batter got out, and the bowler who gets the wicket (if any).
final class OutDetail {
  const OutDetail(this.how, {this.bowler});

  final HowOut how;
  final int? bowler;
}

final class BatterScore {
  const BatterScore({
    required this.player,
    required this.runs,
    required this.balls,
    required this.fours,
    required this.sixes,
    this.out,
  });

  final int player;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;

  /// Null while the batter is not out.
  final OutDetail? out;

  /// Runs per 100 balls, or null before the first ball faced.
  double? get strikeRate => balls == 0 ? null : runs * 100 / balls;
}

final class BowlerFigures {
  const BowlerFigures({
    required this.player,
    required this.balls,
    required this.maidens,
    required this.runs,
    required this.wickets,
    required this.wides,
    required this.noBalls,
  });

  final int player;

  /// Legal balls bowled.
  final int balls;
  final int maidens;

  /// Runs conceded: off the bat, wides and no-balls. Byes don't count.
  final int runs;
  final int wickets;
  final int wides;
  final int noBalls;

  /// Runs per over, or null before the first legal ball.
  double? get economy => balls == 0 ? null : runs * ballsPerOver / balls;
}

final class Extras {
  const Extras({
    this.wides = 0,
    this.noBalls = 0,
    this.byes = 0,
    this.legByes = 0,
  });

  final int wides;
  final int noBalls;
  final int byes;
  final int legByes;

  int get total => wides + noBalls + byes + legByes;
}

final class FallOfWicket {
  const FallOfWicket({
    required this.wicket,
    required this.runs,
    required this.legalBalls,
    required this.player,
  });

  /// 1 for the first wicket.
  final int wicket;

  /// Team score when the wicket fell.
  final int runs;
  final int legalBalls;
  final int player;
}

final class OverSummary {
  OverSummary({
    required this.index,
    required this.bowler,
    required List<BallBowled> balls,
    required this.runs,
    required this.bowlerRuns,
  }) : balls = List.unmodifiable(balls);

  /// 0 for the first over.
  final int index;
  final int bowler;

  /// Every delivery in the over, extras included, in order.
  final List<BallBowled> balls;

  /// Runs added to the total, byes included.
  final int runs;

  /// Runs charged to the bowler.
  final int bowlerRuns;

  int get legalBalls => balls.where((b) => b.kind.isLegal).length;
  bool get isComplete => legalBalls == ballsPerOver;
  bool get isMaiden => isComplete && bowlerRuns == 0;
  int get wickets => balls.where((b) {
    final how = b.dismissal?.how;
    return how != null && how.creditsBowler;
  }).length;
}

final class InningsState {
  InningsState({
    required this.index,
    required this.battingTeam,
    required this.isSuperOver,
    required this.maxBalls,
    required this.wicketLimit,
    required this.target,
    required this.runs,
    required this.wickets,
    required this.legalBalls,
    required this.extras,
    required List<BatterScore> batters,
    required List<BowlerFigures> bowlers,
    required List<FallOfWicket> fallOfWickets,
    required List<OverSummary> overs,
    required this.striker,
    required this.nonStriker,
    required this.bowler,
    required this.freeHit,
    required this.isComplete,
  }) : batters = List.unmodifiable(batters),
       bowlers = List.unmodifiable(bowlers),
       fallOfWickets = List.unmodifiable(fallOfWickets),
       overs = List.unmodifiable(overs);

  /// 0 and 1 for the match innings, 2 and up for super overs.
  final int index;
  final int battingTeam;
  final bool isSuperOver;
  final int maxBalls;
  final int wicketLimit;

  /// Runs needed to win, for the second innings of a pair.
  final int? target;
  final int runs;
  final int wickets;
  final int legalBalls;
  final Extras extras;

  /// In batting order.
  final List<BatterScore> batters;

  /// In the order they first bowled.
  final List<BowlerFigures> bowlers;
  final List<FallOfWicket> fallOfWickets;
  final List<OverSummary> overs;

  /// Players at the crease. Null when the slot waits for a new batter, and
  /// the non-striker is null while a last man stands alone.
  final int? striker;
  final int? nonStriker;

  /// Null between overs, until the next bowler is chosen.
  final int? bowler;

  /// Whether the next ball is a free hit.
  final bool freeHit;
  final bool isComplete;

  int get bowlingTeam => 1 - battingTeam;
  int get ballsLeft => maxBalls - legalBalls;
  int? get runsNeeded => target == null ? null : target! - runs;

  /// Runs per over so far, or null before the first legal ball.
  double? get runRate =>
      legalBalls == 0 ? null : runs * ballsPerOver / legalBalls;

  /// Runs per over still needed, while chasing.
  double? get requiredRate {
    final needed = runsNeeded;
    if (needed == null || ballsLeft == 0) return null;
    return needed * ballsPerOver / ballsLeft;
  }

  BatterScore? batter(int player) {
    for (final score in batters) {
      if (score.player == player) return score;
    }
    return null;
  }

  BowlerFigures? figures(int player) {
    for (final figures in bowlers) {
      if (figures.player == player) return figures;
    }
    return null;
  }

  /// The over in progress, or the last over when between overs.
  OverSummary? get currentOver => overs.isEmpty ? null : overs.last;
}
