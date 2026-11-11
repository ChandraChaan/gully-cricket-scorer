import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/arcade_game.dart';
import 'best_scores_controller.dart';

enum _Status { ready, playing, paused, over }

/// The screen every mini game runs in.
///
/// It owns the game loop and the chrome around the game: how-to-play card,
/// score, lives, pause and the game-over card with the best score. The game
/// itself only has to draw [playfield] and feed touches to its [ArcadeGame].
class GameShell<G extends ArcadeGame> extends ConsumerStatefulWidget {
  const GameShell({
    required this.gameId,
    required this.title,
    required this.howTo,
    required this.create,
    required this.playfield,
    super.key,
  });

  final GameId gameId;
  final String title;
  final String howTo;

  /// Makes a fresh game for each attempt.
  final G Function(math.Random random) create;

  /// Draws the game. [frame] fires after every update.
  final Widget Function(BuildContext context, G game, Listenable frame)
  playfield;

  @override
  ConsumerState<GameShell<G>> createState() => _GameShellState<G>();
}

class _GameShellState<G extends ArcadeGame> extends ConsumerState<GameShell<G>>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late G _game = _newGame();
  late final Ticker _ticker;
  final _frame = ValueNotifier<int>(0);
  Duration _last = Duration.zero;
  _Status _status = _Status.ready;
  bool _newBest = false;

  G _newGame() => widget.create(ref.read(gameRandomProvider));

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _pause();
  }

  void _onTick(Duration elapsed) {
    // A long frame (or coming back from a pause) must not fling the game on.
    final dt = math.min((elapsed - _last).inMicroseconds / 1e6, 0.05);
    _last = elapsed;
    _game.update(dt);
    _frame.value++;
    if (_game.isOver) _finish();
  }

  void _run() {
    _last = Duration.zero;
    _ticker
      ..stop()
      ..start();
  }

  void _start() {
    setState(() {
      _game = _newGame();
      _status = _Status.playing;
      _newBest = false;
    });
    _run();
  }

  void _pause() {
    if (_status != _Status.playing) return;
    _ticker.stop();
    setState(() => _status = _Status.paused);
  }

  void _resume() {
    setState(() => _status = _Status.playing);
    _run();
  }

  void _finish() {
    _ticker.stop();
    setState(() => _status = _Status.over);
    unawaited(_recordScore(_game.score));
  }

  Future<void> _recordScore(int score) async {
    final isBest = await ref
        .read(bestScoresProvider.notifier)
        .submit(widget.gameId, score);
    if (isBest && mounted) setState(() => _newBest = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final best = ref.watch(bestScoresProvider).value?[widget.gameId] ?? 0;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        // The playfield fills the screen whatever else is showing.
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              ignoring: _status != _Status.playing,
              child: Semantics(
                label: widget.title,
                // The 3D ground runs far past the edges of the screen.
                child: ClipRect(
                  child: widget.playfield(context, _game, _frame),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RoundButton(
                    tooltip: l10n.gamesBack,
                    icon: Icons.arrow_back,
                    onPressed: () => context.go('/'),
                  ),
                  const SizedBox(width: 8),
                  ListenableBuilder(
                    listenable: _frame,
                    builder: (context, _) => _Hud(
                      score: _game.score,
                      lives: _game.lives,
                      livesLabel: l10n.gameLives(_game.lives),
                    ),
                  ),
                  const Spacer(),
                  if (_status == _Status.playing)
                    _RoundButton(
                      key: const Key('pauseGame'),
                      tooltip: l10n.gamePause,
                      icon: Icons.pause,
                      onPressed: _pause,
                    ),
                ],
              ),
            ),
          ),
          switch (_status) {
            _Status.playing => const SizedBox.shrink(),
            _Status.ready => _Card(
              title: widget.title,
              body: widget.howTo,
              footnote: best > 0 ? l10n.gameBest(best) : null,
              action: FilledButton.icon(
                key: const Key('startGame'),
                onPressed: _start,
                icon: const Icon(Icons.play_arrow),
                label: Text(l10n.gameStart),
              ),
            ),
            _Status.paused => _Card(
              title: l10n.gamePaused,
              body: widget.howTo,
              action: FilledButton.icon(
                key: const Key('resumeGame'),
                onPressed: _resume,
                icon: const Icon(Icons.play_arrow),
                label: Text(l10n.gameResume),
              ),
            ),
            _Status.over => _Card(
              title: l10n.gameOver,
              headline: l10n.gameScore(_game.score),
              body: _newBest ? l10n.gameNewBest : l10n.gameBest(best),
              highlight: _newBest,
              action: FilledButton.icon(
                key: const Key('playAgain'),
                onPressed: _start,
                icon: const Icon(Icons.replay),
                label: Text(l10n.gamePlayAgain),
              ),
              secondary: TextButton(
                onPressed: () => context.go('/'),
                child: Text(l10n.gamesBack),
              ),
            ),
          },
        ],
      ),
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({
    required this.score,
    required this.lives,
    required this.livesLabel,
  });

  final int score;
  final int lives;
  final String livesLabel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$score',
              key: const Key('gameScore'),
              style: text.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 12),
            Semantics(
              label: livesLabel,
              child: ExcludeSemantics(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Icon(
                        i < lives ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: i < lives
                            ? const Color(0xFFFF6B6B)
                            : Colors.white54,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.55),
        foregroundColor: Colors.white,
      ),
      icon: Icon(icon),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.body,
    required this.action,
    this.headline,
    this.footnote,
    this.secondary,
    this.highlight = false,
  });

  final String title;
  final String? headline;
  final String body;
  final String? footnote;
  final Widget action;
  final Widget? secondary;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: text.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    if (headline case final headline?) ...[
                      const SizedBox(height: 8),
                      Text(
                        headline,
                        key: const Key('finalScore'),
                        style: text.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      body,
                      textAlign: TextAlign.center,
                      style: highlight
                          ? text.titleMedium?.copyWith(
                              color: theme.colorScheme.tertiary,
                              fontWeight: FontWeight.w700,
                            )
                          : text.bodyMedium,
                    ),
                    if (footnote case final footnote?) ...[
                      const SizedBox(height: 8),
                      Text(footnote, style: text.labelLarge),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(width: double.infinity, child: action),
                    ?secondary,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A big word that flashes over the game: "SIX!", "Dropped", "Run out!".
class GameBanner extends StatelessWidget {
  const GameBanner({
    required this.text,
    required this.age,
    this.color = Colors.white,
    this.hold = 1.0,
    super.key,
  });

  final String text;

  /// Seconds since the thing it announces happened.
  final double age;
  final Color color;

  /// Seconds the banner stays up.
  final double hold;

  @override
  Widget build(BuildContext context) {
    if (age >= hold) return const SizedBox.shrink();
    final pop = Curves.easeOutBack.transform((age / 0.18).clamp(0, 1));
    final fade = (1 - (age - hold + 0.25) / 0.25).clamp(0.0, 1.0);
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, -0.45),
        child: Opacity(
          opacity: fade,
          child: Transform.scale(
            scale: 0.6 + 0.4 * pop,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
                shadows: const [
                  Shadow(blurRadius: 12),
                  Shadow(offset: Offset(0, 3), blurRadius: 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A slim bar across the top of a game: time left, a runner's progress,
/// a fighter's health.
class GameMeter extends StatelessWidget {
  const GameMeter({
    required this.label,
    required this.value,
    required this.color,
    this.width = 180,
    super.key,
  });

  /// What the bar measures, for screen readers.
  final String label;

  /// From 0 (empty) to 1 (full).
  final double value;
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    final share = value.clamp(0.0, 1.0);
    return Semantics(
      label: label,
      value: '${(share * 100).round()}%',
      child: SizedBox(
        width: width,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: share,
            backgroundColor: Colors.black45,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// A round on-screen button for games. [onDown] fires the moment a finger
/// lands; [onUp] when it lifts, for buttons that are held.
class GamePadButton extends StatelessWidget {
  const GamePadButton({
    required this.label,
    required this.icon,
    required this.onDown,
    this.onUp,
    this.size = 60,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback onDown;
  final VoidCallback? onUp;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      onTap: () {
        onDown();
        onUp?.call();
      },
      child: Listener(
        onPointerDown: (_) => onDown(),
        onPointerUp: (_) => onUp?.call(),
        onPointerCancel: (_) => onUp?.call(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.primaryContainer.withValues(alpha: 0.92),
            border: Border.all(color: colors.primary, width: 2),
          ),
          child: ExcludeSemantics(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: colors.onPrimaryContainer),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
