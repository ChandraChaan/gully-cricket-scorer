import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/innings_state.dart';
import '../domain/match_state.dart';
import 'format.dart';
import 'match_controller.dart';
import 'scoreboard.dart';
import 'share_actions.dart';

class ScorecardScreen extends ConsumerWidget {
  const ScorecardScreen({required this.matchId, super.key});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final match = ref.watch(matchControllerProvider(matchId));
    final loaded = match.value;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scorecard),
        actions: [
          if (loaded != null) ...[
            IconButton(
              tooltip: l10n.copyText,
              onPressed: () =>
                  shareScorecardText(context, ref, loaded, copyOnly: true),
              icon: const Icon(Icons.copy_outlined),
            ),
            IconButton(
              key: const Key('shareText'),
              tooltip: l10n.shareText,
              onPressed: () => shareScorecardText(context, ref, loaded),
              icon: const Icon(Icons.share_outlined),
            ),
          ],
        ],
      ),
      body: switch (match) {
        AsyncData(:final value) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ScorecardView(match: value),
            ),
          ),
        ),
        AsyncError(:final error) => ErrorView(
          message: error is MatchNotFoundException
              ? l10n.matchNotFound
              : l10n.matchLoadError,
          onBack: () => context.go('/'),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

/// The full scorecard of a match: every innings, top to bottom.
class ScorecardView extends StatelessWidget {
  const ScorecardView({required this.match, super.key});

  final MatchState match;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(matchTitle(match.setup, l10n), style: text.headlineSmall),
        if (match.result case final result?) ...[
          const SizedBox(height: 4),
          Text(
            resultText(result, match.setup, l10n),
            style: text.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (match.innings.isEmpty) Text(l10n.noInningsYet),
        for (final innings in match.innings) ...[
          _InningsCard(match: match, innings: innings),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _InningsCard extends StatelessWidget {
  const _InningsCard({required this.match, required this.innings});

  final MatchState match;
  final InningsState innings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final setup = match.setup;
    final extras = innings.extras;
    final battingTeam = setup.teams[innings.battingTeam];
    final didNotBat = [
      for (final (i, name) in battingTeam.players.indexed)
        if (innings.batter(i) == null) name,
    ];
    String batterName(int player) =>
        playerName(setup, innings.battingTeam, player);
    String bowlerName(int player) =>
        playerName(setup, innings.bowlingTeam, player);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text(
                  inningsTitle(innings, setup, l10n),
                  style: text.titleLarge,
                ),
                Text(
                  l10n.totalDetail(
                    innings.runs,
                    innings.wickets,
                    oversText(innings.legalBalls),
                  ),
                  style: text.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _StatTable(
              headers: [
                l10n.batting,
                l10n.colRuns,
                l10n.colBalls,
                l10n.colFours,
                l10n.colSixes,
                l10n.colStrikeRate,
              ],
              rows: [
                for (final batter in innings.batters)
                  _StatRow(
                    name: batterName(batter.player),
                    detail: outText(batter.out, setup, innings, l10n),
                    values: [
                      '${batter.runs}',
                      '${batter.balls}',
                      '${batter.fours}',
                      '${batter.sixes}',
                      rateText(batter.strikeRate),
                    ],
                  ),
              ],
            ),
            const Divider(height: 24),
            _LabelValue(
              label: l10n.extras,
              value:
                  '${extras.total} (${l10n.extrasDetail(extras.wides, extras.noBalls, extras.byes, extras.legByes)})',
            ),
            _LabelValue(
              label: l10n.total,
              value: l10n.totalDetail(
                innings.runs,
                innings.wickets,
                oversText(innings.legalBalls),
              ),
              strong: true,
            ),
            if (didNotBat.isNotEmpty)
              _LabelValue(label: l10n.didNotBat, value: didNotBat.join(', ')),
            if (innings.fallOfWickets.isNotEmpty)
              _LabelValue(
                label: l10n.fallOfWickets,
                value: [
                  for (final fow in innings.fallOfWickets)
                    l10n.fallOfWicketEntry(
                      fow.wicket,
                      fow.runs,
                      batterName(fow.player),
                      oversText(fow.legalBalls),
                    ),
                ].join(', '),
              ),
            const SizedBox(height: 16),
            _StatTable(
              headers: [
                l10n.bowling,
                l10n.colOvers,
                l10n.colMaidens,
                l10n.colRuns,
                l10n.colWickets,
                l10n.colEconomy,
              ],
              rows: [
                for (final figures in innings.bowlers)
                  _StatRow(
                    name: bowlerName(figures.player),
                    values: [
                      oversText(figures.balls),
                      '${figures.maidens}',
                      '${figures.runs}',
                      '${figures.wickets}',
                      rateText(figures.economy),
                    ],
                  ),
              ],
            ),
            if (innings.overs.any((over) => over.balls.isNotEmpty)) ...[
              const SizedBox(height: 16),
              Text(l10n.overByOver, style: text.titleSmall),
              const SizedBox(height: 8),
              for (final over in innings.overs)
                if (over.balls.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l10n.overNumber(over.index + 1)} · '
                          '${bowlerName(over.bowler)} · '
                          '${l10n.overRuns(over.runs)}',
                          style: text.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            for (final ball in over.balls)
                              BallChip(label: ballLabel(ball, l10n)),
                          ],
                        ),
                      ],
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatRow {
  const _StatRow({required this.name, required this.values, this.detail});

  final String name;
  final String? detail;
  final List<String> values;
}

/// A compact table: a wide name column and narrow number columns.
class _StatTable extends StatelessWidget {
  const _StatTable({required this.headers, required this.rows});

  final List<String> headers;
  final List<_StatRow> rows;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    Widget cell(String value, {TextStyle? style, bool alignEnd = true}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Text(
            value,
            style: style,
            textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          ),
        );
    final headerStyle = text.labelMedium?.copyWith(color: muted);
    return Table(
      columnWidths: {
        0: const FlexColumnWidth(3.2),
        for (var i = 1; i < headers.length; i++)
          i: FlexColumnWidth(i == headers.length - 1 ? 1.4 : 1),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [
            cell(headers.first, style: headerStyle, alignEnd: false),
            for (final header in headers.skip(1))
              cell(header, style: headerStyle),
          ],
        ),
        for (final row in rows)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(row.name, style: text.bodyMedium),
                    if (row.detail case final detail?)
                      Text(
                        detail,
                        style: text.bodySmall?.copyWith(color: muted),
                      ),
                  ],
                ),
              ),
              for (final (i, value) in row.values.indexed)
                cell(
                  value,
                  style: i == 0
                      ? text.bodyMedium?.copyWith(fontWeight: FontWeight.w700)
                      : text.bodyMedium,
                ),
            ],
          ),
      ],
    );
  }
}

class _LabelValue extends StatelessWidget {
  const _LabelValue({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$label  ', style: text.labelLarge),
            TextSpan(
              text: value,
              style: strong
                  ? text.bodyLarge?.copyWith(fontWeight: FontWeight.w700)
                  : text.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
