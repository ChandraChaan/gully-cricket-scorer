import 'dart:math' as math;

import 'arcade_game.dart';

enum FighterMove { idle, punch, kick, block, hurt, down }

/// How an attack unfolds: wind up, a moment where it can land, then recover.
final class Attack {
  const Attack({
    required this.startup,
    required this.active,
    required this.recovery,
    required this.range,
    required this.damage,
  });

  static const punch = Attack(
    startup: 0.1,
    active: 0.1,
    recovery: 0.18,
    range: 1.15,
    damage: 8,
  );
  static const kick = Attack(
    startup: 0.2,
    active: 0.12,
    recovery: 0.3,
    range: 1.55,
    damage: 14,
  );

  final double startup;
  final double active;
  final double recovery;

  /// How far away the other fighter can be and still get hit.
  final double range;
  final double damage;

  double get total => startup + active + recovery;
}

/// One wrestler in the pit.
final class Fighter {
  Fighter(this.x, this.facing, this.maxHealth) : health = maxHealth;

  /// Where they stand along the pit, in metres from the middle.
  double x;

  /// 1 when facing right, -1 when facing left.
  int facing;
  final double maxHealth;
  double health;
  FighterMove move = FighterMove.idle;

  /// Seconds spent in the current [move].
  double moveTime = 0;

  /// Metres walked, to drive the walking animation.
  double walked = 0;

  bool _landed = false;

  Attack? get attack => switch (move) {
    FighterMove.punch => Attack.punch,
    FighterMove.kick => Attack.kick,
    _ => null,
  };

  bool get _canAct => move == FighterMove.idle || move == FighterMove.block;

  void _start(FighterMove next) {
    move = next;
    moveTime = 0;
    _landed = false;
  }
}

/// Akhada Duel: one-on-one bouts in a mud wrestling pit.
///
/// Punches are quick and short, kicks slower and longer, and a held block
/// soaks up most of a hit. Each opponent beaten brings a tougher one; being
/// knocked down three times ends the game. The score is damage dealt plus a
/// bonus for every knockout.
final class DuelGame implements ArcadeGame {
  DuelGame({math.Random? random, this.opponentFights = true})
    : _random = random ?? math.Random() {
    _opponent = _newOpponent();
  }

  static const knockdowns = 3;
  static const pitHalfWidth = 3.2;
  static const minGap = 0.75;
  static const walkSpeed = 2.8;
  static const hurtTime = 0.28;
  static const blockedShare = 0.15;
  static const knockoutBonus = 50;
  static const _startX = 1.2;

  final math.Random _random;

  /// False turns the opponent into a punch bag that never moves or hits
  /// back. Used for practice and tests.
  final bool opponentFights;

  final Fighter _player = Fighter(-_startX, 1, 100);
  late Fighter _opponent;
  int _opponentNumber = 1;
  int _score = 0;
  int _lives = knockdowns;
  double _pause = 0;
  bool _over = false;
  double _thinkIn = 0.6;
  double _blockFor = 0;
  int _walkIntent = 0;
  bool _reacted = false;

  /// -1 to walk left, 1 to walk right, 0 to stand.
  double moveInput = 0;

  /// Whether the player is holding block.
  bool blockHeld = false;

  Fighter get player => _player;
  Fighter get opponent => _opponent;

  /// 1 for the first opponent, 2 for the next and so on.
  int get opponentNumber => _opponentNumber;

  /// True in the pause after a knockdown.
  bool get isBetweenBouts => _pause > 0;

  @override
  int get score => _score;

  @override
  int get lives => _lives;

  @override
  bool get isOver => _over;

  int get _level => _opponentNumber - 1;

  void punch() => _attack(FighterMove.punch);

  void kick() => _attack(FighterMove.kick);

  void _attack(FighterMove move) {
    if (_over || _pause > 0 || !_player._canAct) return;
    _player._start(move);
    _reacted = false;
  }

  Fighter _newOpponent() =>
      Fighter(_startX, -1, math.min(120, 60 + 10.0 * _level));

  @override
  void update(double dt) {
    var left = dt;
    while (left > 0 && !_over) {
      final step = math.min(left, maxStep);
      _step(step);
      left -= step;
    }
  }

  void _step(double dt) {
    _player.moveTime += dt;
    _opponent.moveTime += dt;
    if (_pause > 0) {
      _pause -= dt;
      if (_pause <= 0) _nextBout();
      return;
    }

    if (_player._canAct) {
      _player.move = blockHeld ? FighterMove.block : FighterMove.idle;
      if (!blockHeld) _walk(_player, moveInput.clamp(-1, 1) * walkSpeed * dt);
    }
    if (opponentFights) _think(dt);
    _resolve(_player, _opponent, 1);
    _resolve(_opponent, _player, math.min(1.3, 0.6 + 0.08 * _level));

    // Keep them in the pit, apart, and facing each other.
    _player.x = _player.x.clamp(-pitHalfWidth, pitHalfWidth - minGap);
    _opponent.x = _opponent.x.clamp(-pitHalfWidth + minGap, pitHalfWidth);
    final overlap = minGap - (_opponent.x - _player.x);
    if (overlap > 0) {
      _player.x -= overlap / 2;
      _opponent.x += overlap / 2;
      if (_player.x < -pitHalfWidth) {
        _player.x = -pitHalfWidth;
        _opponent.x = _player.x + minGap;
      }
      if (_opponent.x > pitHalfWidth) {
        _opponent.x = pitHalfWidth;
        _player.x = _opponent.x - minGap;
      }
    }
  }

