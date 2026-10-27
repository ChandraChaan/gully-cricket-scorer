import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/innings_state.dart';
import '../domain/match_setup.dart';
import '../domain/match_state.dart';
import 'format.dart';

/// The big score at the top of the scoring screen.
class ScoreHeader extends StatelessWidget {
  const ScoreHeader({required this.match, required this.innings, super.key});

  final MatchState match;
  final InningsState innings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final setup = match.setup;
    final label = innings.isSuperOver
        ? l10n.superOver
        : innings.index == 0
        ? l10n.firstInnings
        : l10n.secondInnings;
    final needed = innings.runsNeeded;
    return Card(
      color: colors.primaryContainer,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: colors.onPrimaryContainer),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    setup.teams[innings.battingTeam].name,
                    style: text.titleMedium?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    label,
                    style: text.labelLarge?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  if (innings.freeHit && !innings.isComplete)
                    const FreeHitBadge(),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l10n.scoreLine(innings.runs, innings.wickets),
                key: const Key('score'),
                style: text.displayMedium?.copyWith(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                l10n.oversLine(
                  oversText(innings.legalBalls),
                  innings.maxBalls ~/ ballsPerOver,
                ),
                style: text.titleSmall?.copyWith(
                  color: colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  Text(l10n.currentRate(rateText(innings.runRate))),
                  if (innings.target case final target?) ...[
                    Text(l10n.targetLine(target)),
                    if (innings.requiredRate case final rate?)
                      Text(l10n.requiredRate(rateText(rate))),
                  ],
                ],
              ),
              if (needed != null && !innings.isComplete) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.chaseStatus(needed, innings.ballsLeft),
                  key: const Key('chaseStatus'),
                  style: text.titleSmall?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class FreeHitBadge extends StatelessWidget {
  const FreeHitBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.tertiary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt, size: 16, color: colors.onTertiary),
            const SizedBox(width: 2),
            Text(
              AppLocalizations.of(context).freeHitBadge,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: colors.onTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Batters at the crease and the bowler.
class CreaseCard extends StatelessWidget {
  const CreaseCard({required this.match, required this.innings, super.key});

  final MatchState match;
  final InningsState innings;

  @override
  Widget build(BuildContext context) {
    final setup = match.setup;
    final l10n = AppLocalizations.of(context);
    final bowler = innings.bowler ?? innings.currentOver?.bowler;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            for (final (player, onStrike) in [
              (innings.striker, true),
              (innings.nonStriker, false),
            ])
              if (player != null)
                _BatterRow(
                  name: playerName(setup, innings.battingTeam, player),
                  score: innings.batter(player)!,
                  onStrike: onStrike,
                ),
            if (bowler != null) ...[
              const Divider(indent: 16, endIndent: 16),
              ListTile(
                dense: true,
                leading: const Icon(Icons.sports_baseball_outlined),
                title: Text(playerName(setup, innings.bowlingTeam, bowler)),
                trailing: Text(
                  figuresText(innings.figures(bowler)!, l10n),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BatterRow extends StatelessWidget {
  const _BatterRow({
    required this.name,
    required this.score,
    required this.onStrike,
  });

  final String name;
  final BatterScore score;
  final bool onStrike;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return ListTile(
      dense: true,
      leading: onStrike
          ? Icon(
              Icons.sports_cricket,
              color: Theme.of(context).colorScheme.primary,
            )
          : const SizedBox(width: 24),
      title: Text(
        onStrike ? '$name *' : name,
        semanticsLabel: onStrike ? '$name, ${l10n.onStrike}' : name,
        style: onStrike ? const TextStyle(fontWeight: FontWeight.w700) : null,
      ),
      trailing: Text(
        l10n.batterLine(score.runs, score.balls),
        style: text.titleMedium,
      ),
    );
  }
}

/// Every delivery of the current over, extras included.
class ThisOver extends StatelessWidget {
  const ThisOver({required this.innings, super.key});

  final InningsState innings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final over = innings.currentOver;
    final balls = over?.balls ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.thisOver, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        if (balls.isEmpty)
          Text(l10n.noBallsYet)
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final ball in balls) BallChip(label: ballLabel(ball, l10n)),
            ],
          ),
      ],
    );
  }
}

class BallChip extends StatelessWidget {
  const BallChip({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final wicket = label.endsWith(AppLocalizations.of(context).ballWicket);
    final boundary = label == '4' || label == '6';
    final background = wicket
        ? colors.errorContainer
        : boundary
        ? colors.primary
        : colors.surfaceContainerHighest;
    final foreground = wicket
        ? colors.onErrorContainer
        : boundary
        ? colors.onPrimary
        : colors.onSurface;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
