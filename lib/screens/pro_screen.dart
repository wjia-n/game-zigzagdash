import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../services/iap_service.dart';
import '../theme/dash_themes.dart';
import '../theme/ui_kit.dart';

/// Pro screen: Free-vs-Pro comparison table, Pro unlock, tip jar, restore.
/// Honest about store state — never shows a fake buy button.
class ProScreen extends StatefulWidget {
  final DashAudio audio;
  final DashSettings settings;
  final StoreService store;
  const ProScreen(
      {super.key,
      required this.audio,
      required this.settings,
      required this.store});

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  @override
  void initState() {
    super.initState();
    widget.store.proPurchased.addListener(_syncPro);
    widget.settings.addListener(_refresh);
    _syncPro();
  }

  void _syncPro() {
    if (widget.store.proPurchased.value && !widget.settings.isPro) {
      widget.settings.setPro(true);
    }
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    widget.store.proPurchased.removeListener(_syncPro);
    widget.settings.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    final store = widget.store;
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
                    Text('ZIGZAG PRO',
                        style: DashText.display(26,
                            color: theme.panelEdge)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (s.isPro)
                      WoodPanel(
                        panel: theme.panel,
                        edge: theme.panelEdge,
                        child: Row(
                          children: [
                            Text('⭐',
                                style: DashText.display(30,
                                    color: theme.ink)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'You are PRO! Every theme, ball, and the Extreme track are yours.',
                                style: DashText.body(14,
                                    color: theme.ink),
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      _comparisonTable(theme),
                      const SizedBox(height: 14),
                      if (!store.storeReady)
                        WoodPanel(
                          panel: theme.panel,
                          edge: theme.panelEdge,
                          child: Text(
                            store.error ??
                                'Pro unlock will be available after the store setup is finished.',
                            textAlign: TextAlign.center,
                            style: DashText.body(13,
                                color: theme.ink),
                          ),
                        )
                      else ...[
                        ChunkyButton(
                          top: theme.accent,
                          edge: theme.panelEdge,
                          height: 62,
                          onTap: store.purchaseInProgress.value
                              ? null
                              : () {
                                  widget.audio.click();
                                  store.buyPro();
                                },
                          child: store.purchaseInProgress.value
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      color: theme.ink,
                                      strokeWidth: 3),
                                )
                              : Text(
                                  'UNLOCK PRO${store.proProduct != null ? ' • ${store.proProduct!.price}' : ''}',
                                  style: DashText.label(
                                      17, color: theme.ink)),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              widget.audio.click();
                              store.restore();
                            },
                            child: Text('Restore purchases',
                                style: DashText.label(
                                    13, color: theme.accent)),
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 8),
                    ValueListenableBuilder<String?>(
                      valueListenable: store.lastThanks,
                      builder: (_, v, __) => v == null
                          ? const SizedBox.shrink()
                          : WoodPanel(
                              panel: theme.panel,
                              edge: theme.panelEdge,
                              child: Text(v,
                                  textAlign: TextAlign.center,
                                  style: DashText.body(
                                      14, color: theme.ink)),
                            ),
                    ),
                    ValueListenableBuilder<String?>(
                      valueListenable: store.purchaseError,
                      builder: (_, v, __) => v == null
                          ? const SizedBox.shrink()
                          : Padding(
                              padding:
                                  const EdgeInsets.only(top: 8),
                              child: Text(v,
                                  textAlign: TextAlign.center,
                                  style: DashText.body(
                                      13,
                                      color: theme.accent)),
                            ),
                    ),
                    const SizedBox(height: 16),
                    Text('TIP JAR',
                        textAlign: TextAlign.center,
                        style: DashText.label(
                            13, color: theme.panelEdge)),
                    const SizedBox(height: 4),
                    Text(
                      'Zigzag Dash is 100% free. Tips keep the tracks coming!',
                      textAlign: TextAlign.center,
                      style: DashText.body(12,
                          color: theme.panelEdge
                              .withValues(alpha: 0.8)),
                    ),
                    const SizedBox(height: 8),
                    if (!store.storeReady)
                      Text(
                        'Tips will appear here after store setup.',
                        textAlign: TextAlign.center,
                        style: DashText.body(12,
                            color: theme.panelEdge
                                .withValues(alpha: 0.7)),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                              child: _tipCard(
                                  theme, store, '☕', store.coffeeProduct)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _tipCard(theme, store, '🍫',
                                  store.chocolateProduct)),
                        ],
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _comparisonTable(DashTheme theme) {
    const rows = [
      ['Endless mode', true, true],
      ['Score Attack mode', true, true],
      ['Chill & Normal tracks', true, true],
      ['EXTREME track', false, true],
      ['12 track themes', true, true],
      ['Midnight Pine & Royal Mahogany', false, true],
      ['Custom theme creator', false, true],
      ['9 ball styles', true, true],
      ['Gold, Bubblegum & Rainbow balls', false, true],
      ['Custom ball color', false, true],
    ];
    return WoodPanel(
      panel: theme.panel,
      edge: theme.panelEdge,
      child: Column(
        children: [
          Row(
            children: [
              const Spacer(),
              SizedBox(
                  width: 52,
                  child: Text('FREE',
                      textAlign: TextAlign.center,
                      style: DashText.label(11, color: theme.ink))),
              SizedBox(
                  width: 52,
                  child: Text('PRO',
                      textAlign: TextAlign.center,
                      style: DashText.label(11, color: theme.star))),
            ],
          ),
          const SizedBox(height: 6),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                      child: Text(r[0] as String,
                          style: DashText.body(
                              13, color: theme.ink))),
                  SizedBox(
                    width: 52,
                    child: Icon(
                      (r[1] as bool) ? Icons.check : Icons.close,
                      color: (r[1] as bool)
                          ? Colors.green.shade300
                          : theme.ink.withValues(alpha: 0.4),
                      size: 18,
                    ),
                  ),
                  SizedBox(
                    width: 52,
                    child: Icon(
                      (r[2] as bool) ? Icons.check : Icons.close,
                      color: (r[2] as bool)
                          ? theme.star
                          : theme.ink.withValues(alpha: 0.4),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _tipCard(DashTheme theme, StoreService store, String emoji,
      dynamic product) {
    final price = product?.price as String?;
    return ChunkyButton(
      small: true,
      height: 64,
      top: theme.panel,
      edge: theme.panelEdge,
      onTap: product == null || store.purchaseInProgress.value
          ? null
          : () {
              widget.audio.click();
              store.buyTip(product);
            },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          Text('TIP${price != null ? ' • $price' : ''}',
              style: DashText.label(11, color: theme.ink)),
        ],
      ),
    );
  }
}
