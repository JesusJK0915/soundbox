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
