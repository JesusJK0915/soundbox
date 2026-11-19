const String appName = 'SoundBox';
const String appVersion = '0.9.0';

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
