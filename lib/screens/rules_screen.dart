import 'package:flutter/material.dart';
import '../theme/dash_themes.dart';
import '../theme/ui_kit.dart';

/// In-app rules reference (mirrors the root RULES.md).
class RulesScreen extends StatelessWidget {
  final DashTheme theme;
  const RulesScreen({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.skyTop, theme.skyBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    ChunkyButton(
                      small: true,
                      height: 46,
                      top: theme.panel,
                      edge: theme.panelEdge,
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(Icons.arrow_back,
                          color: theme.ink, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Text('HOW TO PLAY',
                        style: DashText.display(26,
                            color: theme.panelEdge)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final s in _sections)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: WoodPanel(
                          panel: theme.panel,
                          edge: theme.panelEdge,
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(s.$1,
                                  style: DashText.label(
                                      14, color: theme.star)),
                              const SizedBox(height: 6),
                              Text(s.$2,
                                  style: DashText.body(
                                      13, color: theme.ink)),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _sections = [
  (
    'OBJECTIVE',
    'Keep the ball on the endless zigzag track for as long as you can. '
        'Every tile you cross scores a point; every star you grab scores more. '
        'One wrong tap — or one late tap — and you fall off.'
  ),
  (
    'SETUP',
    'Pick a mode (Endless or Score Attack) and a difficulty (Chill, Normal, '
        'Extreme). The ball starts on the first tile of a freshly built track, '
        'rolling down-left. Tap anywhere to begin the countdown.'
  ),
  (
    'LEGAL MOVES',
    'Tap anywhere on the screen to flip the ball between its two diagonal '
        'directions: down-left and down-right. That is the only move in the game.'
  ),
  (
    'ILLEGAL MOVES',
    'There are none — every tap is accepted in Endless and Score Attack. '
        'Tapping during the countdown or after the run ends simply does nothing.'
  ),
  (
    'TURNS & CORNERS',
    'The track turns on its own. Corner tiles are marked with a chevron — '
        'tap just before the ball reaches one to stay on the path. '
        'Tap too early or too late and the ball rolls off the edge.'
  ),
  (
    'SCORING',
    '+1 point per tile crossed. Stars are worth 10 × your current combo '
        '(up to ×5): grab stars back-to-back to build the combo. '
        'Missing a star never breaks anything — the combo only counts stars.'
  ),
  (
    'WINNING & LOSING',
    'There is no final win — the run ends when the ball falls off the track '
        '(Endless) or when the 60-second timer hits zero (Score Attack). '
        'Beating your best score on a mode + difficulty is the victory.'
  ),
  (
    'DIFFICULTY PROGRESSION',
    'Chill: slow ball, long straightaways, frequent stars. '
        'Normal: brisk speed, regular corners. '
        'Extreme (Pro): blazing speed, tight constant corners, fewer stars. '
        'Inside every run, the level rises every 400 tiles: faster ball, '
        'tighter corners.'
  ),
  (
    'EDGE CASES',
    'Pausing freezes everything mid-roll and resumes exactly. '
        'Backgrounding the app auto-pauses. '
        'If the game loop ever stalls, a watchdog restarts it — a run can '
        'never freeze with no way forward.'
  ),
];
