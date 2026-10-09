import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'services/audio_service.dart';
import 'services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = DashSettings();
  await settings.load();
  final audio = DashAudio();
  audio.configure(
    musicOn: settings.musicOn,
    sfxOn: settings.sfxOn,
    volume: settings.volume,
  );
  runApp(ZigzagDashApp(audio: audio, settings: settings));
}

class ZigzagDashApp extends StatelessWidget {
  final DashAudio audio;
  final DashSettings settings;
  const ZigzagDashApp(
      {super.key, required this.audio, required this.settings});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zigzag Dash',
      debugShowCheckedModeBanner: false,
      home: SplashScreen(audio: audio, settings: settings),
    );
  }
}
