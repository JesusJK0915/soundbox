import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:soundbox/core/theme_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('los colores del fondo de pantalla vienen activados por defecto',
      () async {
    final settings = await ThemeSettingsService.load();
    expect(settings.wallpaperColors, isTrue);
  });

  test('respeta el valor guardado', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      ThemeSettingsService.wallpaperColorsKey: false,
    });
    final settings = await ThemeSettingsService.load();
    expect(settings.wallpaperColors, isFalse);
  });

  test('el interruptor avisa y no repite avisos iguales', () async {
    final settings = await ThemeSettingsService.load();
    var notifications = 0;
    settings.addListener(() => notifications++);

    settings.setWallpaperColors(false);
    expect(settings.wallpaperColors, isFalse);
    expect(notifications, 1);

    settings.setWallpaperColors(false);
    expect(notifications, 1);

    settings.setWallpaperColors(true);
    expect(settings.wallpaperColors, isTrue);
    expect(notifications, 2);
  });
}
