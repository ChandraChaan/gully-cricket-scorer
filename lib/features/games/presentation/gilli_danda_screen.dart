import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/arcade_game.dart';
import '../domain/gilli_danda_game.dart';
import '../domain/vec3.dart';
import 'engine3d/props.dart';
import 'engine3d/scene3d.dart';
import 'game_shell.dart';

class GilliDandaScreen extends StatelessWidget {
  const GilliDandaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GameShell<GilliDandaGame>(
      gameId: GameId.gilliDanda,
      title: l10n.gameGilliTitle,
      howTo: l10n.gameGilliHowTo,
      create: (random) => GilliDandaGame(random: random),
      playfield: (context, game, frame) => CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.space): game.tap},
        child: Focus(
          autofocus: true,
          child: Stack(
            children: [
              Positioned.fill(
                child: Semantics(
                  button: true,
                  label: l10n.gameGilliTap,
                  onTap: game.tap,
                  child: Listener(
                    key: const Key('gilliField'),
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (_) => game.tap(),
                    child: RepaintBoundary(
                      child: CustomPaint(painter: _GilliPainter(game, frame)),
                    ),
                  ),
                ),
              ),
              ListenableBuilder(
                listenable: frame,
                builder: (context, _) {
                  final result = game.lastResult;
                  final showing =
                      game.phase == GilliPhase.flying ||
                      game.phase == GilliPhase.done;
                  if (result == null || !showing) {
                    return Align(
                      alignment: const Alignment(0, 0.82),
                      child: IgnorePointer(
                        child: Text(
                          game.phase == GilliPhase.ready
                              ? l10n.gameGilliFlick
                              : l10n.gameGilliSwing,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                shadows: const [Shadow(blurRadius: 8)],
                              ),
                        ),
                      ),
                    );
                  }
                  final age = game.phase == GilliPhase.flying
                      ? game.phaseTime
                      : game.phaseTime + (result == GilliResult.miss ? 0 : 1.5);
                  return GameBanner(
                    text: switch (result) {
                      GilliResult.perfect => l10n.gameGilliPerfect(
                        game.lastDistance,
                      ),
                      GilliResult.good || GilliResult.fair =>
                        l10n.gameGilliDistance(game.lastDistance),
                      GilliResult.miss => l10n.gameGilliMiss,
                    },
                    color: switch (result) {
                      GilliResult.perfect => const Color(0xFFFFD54F),
                      GilliResult.miss => const Color(0xFFFF6B6B),
                      _ => Colors.white,
                    },
                    age: age,
                    hold: 2.4,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GilliPainter extends CustomPainter {
  _GilliPainter(this.game, Listenable frame) : super(repaint: frame);

  static final Scene3 _lane = buildGully();
  static const _wood = Color(0xFF8D5A2B);
  static const _spot = Vec3(0.25, 0, 0.6);

  final GilliDandaGame game;

  @override
  void paint(Canvas canvas, Size size) {
    final camera = Camera3(
      position: const Vec3(1.9, 1.9, -3.6),
      target: const Vec3(0.1, 1, 2.5),
      viewport: size,
      fovY: fovToFit(size, 1.9, 4.6),
    );
    paintBackdrop(canvas, camera, GameColors.dust);
    final scene = Scene3();

    // The height to hit it at: a frame that turns green when the gilli is
    // inside it.
    const reach = 0.42;
    final inZone =
        game.phase == GilliPhase.rising &&
        (game.gilli.y - GilliDandaGame.strikeHeight).abs() <=
            GilliDandaGame.goodBand;
    final frame = inZone ? const Color(0xFF69F0AE) : const Color(0xCCFFEB3B);
    Vec3 corner(double x, double z) =>
        _spot + Vec3(x * reach, GilliDandaGame.strikeHeight, z * reach);
    for (final (a, b) in [
      (corner(-1, -1), corner(1, -1)),
      (corner(1, -1), corner(1, 1)),
      (corner(1, 1), corner(-1, 1)),
      (corner(-1, 1), corner(-1, -1)),
    ]) {
      scene.beam(a, b, 0.018, 0.018, frame, side: Vec3.up);
    }

    // The striker and the danda.
    final swing = Curves.easeOut.transform((game.swingAge / 0.16).clamp(0, 1));
    final hands = addFigure(
      scene,
      feet: const Vec3(-0.55, 0, 0.45),
      yaw: math.pi / 2,
      shirt: const Color(0xFF00897B),
      stride: 0.35,
      leftHand: const Vec3(-0.1, 1.05, 0.35),
      rightHand: const Vec3(0.02, 1.0, 0.36),
    );
    final grip = hands.left.lerp(hands.right, 0.5);
    final along = const Vec3(
      -0.5,
      0.75,
      -0.6,
    ).lerp(const Vec3(0.9, 0.05, 0.5), swing).normalized;
    scene.beam(grip - along * 0.05, grip + along * 0.8, 0.028, 0.028, _wood);

    // The gilli, tumbling end over end.
    final spin = game.phase == GilliPhase.ready ? 0.0 : game.phaseTime * 14;
    final axis = Vec3(0.25, math.sin(spin), math.cos(spin)).normalized;
    final gilli = game.gilli;
    scene
      ..disc(gilli.withY(0.012), 0.14, GameColors.shadow, segments: 8)
      ..beam(
        gilli - axis * 0.15,
        gilli + axis * 0.15,
        0.035,
        0.035,
        const Color(0xFFE2C48A),
      );

    Scene3.render(canvas, camera, [_lane, scene]);
  }

  @override
  bool shouldRepaint(_GilliPainter oldDelegate) => oldDelegate.game != game;
}
