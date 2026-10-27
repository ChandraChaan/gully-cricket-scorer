import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/match_event.dart';
import '../domain/match_state.dart';
import 'format.dart';

typedef EventCallback = void Function(MatchEvent event);

/// Big buttons for every kind of ball.
class ScoringPad extends StatelessWidget {
  const ScoringPad({
    required this.match,
    required this.onEvent,
    required this.onUndo,
    super.key,
  });

  final MatchState match;
  final EventCallback onEvent;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    Widget runs(int value) => _PadButton(
      key: Key('runs-$value'),
      label: '$value',
      semanticsLabel: l10n.runsButton(value),
      emphasis: value == 4 || value == 6 ? _Emphasis.strong : _Emphasis.normal,
      onPressed: () => onEvent(BallBowled.runs(value)),
    );

    Widget extra(
      String label,
      BallKind kind,
      String title,
      List<int> options,
    ) => _PadButton(
      key: Key('extra-${kind.name}'),
      label: label,
      emphasis: _Emphasis.quiet,
      onPressed: () async {
        final runs = await showRunsSheet(context, title, options);
        if (runs != null) onEvent(BallBowled(kind: kind, runs: runs));
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PadRow(children: [runs(0), runs(1), runs(2), runs(3)]),
        _PadRow(
          children: [
            runs(4),
            runs(6),
            runs(5),
            _PadButton(
              key: const Key('wicket'),
              label: l10n.wicket,
              background: colors.error,
              foreground: colors.onError,
              onPressed: () async {
                final event = await showWicketFlow(context, match);
                if (event != null) onEvent(event);
              },
            ),
          ],
        ),
        _PadRow(
          children: [
            extra(l10n.wide, BallKind.wide, l10n.wideSheetTitle, [
              0,
              1,
              2,
              3,
              4,
            ]),
            extra(l10n.noBall, BallKind.noBall, l10n.noBallSheetTitle, [
              0,
              1,
              2,
              3,
              4,
              6,
            ]),
            extra(l10n.bye, BallKind.bye, l10n.byeSheetTitle, [1, 2, 3, 4]),
            extra(l10n.legBye, BallKind.legBye, l10n.legByeSheetTitle, [
              1,
              2,
              3,
              4,
            ]),
          ],
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

enum _Emphasis { strong, normal, quiet }

class _PadRow extends StatelessWidget {
  const _PadRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        for (final (i, child) in children.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ],
    ),
  );
}

class _PadButton extends StatelessWidget {
  const _PadButton({
    required this.label,
    required this.onPressed,
    this.semanticsLabel,
    this.emphasis = _Emphasis.normal,
    this.background,
    this.foreground,
    super.key,
  });

  final String label;
  final String? semanticsLabel;
  final VoidCallback onPressed;
  final _Emphasis emphasis;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isNumber = int.tryParse(label) != null;
    final (bg, fg) = switch (emphasis) {
      _ when background != null => (background!, foreground!),
      _Emphasis.strong => (colors.primary, colors.onPrimary),
      _Emphasis.normal => (
        colors.secondaryContainer,
        colors.onSecondaryContainer,
      ),
      _Emphasis.quiet => (colors.surfaceContainerHighest, colors.onSurface),
    };
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        minimumSize: const Size(48, 64),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: isNumber
            ? Theme.of(context).textTheme.headlineSmall
            : Theme.of(context).textTheme.labelLarge,
      ),
      child: Text(
        label,
        semanticsLabel: semanticsLabel,
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Asks how many runs came off an extra.
Future<int?> showRunsSheet(
  BuildContext context,
  String title,
  List<int> options,
) => showModalBottomSheet<int>(
  context: context,
  showDragHandle: true,
  builder: (context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final runs in options)
                SizedBox(
                  width: 64,
                  height: 56,
                  child: FilledButton.tonal(
                    key: Key('sheet-runs-$runs'),
                    onPressed: () => Navigator.pop(context, runs),
                    child: Text(
                      '$runs',
                      semanticsLabel: AppLocalizations.of(
                        context,
                      ).runsButton(runs),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  ),
);

/// Walks through recording a wicket and returns the event, or null if the
/// scorer backed out.
Future<MatchEvent?> showWicketFlow(
  BuildContext context,
  MatchState match,
) async {
  final innings = match.currentInnings!;
  final how = await showModalBottomSheet<HowOut>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      final options = [
        ...HowOut.values.where(
          (how) =>
              match.allowedDismissals(BallKind.legal).contains(how) ||
              how == HowOut.runOut,
        ),
        HowOut.retired,
      ];
      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.howOutTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              for (final how in options)
                ListTile(
                  key: Key('how-${how.name}'),
                  title: Text(howOutName(how, l10n)),
                  onTap: () => Navigator.pop(context, how),
                ),
            ],
          ),
        ),
      );
    },
  );
  if (how == null || !context.mounted) return null;
  switch (how) {
    case HowOut.runOut:
      return showModalBottomSheet<MatchEvent>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) => _RunOutSheet(match: match),
      );
    case HowOut.retired:
      if (innings.nonStriker == null) {
        return const BatterRetired(Crease.striker);
      }
      final crease = await _pickBatter(
        context,
        match,
        AppLocalizations.of(context).retireWho,
      );
      return crease == null ? null : BatterRetired(crease);
    case _:
      return BallBowled(kind: BallKind.legal, dismissal: Dismissal(how));
  }
}

