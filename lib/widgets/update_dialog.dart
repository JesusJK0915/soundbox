import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/update_service.dart';

Future<void> showUpdateDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Consumer<UpdateService>(
      builder: (context, updates, _) {
        final release = updates.release;
        if (release == null) return const SizedBox.shrink();
        final scheme = Theme.of(context).colorScheme;
        final busy = updates.isBusy;
        final progress = updates.progress;

        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.system_update, color: scheme.primary),
              const SizedBox(width: 10),
              const Expanded(child: Text('Actualización disponible')),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    release.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${release.tag} · ${release.sizeLabel} · canal ${release.channel.name}',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  if (busy) ...[
                    const SizedBox(height: 16),
                    LinearProgressIndicator(value: progress == 0 ? null : progress),
                    const SizedBox(height: 6),
                    Text(
                      updates.status == UpdateStatus.installing
                          ? 'Abriendo el instalador…'
                          : 'Descargando… ${(progress * 100).toInt()}%',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (updates.error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      updates.error!,
                      style: TextStyle(color: scheme.error, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 220),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: SingleChildScrollView(
                      child: Text(release.notes),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                updates.skip();
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Omitir'),
            ),
            TextButton(
              onPressed: updates.openReleasePage,
              child: const Text('Ver en GitHub'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () => updates.downloadAndInstall(),
              child: const Text('Descargar e instalar'),
            ),
          ],
        );
      },
    ),
  );
}
