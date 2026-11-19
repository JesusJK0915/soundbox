import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/artwork_palette_service.dart';
import 'core/config.dart';
import 'core/connectivity_service.dart';
import 'core/download_service.dart';
import 'core/download_settings.dart';
import 'core/export_service.dart';
import 'core/library_service.dart';
import 'core/providers.dart';
import 'core/theme_settings.dart';
import 'core/update_service.dart';
import 'core/user_preferences.dart';
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
  final artworkPalette = ArtworkPaletteService();
  final userPrefs = await UserPreferencesService.load();
  final updates = UpdateService(prefs);
  final export = ExportService(prefs);
  final downloads = DownloadService(library, quality);
  final player = PlayerService(connectivity, userPrefs);

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
      artworkPalette: artworkPalette,
      userPrefs: userPrefs,
      updates: updates,
    ),
  );

  // Las pistas importadas en versiones anteriores se enriquecen en segundo
  // plano para no retrasar el arranque.
  unawaited(library.refreshMetadata());
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
    required this.artworkPalette,
    required this.userPrefs,
    required this.updates,
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
  final ArtworkPaletteService artworkPalette;
  final UserPreferencesService userPrefs;
  final UpdateService updates;

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
        ChangeNotifierProvider<ArtworkPaletteService>.value(
          value: widget.artworkPalette,
        ),
        ChangeNotifierProvider<UserPreferencesService>.value(
          value: widget.userPrefs,
        ),
        ChangeNotifierProvider<UpdateService>.value(value: widget.updates),
      ],
      child: Consumer2<ThemeSettingsService, UserPreferencesService>(
        builder: (context, themeSettings, userPrefs, _) {
          return DynamicColorBuilder(
            builder: (lightDynamic, darkDynamic) {
              final platformBrightness =
                  WidgetsBinding.instance.platformDispatcher.platformBrightness;
              final brightness = switch (userPrefs.themeMode) {
                AppThemeMode.system => platformBrightness,
                AppThemeMode.light => Brightness.light,
                AppThemeMode.dark => Brightness.dark,
              };
              final seed = Colors.deepPurple;
              final lightFallback = ColorScheme.fromSeed(
                seedColor: seed,
                brightness: Brightness.light,
              );
              final darkFallback = ColorScheme.fromSeed(
                seedColor: seed,
                brightness: Brightness.dark,
              );
              final selectedDynamic = themeSettings.wallpaperColors
                  ? (brightness == Brightness.dark ? darkDynamic : lightDynamic)
                  : null;

              return WallpaperColors(
                light: lightDynamic,
                dark: darkDynamic,
                child: MaterialApp(
                  title: appName,
                  debugShowCheckedModeBanner: false,
                  theme: ThemeData(
                    useMaterial3: true,
                    brightness: Brightness.light,
                    colorScheme: selectedDynamic ?? lightFallback,
                  ),
                  darkTheme: ThemeData(
                    useMaterial3: true,
                    brightness: Brightness.dark,
                    colorScheme: (themeSettings.wallpaperColors
                            ? darkDynamic
                            : null) ??
                        darkFallback,
                  ),
                  themeMode: switch (userPrefs.themeMode) {
                    AppThemeMode.system => ThemeMode.system,
                    AppThemeMode.light => ThemeMode.light,
                    AppThemeMode.dark => ThemeMode.dark,
                  },
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
