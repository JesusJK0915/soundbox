const String appName = 'SoundBox';
const String appVersion = '0.5.0';

/// Claves opcionales. Se pueden cambiar desde Ajustes sin recompilar.
/// Si estan vacias, el proveedor correspondiente aparece desactivado.
const String jamendoClientId = '';
const String pixabayApiKey = '';
const String soundCloudClientId = '';
const String youtubeApiKey = '';

/// YouTube solo se usa para leer metadata publica (snippet) y buscar la misma
/// cancion en fuentes legales. Nunca se descarga ni se extrae audio del video.
const String downloadPolicy =
    'Solo fuentes legales: archivos propios, licencias Creative Commons, '
    'dominio publico y contenido con descarga autorizada.';
