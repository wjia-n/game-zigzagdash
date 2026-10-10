import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/dash_themes.dart';

/// Persisted profile + settings for Zigzag Dash, stored as ONE JSON string.
///
/// Order-safe: Android's SharedPreferences stores StringLists as an unordered
/// StringSet, so the profile (incl. the player name) lives in a single JSON
/// string under [_kProfile]. NEVER use setStringList for profile data.
class DashSettings extends ChangeNotifier {
  static const _kProfile = 'zigzagdash_profile_json';
  // Legacy keys migrated one time (then removed).
  static const _kLegacyNamesJson = 'zigzagdash_player_names_json';
  static const _kLegacyNames = 'zigzagdash_player_names';
  static const _kLegacyMusic = 'zigzagdash_music_on';
  static const _kLegacySfx = 'zigzagdash_sfx_on';
  static const _kLegacyVolume = 'zigzagdash_volume';
  static const _kLegacyTheme = 'zigzagdash_theme';

  static const defaultName = 'Player';

  // ---- profile ----
  String playerName = defaultName;
  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  String themeId = 'classic_oak';
  String ballStyleId = 'ruby';
  Color customBallColor = const Color(0xFFD94F30);
  int difficulty = 1; // 0 chill, 1 normal, 2 extreme (2 = Pro)
  bool scoreAttack = false;
  bool isPro = true; // everything unlocked — no Pro version
  Map<String, int> bests = {}; // '<mode>_<diff>' -> score
  int starsCollected = 0;
  int gamesPlayed = 0;

  /// Custom theme colors (ARGB ints), the Pro custom-creator palette.
  Map<String, int> customColors = Map.of(_defaultCustomColors);

  static const Map<String, int> _defaultCustomColors = {
    'tileTop': 0xFFC89B62,
    'tileSideLeft': 0xFF8F6335,
    'tileSideRight': 0xFF6E4A24,
    'tileEdge': 0xFF54371A,
    'cornerMark': 0xFF7A5228,
    'skyTop': 0xFFBFE3EF,
    'skyBottom': 0xFFF6E8C8,
    'cloud': 0xFFFFFFFF,
    'star': 0xFFFFC93C,
    'accent': 0xFFD94F30,
    'panel': 0xFF7A4E2A,
    'panelEdge': 0xFF54371A,
    'ink': 0xFFFFF6E6,
    'hudChip': 0xB354371A,
  };

  DashTheme get customTheme {
    Color c(String k) => Color(customColors[k] ?? 0xFF000000);
    return DashTheme(
      id: 'custom',
      name: 'My Creation',
      tileTop: c('tileTop'),
      tileSideLeft: c('tileSideLeft'),
      tileSideRight: c('tileSideRight'),
      tileEdge: c('tileEdge'),
      cornerMark: c('cornerMark'),
      skyTop: c('skyTop'),
      skyBottom: c('skyBottom'),
      cloud: c('cloud'),
      star: c('star'),
      accent: c('accent'),
      panel: c('panel'),
      panelEdge: c('panelEdge'),
      ink: c('ink'),
      hudChip: c('hudChip'),
    );
  }

  SharedPreferences? _prefs;

  Map<String, dynamic> _toJson() => {
        'v': 1,
        'name': playerName,
        'musicOn': musicOn,
        'sfxOn': sfxOn,
        'volume': volume,
        'themeId': themeId,
        'ballStyleId': ballStyleId,
        'customBallColor': customBallColor.toARGB32(),
        'difficulty': difficulty,
        'scoreAttack': scoreAttack,
        'isPro': isPro,
        'bests': bests,
        'starsCollected': starsCollected,
        'gamesPlayed': gamesPlayed,
        'customColors': customColors,
      };

