import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/arcade_game.dart';
import '../domain/lane_runner_game.dart';
import 'game_shell.dart';

class LaneRunnerScreen extends StatelessWidget {
  const LaneRunnerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GameShell<LaneRunnerGame>(
      gameId: GameId.laneRunner,
      title: l10n.gameDashTitle,
      howTo: l10n.gameDashHowTo,
      create: (random) => LaneRunnerGame(random: random),
      playfield: (context, game, frame) => CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowLeft): game.moveLeft,
          const SingleActivator(LogicalKeyboardKey.arrowRight): game.moveRight,
        },
        child: Focus(
          autofocus: true,
          child: LayoutBuilder(
            builder: (context, constraints) => Listener(
              key: const Key('dashField'),
              behavior: HitTestBehavior.opaque,
              // Touch the side you want to dodge to.
              onPointerDown: (event) =>
                  event.localPosition.dx < constraints.maxWidth / 2
                  ? game.moveLeft()
                  : game.moveRight(),
              child: RepaintBoundary(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _DashPainter(game, frame),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The gully from straight above: 2D, scrolling towards the runner.
class _DashPainter extends CustomPainter {
  _DashPainter(this.game, Listenable frame) : super(repaint: frame);

  static const _road = Color(0xFF8D8478);
  static const _roadEdge = Color(0xFF6F675D);
  static const _houses = [
    Color(0xFFE9C46A),
    Color(0xFFE8A0A0),
    Color(0xFF8EC6C5),
    Color(0xFFF1E3C4),
    Color(0xFF9DB7E0),
    Color(0xFFD9A77A),
  ];

  final LaneRunnerGame game;

  @override
  void paint(Canvas canvas, Size size) {
    // The lane is at most a phone wide, centred on bigger screens.
    final width = math.min(size.width, 520.0);
    final left = (size.width - width) / 2;
    final wall = width * 0.1;
    final lane = (width - wall * 2) / LaneRunnerGame.lanes;
    final playerY = size.height * 0.8;
    final scale = playerY / LaneRunnerGame.viewAhead;
    double laneX(double index) => left + wall + lane * (index + 0.5);
    double ahead(double metres) => playerY - metres * scale;

    canvas
      ..drawRect(Offset.zero & size, Paint()..color = const Color(0xFF3B352E))
      ..drawRect(
        Rect.fromLTWH(left + wall, 0, width - wall * 2, size.height),
        Paint()..color = _road,
      );

    // Houses slide by on both sides, six metres to a house.
    const house = 6.0;
    final firstHouse = (game.distance / house).floor() - 2;
    for (var i = firstHouse; i < firstHouse + 9; i++) {
      final top = ahead((i + 1) * house - game.distance);
      final height = house * scale;
      for (final side in const [0, 1]) {
        final x = side == 0 ? left : left + width - wall;
        final color = _houses[(i * 2 + side * 3) % _houses.length];
        canvas
          ..drawRect(
            Rect.fromLTWH(x, top, wall, height - 2),
            Paint()..color = color,
          )
          ..drawRect(
            Rect.fromLTWH(
              side == 0 ? x + wall - 5 : x,
              top + height * 0.35,
              5,
              height * 0.3,
            ),
            Paint()..color = Color.lerp(color, Colors.black, 0.6)!,
          );
      }
    }
    final edge = Paint()..color = _roadEdge;
    canvas
      ..drawRect(Rect.fromLTWH(left + wall, 0, 3, size.height), edge)
      ..drawRect(
        Rect.fromLTWH(left + width - wall - 3, 0, 3, size.height),
        edge,
      );

    // Chalk dashes between the lanes.
    const dash = 4.0;
    final dashPaint = Paint()..color = const Color(0x99FFFFFF);
    final firstDash = (game.distance / dash).floor() - 2;
    for (var i = firstDash; i < firstDash + 12; i++) {
      final y = ahead(i * dash - game.distance);
      for (var line = 1; line < LaneRunnerGame.lanes; line++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(left + wall + lane * line, y),
              width: 4,
              height: dash * scale * 0.45,
            ),
            const Radius.circular(2),
          ),
          dashPaint,
        );
      }
    }

    for (final item in game.items) {
      final centre = Offset(laneX(item.lane.toDouble()), ahead(item.y));
      switch (item.kind) {
        case LaneItemKind.pothole:
          _pothole(canvas, centre, lane);
        case LaneItemKind.crate:
          _crate(canvas, centre, lane);
        case LaneItemKind.scooter:
          _scooter(canvas, centre, lane);
        case LaneItemKind.cow:
          _cow(canvas, centre, lane);
        case LaneItemKind.ball:
          _ball(canvas, centre, lane);
      }
    }

    // Blink while shielded after a bump.
    final blink = game.isShielded && (game.distance * 2).floor().isOdd;
    if (!blink) _runner(canvas, Offset(laneX(game.playerX), playerY), lane);
  }

  void _shadow(Canvas canvas, Offset centre, double width, double height) {
    canvas.drawOval(
      Rect.fromCenter(
        center: centre + const Offset(3, 4),
        width: width,
        height: height,
      ),
      Paint()..color = const Color(0x40000000),
    );
  }

  void _pothole(Canvas canvas, Offset centre, double lane) {
    final rect = Rect.fromCenter(
      center: centre,
      width: lane * 0.72,
      height: lane * 0.5,
    );
    canvas
      ..drawOval(rect.inflate(4), Paint()..color = const Color(0xFF6F675D))
      ..drawOval(rect, Paint()..color = const Color(0xFF2E2A26))
      ..drawOval(
        rect.deflate(lane * 0.12).shift(const Offset(2, 3)),
        Paint()..color = const Color(0xFF1B1917),
      );
  }

  void _crate(Canvas canvas, Offset centre, double lane) {
    final rect = Rect.fromCenter(
      center: centre,
      width: lane * 0.62,
      height: lane * 0.62,
    );
    _shadow(canvas, centre, lane * 0.7, lane * 0.7);
    final plank = Paint()
      ..color = const Color(0xFF7A5230)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas
      ..drawRect(rect, Paint()..color = const Color(0xFFB98652))
      ..drawRect(rect, plank)
      ..drawLine(rect.topLeft, rect.bottomRight, plank)
      ..drawLine(rect.topRight, rect.bottomLeft, plank);
  }

  void _scooter(Canvas canvas, Offset centre, double lane) {
    final length = lane * 0.95;
    _shadow(canvas, centre, lane * 0.5, length);
    final tyre = Paint()..color = const Color(0xFF212121);
    for (final end in const [-1, 1]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: centre + Offset(0, end * length * 0.42),
            width: lane * 0.12,
            height: length * 0.22,
          ),
          const Radius.circular(4),
        ),
        tyre,
      );
    }
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: centre,
            width: lane * 0.3,
            height: length * 0.7,
          ),
          Radius.circular(lane * 0.14),
        ),
        Paint()..color = const Color(0xFF00897B),
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: centre + Offset(0, length * 0.12),
            width: lane * 0.22,
            height: length * 0.32,
          ),
          const Radius.circular(6),
        ),
        Paint()..color = const Color(0xFF263238),
      )
      ..drawLine(
        centre + Offset(-lane * 0.26, -length * 0.3),
        centre + Offset(lane * 0.26, -length * 0.3),
        Paint()
          ..color = const Color(0xFF37474F)
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
  }

  void _cow(Canvas canvas, Offset centre, double lane) {
    _shadow(canvas, centre, lane * 0.62, lane * 1.05);
    final body = Rect.fromCenter(
      center: centre + Offset(0, lane * 0.08),
      width: lane * 0.5,
      height: lane * 0.82,
    );
    final head = centre + Offset(0, -lane * 0.44);
    final horn = Paint()
      ..color = const Color(0xFFD7CCC8)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const patch = Color(0xFF5D4037);
    canvas
      ..drawOval(body, Paint()..color = const Color(0xFFF5F0E6))
      ..drawOval(
        Rect.fromCenter(
          center: body.center + Offset(-lane * 0.08, -lane * 0.1),
          width: lane * 0.22,
          height: lane * 0.26,
        ),
        Paint()..color = patch,
      )
      ..drawOval(
        Rect.fromCenter(
          center: body.center + Offset(lane * 0.1, lane * 0.18),
          width: lane * 0.18,
          height: lane * 0.22,
        ),
        Paint()..color = patch,
      )
      ..drawLine(
        head + Offset(-lane * 0.1, -lane * 0.04),
        head + Offset(-lane * 0.2, -lane * 0.14),
        horn,
      )
      ..drawLine(
        head + Offset(lane * 0.1, -lane * 0.04),
        head + Offset(lane * 0.2, -lane * 0.14),
        horn,
      )
      ..drawOval(
        Rect.fromCenter(center: head, width: lane * 0.26, height: lane * 0.3),
        Paint()..color = const Color(0xFFEDE3D3),
      );
  }

  void _ball(Canvas canvas, Offset centre, double lane) {
    final radius = lane * 0.14;
    canvas
      ..drawCircle(
        centre,
        radius * 1.9,
        Paint()..color = const Color(0x33FFEB3B),
      )
      ..drawCircle(centre, radius, Paint()..color = const Color(0xFFC62828))
      ..drawArc(
        Rect.fromCircle(center: centre, radius: radius * 0.7),
        -0.6,
        1.2,
        false,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
  }

  void _runner(Canvas canvas, Offset centre, double lane) {
    final stride = math.sin(game.distance * 2.4);
    _shadow(canvas, centre, lane * 0.5, lane * 0.6);
    final leg = Paint()..color = const Color(0xFFF3F0E6);
    for (final side in const [-1, 1]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center:
                centre +
                Offset(
                  side * lane * 0.09,
                  lane * 0.1 + side * stride * lane * 0.14,
                ),
            width: lane * 0.11,
            height: lane * 0.26,
          ),
          const Radius.circular(4),
        ),
        leg,
      );
    }
    canvas
      // The bat, carried over the shoulder.
      ..drawLine(
        centre + Offset(lane * 0.2, lane * 0.02),
        centre + Offset(lane * 0.3, -lane * 0.42),
        Paint()
          ..color = const Color(0xFFE2C48A)
          ..strokeWidth = lane * 0.09
          ..strokeCap = StrokeCap.round,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: centre,
            width: lane * 0.42,
            height: lane * 0.26,
          ),
          Radius.circular(lane * 0.1),
        ),
        Paint()..color = const Color(0xFF1E88E5),
      )
      ..drawCircle(
        centre + Offset(0, -lane * 0.03),
        lane * 0.12,
        Paint()..color = const Color(0xFF2B2320),
      );
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) => oldDelegate.game != game;
}
