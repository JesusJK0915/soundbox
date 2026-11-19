import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundbox/core/library_tools.dart';
import 'package:soundbox/core/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<LibraryToolsService> freshService() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    return LibraryToolsService(await SharedPreferences.getInstance());
  }

  Track track(
    String id,
    String title, {
    String artist = 'Artista',
    int? year,
    int durationMs = 120000,
    String? genre,
  }) =>
      Track(
        id: id,
        title: title,
        artist: artist,
        sourceUrl: '/tmp/$id.mp3',
        isLocal: true,
        year: year,
        genre: genre,
        durationMs: durationMs,
      );

  test('detecta duplicados por titulo, artista y duracion', () async {
    final tools = await freshService();
    final groups = tools.findDuplicates([
      track('1', 'Cancion'),
      track('2', '  CANCION  '),
      track('3', 'Otra'),
    ]);
    expect(groups.length, 1);
    expect(groups.first.tracks.length, 2);
  });

  test('crea, renombra y elimina playlists', () async {
    final tools = await freshService();
    final playlist = await tools.createPlaylist('Favoritas');
    expect(playlist.name, 'Favoritas');

    await tools.addToPlaylist(playlist.id, 'a');
    await tools.addToPlaylist(playlist.id, 'a');
    expect(tools.playlists.single.trackIds, ['a']);

    await tools.renamePlaylist(playlist.id, 'Top');
    expect(tools.playlists.single.name, 'Top');

    final restored = LibraryToolsService(await SharedPreferences.getInstance());
    expect(restored.playlists.single.name, 'Top');

    await tools.deletePlaylist(playlist.id);
    expect(tools.playlists, isEmpty);
  });

  test('resuelve las pistas de una playlist', () async {
    final tools = await freshService();
    final created = await tools.createPlaylist('Lista');
    await tools.addToPlaylist(created.id, '1');
    await tools.addToPlaylist(created.id, '3');
    final playlist = tools.playlists.single;
    final tracks = [track('1', 'A'), track('2', 'B'), track('3', 'C')];
    expect(tools.tracksOf(playlist, tracks).map((t) => t.title), ['A', 'C']);
  });

  test('aplica presets y resetea el ecualizador', () async {
    final tools = await freshService();
    expect(tools.bands.length, 5);
    await tools.applyPreset('Bass boost');
    expect(tools.bands.first.gain, 6);
    await tools.resetEqualizer();
    expect(tools.bands.every((band) => band.gain == 0), isTrue);
  });

  test('evalua reglas de listas inteligentes', () async {
    final tools = await freshService();
    final tracks = [
      track('1', 'A', year: 2015, genre: 'Rock'),
      track('2', 'B', year: 2005, genre: 'Jazz'),
    ];
    final byYear = tools.smartPlaylist('year>2010', tracks);
    expect(byYear.single.id, '1');
    final byGenre = tools.smartPlaylist('genre=Rock', tracks);
    expect(byGenre.single.id, '1');
    final favorites = tools.smartPlaylist(
      'favorite',
      tracks,
      favorites: const {'2'},
    );
    expect(favorites.single.id, '2');
  });

  test('normalizacion y replaygain persisten', () async {
    final tools = await freshService();
    await tools.setNormalize(true);
    await tools.setReplayGain(true);
    final restored = LibraryToolsService(await SharedPreferences.getInstance());
    expect(restored.normalize, isTrue);
    expect(restored.replayGain, isTrue);
  });
}
