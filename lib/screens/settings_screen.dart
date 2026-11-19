import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config.dart';
import '../core/connectivity_service.dart';
import '../core/download_settings.dart';
import '../core/export_service.dart';
import '../core/library_service.dart';
import '../core/listening_stats.dart';
import '../core/providers.dart';
import '../core/theme_settings.dart';
import '../core/update_service.dart';
import '../core/user_preferences.dart';
import '../widgets/update_dialog.dart';

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

  String _updateSubtitle(UpdateService updates) {
    switch (updates.status) {
      case UpdateStatus.idle:
        return 'Version instalada: $appVersion';
      case UpdateStatus.checking:
        return 'Buscando en GitHub…';
      case UpdateStatus.available:
        final release = updates.release;
        return release == null
            ? 'Hay una version nueva'
            : '${release.tag} disponible';
      case UpdateStatus.upToDate:
        return 'Estas al dia (canal ${updates.channel.name}).';
      case UpdateStatus.unknown:
        final release = updates.release;
        return release == null
            ? 'Compilacion local'
            : 'Ultima publicacion: ${release.tag} (compilacion local)';
      case UpdateStatus.error:
        return 'No se pudo comprobar. Revisa la conexion.';
      case UpdateStatus.downloading:
        return 'Descargando… ${(updates.progress * 100).toInt()}%';
      case UpdateStatus.installing:
        return 'Abriendo el instalador…';
      case UpdateStatus.installed:
        return 'Instalador abierto';
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
        Text(
          'Actualizaciones',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Consumer<UpdateService>(
          builder: (context, updates, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.autorenew),
                title: const Text('Buscar automaticamente'),
                subtitle: Text(
                  'Comprueba los releases de GitHub cada '
                  '${UpdateService.checkInterval.inHours} horas.',
                ),
                value: updates.autoCheck,
                onChanged: updates.setAutoCheck,
              ),
              ListTile(
                leading: const Icon(Icons.system_update_alt),
                title: const Text('Buscar actualizaciones ahora'),
                subtitle: Text(_updateSubtitle(updates)),
                trailing: updates.isChecking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                onTap: updates.isChecking || updates.isBusy
                    ? null
                    : () async {
                        await updates.check(force: true);
                        if (!context.mounted) return;
                        if (updates.shouldPrompt) {
                          updates.markPromptShown();
                          unawaited(showUpdateDialog(context));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(_updateSubtitle(updates))),
                          );
                        }
                      },
              ),
              if (updates.isBusy)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LinearProgressIndicator(
                    value: updates.progress == 0 ? null : updates.progress,
                  ),
                ),
              if (updates.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    updates.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const Divider(),
        Text(
          'Apariencia',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Consumer<ThemeSettingsService>(
          builder: (context, theme, _) {
            final available = WallpaperColors.maybeOf(context)?.dark != null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.palette_outlined),
                  title: const Text('Colores del fondo de pantalla'),
                  subtitle: Text(
                    available
                        ? 'Material You del sistema en toda la app.'
                        : 'Material You del sistema. Este dispositivo no lo '
                            'ofrece: se usa el color de respaldo.',
                  ),
                  value: theme.wallpaperColors,
                  onChanged: theme.setWallpaperColors,
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.image_outlined),
                  title: const Text('Colores de la carátula'),
                  subtitle: const Text(
                    'El reproductor toma los colores de la imagen de la '
                    'canción y cambia con cada pista.',
                  ),
                  value: theme.artworkColors,
                  onChanged: theme.setArtworkColors,
                ),
                Consumer<UserPreferencesService>(
                  builder: (context, prefs, _) => SwitchListTile(
                    secondary: const Icon(Icons.blur_on),
                    title: const Text('Carátula difuminada'),
                    subtitle: const Text(
                      'Aplica un suave desenfoque a la carátula del reproductor.',
                    ),
                    value: prefs.artworkBlur,
                    onChanged: prefs.setArtworkBlur,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    'Si desactivas los colores de la carátula se usa el tema '
                    'del fondo de pantalla. Si también lo desactivas, cada '
                    'canción usa su color de respaldo.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            );
          },
        ),
        const Divider(),
        Text(
          'Interfaz y gestos',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Consumer<UserPreferencesService>(
          builder: (context, prefs, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(Icons.brightness_auto),
                title: const Text('Tema'),
                subtitle: const Text('Sistema, claro u oscuro'),
                trailing: DropdownButton<AppThemeMode>(
                  value: prefs.themeMode,
                  items: const [
                    DropdownMenuItem(
                      value: AppThemeMode.system,
                      child: Text('Sistema'),
                    ),
                    DropdownMenuItem(
                      value: AppThemeMode.light,
                      child: Text('Claro'),
                    ),
                    DropdownMenuItem(
                      value: AppThemeMode.dark,
                      child: Text('Oscuro'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) prefs.setThemeMode(value);
                  },
                ),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.airplay_outlined),
                title: const Text('Dock flotante'),
                subtitle: const Text(
                  'Mini reproductor arrastrable. Se acopla arriba o abajo.',
                ),
                value: prefs.dockVisible,
                onChanged: prefs.setDockVisible,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.swipe_rounded),
                title: const Text('Gestos'),
                subtitle: const Text(
                  'Desliza entre pestañas, doble toque a la carátula para '
                  'favoritar y arrastra el reproductor para cerrarlo.',
                ),
                value: prefs.gestures,
                onChanged: prefs.setGestures,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.vibration),
                title: const Text('Respuesta háptica'),
                subtitle: const Text('Una vibración suave al interactuar.'),
                value: prefs.haptics,
                onChanged: prefs.setHaptics,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.swipe_left),
                title: const Text('Deslizar para cambiar de pista'),
                subtitle: const Text(
                  'Desliza la carátula del reproductor para saltar.',
                ),
                value: prefs.swipeToSkip,
                onChanged: prefs.setSwipeToSkip,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.crop_free),
                title: const Text('Dock compacto'),
                subtitle: const Text('Mini reproductor más pequeño.'),
                value: prefs.compactDock,
                onChanged: prefs.setCompactDock,
              ),
            ],
          ),
        ),
        const Divider(),
        Text(
          'Letras y reproducción',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Consumer<UserPreferencesService>(
          builder: (context, prefs, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.short_text),
                title: const Text('Buscar letras automáticamente'),
                subtitle: const Text(
                  'Consulta LRCLIB al cambiar de canción y guarda la letra '
                  'sincronizada (.lrc) para mostrarla sin conexión.',
                ),
                value: prefs.autoLyrics,
                onChanged: prefs.setAutoLyrics,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.text_fields),
                title: const Text('Resaltar letra activa'),
                subtitle: const Text(
                  'Marca con ♪ la línea que suena en cada momento.',
                ),
                value: prefs.lyricsKaraoke,
                onChanged: prefs.setLyricsKaraoke,
              ),
              ListTile(
                leading: const Icon(Icons.font_download_outlined),
                title: const Text('Tamaño de la letra'),
                subtitle: Text('${prefs.lyricFont.round().toInt()} px'),
                trailing: SizedBox(
                  width: 140,
                  child: Slider(
                    min: 16,
                    max: 34,
                    divisions: 18,
                    value: prefs.lyricFont,
                    onChanged: prefs.setLyricFont,
                  ),
                ),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.shuffle_on_outlined),
                title: const Text('Aleatorio sesgado'),
                subtitle: const Text(
                  'Al mezclar la cola prioriza favoritas y más escuchadas.',
                ),
                value: prefs.shuffleBiased,
                onChanged: prefs.setShuffleBiased,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.graphic_eq),
                title: const Text('Crossfade entre canciones'),
                subtitle: const Text(
                  'Atenúa suavemente antes de saltar a la siguiente pista.',
                ),
                value: prefs.crossfade,
                onChanged: prefs.setCrossfade,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.av_timer),
                title: const Text('Reproducción sin pausas (gapless)'),
                subtitle: const Text(
                  'Encadena las pistas sin silencios entre ellas.',
                ),
                value: prefs.gapless,
                onChanged: prefs.setGapless,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.bedtime),
                title: const Text('Fade al terminar el temporizador'),
                subtitle: const Text(
                  'Baja el volumen antes de pausar con el sueño.',
                ),
                value: prefs.sleepFade,
                onChanged: prefs.setSleepFade,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.replay),
                title: const Text('Recordar aleatorio y velocidad'),
                subtitle: const Text(
                  'Conserva el modo aleatorio y la velocidad al reiniciar.',
                ),
                value: prefs.rememberShuffle && prefs.rememberSpeed,
                onChanged: (value) {
                  prefs.setRememberShuffle(value);
                  prefs.setRememberSpeed(value);
                },
              ),
            ],
          ),
        ),
        const Divider(),
        Consumer2<LibraryService, UserPreferencesService>(
          builder: (context, library, prefs, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tus estadísticas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.audiotrack,
                      label: 'Canciones',
                      value: '${library.playableTracks.length}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.favorite,
                      label: 'Favoritas',
                      value: '${prefs.favoriteIds.length}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.play_circle_outline,
                      label: 'Reproducciones',
                      value: '${prefs.totalPlays}',
                    ),
                  ),
                ],
              ),
              Consumer<ListeningStatsService>(
                builder: (context, stats, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.local_fire_department,
                            label: 'Racha (días)',
                            value: '${stats.streak}',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.emoji_events,
                            label: 'Mejor racha',
                            value: '${stats.bestStreak}',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.schedule,
                            label: 'Hoy (min)',
                            value: '${stats.todaySeconds ~/ 60}',
                          ),
                        ),
                      ],
                    ),
                    ListTile(
                      leading: const Icon(Icons.ios_share),
                      title: const Text('Exportar historial de escucha'),
                      subtitle: const Text(
                        'Genera un CSV con tiempo diario y reproducciones.',
                      ),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Historial: ${stats.sessions.length} día(s), '
                              '${stats.totalSeconds ~/ 60} minuto(s) en total',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('Reiniciar estadísticas'),
                subtitle: const Text(
                  'Borra favoritos, conteos y posiciones guardadas.',
                ),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('¿Reiniciar estadísticas?'),
                      content: const Text(
                        'Perderás favoritos, reproducciones y el punto donde '
                        'se quedó cada canción.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('Reiniciar'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) await prefs.resetStats();
                },
              ),
            ],
          ),
        ),
        const Divider(),
        Text(
          'Biblioteca',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Consumer<UserPreferencesService>(
          builder: (context, prefs, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.folder_open),
                title: const Text('Escanear al iniciar'),
                subtitle: const Text(
                  'Busca audio nuevo en la última carpeta escaneada.',
                ),
                value: prefs.scanOnStart,
                onChanged: prefs.setScanOnStart,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.auto_fix_high),
                title: const Text('Leer metadatos automáticamente'),
                subtitle: const Text(
                  'Actualiza etiquetas y carátulas al importar canciones.',
                ),
                value: prefs.autoMetadata,
                onChanged: prefs.setAutoMetadata,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.groups),
                title: const Text('Agrupar artistas'),
                subtitle: const Text(
                  'Trata a los artistas colaboradores como uno solo.',
                ),
                value: prefs.groupArtists,
                onChanged: prefs.setGroupArtists,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.calendar_month),
                title: const Text('Mostrar año y bitrate'),
                subtitle: const Text(
                  'Añade estos datos a cada canción de la biblioteca.',
                ),
                value: prefs.showYear && prefs.showBitrate,
                onChanged: (value) {
                  prefs.setShowYear(value);
                  prefs.setShowBitrate(value);
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.data_saver_off),
                title: const Text('Ahorro de datos'),
                subtitle: const Text(
                  'Evita consultas online (letras) para pistas remotas.',
                ),
                value: prefs.lowData,
                onChanged: prefs.setLowData,
              ),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.edit_note),
          title: const Text('Leer metadatos de los archivos'),
          subtitle: const Text(
            'Actualiza artista, álbum, carátula y otros datos de las '
            'canciones locales.',
          ),
          onTap: () async {
            final count = await context
                .read<LibraryService>()
                .refreshMetadata(force: true);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  count == 0
                      ? 'No habia nada que actualizar'
                      : '$count cancion(es) actualizada(s)',
                ),
              ),
            );
          },
        ),
        const Divider(),
        const ListTile(
          leading: Icon(Icons.gavel),
          title: Text('Fuentes legales'),
          subtitle: Text(downloadPolicy),
        ),
        const SizedBox(height: 8),
        Text(
          'Fuentes y servicios',
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
          'Opciones experimentales',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Consumer<ProviderSettingsService>(
          builder: (context, settings, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.download_for_offline),
                title: const Text('Descarga directa de YouTube'),
                subtitle: const Text(
                  'Extrae solo el audio del video. Usalo solo con musica '
                  'propia o con licencia.',
                ),
                value: settings.youtubeDirect,
                onChanged: settings.setYoutubeDirect,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  'Si lo desactivas, los links de YouTube buscan la cancion '
                  'en fuentes legales con la API key.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: scheme.onSecondaryContainer, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: scheme.onSecondaryContainer,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.onSecondaryContainer.withOpacity(0.75),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
