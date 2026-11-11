import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/arcade_game.dart';
import 'best_scores_controller.dart';

/// The front door: the cricket scorer and every game, with best scores.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final best = ref.watch(bestScoresProvider).value ?? const {};

    Widget game(
      GameId id,
      IconData icon,
      String title,
      String blurb,
      bool is3d,
    ) => _Tile(
      key: Key('game-${id.key}'),
      icon: icon,
      title: title,
      blurb: blurb,
      tag: is3d ? l10n.games3d : l10n.games2d,
      footnote: switch (best[id]) {
        final score? => l10n.gameBest(score),
        null => null,
      },
      onTap: () => context.go('/games/${id.key}'),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              l10n.gamesIntro,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          _Heading(l10n.homeStreet),
          game(
            GameId.duel,
            Icons.sports_martial_arts,
            l10n.gameDuelTitle,
            l10n.gameDuelBlurb,
            true,
          ),
          game(
            GameId.kabaddi,
            Icons.sports_kabaddi,
            l10n.gameKabaddiTitle,
            l10n.gameKabaddiBlurb,
            true,
          ),
          game(
            GameId.gilliDanda,
            Icons.sports_hockey,
            l10n.gameGilliTitle,
            l10n.gameGilliBlurb,
            true,
          ),
          game(
            GameId.kiteFight,
            Icons.air,
            l10n.gameKiteTitle,
            l10n.gameKiteBlurb,
            false,
          ),
          game(
            GameId.carrom,
            Icons.adjust,
            l10n.gameCarromTitle,
            l10n.gameCarromBlurb,
            false,
          ),
          game(
            GameId.laneRunner,
            Icons.directions_run,
            l10n.gameDashTitle,
            l10n.gameDashBlurb,
            false,
          ),
          _Heading(l10n.homeCricket),
          game(
            GameId.batting,
            Icons.sports_cricket,
            l10n.gameBattingTitle,
            l10n.gameBattingBlurb,
            true,
          ),
          game(
            GameId.catching,
            Icons.sports_handball,
            l10n.gameCatchingTitle,
            l10n.gameCatchingBlurb,
            true,
          ),
          game(
            GameId.directHit,
            Icons.gps_fixed,
            l10n.gameDirectHitTitle,
            l10n.gameDirectHitBlurb,
            true,
          ),
          _Tile(
            key: const Key('openScorer'),
            icon: Icons.scoreboard,
            title: l10n.homeScorerTitle,
            blurb: l10n.homeScorerBlurb,
            onTap: () => context.go('/scorer'),
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.blurb,
    required this.onTap,
    this.tag,
    this.footnote,
    super.key,
  });

  final IconData icon;
  final String title;
  final String blurb;
  final String? tag;
  final String? footnote;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: colors.primaryContainer,
                foregroundColor: colors.onPrimaryContainer,
                child: Icon(icon, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        if (tag case final tag?) ...[
                          const SizedBox(width: 8),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.tertiaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              child: Text(
                                tag,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colors.onTertiaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(blurb, style: theme.textTheme.bodyMedium),
                    if (footnote case final footnote?) ...[
                      const SizedBox(height: 6),
                      Text(
                        footnote,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
