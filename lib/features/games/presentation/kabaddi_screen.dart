import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/arcade_game.dart';
import '../domain/kabaddi_game.dart';
import '../domain/vec3.dart';
import 'engine3d/props.dart';
import 'engine3d/scene3d.dart';
import 'game_shell.dart';

class KabaddiScreen extends StatelessWidget {
  const KabaddiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GameShell<KabaddiGame>(
      gameId: GameId.kabaddi,
      title: l10n.gameKabaddiTitle,
      howTo: l10n.gameKabaddiHowTo,
      create: (random) => KabaddiGame(random: random),
      playfield: (context, game, frame) =>
          _KabaddiField(game: game, frame: frame),
    );
  }
}

Camera3 _camera(Size size) => Camera3(
  position: const Vec3(0, 17, -7),
  target: const Vec3(0, 0, 3.4),
  viewport: size,
  fovY: fovToFit(size, KabaddiGame.matHalfWidth + 0.9, 17.4),
);

class _KabaddiField extends StatelessWidget {
  const _KabaddiField({required this.game, required this.frame});

  final KabaddiGame game;
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
                key: const Key('kabaddiField'),
                behavior: HitTestBehavior.opaque,
                onPointerDown: (event) => runTo(event.localPosition),
                onPointerMove: (event) => runTo(event.localPosition),
                child: RepaintBoundary(
                  child: CustomPaint(painter: _KabaddiPainter(game, frame)),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0, -0.78),
              child: SafeArea(
                child: ListenableBuilder(
                  listenable: frame,
                  builder: (context, _) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GameMeter(
                        label: l10n.gameKabaddiClock,
                        value: game.timeLeft,
                        color: Color.lerp(
                          const Color(0xFFFF5252),
                          const Color(0xFF66BB6A),
                          game.timeLeft,
                        )!,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.gameKabaddiTags(game.tags),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              shadows: const [Shadow(blurRadius: 6)],
                            ),
                      ),
                    ],
                  ),
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
                    RaidEvent.scored => l10n.gameKabaddiScored(game.lastPoints),
                    RaidEvent.tackled => l10n.gameKabaddiCaught,
                    RaidEvent.timeUp => l10n.gameKabaddiTimeUp,
                  },
                  color: event == RaidEvent.scored
                      ? const Color(0xFFFFD54F)
                      : const Color(0xFFFF6B6B),
                  age: game.eventAge,
                  hold: 1.2,
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _KabaddiPainter extends CustomPainter {
  _KabaddiPainter(this.game, Listenable frame) : super(repaint: frame);

  static const _homeMat = Color(0xFF3F7CAC);
  static const _awayMat = Color(0xFFD9814E);
  static final Scene3 _court = _buildCourt();

  final KabaddiGame game;

  static Scene3 _buildCourt() {
    const half = KabaddiGame.matHalfWidth + 0.5;
    const near = KabaddiGame.matNear - 0.3;
    const far = KabaddiGame.matFar + 0.5;
    final scene = buildMaidan()
      ..floor(-half, near, half, 0, _homeMat, layer: Layers.tint)
      ..floor(-half, 0, half, far, _awayMat, layer: Layers.tint);
    void line(double x0, double z0, double x1, double z1) =>
        scene.floor(x0, z0, x1, z1, GameColors.chalk, layer: Layers.marks);
    line(-half, -0.06, half, 0.06);
    line(-half, 3.7, half, 3.78);
    line(-half, near, half, near + 0.1);
    line(-half, far - 0.1, half, far);
    line(-half, near, -half + 0.1, far);
    line(half - 0.1, near, half, far);
    return scene;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final camera = _camera(size);
    paintBackdrop(canvas, camera, GameColors.grass);
    final scene = Scene3();

    // With a tag in hand, home lights up: get back over the line.
    if (game.tags > 0) {
      scene.floor(
        -KabaddiGame.matHalfWidth - 0.5,
        KabaddiGame.matNear - 0.3,
        KabaddiGame.matHalfWidth + 0.5,
        0,
        const Color(0x5566FF88),
        layer: Layers.marks,
      );
    }

    for (final defender in game.defenders) {
      final at = defender.position;
      final yaw = math.atan2(defender.heading.x, defender.heading.z);
      const shirt = Color(0xFFC62828);
      switch (defender.state) {
        case DefenderState.ready:
          addFigure(
            scene,
            feet: at,
            yaw: yaw,
            shirt: shirt,
            crouch: 0.1,
            stride: 0.3,
            leftHand: const Vec3(-0.6, 1.05, 0.25),
            rightHand: const Vec3(0.6, 1.05, 0.25),
          );
        case DefenderState.windUp:
          scene.disc(
            at.withY(0.03),
            0.75,
            const Color(0xCCFFEB3B),
            innerRadius: 0.55,
            layer: Layers.shadows,
          );
          addFigure(
            scene,
            feet: at,
            yaw: yaw,
            shirt: const Color(0xFFFF7043),
            crouch: 0.3,
            lean: 0.3,
            stride: 0.5,
            leftHand: const Vec3(-0.35, 0.9, 0.4),
            rightHand: const Vec3(0.35, 0.9, 0.4),
          );
        case DefenderState.lunge:
          addFigure(
            scene,
            feet: at,
            yaw: yaw,
            shirt: const Color(0xFFFF7043),
            crouch: 0.35,
            lean: 0.6,
            stride: 0.9,
            leftHand: const Vec3(-0.2, 1.0, 0.9),
            rightHand: const Vec3(0.2, 1.0, 0.9),
          );
        case DefenderState.down:
          scene.disc(
            at.withY(0.03),
            KabaddiGame.tagRadius,
            const Color(0x8866FF88),
            layer: Layers.shadows,
          );
          addFallenFigure(scene, middle: at, yaw: yaw, shirt: shirt);
        case DefenderState.out:
          break;
      }
    }

    addFigure(
      scene,
      feet: game.raider,
      yaw: game.isRunning ? game.facing : 0,
      shirt: const Color(0xFF1565C0),
      stride: game.isRunning ? math.sin(game.distanceRun * 3.4) : 0,
      leftHand: const Vec3(-0.35, 1.0, 0.25),
      rightHand: const Vec3(0.35, 1.0, 0.25),
    );

    Scene3.render(canvas, camera, [_court, scene]);
  }

  @override
  bool shouldRepaint(_KabaddiPainter oldDelegate) => oldDelegate.game != game;
}
