import 'package:flutter_test/flutter_test.dart';
import 'package:gully_cricket_scorer/features/match/domain/match_event.dart';
import 'package:gully_cricket_scorer/features/match/domain/match_setup.dart';
import 'package:gully_cricket_scorer/features/match/domain/match_state.dart';
import 'package:gully_cricket_scorer/features/match/domain/saved_match.dart';

MatchSetup setupWith({
  int overs = 2,
  int players = 4,
  bool lastManStands = false,
  int wideRuns = 1,
  int noBallRuns = 1,
  bool freeHit = true,
  int battingFirst = 0,
}) => MatchSetup(
  id: 'm1',
  createdAt: DateTime.utc(2026, 10, 27, 9),
  teams: [
    Team(name: 'Lions', players: [for (var i = 1; i <= players; i++) 'L$i']),
    Team(name: 'Tigers', players: [for (var i = 1; i <= players; i++) 'T$i']),
  ],
  battingFirst: battingFirst,
  rules: MatchRules(
    oversPerInnings: overs,
    playersPerSide: players,
    lastManStands: lastManStands,
    wideRuns: wideRuns,
    noBallRuns: noBallRuns,
    freeHit: freeHit,
  ),
);

const open = InningsStarted(striker: 0, nonStriker: 1, bowler: 0);
const dot = BallBowled.runs(0);
const one = BallBowled.runs(1);
const two = BallBowled.runs(2);
const four = BallBowled.runs(4);
const six = BallBowled.runs(6);
const bowled = BallBowled(
  kind: BallKind.legal,
  dismissal: Dismissal(HowOut.bowled),
);
const caught = BallBowled(
  kind: BallKind.legal,
  dismissal: Dismissal(HowOut.caught),
);
BallBowled wide([int runs = 0]) => BallBowled(kind: BallKind.wide, runs: runs);
BallBowled noBall([int runs = 0]) =>
    BallBowled(kind: BallKind.noBall, runs: runs);

MatchState play(MatchSetup setup, List<MatchEvent> events) =>
    MatchState.replay(setup, events);

/// Six dots from the current bowler.
List<MatchEvent> maidenOver() => List.filled(6, dot);

