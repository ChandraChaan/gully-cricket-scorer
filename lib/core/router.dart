import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/history/presentation/history_screen.dart';
import '../features/match/presentation/scorecard_screen.dart';
import '../features/match/presentation/scoring_screen.dart';
import '../features/setup/presentation/setup_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HistoryScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const SetupScreen(),
          ),
          GoRoute(
            path: 'match/:id',
            builder: (context, state) =>
                ScoringScreen(matchId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'scorecard',
                builder: (context, state) =>
                    ScorecardScreen(matchId: state.pathParameters['id']!),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
