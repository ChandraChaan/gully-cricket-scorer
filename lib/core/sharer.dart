import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// How a share attempt ended.
enum ShareOutcome { shared, copied, failed }

/// Sends scorecards to other apps. Tests replace it with a fake.
abstract interface class Sharer {
  /// Opens the system share sheet with [text]. Where there is none (most
  /// desktop browsers), copies [text] to the clipboard instead.
  Future<ShareOutcome> shareText(String text, {String? subject});

  Future<ShareOutcome> copyText(String text);
}

final class SystemSharer implements Sharer {
  const SystemSharer();

  @override
  Future<ShareOutcome> shareText(String text, {String? subject}) async {
    try {
      // Without a share sheet this throws instead of opening an email.
      await SharePlus.instance.share(
        ShareParams(text: text, subject: subject, mailToFallbackEnabled: false),
      );
      return ShareOutcome.shared;
    } catch (error, stackTrace) {
      developer.log(
        'Share sheet unavailable, copying instead',
        name: 'Sharer',
        error: error,
        stackTrace: stackTrace,
      );
    }
    final copied = await copyText(text);
    return copied == ShareOutcome.failed ? copied : ShareOutcome.copied;
  }

  @override
  Future<ShareOutcome> copyText(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return ShareOutcome.copied;
    } catch (error, stackTrace) {
      developer.log(
        'Could not copy to the clipboard',
        name: 'Sharer',
        error: error,
        stackTrace: stackTrace,
      );
      return ShareOutcome.failed;
    }
  }
}

final sharerProvider = Provider<Sharer>((ref) => const SystemSharer());
