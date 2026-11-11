import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/games/domain/arcade_game.dart';
import '../features/games/presentation/batting_screen.dart';
import '../features/games/presentation/carrom_screen.dart';
import '../features/games/presentation/catching_screen.dart';
import '../features/games/presentation/direct_hit_screen.dart';
import '../features/games/presentation/duel_screen.dart';
import '../features/games/presentation/gilli_danda_screen.dart';
import '../features/games/presentation/home_screen.dart';
import '../features/games/presentation/kabaddi_screen.dart';
import '../features/games/presentation/kite_fight_screen.dart';
import '../features/games/presentation/lane_runner_screen.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/match/presentation/scorecard_screen.dart';
import '../features/match/presentation/scoring_screen.dart';
import '../features/setup/presentation/setup_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    redirect: (context, state) {
      // Links from before the scorer moved under /scorer, and the old
      // games list, which is now the home screen.
      final path = state.uri.path;
      if (path == '/new' || path.startsWith('/match/')) return '/scorer$path';
      if (path == '/games') return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'scorer',
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
          for (final game in GameId.values)
            GoRoute(
              path: 'games/${game.key}',
              builder: (context, state) => switch (game) {
                GameId.batting => const BattingScreen(),
                GameId.catching => const CatchingScreen(),
                GameId.directHit => const DirectHitScreen(),
                GameId.laneRunner => const LaneRunnerScreen(),
                GameId.duel => const DuelScreen(),
                GameId.kabaddi => const KabaddiScreen(),
                GameId.gilliDanda => const GilliDandaScreen(),
                GameId.kiteFight => const KiteFightScreen(),
                GameId.carrom => const CarromScreen(),
              },
            ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