  void _fromJson(Map<String, dynamic> j) {
    String s(Object? v, String d) => v is String ? v : d;
    bool b(Object? v, bool d) => v is bool ? v : d;
    playerName = s(j['name'], defaultName).trim();
    if (playerName.isEmpty) playerName = defaultName;
    musicOn = b(j['musicOn'], true);
    sfxOn = b(j['sfxOn'], true);
    final vol = j['volume'];
    volume = vol is num ? vol.toDouble().clamp(0.0, 1.0) : 0.8;
    themeId = s(j['themeId'], 'classic_oak');
    ballStyleId = s(j['ballStyleId'], 'ruby');
    final cbc = j['customBallColor'];
    if (cbc is int) customBallColor = Color(cbc);
    final d = j['difficulty'];
    difficulty = d is int ? d.clamp(0, 2) : 1;
    scoreAttack = b(j['scoreAttack'], false);
    isPro = b(j['isPro'], false);
    final bj = j['bests'];
    if (bj is Map) {
      bests = {for (final e in bj.entries) e.key.toString(): (e.value is int ? e.value as int : 0)};
    }
    final sc = j['starsCollected'];
    starsCollected = sc is int ? sc : 0;
    final gp = j['gamesPlayed'];
    gamesPlayed = gp is int ? gp : 0;
    final cc = j['customColors'];
    if (cc is Map) {
      for (final k in _defaultCustomColors.keys) {
        final v = cc[k];
        if (v is int) customColors[k] = v;
      }
    }
  }

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    final raw = p.getString(_kProfile);
    if (raw != null) {
      try {
        final d = jsonDecode(raw);
        if (d is Map<String, dynamic>) _fromJson(d);
      } catch (_) {}
    } else {
      _migrateLegacy(p);
    }
    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  /// One-time migration from any legacy keys the old shell may have left.
  void _migrateLegacy(SharedPreferences p) {
    String? name;
    final nj = p.getString(_kLegacyNamesJson);
    if (nj != null) {
      try {
        final d = jsonDecode(nj);
        if (d is List && d.isNotEmpty && d.first is String) {
          name = (d.first as String).trim();
        }
      } catch (_) {}
    }
    name ??= () {
      final l = p.getStringList(_kLegacyNames);
      if (l != null && l.isNotEmpty) return l.first.trim();
      return null;
    }();
    if (name != null && name.isNotEmpty) playerName = name;
    musicOn = p.getBool(_kLegacyMusic) ?? true;
    sfxOn = p.getBool(_kLegacySfx) ?? true;
    volume = (p.getDouble(_kLegacyVolume) ?? 0.8).clamp(0.0, 1.0);
    final lt = p.getString(_kLegacyTheme);
    if (lt != null && lt.isNotEmpty) themeId = lt;
    for (final k in [
      _kLegacyNamesJson,
      _kLegacyNames,
      _kLegacyMusic,
      _kLegacySfx,
      _kLegacyVolume,
      _kLegacyTheme,
    ]) {
      p.remove(k);
    }
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setString(_kProfile, jsonEncode(_toJson()));
  }

  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    if (themeId == 'custom' || DashThemes.isProTheme(themeId)) {
      themeId = 'classic_oak';
      changed = true;
    }
    if (ballStyleId == 'custom' || BallStyles.isPro(ballStyleId)) {
      ballStyleId = 'ruby';
      changed = true;
    }
    if (difficulty > 1) {
      difficulty = 1;
      changed = true;
    }
    if (changed && !silent) {
      notifyListeners();
      _save();
    }
  }

  // ------------------------------------------------------------- mutations
  Future<void> setPlayerName(String v) async {
    final clean = v.trim();
    playerName = clean.isEmpty ? defaultName : clean;
    notifyListeners();
    await _save();
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  Future<void> setTheme(String id) async {
    if (!isPro && (id == 'custom' || DashThemes.isProTheme(id))) return;
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setBallStyle(String id) async {
    if (!isPro && (id == 'custom' || BallStyles.isPro(id))) return;
    ballStyleId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setCustomBallColor(Color c) async {
    if (!isPro) return;
    customBallColor = c;
    if (ballStyleId != 'custom') ballStyleId = 'custom';
    notifyListeners();
    await _save();
  }

  Future<void> setCustomColor(String key, int argb) async {
    if (!isPro || !_defaultCustomColors.containsKey(key)) return;
    customColors[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomColors() async {
    customColors = Map.of(_defaultCustomColors);
    notifyListeners();
    await _save();
  }

  Future<void> setDifficulty(int d) async {
    d = d.clamp(0, 2);
    if (!isPro && d > 1) return; // Extreme is a Pro feature
    difficulty = d;
    notifyListeners();
    await _save();
  }

  Future<void> setScoreAttack(bool v) async {
    scoreAttack = v;
    notifyListeners();
    await _save();
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save();
  }

  String bestKey(bool attack, int diff) => '${attack ? 'attack' : 'classic'}_$diff';

  int bestFor(bool attack, int diff) => bests[bestKey(attack, diff)] ?? 0;

  /// Record a finished run. Returns true if it is a new best.
  Future<bool> recordRun({
    required bool scoreAttack,
    required int difficulty,
    required int score,
    required int stars,
  }) async {
    gamesPlayed++;
    starsCollected += stars;
    final key = bestKey(scoreAttack, difficulty);
    final isBest = score > (bests[key] ?? 0);
    if (isBest) bests[key] = score;
    notifyListeners();
    await _save();
    return isBest;
  }

  Future<void> resetProgress() async {
    bests = {};
    starsCollected = 0;
    gamesPlayed = 0;
    notifyListeners();
    await _save();
  }
}
