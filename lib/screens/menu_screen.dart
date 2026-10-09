import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../services/iap_service.dart';
import '../theme/dash_themes.dart';
import '../theme/ui_kit.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'pro_screen.dart';
import 'rules_screen.dart';

/// Main menu: logo, renameable profile chip, mode + difficulty pickers,
/// big PLAY button, and navigation to themes/settings/Pro/rules/share.
class MenuScreen extends StatefulWidget {
  final DashAudio audio;
  final DashSettings settings;
  const MenuScreen({super.key, required this.audio, required this.settings});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with WidgetsBindingObserver {
  late final StoreService _store;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _store = StoreService();
    _store.init().then((_) {
      if (!mounted) return;
      // Restore Pro from an earlier purchase.
      _store.proPurchased.addListener(_syncPro);
      _syncPro();
      setState(() {});
    });
    widget.audio.configure(
      musicOn: widget.settings.musicOn,
      sfxOn: widget.settings.sfxOn,
      volume: widget.settings.volume,
    );
    widget.audio.startMenuMusic();
    widget.settings.addListener(_refresh);
  }

  void _syncPro() {
    if (_store.proPurchased.value && !widget.settings.isPro) {
      widget.settings.setPro(true);
    }
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.settings.removeListener(_refresh);
    _store.proPurchased.removeListener(_syncPro);
    _store.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      widget.audio.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      widget.audio.onAppResumed();
    }
  }

  void _play() {
    widget.audio.gameStart();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          audio: widget.audio,
          settings: widget.settings,
          store: _store,
        ),
      ),
    );
  }

  void _renameProfile() {
    final c = TextEditingController(text: widget.settings.playerName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Your name'),
        content: TextField(
          controller: c,
          autofocus: true,
          maxLength: 16,
          decoration:
              const InputDecoration(hintText: 'What should we call you?'),
          // Master rule: persist on every keystroke; the final value is
          // committed again when the dialog (and the field's focus) closes.
          onChanged: (v) => widget.settings.setPlayerName(v),
          onSubmitted: (_) => Navigator.of(ctx).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.audio.click();
              widget.settings.setPlayerName(c.text);
              Navigator.of(ctx).pop();
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    ).then((_) {
      // Focus loss / dialog dismissed: commit whatever is in the field.
      widget.settings.setPlayerName(c.text);
      c.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    final theme = DashThemes.byId(s.themeId, custom: s.customTheme);
    final ball = BallStyles.byId(s.ballStyleId, customColor: s.customBallColor);
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo.
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border:
                          Border.all(color: theme.panelEdge, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          offset: const Offset(0, 8),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset('assets/zigzagdash_logo.png',
                        fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 10),
                  Text('ZIGZAG DASH',
                      style: DashText.display(38, color: theme.panelEdge)),
                  const SizedBox(height: 2),
                  Text('HOW LONG CAN YOU STAY ON?',
                      style: DashText.label(12, color: theme.panelEdge)),
                  const SizedBox(height: 12),
                  // Profile chip (tap to rename).
                  GestureDetector(
                    onTap: () {
                      widget.audio.click();
                      _renameProfile();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: theme.hudChip,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: theme.ink.withValues(alpha: 0.4),
                            width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ballDot(ball),
                          const SizedBox(width: 10),
                          Text(s.playerName,
                              style:
                                  DashText.label(16, color: theme.ink)),
                          const SizedBox(width: 6),
                          Icon(Icons.edit,
                              size: 16,
                              color:
                                  theme.ink.withValues(alpha: 0.7)),
                          if (s.isPro) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: theme.star,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('PRO',
                                  style: DashText.label(11,
                                      color: theme.panelEdge)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Mode picker.
                  WoodPanel(
                    panel: theme.panel,
                    edge: theme.panelEdge,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MODE',
                            style: DashText.label(12, color: theme.ink)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                                child: _modeCard(theme, 'ENDLESS',
                                    'Survive as long as you can', false, s)),
                            const SizedBox(width: 8),
                            Expanded(
                                child: _modeCard(theme, 'SCORE ATTACK',
                                    '60 seconds, grab every star', true, s)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text('DIFFICULTY',
                            style: DashText.label(12, color: theme.ink)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            for (int d = 0; d < 3; d++)
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                      right: d < 2 ? 8 : 0),
                                  child: _diffCard(theme, d, s),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _diffBlurb(s.difficulty),
                          style: DashText.body(
                              12,
                              color:
                                  theme.ink.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ChunkyButton(
                    top: theme.accent,
                    edge: theme.panelEdge,
                    height: 66,
                    onTap: _play,
                    child: Text('▶  PLAY',
                        style: DashText.display(26, color: theme.ink)),
                  ),
                  const SizedBox(height: 12),
                  // Best line.
                  Text(
                    'Best: Endless ${s.bestFor(false, s.difficulty)}  •  Attack ${s.bestFor(true, s.difficulty)}',
                    style: DashText.label(12, color: theme.panelEdge),
                  ),
                  const SizedBox(height: 10),
                  // Nav row.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _navBtn(theme, Icons.palette, 'THEMES', () {
                        widget.audio.click();
                        Navigator.of(context)
                            .push(MaterialPageRoute(
                                builder: (_) => SettingsScreen(
                                    audio: widget.audio,
                                    settings: s,
                                    initialTab: 0)))
                            .then((_) => setState(() {}));
                      }),
                      _navBtn(theme, Icons.settings, 'SETUP', () {
                        widget.audio.click();
                        Navigator.of(context)
                            .push(MaterialPageRoute(
                                builder: (_) => SettingsScreen(
                                    audio: widget.audio,
                                    settings: s,
                                    initialTab: 1)))
                            .then((_) => setState(() {}));
                      }),
                      _navBtn(theme, Icons.star, 'PRO', () {
                        widget.audio.click();
                        Navigator.of(context)
                            .push(MaterialPageRoute(
                                builder: (_) => ProScreen(
                                    audio: widget.audio,
                                    settings: s,
                                    store: _store)))
                            .then((_) => setState(() {}));
                      }),
                      _navBtn(theme, Icons.menu_book, 'RULES', () {
                        widget.audio.click();
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => RulesScreen(theme: theme)));
                      }),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/wajiha_logo.png',
                          width: 22, height: 22, fit: BoxFit.contain),
                      const SizedBox(width: 8),
                      Text('Credits: WAJIHA',
                          style: DashText.label(
                              12, color: theme.panelEdge)),
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

  Widget _ballDot(BallStyle b) => Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.4, -0.5),
            colors: [b.light, b.base, b.dark],
          ),
          border: Border.all(color: Colors.black26, width: 1.5),
        ),
      );

  Widget _modeCard(DashTheme theme, String title, String sub, bool attack,
      DashSettings s) {
    final sel = s.scoreAttack == attack;
    return GestureDetector(
      onTap: () {
        widget.audio.click();
        s.setScoreAttack(attack);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: sel
              ? theme.accent
              : Colors.black.withValues(alpha: 0.18),
          border: Border.all(
            color: sel
                ? theme.ink
                : theme.ink.withValues(alpha: 0.35),
            width: sel ? 2.5 : 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(title,
                textAlign: TextAlign.center,
                style: DashText.label(13, color: theme.ink)),
            const SizedBox(height: 3),
            Text(sub,
                textAlign: TextAlign.center,
                style: DashText.body(10,
                    color: theme.ink.withValues(alpha: 0.85))),
          ],
        ),
      ),
    );
  }

  Widget _diffCard(DashTheme theme, int d, DashSettings s) {
    final sel = s.difficulty == d;
    final locked = d == 2 && !s.isPro;
    final names = ['CHILL', 'NORMAL', 'EXTREME'];
    return GestureDetector(
      onTap: () {
        if (locked) {
          widget.audio.invalid();
          Navigator.of(context)
              .push(MaterialPageRoute(
                  builder: (_) => ProScreen(
                      audio: widget.audio,
                      settings: s,
                      store: _store)))
              .then((_) => setState(() {}));
          return;
        }
        widget.audio.click();
        s.setDifficulty(d);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color:
              sel ? theme.accent : Colors.black.withValues(alpha: 0.18),
          border: Border.all(
            color:
                sel ? theme.ink : theme.ink.withValues(alpha: 0.35),
            width: sel ? 2.5 : 1.5,
          ),
        ),
        child: Column(
          children: [
            locked
                ? Icon(Icons.lock,
                    color: theme.ink.withValues(alpha: 0.7), size: 18)
                : Text(['🐢', '🐇', '⚡'][d],
                    style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 3),
            Text(names[d],
                style: DashText.label(11, color: theme.ink)),
          ],
        ),
      ),
    );
  }

  String _diffBlurb(int d) => [
        'Chill: gentle speed, long straightaways. Learn the ropes.',
        'Normal: a brisk dash with regular corners.',
        'Extreme (PRO): blazing fast, tight nonstop corners.',
      ][d.clamp(0, 2)];

  Widget _navBtn(
      DashTheme theme, IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          ChunkyButton(
            small: true,
            height: 54,
            top: theme.panel,
            edge: theme.panelEdge,
            onTap: onTap,
            child: Icon(icon, color: theme.ink, size: 24),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: DashText.label(10, color: theme.panelEdge)),
        ],
      ),
    );
  }
}
