import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// A full-screen error with an optional retry and a way back.
class ErrorView extends StatelessWidget {
  const ErrorView({
    required this.message,
    this.onRetry,
    this.onBack,
    super.key,
  });

  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (onRetry case final retry?)
              FilledButton(onPressed: retry, child: Text(l10n.retry)),
            if (onBack case final back?)
              TextButton(onPressed: back, child: Text(l10n.backToMatches)),
          ],
        ),
      ),
    );
  }
}
