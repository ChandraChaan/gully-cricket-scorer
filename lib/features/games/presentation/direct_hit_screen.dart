import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/arcade_game.dart';
import '../domain/direct_hit_game.dart';
import '../domain/vec3.dart';
import 'engine3d/props.dart';
import 'engine3d/scene3d.dart';
import 'game_shell.dart';

class DirectHitScreen extends StatelessWidget {
  const DirectHitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GameShell<DirectHitGame>(
      gameId: GameId.directHit,
      title: l10n.gameDirectHitTitle,
      howTo: l10n.gameDirectHitHowTo,
      create: (random) => DirectHitGame(random: random),
      playfield: (context, game, frame) =>
          _DirectHitField(game: game, frame: frame),
    );
  }
}

/// A throw being lined up: an angle and a power from 0 to 1.
typedef _Aim = ({double yaw, double power});

class _DirectHitField extends StatefulWidget {
  const _DirectHitField({required this.game, required this.frame});

  final DirectHitGame game;
  final Listenable frame;

  @override
  State<_DirectHitField> createState() => _DirectHitFieldState();
}

class _DirectHitFieldState extends State<_DirectHitField> {
  /// Below this much pull the finger is treated as a slip, not a throw.
  static const _minPower = 0.08;

  final _aim = ValueNotifier<_Aim?>(null);
  Offset? _start;

  @override
  void dispose() {
    _aim.dispose();
    super.dispose();
  }

  void _drag(Offset position, Size size) {
    final start = _start;
    if (start == null) return;
    final pull = position - start;
    _aim.value = (
      yaw:
          (pull.dx / (size.width * 0.45)).clamp(-1.0, 1.0) *
          DirectHitGame.maxYaw,
      power: (-pull.dy / (size.height * 0.28)).clamp(0.0, 1.0),
    );
  }

  void _release() {
    final aim = _aim.value;
    if (aim != null && aim.power >= _minPower) {
      widget.game.throwBall(aim.yaw, aim.power);
    }
    _start = null;
    _aim.value = null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final game = widget.game;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return Stack(
          children: [
            Positioned.fill(
              child: Listener(
                key: const Key('directHitField'),
                behavior: HitTestBehavior.opaque,
                onPointerDown: (event) => _start = event.localPosition,
                onPointerMove: (event) => _drag(event.localPosition, size),
                onPointerUp: (_) => _release(),
                onPointerCancel: (_) {
                  _start = null;
                  _aim.value = null;
                },
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _DirectHitPainter(
                      game,
                      _aim,
                      Listenable.merge([widget.frame, _aim]),
                    ),
                  ),
                ),
              ),
            ),
            // How close the runner is to making it home.
            Align(
              alignment: const Alignment(0, -0.78),
              child: SafeArea(
                child: ListenableBuilder(
                  listenable: widget.frame,
                  builder: (context, _) => Semantics(
                    label: l10n.gameDirectHitRunner,
                    value: '${(game.runnerProgress * 100).round()}%',
                    child: SizedBox(
                      width: 180,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          minHeight: 10,
                          value: game.runnerProgress,
                          backgroundColor: Colors.black45,
                          color: Color.lerp(
                            const Color(0xFF66BB6A),
                            const Color(0xFFFF5252),
                            game.runnerProgress,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            ListenableBuilder(
              listenable: widget.frame,
              builder: (context, _) {
                final (text, color) = switch (game.phase) {
                  DirectHitPhase.out when game.lastWasFull => (
                    l10n.gameDirectHitFull,
                    const Color(0xFFFFD54F),
                  ),
                  DirectHitPhase.out => (l10n.gameDirectHitOut, Colors.white),
                  DirectHitPhase.safe => (
                    l10n.gameDirectHitSafe,
                    const Color(0xFFFF6B6B),
                  ),
                  _ => (null, Colors.white),
                };
                if (text == null) return const SizedBox.shrink();
                return GameBanner(
                  text: text,
                  color: color,
                  age: 1.2 - game.pause,
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

class _DirectHitPainter extends CustomPainter {
  _DirectHitPainter(this.game, this.aim, Listenable repaint)
    : super(repaint: repaint);

  static final Scene3 _ground = buildMaidan();

  final DirectHitGame game;
  final ValueNotifier<_Aim?> aim;

  @override
  void paint(Canvas canvas, Size size) {
    final stumps = game.stumps;
    // Zoom so the stumps and the runner fill the width, near or far.
    final camera = Camera3(
      position: const Vec3(0, 2.1, -1.8),
      target: const Vec3(0, 0.3, 12),
      viewport: size,
      fovY: fovToFit(size, stumps.x.abs() + 2.4, stumps.z + 1.8),
    );
    paintBackdrop(canvas, camera, GameColors.grass);

    final crease = stumps.z + DirectHitGame.creaseGap;
    final scene = Scene3()
      ..floor(
        stumps.x - 1.4,
        stumps.z - 1,
        stumps.x + 1.4,
        stumps.z + DirectHitGame.runnerStart + 3,
        GameColors.pitch,
        layer: Layers.tint,
      )
      ..floor(
        stumps.x - 1.4,
        crease,
        stumps.x + 1.4,
        crease + 0.08,
        GameColors.chalk,
        layer: Layers.marks,
      );
    addStumps(scene, stumps, broken: game.phase == DirectHitPhase.out);

    final home = game.phase == DirectHitPhase.safe;
    final hands = addFigure(
      scene,
      feet: game.runner,
      yaw: math.pi,
      shirt: const Color(0xFFF9A825),
      stride: home ? 0 : math.sin(game.runnerProgress * 26),
      rightHand: const Vec3(0.3, 0.9, 0.3),
    );
    addBat(scene, hands.right, const Vec3(0.1, -0.5, -1));

    final ball = game.ball;
    if (ball != null) {
      addBall(scene, ball, 0.16);
    } else if (game.canThrow) {
      final lined = aim.value;
      scene.ball(DirectHitGame.release, 0.1, GameColors.leather);
      if (lined != null) {
        for (final point in game.previewPath(lined.yaw, lined.power)) {
          scene.ball(point, 0.06, Colors.white);
        }
      }
    }

    Scene3.render(canvas, camera, [_ground, scene]);
  }

  @override
  bool shouldRepaint(_DirectHitPainter oldDelegate) => oldDelegate.game != game;
}
