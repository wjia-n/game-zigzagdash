import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Zigzag Dash engine. Owns ALL game state and phase transitions.
///
/// Phases: ready -> countdown -> running -> dying -> gameover.
/// pause can suspend countdown/running; resume continues.
///
/// Watchdog: a periodic timer checks that the main loop is still ticking
/// whenever a live phase is active; if the loop died (timer cancelled,
/// exception, throttled), it is restarted automatically. Stuck states are
/// impossible by construction: every phase advances only inside [tick],
/// and the watchdog guarantees [tick] keeps running.
enum DashPhase { ready, countdown, running, dying, gameover }

/// Direction the ball rolls in grid space.
/// A=(0,1) renders as screen down-left, B=(1,0) as screen down-right.
enum DashDir { a, b }

class DashTile {
  final int x;
  final int z;
  final bool corner; // path changed direction here
  final bool hasStar;
  const DashTile(this.x, this.z, {this.corner = false, this.hasStar = false});
  @override
  bool operator ==(Object other) =>
      other is DashTile && other.x == x && other.z == z;
  @override
  int get hashCode => Object.hash(x, z);
}

/// A floating score popup / burst spawned by the engine for the UI to draw.
class DashFx {
  final String kind; // 'text' | 'puff' | 'burst' | 'trail'
  final double x; // grid coords
  final double z;
  final String text;
  final double born;
  const DashFx(this.kind, this.x, this.z, this.text, this.born);
}

class ZigzagEngine extends ChangeNotifier {
  final Random _rand;

  // ---- configuration (set once per run) ----
  int difficulty = 1; // 0 chill, 1 normal, 2 extreme
  bool scoreAttack = false;
  double attackSeconds = 60;

  // ---- observable state ----
  DashPhase phase = DashPhase.ready;
  int score = 0;
  int stars = 0;
  int distance = 0;
  int level = 1;
  int combo = 0;
  double timeLeft = 0;
  double countdownT = 0; // seconds remaining in countdown
  double fallT = 0; // 0..1 during dying
  bool fellOff = true; // dying cause: fell off (false = time up)
  int newBest = 0; // >0 when a new best was just set (for fanfare/review)
  final List<DashFx> fx = [];

  // ---- ball / path ----
  double bx = 0, bz = 0;
  DashDir dir = DashDir.a;
  final List<DashTile> tiles = [];
  final Set<DashTile> tileSet = {};
  double speed = 5.0; // tiles per second
  double squashT = 1; // 0 just turned -> 1 settled (ball squash anim)
  double turnX = 0, turnZ = 0; // where the last turn happened

  // ---- events the UI consumes (audio hooks) ----
  void Function(String event)? onEvent;
  // 'tap' 'turn' 'star' 'combo' 'fall' 'over' 'tick' 'go' 'record' 'levelup'
  // 'invalid'

  Timer? _loop;
  Timer? _watchdog;
  DateTime _lastTick = DateTime.now();
  bool _paused = false;
  bool _disposed = false;
  double _elapsed = 0; // seconds of running play

  /// Engine clock, for painters/FX timing.
  double get elapsed => _elapsed;

  ZigzagEngine({int? seed}) : _rand = Random(seed);

  // ------------------------------------------------------------ lifecycle
  /// Start a fresh run. Always callable; resets everything and lands in
  /// [DashPhase.ready] (tap to begin the countdown).
  void startRun({required int difficulty, required bool scoreAttack}) {
    _cancelLoop();
    this.difficulty = difficulty.clamp(0, 2);
    this.scoreAttack = scoreAttack;
    score = 0;
    stars = 0;
    distance = 0;
    level = 1;
    combo = 0;
    timeLeft = attackSeconds;
    countdownT = 0;
    fallT = 0;
    fellOff = true;
    newBest = 0;
    fx.clear();
    bx = 0;
    bz = 0;
    dir = DashDir.a;
    tiles.clear();
    tileSet.clear();
    speed = _baseSpeed();
    squashT = 1;
    _elapsed = 0;
    _paused = false;
    _genInitialPath();
    _setPhase(DashPhase.ready);
    _ensureLoop();
  }

  double _baseSpeed() => switch (difficulty) {
        0 => 4.1,
        2 => 6.6,
        _ => 5.3,
      };

