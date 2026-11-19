import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config.dart';
import 'core/connectivity_service.dart';
import 'core/download_service.dart';
import 'core/download_settings.dart';
import 'core/export_service.dart';
import 'core/library_service.dart';
import 'core/providers.dart';
import 'core/theme_settings.dart';
import 'player/player_service.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    await Permission.notification.request();
  }

  final prefs = await SharedPreferences.getInstance();
  final library = LibraryService(prefs);
  await library.initialize();

  final connectivity = ConnectivityService();
  await connectivity.initialize();

  final sources = await ProviderSettingsService.load();
  final quality = await DownloadSettingsService.load();
  final themeSettings = await ThemeSettingsService.load();
  final export = ExportService(prefs);
  final downloads = DownloadService(library, quality);
  final player = PlayerService(connectivity);

  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  runApp(
    SoundBoxApp(
      prefs: prefs,
      connectivity: connectivity,
      library: library,
      downloads: downloads,
      player: player,
      sources: sources,
      export: export,
      quality: quality,
      themeSettings: themeSettings,
    ),
  );
}

class SoundBoxApp extends StatefulWidget {
  const SoundBoxApp({
    super.key,
    required this.prefs,
    required this.connectivity,
    required this.library,
    required this.downloads,
    required this.player,
    required this.sources,
    required this.export,
    required this.quality,
    required this.themeSettings,
  });

  final SharedPreferences prefs;
  final ConnectivityService connectivity;
  final LibraryService library;
  final DownloadService downloads;
  final PlayerService player;
  final ProviderSettingsService sources;
  final ExportService export;
  final DownloadSettingsService quality;
  final ThemeSettingsService themeSettings;

  @override
  State<SoundBoxApp> createState() => _SoundBoxAppState();
}

class _SoundBoxAppState extends State<SoundBoxApp> {
  static const _welcomeKey = 'welcome.accepted';

  late bool _welcomeAccepted;

  @override
  void initState() {
    super.initState();
    _welcomeAccepted = widget.prefs.getBool(_welcomeKey) ?? false;
  }

  Future<void> _acceptWelcome() async {
    await widget.prefs.setBool(_welcomeKey, true);
    if (!mounted) return;
    setState(() => _welcomeAccepted = true);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ConnectivityService>.value(
          value: widget.connectivity,
        ),
        ChangeNotifierProvider<LibraryService>.value(value: widget.library),
        ChangeNotifierProvider<DownloadService>.value(value: widget.downloads),
        ChangeNotifierProvider<PlayerService>.value(value: widget.player),
        ChangeNotifierProvider<ProviderSettingsService>.value(
          value: widget.sources,
        ),
        ChangeNotifierProvider<ExportService>.value(value: widget.export),
        ChangeNotifierProvider<DownloadSettingsService>.value(
          value: widget.quality,
        ),
        ChangeNotifierProvider<ThemeSettingsService>.value(
          value: widget.themeSettings,
        ),
      ],
      child: Consumer<ThemeSettingsService>(
        builder: (context, themeSettings, _) {
          return DynamicColorBuilder(
            builder: (lightDynamic, darkDynamic) {
              final fallback = ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.dark,
              );
              return WallpaperColors(
                light: lightDynamic,
                dark: darkDynamic,
                child: MaterialApp(
                  title: appName,
                  debugShowCheckedModeBanner: false,
                  theme: ThemeData(
                    useMaterial3: true,
                    colorScheme: themeSettings.wallpaperColors
                        ? (darkDynamic ?? fallback)
                        : fallback,
                  ),
                  home: _welcomeAccepted
                      ? const HomeScreen()
                      : WelcomeScreen(onAccepted: _acceptWelcome),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
