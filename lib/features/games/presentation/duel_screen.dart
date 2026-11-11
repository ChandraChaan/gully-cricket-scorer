import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/arcade_game.dart';
import '../domain/duel_game.dart';
import '../domain/vec3.dart';
import 'engine3d/props.dart';
import 'engine3d/scene3d.dart';
import 'game_shell.dart';

class DuelScreen extends StatelessWidget {
  const DuelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GameShell<DuelGame>(
      gameId: GameId.duel,
      title: l10n.gameDuelTitle,
      howTo: l10n.gameDuelHowTo,
      create: (random) => DuelGame(random: random),
      playfield: (context, game, frame) => _DuelField(game: game, frame: frame),
    );
  }
}

class _DuelField extends StatelessWidget {
  const _DuelField({required this.game, required this.frame});

  final DuelGame game;
  final Listenable frame;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final down = event is KeyDownEvent;
    if (!down && event is! KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft) {
      game.moveInput = down ? -1 : 0;
    } else if (key == LogicalKeyboardKey.arrowRight) {
      game.moveInput = down ? 1 : 0;
    } else if (key == LogicalKeyboardKey.arrowDown) {
      game.blockHeld = down;
    } else if (key == LogicalKeyboardKey.keyZ) {
      if (down) game.punch();
    } else if (key == LogicalKeyboardKey.keyX) {
      if (down) game.kick();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: _DuelPainter(game, frame)),
            ),
          ),
          Align(
            alignment: const Alignment(0, -0.76),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListenableBuilder(
                  listenable: frame,
                  builder: (context, _) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _Health(
                        name: l10n.gameDuelYou,
                        fighter: game.player,
                        color: const Color(0xFF42A5F5),
                      ),
                      _Health(
                        name: l10n.gameDuelOpponent(game.opponentNumber),
                        fighter: game.opponent,
                        color: const Color(0xFFEF5350),
                        alignEnd: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ListenableBuilder(
            listenable: frame,
            builder: (context, _) {
              if (!game.isBetweenBouts || game.isOver) {
                return const SizedBox.shrink();
              }
              final won = game.opponent.move == FighterMove.down;
              return GameBanner(
                text: won ? l10n.gameDuelKnockout : l10n.gameDuelDown,
                color: won ? const Color(0xFFFFD54F) : const Color(0xFFFF6B6B),
                age: won ? game.opponent.moveTime : game.player.moveTime,
                hold: 1.6,
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
                    GamePadButton(
                      key: const Key('duelLeft'),
                      label: l10n.gameDuelBack,
                      icon: Icons.arrow_back,
                      onDown: () => game.moveInput = -1,
                      onUp: () => game.moveInput = 0,
                    ),
                    const SizedBox(width: 8),
                    GamePadButton(
                      key: const Key('duelRight'),
                      label: l10n.gameDuelForward,
                      icon: Icons.arrow_forward,
                      onDown: () => game.moveInput = 1,
                      onUp: () => game.moveInput = 0,
                    ),
                    const Spacer(),
                    GamePadButton(
                      key: const Key('duelBlock'),
                      label: l10n.gameDuelBlock,
                      icon: Icons.shield,
                      onDown: () => game.blockHeld = true,
                      onUp: () => game.blockHeld = false,
                    ),
                    const SizedBox(width: 8),
                    GamePadButton(
                      key: const Key('duelPunch'),
                      label: l10n.gameDuelPunch,
                      icon: Icons.front_hand,
                      onDown: game.punch,
                    ),
                    const SizedBox(width: 8),
                    GamePadButton(
                      key: const Key('duelKick'),
                      label: l10n.gameDuelKick,
                      icon: Icons.sports_martial_arts,
                      onDown: game.kick,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Health extends StatelessWidget {
  const _Health({
    required this.name,
    required this.fighter,
    required this.color,
    this.alignEnd = false,
  });

  final String name;
  final Fighter fighter;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Text(
            name,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              shadows: const [Shadow(blurRadius: 4)],
            ),
          ),
        ),
        const SizedBox(height: 4),
        GameMeter(
          label: name,
          value: fighter.health / fighter.maxHealth,
          color: color,
          width: 130,
        ),
      ],
    );
  }
}

class _DuelPainter extends CustomPainter {
  _DuelPainter(this.game, Listenable frame) : super(repaint: frame);

  static const _mud = Color(0xFFB07B4F);
  static const _shirts = [
    Color(0xFFD32F2F),
    Color(0xFF7B1FA2),
    Color(0xFF00897B),
    Color(0xFF5D4037),
    Color(0xFF455A64),
  ];
  static final Scene3 _pit = _buildPit();

  final DuelGame game;

  /// The mud pit, its rope and the crowd behind it.
  static Scene3 _buildPit() {
    final scene = buildMaidan()
      ..disc(const Vec3(0, 0.01, 0), 6, _mud, layer: Layers.tint, segments: 24)
      ..disc(
        const Vec3(0, 0.02, 0),
        6.3,
        const Color(0xFFE8D8B0),
        innerRadius: 6,
        layer: Layers.tint,
        segments: 24,
      );
    final random = math.Random(3);
    for (var i = 0; i < 9; i++) {
      addFigure(
        scene,
        feet: Vec3(-6 + i * 1.5 + random.nextDouble() * 0.5, 0, 6.5),
        yaw: math.pi,
        shirt: _houseShirts[i % _houseShirts.length],
        leftHand: Vec3(-0.3, 0.9 + random.nextDouble() * 0.9, 0.1),
      );
    }
    return scene;
  }

  static const _houseShirts = [
    Color(0xFFFFB300),
    Color(0xFF8E24AA),
    Color(0xFF43A047),
    Color(0xFFF4511E),
    Color(0xFF1E88E5),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final player = game.player;
    final foe = game.opponent;
    final middle = (player.x + foe.x) / 2;
    final gap = foe.x - player.x;
    // Stand back far enough to keep both fighters in the frame.
    const fovY = 1.25;
    final tanHalfWidth = math.tan(fovY / 2) * size.aspectRatio;
    final distance = math.max(3.4, (gap / 2 + 1.25) / tanHalfWidth);
    final camera = Camera3(
      position: Vec3(middle, 1.5, -distance),
      target: Vec3(middle, 1.05, 0),
      viewport: size,
      fovY: fovY,
    );
    paintBackdrop(canvas, camera, GameColors.grass);

    final scene = Scene3();
    _addFighter(scene, player, const Color(0xFF1565C0));
    _addFighter(
      scene,
      foe,
      _shirts[(game.opponentNumber - 1) % _shirts.length],
    );
    Scene3.render(canvas, camera, [_pit, scene]);
  }

  void _addFighter(Scene3 scene, Fighter fighter, Color shirt) {
    final feet = Vec3(fighter.x, 0, 0);
    final yaw = fighter.facing * math.pi / 2;
    if (fighter.move == FighterMove.down) {
      addFallenFigure(scene, middle: feet, yaw: -yaw, shirt: shirt);
      return;
    }
    // How far through its reach an attack is: out fast, back slower.
    var reach = 0.0;
    final attack = fighter.attack;
    if (attack != null) {
      final time = fighter.moveTime;
      reach = time < attack.startup
          ? time / attack.startup
          : time < attack.startup + attack.active
          ? 1
          : 1 - (time - attack.startup - attack.active) / attack.recovery;
    }
    final step = math.sin(fighter.walked * 7) * 0.5;
    switch (fighter.move) {
      case FighterMove.punch:
        addFigure(
          scene,
          feet: feet,
          yaw: yaw,
          shirt: shirt,
          stride: 0.4,
          lean: 0.12 * reach,
          rightHand: Vec3(0.1, 1.32, 0.3 + 0.62 * reach),
          leftHand: const Vec3(-0.12, 1.2, 0.25),
        );
      case FighterMove.kick:
        addFigure(
          scene,
          feet: feet,
          yaw: yaw,
          shirt: shirt,
          lean: -0.18 * reach,
          rightHand: const Vec3(0.2, 1.15, 0.2),
          leftHand: const Vec3(-0.25, 1.1, 0.1),
          leftFoot: const Vec3(-0.1, 0, -0.1),
          rightFoot: Vec3(0.1, 0.05 + 0.9 * reach, 0.2 + 1.0 * reach),
        );
      case FighterMove.block:
        addFigure(
          scene,
          feet: feet,
          yaw: yaw,
          shirt: shirt,
          stride: 0.35,
          crouch: 0.08,
          rightHand: const Vec3(0.1, 1.5, 0.32),
          leftHand: const Vec3(-0.1, 1.45, 0.3),
        );
      case FighterMove.hurt:
        addFigure(
          scene,
          feet: feet,
          yaw: yaw,
          shirt: shirt,
          stride: -0.3,
          lean: -0.25,
          rightHand: const Vec3(0.4, 1.2, -0.1),
          leftHand: const Vec3(-0.4, 1.3, -0.1),
        );
      case FighterMove.idle || FighterMove.down:
        addFigure(
          scene,
          feet: feet,
          yaw: yaw,
          shirt: shirt,
          stride: 0.3 + step * 0.6,
          rightHand: const Vec3(0.12, 1.25, 0.35),
          leftHand: const Vec3(-0.12, 1.2, 0.25),
        );
    }
  }

  @override
  bool shouldRepaint(_DuelPainter oldDelegate) => oldDelegate.game != game;
}
