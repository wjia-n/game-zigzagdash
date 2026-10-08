import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

/// Zigzag Dash: tap to turn, don't fall off the endless zigzag path!
class ZigzagDashScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;
  const ZigzagDashScreen({super.key, required this.players, required this.callbacks});

  @override
  State<ZigzagDashScreen> createState() => _ZigzagDashScreenState();
}

class _ZigzagDashScreenState extends State<ZigzagDashScreen> with SingleTickerProviderStateMixin {
  late Ticker ticker;
  final rng = Random();
  final tiles = <String, bool>{}; // "x,y" -> hasStar
  int cx = 0, cy = 0;   // current cell
  int sy = 1;           // y direction (+1 / -1)
  double prog = 0;      // progress to next cell 0..1
  double speed = 3.0;   // cells per second
  int stars = 0;
  bool over = false, started = false, falling = false;
  double fallT = 0;
  int best = 0, bestStars = 0;
  Duration lastTick = Duration.zero;

  double get ballX => cx + prog;
  double get ballY => cy + sy * prog;

  @override
  void initState() {
    super.initState();
    _genPath(0);
    SharedPreferences.getInstance().then((p) {
      if (mounted) {
        setState(() {
          best = p.getInt('zigzagdash_best') ?? 0;
          bestStars = p.getInt('zigzagdash_stars') ?? 0;
        });
      }
    });
    ticker = createTicker(_tick)..start();
  }

