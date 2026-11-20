# SoundBox

Reproductor y biblioteca musical para Android compilado **100% en GitHub Actions**.
Tu PC solo sirve para escribir codigo y hacer `push`.

## Que hace

- Importa musica local y la reproduce sin conexion (solo audio).
- Detecta automaticamente si hay internet; si no hay, oculta la busqueda y usa solo la biblioteca local.
- Busca en varias fuentes legales y descarga al dispositivo.
- Descargas con progreso, pausa y reanude (`Range`).
- Conversion local a **MP3, M4A/AAC, OGG, FLAC o WAV** con bitrate de 64 a 320 kbps.
- Subtitulos `.srt` / `.vtt` que se adjuntan a una pista.
- Pega una **URL directa** a un archivo propio para descargarlo.
- Pega un **link de YouTube** y extrae solo el audio (modo experimental).
- **Escanea una carpeta** e importa toda la musica que encuentre.
- **Guardar en otro lugar**: exporta una canción o toda la biblioteca a la carpeta que elijas (Descargas, Drive, etc.).
- **Material You**: usa los colores del fondo de pantalla del teléfono en toda la app y en el reproductor.
- **Metadatos**: lee artista, álbum, carátula, año, género, pista, bitrate y más de los archivos de audio.
- **Mini reproductor fijo** en la parte inferior, sin dock flotante.
- **Pestañas** con deslizamiento lateral.
- **Favoritos, estadísticas y reanudación** de la reproducción donde la dejaste.
- **Temporizador de sueño, velocidad de reproducción y letra** desde el reproductor.

## Interfaz y nuevas funciones

- **Mini reproductor fijo**: siempre visible en la parte inferior al escuchar
  música; no hay dock flotante ni animaciones globales.
- **Pestañas**: cambio con deslizamiento; también puedes deslizar el dedo de
  izquierda a derecha para cambiar de pestaña.
- **Biblioteca mejorada**: búsqueda local, filtros (Todas, Favoritas,
  Recientes, Más escuchadas), orden configurable, vista de lista o cuadrícula,
  reproducción de todo o en aleatorio y selección múltiple (añadir a la cola,
  guardar o eliminar varias canciones a la vez). Desliza hacia abajo para
  volver a leer los metadatos.
- **Favoritos**: toca el corazón en el reproductor o en el mini reproductor;
  doble toque a la carátula también lo marca como favorito (si los gestos están
  activos).
- **Estadísticas**: se cuenta cada reproducción y se guarda la posición de cada
  canción para continuar después de reiniciar. Ajustes muestra totales y permite
  reiniciar los datos.
- **Reproductor centrado**: los controles quedan en el centro de la pantalla
  y se adaptan al alto del teléfono, sin tener que deslizar. Mientras suena la
  música aparece la **onda Material 3 Expressive** (“gusanito”) sobre los
  controles; se puede desactivar en Ajustes. Incluye temporizador de sueño
  (5 a 90 minutos, con +5 min y cancelación), velocidad de 0,5× a 2×,
  retroceso/avance de 10 segundos, letra incrustada, control de la cola
  (subir, bajar, quitar y limpiar) y arrastre hacia abajo desde el tirador
  superior para cerrarlo.
- **Apariencia**: tema del sistema, claro u oscuro, respuesta háptica y gestos
  configurables en **Ajustes → Interfaz y gestos**.

## Actualizaciones automáticas

SoundBox se actualiza directamente desde los **releases de GitHub** (no hay
Play Store):

- Al abrir la app comprueba si hay una versión nueva (máximo una vez cada
  6 horas) y muestra un diálogo con las notas del release.
- El canal se detecta según la compilación: **alpha** busca
  `v0.1.0-alpha.*`, **beta** busca `v0.2.0-beta.*` y la compilación
  **estable** busca etiquetas `vX.Y.Z` sin guion (por ejemplo `v1.1.0`).
- El APK se elige según la arquitectura del teléfono (`arm64-v8a`,
  `armeabi-v7a` o `x86_64`). Las compilaciones alpha usan `app-debug.apk`.
- Puedes descargar e instalar desde el propio diálogo, abrir la página del
  release en GitHub u omitir esa versión.
- Si Android pide permiso, la app abre **Instalar aplicaciones desconocidas**
  para que lo actives y luego reanudas la instalación.
