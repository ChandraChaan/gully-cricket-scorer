// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Gully Games';

  @override
  String shareFooter(String url) {
    return 'Scored with Gully Games: $url';
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
  String get shareImage => 'Share as image';

  @override
  String get shareImageFailed => 'Couldn\'t create the scorecard image.';

  @override
  String get shareFailed => 'Couldn\'t share the scorecard.';

  @override
  String get shareUnavailable =>
      'Sharing isn\'t available here, so the scorecard was copied instead.';

  @override
  String get gamesIntro =>
      'Quick games from the gully and the maidan. Best scores stay on this device.';

  @override
  String get gamesBack => 'Back to games';

  @override
  String get games3d => '3D';

  @override
  String get games2d => '2D';

  @override
  String get gameStart => 'Start';

  @override
  String get gamePause => 'Pause';

  @override
  String get gamePaused => 'Paused';

  @override
  String get gameResume => 'Resume';

  @override
  String get gameOver => 'Game over';

  @override
  String get gamePlayAgain => 'Play again';

  @override
  String get gameNewBest => 'New best score!';

  @override
  String gameScore(int score) {
    return '$score';
  }

  @override
  String gameBest(int score) {
    return 'Best: $score';
  }

  @override
  String gameLives(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lives left',
      one: '1 life left',
      zero: 'No lives left',
    );
    return '$_temp0';
  }

  @override
  String get gameBattingTitle => 'Gully Batting';

  @override
  String get gameBattingBlurb =>
      'Time your swing and clear the rooftops. Three wickets and you\'re out.';

  @override
  String get gameBattingHowTo =>
      'Hit Leg, Straight or Off just as the ball reaches the bat. Perfect timing is a six. Miss a straight one and you\'re bowled. The bowler gets quicker every over.';

  @override
  String get gameBattingLeg => 'Leg';

  @override
  String get gameBattingStraight => 'Straight';

  @override
  String get gameBattingOff => 'Off';

  @override
  String get gameBattingSix => 'SIX!';

  @override
  String get gameBattingFour => 'FOUR!';

  @override
  String gameBattingRuns(int runs) {
    String _temp0 = intl.Intl.pluralLogic(
      runs,
      locale: localeName,
      other: '$runs runs',
      one: '1 run',
    );
    return '$_temp0';
  }

  @override
  String get gameBattingDot => 'Dot ball';

  @override
  String get gameBattingBowled => 'Bowled!';

  @override
  String get gameBattingCaught => 'Caught!';

  @override
  String get gameCatchingTitle => 'High Catch';

  @override
  String get gameCatchingBlurb =>
      'Get under the skier before it lands. Drop three and it\'s over.';

  @override
  String get gameCatchingHowTo =>
      'Touch or drag where the fielder should run. The red spot shows where the ball will land and the yellow ring closes in as it drops. Catch it dead centre for double points.';

  @override
  String get gameCatchingCaught => 'Caught!';

  @override
  String get gameCatchingPerfect => 'Perfect catch!';

  @override
  String get gameCatchingDropped => 'Dropped';

  @override
  String get gameDirectHitTitle => 'Direct Hit';

  @override
  String get gameDirectHitBlurb =>
      'Throw down the stumps before the runner gets home.';

  @override
  String get gameDirectHitHowTo =>
      'Drag up to set the power and sideways to aim, then let go to throw. The dots show the ball\'s path. Hit the stumps before the runner makes the crease; hitting on the full scores double. Three runs conceded ends it.';

  @override
  String get gameDirectHitOut => 'Run out!';

  @override
  String get gameDirectHitFull => 'Direct hit!';

  @override
  String get gameDirectHitSafe => 'Safe';

  @override
  String get gameDirectHitRunner => 'Runner';

  @override
  String get gameDashTitle => 'Gully Dash';

  @override
  String get gameDashBlurb =>
      'Sprint to the match, dodging scooters, cows and potholes.';

  @override
  String get gameDashHowTo =>
      'Tap the left or right side of the screen to change lanes. Dodge everything in the way, grab cricket balls for bonus points, and keep going as the pace picks up. Three bumps and you\'re out.';

  @override
  String get homeCricket => 'Cricket';

  @override
  String get homeStreet => 'Street games';

  @override
  String get homeScorerTitle => 'Cricket scorer';

  @override
  String get homeScorerBlurb =>
      'Score a real match ball by ball, with a scorecard to share.';

  @override
  String get scorerTitle => 'Cricket scorer';

  @override
  String get gameDuelTitle => 'Akhada Duel';

  @override
  String get gameDuelBlurb =>
      'One-on-one bouts in the mud pit. Punch, kick, block.';

  @override
  String get gameDuelHowTo =>
      'Use the arrows to step in and out. Punch is quick, Kick reaches further and hits harder, and holding Block soaks up most of a hit. Beat each wrestler to meet a tougher one. Get knocked down three times and it\'s over.';

  @override
  String get gameDuelYou => 'You';

  @override
  String gameDuelOpponent(int number) {
    return 'Wrestler $number';
  }

  @override
  String get gameDuelBack => 'Back';

  @override
  String get gameDuelForward => 'In';

  @override
  String get gameDuelBlock => 'Block';

  @override
  String get gameDuelPunch => 'Punch';

  @override
  String get gameDuelKick => 'Kick';

  @override
  String get gameDuelKnockout => 'Knockout!';

  @override
  String get gameDuelDown => 'Knocked down';

  @override
  String get gameKabaddiTitle => 'Kabaddi Raid';

  @override
  String get gameKabaddiBlurb =>
      'Cross the line, tag a defender and get home in time.';

  @override
  String get gameKabaddiHowTo =>
      'Touch where the raider should run. Defenders on their feet will catch you, so tempt one into diving (they crouch and glow first), dodge, then touch them while they\'re down. Tags only count once you\'re back over the line. Get caught or run out of time three times and it\'s over.';

  @override
  String get gameKabaddiClock => 'Raid time';

  @override
  String gameKabaddiTags(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tags: get home!',
      one: '1 tag: get home!',
      zero: 'No tags yet',
    );
    return '$_temp0';
  }

  @override
  String gameKabaddiScored(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '+$points points',
      one: '+1 point',
    );
    return '$_temp0';
  }

  @override
  String get gameKabaddiCaught => 'Caught!';

  @override
  String get gameKabaddiTimeUp => 'Time up';

  @override
  String get gameGilliTitle => 'Gilli Danda';

  @override
  String get gameGilliBlurb => 'Flick the gilli up and whack it down the lane.';

  @override
  String get gameGilliHowTo =>
      'Tap once to flick the gilli into the air. Tap again as it passes through the frame to hit it: the closer to the middle, the further it flies. Your score is the total distance. Miss three and it\'s over.';

  @override
  String get gameGilliTap => 'Flick or hit';

  @override
  String get gameGilliFlick => 'Tap to flick';

  @override
  String get gameGilliSwing => 'Tap to hit!';

  @override
  String gameGilliPerfect(int metres) {
    return 'Perfect! $metres m';
  }

  @override
  String gameGilliDistance(int metres) {
    return '$metres m';
  }

  @override
  String get gameGilliMiss => 'Missed';

  @override
  String get gameKiteTitle => 'Kite Fight';

  @override
  String get gameKiteBlurb =>
      'Cut the other kites\' strings before they cut yours.';

  @override
  String get gameKiteHowTo =>
      'Drag to fly your blue kite. Sweep your string quickly across a rival\'s string to cut it: the faster kite wins. A rival that wobbles is about to swoop at your string, so keep moving. Lose three kites and it\'s over.';

  @override
  String get gameCarromTitle => 'Carrom Strike';

  @override
  String get gameCarromBlurb => 'Pocket the coins before the clock runs out.';

  @override
  String get gameCarromHowTo =>
      'Touch the board to place the striker, pull back to aim and let go to shoot. Black is 1, white is 2 and the red queen is 5, and every coin adds 3 seconds. Sinking the striker is a foul: three fouls end the game.';

  @override
  String get gameCarromClock => 'Time left';

  @override
  String gameCarromSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get gameCarromFoul => 'Foul!';
}
