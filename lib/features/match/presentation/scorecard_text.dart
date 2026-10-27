import '../../../core/app_links.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/innings_state.dart';
import '../domain/match_state.dart';
import 'format.dart';

/// The scorecard as plain text that reads well in WhatsApp: bold with
/// asterisks, one line per batter and bowler, no tables.
String scorecardText(MatchState match, AppLocalizations l10n) {
  final setup = match.setup;
  final lines = <String>['*${matchTitle(setup, l10n)}*'];
  if (match.result case final result?) {
    lines.add(resultText(result, setup, l10n));
  }
  for (final innings in match.innings) {
    lines
      ..add('')
      ..addAll(_inningsLines(innings, match, l10n));
  }
  lines
    ..add('')
    ..add(l10n.shareFooter(appUrl));
  return lines.join('\n');
}

Iterable<String> _inningsLines(
  InningsState innings,
  MatchState match,
  AppLocalizations l10n,
) sync* {
  final setup = match.setup;
  final total = l10n.totalDetail(
    innings.runs,
    innings.wickets,
    oversText(innings.legalBalls),
  );
  yield '*${inningsTitle(innings, setup, l10n)}*: $total';
  for (final batter in innings.batters) {
    final name = playerName(setup, innings.battingTeam, batter.player);
    yield '$name ${l10n.batterLine(batter.runs, batter.balls)}, '
        '${outText(batter.out, setup, innings, l10n)}';
  }
  final extras = innings.extras;
  if (extras.total > 0) {
    yield '${l10n.extras} ${extras.total} '
        '(${l10n.extrasDetail(extras.wides, extras.noBalls, extras.byes, extras.legByes)})';
  }
  yield '_${l10n.bowling}_';
  for (final figures in innings.bowlers) {
    final name = playerName(setup, innings.bowlingTeam, figures.player);
    yield '$name ${figuresText(figures, l10n)}';
  }
}
