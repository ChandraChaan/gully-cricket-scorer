import 'innings_state.dart';
import 'match_event.dart';
import 'match_setup.dart';

sealed class WinMargin {
  const WinMargin();
}

final class ByRuns extends WinMargin {
  const ByRuns(this.runs);

  final int runs;
}

final class ByWickets extends WinMargin {
  const ByWickets(this.wickets);

  final int wickets;
}

sealed class MatchResult {
  const MatchResult();
}

final class Win extends MatchResult {
  const Win({
    required this.winner,
    required this.margin,
    required this.inSuperOver,
  });

  final int winner;
  final WinMargin margin;
  final bool inSuperOver;
}

final class Tie extends MatchResult {
  const Tie();
}

/// What the scorer has to do next.
sealed class NextStep {
  const NextStep();
}

/// Pick two openers and a bowler for innings [innings].
final class ChooseOpeners extends NextStep {
  const ChooseOpeners({
    required this.innings,
    required this.battingTeam,
    required this.isSuperOver,
  });

  final int innings;
  final int battingTeam;
  final bool isSuperOver;

  int get bowlingTeam => 1 - battingTeam;
}

final class ChooseBowler extends NextStep {
  ChooseBowler(List<int> eligible) : eligible = List.unmodifiable(eligible);

  /// Everyone except the bowler of the previous over.
  final List<int> eligible;
}

final class ChooseBatter extends NextStep {
  ChooseBatter(List<int> available) : available = List.unmodifiable(available);

  /// Players who haven't batted yet in this innings.
  final List<int> available;
}

final class Bowl extends NextStep {
  const Bowl();
}

final class MatchOver extends NextStep {
  const MatchOver(this.result);

  final MatchResult result;
}

/// Thrown when an event doesn't fit the state of the match, for example a
/// ball before the bowler is chosen.
final class InvalidEventException implements Exception {
  const InvalidEventException(this.message);

  final String message;

  @override
  String toString() => 'InvalidEventException: $message';
}

/// The state of a match, derived by replaying its events.
final class MatchState {
  MatchState._({
    required this.setup,
    required List<MatchEvent> events,
    required List<InningsState> innings,
    required this.next,
  }) : events = List.unmodifiable(events),
       innings = List.unmodifiable(innings);

  /// Replays [events] over [setup]. Throws [InvalidEventException] if an
  /// event doesn't fit.
  factory MatchState.replay(MatchSetup setup, List<MatchEvent> events) {
    final scorer = _Scorer(setup);
    events.forEach(scorer.apply);
    return MatchState._(
      setup: setup,
      events: events,
      innings: [for (final innings in scorer.innings) innings.build()],
      next: scorer.next,
    );
  }

  final MatchSetup setup;
  final List<MatchEvent> events;
  final List<InningsState> innings;
  final NextStep next;

  MatchRules get rules => setup.rules;
  InningsState? get currentInnings => innings.isEmpty ? null : innings.last;
  MatchResult? get result => switch (next) {
    MatchOver(:final result) => result,
    _ => null,
  };
  bool get isStarted => events.isNotEmpty;

  /// The result of the match itself, before any super over.
  MatchResult? get mainResult => innings.length >= 2 && innings[1].isComplete
      ? _decide(innings[0], innings[1])
      : null;

  /// Records [event]. Throws [InvalidEventException] if it doesn't fit.
  MatchState apply(MatchEvent event) =>
      MatchState.replay(setup, [...events, event]);

  bool get canUndo => events.isNotEmpty;

  /// Takes back the last ball or action, together with the bowler and
  /// batter picks that followed it.
  MatchState undo() =>
      MatchState.replay(setup, withoutLastAction(events).toList());

  /// Ways the striker or non-striker can be out on a ball of [kind], given
  /// the free-hit state of the current innings.
  Set<HowOut> allowedDismissals(BallKind kind) =>
      allowedDismissalsFor(kind, freeHit: currentInnings?.freeHit ?? false);
}

MatchResult _decide(InningsState first, InningsState chase) {
  if (chase.runs >= chase.target!) {
    return Win(
      winner: chase.battingTeam,
      margin: ByWickets(chase.wicketLimit - chase.wickets),
      inSuperOver: chase.isSuperOver,
    );
  }
  if (chase.runs == first.runs) return const Tie();
  return Win(
    winner: first.battingTeam,
    margin: ByRuns(first.runs - chase.runs),
    inSuperOver: chase.isSuperOver,
  );
}

