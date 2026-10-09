import 'package:flutter/material.dart';

/// Theme catalog for Zigzag Dash. Pseudo-3D physical-material art direction:
/// every theme is a chunky wooden-toy world — light top face, shaded side
/// faces, warm backgrounds. No neon, no cyberpunk, no AI-dashboard looks.
class DashTheme {
  final String id;
  final String name;
  final bool pro;
  // Tile block faces.
  final Color tileTop;
  final Color tileSideLeft;
  final Color tileSideRight;
  final Color tileEdge;
  final Color cornerMark;
  // Sky.
  final Color skyTop;
  final Color skyBottom;
  final Color cloud;
  // Accents.
  final Color star;
  final Color accent;
  final Color panel;
  final Color panelEdge;
  final Color ink; // text on panels
  final Color hudChip;
  const DashTheme({
    required this.id,
    required this.name,
    this.pro = false,
    required this.tileTop,
    required this.tileSideLeft,
    required this.tileSideRight,
    required this.tileEdge,
    required this.cornerMark,
    required this.skyTop,
    required this.skyBottom,
    required this.cloud,
    required this.star,
    required this.accent,
    required this.panel,
    required this.panelEdge,
    required this.ink,
    required this.hudChip,
  });
}

class DashThemes {
  static const List<DashTheme> all = [
    DashTheme(
      id: 'classic_oak',
      name: 'Classic Oak',
      tileTop: Color(0xFFC89B62),
      tileSideLeft: Color(0xFF8F6335),
      tileSideRight: Color(0xFF6E4A24),
      tileEdge: Color(0xFF54371A),
      cornerMark: Color(0xFF7A5228),
      skyTop: Color(0xFFBFE3EF),
      skyBottom: Color(0xFFF6E8C8),
      cloud: Color(0xFFFFFFFF),
      star: Color(0xFFFFC93C),
      accent: Color(0xFFD94F30),
      panel: Color(0xFF7A4E2A),
      panelEdge: Color(0xFF54371A),
      ink: Color(0xFFFFF6E6),
      hudChip: Color(0xB354371A),
    ),
    DashTheme(
      id: 'maple_morning',
      name: 'Maple Morning',
      tileTop: Color(0xFFE3B877),
      tileSideLeft: Color(0xFFB07F42),
      tileSideRight: Color(0xFF8F6230),
      tileEdge: Color(0xFF6E4A20),
      cornerMark: Color(0xFF9A6A34),
      skyTop: Color(0xFFFFF3D6),
      skyBottom: Color(0xFFFFD9A0),
      cloud: Color(0xFFFFFFFF),
      star: Color(0xFFFF9E2C),
      accent: Color(0xFFE07B39),
      panel: Color(0xFF8F6230),
      panelEdge: Color(0xFF6E4A20),
      ink: Color(0xFFFFF9EC),
      hudChip: Color(0xB36E4A20),
    ),
    DashTheme(
      id: 'cherry_wood',
      name: 'Cherry Wood',
      tileTop: Color(0xFFB4643C),
      tileSideLeft: Color(0xFF843E20),
      tileSideRight: Color(0xFF682D16),
      tileEdge: Color(0xFF4E2010),
      cornerMark: Color(0xFF8F4526),
      skyTop: Color(0xFFFFDCD2),
      skyBottom: Color(0xFFFFEFE3),
      cloud: Color(0xFFFFFFFF),
      star: Color(0xFFFFD93C),
      accent: Color(0xFFC23B3B),
      panel: Color(0xFF682D16),
      panelEdge: Color(0xFF4E2010),
      ink: Color(0xFFFFEFE0),
      hudChip: Color(0xB34E2010),
    ),
    DashTheme(
      id: 'walnut_night',
      name: 'Walnut Night',
      tileTop: Color(0xFF7C5A3E),
      tileSideLeft: Color(0xFF54402C),
      tileSideRight: Color(0xFF3E2F20),
      tileEdge: Color(0xFF2B2115),
      cornerMark: Color(0xFF63503A),
      skyTop: Color(0xFF1E2A44),
      skyBottom: Color(0xFF3B4A6E),
      cloud: Color(0xFF8FA3C7),
      star: Color(0xFFFFD76A),
      accent: Color(0xFFFFB347),
      panel: Color(0xFF3E2F20),
      panelEdge: Color(0xFF2B2115),
      ink: Color(0xFFF3E7D3),
      hudChip: Color(0xB32B2115),
    ),
    DashTheme(
      id: 'bamboo_garden',
      name: 'Bamboo Garden',
      tileTop: Color(0xFFC9D98A),
      tileSideLeft: Color(0xFF8AA14F),
      tileSideRight: Color(0xFF6B7F3B),
      tileEdge: Color(0xFF4F5E2A),
      cornerMark: Color(0xFF7E9348),
      skyTop: Color(0xFFDFF3D8),
      skyBottom: Color(0xFFFFF6DC),
      cloud: Color(0xFFFFFFFF),
      star: Color(0xFFFFC93C),
      accent: Color(0xFF4F8F3B),
      panel: Color(0xFF5E7033),
      panelEdge: Color(0xFF4F5E2A),
      ink: Color(0xFFFBF7E4),
      hudChip: Color(0xB34F5E2A),
    ),
    DashTheme(
      id: 'sandstone',
      name: 'Sandstone Desert',
      tileTop: Color(0xFFE0B96F),
      tileSideLeft: Color(0xFFB08A46),
      tileSideRight: Color(0xFF8F6A33),
      tileEdge: Color(0xFF6B4E22),
      cornerMark: Color(0xFF9E7A3C),
      skyTop: Color(0xFF9ADCF0),
      skyBottom: Color(0xFFFFE3A8),
      cloud: Color(0xFFFFFFFF),
      star: Color(0xFFFF8A3C),
      accent: Color(0xFFC46A2B),
      panel: Color(0xFF8F6A33),
      panelEdge: Color(0xFF6B4E22),
      ink: Color(0xFFFFF6E2),
      hudChip: Color(0xB36B4E22),
    ),
    DashTheme(
      id: 'candy_shop',
      name: 'Candy Shop',
      tileTop: Color(0xFFF6C6D8),
      tileSideLeft: Color(0xFFD68FAE),
      tileSideRight: Color(0xFFB56E8E),
      tileEdge: Color(0xFF8F5270),
      cornerMark: Color(0xFFE09EBD),
      skyTop: Color(0xFFFFE9F2),
      skyBottom: Color(0xFFFFF8E6),
      cloud: Color(0xFFFFFFFF),
      star: Color(0xFFFF9E5E),
      accent: Color(0xFFE0507E),
      panel: Color(0xFFB56E8E),
      panelEdge: Color(0xFF8F5270),
      ink: Color(0xFFFFF3F8),
      hudChip: Color(0xB38F5270),
    ),
    DashTheme(
      id: 'slate_quarry',
      name: 'Slate Quarry',
      tileTop: Color(0xFFA8B0B8),
      tileSideLeft: Color(0xFF707880),
      tileSideRight: Color(0xFF585F66),
      tileEdge: Color(0xFF40464C),
      cornerMark: Color(0xFF7E868E),
      skyTop: Color(0xFFC9D6DE),
      skyBottom: Color(0xFFEDF1F2),
      cloud: Color(0xFFFFFFFF),
      star: Color(0xFFFFC93C),
      accent: Color(0xFF4F6E8F),
      panel: Color(0xFF585F66),
      panelEdge: Color(0xFF40464C),
      ink: Color(0xFFF2F5F6),
      hudChip: Color(0xB340464C),
    ),
    DashTheme(
      id: 'mossy_forest',
      name: 'Mossy Forest',
      tileTop: Color(0xFF8FAE6B),
      tileSideLeft: Color(0xFF5E7A42),
      tileSideRight: Color(0xFF475E31),
      tileEdge: Color(0xFF33431F),
      cornerMark: Color(0xFF6E8F4E),
      skyTop: Color(0xFFCFE8C0),
      skyBottom: Color(0xFFFFF2CC),
      cloud: Color(0xFFFFFFFF),
      star: Color(0xFFFFD93C),
      accent: Color(0xFF7A4E2A),
      panel: Color(0xFF475E31),
      panelEdge: Color(0xFF33431F),
      ink: Color(0xFFF6F3E2),
      hudChip: Color(0xB333431F),
    ),
    DashTheme(
      id: 'terracotta',
      name: 'Terracotta',
      tileTop: Color(0xFFD88A5E),
      tileSideLeft: Color(0xFFA55F38),
      tileSideRight: Color(0xFF83482A),
      tileEdge: Color(0xFF63351D),
      cornerMark: Color(0xFFB06A42),
      skyTop: Color(0xFFFFE4C4),
      skyBottom: Color(0xFFFFF7E8),
      cloud: Color(0xFFFFFFFF),
      star: Color(0xFFFFE066),
      accent: Color(0xFF8F3B2B),
      panel: Color(0xFF83482A),
      panelEdge: Color(0xFF63351D),
      ink: Color(0xFFFFF1E0),
      hudChip: Color(0xB363351D),
    ),
    DashTheme(
      id: 'driftwood',
      name: 'Ocean Driftwood',
      tileTop: Color(0xFFA9C6CE),
      tileSideLeft: Color(0xFF6E94A0),
      tileSideRight: Color(0xFF55747E),
      tileEdge: Color(0xFF3E585F),
      cornerMark: Color(0xFF7FA3AD),
      skyTop: Color(0xFFBDE8F2),
      skyBottom: Color(0xFFFFF3D0),
      cloud: Color(0xFFFFFFFF),
      star: Color(0xFFFFB13C),
      accent: Color(0xFF2B6E8F),
      panel: Color(0xFF55747E),
      panelEdge: Color(0xFF3E585F),
      ink: Color(0xFFEFF8FA),
      hudChip: Color(0xB33E585F),
    ),
    DashTheme(
      id: 'autumn_harvest',
      name: 'Autumn Harvest',
      tileTop: Color(0xFFDE9E4E),
      tileSideLeft: Color(0xFFA96F2E),
      tileSideRight: Color(0xFF86551F),
      tileEdge: Color(0xFF633D14),
      cornerMark: Color(0xFFB87E38),
      skyTop: Color(0xFFFFD9A8),
      skyBottom: Color(0xFFFFF0D8),
      cloud: Color(0xFFFFFFFF),
      star: Color(0xFFFF4E3C),
      accent: Color(0xFFA03B2B),
      panel: Color(0xFF86551F),
      panelEdge: Color(0xFF633D14),
      ink: Color(0xFFFFF4E2),
      hudChip: Color(0xB3633D14),
    ),
    DashTheme(
      id: 'midnight_pine',
      name: 'Midnight Pine',
      pro: true,
      tileTop: Color(0xFF4E6E5E),
      tileSideLeft: Color(0xFF33493D),
      tileSideRight: Color(0xFF24352B),
      tileEdge: Color(0xFF18241D),
      cornerMark: Color(0xFF5E7E6C),
      skyTop: Color(0xFF101C2E),
      skyBottom: Color(0xFF2E3E5E),
      cloud: Color(0xFF7E94B5),
      star: Color(0xFFFFE066),
      accent: Color(0xFF7ED6A0),
      panel: Color(0xFF24352B),
      panelEdge: Color(0xFF18241D),
      ink: Color(0xFFEAF3EA),
      hudChip: Color(0xB318241D),
    ),
    DashTheme(
      id: 'royal_mahogany',
      name: 'Royal Mahogany',
      pro: true,
      tileTop: Color(0xFF9E4E3C),
      tileSideLeft: Color(0xFF6E3226),
      tileSideRight: Color(0xFF55251C),
      tileEdge: Color(0xFF3E1912),
      cornerMark: Color(0xFFAE5E48),
      skyTop: Color(0xFF3E2438),
      skyBottom: Color(0xFF6E3E4E),
      cloud: Color(0xFFC49EAE),
      star: Color(0xFFFFD76A),
      accent: Color(0xFFD9A441),
      panel: Color(0xFF55251C),
      panelEdge: Color(0xFF3E1912),
      ink: Color(0xFFF8EAD8),
      hudChip: Color(0xB33E1912),
    ),
  ];