- El interruptor **Buscar automáticamente** y el botón **Buscar actualizaciones
  ahora** están en **Ajustes → Actualizaciones**. Funciona en modo offline sin
  errores: simplemente no hay comprobación hasta que vuelva la conexión.

Los workflows inyectan `--dart-define=UPDATE_CHANNEL=...` y
`--dart-define=UPDATE_BUILD=<codigo>` para que el número de build comparado
sea exactamente el mismo de la etiqueta publicada.

## Versión estable 1.1.0

Esta versión es una release **estable** (no alpha ni beta). Incluye:

- Versión real de Android `1.1.0` con `versionCode 110`, generada desde
  `pubspec.yaml` y los argumentos `--build-name` / `--build-number` del
  workflow, sin el antiguo `0.1.0`.
- Reproductor centrado con el indicador Material Expressive 3 (gusanito)
  **sobre el control deslizante del tiempo**, visible solo mientras suena la
  música y respetando el interruptor de Ajustes.
- Deslizamiento horizontal entre las cinco pestañas cuando los gestos están
  activados.
- Historial con botones rellenos y animación de pulsación al tocarlos.
- **300 funciones útiles** en `lib/core/pro_toolkit.dart` (100 originales más
  200 nuevas), cubiertas por `test/pro_toolkit_test.dart`.
- **300 mejoras**: 100 nuevas sobre las funciones recientes, 100 nuevas sobre
  funciones anteriores y las 100 mejoras de la versión 1.0.3.
- Sin dock flotante; el mini reproductor es fijo.
- Solo audio; se mantienen los proveedores legales y las letras automáticas
  con LRCLIB (Recomendado), sin IA local.

Consulta el detalle de funciones y mejoras en `CHANGELOG.md`.

## Metadatos y carátulas

Al importar o escanear música (y también al terminar una descarga), SoundBox
lee las etiquetas del archivo con `audio_metadata_reader`: ID3v1/v2 en MP3,
Vorbis comments en FLAC/OGG/Opus y `ilst` en M4A. Se guardan título, artista,
artista del álbum, álbum, año, género, número de pista/disco, duración, bitrate,
frecuencia, letra e intérpretes. La carátula incrustada se extrae y se muestra
en la biblioteca, el mini reproductor y la pantalla completa.

Las pistas importadas antes de esta versión se actualizan automáticamente en
segundo plano al abrir la app. También puedes forzar la lectura en
**Ajustes → Biblioteca → Leer metadatos de los archivos**. En la biblioteca,
el menú de cada canción tiene **Ver metadatos**, y el reproductor muestra un
botón de información con todos los campos.

Si un archivo no tiene etiquetas, se conservan el nombre del archivo y los
datos de la fuente.

## Colores del fondo de pantalla

En Android 12 o superior, SoundBox toma los colores del fondo de pantalla
mediante `dynamic_color` y los aplica al tema global, al mini reproductor y a
la pantalla completa. En dispositivos sin color dinámico se usa una paleta de
respaldo.

El interruptor **Ajustes → Apariencia → Colores del fondo de pantalla** permite
activarlo o desactivarlo en cualquier momento; la elección se guarda en el
dispositivo. Si lo desactivas, cada canción recupera su paleta determinista
anterior.

## Formato y calidad de descarga

En **Ajustes → Formato de descarga** eliges el formato final y, para los
formatos con perdida (MP3/M4A/OGG), el bitrate: 64, 96, 128, 192, 256 o 320
kbps. La app baja el archivo original y lo convierte en el telefono con
`ffmpeg-kit` (GPL), sin subirlo a ningun servidor. FLAC y WAV ignoran el
bitrate. "Original (sin convertir)" guarda lo que ofrece la fuente.

Si la conversion falla, se guarda el archivo original y se avisa en Descargas.
Requiere Android 7.0 (API 24) o superior.

El motor de conversion (`ffmpeg_kit_flutter_new`) se distribuye bajo GPLv3; su
codigo fuente esta disponible en https://github.com/sk3llo/ffmpeg_kit_flutter .

## Guardar la musica en otra carpeta

La biblioteca y las descargas viven en el almacenamiento privado de la app. Para
sacar copias a otro sitio:

