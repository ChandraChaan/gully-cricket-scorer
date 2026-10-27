import '../../../l10n/app_localizations.dart';
import '../domain/innings_state.dart';
import '../domain/match_event.dart';
import '../domain/match_setup.dart';
import '../domain/match_state.dart';

/// Overs as cricket writes them: 13 balls is "2.1", 12 balls is "2".
String oversText(int balls) {
  final overs = balls ~/ ballsPerOver;
  final rest = balls % ballsPerOver;
  return rest == 0 ? '$overs' : '$overs.$rest';
}

/// A rate with two decimals, or a dash when there is none yet.
String rateText(double? rate) => rate == null ? '-' : rate.toStringAsFixed(2);

String playerName(MatchSetup setup, int team, int player) =>
    setup.teams[team].players[player];

String matchTitle(MatchSetup setup, AppLocalizations l10n) =>
    l10n.teamVersusTeam(setup.teams[0].name, setup.teams[1].name);

String resultText(MatchResult result, MatchSetup setup, AppLocalizations l10n) {
  switch (result) {
    case Tie():
      return l10n.resultTied;
    case Win(:final winner, :final margin, :final inSuperOver):
      final team = setup.teams[winner].name;
      if (inSuperOver) return l10n.resultWonSuperOver(team);
      return switch (margin) {
        ByRuns(:final runs) => l10n.resultWonByRuns(team, runs),
        ByWickets(:final wickets) => l10n.resultWonByWickets(team, wickets),
      };
  }
}

String inningsTitle(
  InningsState innings,
  MatchSetup setup,
  AppLocalizations l10n,
) {
  final team = setup.teams[innings.battingTeam].name;
  return innings.isSuperOver
      ? l10n.superOverTitle(team)
      : l10n.inningsTitle(team);
}

String howOutName(HowOut how, AppLocalizations l10n) => switch (how) {
  HowOut.bowled => l10n.howBowled,
  HowOut.caught => l10n.howCaught,
  HowOut.lbw => l10n.howLbw,
  HowOut.stumped => l10n.howStumped,
  HowOut.hitWicket => l10n.howHitWicket,
  HowOut.runOut => l10n.howRunOut,
  HowOut.retired => l10n.howRetired,
};

/// The dismissal column of a scorecard: "b Ravi", "run out", "not out".
String outText(
  OutDetail? out,
  MatchSetup setup,
  InningsState innings,
  AppLocalizations l10n,
) {
  if (out == null) return l10n.notOut;
  final bowler = out.bowler == null
      ? ''
      : playerName(setup, innings.bowlingTeam, out.bowler!);
  return switch (out.how) {
    HowOut.bowled => l10n.outBowled(bowler),
    HowOut.caught => l10n.outCaught(bowler),
    HowOut.lbw => l10n.outLbw(bowler),
    HowOut.stumped => l10n.outStumped(bowler),
    HowOut.hitWicket => l10n.outHitWicket(bowler),
    HowOut.runOut => l10n.outRunOut,
    HowOut.retired => l10n.outRetired,
  };
}

/// A short label for one delivery: "4", "Wd", "Nb+2", "1Lb", "W".
String ballLabel(BallBowled ball, AppLocalizations l10n) {
  final runs = ball.runs;
  final base = switch (ball.kind) {
    BallKind.legal => '$runs',
    BallKind.wide => runs == 0 ? l10n.ballWide : '${l10n.ballWide}+$runs',
    BallKind.noBall => runs == 0 ? l10n.ballNoBall : '${l10n.ballNoBall}+$runs',
    BallKind.bye => '$runs${l10n.ballBye}',
    BallKind.legBye => '$runs${l10n.ballLegBye}',
  };
  if (ball.dismissal == null) return base;
  if (ball.kind == BallKind.legal && runs == 0) return l10n.ballWicket;
  return '$base+${l10n.ballWicket}';
}

/// Bowling figures as overs-maidens-runs-wickets.
String figuresText(BowlerFigures figures, AppLocalizations l10n) =>
    l10n.bowlerLine(
      oversText(figures.balls),
      figures.maidens,
      figures.runs,
      figures.wickets,
    );
