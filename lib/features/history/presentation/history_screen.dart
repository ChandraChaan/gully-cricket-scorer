import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../match/domain/match_state.dart';
import '../../match/presentation/format.dart';
import '../../match/presentation/saved_matches_controller.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final matches = ref.watch(savedMatchesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('newMatch'),
        onPressed: () => context.go('/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.newMatch),
      ),
      body: switch (matches) {
        AsyncData(:final value) when value.isEmpty => const _EmptyHistory(),
        AsyncData(:final value) => ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          itemCount: value.length,
          itemBuilder: (context, index) {
            final match = value[index];
            return _MatchTile(key: ValueKey(match.setup.id), match: match);
          },
        ),
        AsyncError() => ErrorView(
          message: l10n.historyLoadError,
          onRetry: () => ref.read(savedMatchesProvider.notifier).reload(),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sports_cricket,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(l10n.historyEmptyTitle, style: text.titleLarge),
            const SizedBox(height: 8),
            Text(
              l10n.historyEmptyBody,
              textAlign: TextAlign.center,
              style: text.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchTile extends ConsumerWidget {
  const _MatchTile({required this.match, super.key});

  final MatchState match;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteMatchTitle),
        content: Text(l10n.deleteMatchBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            key: const Key('confirmDelete'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final deleted = await ref
        .read(savedMatchesProvider.notifier)
        .delete(match.setup.id);
    if (!deleted && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.storageError)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final setup = match.setup;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = DateFormat.yMMMd(locale).format(setup.createdAt.toLocal());
    final status = switch (match.result) {
      final result? => resultText(result, setup, l10n),
      null when match.isStarted => l10n.matchInProgress,
      null => l10n.matchNotStarted,
    };
    final scores = [
      for (final innings in match.innings.take(2))
        '${setup.teams[innings.battingTeam].name} '
            '${l10n.scoreLine(innings.runs, innings.wickets)}',
    ].join(' · ');
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
        title: Text(matchTitle(setup, l10n)),
        subtitle: Text(
          [status, if (scores.isNotEmpty) scores, date].join('\n'),
        ),
        isThreeLine: true,
        onTap: () => context.go('/match/${setup.id}'),
        trailing: IconButton(
          tooltip: l10n.deleteMatch,
          onPressed: () => _delete(context, ref),
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }
}
