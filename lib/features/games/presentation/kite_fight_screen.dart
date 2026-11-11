import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/arcade_game.dart';
import '../domain/kite_fight_game.dart';
import 'game_shell.dart';

class KiteFightScreen extends StatelessWidget {
  const KiteFightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GameShell<KiteFightGame>(
      gameId: GameId.kiteFight,
      title: l10n.gameKiteTitle,
      howTo: l10n.gameKiteHowTo,
      create: (random) => KiteFightGame(random: random),
      playfield: (context, game, frame) => LayoutBuilder(
        builder: (context, constraints) {
          final sky = _Sky(constraints.biggest);
          void flyTo(Offset position) {
            final point = sky.toSky(position);
            game.flyTo(point.x, point.y);
          }

          return Listener(
            key: const Key('kiteField'),
            behavior: HitTestBehavior.opaque,
            onPointerDown: (event) => flyTo(event.localPosition),
            onPointerMove: (event) => flyTo(event.localPosition),
            child: RepaintBoundary(
              child: CustomPaint(
                size: Size.infinite,
                painter: _KitePainter(game, frame),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Maps between the game's sky and the screen.
final class _Sky {
  const _Sky(this.size);

  final Size size;

  /// Where the rooftops are, as a height on screen.
  double get _ground => size.height * 0.9;
  double get _rise => size.height * 0.82;

  Offset toScreen(SkyPoint point) => Offset(
    point.x * size.width,
    _ground - point.y / KiteFightGame.skyHeight * _rise,
  );

  SkyPoint toSky(Offset position) => (
    x: position.dx / size.width,
    y: (_ground - position.dy) / _rise * KiteFightGame.skyHeight,
  );
}

class _KitePainter extends CustomPainter {
  _KitePainter(this.game, Listenable frame) : super(repaint: frame);

  static const _rivalColors = [
    Color(0xFFE53935),
    Color(0xFF8E24AA),
    Color(0xFF43A047),
    Color(0xFFFB8C00),
  ];

  final KiteFightGame game;

  @override
  void paint(Canvas canvas, Size size) {
    final sky = _Sky(size);
    final all = Offset.zero & size;
    canvas.drawRect(
      all,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3F8FD8), Color(0xFFBDE3F5), Color(0xFFFFE0B2)],
          stops: [0, 0.7, 1],
        ).createShader(all),
    );
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.16),
      size.width * 0.09,
      Paint()..color = const Color(0xFFFFF59D),
    );
    final cloud = Paint()..color = const Color(0xCCFFFFFF);
    for (final (x, y, scale) in const [
      (0.2, 0.22, 1.0),
      (0.65, 0.38, 0.8),
      (0.35, 0.55, 0.65),
    ]) {
      final at = Offset(size.width * x, size.height * y);
      final r = size.width * 0.07 * scale;
      canvas
        ..drawCircle(at, r, cloud)
        ..drawCircle(at + Offset(r * 1.1, r * 0.2), r * 0.8, cloud)
        ..drawCircle(at - Offset(r * 1.1, -r * 0.25), r * 0.7, cloud);
    }

    // Rooftops along the bottom, where the strings are held.
    final roofs = Paint()..color = const Color(0xFF5D4037);
    final ground = size.height * 0.9;
    final random = math.Random(4);
    var x = 0.0;
    while (x < size.width) {
      final width = size.width * (0.12 + random.nextDouble() * 0.1);
      final rise = size.height * random.nextDouble() * 0.05;
      canvas.drawRect(
        Rect.fromLTRB(x, ground - rise, x + width - 2, size.height),
        roofs
          ..color = Color.lerp(
            const Color(0xFF6D4C41),
            const Color(0xFF8D6E63),
            random.nextDouble(),
          )!,
      );
      x += width;
    }

    for (final rival in game.rivals) {
      final cut = rival.state == RivalState.cut;
      final at = sky.toScreen(rival.position);
      final wobble = rival.state == RivalState.windUp
          ? math.sin(rival.stateTime * 40) * 0.35
          : cut
          ? rival.stateTime * 5
          : rival.velocity.x * 0.25;
      if (!cut) {
        _string(
          canvas,
          sky.toScreen(rival.anchor),
          at,
          const Color(0xCCFFFFFF),
        );
      }
      _kite(
        canvas,
        at,
        size.width * 0.075,
        _rivalColors[rival.color],
        wobble,
        warning: rival.state == RivalState.windUp,
      );
    }

    final mine = sky.toScreen(game.kite);
    if (!game.isDown) {
      _string(
        canvas,
        sky.toScreen(KiteFightGame.anchor),
        mine,
        const Color(0xFFFFF176),
        width: 2,
      );
    }
    if (game.isSafe && !game.isDown) {
      canvas.drawCircle(
        mine,
        size.width * 0.1,
        Paint()..color = const Color(0x55FFFFFF),
      );
    }
    _kite(
      canvas,
      mine,
      size.width * 0.085,
      const Color(0xFF1E88E5),
      game.isDown ? game.kite.y * 9 : game.velocity.x * 0.2,
    );
  }

  void _string(
    Canvas canvas,
    Offset from,
    Offset to,
    Color color, {
    double width = 1.2,
  }) {
    canvas.drawLine(
      from,
      to,
      Paint()
        ..color = color
        ..strokeWidth = width,
    );
  }

  void _kite(
    Canvas canvas,
    Offset at,
    double size,
    Color color,
    double tilt, {
    bool warning = false,
  }) {
    canvas
      ..save()
      ..translate(at.dx, at.dy)
      ..rotate(tilt);
    final diamond = Path()
      ..moveTo(0, -size)
      ..lineTo(size * 0.8, 0)
      ..lineTo(0, size * 1.15)
      ..lineTo(-size * 0.8, 0)
      ..close();
    final spar = Paint()
      ..color = const Color(0xFF3E2723)
      ..strokeWidth = 1.5;
    final tail = Path()
      ..moveTo(0, size * 1.15)
      ..quadraticBezierTo(size * 0.5, size * 1.6, 0, size * 2)
      ..quadraticBezierTo(-size * 0.5, size * 2.4, 0, size * 2.8);
    canvas
      ..drawPath(
        tail,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      )
      ..drawPath(diamond, Paint()..color = color)
      ..drawPath(
        Path()
          ..moveTo(0, -size)
          ..lineTo(size * 0.8, 0)
          ..lineTo(0, 0)
          ..close(),
        Paint()..color = const Color(0x33FFFFFF),
      )
      ..drawLine(Offset(0, -size), Offset(0, size * 1.15), spar)
      ..drawLine(Offset(-size * 0.8, 0), Offset(size * 0.8, 0), spar);
    if (warning) {
      canvas.drawPath(
        diamond,
        Paint()
          ..color = const Color(0xFFFFEB3B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_KitePainter oldDelegate) => oldDelegate.game != game;
}
