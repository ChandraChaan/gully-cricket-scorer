import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/arcade_game.dart';
import '../domain/catching_game.dart';
import '../domain/vec3.dart';
import 'engine3d/props.dart';
import 'engine3d/scene3d.dart';
import 'game_shell.dart';

class CatchingScreen extends StatelessWidget {
  const CatchingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GameShell<CatchingGame>(
      gameId: GameId.catching,
      title: l10n.gameCatchingTitle,
      howTo: l10n.gameCatchingHowTo,
      create: (random) => CatchingGame(random: random),
      playfield: (context, game, frame) =>
          _CatchingField(game: game, frame: frame),
    );
  }
}

Camera3 _camera(Size size) => Camera3(
  position: const Vec3(0, 11, -12),
  target: const Vec3(0, 2.5, 8),
  viewport: size,
  fovY: fovToFit(size, CatchingGame.fieldHalfWidth + 0.9, 17),
);

class _CatchingField extends StatelessWidget {
  const _CatchingField({required this.game, required this.frame});

  final CatchingGame game;
  final Listenable frame;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final camera = _camera(constraints.biggest);
        void runTo(Offset position) {
          final spot = camera.groundPoint(position);
          if (spot != null) game.runTo(spot.x, spot.z);
        }

        return Stack(
          children: [
            Positioned.fill(
              child: Listener(
                key: const Key('catchingField'),
                behavior: HitTestBehavior.opaque,
                onPointerDown: (event) => runTo(event.localPosition),
                onPointerMove: (event) => runTo(event.localPosition),
                child: RepaintBoundary(
                  child: CustomPaint(painter: _CatchingPainter(game, frame)),
                ),
              ),
            ),
            ListenableBuilder(
              listenable: frame,
              builder: (context, _) {
                final event = game.lastEvent;
                if (event == null || game.isOver) {
                  return const SizedBox.shrink();
                }
                return GameBanner(
                  text: switch (event) {
                    CatchEvent.perfect => l10n.gameCatchingPerfect,
                    CatchEvent.caught => l10n.gameCatchingCaught,
                    CatchEvent.dropped => l10n.gameCatchingDropped,
                  },
                  color: switch (event) {
                    CatchEvent.perfect => const Color(0xFFFFD54F),
                    CatchEvent.caught => Colors.white,
                    CatchEvent.dropped => const Color(0xFFFF6B6B),
                  },
                  age: game.eventAge,
                  hold: 0.9,
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _CatchingPainter extends CustomPainter {
  _CatchingPainter(this.game, Listenable frame) : super(repaint: frame);

  static final Scene3 _ground = buildMaidan();

  final CatchingGame game;

  @override
  void paint(Canvas canvas, Size size) {
    final camera = _camera(size);
    paintBackdrop(canvas, camera, GameColors.grass);

    const half = CatchingGame.fieldHalfWidth + 0.6;
    const near = CatchingGame.fieldNear - 0.6;
    const far = CatchingGame.fieldFar + 0.6;
    final scene = Scene3()
      // The patch the fielder patrols.
      ..floor(
        -half,
        near,
        half,
        far,
        const Color(0x22FFFFFF),
        layer: Layers.tint,
      )
      ..floor(
        -half,
        near,
        half,
        near + 0.1,
        GameColors.chalk,
        layer: Layers.marks,
      )
      ..floor(
        -half,
        far - 0.1,
        half,
        far,
        GameColors.chalk,
        layer: Layers.marks,
      )
      ..floor(
        -half,
        near,
        -half + 0.1,
        far,
        GameColors.chalk,
        layer: Layers.marks,
      )
      ..floor(
        half - 0.1,
        near,
        half,
        far,
        GameColors.chalk,
        layer: Layers.marks,
      )
      // The batter who keeps skying it.
      ..floor(-1.4, 30, 1.4, 48, GameColors.pitch, layer: Layers.tint);
    addStumps(scene, const Vec3(0, 0, 35.2));
    final batter = addFigure(
      scene,
      feet: const Vec3(-0.5, 0, 34),
      yaw: math.pi,
      shirt: const Color(0xFFF9A825),
      leftHand: const Vec3(-0.1, 1.2, 0.3),
      rightHand: const Vec3(0.1, 1.25, 0.3),
    );
    addBat(scene, batter.right, const Vec3(0.3, 1, -0.2));

    final ball = game.ball;
    if (ball != null) {
      final left = 1 - game.flightProgress;
      scene
        ..disc(
          game.landing.withY(0.02),
          CatchingGame.catchRadius,
          const Color(0x66FF5252),
          layer: Layers.shadows,
        )
        ..disc(
          game.landing.withY(0.03),
          CatchingGame.catchRadius + 0.15 + 3 * left,
          const Color(0xFFFFEB3B),
          innerRadius: CatchingGame.catchRadius + 3 * left,
          layer: Layers.shadows,
        );
      addBall(scene, ball, 0.2);
    }

    // Hands go up as the ball comes down.
    final reach = ball == null
        ? 0.0
        : ((game.flightProgress - 0.55) / 0.3).clamp(0.0, 1.0);
    addFigure(
      scene,
      feet: game.fielder,
      yaw: game.isRunning ? game.facing : 0,
      shirt: const Color(0xFF1E88E5),
      stride: game.isRunning ? math.sin(game.distanceRun * 3.4) : 0,
      leftHand: Vec3(
        -0.3 + 0.12 * reach,
        0.82 + 0.95 * reach,
        0.06 + 0.1 * reach,
      ),
      rightHand: Vec3(
        0.3 - 0.12 * reach,
        0.82 + 0.95 * reach,
        0.06 + 0.1 * reach,
      ),
    );

    Scene3.render(canvas, camera, [_ground, scene]);
  }

  @override
  bool shouldRepaint(_CatchingPainter oldDelegate) => oldDelegate.game != game;
}
