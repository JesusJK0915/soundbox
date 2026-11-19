import 'package:flutter_test/flutter_test.dart';
import 'package:soundbox/core/metadata_service.dart';
import 'package:soundbox/core/models.dart';

void main() {
  test('TrackMetadata conserva etiquetas y caratula al serializar', () {
    const metadata = TrackMetadata(
      title: 'Cancion',
      artist: 'Artista',
      album: 'Album',
      year: 2024,
      genre: 'Rock',
      trackNumber: 3,
      bitrateBps: 320000,
      artworkPath: '/tmp/cover.jpg',
      extraTags: <String, String>{'Idioma': 'es'},
    );

    final restored = TrackMetadata.fromJson(metadata.toJson());

    expect(restored.title, 'Cancion');
    expect(restored.artist, 'Artista');
    expect(restored.album, 'Album');
    expect(restored.year, 2024);
    expect(restored.genre, 'Rock');
    expect(restored.trackNumber, 3);
    expect(restored.bitrateBps, 320000);
    expect(restored.artworkPath, '/tmp/cover.jpg');
    expect(restored.extraTags['Idioma'], 'es');
  });

  test('Track guarda y copia los nuevos campos de metadatos', () {
    const track = Track(
      id: 'id',
      title: 'Titulo',
      artist: 'Artista',
      sourceUrl: '/tmp/song.mp3',
      album: 'Album',
      artworkPath: '/tmp/cover.jpg',
      year: 2020,
      genre: 'Jazz',
      tagsRead: true,
    );

    final restored = Track.fromJson(track.toJson());
    final copied = track.copyWith(title: 'Otro titulo');

    expect(restored.artworkPath, '/tmp/cover.jpg');
    expect(restored.year, 2020);
    expect(restored.genre, 'Jazz');
    expect(restored.tagsRead, isTrue);
    expect(copied.title, 'Otro titulo');
    expect(copied.artworkPath, '/tmp/cover.jpg');
    expect(copied.tagsRead, isTrue);
  });
}