/// Asks which batter at the crease, for retirements.
Future<Crease?> _pickBatter(
  BuildContext context,
  MatchState match,
  String title,
) {
  final innings = match.currentInnings!;
  return showModalBottomSheet<Crease>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          for (final (crease, player) in [
            (Crease.striker, innings.striker),
            (Crease.nonStriker, innings.nonStriker),
          ])
            if (player != null)
              ListTile(
                key: Key('crease-${crease.name}'),
                title: Text(
                  playerName(match.setup, innings.battingTeam, player),
                ),
                onTap: () => Navigator.pop(context, crease),
              ),
        ],
      ),
    ),
  );
}

class _RunOutSheet extends StatefulWidget {
  const _RunOutSheet({required this.match});

  final MatchState match;

  @override
  State<_RunOutSheet> createState() => _RunOutSheetState();
}

class _RunOutSheetState extends State<_RunOutSheet> {
  Crease _batter = Crease.striker;
  int _runs = 0;
  BallKind _kind = BallKind.legal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final innings = widget.match.currentInnings!;
    final setup = widget.match.setup;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.runOutTitle, style: text.titleLarge),
            const SizedBox(height: 16),
            if (innings.nonStriker != null) ...[
              Text(l10n.whoIsOut, style: text.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<Crease>(
                segments: [
                  for (final (crease, player) in [
                    (Crease.striker, innings.striker!),
                    (Crease.nonStriker, innings.nonStriker!),
                  ])
                    ButtonSegment(
                      value: crease,
                      label: Text(
                        playerName(setup, innings.battingTeam, player),
                        key: Key('runout-${crease.name}'),
                      ),
                    ),
                ],
                selected: {_batter},
                onSelectionChanged: (value) =>
                    setState(() => _batter = value.single),
              ),
              const SizedBox(height: 16),
            ],
            Text(l10n.runsCompleted, style: text.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: [
                for (final runs in [0, 1, 2, 3])
                  ButtonSegment(value: runs, label: Text('$runs')),
              ],
              selected: {_runs},
              onSelectionChanged: (value) =>
                  setState(() => _runs = value.single),
            ),
            const SizedBox(height: 16),
            Text(l10n.deliveryType, style: text.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<BallKind>(
              segments: [
                ButtonSegment(
                  value: BallKind.legal,
                  label: Text(l10n.fairBall),
                ),
                ButtonSegment(value: BallKind.wide, label: Text(l10n.wide)),
                ButtonSegment(value: BallKind.noBall, label: Text(l10n.noBall)),
              ],
              selected: {_kind},
              onSelectionChanged: (value) =>
                  setState(() => _kind = value.single),
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('runout-confirm'),
              style: FilledButton.styleFrom(minimumSize: const Size(48, 52)),
              onPressed: () => Navigator.pop(
                context,
                BallBowled(
                  kind: _kind,
                  runs: _runs,
                  dismissal: Dismissal(HowOut.runOut, batter: _batter),
                ),
              ),
              child: Text(l10n.confirm),
            ),
          ],
        ),
      ),
    );
  }
}
