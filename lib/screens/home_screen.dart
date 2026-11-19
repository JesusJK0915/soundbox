import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/connectivity_service.dart';
import '../core/library_service.dart';
import '../core/update_service.dart';
import '../core/user_preferences.dart';
import '../widgets/floating_dock.dart';
import '../widgets/update_dialog.dart';
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
  double _direction = 1;
  UpdateService? _updates;

  late final List<Widget> _pages = const [
    LibraryScreen(),
    SearchScreen(),
    DownloadsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final updates = context.read<UpdateService>();
      _updates = updates;
      updates.addListener(_maybePromptUpdate);
      unawaited(updates.checkIfNeeded());
      _maybePromptUpdate();
    });
  }

  void _maybePromptUpdate() {
    final updates = _updates;
    if (!mounted || updates == null || !updates.shouldPrompt) return;
    updates.markPromptShown();
    unawaited(showUpdateDialog(context));
  }

  @override
  void dispose() {
    _updates?.removeListener(_maybePromptUpdate);
    super.dispose();
  }

  void _goTo(int index) {
    if (index == _index) return;
    final prefs = context.read<UserPreferencesService>();
    if (prefs.haptics) HapticFeedback.selectionClick();
    setState(() {
      _direction = index > _index ? 1 : -1;
      _index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserPreferencesService>(
      builder: (context, prefs, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('SoundBox'),
            actions: [
              Consumer<ConnectivityService>(
                builder: (context, connectivity, _) => AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: connectivity.isOnline
                        ? Colors.green.withOpacity(0.14)
                        : Colors.red.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        connectivity.isOnline ? Icons.wifi : Icons.wifi_off,
                        size: 16,
                        color: connectivity.isOnline
                            ? Colors.green
                            : Colors.red,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        connectivity.isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 11,
                          color: connectivity.isOnline
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: _index == 0 ? const _LibraryFab() : null,
          body: GestureDetector(
            onHorizontalDragEnd: (details) {
              if (!prefs.gestures) return;
              final velocity = details.primaryVelocity ?? 0;
              if (velocity.abs() < 350) return;
              if (velocity < 0 && _index < _pages.length - 1) {
                _goTo(_index + 1);
              } else if (velocity > 0 && _index > 0) {
                _goTo(_index - 1);
              }
            },
            child: Column(
              children: [
                Consumer<ConnectivityService>(
                  builder: (context, connectivity, _) => AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    child: connectivity.isOnline
                        ? const SizedBox.shrink()
                        : Container(
                            width: double.infinity,
                            color: Colors.orange.shade900,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: const Text(
                              'Sin conexion: solo biblioteca local disponible',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 340),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: Offset(_direction * 0.12, 0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child: KeyedSubtree(
                            key: ValueKey<int>(_index),
                            child: _pages[_index],
                          ),
                        ),
                      ),
                      const FloatingDock(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _goTo,
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
      },
    );
  }
}

class _LibraryFab extends StatelessWidget {
  const _LibraryFab();

  Future<void> _scanFolder(BuildContext context) async {
    try {
      final count = await context.read<LibraryService>().scanAudioFolder();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count == 0
                ? 'No se encontro audio nuevo en la carpeta'
                : '$count cancion(es) importadas',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo escanear: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'scan-folder',
          tooltip: 'Escanear carpeta',
          onPressed: () => _scanFolder(context),
          child: const Icon(Icons.folder_open),
        ),
        const SizedBox(width: 12),
        FloatingActionButton(
          heroTag: 'import-files',
          tooltip: 'Importar musica',
          onPressed: () => context.read<LibraryService>().importFiles(),
          child: const Icon(Icons.audiotrack),
        ),
      ],
    );
  }
}
