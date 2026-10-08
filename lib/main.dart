import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const ZigzagDashApp());

class ZigzagDashApp extends StatelessWidget {
  const ZigzagDashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Zigzag Dash',
      tagline: 'Zig and zag without falling off the endless path! 🌀',
      emoji: '🌀',
      slug: 'zigzagdash',
      howToPlay:
          '• Your ball dashes forward on its own. Tap anywhere!\n• TAP turns the ball — zig and zag to stay on the path.\n• Fall off the edge and the run ends. Grab ⭐ stars for glory!\n• The longer you survive, the faster it gets. Good luck! 🌀',
      playerOptions: const [1],
      supportsBots: false,
      gameBuilder: (ctx, players, cb) => ZigzagDashScreen(players: players, callbacks: cb),
    );
  }
}
