const String appName = 'SoundBox';
const String appVersion = '0.3.0';

/// Claves opcionales. Se pueden cambiar desde Ajustes sin recompilar.
/// Si estan vacias, el proveedor correspondiente aparece desactivado.
const String jamendoClientId = '';
const String pixabayApiKey = '';
const String soundCloudClientId = '';

/// YouTube no tiene API de descarga oficial y sus terminos prohiben extraer
/// contenido, por lo que no se incluye como fuente de descarga.
const String downloadPolicy =
    'Solo fuentes legales: archivos propios, licencias Creative Commons, '
    'dominio publico y contenido con descarga autorizada.';
