import 'dart:math';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/zigzag_engine.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../services/iap_service.dart';
import '../theme/dash_themes.dart';
import '../theme/ui_kit.dart';

const _storeUrl =
    'https://play.google.com/store/apps/details?id=com.gameswajiha.zigzagdash';

/// The play screen: full-screen tap-to-turn zigzag running on a chunky
/// wooden toy track rendered in pseudo-3D.
class GameScreen extends StatefulWidget {
  final DashAudio audio;
  final DashSettings settings;
  final StoreService store;
  const GameScreen(
      {super.key,
      required this.audio,
      required this.settings,
      required this.store});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final ZigzagEngine _engine;
  late final AnimationController _pulse;
  bool _overHandled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _engine = ZigzagEngine();
    _engine.onEvent = _onEngineEvent;
    _engine.startRun(
      difficulty: widget.settings.difficulty,
      scoreAttack: widget.settings.scoreAttack,
    );
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    widget.audio.startGameMusic();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulse.dispose();
    _engine.dispose();
    widget.audio.startMenuMusic();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      widget.audio.onAppPaused();
      if (_engine.phase == DashPhase.running ||
          _engine.phase == DashPhase.countdown) {
        _engine.setPaused(true);
      }
    } else if (state == AppLifecycleState.resumed) {
      widget.audio.onAppResumed();
    }
  }

  void _onEngineEvent(String e) {
    final a = widget.audio;
    switch (e) {
      case 'turn':
        a.turn();
      case 'star':
        a.star();
      case 'combo':
        a.combo();
      case 'fall':
        a.fall();
      case 'over':
        a.thud();
        Future.delayed(const Duration(milliseconds: 180), () {
          if (mounted) widget.audio.gameOver();
        });
        _handleGameOver();
      case 'tick':
        a.tick();
      case 'go':
        a.go();
      case 'go_countdown':
        a.gameStart();
      case 'levelup':
        a.levelup();
      case 'timeup':
        a.go();
      case 'invalid':
        a.invalid();
    }
  }

  Future<void> _handleGameOver() async {
    if (_overHandled) return;
    _overHandled = true;
    final s = widget.settings;
    final isBest = await s.recordRun(
      scoreAttack: _engine.scoreAttack,
      difficulty: _engine.difficulty,
      score: _engine.score,
      stars: _engine.stars,
    );
    _engine.markBestRecorded(isBest ? _engine.score : 0);
    if (isBest && mounted) {
      widget.audio.record();
      // Ask for a review at a genuine moment of delight. Graceful when the
      // app did not come from Play (the call simply no-ops there).
      try {
        await InAppReview.instance.requestReview();
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  void _retry() {
    widget.audio.click();
    _overHandled = false;
    _engine.startRun(
      difficulty: widget.settings.difficulty,
      scoreAttack: widget.settings.scoreAttack,
    );
  }

  void _shareScore() {
    widget.audio.click();
    final e = _engine;
    Share.share(
      'I scored ${e.score} in Zigzag Dash with ${widget.settings.playerName}! '
      'Can you beat my run? $_storeUrl',
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    final theme = DashThemes.byId(s.themeId, custom: s.customTheme);
    final ball = BallStyles.byId(s.ballStyleId, customColor: s.customBallColor);
    return Scaffold(
      body: AnimatedBuilder(
        animation: _engine,
        builder: (context, _) {
          final e = _engine;
          return Stack(
            children: [
              // Tap anywhere to turn.
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  widget.audio.click();
                  e.tap();
                },
                child: CustomPaint(
                  painter: _DashPainter(
                    engine: e,
                    theme: theme,
                    ball: ball,
                    time: DateTime.now().millisecondsSinceEpoch / 1000.0,
                  ),
                  size: Size.infinite,
                ),
              ),
              _hud(context, theme, e),
              if (e.phase == DashPhase.ready) _readyOverlay(theme),
              if (e.phase == DashPhase.countdown) _countdownOverlay(theme, e),
              if (e.paused) _pauseOverlay(theme),
              if (e.phase == DashPhase.gameover) _gameOverOverlay(theme, e),
            ],
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------------ HUD
  Widget _hud(BuildContext context, DashTheme theme, ZigzagEngine e) {
    final s = widget.settings;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _chip(theme,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('SCORE',
                            style: DashText.label(10, color: theme.ink)),
                        Text('${e.score}',
                            style: DashText.display(30, color: theme.ink)),
                      ],
                    )),
                const SizedBox(width: 8),
                _chip(theme,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('⭐ ${e.stars}',
                            style: DashText.label(15, color: theme.ink)),
                        const SizedBox(height: 2),
                        Text(
                          e.scoreAttack
                              ? _fmtTime(e.timeLeft)
                              : 'LV ${e.level}',
                          style: DashText.label(13,
                              color: theme.ink.withValues(alpha: 0.85)),
                        ),
                      ],
                    )),
                const Spacer(),
                _chip(theme,
                    child: Text(
                      'BEST\n${s.bestFor(e.scoreAttack, e.difficulty)}',
                      textAlign: TextAlign.center,
                      style: DashText.label(11, color: theme.ink),
                    )),
                const SizedBox(width: 8),
                ChunkyButton(
                  small: true,
                  height: 52,
                  top: theme.accent,
                  edge: theme.panelEdge,
                  onTap: () {
                    widget.audio.click();
                    e.setPaused(true);
                  },
                  child: Icon(Icons.pause,
                      color: theme.ink, size: 26),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: _chip(
                theme,
                child: Text(
                  '${s.playerName} • ${e.scoreAttack ? 'SCORE ATTACK' : 'ENDLESS'} • ${_diffName(e.difficulty)}',
                  style: DashText.label(11, color: theme.ink),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _diffName(int d) =>
      ['CHILL', 'NORMAL', 'EXTREME'][d.clamp(0, 2)];

  String _fmtTime(double t) {
    final s = t.ceil();
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  Widget _chip(DashTheme theme, {required Widget child}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.hudChip,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: theme.ink.withValues(alpha: 0.35), width: 1.5),
        ),
        child: child,
      );

  // -------------------------------------------------------------- overlays
  Widget _readyOverlay(DashTheme theme) => Center(
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) => Opacity(
            opacity: 0.65 + 0.35 * _pulse.value,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
              decoration: BoxDecoration(
                color: theme.hudChip,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: theme.ink.withValues(alpha: 0.5), width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('READY?',
                      style: DashText.display(34, color: theme.ink)),
                  const SizedBox(height: 6),
                  Text('TAP anywhere to turn the ball.\nStay on the track!',
                      textAlign: TextAlign.center,
                      style: DashText.body(15, color: theme.ink)),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _countdownOverlay(DashTheme theme, ZigzagEngine e) => Center(
        child: Text(
          '${e.countdownT.ceil().clamp(1, 3)}',
          style: DashText.display(110, color: theme.ink),
        ),
      );

  Widget _pauseOverlay(DashTheme theme) {
    final s = widget.settings;
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: WoodPanel(
          panel: theme.panel,
          edge: theme.panelEdge,
          child: SizedBox(
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('PAUSED',
                    style: DashText.display(34, color: theme.ink)),
                const SizedBox(height: 14),
                ChunkyButton(
                  top: theme.accent,
                  edge: theme.panelEdge,
                  onTap: () {
                    widget.audio.click();
                    _engine.resume();
                  },
                  child: Text('RESUME',
                      style: DashText.label(17, color: theme.ink)),
                ),
                const SizedBox(height: 10),
                ChunkyButton(
                  top: theme.tileSideLeft,
                  edge: theme.panelEdge,
                  onTap: _retry,
                  child: Text('RESTART',
                      style: DashText.label(17, color: theme.ink)),
                ),
                const SizedBox(height: 10),
                ChunkyButton(
                  top: theme.tileSideLeft,
                  edge: theme.panelEdge,
                  onTap: () {
                    widget.audio.click();
                    Navigator.of(context).pop();
                  },
                  child: Text('MENU',
                      style: DashText.label(17, color: theme.ink)),
                ),
                const SizedBox(height: 14),
                ToggleRow(
                  title: 'Music',
                  subtitle: 'Menu & gameplay tunes',
                  value: s.musicOn,
                  ink: theme.ink,
                  accent: theme.accent,
                  onChanged: (v) {
                    widget.audio.click();
                    s.setMusic(v);
                    widget.audio.configure(
                        musicOn: v, sfxOn: s.sfxOn, volume: s.volume);
                    if (v) widget.audio.startGameMusic();
                  },
                ),
                ToggleRow(
                  title: 'Sound FX',
                  subtitle: 'Turns, stars & thuds',
                  value: s.sfxOn,
                  ink: theme.ink,
                  accent: theme.accent,
                  onChanged: (v) {
                    s.setSfx(v);
                    widget.audio.configure(
                        musicOn: s.musicOn, sfxOn: v, volume: s.volume);
                    widget.audio.click();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _gameOverOverlay(DashTheme theme, ZigzagEngine e) {
    final s = widget.settings;
    final title = e.fellOff ? 'RUN OVER!' : "TIME'S UP!";
    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: SingleChildScrollView(
          child: WoodPanel(
            panel: theme.panel,
            edge: theme.panelEdge,
            child: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: DashText.display(36, color: theme.ink)),
                  if (e.newBest > 0) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.star,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('★ NEW BEST! ★',
                          style: DashText.label(
                              14,
                              color: theme.panelEdge)),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _statRow(theme, 'Score', '${e.score}'),
                  _statRow(theme, 'Stars', '⭐ ${e.stars}'),
                  _statRow(theme, 'Distance', '${e.distance} tiles'),
                  _statRow(theme, 'Best',
                      '${s.bestFor(e.scoreAttack, e.difficulty)}'),
                  const SizedBox(height: 14),
                  ChunkyButton(
                    top: theme.accent,
                    edge: theme.panelEdge,
                    onTap: _retry,
                    child: Text('DASH AGAIN',
                        style: DashText.label(17, color: theme.ink)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ChunkyButton(
                          small: true,
                          height: 50,
                          top: theme.tileSideLeft,
                          edge: theme.panelEdge,
                          onTap: () {
                            widget.audio.click();
                            Navigator.of(context).pop();
                          },
                          child: Text('MENU',
                              style: DashText.label(14, color: theme.ink)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChunkyButton(
                          small: true,
                          height: 50,
                          top: theme.tileSideLeft,
                          edge: theme.panelEdge,
                          onTap: _shareScore,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.share,
                                  color: theme.ink, size: 18),
                              const SizedBox(width: 6),
                              Text('SHARE',
                                  style: DashText.label(
                                      14, color: theme.ink)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statRow(DashTheme theme, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Text(k, style: DashText.body(15, color: theme.ink)),
            const Spacer(),
            Text(v, style: DashText.label(15, color: theme.ink)),
          ],
        ),
      );
}

// ================================================================== painter
class _DashPainter extends CustomPainter {
  final ZigzagEngine engine;
  final DashTheme theme;
  final BallStyle ball;
  final double time;

  _DashPainter(
      {required this.engine,
      required this.theme,
      required this.ball,
      required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final tw = (w * 0.21).clamp(60.0, 108.0);
    final th = tw * 0.5;
    final depth = tw * 0.24;

    // Sky.
    final sky = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRect(
        sky,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.skyTop, theme.skyBottom],
          ).createShader(sky));

    // Clouds drift.
    for (int i = 0; i < 5; i++) {
      final cx = ((i * 293.7 + time * (8 + i * 3)) % (w + 300)) - 150;
      final cy = h * (0.06 + 0.09 * ((i * 137) % 5) / 5);
      _cloud(canvas, Offset(cx, cy), tw * (0.5 + 0.12 * (i % 3)), theme.cloud);
    }

    double ix(double x, double z) => (x - z) * tw / 2;
    double iy(double x, double z) => (x + z) * th / 2;
    final camX = ix(engine.bx, engine.bz) - w * 0.5;
    final camY = iy(engine.bx, engine.bz) - h * 0.62;
    double sx(double x, double z) => ix(x, z) - camX;
    double sy(double x, double z) => iy(x, z) - camY;

    // Tiles far -> near.
    for (final t in engine.tiles) {
      final px = sx(t.x.toDouble(), t.z.toDouble());
      final py = sy(t.x.toDouble(), t.z.toDouble());
      if (px < -tw || px > w + tw || py < -th - depth || py > h + th) continue;
      _tile(canvas, px, py, tw, th, depth, t.corner);
      if (t.hasStar) _starTile(canvas, px, py - th * 0.9, tw * 0.17);
    }

    // FX under ball.
    for (final f in engine.fx) {
      final age = engineElapsed() - f.born;
      if (f.kind == 'puff') {
        _puff(canvas, sx(f.x, f.z), sy(f.x, f.z), age);
      } else if (f.kind == 'burst') {
        _burst(canvas, sx(f.x, f.z), sy(f.x, f.z) - th * 0.9, age);
      }
    }

    _ball(canvas, sx(engine.bx, engine.bz), sy(engine.bx, engine.bz), tw, th);

    // Floating texts on top.
    for (final f in engine.fx) {
      if (f.kind != 'text') continue;
      final age = engineElapsed() - f.born;
      _floatText(canvas, f.text, sx(f.x, f.z), sy(f.x, f.z) - th * 1.6, age,
          theme);
    }
  }

  double engineElapsed() => engine.elapsed;

  void _cloud(Canvas c, Offset o, double r, Color col) {
    final p = Paint()..color = col.withValues(alpha: 0.85);
    c.drawCircle(o, r * 0.55, p);
    c.drawCircle(o + Offset(-r * 0.5, r * 0.12), r * 0.38, p);
    c.drawCircle(o + Offset(r * 0.5, r * 0.12), r * 0.42, p);
    c.drawCircle(o + Offset(0, r * 0.22), r * 0.5, p);
  }

  void _tile(Canvas c, double px, double py, double tw, double th, double d,
      bool corner) {
    final hw = tw / 2, hh = th / 2;
    final top = Offset(px, py);
    final right = Offset(px + hw, py + hh);
    final bottom = Offset(px, py + th);
    final left = Offset(px - hw, py + hh);
    // Side faces (drawn first, behind top).
    final sideL = Path()
      ..moveTo(left.dx, left.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(bottom.dx, bottom.dy + d)
      ..lineTo(left.dx, left.dy + d)
      ..close();
    final sideR = Path()
      ..moveTo(right.dx, right.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(bottom.dx, bottom.dy + d)
      ..lineTo(right.dx, right.dy + d)
      ..close();
    c.drawPath(sideL, Paint()..color = theme.tileSideLeft);
    c.drawPath(sideR, Paint()..color = theme.tileSideRight);
    // Soft AO under the front edge.
    c.drawPath(
        sideR,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    // Top face.
    final topFace = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(left.dx, left.dy)
      ..close();
    c.drawPath(topFace, Paint()..color = theme.tileTop);
    // Top highlight edge (light from upper-left).
    c.drawLine(
        top,
        left,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.28)
          ..strokeWidth = 2);
    c.drawLine(
        top,
        right,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.14)
          ..strokeWidth = 2);
    // Dark bevel on lower edges.
    c.drawLine(
        left,
        bottom,
        Paint()
          ..color = theme.tileEdge.withValues(alpha: 0.6)
          ..strokeWidth = 2.5);
    c.drawLine(
        right,
        bottom,
        Paint()
          ..color = theme.tileEdge.withValues(alpha: 0.6)
          ..strokeWidth = 2.5);
    // Corner marker: a subtle chevron pointing the turn way.
    if (corner) {
      final chev = Path()
        ..moveTo(px - hw * 0.35, py + hh * 0.35)
        ..lineTo(px, py + hh * 0.75)
        ..lineTo(px + hw * 0.35, py + hh * 0.35);
      c.drawPath(
          chev,
          Paint()
            ..color = theme.cornerMark
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round);
    }
  }

  void _starTile(Canvas c, double px, double py, double r) {
    final bob = sin(time * 3.2 + px * 0.05) * 4;
    final y = py + bob;
    // glow
    c.drawCircle(
        Offset(px, y),
        r * 1.7,
        Paint()
          ..color = theme.star.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    _starPath(c, Offset(px, y), r, theme.star);
    _starPath(c, Offset(px - r * 0.25, y - r * 0.3), r * 0.35,
        Colors.white.withValues(alpha: 0.9));
  }

  void _starPath(Canvas c, Offset o, double r, Color col) {
    final p = Path();
    for (int i = 0; i < 10; i++) {
      final a = -pi / 2 + i * pi / 5;
      final rr = i.isEven ? r : r * 0.45;
      final pt = o + Offset(cos(a) * rr, sin(a) * rr);
      if (i == 0) {
        p.moveTo(pt.dx, pt.dy);
      } else {
        p.lineTo(pt.dx, pt.dy);
      }
    }
    p.close();
    c.drawPath(p, Paint()..color = col);
  }

  void _puff(Canvas c, double px, double py, double age) {
    final t = (age / 0.45).clamp(0.0, 1.0);
    if (t >= 1) return;
    c.drawCircle(
        Offset(px, py),
        8 + t * 34,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.55 * (1 - t))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4 * (1 - t) + 1);
  }

  void _burst(Canvas c, double px, double py, double age) {
    final t = (age / 0.5).clamp(0.0, 1.0);
    if (t >= 1) return;
    for (int i = 0; i < 10; i++) {
      final a = i * 2 * pi / 10 + age * 3;
      final r0 = 6 + t * 30;
      final r1 = r0 + 12 * (1 - t);
      c.drawLine(
          Offset(px + cos(a) * r0, py + sin(a) * r0),
          Offset(px + cos(a) * r1, py + sin(a) * r1),
          Paint()
            ..color = theme.star.withValues(alpha: 0.9 * (1 - t))
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round);
    }
  }

  void _floatText(
      Canvas c, String text, double px, double py, double age, DashTheme th) {
    final t = (age / 1.1).clamp(0.0, 1.0);
    if (t >= 1 || text.isEmpty) return;
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: DashText.display(22, color: th.ink),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c,
        Offset(px - tp.width / 2, py - t * 46 - tp.height / 2));
    // fade by overlaying? TextPainter has no alpha — draw with opacity via
    // a second pass is overkill; pop motion alone reads clearly.
  }

  void _ball(Canvas c, double px, double py, double tw, double th) {
    final e = engine;
    double fallOffset = 0;
    double alpha = 1;
    double squashY = 1 - 0.28 * (1 - e.squashT);
    double squashX = 1 + 0.22 * (1 - e.squashT);
    double bob = 0;
    if (e.phase == DashPhase.dying) {
      if (e.fellOff) {
        final t = e.fallT.clamp(0.0, 1.0);
        fallOffset = 620 * t * t;
        alpha = 1 - t * 0.85;
        squashX = squashY = 1 - 0.35 * t;
      } else {
        bob = -8 * sin(e.fallT * pi); // happy little hop on time-up
      }
    } else if (e.phase == DashPhase.ready) {
      bob = -6 * (0.5 + 0.5 * sin(time * 4));
    } else if (e.phase == DashPhase.running) {
      bob = -2.5 * (0.5 + 0.5 * sin(time * 14)); // rolling bounce
    }
    final r = tw * 0.30;
    final cy = py - r * 0.85 + bob + fallOffset;
    // Contact shadow.
    c.drawOval(
        Rect.fromCenter(
            center: Offset(px, py + 4),
            width: r * 1.7 * (1 - fallOffset / 1200).clamp(0.4, 1.0),
            height: r * 0.55 * (1 - fallOffset / 1200).clamp(0.4, 1.0)),
        Paint()..color = Colors.black.withValues(alpha: 0.32 * alpha));
    // Body.
    final bodyC = Offset(px, cy);
    final bodyR = r * squashX;
    final bodyH = r * squashY;
    final bodyRect = Rect.fromCenter(
        center: bodyC, width: bodyR * 2, height: bodyH * 2);
    final bodyPaint = Paint()
      ..color = ball.base.withValues(alpha: alpha)
      ..shader = null;
    // radial light from upper-left
    final grad = RadialGradient(
      center: const Alignment(-0.45, -0.55),
      radius: 1.1,
      colors: [
        ball.light.withValues(alpha: alpha),
        ball.base.withValues(alpha: alpha),
        ball.dark.withValues(alpha: alpha),
      ],
      stops: const [0.0, 0.55, 1.0],
    );
    bodyPaint.shader = grad.createShader(bodyRect);
    c.save();
    c.translate(bodyC.dx, bodyC.dy);
    c.scale(squashX, squashY);
    c.translate(-bodyC.dx, -bodyC.dy);
    c.drawCircle(bodyC, r, bodyPaint);
    // Pattern.
    final patPaint = Paint()
      ..color = ball.dark.withValues(alpha: 0.45 * alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    switch (ball.pattern) {
      case BallPattern.marble:
        c.drawArc(Rect.fromCircle(center: bodyC, radius: r * 0.55),
            0.4, 2.2, false, patPaint);
        c.drawArc(Rect.fromCircle(center: bodyC, radius: r * 0.8),
            2.8, 1.6, false, patPaint);
      case BallPattern.wood:
        for (int i = -1; i <= 1; i++) {
          c.drawLine(
              Offset(bodyC.dx - r * 0.7, bodyC.dy + i * r * 0.35),
              Offset(bodyC.dx + r * 0.7, bodyC.dy + i * r * 0.35),
              patPaint);
        }
      case BallPattern.stripe:
        c.drawLine(Offset(bodyC.dx - r * 0.85, bodyC.dy),
            Offset(bodyC.dx + r * 0.85, bodyC.dy), patPaint..strokeWidth = 6);
      case BallPattern.swirl:
        c.drawArc(Rect.fromCircle(center: bodyC, radius: r * 0.6),
            time * 2, 4.2, false, patPaint);
      case BallPattern.solid:
        break;
    }
    // Rim + specular highlight.
    c.drawCircle(
        bodyC,
        r,
        Paint()
          ..color = ball.dark.withValues(alpha: 0.7 * alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    c.drawCircle(
        bodyC + Offset(-r * 0.38, -r * 0.42),
        r * 0.22,
        Paint()..color = Colors.white.withValues(alpha: 0.85 * alpha));
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _DashPainter old) => true;
}
