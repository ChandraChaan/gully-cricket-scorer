import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Gully Cricket Scorer'**
  String get appTitle;

  /// No description provided for @shareFooter.
  ///
  /// In en, this message translates to:
  /// **'Scored with Gully Cricket Scorer: {url}'**
  String shareFooter(String url);

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get historyTitle;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No matches yet'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Tap New match to score your first game. Everything stays on this device.'**
  String get historyEmptyBody;

  /// No description provided for @historyLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your matches.'**
  String get historyLoadError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @newMatch.
  ///
  /// In en, this message translates to:
  /// **'New match'**
  String get newMatch;

  /// No description provided for @matchInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get matchInProgress;

  /// No description provided for @matchNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get matchNotStarted;

  /// No description provided for @deleteMatch.
  ///
  /// In en, this message translates to:
  /// **'Delete match'**
  String get deleteMatch;

  /// No description provided for @deleteMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this match?'**
  String get deleteMatchTitle;

  /// No description provided for @deleteMatchBody.
  ///
  /// In en, this message translates to:
  /// **'The score and scorecard will be removed from this device.'**
  String get deleteMatchBody;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @storageError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save to this device.'**
  String get storageError;

  /// No description provided for @teamVersusTeam.
  ///
  /// In en, this message translates to:
  /// **'{teamA} v {teamB}'**
  String teamVersusTeam(String teamA, String teamB);

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'New match'**
  String get setupTitle;

  /// No description provided for @teamOne.
  ///
  /// In en, this message translates to:
  /// **'Team 1'**
  String get teamOne;

  /// No description provided for @teamTwo.
  ///
  /// In en, this message translates to:
  /// **'Team 2'**
  String get teamTwo;

  /// No description provided for @defaultTeamOne.
  ///
  /// In en, this message translates to:
  /// **'Team A'**
  String get defaultTeamOne;

  /// No description provided for @defaultTeamTwo.
  ///
  /// In en, this message translates to:
  /// **'Team B'**
  String get defaultTeamTwo;

  /// No description provided for @teamName.
  ///
  /// In en, this message translates to:
  /// **'Team name'**
  String get teamName;

  /// No description provided for @playerNames.
  ///
  /// In en, this message translates to:
  /// **'Player names (optional)'**
  String get playerNames;

  /// No description provided for @playerNamesHint.
  ///
  /// In en, this message translates to:
  /// **'One name per line'**
  String get playerNamesHint;

  /// No description provided for @defaultPlayerName.
  ///
  /// In en, this message translates to:
  /// **'Player {number}'**
  String defaultPlayerName(int number);

  /// No description provided for @oversPerInnings.
  ///
  /// In en, this message translates to:
  /// **'Overs per innings'**
  String get oversPerInnings;

  /// No description provided for @playersPerSide.
  ///
  /// In en, this message translates to:
  /// **'Players per side'**
  String get playersPerSide;

  /// No description provided for @oversInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter 1 to 99 overs'**
  String get oversInvalid;

  /// No description provided for @playersInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter 2 to 30 players'**
  String get playersInvalid;

  /// No description provided for @battingFirst.
  ///
  /// In en, this message translates to:
  /// **'Batting first'**
  String get battingFirst;

  /// No description provided for @gullyRules.
  ///
  /// In en, this message translates to:
  /// **'Gully rules'**
  String get gullyRules;

  /// No description provided for @lastManStands.
  ///
  /// In en, this message translates to:
  /// **'Last man stands'**
  String get lastManStands;

  /// No description provided for @lastManStandsHint.
  ///
  /// In en, this message translates to:
  /// **'The last batter carries on alone'**
  String get lastManStandsHint;

  /// No description provided for @wideGivesRun.
  ///
  /// In en, this message translates to:
  /// **'Wide gives a run'**
  String get wideGivesRun;

  /// No description provided for @noBallGivesRun.
  ///
  /// In en, this message translates to:
  /// **'No-ball gives a run'**
  String get noBallGivesRun;

  /// No description provided for @freeHit.
  ///
  /// In en, this message translates to:
  /// **'Free hit after a no-ball'**
  String get freeHit;

  /// No description provided for @startMatch.
  ///
  /// In en, this message translates to:
  /// **'Start match'**
  String get startMatch;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @scorecard.
  ///
  /// In en, this message translates to:
  /// **'Scorecard'**
  String get scorecard;

  /// No description provided for @moreActions.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreActions;

  /// No description provided for @swapStrike.
  ///
  /// In en, this message translates to:
  /// **'Swap strike'**
  String get swapStrike;

  /// No description provided for @retireWho.
  ///
  /// In en, this message translates to:
  /// **'Who is retiring?'**
  String get retireWho;

  /// No description provided for @matchNotFound.
  ///
  /// In en, this message translates to:
  /// **'This match isn\'t on this device any more.'**
  String get matchNotFound;

  /// No description provided for @matchLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open this match.'**
  String get matchLoadError;

  /// No description provided for @backToMatches.
  ///
  /// In en, this message translates to:
  /// **'Back to matches'**
  String get backToMatches;

  /// No description provided for @firstInnings.
  ///
  /// In en, this message translates to:
  /// **'1st innings'**
  String get firstInnings;

  /// No description provided for @secondInnings.
  ///
  /// In en, this message translates to:
  /// **'2nd innings'**
  String get secondInnings;

  /// No description provided for @superOver.
  ///
  /// In en, this message translates to:
  /// **'Super over'**
  String get superOver;

  /// No description provided for @scoreLine.
  ///
  /// In en, this message translates to:
  /// **'{runs}/{wickets}'**
  String scoreLine(int runs, int wickets);

  /// No description provided for @oversLine.
  ///
  /// In en, this message translates to:
  /// **'{overs} of {maxOvers} overs'**
  String oversLine(String overs, int maxOvers);

  /// No description provided for @currentRate.
  ///
  /// In en, this message translates to:
  /// **'Run rate {rate}'**
  String currentRate(String rate);

  /// No description provided for @requiredRate.
  ///
  /// In en, this message translates to:
  /// **'Required {rate}'**
  String requiredRate(String rate);

  /// No description provided for @chaseStatus.
  ///
  /// In en, this message translates to:
  /// **'Need {runs, plural, =1{1 run} other{{runs} runs}} from {balls, plural, =1{1 ball} other{{balls} balls}}'**
  String chaseStatus(int runs, int balls);

  /// No description provided for @targetLine.
  ///
  /// In en, this message translates to:
  /// **'Target {target}'**
  String targetLine(int target);

  /// No description provided for @freeHitBadge.
  ///
  /// In en, this message translates to:
  /// **'Free hit'**
  String get freeHitBadge;

  /// No description provided for @onStrike.
  ///
  /// In en, this message translates to:
  /// **'on strike'**
  String get onStrike;

  /// No description provided for @batterLine.
  ///
  /// In en, this message translates to:
  /// **'{runs} ({balls})'**
  String batterLine(int runs, int balls);

  /// No description provided for @bowlerLine.
  ///
  /// In en, this message translates to:
  /// **'{overs}-{maidens}-{runs}-{wickets}'**
  String bowlerLine(String overs, int maidens, int runs, int wickets);

  /// No description provided for @thisOver.
  ///
  /// In en, this message translates to:
  /// **'This over'**
  String get thisOver;

  /// No description provided for @noBallsYet.
  ///
  /// In en, this message translates to:
  /// **'No balls yet'**
  String get noBallsYet;

  /// No description provided for @wide.
  ///
  /// In en, this message translates to:
  /// **'Wide'**
  String get wide;

  /// No description provided for @noBall.
  ///
  /// In en, this message translates to:
  /// **'No ball'**
  String get noBall;

  /// No description provided for @bye.
  ///
  /// In en, this message translates to:
  /// **'Bye'**
  String get bye;

  /// No description provided for @legBye.
  ///
  /// In en, this message translates to:
  /// **'Leg bye'**
  String get legBye;

  /// No description provided for @wicket.
  ///
  /// In en, this message translates to:
  /// **'Wicket'**
  String get wicket;

  /// No description provided for @runsButton.
  ///
  /// In en, this message translates to:
  /// **'{runs, plural, =0{Dot ball} =1{1 run} other{{runs} runs}}'**
  String runsButton(int runs);

  /// No description provided for @wideSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Wide: runs taken'**
  String get wideSheetTitle;

  /// No description provided for @noBallSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'No ball: runs off the bat'**
  String get noBallSheetTitle;

  /// No description provided for @byeSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Byes: runs taken'**
  String get byeSheetTitle;

  /// No description provided for @legByeSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Leg byes: runs taken'**
  String get legByeSheetTitle;

  /// No description provided for @howOutTitle.
  ///
  /// In en, this message translates to:
  /// **'How out?'**
  String get howOutTitle;

  /// No description provided for @runOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Run out'**
  String get runOutTitle;

  /// No description provided for @whoIsOut.
  ///
  /// In en, this message translates to:
  /// **'Who is out?'**
  String get whoIsOut;

  /// No description provided for @runsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Runs completed'**
  String get runsCompleted;

  /// No description provided for @deliveryType.
  ///
  /// In en, this message translates to:
  /// **'Off a'**
  String get deliveryType;

  /// No description provided for @fairBall.
  ///
  /// In en, this message translates to:
  /// **'Fair ball'**
  String get fairBall;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @howBowled.
  ///
  /// In en, this message translates to:
  /// **'Bowled'**
  String get howBowled;

  /// No description provided for @howCaught.
  ///
  /// In en, this message translates to:
  /// **'Caught'**
  String get howCaught;

  /// No description provided for @howLbw.
  ///
  /// In en, this message translates to:
  /// **'LBW'**
  String get howLbw;

  /// No description provided for @howStumped.
  ///
  /// In en, this message translates to:
  /// **'Stumped'**
  String get howStumped;

  /// No description provided for @howHitWicket.
  ///
  /// In en, this message translates to:
  /// **'Hit wicket'**
  String get howHitWicket;

  /// No description provided for @howRunOut.
  ///
  /// In en, this message translates to:
  /// **'Run out'**
  String get howRunOut;

  /// No description provided for @howRetired.
  ///
  /// In en, this message translates to:
  /// **'Retired'**
  String get howRetired;

  /// No description provided for @ballWide.
  ///
  /// In en, this message translates to:
  /// **'Wd'**
  String get ballWide;

  /// No description provided for @ballNoBall.
  ///
  /// In en, this message translates to:
  /// **'Nb'**
  String get ballNoBall;

  /// No description provided for @ballBye.
  ///
  /// In en, this message translates to:
  /// **'B'**
  String get ballBye;

  /// No description provided for @ballLegBye.
  ///
  /// In en, this message translates to:
  /// **'Lb'**
  String get ballLegBye;

  /// No description provided for @ballWicket.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get ballWicket;

  /// No description provided for @openersTitle.
  ///
  /// In en, this message translates to:
  /// **'{team} to bat'**
  String openersTitle(String team);

  /// No description provided for @superOverOpenersTitle.
  ///
  /// In en, this message translates to:
  /// **'Super over: {team} to bat'**
  String superOverOpenersTitle(String team);

  /// No description provided for @striker.
  ///
  /// In en, this message translates to:
  /// **'Striker'**
  String get striker;

  /// No description provided for @nonStriker.
  ///
  /// In en, this message translates to:
  /// **'Non-striker'**
  String get nonStriker;

  /// No description provided for @openingBowler.
  ///
  /// In en, this message translates to:
  /// **'Bowler ({team})'**
  String openingBowler(String team);

  /// No description provided for @openersMustDiffer.
  ///
  /// In en, this message translates to:
  /// **'Pick two different batters'**
  String get openersMustDiffer;

  /// No description provided for @startInnings.
  ///
  /// In en, this message translates to:
  /// **'Start innings'**
  String get startInnings;

  /// No description provided for @inningsBreak.
  ///
  /// In en, this message translates to:
  /// **'{team} made {runs}/{wickets}. {chasers} need {target} to win.'**
  String inningsBreak(
    String team,
    int runs,
    int wickets,
    String chasers,
    int target,
  );

  /// No description provided for @chooseBowlerTitle.
  ///
  /// In en, this message translates to:
  /// **'Over {over}: who bowls?'**
  String chooseBowlerTitle(int over);

  /// No description provided for @chooseBatterTitle.
  ///
  /// In en, this message translates to:
  /// **'Who comes in?'**
  String get chooseBatterTitle;

  /// No description provided for @resultWonByRuns.
  ///
  /// In en, this message translates to:
  /// **'{team} won by {runs, plural, =1{1 run} other{{runs} runs}}'**
  String resultWonByRuns(String team, int runs);

  /// No description provided for @resultWonByWickets.
  ///
  /// In en, this message translates to:
  /// **'{team} won by {wickets, plural, =1{1 wicket} other{{wickets} wickets}}'**
  String resultWonByWickets(String team, int wickets);

  /// No description provided for @resultWonSuperOver.
  ///
  /// In en, this message translates to:
  /// **'{team} won the super over'**
  String resultWonSuperOver(String team);

  /// No description provided for @resultTied.
  ///
  /// In en, this message translates to:
  /// **'Match tied'**
  String get resultTied;

  /// No description provided for @playSuperOver.
  ///
  /// In en, this message translates to:
  /// **'Play a super over'**
  String get playSuperOver;

  /// No description provided for @viewScorecard.
  ///
  /// In en, this message translates to:
  /// **'View scorecard'**
  String get viewScorecard;

  /// No description provided for @batting.
  ///
  /// In en, this message translates to:
  /// **'Batting'**
  String get batting;

  /// No description provided for @bowling.
  ///
  /// In en, this message translates to:
  /// **'Bowling'**
  String get bowling;

  /// No description provided for @colRuns.
  ///
  /// In en, this message translates to:
  /// **'R'**
  String get colRuns;

  /// No description provided for @colBalls.
  ///
  /// In en, this message translates to:
  /// **'B'**
  String get colBalls;

  /// No description provided for @colFours.
  ///
  /// In en, this message translates to:
  /// **'4s'**
  String get colFours;

  /// No description provided for @colSixes.
  ///
  /// In en, this message translates to:
  /// **'6s'**
  String get colSixes;

  /// No description provided for @colStrikeRate.
  ///
  /// In en, this message translates to:
  /// **'SR'**
  String get colStrikeRate;

  /// No description provided for @colOvers.
  ///
  /// In en, this message translates to:
  /// **'O'**
  String get colOvers;

  /// No description provided for @colMaidens.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get colMaidens;

  /// No description provided for @colWickets.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get colWickets;

  /// No description provided for @colEconomy.
  ///
  /// In en, this message translates to:
  /// **'Econ'**
  String get colEconomy;

  /// No description provided for @extras.
  ///
  /// In en, this message translates to:
  /// **'Extras'**
  String get extras;

  /// No description provided for @extrasDetail.
  ///
  /// In en, this message translates to:
  /// **'wd {wides}, nb {noBalls}, b {byes}, lb {legByes}'**
  String extrasDetail(int wides, int noBalls, int byes, int legByes);

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @totalDetail.
  ///
  /// In en, this message translates to:
  /// **'{runs}/{wickets} ({overs} ov)'**
  String totalDetail(int runs, int wickets, String overs);

  /// No description provided for @didNotBat.
  ///
  /// In en, this message translates to:
  /// **'Did not bat'**
  String get didNotBat;

  /// No description provided for @fallOfWickets.
  ///
  /// In en, this message translates to:
  /// **'Fall of wickets'**
  String get fallOfWickets;

  /// No description provided for @fallOfWicketEntry.
  ///
  /// In en, this message translates to:
  /// **'{wicket}-{runs} ({player}, {overs} ov)'**
  String fallOfWicketEntry(int wicket, int runs, String player, String overs);

  /// No description provided for @overByOver.
  ///
  /// In en, this message translates to:
  /// **'Over by over'**
  String get overByOver;

  /// No description provided for @overNumber.
  ///
  /// In en, this message translates to:
  /// **'Over {number}'**
  String overNumber(int number);

  /// No description provided for @overRuns.
  ///
  /// In en, this message translates to:
  /// **'{runs, plural, =1{1 run} other{{runs} runs}}'**
  String overRuns(int runs);

  /// No description provided for @inningsTitle.
  ///
  /// In en, this message translates to:
  /// **'{team} innings'**
  String inningsTitle(String team);

  /// No description provided for @superOverTitle.
  ///
  /// In en, this message translates to:
  /// **'{team} super over'**
  String superOverTitle(String team);

  /// No description provided for @noInningsYet.
  ///
  /// In en, this message translates to:
  /// **'The scorecard fills in as the match is played.'**
  String get noInningsYet;

  /// No description provided for @notOut.
  ///
  /// In en, this message translates to:
  /// **'not out'**
  String get notOut;

  /// No description provided for @outBowled.
  ///
  /// In en, this message translates to:
  /// **'b {bowler}'**
  String outBowled(String bowler);

  /// No description provided for @outCaught.
  ///
  /// In en, this message translates to:
  /// **'ct b {bowler}'**
  String outCaught(String bowler);

  /// No description provided for @outLbw.
  ///
  /// In en, this message translates to:
  /// **'lbw b {bowler}'**
  String outLbw(String bowler);

  /// No description provided for @outStumped.
  ///
  /// In en, this message translates to:
  /// **'st b {bowler}'**
  String outStumped(String bowler);

  /// No description provided for @outHitWicket.
  ///
  /// In en, this message translates to:
  /// **'hit wicket b {bowler}'**
  String outHitWicket(String bowler);

  /// No description provided for @outRunOut.
  ///
  /// In en, this message translates to:
  /// **'run out'**
  String get outRunOut;

  /// No description provided for @outRetired.
  ///
  /// In en, this message translates to:
  /// **'retired'**
  String get outRetired;

  /// No description provided for @shareText.
  ///
  /// In en, this message translates to:
  /// **'Share as text'**
  String get shareText;

  /// No description provided for @copyText.
  ///
  /// In en, this message translates to:
  /// **'Copy as text'**
  String get copyText;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Scorecard copied. Paste it into any chat.'**
  String get copied;

  /// No description provided for @shareImage.
  ///
  /// In en, this message translates to:
  /// **'Share as image'**
  String get shareImage;

  /// No description provided for @shareImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the scorecard image.'**
  String get shareImageFailed;

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t share the scorecard.'**
  String get shareFailed;

  /// No description provided for @shareUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sharing isn\'t available here, so the scorecard was copied instead.'**
  String get shareUnavailable;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