  void _genPath(int fromX) {
    // find the tail tile (max x) and its direction
    int tailX = -1, tailY = 0, dir = 1;
    for (final k in tiles.keys) {
      final parts = k.split(',');
      final x = int.parse(parts[0]), y = int.parse(parts[1]);
      if (x > tailX) {
        tailX = x;
        tailY = y;
      }
    }
    for (final k in tiles.keys) {
      final parts = k.split(',');
      if (int.parse(parts[0]) == tailX - 1) {
        final py = int.parse(parts[1]);
        dir = tailY >= py ? 1 : -1;
      }
    }
    int y = tailY;
    int startX = max(fromX, tailX + 1);
    if (tailX < 0) {
      tiles['0,0'] = false;
      tiles['1,1'] = false;
      startX = 2;
      y = 1;
      dir = 1;
    }
    for (int x = startX; x < startX + 500; x++) {
      if (rng.nextDouble() < 0.30) dir = -dir;
      y += dir;
      tiles['$x,$y'] = (x % 6 == 4);
    }
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  void _tick(Duration now) {
    if (!mounted || over) return;
    if (ModalRoute.of(context)?.isCurrent != true) {
      lastTick = now;
      return;
    }
    final dt = lastTick == Duration.zero ? 0.016 : (now - lastTick).inMicroseconds / 1e6;
    lastTick = now;
    final step = dt.clamp(0.0, 0.05);
    if (!started || falling) {
      if (falling) {
        setState(() {
          fallT += step;
          if (fallT > 0.7) _gameOver();
        });
      }
      return;
    }
    setState(() {
      speed = min(7.0, 3.0 + ballX * 0.012);
      prog += speed * step;
      if (prog >= 1) {
        prog = 0;
        final nx = cx + 1, ny = cy + sy;
        if (tiles.containsKey('$nx,$ny')) {
          cx = nx; cy = ny;
          if (tiles['$cx,$cy'] == true) {
            stars++;
            tiles['$cx,$cy'] = false;
            Sfx.click();
          }
          // extend path ahead
          if (cx > 0 && (tiles.keys.map((k) => int.parse(k.split(',')[0])).reduce(max)) - cx < 200) {
            _genPath(cx + 200);
          }
        } else {
          falling = true;
          fallT = 0;
        }
      }
    });
  }

  void _onTap() {
    if (over || falling) return;
    if (!started) {
      setState(() => started = true);
      return;
    }
    Sfx.tap();
    setState(() => sy = -sy);
  }

  void _gameOver() {
    over = true;
    Sfx.lose();
    final dist = cx;
    final isBest = dist > best;
    if (isBest) {
      best = dist;
      SharedPreferences.getInstance().then((p) {
        p.setInt('zigzagdash_best', best);
        if (stars > bestStars) p.setInt('zigzagdash_stars', stars);
      });
    }
    widget.players[0].score = dist;
    widget.callbacks.refreshHud();
    widget.callbacks.finish(
      headline: '🌀 You dashed ${dist}m!',
      subline: '⭐ $stars stars${isBest ? ' — 🏆 NEW BEST!' : ' — best: ${best}m'}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          TurnBanner(player: widget.players[0],
              action: over ? 'fell off!' : (started ? 'is dashing!' : 'tap to start!')),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('📏 ${ballX.toStringAsFixed(0)}m',
                    style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontSize: 22)),
                const SizedBox(width: 14),
                Text('⭐ $stars', style: TextStyle(color: t.accent, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(width: 14),
                Text('🏆 ${best}m', style: TextStyle(color: t.muted, fontSize: 14)),
              ],
            ),
          ),
          Expanded(
            child: CustomPaint(
              painter: _ZigzagPainter(
                tiles: tiles, ballX: ballX, ballY: ballY, falling: falling, fallT: fallT,
                started: started, over: over, primary: t.primary, accent: t.accent,
                secondary: t.secondary, text: t.text, muted: t.muted, surface: t.surface,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text('👆 TAP to turn! Stay on the path, grab the stars!',
                style: TextStyle(color: t.muted, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _ZigzagPainter extends CustomPainter {
  final Map<String, bool> tiles;
  final double ballX, ballY, fallT;
  final bool falling, started, over;
  final Color primary, accent, secondary, text, muted, surface;
  _ZigzagPainter({required this.tiles, required this.ballX, required this.ballY,
    required this.falling, required this.fallT, required this.started, required this.over,
    required this.primary, required this.accent, required this.secondary,
    required this.text, required this.muted, required this.surface});

  @override
  void paint(Canvas c, Size s) {
    const tw = 64.0; // tile width px
    final camX = ballX - 2.2, camY = ballY - 1.2;
    Offset cellPt(int x, int y) =>
        Offset((x - camX) * tw + s.width * 0.18, (y - camY) * tw * 0.62 + s.height * 0.42);

    // draw tiles near camera
    final keys = tiles.keys.toList()..sort();
    for (final k in keys) {
      final parts = k.split(',');
      final x = int.parse(parts[0]), y = int.parse(parts[1]);
      if ((x - ballX).abs() > 9) continue;
      final p = cellPt(x, y);
      if (p.dx < -tw || p.dx > s.width + tw || p.dy < -tw || p.dy > s.height + tw) continue;
      final depth = ((x * 7 + y * 13) % 5) / 5; // subtle shade variety
      final diamond = Path()
        ..moveTo(p.dx, p.dy - tw * 0.31)
        ..lineTo(p.dx + tw * 0.5, p.dy)
        ..lineTo(p.dx, p.dy + tw * 0.31)
        ..lineTo(p.dx - tw * 0.5, p.dy)
        ..close();
      c.drawPath(diamond, Paint()..color = Color.lerp(primary, surface, 0.35 + depth * 0.3)!);
      c.drawPath(diamond, Paint()..style = PaintingStyle.stroke..strokeWidth = 2
        ..color = primary.withValues(alpha: .8));
      if (tiles[k] == true) {
        // star
        final sp = Paint()..color = accent;
        c.drawCircle(Offset(p.dx, p.dy - 6), 9, sp);
        final starTp = TextPainter(
            text: const TextSpan(text: '⭐', style: TextStyle(fontSize: 20)),
            textDirection: TextDirection.ltr)
          ..layout();
        starTp.paint(c, Offset(p.dx - starTp.width / 2, p.dy - 6 - starTp.height / 2));
      }
    }
    // ball
    if (!over) {
      final fx = (ballX - camX) * tw + s.width * 0.18;
      final fy = (ballY - camY) * tw * 0.62 + s.height * 0.42 - 14 + (falling ? fallT * fallT * 400 : 0);
      // shadow
      c.drawOval(Rect.fromCenter(center: Offset(fx, fy + 16), width: 26, height: 8),
          Paint()..color = text.withValues(alpha: .25));
      final scale = falling ? (1 - fallT * 0.8).clamp(0.2, 1.0) : 1.0;
      final bg = RadialGradient(colors: [secondary, accent]);
      c.drawCircle(Offset(fx, fy), 13 * scale,
          Paint()..shader = bg.createShader(Rect.fromCircle(center: Offset(fx, fy), radius: 13 * scale)));
      c.drawCircle(Offset(fx, fy), 13 * scale,
          Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = text);
    }
    if (!started && !over) {
      final tp = TextPainter(
          text: TextSpan(text: '👆 tap to start dashing!',
              style: TextStyle(color: text, fontSize: 20, fontWeight: FontWeight.bold)),
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(c, Offset((s.width - tp.width) / 2, s.height * 0.2));
    }
  }

  @override
  bool shouldRepaint(covariant _ZigzagPainter o) => true;
}
