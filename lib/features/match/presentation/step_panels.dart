import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/match_event.dart';
import '../domain/match_state.dart';
import 'format.dart';
import 'scoring_pad.dart';

/// Picks two openers and the first bowler of an innings.
class OpenersPanel extends StatefulWidget {
  const OpenersPanel({
    required this.match,
    required this.step,
    required this.onEvent,
    super.key,
  });

  final MatchState match;
  final ChooseOpeners step;
  final EventCallback onEvent;

  @override
  State<OpenersPanel> createState() => _OpenersPanelState();
}

class _OpenersPanelState extends State<OpenersPanel> {
  int _striker = 0;
  int _nonStriker = 1;
  int _bowler = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final setup = widget.match.setup;
    final step = widget.step;
    final batting = setup.teams[step.battingTeam];
    final bowling = setup.teams[step.bowlingTeam];
    final valid = _striker != _nonStriker;
    final previous = step.innings.isOdd && !step.isSuperOver
        ? widget.match.innings[step.innings - 1]
        : null;

    DropdownButtonFormField<int> picker({
      required Key key,
      required String label,
      required List<String> players,
      required int value,
      required ValueChanged<int> onChanged,
    }) => DropdownButtonFormField<int>(
      key: key,
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final (i, name) in players.indexed)
          DropdownMenuItem(value: i, child: Text(name)),
      ],
      onChanged: (value) {
        if (value != null) setState(() => onChanged(value));
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (previous != null) ...[
          Text(
            l10n.inningsBreak(
              setup.teams[previous.battingTeam].name,
              previous.runs,
              previous.wickets,
              batting.name,
              previous.runs + 1,
            ),
            key: const Key('inningsBreak'),
            style: text.titleMedium,
          ),
          const SizedBox(height: 16),
        ],
        Text(
          step.isSuperOver
              ? l10n.superOverOpenersTitle(batting.name)
              : l10n.openersTitle(batting.name),
          style: text.titleLarge,
        ),
        const SizedBox(height: 16),
        picker(
          key: const Key('pick-striker'),
          label: l10n.striker,
          players: batting.players,
          value: _striker,
          onChanged: (value) => _striker = value,
        ),
        const SizedBox(height: 12),
        picker(
          key: const Key('pick-nonStriker'),
          label: l10n.nonStriker,
          players: batting.players,
          value: _nonStriker,
          onChanged: (value) => _nonStriker = value,
        ),
        if (!valid)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n.openersMustDiffer,
              style: text.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        const SizedBox(height: 12),
        picker(
          key: const Key('pick-bowler'),
          label: l10n.openingBowler(bowling.name),
          players: bowling.players,
          value: _bowler,
          onChanged: (value) => _bowler = value,
        ),
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('startInnings'),
          style: FilledButton.styleFrom(minimumSize: const Size(48, 56)),
          onPressed: valid
              ? () => widget.onEvent(
                  InningsStarted(
                    striker: _striker,
                    nonStriker: _nonStriker,
                    bowler: _bowler,
                  ),
                )
              : null,
          child: Text(l10n.startInnings),
        ),
      ],
    );
  }
}

/// A list of players to tap: the next bowler or the next batter.
class PlayerPickPanel extends StatelessWidget {
  const PlayerPickPanel({
    required this.title,
    required this.players,
    required this.onPick,
    required this.onUndo,
    super.key,
  });

  final String title;

  /// Player index, name and an optional detail such as bowling figures.
  final List<(int, String, String?)> players;
  final ValueChanged<int> onPick;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (player, name, detail) in players)
                ListTile(
                  key: Key('pick-player-$player'),
                  title: Text(name),
                  trailing: detail == null ? null : Text(detail),
                  onTap: () => onPick(player),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          key: const Key('undo'),
          onPressed: onUndo,
          icon: const Icon(Icons.undo),
          label: Text(l10n.undo),
          style: OutlinedButton.styleFrom(minimumSize: const Size(48, 52)),
        ),
      ],
    );
  }
}

/// Shown when the match is over.
class ResultPanel extends StatelessWidget {
  const ResultPanel({
    required this.match,
    required this.result,
    required this.onSuperOver,
    required this.onScorecard,
    required this.onShare,
    required this.onUndo,
    super.key,
  });

  final MatchState match;
  final MatchResult result;
  final VoidCallback onSuperOver;
  final VoidCallback onScorecard;
  final VoidCallback onShare;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          margin: EdgeInsets.zero,
          color: colors.tertiaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  color: colors.onTertiaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    resultText(result, match.setup, l10n),
                    key: const Key('result'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colors.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (result is Tie) ...[
          FilledButton.icon(
            key: const Key('superOver'),
            onPressed: onSuperOver,
            icon: const Icon(Icons.replay),
            label: Text(l10n.playSuperOver),
            style: FilledButton.styleFrom(minimumSize: const Size(48, 52)),
          ),
          const SizedBox(height: 8),
        ],
        FilledButton.tonalIcon(
          onPressed: onScorecard,
          icon: const Icon(Icons.table_chart_outlined),
          label: Text(l10n.viewScorecard),
          style: FilledButton.styleFrom(minimumSize: const Size(48, 52)),
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: onShare,
          icon: const Icon(Icons.share_outlined),
          label: Text(l10n.shareText),
          style: FilledButton.styleFrom(minimumSize: const Size(48, 52)),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('undo'),
          onPressed: onUndo,
          icon: const Icon(Icons.undo),
          label: Text(l10n.undo),
          style: OutlinedButton.styleFrom(minimumSize: const Size(48, 52)),
        ),
      ],
    );
  }
}
