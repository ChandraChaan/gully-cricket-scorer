import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/match_event.dart';
import '../domain/match_state.dart';
import 'format.dart';
import 'match_controller.dart';
import 'scoreboard.dart';
import 'scoring_pad.dart';
import 'share_actions.dart';
import 'step_panels.dart';

class ScoringScreen extends ConsumerWidget {
  const ScoringScreen({required this.matchId, super.key});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final match = ref.watch(matchControllerProvider(matchId));
    return switch (match) {
      AsyncData(:final value) => _ScoringView(match: value),
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          message: error is MatchNotFoundException
              ? l10n.matchNotFound
              : l10n.matchLoadError,
          onRetry: error is MatchNotFoundException
              ? null
              : () => ref.invalidate(matchControllerProvider(matchId)),
          onBack: () => context.go('/'),
        ),
      ),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}

class _ScoringView extends ConsumerWidget {
  const _ScoringView({required this.match});

  final MatchState match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final setup = match.setup;
    final controller = ref.read(matchControllerProvider(setup.id).notifier);
    final innings = match.currentInnings;
    final next = match.next;

    Future<void> record(MatchEvent event) async {
      final messenger = ScaffoldMessenger.of(context);
      final saved = await controller.record(event);
      if (!saved) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.storageError)));
      }
    }

    Future<void> undo() async {
      final messenger = ScaffoldMessenger.of(context);
      final saved = await controller.undo();
      if (!saved) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.storageError)));
      }
    }

    void openScorecard() => context.go('/match/${setup.id}/scorecard');

    final panel = switch (next) {
      ChooseOpeners() => OpenersPanel(
        // A fresh panel for each innings, so the picks reset.
        key: ValueKey('openers-${next.innings}'),
        match: match,
        step: next,
        onEvent: record,
      ),
      ChooseBowler(:final eligible) => PlayerPickPanel(
        title: l10n.chooseBowlerTitle(innings!.overs.length + 1),
        players: [
          for (final player in eligible)
            (
              player,
              playerName(setup, innings.bowlingTeam, player),
              switch (innings.figures(player)) {
                final figures? => figuresText(figures, l10n),
                null => null,
              },
            ),
        ],
        onPick: (player) => record(BowlerChosen(player)),
        onUndo: undo,
      ),
      ChooseBatter(:final available) => PlayerPickPanel(
        title: l10n.chooseBatterTitle,
        players: [
          for (final player in available)
            (player, playerName(setup, innings!.battingTeam, player), null),
        ],
        onPick: (player) => record(BatterChosen(player)),
        onUndo: undo,
      ),
      Bowl() => ScoringPad(match: match, onEvent: record, onUndo: undo),
      MatchOver(:final result) => ResultPanel(
        match: match,
        result: result,
        onSuperOver: () => record(const SuperOverStarted()),
        onScorecard: openScorecard,
        onShare: () => shareScorecardText(context, ref, match),
        onUndo: undo,
      ),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(matchTitle(setup, l10n)),
        actions: [
          IconButton(
            tooltip: l10n.undo,
            onPressed: match.canUndo ? undo : null,
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            key: const Key('openScorecard'),
            tooltip: l10n.scorecard,
            onPressed: openScorecard,
            icon: const Icon(Icons.table_chart_outlined),
          ),
          PopupMenuButton<VoidCallback>(
            tooltip: l10n.moreActions,
            onSelected: (action) => action(),
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: next is Bowl && innings?.nonStriker != null,
                value: () => record(const StrikeSwapped()),
                child: Text(l10n.swapStrike),
              ),
              PopupMenuItem(
                value: () => shareScorecardText(context, ref, match),
                child: Text(l10n.shareText),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (innings != null && next is! ChooseOpeners) ...[
                    ScoreHeader(match: match, innings: innings),
                    const SizedBox(height: 12),
                    if (!innings.isComplete) ...[
                      CreaseCard(match: match, innings: innings),
                      const SizedBox(height: 12),
                      ThisOver(innings: innings),
                      const SizedBox(height: 16),
                    ],
                  ],
                  panel,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
