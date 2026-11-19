import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundbox/core/models.dart';
import 'package:soundbox/core/user_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<UserPreferencesService> freshService() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    return UserPreferencesService(await SharedPreferences.getInstance());
  }

  Track track(String id, String title, {int? year}) => Track(
        id: id,
        title: title,
        artist: 'Artista',
        sourceUrl: '/tmp/$id.mp3',
        year: year,
      );

  test('favoritos se alternan y sobreviven a una nueva instancia', () async {
    final prefs = await freshService();
    expect(prefs.isFavorite('a'), isFalse);

    await prefs.toggleFavorite('a');
    expect(prefs.isFavorite('a'), isTrue);

    final restored = UserPreferencesService(await SharedPreferences.getInstance());
    expect(restored.isFavorite('a'), isTrue);
    expect(restored.favoriteIds, contains('a'));
  });

  test('reproducciones y estadísticas se acumulan', () async {
    final prefs = await freshService();
    await prefs.registerPlay('a');
    await prefs.registerPlay('a');
    await prefs.registerPlay('b');

    expect(prefs.playCount('a'), 2);
    expect(prefs.totalPlays, 3);
    expect(prefs.lastPlayed('a'), isNotNull);
    expect(
      prefs.mostPlayed([track('a', 'A'), track('b', 'B')]).first.id,
      'a',
    );
  });

  test('el orden por título y por año funciona', () async {
    final prefs = await freshService();
    final tracks = [
      track('z', 'Zebra', year: 1999),
      track('a', 'Amarillo', year: 2024),
    ];

    expect(prefs.sorted(tracks).first.title, 'Amarillo');
    await prefs.setSort(LibrarySort.year);
    expect(prefs.sorted(tracks).first.title, 'Amarillo');
  });

  test('reiniciar borra favoritos y estadísticas', () async {
    final prefs = await freshService();
    await prefs.toggleFavorite('a');
    await prefs.registerPlay('a');
    await prefs.resetStats();

    expect(prefs.favoriteIds, isEmpty);
    expect(prefs.totalPlays, 0);
    expect(prefs.positionFor('a'), Duration.zero);
  });
}
