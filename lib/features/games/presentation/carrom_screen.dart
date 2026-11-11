import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/arcade_game.dart';
import '../domain/carrom_game.dart';
import 'game_shell.dart';

class CarromScreen extends StatelessWidget {
  const CarromScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GameShell<CarromGame>(
      gameId: GameId.carrom,
      title: l10n.gameCarromTitle,
      howTo: l10n.gameCarromHowTo,
      create: (random) => CarromGame(random: random),
      playfield: (context, game, frame) =>
          _CarromField(game: game, frame: frame),
    );
  }
}

/// The square the board is drawn in.
Rect _boardRect(Size size) {
  final side = math.min(size.width - 24, size.height * 0.62);
  return Rect.fromCenter(
    center: Offset(size.width / 2, size.height * 0.54),
    width: side,
    height: side,
  );
}

/// A shot being lined up: which way and how hard.
typedef _Aim = ({double dx, double dy, double power});

class _CarromField extends StatefulWidget {
  const _CarromField({required this.game, required this.frame});

  final CarromGame game;
  final Listenable frame;

  @override
  State<_CarromField> createState() => _CarromFieldState();
}

class _CarromFieldState extends State<_CarromField> {
  final _aim = ValueNotifier<_Aim?>(null);
  Offset? _start;

  @override
  void dispose() {
    _aim.dispose();
    super.dispose();
  }

  void _down(Offset position, Rect board) {
    if (widget.game.isMoving) return;
    widget.game.placeStriker((position.dx - board.left) / board.width);
    _start = position;
  }

  void _drag(Offset position, Rect board) {
    final start = _start;
    if (start == null) return;
    // Pull back like a catapult: the shot goes the opposite way.
    final pull = start - position;
    final length = pull.distance;
    if (length < 4 || pull.dy > -2) {
      _aim.value = null;
      return;
    }
    _aim.value = (
      dx: pull.dx / length,
      dy: pull.dy / length,
      power: (length / (board.width * 0.4)).clamp(0.0, 1.0),
    );
  }

  void _release() {
    final aim = _aim.value;
    if (aim != null && aim.power >= 0.08) {
      widget.game.shoot(aim.dx, aim.dy, aim.power);
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
        final board = _boardRect(constraints.biggest);
        return Stack(
          children: [
            Positioned.fill(
              child: Listener(
                key: const Key('carromField'),
                behavior: HitTestBehavior.opaque,
                onPointerDown: (event) => _down(event.localPosition, board),
                onPointerMove: (event) => _drag(event.localPosition, board),
                onPointerUp: (_) => _release(),
                onPointerCancel: (_) {
                  _start = null;
                  _aim.value = null;
                },
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _CarromPainter(
                      game,
                      _aim,
                      Listenable.merge([widget.frame, _aim]),
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0, -0.78),
              child: SafeArea(
                child: ListenableBuilder(
                  listenable: widget.frame,
                  builder: (context, _) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GameMeter(
                        label: l10n.gameCarromClock,
                        value: game.timeLeft / CarromGame.startTime,
                        color: game.timeLeft < 10
                            ? const Color(0xFFFF5252)
                            : const Color(0xFF66BB6A),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.gameCarromSeconds(game.timeLeft.ceil()),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ListenableBuilder(
              listenable: widget.frame,
              builder: (context, _) => game.isOver
                  ? const SizedBox.shrink()
                  : GameBanner(
                      text: l10n.gameCarromFoul,
                      color: const Color(0xFFFF6B6B),
                      age: game.sinceFoul,
                      hold: 1.2,
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _CarromPainter extends CustomPainter {
  _CarromPainter(this.game, this.aim, Listenable repaint)
    : super(repaint: repaint);

  final CarromGame game;
  final ValueNotifier<_Aim?> aim;

  @override
  void paint(Canvas canvas, Size size) {
    final board = _boardRect(size);
    final unit = board.width;
    Offset at(double x, double y) =>
        Offset(board.left + x * unit, board.top + y * unit);

    canvas
      ..drawRect(Offset.zero & size, Paint()..color = const Color(0xFF263238))
      // The frame, then the playing surface.
      ..drawRRect(
        RRect.fromRectAndRadius(
          board.inflate(unit * 0.045),
          Radius.circular(unit * 0.05),
        ),
        Paint()..color = const Color(0xFF4E342E),
      )
      ..drawRect(board, Paint()..color = const Color(0xFFE9C98B));

    final line = Paint()
      ..color = const Color(0xFF6D4C41)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas
      ..drawCircle(at(0.5, 0.5), unit * 0.13, line)
      ..drawCircle(at(0.5, 0.5), unit * 0.03, line);
    // Baselines on all four sides, as on a real board.
    for (final (a, b) in [
      (at(0.2, 0.84), at(0.8, 0.84)),
      (at(0.2, 0.16), at(0.8, 0.16)),
      (at(0.16, 0.2), at(0.16, 0.8)),
      (at(0.84, 0.2), at(0.84, 0.8)),
    ]) {
      canvas.drawLine(a, b, line);
    }
    final pocket = Paint()..color = const Color(0xFF1B1B1B);
    for (final x in const [0.0, 1.0]) {
      for (final y in const [0.0, 1.0]) {
        canvas.drawCircle(
          at(x == 0 ? 0.045 : 0.955, y == 0 ? 0.045 : 0.955),
          unit * 0.058,
          pocket,
        );
      }
    }

    void disc(CarromDisc disc, Color fill, Color rim) {
      final centre = at(disc.x, disc.y);
      final radius = disc.radius * unit;
      canvas
        ..drawCircle(
          centre + const Offset(1.5, 2),
          radius,
          Paint()..color = const Color(0x40000000),
        )
        ..drawCircle(centre, radius, Paint()..color = fill)
        ..drawCircle(
          centre,
          radius * 0.62,
          Paint()
            ..color = rim
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
    }

    for (final coin in game.coins) {
      switch (coin.piece) {
        case CarromPiece.black:
          disc(coin, const Color(0xFF2B2B2B), const Color(0xFF616161));
        case CarromPiece.white:
          disc(coin, const Color(0xFFFFF8E1), const Color(0xFFBCAAA4));
        case CarromPiece.queen:
          disc(coin, const Color(0xFFD32F2F), const Color(0xFFFFCDD2));
        case CarromPiece.striker:
          break;
      }
    }

    final striker = game.striker;
    final lined = aim.value;
    if (lined != null && !game.isMoving) {
      // Dots along the shot, longer for a harder one.
      final from = at(striker.x, striker.y);
      final reach = unit * (0.12 + 0.45 * lined.power);
      final dot = Paint()..color = const Color(0xFFFFFFFF);
      for (var i = 1; i <= 8; i++) {
        canvas.drawCircle(
          from + Offset(lined.dx, lined.dy) * (reach * i / 8),
          3,
          dot,
        );
      }
    }
    disc(striker, const Color(0xFF1E88E5), const Color(0xFFBBDEFB));
  }

  @override
  bool shouldRepaint(_CarromPainter oldDelegate) => oldDelegate.game != game;
}