- En **Biblioteca**, abre el menú de una canción → **Guardar en otro lugar**.
- En **Descargas**, toca el icono 💾 de una descarga terminada.
- En **Ajustes → Guardar en otro lugar**, elige una carpeta y pulsa
  **Exportar toda la biblioteca**.

Se usa el selector del sistema (Storage Access Framework), así que la carpeta
elegida se recuerda y no hace falta permiso de almacenamiento. La copia se crea
en el destino; el original sigue en la app.

## Fuentes de descarga

Se activan y configuran en **Ajustes → Fuentes de descarga** (se guardan en el dispositivo):

| Fuente | Clave | Que aporta |
| --- | --- | --- |
| Internet Archive | no | Creative Commons y dominio publico (activa por defecto) |
| Wikimedia Commons | no | Audio con licencia libre (activa por defecto) |
| Jamendo | `client_id` | Musica Creative Commons |
| SoundCloud | `client_id` | Solo pistas marcadas como descargables por su autor |
| Pixabay | API key | Musica libre de regalias |
| URL directa | no | Cualquier archivo de audio legal al que tengas enlace |
| YouTube (solo busqueda) | API key | Lee titulo/canal de un link y busca esa cancion en fuentes legales; no descarga audio |

La app solo maneja audio: no importa ni descarga video.

Las claves tambien se pueden dejar en `lib/core/config.dart` como valores por defecto.

### Links de YouTube (modo directo)

Pega un link de `youtube.com`, `youtu.be`, `/shorts/` o `/embed/` en **Buscar**
y SoundBox extrae **solo el audio** usando `youtube_explode_dart` (el
equivalente a yt-dlp en Dart, sin API key). El archivo se convierte al formato y
bitrate elegidos y entra en la biblioteca. Es una funcion **experimental**:
YouTube suele cambiar su funcionamiento y puede dejar de trabajar hasta que se
actualice la libreria.

El modo directo viene activado. En **Ajustes → Opciones experimentales** puedes
desactivarlo: entonces los links de YouTube pasan a consultar solo la metadata
publica (`videos.list?part=snippet`, con API key de YouTube Data API v3) y
buscan la cancion en las fuentes legales activas, sin extraer audio del video.

La primera vez se muestra una pantalla de bienvenida con el aviso de uso
responsable. Usa esta funcion solo con audio tuyo, con licencia o con permiso
del autor.

## Como obtener el APK

1. Crea el repositorio en GitHub y sube este codigo.
2. Crea las ramas `alpha`, `develop` y `main`.
3. Haz `push` a `alpha`: el workflow `Alpha APK` compila y publica un APK debug en
   **Releases** y en **Artifacts**.
4. Haz `push` a `develop`: sale la beta con APK por ABI.
5. Crea un tag `v1.0.0` en `main`: sale el release estable.

## Firma (opcional)

`DEBUG_KEYSTORE_BASE64` contiene una clave debug fija para que las actualizaciones
se instalen sin desinstalar la version anterior. El workflow la decodifica y crea
`android/app/debug.keystore` automaticamente.

Para firmar con una clave propia de release, anade estos Secrets en GitHub:

- `KEYSTORE_BASE64` (keystore en base64)
- `KEY_ALIAS`
- `STORE_PASSWORD`
- `KEY_PASSWORD`

El workflow crea `android/key.properties` automaticamente.

## Notas tecnicas

- Flutter 3.24.5, Dart 3.x, Java 17.
- Los workflows ejecutan `flutter create --platforms=android .` para generar el
  wrapper de Gradle y los recursos que no se versionan.
- `just_audio` muestra la notificacion de reproduccion en segundo plano.

## Funciones avanzadas incluidas

- Estadisticas de escucha, racha diaria y exportacion CSV.
- Letras automaticas con LRCLIB y resaltado karaoke.
- Crossfade, gapless, velocidad, temporizador y repeticion de cola.
- Busqueda, filtros, orden, cuadricula y seleccion multiple.
- Pestana Herramientas con duplicados, playlists, ecualizador y normalizacion.
- Exportacion M3U/CSV/JSON y guardado seguro con SAF.
- Material You desde la caratula, metadatos automaticos y escaneo al iniciar.
- Atajos de teclado, deslizamiento, doble toque y letra incrustada.

La interfaz se mantiene sin animaciones ni dock flotante para garantizar que
el cuerpo de la aplicacion siempre sea visible.