/// Ways a batter can be out on a ball of [kind].
Set<HowOut> allowedDismissalsFor(BallKind kind, {required bool freeHit}) {
  if (freeHit) return {HowOut.runOut};
  return switch (kind) {
    BallKind.legal => {
      HowOut.bowled,
      HowOut.caught,
      HowOut.lbw,
      HowOut.stumped,
      HowOut.hitWicket,
      HowOut.runOut,
    },
    BallKind.wide => {HowOut.stumped, HowOut.hitWicket, HowOut.runOut},
    BallKind.noBall || BallKind.bye || BallKind.legBye => {HowOut.runOut},
  };
}

/// [events] without the last scoring action. Bowler and batter picks are
/// prompted by the ball before them, so they go with it.
Iterable<MatchEvent> withoutLastAction(List<MatchEvent> events) {
  var end = events.length;
  while (end > 0 &&
      (events[end - 1] is BowlerChosen || events[end - 1] is BatterChosen)) {
    end--;
  }
  return events.take(end > 0 ? end - 1 : 0);
}

class _BatterTally {
  _BatterTally(this.player);

  final int player;
  int runs = 0;
  int balls = 0;
  int fours = 0;
  int sixes = 0;
  OutDetail? out;

  void addRuns(int scored) {
    runs += scored;
    if (scored == 4) fours++;
    if (scored == 6) sixes++;
  }

  BatterScore build() => BatterScore(
    player: player,
    runs: runs,
    balls: balls,
    fours: fours,
    sixes: sixes,
    out: out,
  );
}

class _BowlerTally {
  _BowlerTally(this.player);

  final int player;
  int balls = 0;
  int maidens = 0;
  int runs = 0;
  int wickets = 0;
  int wides = 0;
  int noBalls = 0;

  BowlerFigures build() => BowlerFigures(
    player: player,
    balls: balls,
    maidens: maidens,
    runs: runs,
    wickets: wickets,
    wides: wides,
    noBalls: noBalls,
  );
}

class _OverTally {
  _OverTally(this.index, this.bowler);

  final int index;
  final int bowler;
  final balls = <BallBowled>[];
  int runs = 0;
  int bowlerRuns = 0;

  int get legalBalls => balls.where((b) => b.kind.isLegal).length;

  OverSummary build() => OverSummary(
    index: index,
    bowler: bowler,
    balls: balls,
    runs: runs,
    bowlerRuns: bowlerRuns,
  );
}

class _InningsTally {
  _InningsTally({
    required this.index,
    required this.battingTeam,
    required this.isSuperOver,
    required this.maxBalls,
    required this.wicketLimit,
    required this.target,
  });

  final int index;
  final int battingTeam;
  final bool isSuperOver;
  final int maxBalls;
  final int wicketLimit;
  final int? target;

  int runs = 0;
  int wickets = 0;
  int legalBalls = 0;
  int wides = 0;
  int noBalls = 0;
  int byes = 0;
  int legByes = 0;
  final batters = <int, _BatterTally>{};
  final bowlers = <int, _BowlerTally>{};
  final fallOfWickets = <FallOfWicket>[];
  final overs = <_OverTally>[];
  int? striker;
  int? nonStriker;
  int? bowler;
  int? previousBowler;
  bool freeHit = false;

  bool get isComplete =>
      wickets >= wicketLimit ||
      legalBalls >= maxBalls ||
      (target != null && runs >= target!);

  void swapEnds() {
    final wasStriker = striker;
    striker = nonStriker;
    nonStriker = wasStriker;
  }

  void startOver(int player) {
    bowler = player;
    bowlers.putIfAbsent(player, () => _BowlerTally(player));
    overs.add(_OverTally(overs.length, player));
  }

  void addBatter(int player) {
    batters[player] = _BatterTally(player);
    if (striker == null) {
      striker = player;
    } else {
      nonStriker = player;
    }
  }

