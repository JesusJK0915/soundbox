import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundbox/core/listening_stats.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ListeningStatsService> freshService() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    return ListeningStatsService(await SharedPreferences.getInstance());
  }

  test('acumula tiempo diario y calcula racha', () async {
    final stats = await freshService();
    await stats.addListeningTime(const Duration(minutes: 5));
    expect(stats.todaySeconds, 300);
    expect(stats.streak, 1);
    expect(stats.bestStreak, 1);

    await stats.addListeningTime(const Duration(minutes: 2));
    expect(stats.todaySeconds, 420);
    expect(stats.sessions.length, 1);
  });

  test('persiste sesiones y rachas', () async {
    final stats = await freshService();
    await stats.addListeningTime(const Duration(minutes: 3));
    final restored = ListeningStatsService(await SharedPreferences.getInstance());
    expect(restored.todaySeconds, 180);
    expect(restored.streak, 1);
  });

  test('genera CSV con cabecera', () async {
    final stats = await freshService();
    await stats.addListeningTime(const Duration(minutes: 1));
    expect(stats.toCsv(), contains('dia,segundos,reproducciones'));
    expect(stats.toCsv(), contains(',60,0'));
  });

  test('reset limpia todo', () async {
    final stats = await freshService();
    await stats.addListeningTime(const Duration(minutes: 1));
    await stats.reset();
    expect(stats.sessions, isEmpty);
    expect(stats.streak, 0);
    expect(stats.bestStreak, 0);
  });
}