void main() {
  group('starting', () {
    test('a new match asks for openers of the side batting first', () {
      final state = play(setupWith(battingFirst: 1), []);
      final next = state.next as ChooseOpeners;
      expect(next.innings, 0);
      expect(next.battingTeam, 1);
      expect(next.isSuperOver, isFalse);
      expect(state.isStarted, isFalse);
    });

    test('openers take guard and the bowler is ready', () {
      final innings = play(setupWith(), [open]).currentInnings!;
      expect(innings.striker, 0);
      expect(innings.nonStriker, 1);
      expect(innings.bowler, 0);
      expect(innings.battingTeam, 0);
      expect(innings.target, isNull);
    });

    test('rejects the same player at both ends', () {
      expect(
        () => play(setupWith(), [
          const InningsStarted(striker: 1, nonStriker: 1, bowler: 0),
        ]),
        throwsA(isA<InvalidEventException>()),
      );
    });

    test('rejects a ball before the innings starts', () {
      expect(
        () => play(setupWith(), [one]),
        throwsA(isA<InvalidEventException>()),
      );
    });
  });

  group('runs and strike', () {
    test('odd runs swap the strike, even runs keep it', () {
      var state = play(setupWith(), [open, one]);
      expect(state.currentInnings!.striker, 1);
      state = state.apply(two);
      expect(state.currentInnings!.striker, 1);
      state = state.apply(const BallBowled.runs(3));
      expect(state.currentInnings!.striker, 0);
    });

    test('batters get runs, balls, fours and sixes', () {
      final innings = play(setupWith(), [
        open,
        four,
        six,
        dot,
        one,
      ]).currentInnings!;
      final opener = innings.batter(0)!;
      expect(opener.runs, 11);
      expect(opener.balls, 4);
      expect(opener.fours, 1);
      expect(opener.sixes, 1);
      expect(opener.strikeRate, closeTo(275, 0.001));
      expect(innings.batter(1)!.balls, 0);
      expect(innings.batter(1)!.strikeRate, isNull);
      expect(innings.runs, 11);
    });

    test('the strike changes at the end of an over', () {
      final innings = play(setupWith(), [
        open,
        ...maidenOver(),
      ]).currentInnings!;
      expect(innings.striker, 1);
      expect(innings.nonStriker, 0);
    });

    test('a single off the last ball keeps the batter on strike', () {
      final innings = play(setupWith(), [
        open,
        ...List.filled(5, dot),
        one,
      ]).currentInnings!;
      expect(innings.striker, 0);
    });

    test('swapping strike by hand needs no ball', () {
      final innings = play(setupWith(), [
        open,
        const StrikeSwapped(),
      ]).currentInnings!;
      expect(innings.striker, 1);
      expect(innings.legalBalls, 0);
    });
  });

  group('extras', () {
    test('wides and no-balls are not legal balls', () {
      final innings = play(setupWith(), [
        open,
        wide(),
        noBall(),
        dot,
      ]).currentInnings!;
      expect(innings.legalBalls, 1);
      expect(innings.currentOver!.balls, hasLength(3));
      expect(innings.currentOver!.legalBalls, 1);
    });

    test('an over needs six legal balls', () {
      final state = play(setupWith(), [
        open,
        ...List.filled(5, dot),
        wide(),
        noBall(),
      ]);
      expect(state.next, isA<Bowl>());
      expect(state.apply(dot).next, isA<ChooseBowler>());
    });

    test('wide with one run penalty plus runs taken', () {
      final innings = play(setupWith(), [
        open,
        wide(),
        wide(1),
      ]).currentInnings!;
      expect(innings.runs, 3);
      expect(innings.extras.wides, 3);
      expect(innings.striker, 1, reason: 'one run taken on the wide');
      expect(innings.batter(0)!.balls, 0, reason: 'wides are not faced');
      final bowler = innings.figures(0)!;
      expect(bowler.runs, 3);
      expect(bowler.wides, 2);
      expect(bowler.balls, 0);
    });

    test('wides worth nothing in gully rules', () {
      final innings = play(setupWith(wideRuns: 0), [
        open,
        wide(),
      ]).currentInnings!;
      expect(innings.runs, 0);
      expect(innings.extras.total, 0);
      expect(innings.legalBalls, 0);
    });

    test('no-ball penalty plus runs off the bat', () {
      final innings = play(setupWith(), [open, noBall(4)]).currentInnings!;
      expect(innings.runs, 5);
      expect(innings.extras.noBalls, 1);
      final batter = innings.batter(0)!;
      expect(batter.runs, 4);
      expect(batter.fours, 1);
      expect(batter.balls, 1, reason: 'a no-ball counts as faced');
      expect(innings.figures(0)!.runs, 5);
      expect(innings.figures(0)!.noBalls, 1);
    });

    test('no-ball worth nothing still gives runs off the bat', () {
      final innings = play(setupWith(noBallRuns: 0), [
        open,
        noBall(2),
      ]).currentInnings!;
      expect(innings.runs, 2);
      expect(innings.extras.noBalls, 0);
    });

    test('byes and leg byes go to extras, not the batter or bowler', () {
      final innings = play(setupWith(), [
        open,
        const BallBowled(kind: BallKind.bye, runs: 2),
        const BallBowled(kind: BallKind.legBye, runs: 1),
      ]).currentInnings!;
      expect(innings.runs, 3);
      expect(innings.extras.byes, 2);
      expect(innings.extras.legByes, 1);
      expect(innings.legalBalls, 2);
      expect(innings.batter(0)!.runs, 0);
      expect(innings.batter(0)!.balls, 2);
      expect(innings.figures(0)!.runs, 0);
      expect(innings.figures(0)!.balls, 2);
      expect(innings.striker, 1);
    });
  });

  group('free hit', () {
    test('the ball after a no-ball is a free hit', () {
      final state = play(setupWith(), [open, noBall()]);
      expect(state.currentInnings!.freeHit, isTrue);
      expect(state.allowedDismissals(BallKind.legal), {HowOut.runOut});
      expect(state.apply(dot).currentInnings!.freeHit, isFalse);
    });

    test('a wide keeps the free hit, a no-ball renews it', () {
      var state = play(setupWith(), [open, noBall(), wide()]);
      expect(state.currentInnings!.freeHit, isTrue);
      state = state.apply(noBall());
      expect(state.currentInnings!.freeHit, isTrue);
    });

    test('only a run out on a free hit', () {
      final state = play(setupWith(), [open, noBall()]);
      expect(() => state.apply(bowled), throwsA(isA<InvalidEventException>()));
      final out = state.apply(
        const BallBowled(
          kind: BallKind.legal,
          runs: 1,
          dismissal: Dismissal(HowOut.runOut),
        ),
      );
      expect(out.currentInnings!.wickets, 1);
    });

    test('no free hits when the rule is off', () {
      final state = play(setupWith(freeHit: false), [open, noBall()]);
      expect(state.currentInnings!.freeHit, isFalse);
      expect(state.allowedDismissals(BallKind.legal), contains(HowOut.bowled));
    });
  });

  group('wickets', () {
    test('a wicket asks for the next batter, who takes the striker end', () {
      final state = play(setupWith(), [open, bowled]);
      final next = state.next as ChooseBatter;
      expect(next.available, [2, 3]);
      final innings = state.apply(const BatterChosen(3)).currentInnings!;
      expect(innings.striker, 3);
      expect(innings.nonStriker, 1);
      expect(innings.wickets, 1);
    });

    test('the bowler gets bowled, caught, lbw, stumped and hit wicket', () {
      for (final how in [
        HowOut.bowled,
        HowOut.caught,
        HowOut.lbw,
        HowOut.stumped,
        HowOut.hitWicket,
      ]) {
        final innings = play(setupWith(), [
          open,
          BallBowled(kind: BallKind.legal, dismissal: Dismissal(how)),
        ]).currentInnings!;
        expect(innings.figures(0)!.wickets, 1, reason: how.name);
        expect(innings.batter(0)!.out!.how, how);
        expect(innings.batter(0)!.out!.bowler, 0);
      }
    });

    test('rejects runs with a catch', () {
      expect(
        () => play(setupWith(), [
          open,
          const BallBowled(
            kind: BallKind.legal,
            runs: 1,
            dismissal: Dismissal(HowOut.caught),
          ),
        ]),
        throwsA(isA<InvalidEventException>()),
      );
    });

    test('stumped off a wide counts the wide but not the ball', () {
      final innings = play(setupWith(), [
        open,
        const BallBowled(
          kind: BallKind.wide,
          dismissal: Dismissal(HowOut.stumped),
        ),
      ]).currentInnings!;
      expect(innings.runs, 1);
      expect(innings.wickets, 1);
      expect(innings.legalBalls, 0);
      expect(innings.figures(0)!.wickets, 1);
    });

    test('run out of the non-striker after a completed run', () {
      final state = play(setupWith(), [
        open,
        const BallBowled(
          kind: BallKind.legal,
          runs: 1,
          dismissal: Dismissal(HowOut.runOut, batter: Crease.nonStriker),
        ),
      ]);
      final innings = state.currentInnings!;
      expect(innings.runs, 1);
      expect(innings.batter(0)!.runs, 1);
      expect(innings.batter(1)!.out!.how, HowOut.runOut);
      expect(innings.batter(1)!.out!.bowler, isNull);
      expect(innings.figures(0)!.wickets, 0);
      // After one run the striker is at the far end, so the new batter
      // faces.
      expect(innings.striker, isNull);
      expect(innings.nonStriker, 0);
      final next = state.apply(const BatterChosen(2)).currentInnings!;
      expect(next.striker, 2);
    });

    test('run out of the non-striker without a run', () {
      final innings = play(setupWith(), [
        open,
        const BallBowled(
          kind: BallKind.legal,
          dismissal: Dismissal(HowOut.runOut, batter: Crease.nonStriker),
        ),
        const BatterChosen(2),
      ]).currentInnings!;
      expect(innings.striker, 0);
      expect(innings.nonStriker, 2);
    });

    test(
      'a wicket off the last ball of the over: new batter at the far end',
      () {
        final state = play(setupWith(), [
          open,
          ...List.filled(5, dot),
          caught,
          const BatterChosen(2),
        ]);
        final innings = state.currentInnings!;
        expect(innings.striker, 1);
        expect(innings.nonStriker, 2);
        expect(state.next, isA<ChooseBowler>());
      },
    );

    test('retired counts as a wicket without a ball', () {
      final state = play(setupWith(), [
        open,
        one,
        const BatterRetired(Crease.nonStriker),
      ]);
      final innings = state.currentInnings!;
      expect(innings.wickets, 1);
      expect(innings.legalBalls, 1);
      expect(innings.batter(0)!.out!.how, HowOut.retired);
      expect(innings.figures(0)!.wickets, 0);
      expect(state.next, isA<ChooseBatter>());
    });

    test('fall of wickets records score and balls', () {
      final innings = play(setupWith(), [
        open,
        four,
        one,
        bowled,
        const BatterChosen(2),
      ]).currentInnings!;
      final fow = innings.fallOfWickets.single;
      expect(fow.wicket, 1);
      expect(fow.runs, 5);
      expect(fow.legalBalls, 3);
      expect(fow.player, 1);
    });
  });

  group('all out', () {
    test('ends after players minus one wickets', () {
      final state = play(setupWith(players: 3), [
        open,
        bowled,
        const BatterChosen(2),
        bowled,
      ]);
      final innings = state.innings.first;
      expect(innings.isComplete, isTrue);
      expect(innings.wickets, 2);
      expect(state.next, isA<ChooseOpeners>());
    });

    test('last man stands: the last batter bats alone and keeps strike', () {
      var state = play(setupWith(players: 3, lastManStands: true), [
        open,
        bowled,
        const BatterChosen(2),
        bowled,
      ]);
      var innings = state.currentInnings!;
      expect(innings.isComplete, isFalse);
      expect(state.next, isA<Bowl>());
      expect(innings.striker, 1);
      expect(innings.nonStriker, isNull);

      state = state.apply(one);
      innings = state.currentInnings!;
      expect(innings.striker, 1, reason: 'no one to swap with');

      state = state.apply(bowled);
      expect(state.innings.first.isComplete, isTrue);
      expect(state.innings.first.wickets, 3);
    });

    test('last man stands: the lone batter keeps strike over to over', () {
      final state = play(setupWith(players: 2, lastManStands: true), [
        open,
        bowled,
        ...List.filled(5, dot),
      ]);
      expect(state.next, isA<ChooseBowler>());
      expect(state.currentInnings!.striker, 1);
    });

    test('last man stands: the non-striker left alone takes strike', () {
      final innings = play(setupWith(players: 2, lastManStands: true), [
        open,
        bowled,
      ]).currentInnings!;
      expect(innings.striker, 1);
      expect(innings.nonStriker, isNull);
    });
  });

  group('overs and bowlers', () {
    test('asks for a new bowler each over, not the same one', () {
      final state = play(setupWith(), [open, ...maidenOver()]);
      final next = state.next as ChooseBowler;
      expect(next.eligible, [1, 2, 3]);
      expect(
        () => state.apply(const BowlerChosen(0)),
        throwsA(isA<InvalidEventException>()),
      );
      expect(state.apply(const BowlerChosen(2)).currentInnings!.bowler, 2);
    });

    test('a maiden is a full over with nothing off the bowler', () {
      final innings = play(setupWith(), [
        open,
        const BallBowled(kind: BallKind.bye, runs: 1),
        const BallBowled(kind: BallKind.legBye, runs: 1),
        ...List.filled(4, dot),
      ]).currentInnings!;
      expect(innings.figures(0)!.maidens, 1);
      expect(innings.overs.single.isMaiden, isTrue);
      expect(innings.overs.single.runs, 2);
    });

    test('a wide spoils a maiden', () {
      final innings = play(setupWith(), [
        open,
        wide(),
        ...maidenOver(),
      ]).currentInnings!;
      expect(innings.figures(0)!.maidens, 0);
    });

    test('bowling figures across overs', () {
      final innings = play(setupWith(overs: 3), [
        open,
        ...maidenOver(),
        const BowlerChosen(1),
        four,
        caught,
        const BatterChosen(2),
        ...List.filled(4, dot),
        const BowlerChosen(0),
        one,
      ]).currentInnings!;
      final first = innings.figures(0)!;
      expect(first.balls, 7);
      expect(first.maidens, 1);
      expect(first.runs, 1);
      expect(first.economy, closeTo(6 / 7, 0.001));
      final second = innings.figures(1)!;
      expect(second.balls, 6);
      expect(second.runs, 4);
      expect(second.wickets, 1);
      expect(innings.overs, hasLength(3));
      expect(innings.overs[1].bowler, 1);
      expect(innings.overs[1].wickets, 1);
    });

    test('innings ends when the overs run out', () {
      final state = play(setupWith(overs: 1), [open, ...maidenOver()]);
      expect(state.innings.first.isComplete, isTrue);
      final next = state.next as ChooseOpeners;
      expect(next.innings, 1);
      expect(next.battingTeam, 1);
    });
  });

  group('chase and result', () {
    List<MatchEvent> firstInnings(List<MatchEvent> balls) => [open, ...balls];

    test('second innings has a target and run rates', () {
      final state = play(setupWith(overs: 1), [
        ...firstInnings([six, six, dot, dot, dot, dot]),
        open,
        four,
      ]);
      final chase = state.currentInnings!;
      expect(chase.target, 13);
      expect(chase.runsNeeded, 9);
      expect(chase.ballsLeft, 5);
      expect(chase.requiredRate, closeTo(10.8, 0.001));
      expect(chase.runRate, closeTo(24, 0.001));
    });

    test('the chase ends as soon as the target is passed', () {
      final state = play(setupWith(overs: 1), [
        ...firstInnings([four, dot, dot, dot, dot, dot]),
        open,
        six,
      ]);
      final result = state.result as Win;
      expect(result.winner, 1);
      expect((result.margin as ByWickets).wickets, 3);
      expect(result.inSuperOver, isFalse);
      expect(() => state.apply(dot), throwsA(isA<InvalidEventException>()));
    });

    test('a wide can win it', () {
      final state = play(setupWith(overs: 1), [
        ...firstInnings([dot, dot, dot, dot, dot, dot]),
        open,
        wide(),
      ]);
      expect((state.result as Win).winner, 1);
    });

    test('defending side wins by runs', () {
      final state = play(setupWith(overs: 1), [
        ...firstInnings([six, six, dot, dot, dot, dot]),
        open,
        one,
        ...List.filled(5, dot),
      ]);
      final result = state.result as Win;
      expect(result.winner, 0);
      expect((result.margin as ByRuns).runs, 11);
    });

    test('defending side wins when the chasers are all out', () {
      final state = play(setupWith(overs: 1, players: 2), [
        ...firstInnings([one, ...List.filled(5, dot)]),
        open,
        bowled,
      ]);
      expect((state.result as Win).winner, 0);
    });

    test('wickets in hand count the lone last man', () {
      final state = play(setupWith(overs: 1, lastManStands: true), [
        ...firstInnings(maidenOver()),
        open,
        one,
      ]);
      expect(((state.result as Win).margin as ByWickets).wickets, 4);
    });

    test('equal scores are a tie', () {
      final state = play(setupWith(overs: 1), [
        ...firstInnings([four, ...List.filled(5, dot)]),
        open,
        two,
        two,
        ...List.filled(4, dot),
      ]);
      expect(state.result, isA<Tie>());
      expect(state.mainResult, isA<Tie>());
    });
  });

  group('super over', () {
    List<MatchEvent> tiedMatch() => [
      open,
      four,
      ...List.filled(5, dot),
      open,
      four,
      ...List.filled(5, dot),
    ];

    test('only after a tie', () {
      expect(
        () => play(setupWith(overs: 1), [const SuperOverStarted()]),
        throwsA(isA<InvalidEventException>()),
      );
    });

    test('side batting second bats first, one over, two wickets', () {
      final state = play(setupWith(overs: 1), [
        ...tiedMatch(),
        const SuperOverStarted(),
      ]);
      final next = state.next as ChooseOpeners;
      expect(next.innings, 2);
      expect(next.battingTeam, 1);
      expect(next.isSuperOver, isTrue);

      final started = state.apply(open);
      final innings = started.currentInnings!;
      expect(innings.isSuperOver, isTrue);
      expect(innings.maxBalls, 6);
      expect(innings.wicketLimit, 2);
      expect(started.result, isNull);
    });

    test('the super over decides the match', () {
      final state = play(setupWith(overs: 1), [
        ...tiedMatch(),
        const SuperOverStarted(),
        open,
        bowled,
        const BatterChosen(2),
        bowled,
        open,
        one,
      ]);
      expect(state.innings[2].isComplete, isTrue);
      final result = state.result as Win;
      expect(result.winner, 0);
      expect(result.inSuperOver, isTrue);
      expect(state.mainResult, isA<Tie>());
    });
  });

  group('undo', () {
    test('takes back the last ball', () {
      final state = play(setupWith(), [open, four, one]).undo();
      expect(state.events, [open, four]);
      expect(state.currentInnings!.runs, 4);
      expect(state.currentInnings!.striker, 0);
    });

    test('takes back any number of balls', () {
      var state = play(setupWith(), [open, four, one, six, wide()]);
      for (var i = 0; i < 4; i++) {
        state = state.undo();
      }
      expect(state.events, [open]);
      expect(state.undo().events, isEmpty);
      expect(state.undo().undo().canUndo, isFalse);
    });

    test('takes back a wicket together with the new batter', () {
      final state = play(setupWith(), [
        open,
        bowled,
        const BatterChosen(2),
      ]).undo();
      expect(state.events, [open]);
      expect(state.currentInnings!.wickets, 0);
    });

    test('takes back the last ball of an over with the new bowler', () {
      final state = play(setupWith(), [
        open,
        ...maidenOver(),
        const BowlerChosen(1),
      ]).undo();
      expect(state.events, hasLength(6));
      expect(state.next, isA<Bowl>());
      expect(state.currentInnings!.bowler, 0);
    });

    test('reopens a finished match', () {
      final state = play(setupWith(overs: 1), [
        open,
        four,
        ...List.filled(5, dot),
        open,
        six,
      ]).undo();
      expect(state.result, isNull);
      expect(state.next, isA<Bowl>());
    });

    test('withoutLastAction on an empty list is empty', () {
      expect(withoutLastAction(const []), isEmpty);
    });
  });

  group('json', () {
    test('a match survives a round trip', () {
      final setup = setupWith(lastManStands: true, wideRuns: 0);
      final events = <MatchEvent>[
        open,
        four,
        wide(2),
        noBall(1),
        const BallBowled(kind: BallKind.bye, runs: 1),
        const BallBowled(
          kind: BallKind.legal,
          runs: 1,
          dismissal: Dismissal(HowOut.runOut, batter: Crease.nonStriker),
        ),
        const BatterChosen(2),
        const StrikeSwapped(),
        const BatterRetired(Crease.striker),
        const BatterChosen(3),
        const SuperOverStarted(),
        const BowlerChosen(1),
      ];
      final copy = SavedMatch.fromJson(
        SavedMatch(setup: setup, events: events).toJson(),
      );
      expect(copy.setup, setup);
      expect(copy.events, events);
    });

    test('unknown events are rejected', () {
      expect(
        () => MatchEvent.fromJson({'t': 'rain'}),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