  void dismiss(int player, OutDetail out) {
    batters[player]!.out = out;
    wickets++;
    fallOfWickets.add(
      FallOfWicket(
        wicket: wickets,
        runs: runs,
        legalBalls: legalBalls,
        player: player,
      ),
    );
    if (striker == player) {
      striker = null;
    } else {
      nonStriker = null;
    }
  }

  InningsState build() => InningsState(
    index: index,
    battingTeam: battingTeam,
    isSuperOver: isSuperOver,
    maxBalls: maxBalls,
    wicketLimit: wicketLimit,
    target: target,
    runs: runs,
    wickets: wickets,
    legalBalls: legalBalls,
    extras: Extras(
      wides: wides,
      noBalls: noBalls,
      byes: byes,
      legByes: legByes,
    ),
    batters: [for (final tally in batters.values) tally.build()],
    bowlers: [for (final tally in bowlers.values) tally.build()],
    fallOfWickets: fallOfWickets,
    overs: [for (final over in overs) over.build()],
    striker: striker,
    nonStriker: nonStriker,
    bowler: bowler,
    freeHit: freeHit,
    isComplete: isComplete,
  );
}

class _Scorer {
  _Scorer(this.setup);

  final MatchSetup setup;
  final innings = <_InningsTally>[];

  /// Innings slots opened so far: 2 for the match, plus 2 per super over.
  int scheduledInnings = 2;

  MatchRules get rules => setup.rules;
  int get playersPerSide => rules.playersPerSide;

  NextStep get next {
    final current = innings.isEmpty ? null : innings.last;
    if (current == null || current.isComplete) {
      if (current != null &&
          current.index.isOdd &&
          innings.length == scheduledInnings) {
        return MatchOver(
          _decide(innings[current.index - 1].build(), current.build()),
        );
      }
      final index = innings.length;
      return ChooseOpeners(
        innings: index,
        battingTeam: _battingTeam(index),
        isSuperOver: index >= 2,
      );
    }
    if (current.striker == null || current.nonStriker == null) {
      final available = _available(current);
      if (available.isNotEmpty) return ChooseBatter(available);
    }
    if (current.bowler == null) {
      return ChooseBowler([
        for (var p = 0; p < playersPerSide; p++)
          if (p != current.previousBowler) p,
      ]);
    }
    return const Bowl();
  }

  int _battingTeam(int index) {
    if (index == 0) return setup.battingFirst;
    if (index.isOdd) return 1 - innings[index - 1].battingTeam;
    // In a super over, the side that batted second bats first.
    return innings[index - 1].battingTeam;
  }

  List<int> _available(_InningsTally tally) => [
    for (var p = 0; p < playersPerSide; p++)
      if (!tally.batters.containsKey(p)) p,
  ];

  void apply(MatchEvent event) {
    final step = next;
    switch (event) {
      case InningsStarted():
        if (step is! ChooseOpeners) _reject(event, step);
        if (innings.length >= scheduledInnings) _reject(event, step);
        _startInnings(event, step);
      case BowlerChosen(:final player):
        if (step is! ChooseBowler || !step.eligible.contains(player)) {
          _reject(event, step);
        }
        innings.last.startOver(player);
      case BatterChosen(:final player):
        if (step is! ChooseBatter || !step.available.contains(player)) {
          _reject(event, step);
        }
        innings.last.addBatter(player);
        _settleLastMan(innings.last);
      case BallBowled():
        if (step is! Bowl) _reject(event, step);
        _bowl(innings.last, event);
      case BatterRetired(:final batter):
        if (step is! Bowl) _reject(event, step);
        final tally = innings.last;
        final player = batter == Crease.striker
            ? tally.striker
            : tally.nonStriker;
        if (player == null) _reject(event, step);
        tally.dismiss(player, const OutDetail(HowOut.retired));
        _settleLastMan(tally);
      case StrikeSwapped():
        if (step is! Bowl) _reject(event, step);
        innings.last.swapEnds();
        _settleLastMan(innings.last);
      case SuperOverStarted():
        if (step is! MatchOver || step.result is! Tie) _reject(event, step);
        scheduledInnings += 2;
    }
  }

  Never _reject(MatchEvent event, NextStep step) => throw InvalidEventException(
    '${event.runtimeType} does not fit while waiting for ${step.runtimeType}',
  );

