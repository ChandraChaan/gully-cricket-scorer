/// The mini games in the app. [key] is used in routes and storage.
enum GameId {
  batting('batting'),
  catching('catching'),
  directHit('direct-hit'),
  laneRunner('gully-dash'),
  duel('akhada-duel'),
  kabaddi('kabaddi-raid'),
  gilliDanda('gilli-danda'),
  kiteFight('kite-fight'),
  carrom('carrom-strike');

  const GameId(this.key);

  final String key;

  static GameId? fromKey(String key) {
    for (final id in values) {
      if (id.key == key) return id;
    }
    return null;
  }
}

/// What every mini game exposes to the shared game screen.
///
/// Games are plain Dart: the screen calls [update] once a frame and draws
/// whatever state it finds afterwards.
abstract interface class ArcadeGame {
  int get score;

  /// Wickets, drops or bumps the player can still afford.
  int get lives;

  bool get isOver;

  /// Moves the game on by [dt] seconds.
  void update(double dt);
}

/// Metres per second squared.
const gravity = 9.81;

/// The longest physics step a game takes. Longer frames are split up so a
/// fast ball can't tunnel through the stumps.
const maxStep = 1 / 120;
