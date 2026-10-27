import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'l10n/app_localizations.dart';

class GullyCricketApp extends ConsumerWidget {
  const GullyCricketApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ThemeData theme(Brightness brightness) {
      final colors = ColorScheme.fromSeed(
        seedColor: const Color(0xFF1E7A46),
        brightness: brightness,
      );
      return ThemeData(
        colorScheme: colors,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
        cardTheme: const CardThemeData(margin: EdgeInsets.only(bottom: 8)),
      );
    }

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