  void _startInnings(InningsStarted event, ChooseOpeners step) {
    bool valid(int player) => player >= 0 && player < playersPerSide;
    if (!valid(event.striker) ||
        !valid(event.nonStriker) ||
        !valid(event.bowler) ||
        event.striker == event.nonStriker) {
      _reject(event, step);
    }
    final index = innings.length;
    final superOver = index >= 2;
    final tally = _InningsTally(
      index: index,
      battingTeam: step.battingTeam,
      isSuperOver: superOver,
      maxBalls: superOver ? ballsPerOver : rules.ballsPerInnings,
      wicketLimit: superOver
          ? (rules.wicketsPerInnings < 2 ? rules.wicketsPerInnings : 2)
          : rules.wicketsPerInnings,
      target: index.isOdd ? innings[index - 1].runs + 1 : null,
    );
    innings.add(tally);
    tally
      ..addBatter(event.striker)
      ..addBatter(event.nonStriker)
      ..startOver(event.bowler);
  }

  void _bowl(_InningsTally tally, BallBowled ball) {
    final striker = tally.striker!;
    final nonStriker = tally.nonStriker;
    final dismissal = ball.dismissal;
    if (dismissal != null) {
      final allowed = allowedDismissalsFor(ball.kind, freeHit: tally.freeHit);
      final outPlayer = dismissal.batter == Crease.striker
          ? striker
          : nonStriker;
      if (!allowed.contains(dismissal.how) ||
          outPlayer == null ||
          (dismissal.how != HowOut.runOut && ball.runs != 0)) {
        throw InvalidEventException(
          '${dismissal.how.name} is not possible on this ball',
        );
      }
    }

    final batter = tally.batters[striker]!;
    final bowler = tally.bowlers[tally.bowler]!;
    final over = tally.overs.last;
    final runs = ball.runs;
    final int total;
    final int conceded;
    switch (ball.kind) {
      case BallKind.legal:
        batter
          ..addRuns(runs)
          ..balls += 1;
        total = conceded = runs;
      case BallKind.wide:
        total = conceded = rules.wideRuns + runs;
        tally.wides += total;
        bowler.wides++;
      case BallKind.noBall:
        batter
          ..addRuns(runs)
          ..balls += 1;
        tally.noBalls += rules.noBallRuns;
        total = conceded = rules.noBallRuns + runs;
        bowler.noBalls++;
      case BallKind.bye:
        batter.balls++;
        tally.byes += runs;
        total = runs;
        conceded = 0;
      case BallKind.legBye:
        batter.balls++;
        tally.legByes += runs;
        total = runs;
        conceded = 0;
    }
    if (ball.kind.isLegal) {
      tally.legalBalls++;
      bowler.balls++;
    }
    tally.runs += total;
    bowler.runs += conceded;
    over
      ..balls.add(ball)
      ..runs += total
      ..bowlerRuns += conceded;

    // A free hit carries on through wides and starts again on a no-ball.
    tally.freeHit =
        rules.freeHit &&
        (ball.kind == BallKind.noBall ||
            (tally.freeHit && ball.kind == BallKind.wide));

    if (runs.isOdd) tally.swapEnds();

    if (dismissal != null) {
      final out = dismissal.batter == Crease.striker ? striker : nonStriker!;
      final credited = dismissal.how.creditsBowler;
      tally.dismiss(
        out,
        OutDetail(dismissal.how, bowler: credited ? bowler.player : null),
      );
      if (credited) bowler.wickets++;
    }

    if (over.legalBalls == ballsPerOver) {
      if (over.bowlerRuns == 0) bowler.maidens++;
      tally
        ..swapEnds()
        ..previousBowler = tally.bowler
        ..bowler = null;
    }
    _settleLastMan(tally);
  }

  /// With last man stands, the last batter bats alone and keeps the strike.
  void _settleLastMan(_InningsTally tally) {
    if (!rules.lastManStands || tally.isComplete) return;
    if (tally.striker != null && tally.nonStriker != null) return;
    if (_available(tally).isNotEmpty) return;
    final alone = tally.striker ?? tally.nonStriker;
    tally
      ..striker = alone
      ..nonStriker = null;
  }
}
