const String appName = 'SoundBox';
const String appVersion = '1.2.0';

/// Los workflows inyectan el canal y el numero de build del release con
/// `--dart-define`. Asi el numero de la etiqueta de GitHub siempre coincide
/// con la compilacion instalada, sin tener que tocar el codigo a mano.
const String updateChannelName = String.fromEnvironment(
  'UPDATE_CHANNEL',
  defaultValue: 'stable',
);
const int updateBuildNumber = int.fromEnvironment('UPDATE_BUILD', defaultValue: 0);
const String updateOwner = 'JesusJK0915';
const String updateRepo = 'soundbox';

/// Claves opcionales. Se pueden cambiar desde Ajustes sin recompilar.
/// Si estan vacias, el proveedor correspondiente aparece desactivado.
const String jamendoClientId = '';
const String pixabayApiKey = '';
const String soundCloudClientId = '';
const String youtubeApiKey = '';

/// YouTube tiene dos modos: extraccion directa de audio (experimental) o,
/// si se desactiva, solo metadata publica (snippet) para buscar en fuentes
/// legales. Usa el modo directo solo con audio propio o autorizado.
const String downloadPolicy =
    'Solo fuentes legales: archivos propios, licencias Creative Commons, '
    'dominio publico y contenido con descarga autorizada.';
