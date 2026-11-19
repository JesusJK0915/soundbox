import 'package:flutter/material.dart';

import '../core/config.dart';

/// Pantalla de bienvenida que se muestra una sola vez.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.onAccepted});

  final VoidCallback onAccepted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Icon(Icons.music_note, size: 72, color: colors.primary),
              const SizedBox(height: 16),
              Text('Bienvenido a $appName', style: text.headlineMedium),
              const SizedBox(height: 16),
              const Text(
                'Usa la musica de forma responsable: solo archivos tuyos, con '
                'licencia o con permiso del autor. La descarga directa de '
                'YouTube es experimental y puede dejar de funcionar si '
                'YouTube cambia su funcionamiento.',
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Si no usas la musica adecuadamente te pueden mandar una '
                  'bomba a tu casa 💣',
                  style: TextStyle(color: colors.onErrorContainer),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onAccepted,
                  child: const Text('Entendido'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
