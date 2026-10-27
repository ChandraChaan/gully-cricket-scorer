import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sharer.dart';
import '../../../core/widget_image.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/match_state.dart';
import 'format.dart';
import 'scorecard_text.dart';

/// Shares the scorecard as text, or copies it where there is no share sheet.
Future<void> shareScorecardText(
  BuildContext context,
  WidgetRef ref,
  MatchState match, {
  bool copyOnly = false,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final sharer = ref.read(sharerProvider);
  final text = scorecardText(match, l10n);
  final outcome = copyOnly
      ? await sharer.copyText(text)
      : await sharer.shareText(text, subject: matchTitle(match.setup, l10n));
  final message = switch (outcome) {
    ShareOutcome.shared => null,
    ShareOutcome.copied when copyOnly => l10n.copied,
    ShareOutcome.copied => l10n.shareUnavailable,
    ShareOutcome.failed => l10n.shareFailed,
  };
  if (message != null) {
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Shares the scorecard drawn inside the [RepaintBoundary] behind
/// [boundaryKey] as a PNG.
Future<void> shareScorecardImage(
  BuildContext context,
  WidgetRef ref,
  MatchState match,
  GlobalKey boundaryKey,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final sharer = ref.read(sharerProvider);
  final png = await captureBoundaryPng(boundaryKey);
  if (png == null) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.shareImageFailed)));
    return;
  }
  final outcome = await sharer.shareImage(
    png,
    fileName: 'scorecard-${match.setup.id}.png',
  );
  if (outcome == ShareOutcome.failed) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.shareImageFailed)));
  }
}
