import 'package:flutter_test/flutter_test.dart';
import 'package:gully_cricket_scorer/features/match/domain/match_event.dart';
import 'package:gully_cricket_scorer/features/match/presentation/format.dart';
import 'package:gully_cricket_scorer/features/setup/presentation/setup_screen.dart';
import 'package:gully_cricket_scorer/l10n/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();

  test('overs are written as overs.balls', () {
    expect(oversText(0), '0');
    expect(oversText(5), '0.5');
    expect(oversText(6), '1');
    expect(oversText(13), '2.1');
  });

  test('rates have two decimals or a dash', () {
    expect(rateText(null), '-');
    expect(rateText(7.5), '7.50');
  });

  test('ball labels', () {
    expect(ballLabel(const BallBowled.runs(0), l10n), '0');
    expect(ballLabel(const BallBowled.runs(6), l10n), '6');
    expect(ballLabel(const BallBowled(kind: BallKind.wide), l10n), 'Wd');
    expect(
      ballLabel(const BallBowled(kind: BallKind.noBall, runs: 4), l10n),
      'Nb+4',
    );
    expect(
      ballLabel(const BallBowled(kind: BallKind.legBye, runs: 1), l10n),
      '1Lb',
    );
    expect(
      ballLabel(
        const BallBowled(
          kind: BallKind.legal,
          dismissal: Dismissal(HowOut.caught),
        ),
        l10n,
      ),
      'W',
    );
    expect(
      ballLabel(
        const BallBowled(
          kind: BallKind.legal,
          runs: 1,
          dismissal: Dismissal(HowOut.runOut),
        ),
        l10n,
      ),
      '1+W',
    );
  });

  group('buildTeam', () {
    test('fills blank names with defaults', () {
      final team = buildTeam(
        name: '  ',
        fallbackName: 'Team A',
        playerNames: '',
        players: 2,
        defaultPlayer: l10n.defaultPlayerName,
      );
      expect(team.name, 'Team A');
      expect(team.players, ['Player 1', 'Player 2']);
    });

    test('uses typed names, skips blank lines and pads the rest', () {
      final team = buildTeam(
        name: ' Street Kings ',
        fallbackName: 'Team A',
        playerNames: 'Ravi\n\n  Anu \n',
        players: 3,
        defaultPlayer: l10n.defaultPlayerName,
      );
      expect(team.name, 'Street Kings');
      expect(team.players, ['Ravi', 'Anu', 'Player 3']);
    });

    test('ignores names beyond the team size', () {
      final team = buildTeam(
        name: 'X',
        fallbackName: 'Team A',
        playerNames: 'A\nB\nC',
        players: 2,
        defaultPlayer: l10n.defaultPlayerName,
      );
      expect(team.players, ['A', 'B']);
    });
  });
}