  /// The current target speed, including in-run progression.
  double targetSpeed() {
    final prog = (distance ~/ 120);
    return (_baseSpeed() + prog * 0.35).clamp(_baseSpeed(), 9.6);
  }

  /// Tap = turn. Legal in ready (starts countdown) and running.
  /// Gracefully ignored elsewhere — never an error, never a stuck state.
  void tap() {
    if (_disposed || _paused) return;
    switch (phase) {
      case DashPhase.ready:
        _beginCountdown();
      case DashPhase.running:
        dir = dir == DashDir.a ? DashDir.b : DashDir.a;
        squashT = 0;
        turnX = bx;
        turnZ = bz;
        _fx('puff', bx, bz, '');
        _emit('turn');
        notifyListeners();
      case DashPhase.countdown:
        _emit('invalid'); // too early — gentle feedback, no state change
      case DashPhase.dying:
      case DashPhase.gameover:
        break; // ignore
    }
  }

  void _beginCountdown() {
    countdownT = 1.5;
    _setPhase(DashPhase.countdown);
    _emit('go_countdown');
  }

  void setPaused(bool p) {
    if (_disposed || phase == DashPhase.gameover) return;
    if (_paused == p) return;
    _paused = p;
    _lastTick = DateTime.now(); // watchdog must not fire while paused
    notifyListeners();
  }

  bool get paused => _paused;

  void resume() => setPaused(false);

  // ------------------------------------------------------------- path gen
  void _genInitialPath() {
    int x = 0, z = 0;
    DashDir d = DashDir.a;
    _addTile(x, z, corner: false, star: false);
    int run = 0;
    while (tiles.length < 26) {
      final maxRun = _maxRun();
      if (run >= 3 + _rand.nextInt(maxRun)) {
        d = d == DashDir.a ? DashDir.b : DashDir.a;
        run = 0;
      }
      if (d == DashDir.a) {
        z += 1;
      } else {
        x += 1;
      }
      _addTile(x, z, corner: run == 0, star: false);
      run++;
    }
    // seed a few stars further ahead
    for (int i = 8; i < 24; i += 4) {
      final t = tiles[i];
      _addTile(t.x, t.z, corner: t.corner, star: true);
    }
  }

  int _maxRun() => switch (difficulty) {
        0 => 7, // long straightaways
        2 => 3, // constant corners
        _ => 5,
      };

  void _addTile(int x, int z, {required bool corner, required bool star}) {
    final t = DashTile(x, z, corner: corner, hasStar: star);
    tiles.add(t);
    tileSet.add(t);
  }

  /// Extend the path ahead of the ball; prune tiles far behind the camera.
  void _extendPath() {
    while (tiles.length < 40) {
      final last = tiles.last;
      DashDir d = _lastDir;
      final maxRun = _maxRun();
      if (_runLen >= 2 + _rand.nextInt(maxRun)) {
        d = d == DashDir.a ? DashDir.b : DashDir.a;
        _runLen = 0;
        _lastDir = d;
      }
      final nx = last.x + (d == DashDir.b ? 1 : 0);
      final nz = last.z + (d == DashDir.a ? 1 : 0);
      final corner = _runLen == 0;
      final star = tiles.length > 10 && _rand.nextDouble() < _starChance();
      _addTile(nx, nz, corner: corner, star: star);
      _runLen++;
    }
    // prune behind (keep the last 8 behind the ball)
    while (tiles.length > 48) {
      tileSet.remove(tiles.removeAt(0));
    }
  }

  DashDir _lastDir = DashDir.a;
  int _runLen = 1;

  double _starChance() => switch (difficulty) {
        0 => 0.22,
        2 => 0.13,
        _ => 0.17,
      };

  bool _supported(double x, double z) =>
      tileSet.contains(DashTile(x.round(), z.round()));

  // ---------------------------------------------------------------- loop
  void _ensureLoop() {
    if (_disposed) return;
    _loop ??= Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
    _watchdog ??=
        Timer.periodic(const Duration(milliseconds: 300), (_) => _guard());
    _lastTick = DateTime.now();
  }

  void _cancelLoop() {
    _loop?.cancel();
    _loop = null;
  }