  void _walk(Fighter fighter, double distance) {
    fighter.x += distance;
    fighter.walked += distance.abs();
  }

  /// Moves [fighter]'s attack or stagger on and lands the hit if it reaches.
  void _resolve(Fighter fighter, Fighter other, double strength) {
    final attack = fighter.attack;
    if (attack != null) {
      final time = fighter.moveTime;
      final live =
          time >= attack.startup && time <= attack.startup + attack.active;
      if (live &&
          !fighter._landed &&
          (other.x - fighter.x).abs() <= attack.range) {
        fighter._landed = true;
        _hit(fighter, other, attack.damage * strength);
      }
      if (time >= attack.total) fighter._start(FighterMove.idle);
    } else if (fighter.move == FighterMove.hurt &&
        fighter.moveTime >= hurtTime) {
      fighter._start(FighterMove.idle);
    }
  }

  void _hit(Fighter attacker, Fighter defender, double damage) {
    if (defender.move == FighterMove.down) return;
    final blocked = defender.move == FighterMove.block;
    final dealt = blocked ? damage * blockedShare : damage;
    // A blocked hit can wear you down but never finish you.
    final floor = blocked ? 1.0 : 0.0;
    final before = defender.health;
    defender.health = math.max(floor, defender.health - dealt);
    defender.x += attacker.facing * (blocked ? 0.15 : 0.45);
    if (identical(attacker, _player)) {
      _score += (before - defender.health).round();
    }
    if (blocked) return;
    if (defender.health <= 0) {
      defender._start(FighterMove.down);
      _pause = 1.6;
      if (identical(defender, _opponent)) {
        _score += knockoutBonus;
      } else {
        _lives--;
      }
    } else {
      defender._start(FighterMove.hurt);
    }
  }

  void _nextBout() {
    _pause = 0;
    if (_player.move == FighterMove.down) {
      if (_lives == 0) {
        _over = true;
        return;
      }
      _player.health = _player.maxHealth;
    } else {
      _opponentNumber++;
      _opponent = _newOpponent();
      _player.health = math.min(_player.maxHealth, _player.health + 35);
    }
    _player
      ..x = -_startX
      .._start(FighterMove.idle);
    _opponent
      ..x = _startX
      .._start(FighterMove.idle);
    _thinkIn = 0.6;
    _blockFor = 0;
    _walkIntent = 0;
  }

  /// The opponent's brain. Later opponents think faster, attack more and
  /// read the player's wind-up more often.
  void _think(double dt) {
    final foe = _opponent;
    if (!foe._canAct) return;
    final gap = (foe.x - _player.x).abs();

    // See a punch or kick coming and maybe get the guard up.
    final incoming = _player.attack;
    if (incoming != null && !_reacted && gap <= incoming.range + 0.3) {
      _reacted = true;
      if (_random.nextDouble() < math.min(0.75, 0.1 + 0.09 * _level)) {
        _blockFor = 0.45;
      }
    }
    if (_blockFor > 0) {
      _blockFor -= dt;
      foe.move = FighterMove.block;
      return;
    }
    foe.move = FighterMove.idle;

    _thinkIn -= dt;
    if (_thinkIn <= 0) {
      _thinkIn =
          math.max(0.16, 0.5 - 0.05 * _level) *
          (0.7 + 0.6 * _random.nextDouble());
      final keen = math.min(0.9, 0.45 + 0.07 * _level);
      final roll = _random.nextDouble();
      _walkIntent = 0;
      if (gap > Attack.kick.range - 0.1) {
        _walkIntent = foe.facing;
      } else if (gap > Attack.punch.range - 0.1) {
        if (roll < keen * 0.7) {
          foe._start(FighterMove.kick);
        } else {
          _walkIntent = foe.facing;
        }
      } else if (roll < keen) {
        foe._start(roll < keen * 0.65 ? FighterMove.punch : FighterMove.kick);
      } else if (roll > 0.85) {
        _walkIntent = -foe.facing;
      }
    }
    if (foe.move == FighterMove.idle && _walkIntent != 0) {
      _walk(foe, _walkIntent * math.min(3.0, 2.0 + 0.15 * _level) * dt);
    }
    foe.facing = _player.x <= foe.x ? -1 : 1;
  }
}
