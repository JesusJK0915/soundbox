# SoundBox

Reproductor y biblioteca musical para Android compilado **100% en GitHub Actions**.
Tu PC solo sirve para escribir codigo y hacer `push`.

## Que hace

- Importa musica y video locales y los reproduce sin conexion.
- Detecta automaticamente si hay internet; si no hay, oculta la busqueda y usa solo la biblioteca local.
- Busca musica Creative Commons en **Internet Archive** y la descarga al dispositivo.
- Descargas con progreso, pausa y reanude (`Range`).
- Subtitulos `.srt` / `.vtt` que se adjuntan a una pista o video.
- Opcional: soporte para **Jamendo** poniendo tu `client_id` en `lib/core/config.dart`.

## Fuentes legales

SoundBox **no** descarga contenido con DRM ni de servicios de streaming privados.
Solo trabaja con archivos del usuario y fuentes abiertas/autorizadas.

## Como obtener el APK

1. Crea el repositorio en GitHub y sube este codigo.
2. Crea las ramas `alpha`, `develop` y `main`.
3. Haz `push` a `alpha`: el workflow `Alpha APK` compila y publica un APK debug en
   **Releases** y en **Artifacts**.
4. Haz `push` a `develop`: sale la beta con APK por ABI.
5. Crea un tag `v1.0.0` en `main`: sale el release estable.

## Firma (opcional)

Sin secrets, los APKs se firman con la clave debug de Flutter (instalables, pero
Android avisara de que son de desarrollo). Para firmar de verdad, anade estos
Secrets en GitHub:

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
