import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config.dart';
import '../core/connectivity_service.dart';
import '../core/download_settings.dart';
import '../core/export_service.dart';
import '../core/library_service.dart';
import '../core/providers.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<String?> _askKey(
    BuildContext context,
    ProviderDefinition definition,
    String current,
  ) async {
    final controller = TextEditingController(text: current);
    try {
      return await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Conectar ${definition.label}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(definition.description),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: definition.keyLabel ?? 'Clave',
                  hintText: definition.keyHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Guardar'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _chooseFolder(BuildContext context) async {
    try {
      final uri = await context.read<ExportService>().chooseFolder();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(uri == null ? 'Eleccion cancelada' : 'Carpeta guardada'),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo elegir: $error')),
      );
    }
  }

  Future<void> _exportAll(BuildContext context) async {
    final export = context.read<ExportService>();
    final tracks = context.read<LibraryService>().playableTracks;
    if (tracks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La biblioteca esta vacia')),
      );
      return;
    }

    final folder = export.folderUri ?? await export.chooseFolder();
    if (folder == null || !context.mounted) return;
    try {
      final count = await export.exportToFolder(folder, tracks);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count cancion(es) copiadas')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo exportar: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('SoundBox'),
          subtitle: const Text('Version $appVersion (beta)'),
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
          subtitle: Text(downloadPolicy),
        ),
        const SizedBox(height: 8),
        Text(
          'Fuentes de descarga',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        ...providerDefinitions.map(
          (definition) => Consumer<ProviderSettingsService>(
            builder: (context, settings, _) {
              final hasKey = settings.key(definition.kind).isNotEmpty;
              final enabled = settings.isEnabled(definition.kind);

              Future<void> toggle(bool value) async {
                if (value && definition.requiresKey && !hasKey) {
                  final key = await _askKey(context, definition, '');
                  if (key == null || key.isEmpty) return;
                  settings.setKey(definition.kind, key);
                  return;
                }
                settings.setEnabled(definition.kind, value);
              }

              return ListTile(
                leading: Icon(definition.icon),
                title: Text(definition.label),
                subtitle: Text(
                  definition.requiresKey
                      ? '${definition.description} · '
                          '${hasKey ? 'conectado' : 'sin clave'}'
                      : definition.description,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (definition.requiresKey)
                      IconButton(
                        icon: const Icon(Icons.key),
                        tooltip: 'Cambiar clave',
                        onPressed: () async {
                          final key = await _askKey(
                            context,
                            definition,
                            settings.key(definition.kind),
                          );
                          if (key != null) {
                            settings.setKey(definition.kind, key);
                          }
                        },
                      ),
                    Switch(
                      value: enabled,
                      onChanged: toggle,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const Divider(),
        Text(
          'Formato de descarga',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Consumer<DownloadSettingsService>(
          builder: (context, quality, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(Icons.audiotrack),
                title: const Text('Formato'),
                trailing: DropdownButton<AudioFormat>(
                  value: quality.format,
                  items: AudioFormat.values
                      .map(
                        (format) => DropdownMenuItem<AudioFormat>(
                          value: format,
                          child: Text(format.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) quality.setFormat(value);
                  },
                ),
              ),
              if (quality.isLossy)
                ListTile(
                  leading: const Icon(Icons.speed),
                  title: const Text('Bitrate'),
                  trailing: DropdownButton<int>(
                    value: quality.bitrate,
                    items: DownloadSettingsService.bitrates
                        .map(
                          (value) => DropdownMenuItem<int>(
                            value: value,
                            child: Text('$value kbps'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) quality.setBitrate(value);
                    },
                  ),
                ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  'Se descarga el archivo original y se convierte en el '
                  'dispositivo. Los formatos sin perdida ignoran el bitrate.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        Text(
          'Guardar en otro lugar',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Consumer<ExportService>(
          builder: (context, export, _) => ListTile(
            leading: const Icon(Icons.folder_open),
            title: const Text('Carpeta de exportacion'),
            subtitle: Text(
              export.hasFolder
                  ? 'Carpeta elegida: ${export.folderUri}'
                  : 'Elige una carpeta (Descargas, Drive, etc.)',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: TextButton(
              onPressed: () => _chooseFolder(context),
              child: const Text('Elegir'),
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.file_upload),
          title: const Text('Exportar toda la biblioteca'),
          subtitle: const Text('Copia las canciones a la carpeta elegida'),
          onTap: () => _exportAll(context),
        ),
        const Divider(),
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('Sobre YouTube'),
          subtitle: Text(
            'YouTube no ofrece una API de descarga y sus terminos prohiben '
            'extraer contenido. SoundBox solo usa fuentes con licencia '
            'o archivos que te pertenecen.',
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
