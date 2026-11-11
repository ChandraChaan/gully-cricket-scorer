import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/arcade_game.dart';
import '../domain/batting_game.dart';
import '../domain/vec3.dart';
import 'engine3d/props.dart';
import 'engine3d/scene3d.dart';
import 'game_shell.dart';

class BattingScreen extends StatelessWidget {
  const BattingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GameShell<BattingGame>(
      gameId: GameId.batting,
      title: l10n.gameBattingTitle,
      howTo: l10n.gameBattingHowTo,
      create: (random) => BattingGame(random: random),
      playfield: (context, game, frame) =>
          _BattingField(game: game, frame: frame),
    );
  }
}

class _BattingField extends StatelessWidget {
  const _BattingField({required this.game, required this.frame});

  final BattingGame game;
  final Listenable frame;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            game.swing(ShotDirection.leg),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            game.swing(ShotDirection.straight),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            game.swing(ShotDirection.off),
      },
      child: Focus(
        autofocus: true,
        child: Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(painter: _BattingPainter(game, frame)),
              ),
            ),
            ListenableBuilder(
              listenable: frame,
              builder: (context, _) {
                final result = game.lastResult;
                if (result == null || game.isOver) {
                  return const SizedBox.shrink();
                }
                return GameBanner(
                  text: switch (result.outcome) {
                    BallOutcome.six => l10n.gameBattingSix,
                    BallOutcome.four => l10n.gameBattingFour,
                    BallOutcome.runs => l10n.gameBattingRuns(result.runs),
                    BallOutcome.dot => l10n.gameBattingDot,
                    BallOutcome.bowled => l10n.gameBattingBowled,
                    BallOutcome.caught => l10n.gameBattingCaught,
                  },
                  color: result.isWicket
                      ? const Color(0xFFFF6B6B)
                      : result.runs >= 4
                      ? const Color(0xFFFFD54F)
                      : Colors.white,
                  age: game.resultAge,
                  hold: 1.4,
                );
              },
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  child: Row(
                    children: [
                      _ShotButton(
                        key: const Key('shotLeg'),
                        label: l10n.gameBattingLeg,
                        icon: Icons.turn_left,
                        onDown: () => game.swing(ShotDirection.leg),
                      ),
                      const SizedBox(width: 8),
                      _ShotButton(
                        key: const Key('shotStraight'),
                        label: l10n.gameBattingStraight,
                        icon: Icons.straight,
                        onDown: () => game.swing(ShotDirection.straight),
                      ),
                      const SizedBox(width: 8),
                      _ShotButton(
                        key: const Key('shotOff'),
                        label: l10n.gameBattingOff,
                        icon: Icons.turn_right,
                        onDown: () => game.swing(ShotDirection.off),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fires on touch down, not on release: timing is the whole game.
class _ShotButton extends StatelessWidget {
  const _ShotButton({
    required this.label,
    required this.icon,
    required this.onDown,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback onDown;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        onTap: onDown,
        child: Listener(
          onPointerDown: (_) => onDown(),
          child: Container(
            height: 76,
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.primary, width: 2),
            ),
            child: ExcludeSemantics(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: colors.onPrimaryContainer),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BattingPainter extends CustomPainter {
  _BattingPainter(this.game, Listenable frame) : super(repaint: frame);

  static final Scene3 _lane = buildGully();
  static const _batter = Vec3(-0.55, 0, 1);
  static const _bowlerEnd = 16.6;

  final BattingGame game;

  @override
  void paint(Canvas canvas, Size size) {
    final camera = Camera3(
      position: const Vec3(0, 3, -6.2),
      target: const Vec3(0, 0.7, 6),
      viewport: size,
      fovY: fovToFit(size, 2.9, 7.6),
    );
    paintBackdrop(canvas, camera, GameColors.dust);

    final scene = Scene3()
      // Where bat meets ball.
      ..floor(
        -1.4,
        BattingGame.contactZ - 0.3,
        1.4,
        BattingGame.contactZ + 0.3,
        const Color(0x40FFFFFF),
        layer: Layers.marks,
      );
    addStumps(scene, Vec3.zero, broken: game.stumpsBroken);
    addStumps(scene, const Vec3(0, 0, _bowlerEnd));
    _addBowler(scene);
    _addBatter(scene);
    if (game.phase != BattingPhase.runUp) addBall(scene, game.ball, 0.13);

    Scene3.render(canvas, camera, [_lane, scene]);
  }

  void _addBowler(Scene3 scene) {
    final runningIn = game.phase == BattingPhase.runUp;
    final progress = runningIn
        ? (game.phaseTime / BattingGame.runUpTime).clamp(0.0, 1.0)
        : 1.0;
    // The arm comes over in the last stride.
    final arm = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);
    final hands = addFigure(
      scene,
      feet: Vec3(0.5, 0, _bowlerEnd + 3.6 - 3.6 * progress),
      yaw: math.pi,
      shirt: const Color(0xFF1565C0),
      stride: runningIn ? math.sin(game.phaseTime * 16) : 0.3,
      rightHand: runningIn
          ? Vec3(0.3, 0.82 + 1.2 * arm, 0.06 - 0.3 * arm)
          : const Vec3(0.2, 0.7, 0.45),
    );
    if (runningIn) scene.ball(hands.right, 0.13, GameColors.leather);
  }

  void _addBatter(Scene3 scene) {
    final hands = addFigure(
      scene,
      feet: _batter,
      yaw: math.pi / 2,
      shirt: const Color(0xFFF9A825),
      stride: 0.35,
      leftHand: const Vec3(-0.12, 0.92, 0.36),
      rightHand: const Vec3(0.02, 0.86, 0.36),
    );
    const stance = Vec3(0.1, -1, -0.3);
    const backlift = Vec3(0, 0.8, -0.7);
    final through = switch (game.shot) {
      ShotDirection.leg => const Vec3(-1, -0.05, 0.35),
      ShotDirection.off => const Vec3(1, -0.05, 0.35),
      _ => const Vec3(0.08, -0.3, 1),
    };
    final Vec3 direction;
    if (game.shot == null) {
      // Pick the bat up as the ball comes down.
      final time = game.timeToContact;
      final lift = time == null ? 0.0 : (1 - time / 0.5).clamp(0.0, 1.0);
      direction = stance.lerp(backlift, lift);
    } else {
      final swing = Curves.easeOut.transform(
        (game.swingAge / 0.14).clamp(0, 1),
      );
      direction = backlift.lerp(through, swing);
    }
    addBat(
      scene,
      hands.left.lerp(hands.right, 0.5),
      direction,
      face: const Vec3(0, 0, 1),
    );
  }

  @override
  bool shouldRepaint(_BattingPainter oldDelegate) => oldDelegate.game != game;
}
