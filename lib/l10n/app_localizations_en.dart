// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Gully Cricket Scorer';

  @override
  String shareFooter(String url) {
    return 'Scored with Gully Cricket Scorer: $url';
  }

  @override
  String get historyTitle => 'Matches';

  @override
  String get historyEmptyTitle => 'No matches yet';

  @override
  String get historyEmptyBody =>
      'Tap New match to score your first game. Everything stays on this device.';

  @override
  String get historyLoadError => 'Couldn\'t load your matches.';

  @override
  String get retry => 'Retry';

  @override
  String get newMatch => 'New match';

  @override
  String get matchInProgress => 'In progress';

  @override
  String get matchNotStarted => 'Not started';

  @override
  String get deleteMatch => 'Delete match';

  @override
  String get deleteMatchTitle => 'Delete this match?';

  @override
  String get deleteMatchBody =>
      'The score and scorecard will be removed from this device.';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get storageError => 'Couldn\'t save to this device.';

  @override
  String teamVersusTeam(String teamA, String teamB) {
    return '$teamA v $teamB';
  }

  @override
  String get setupTitle => 'New match';

  @override
  String get teamOne => 'Team 1';

  @override
  String get teamTwo => 'Team 2';

  @override
  String get defaultTeamOne => 'Team A';

  @override
  String get defaultTeamTwo => 'Team B';

  @override
  String get teamName => 'Team name';

  @override
  String get playerNames => 'Player names (optional)';

  @override
  String get playerNamesHint => 'One name per line';

  @override
  String defaultPlayerName(int number) {
    return 'Player $number';
  }

  @override
  String get oversPerInnings => 'Overs per innings';

  @override
  String get playersPerSide => 'Players per side';

  @override
  String get oversInvalid => 'Enter 1 to 99 overs';

  @override
  String get playersInvalid => 'Enter 2 to 30 players';

  @override
  String get battingFirst => 'Batting first';

  @override
  String get gullyRules => 'Gully rules';

  @override
  String get lastManStands => 'Last man stands';

  @override
  String get lastManStandsHint => 'The last batter carries on alone';

  @override
  String get wideGivesRun => 'Wide gives a run';

  @override
  String get noBallGivesRun => 'No-ball gives a run';

  @override
  String get freeHit => 'Free hit after a no-ball';

  @override
  String get startMatch => 'Start match';

  @override
  String get undo => 'Undo';

  @override
  String get scorecard => 'Scorecard';

  @override
  String get moreActions => 'More';

  @override
  String get swapStrike => 'Swap strike';

  @override
  String get retireWho => 'Who is retiring?';

  @override
  String get matchNotFound => 'This match isn\'t on this device any more.';

  @override
  String get matchLoadError => 'Couldn\'t open this match.';

  @override
  String get backToMatches => 'Back to matches';

  @override
  String get firstInnings => '1st innings';

  @override
  String get secondInnings => '2nd innings';

  @override
  String get superOver => 'Super over';

  @override
  String scoreLine(int runs, int wickets) {
    return '$runs/$wickets';
  }

  @override
  String oversLine(String overs, int maxOvers) {
    return '$overs of $maxOvers overs';
  }

  @override
  String currentRate(String rate) {
    return 'Run rate $rate';
  }

  @override
  String requiredRate(String rate) {
    return 'Required $rate';
  }

  @override
  String chaseStatus(int runs, int balls) {
    String _temp0 = intl.Intl.pluralLogic(
      runs,
      locale: localeName,
      other: '$runs runs',
      one: '1 run',
    );
    String _temp1 = intl.Intl.pluralLogic(
      balls,
      locale: localeName,
      other: '$balls balls',
      one: '1 ball',
    );
    return 'Need $_temp0 from $_temp1';
  }

  @override
  String targetLine(int target) {
    return 'Target $target';
  }

  @override
  String get freeHitBadge => 'Free hit';

  @override
  String get onStrike => 'on strike';

  @override
  String batterLine(int runs, int balls) {
    return '$runs ($balls)';
  }

  @override
  String bowlerLine(String overs, int maidens, int runs, int wickets) {
    return '$overs-$maidens-$runs-$wickets';
  }

  @override
  String get thisOver => 'This over';

  @override
  String get noBallsYet => 'No balls yet';

  @override
  String get wide => 'Wide';

  @override
  String get noBall => 'No ball';

  @override
  String get bye => 'Bye';

  @override
  String get legBye => 'Leg bye';

  @override
  String get wicket => 'Wicket';

  @override
  String runsButton(int runs) {
    String _temp0 = intl.Intl.pluralLogic(
      runs,
      locale: localeName,
      other: '$runs runs',
      one: '1 run',
      zero: 'Dot ball',
    );
    return '$_temp0';
  }

  @override
  String get wideSheetTitle => 'Wide: runs taken';

  @override
  String get noBallSheetTitle => 'No ball: runs off the bat';

  @override
  String get byeSheetTitle => 'Byes: runs taken';

  @override
  String get legByeSheetTitle => 'Leg byes: runs taken';

  @override
  String get howOutTitle => 'How out?';

  @override
  String get runOutTitle => 'Run out';

  @override
  String get whoIsOut => 'Who is out?';

  @override
  String get runsCompleted => 'Runs completed';

  @override
  String get deliveryType => 'Off a';

  @override
  String get fairBall => 'Fair ball';

  @override
  String get confirm => 'Confirm';

  @override
  String get howBowled => 'Bowled';

  @override
  String get howCaught => 'Caught';

  @override
  String get howLbw => 'LBW';

  @override
  String get howStumped => 'Stumped';

  @override
  String get howHitWicket => 'Hit wicket';

  @override
  String get howRunOut => 'Run out';

  @override
  String get howRetired => 'Retired';

  @override
  String get ballWide => 'Wd';

  @override
  String get ballNoBall => 'Nb';

  @override
  String get ballBye => 'B';

  @override
  String get ballLegBye => 'Lb';

  @override
  String get ballWicket => 'W';

  @override
  String openersTitle(String team) {
    return '$team to bat';
  }

  @override
  String superOverOpenersTitle(String team) {
    return 'Super over: $team to bat';
  }

  @override
  String get striker => 'Striker';

  @override
  String get nonStriker => 'Non-striker';

  @override
  String openingBowler(String team) {
    return 'Bowler ($team)';
  }

  @override
  String get openersMustDiffer => 'Pick two different batters';

  @override
  String get startInnings => 'Start innings';

  @override
  String inningsBreak(
    String team,
    int runs,
    int wickets,
    String chasers,
    int target,
  ) {
    return '$team made $runs/$wickets. $chasers need $target to win.';
  }

  @override
  String chooseBowlerTitle(int over) {
    return 'Over $over: who bowls?';
  }

  @override
  String get chooseBatterTitle => 'Who comes in?';

  @override
  String resultWonByRuns(String team, int runs) {
    String _temp0 = intl.Intl.pluralLogic(
      runs,
      locale: localeName,
      other: '$runs runs',
      one: '1 run',
    );
    return '$team won by $_temp0';
  }

  @override
  String resultWonByWickets(String team, int wickets) {
    String _temp0 = intl.Intl.pluralLogic(
      wickets,
      locale: localeName,
      other: '$wickets wickets',
      one: '1 wicket',
    );
    return '$team won by $_temp0';
  }

  @override
  String resultWonSuperOver(String team) {
    return '$team won the super over';
  }

  @override
  String get resultTied => 'Match tied';

  @override
  String get playSuperOver => 'Play a super over';

  @override
  String get viewScorecard => 'View scorecard';

  @override
  String get batting => 'Batting';

  @override
  String get bowling => 'Bowling';

  @override
  String get colRuns => 'R';

  @override
  String get colBalls => 'B';

  @override
  String get colFours => '4s';

  @override
  String get colSixes => '6s';

  @override
  String get colStrikeRate => 'SR';

  @override
  String get colOvers => 'O';

  @override
  String get colMaidens => 'M';

  @override
  String get colWickets => 'W';

  @override
  String get colEconomy => 'Econ';

  @override
  String get extras => 'Extras';

  @override
  String extrasDetail(int wides, int noBalls, int byes, int legByes) {
    return 'wd $wides, nb $noBalls, b $byes, lb $legByes';
  }

  @override
  String get total => 'Total';

  @override
  String totalDetail(int runs, int wickets, String overs) {
    return '$runs/$wickets ($overs ov)';
  }

  @override
  String get didNotBat => 'Did not bat';

  @override
  String get fallOfWickets => 'Fall of wickets';

  @override
  String fallOfWicketEntry(int wicket, int runs, String player, String overs) {
    return '$wicket-$runs ($player, $overs ov)';
  }

  @override
  String get overByOver => 'Over by over';

  @override
  String overNumber(int number) {
    return 'Over $number';
  }

  @override
  String overRuns(int runs) {
    String _temp0 = intl.Intl.pluralLogic(
      runs,
      locale: localeName,
      other: '$runs runs',
      one: '1 run',
    );
    return '$_temp0';
  }

  @override
  String inningsTitle(String team) {
    return '$team innings';
  }

  @override
  String superOverTitle(String team) {
    return '$team super over';
  }

  @override
  String get noInningsYet => 'The scorecard fills in as the match is played.';

  @override
  String get notOut => 'not out';

  @override
  String outBowled(String bowler) {
    return 'b $bowler';
  }

  @override
  String outCaught(String bowler) {
    return 'ct b $bowler';
  }

  @override
  String outLbw(String bowler) {
    return 'lbw b $bowler';
  }

  @override
  String outStumped(String bowler) {
    return 'st b $bowler';
  }

  @override
  String outHitWicket(String bowler) {
    return 'hit wicket b $bowler';
  }

  @override
  String get outRunOut => 'run out';

  @override
  String get outRetired => 'retired';

  @override
  String get shareText => 'Share as text';

  @override
  String get copyText => 'Copy as text';

  @override
  String get copied => 'Scorecard copied. Paste it into any chat.';

  @override
  String get shareFailed => 'Couldn\'t share the scorecard.';

  @override
  String get shareUnavailable =>
      'Sharing isn\'t available here, so the scorecard was copied instead.';
}
