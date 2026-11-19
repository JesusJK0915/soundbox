import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/connectivity_service.dart';
import '../core/library_service.dart';
import '../widgets/mini_player.dart';
import 'downloads_screen.dart';
import 'library_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  late final List<Widget> _pages = const [
    LibraryScreen(),
    SearchScreen(),
    DownloadsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SoundBox'),
        actions: [
          Consumer<ConnectivityService>(
            builder: (context, connectivity, _) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(
                connectivity.isOnline ? Icons.wifi : Icons.wifi_off,
                color: connectivity.isOnline ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _index == 0 ? const _LibraryFab() : null,
      body: Column(
        children: [
          Consumer<ConnectivityService>(
            builder: (context, connectivity, _) {
              if (connectivity.isOnline) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                color: Colors.orange.shade900,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: const Text(
                  'Sin conexion: solo biblioteca local disponible',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              );
            },
          ),
          Expanded(child: IndexedStack(index: _index, children: _pages)),
          const MiniPlayer(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music),
            label: 'Biblioteca',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Buscar',
          ),
          NavigationDestination(
            icon: Icon(Icons.download_outlined),
            selectedIcon: Icon(Icons.download),
            label: 'Descargas',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}

class _LibraryFab extends StatelessWidget {
  const _LibraryFab();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      tooltip: 'Importar musica',
      onPressed: () => context.read<LibraryService>().importFiles(),
      child: const Icon(Icons.audiotrack),
    );
  }
}