  static DashTheme byId(String id, {required DashTheme custom}) {
    if (id == 'custom') return custom;
    for (final t in all) {
      if (t.id == id) return t;
    }
    return all.first;
  }

  static bool isProTheme(String id) =>
      all.any((t) => t.id == id && t.pro);
}

/// Ball styles — physical marbles/toys with real material response.
class BallStyle {
  final String id;
  final String name;
  final bool pro;
  final Color base;
  final Color dark;
  final Color light;
  final BallPattern pattern;
  const BallStyle({
    required this.id,
    required this.name,
    this.pro = false,
    required this.base,
    required this.dark,
    required this.light,
    this.pattern = BallPattern.solid,
  });
}

enum BallPattern { solid, marble, wood, stripe, swirl }

class BallStyles {
  static const List<BallStyle> all = [
    BallStyle(id: 'ruby', name: 'Ruby Marble', base: Color(0xFFD94F30), dark: Color(0xFF8F2A1A), light: Color(0xFFFF9E7E), pattern: BallPattern.marble),
    BallStyle(id: 'ocean', name: 'Ocean Marble', base: Color(0xFF2B7EB8), dark: Color(0xFF1A4E78), light: Color(0xFF8ED0F2), pattern: BallPattern.marble),
    BallStyle(id: 'forest', name: 'Forest Marble', base: Color(0xFF3B8F4E), dark: Color(0xFF22592E), light: Color(0xFF9EDBA8), pattern: BallPattern.marble),
    BallStyle(id: 'sunny', name: 'Sunny Toy', base: Color(0xFFFFC93C), dark: Color(0xFFB8871E), light: Color(0xFFFFE89E), pattern: BallPattern.solid),
    BallStyle(id: 'ivory', name: 'Ivory', base: Color(0xFFF5EFE0), dark: Color(0xFFB8AE98), light: Color(0xFFFFFFFF), pattern: BallPattern.solid),
    BallStyle(id: 'charcoal', name: 'Charcoal', base: Color(0xFF4A4A4E), dark: Color(0xFF26262A), light: Color(0xFF9E9EA6), pattern: BallPattern.solid),
    BallStyle(id: 'sunset', name: 'Sunset Swirl', base: Color(0xFFE07B39), dark: Color(0xFF9E4E1E), light: Color(0xFFFFC98E), pattern: BallPattern.swirl),
    BallStyle(id: 'teal', name: 'Teal Stripe', base: Color(0xFF2B9E8F), dark: Color(0xFF1A6359), light: Color(0xFF8EDCD0), pattern: BallPattern.stripe),
    BallStyle(id: 'wood', name: 'Wooden Bead', base: Color(0xFFB07F42), dark: Color(0xFF7A5228), light: Color(0xFFE3B877), pattern: BallPattern.wood),
    BallStyle(id: 'bubblegum', name: 'Bubblegum', pro: true, base: Color(0xFFE0507E), dark: Color(0xFF9E2E54), light: Color(0xFFFFA8C4), pattern: BallPattern.solid),
    BallStyle(id: 'gold', name: 'Trophy Gold', pro: true, base: Color(0xFFD9A441), dark: Color(0xFF8F6A22), light: Color(0xFFFFE89E), pattern: BallPattern.marble),
    BallStyle(id: 'rainbow', name: 'Rainbow Marble', pro: true, base: Color(0xFF8F5EC9), dark: Color(0xFF5E3A8F), light: Color(0xFFC9A8F2), pattern: BallPattern.swirl),
  ];

  static BallStyle byId(String id, {required Color customColor}) {
    if (id == 'custom') {
      return BallStyle(
        id: 'custom',
        name: 'My Ball',
        base: customColor,
        dark: Color.lerp(customColor, const Color(0xFF000000), 0.45)!,
        light: Color.lerp(customColor, const Color(0xFFFFFFFF), 0.45)!,
      );
    }
    for (final b in all) {
      if (b.id == id) return b;
    }
    return all.first;
  }

  static bool isPro(String id) => all.any((b) => b.id == id && b.pro);
}
