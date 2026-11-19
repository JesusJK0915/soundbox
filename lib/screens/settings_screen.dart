import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config.dart';
import '../core/connectivity_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('SoundBox'),
          subtitle: const Text('Version $appVersion (alpha)'),
        ),
        Consumer<ConnectivityService>(
          builder: (context, connectivity, _) => ListTile(
            leading: Icon(
              connectivity.isOnline ? Icons.cloud_done : Icons.cloud_off,
            ),
            title: const Text('Estado de red'),
            subtitle: Text(
              connectivity.isOnline ? 'Conectado' : 'Modo offline',
            ),
          ),
        ),
        const Divider(),
        const ListTile(
          leading: Icon(Icons.gavel),
          title: Text('Fuentes legales'),
          subtitle: Text(
            'Busqueda en Internet Archive (Creative Commons) y archivos '
            'locales. No se descarga contenido con DRM.',
          ),
        ),
        ListTile(
          leading: const Icon(Icons.key),
          title: const Text('Jamendo'),
          subtitle: Text(
            jamendoClientId.isEmpty
                ? 'Desactivado (configura jamendoClientId para activar)'
                : 'Activado',
          ),
        ),
        const Divider(),
        const ListTile(
          leading: Icon(Icons.folder),
          title: Text('Almacenamiento'),
          subtitle: Text('Todo se guarda en la carpeta privada de la app.'),
        ),
      ],
    );
  }
}
