import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/dash_themes.dart';
import '../theme/ui_kit.dart';
import 'menu_screen.dart';

/// Single launch splash: game logo + name + animated loading line +
/// "Credits: WAJIHA" with the official company logo.
class SplashScreen extends StatefulWidget {
  final DashAudio audio;
  final DashSettings settings;
  const SplashScreen({super.key, required this.audio, required this.settings});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loader;
  int _phase = 0; // 0 = company moment, 1 = game splash

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _run();
  }

  Future<void> _run() async {
    widget.audio.prewarm();
    widget.audio.startMenuMusic();
    // Phase 1: company moment.
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    setState(() => _phase = 1);
    _loader.forward();
    // Phase 2: game splash with animated loading line.
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          audio: widget.audio,
          settings: widget.settings,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = DashThemes.byId(
      widget.settings.themeId,
      custom: widget.settings.customTheme,
    );
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.skyTop, theme.skyBottom],
          ),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: _phase == 0 ? _companyMoment() : _gameSplash(theme),
          ),
        ),
      ),
    );
  }

  /// Company moment: the official WAJIHA logo, unaltered, on a calm backdrop.
  Widget _companyMoment() {
    return Column(
      key: const ValueKey('company'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/wajiha_logo.png',
          width: 130,
          height: 130,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 18),
        Text('WAJIHA',
            style: DashText.display(30,
                color: const Color(0xFF2B3A55))),
        const SizedBox(height: 6),
        Text('presents',
            style: DashText.label(13,
                color: const Color(0xFF2B3A55))),
      ],
    );
  }

  /// Game splash: logo + name + animated loading line + Credits: WAJIHA.
  Widget _gameSplash(DashTheme theme) {
    return Column(
      key: const ValueKey('game'),
      mainAxisSize: MainAxisSize.min,
      children: [
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: theme.panelEdge, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      offset: const Offset(0, 10),
                      blurRadius: 24,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset('assets/zigzagdash_logo.png',
                    fit: BoxFit.cover),
              ),
              const SizedBox(height: 20),
              Text('ZIGZAG DASH',
                  style: DashText.display(44, color: theme.panelEdge)),
              const SizedBox(height: 4),
              Text('STAY ON THE TRACK',
                  style: DashText.label(13, color: theme.panelEdge)),
              const SizedBox(height: 28),
              SizedBox(
                width: 220,
                child: AnimatedBuilder(
                  animation: _loader,
                  builder: (_, __) => Column(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.black.withValues(alpha: 0.18),
                          border: Border.all(
                              color:
                                  theme.panelEdge.withValues(alpha: 0.5)),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _loader.value.clamp(0.03, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: theme.accent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _loader.value < 1
                            ? 'Warming up the track…'
                            : 'Ready!',
                        style: DashText.body(
                            13,
                            color: theme.panelEdge
                                .withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/wajiha_logo.png',
                    width: 30,
                    height: 30,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  Text('Credits: WAJIHA',
                      style: DashText.label(14, color: theme.panelEdge)),
                ],
              ),
            ],
      );
  }
}
