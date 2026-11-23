import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/connectivity_service.dart';
import '../core/library_service.dart';
import '../core/update_service.dart';
import '../core/user_preferences.dart';
import '../widgets/mini_player.dart';
import '../widgets/update_dialog.dart';
import 'downloads_screen.dart';
import 'library_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'tools_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  UpdateService? _updates;
  double? _dragStartX;
  double? _dragStartY;

  late final List<Widget> _pages = const [
    LibraryScreen(),
    SearchScreen(),
    DownloadsScreen(),
    ToolsScreen(),
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
    setState(() => _index = index);
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
                builder: (context, connectivity, _) => Container(
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
          // Listener recibe los eventos crudos aunque el hijo tenga un
          // TextField o un Scrollable, que antes ganaban la arena de gestos
          // y dejaban el swipe trabado en Buscar.
          body: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (event) {
              _dragStartX = event.localPosition.dx;
              _dragStartY = event.localPosition.dy;
            },
            onPointerUp: (event) {
              final startX = _dragStartX;
              final startY = _dragStartY;
              _dragStartX = null;
              _dragStartY = null;
              if (!prefs.gestures || startX == null || startY == null) return;
              final dx = event.localPosition.dx - startX;
              final dy = event.localPosition.dy - startY;
              if (dx.abs() < 80 || dx.abs() <= dy.abs() * 1.5) return;
              if (dx < 0) {
                _goTo((_index + 1).clamp(0, _pages.length - 1));
              } else {
                _goTo((_index - 1).clamp(0, _pages.length - 1));
              }
            },
            onPointerCancel: (_) {
              _dragStartX = null;
              _dragStartY = null;
            },
            child: Column(
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
                Expanded(child: _pages[_index]),
                const MiniPlayer(),
              ],
            ),
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NavigationBar(
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
                    icon: Icon(Icons.construction_outlined),
                    selectedIcon: Icon(Icons.construction),
                    label: 'Herramientas',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings),
                    label: 'Ajustes',
                  ),
                ],
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
