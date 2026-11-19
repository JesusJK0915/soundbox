# SoundBox

Reproductor y biblioteca musical para Android compilado **100% en GitHub Actions**.
Tu PC solo sirve para escribir codigo y hacer `push`.

## Que hace

- Importa musica local y la reproduce sin conexion (solo audio).
- Detecta automaticamente si hay internet; si no hay, oculta la busqueda y usa solo la biblioteca local.
- Busca en varias fuentes legales y descarga al dispositivo.
- Descargas con progreso, pausa y reanude (`Range`).
- Subtitulos `.srt` / `.vtt` que se adjuntan a una pista.
- Pega una **URL directa** a un archivo propio para descargarlo.

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

La app solo maneja audio: no importa ni descarga video.

Las claves tambien se pueden dejar en `lib/core/config.dart` como valores por defecto.

### ¿Por que no YouTube?

YouTube no expone una API de descarga y sus terminos prohiben extraer contenido.
Por eso SoundBox no incluye esa fuente: solo trabaja con licencias verificables,
descargas autorizadas y archivos del usuario. Para contenido tipo YouTube puedes
usar **Wikimedia Commons**, **Pixabay** o **Internet Archive**.

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
