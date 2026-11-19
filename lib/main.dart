import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config.dart';
import 'core/connectivity_service.dart';
import 'core/download_service.dart';
import 'core/library_service.dart';
import 'player/player_service.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final library = LibraryService(prefs);
  await library.initialize();

  final connectivity = ConnectivityService();
  await connectivity.initialize();

  final downloads = DownloadService(library);
  final player = PlayerService(connectivity);

  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  runApp(
    SoundBoxApp(
      connectivity: connectivity,
      library: library,
      downloads: downloads,
      player: player,
    ),
  );
}

class SoundBoxApp extends StatelessWidget {
  final ConnectivityService connectivity;
  final LibraryService library;
  final DownloadService downloads;
  final PlayerService player;

  const SoundBoxApp({
    super.key,
    required this.connectivity,
    required this.library,
    required this.downloads,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ConnectivityService>.value(value: connectivity),
        ChangeNotifierProvider<LibraryService>.value(value: library),
        ChangeNotifierProvider<DownloadService>.value(value: downloads),
        ChangeNotifierProvider<PlayerService>.value(value: player),
      ],
      child: MaterialApp(
        title: appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
