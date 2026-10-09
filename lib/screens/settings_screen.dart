import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/dash_themes.dart';
import '../theme/ui_kit.dart';

/// Settings with two tabs: THEMES (theme grid + ball styles + custom
/// creator) and SETUP (audio, name, difficulty, progress reset).
class SettingsScreen extends StatefulWidget {
  final DashAudio audio;
  final DashSettings settings;
  final int initialTab;
  const SettingsScreen(
      {super.key,
      required this.audio,
      required this.settings,
      this.initialTab = 0});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
        length: 2, vsync: this, initialIndex: widget.initialTab);
    widget.settings.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    widget.settings.removeListener(_refresh);
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    final theme = DashThemes.byId(s.themeId, custom: s.customTheme);
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
                      onTap: () {
                        widget.audio.click();
                        Navigator.of(context).pop();
                      },
                      child: Icon(Icons.arrow_back,
                          color: theme.ink, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Text('CUSTOMIZE',
                        style: DashText.display(26,
                            color: theme.panelEdge)),
                  ],
                ),
              ),
              TabBar(
                controller: _tabs,
                labelColor: theme.panelEdge,
                unselectedLabelColor:
                    theme.panelEdge.withValues(alpha: 0.55),
                indicatorColor: theme.accent,
                labelStyle: DashText.label(14, color: theme.panelEdge),
                tabs: const [
                  Tab(text: 'THEMES'),
                  Tab(text: 'SETUP'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _themesTab(theme, s),
                    _setupTab(theme, s),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------- themes
  Widget _themesTab(DashTheme theme, DashSettings s) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('TRACK THEME',
            style: DashText.label(13, color: theme.panelEdge)),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.6,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: DashThemes.all.length + 1, // + custom creator
          itemBuilder: (ctx, i) {
            if (i == DashThemes.all.length) {
              return _themeCard(theme, s, null);
            }
            return _themeCard(theme, s, DashThemes.all[i]);
          },
        ),
        if (s.themeId == 'custom') ...[
          const SizedBox(height: 12),
          _customThemeEditor(theme, s),
        ],
        const SizedBox(height: 16),
        Text('BALL STYLE',
            style: DashText.label(13, color: theme.panelEdge)),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.05,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: BallStyles.all.length + 1,
          itemBuilder: (ctx, i) {
            if (i == BallStyles.all.length) {
              return _ballCard(theme, s, null);
            }
            return _ballCard(theme, s, BallStyles.all[i]);
          },
        ),
        if (s.ballStyleId == 'custom') ...[
          const SizedBox(height: 12),
          _customBallEditor(theme, s),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _themeCard(DashTheme theme, DashSettings s, DashTheme? t) {
    final isCustom = t == null;
    final id = isCustom ? 'custom' : t.id;
    final locked =
        !s.isPro && (isCustom || DashThemes.isProTheme(id));
    final sel = s.themeId == id;
    final preview = isCustom ? s.customTheme : t;
    return GestureDetector(
      onTap: () {
        if (locked) {
          widget.audio.invalid();
          return;
        }
        widget.audio.click();
        s.setTheme(id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [preview.tileTop, preview.tileSideLeft],
          ),
          border: Border.all(
            color: sel ? theme.accent : theme.panelEdge,
            width: sel ? 3 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              offset: const Offset(0, 3),
              blurRadius: 6,
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                isCustom ? '🎨 My Creation' : t.name,
                textAlign: TextAlign.center,
                style: DashText.label(12, color: Colors.white),
              ),
            ),
            if (locked)
              const Positioned(
                right: 2,
                top: 2,
                child: Icon(Icons.lock,
                    size: 16, color: Colors.white70),
              ),
            if (sel)
              const Positioned(
                right: 2,
                bottom: 2,
                child:
                    Icon(Icons.check_circle, size: 18, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  Widget _ballCard(DashTheme theme, DashSettings s, BallStyle? b) {
    final isCustom = b == null;
    final id = isCustom ? 'custom' : b.id;
    final locked = !s.isPro && (isCustom || BallStyles.isPro(id));
    final sel = s.ballStyleId == id;
    final style = isCustom
        ? BallStyle(
            id: 'custom',
            name: 'My Ball',
            base: s.customBallColor,
            dark: s.customBallColor,
            light: s.customBallColor)
        : b;
    return GestureDetector(
      onTap: () {
        if (locked) {
          widget.audio.invalid();
          return;
        }
        widget.audio.click();
        s.setBallStyle(id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: theme.panel,
          border: Border.all(
            color: sel ? theme.accent : theme.panelEdge,
            width: sel ? 3 : 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.4, -0.5),
                      colors: [
                        style.light,
                        style.base,
                        style.dark
                      ],
                    ),
                    border: Border.all(
                        color: Colors.black26, width: 1.5),
                  ),
                ),
                if (locked)
                  const Icon(Icons.lock,
                      size: 14, color: Colors.white70),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isCustom ? 'My Ball' : b.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: DashText.label(9, color: theme.ink),
            ),
          ],
        ),
      ),
    );
  }

  static const _swatches = [
    0xFFD94F30, 0xFFE07B39, 0xFFFFC93C, 0xFF3B8F4E, 0xFF2B9E8F, 0xFF2B7EB8,
    0xFF8F5EC9, 0xFFE0507E, 0xFFF5EFE0, 0xFF4A4A4E, 0xFFB07F42, 0xFFD9A441,
    0xFF7ED6A0, 0xFF8ED0F2, 0xFFFFA8C4, 0xFF1E2A44,
  ];

  Widget _customThemeEditor(DashTheme theme, DashSettings s) {
    const labels = {
      'tileTop': 'Tile top',
      'tileSideLeft': 'Tile side',
      'tileSideRight': 'Tile shade',
      'tileEdge': 'Tile edge',
      'skyTop': 'Sky top',
      'skyBottom': 'Sky bottom',
      'star': 'Stars',
      'accent': 'Accent',
      'panel': 'Panels',
    };
    return WoodPanel(
      panel: theme.panel,
      edge: theme.panelEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('MY CREATION',
                  style: DashText.label(13, color: theme.ink)),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  widget.audio.click();
                  s.resetCustomColors();
                },
                child: Text('RESET',
                    style: DashText.label(12, color: theme.star)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final e in labels.entries) ...[
            Text(e.value,
                style: DashText.body(12, color: theme.ink)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final sw in _swatches)
                  GestureDetector(
                    onTap: () {
                      widget.audio.click();
                      s.setCustomColor(e.key, sw);
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Color(sw),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: s.customColors[e.key] == sw
                              ? Colors.white
                              : Colors.black26,
                          width: s.customColors[e.key] == sw ? 3 : 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _customBallEditor(DashTheme theme, DashSettings s) {
    return WoodPanel(
      panel: theme.panel,
      edge: theme.panelEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MY BALL COLOR',
              style: DashText.label(13, color: theme.ink)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final sw in _swatches)
                GestureDetector(
                  onTap: () {
                    widget.audio.click();
                    s.setCustomBallColor(Color(sw));
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(sw),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: s.customBallColor.toARGB32() == sw
                            ? Colors.white
                            : Colors.black26,
                        width:
                            s.customBallColor.toARGB32() == sw ? 3 : 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- setup
  Widget _setupTab(DashTheme theme, DashSettings s) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        WoodPanel(
          panel: theme.panel,
          edge: theme.panelEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PROFILE',
                  style: DashText.label(13, color: theme.ink)),
              const SizedBox(height: 8),
              _NameField(
                settings: s,
                audio: widget.audio,
              ),
              const SizedBox(height: 8),
              Text(
                '${s.gamesPlayed} runs played • ⭐ ${s.starsCollected} stars grabbed',
                style: DashText.body(12,
                    color: theme.ink.withValues(alpha: 0.85)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        WoodPanel(
          panel: theme.panel,
          edge: theme.panelEdge,
          child: Column(
            children: [
              ToggleRow(
                title: 'Music',
                subtitle: 'Menu & gameplay tunes',
                value: s.musicOn,
                ink: theme.ink,
                accent: theme.accent,
                onChanged: (v) {
                  s.setMusic(v);
                  widget.audio.configure(
                      musicOn: v, sfxOn: s.sfxOn, volume: s.volume);
                  if (v) {
                    widget.audio.click();
                    widget.audio.startMenuMusic();
                  }
                },
              ),
              const SizedBox(height: 6),
              ToggleRow(
                title: 'Sound FX',
                subtitle: 'Turns, stars & thuds',
                value: s.sfxOn,
                ink: theme.ink,
                accent: theme.accent,
                onChanged: (v) {
                  s.setSfx(v);
                  widget.audio.configure(
                      musicOn: s.musicOn,
                      sfxOn: v,
                      volume: s.volume);
                  widget.audio.click();
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('Volume',
                      style: DashText.label(15, color: theme.ink)),
                  Expanded(
                    child: Slider(
                      value: s.volume,
                      activeColor: theme.accent,
                      onChanged: (v) {
                        s.setVolume(v);
                        widget.audio.configure(
                            musicOn: s.musicOn,
                            sfxOn: s.sfxOn,
                            volume: v);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        WoodPanel(
          panel: theme.panel,
          edge: theme.panelEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DIFFICULTY',
                  style: DashText.label(13, color: theme.ink)),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (int d = 0; d < 3; d++)
                    Expanded(
                      child: Padding(
                        padding:
                            EdgeInsets.only(right: d < 2 ? 8 : 0),
                        child: GestureDetector(
                          onTap: () {
                            if (d == 2 && !s.isPro) {
                              widget.audio.invalid();
                              return;
                            }
                            widget.audio.click();
                            s.setDifficulty(d);
                          },
                          child: AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 120),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(12),
                              color: s.difficulty == d
                                  ? theme.accent
                                  : Colors.black
                                      .withValues(alpha: 0.18),
                              border: Border.all(
                                color: s.difficulty == d
                                    ? theme.ink
                                    : theme.ink
                                        .withValues(alpha: 0.35),
                                width: s.difficulty == d ? 2.5 : 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                d == 2 && !s.isPro
                                    ? Icon(Icons.lock,
                                        size: 18,
                                        color: theme.ink.withValues(
                                            alpha: 0.7))
                                    : Text(['🐢', '🐇', '⚡'][d],
                                        style: const TextStyle(
                                            fontSize: 18)),
                                const SizedBox(height: 2),
                                Text(
                                    ['CHILL', 'NORMAL', 'EXTREME'][d],
                                    style: DashText.label(
                                        10, color: theme.ink)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () {
              widget.audio.click();
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Reset progress?'),
                  content: const Text(
                      'This clears all best scores and stats. Your name and themes stay.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('CANCEL'),
                    ),
                    TextButton(
                      onPressed: () {
                        s.resetProgress();
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('RESET'),
                    ),
                  ],
                ),
              );
            },
            child: Text('Reset progress',
                style: DashText.label(12,
                    color: theme.accent)),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Player-name field that follows the master rule: save on EVERY keystroke
/// into the order-preserving JSON profile string, and commit again on focus
/// loss. The controller/focus node survive rebuilds; the cursor is never
/// reset by external notifies while editing.
class _NameField extends StatefulWidget {
  final DashSettings settings;
  final DashAudio audio;
  const _NameField({required this.settings, required this.audio});

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  late final TextEditingController _c;
  late final FocusNode _focus;
  bool _internalChange = false;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.settings.playerName);
    _focus = FocusNode();
    _focus.addListener(() {
      if (!_focus.hasFocus) {
        // Focus loss: commit whatever is in the field.
        widget.settings.setPlayerName(_c.text);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _NameField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the persisted name changed externally while we are NOT editing,
    // reflect it. Never touch the text while the user is typing.
    if (!_focus.hasFocus &&
        !_internalChange &&
        _c.text != widget.settings.playerName) {
      _c.text = widget.settings.playerName;
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _c,
      focusNode: _focus,
      maxLength: 16,
      style: DashText.body(15, color: Colors.black87),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: 'Your display name',
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.check),
          onPressed: () {
            widget.audio.click();
            widget.settings.setPlayerName(_c.text);
            FocusScope.of(context).unfocus();
          },
        ),
      ),
      onChanged: (v) {
        // Per-keystroke save (mandatory master rule).
        _internalChange = true;
        widget.settings.setPlayerName(v).then((_) {
          _internalChange = false;
        });
      },
      onSubmitted: (_) {
        widget.audio.click();
        FocusScope.of(context).unfocus();
      },
    );
  }
}