  /// Watchdog: if a live phase is active but the loop hasn't ticked recently,
  /// restart the loop. Never touches a paused engine or a settled phase.
  void _guard() {
    if (_disposed || _paused) return;
    if (phase == DashPhase.ready || phase == DashPhase.gameover) return;
    final dt = DateTime.now().difference(_lastTick).inMilliseconds;
    if (dt > 900) {
      _cancelLoop();
      _ensureLoop();
    }
  }

  void _setPhase(DashPhase p) {
    phase = p;
    _lastTick = DateTime.now();
    notifyListeners();
  }

  void _emit(String e) => onEvent?.call(e);

  void _fx(String kind, double x, double z, String text) {
    fx.add(DashFx(kind, x, z, text, _elapsed));
    if (fx.length > 60) fx.removeAt(0);
  }

  void _tick() {
    if (_disposed || _paused) return;
    _lastTick = DateTime.now();
    const dt = 1 / 60;
    _elapsed += dt;
    squashT = (squashT + dt * 6).clamp(0.0, 1.0);
    // expire fx
    fx.removeWhere((f) => _elapsed - f.born > 1.2);

    switch (phase) {
      case DashPhase.ready:
        _idleBob();
      case DashPhase.countdown:
        _tickCountdown(dt);
      case DashPhase.running:
        _tickRunning(dt);
      case DashPhase.dying:
        _tickDying(dt);
      case DashPhase.gameover:
        break;
    }
    notifyListeners();
  }

  void _idleBob() {
    // Ball gently bobs on the start tile while waiting.
  }

  double _lastCountInt = 3;
  void _tickCountdown(double dt) {
    countdownT -= dt;
    final n = countdownT.ceil().clamp(0, 3);
    if (n < _lastCountInt && n > 0) {
      _lastCountInt = n.toDouble();
      _emit('tick');
    }
    if (countdownT <= 0) {
      _lastCountInt = 3;
      _setPhase(DashPhase.running);
      _emit('go');
    }
  }

  void _tickRunning(double dt) {
    speed += (targetSpeed() - speed) * dt * 0.8;
    final step = speed * dt;
    if (dir == DashDir.a) {
      bz += step;
    } else {
      bx += step;
    }
    _extendPath();

    // distance = tiles passed
    final d = (bx + bz).floor();
    if (d > distance) {
      final gained = d - distance;
      distance = d;
      score += gained;
      final nl = 1 + distance ~/ 400;
      if (nl > level) {
        level = nl;
        _emit('levelup');
        _fx('text', bx, bz, 'LEVEL $level!');
      }
    }

    // star pickup
    for (final t in tiles) {
      if (!t.hasStar) continue;
      final dx = t.x - bx, dz = t.z - bz;
      if (dx * dx + dz * dz < 0.16) {
        // collect: replace tile with star-less twin
        final i = tiles.indexOf(t);
        tiles[i] = DashTile(t.x, t.z, corner: t.corner, hasStar: false);
        tileSet
          ..remove(t)
          ..add(tiles[i]);
        stars++;
        combo++;
        final pts = 10 * combo.clamp(1, 5);
        score += pts;
        _fx('burst', t.x.toDouble(), t.z.toDouble(), '+$pts');
        if (combo >= 3) _fx('text', bx, bz - 1, 'COMBO x${combo.clamp(1, 5)}!');
        _emit(combo >= 3 ? 'combo' : 'star');
        break;
      }
    }

    // score attack timer
    if (scoreAttack) {
      timeLeft -= dt;
      if (timeLeft <= 0) {
        timeLeft = 0;
        _finishRun(fell: false);
        return;
      }
    }

    // fall check
    if (!_supported(bx, bz)) {
      _beginFall();
    }
  }

  void _beginFall() {
    fallT = 0;
    fellOff = true;
    _setPhase(DashPhase.dying);
    _emit('fall');
  }

  void _finishRun({required bool fell}) {
    fellOff = fell;
    fallT = 0;
    _setPhase(DashPhase.dying);
    _emit(fell ? 'fall' : 'timeup');
  }

  void _tickDying(double dt) {
    fallT += dt / 0.75;
    if (fallT >= 1) {
      fallT = 1;
      _setPhase(DashPhase.gameover);
      _emit('over');
    }
  }

  /// Called by the UI once it has read the score, so persistence/review can
  /// happen exactly once per run.
  void markBestRecorded(int best) {
    newBest = best;
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelLoop();
    _watchdog?.cancel();
    _watchdog = null;
    super.dispose();
  }
}
