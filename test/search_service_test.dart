import 'package:flutter_test/flutter_test.dart';
import 'package:soundbox/core/providers.dart';
import 'package:soundbox/core/search_service.dart';

void main() {
  test('una URL directa se convierte en pista descargable', () async {
    final service = SearchService(ProviderSettingsService());
    final results = await service.search('https://ejemplo.org/mi-cancion.mp3');

    expect(results, hasLength(1));
    expect(results.single.title, 'mi-cancion');
    expect(results.single.format, 'mp3');
    expect(results.single.source, 'URL directa');
  });

  test('una URL de video no se acepta como pista', () async {
    final service = SearchService(ProviderSettingsService());
    final results = await service.search('https://ejemplo.org/mi-video.mp4');

    expect(results, isEmpty);
  });

  test('los proveedores sin clave no se activan solos', () {
    final settings = ProviderSettingsService();
    final active = settings.activeSearchProviders;

    expect(active, contains(ProviderKind.internetArchive));
    expect(active, contains(ProviderKind.wikimedia));
    expect(active, isNot(contains(ProviderKind.jamendo)));
    expect(active, isNot(contains(ProviderKind.pixabay)));
  });
}
