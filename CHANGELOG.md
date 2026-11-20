# Changelog

## 1.0.3 (estable)

Release estable. No es alpha ni beta.

### Reproductor y versión

1. Reproductor centrado con `LayoutBuilder` y `Center`; los botones quedan visibles sin deslizar.
2. Carátula adaptable al ancho y alto reales del dispositivo.
3. Se ocultan chips, volumen y cola en pantallas compactas para priorizar los controles.
4. Indicador ondulado Material 3 Expressive (“gusanito”) solo mientras `player.isPlaying`.
5. Opción para activar/desactivar la onda en Ajustes.
6. Versión real de Android corregida: `1.0.3` / `versionCode 103`, sin el antiguo `0.1.0`.
7. Canal `stable` en el servicio de actualizaciones y en los workflows.
8. Comparación semver de etiquetas estables (`v1.0.3` → `103`).
9. Release publicado con `prerelease: false`.
10. CI de verificación para ramas `release/**` con build y tests.

### 100 funciones nuevas

`lib/core/pro_toolkit.dart` expone 100 utilidades puras y testeables:

#### Biblioteca (1–18)

1. Normalización de texto sin tildes.
2. Clave de título sin entreparéntesis.
3. Clave de artista sin `feat.`/`&`.
4. División de varios artistas.
5. Detección de versiones en vivo.
6. Detección de remezclas.
7. Detección de instrumentales/karaoke.
8. Detección de covers acústicos.
9. Etiqueta de duración legible.
10. Etiqueta de tamaño de archivo.
11. Etiqueta de bitrate.
12. Sanitización de nombres de archivo.
13. Tokenización para búsqueda.
14. Puntuación de coincidencia de búsqueda.
15. Agrupación por álbum.
16. Agrupación por artista.
17. Campos incompletos de una pista.
18. Detección de duplicados.

#### Reproducción (19–37)

19. Top de géneros.
20. Salud de biblioteca.
21. Limitación segura de duración.
22. Siguiente índice de cola.
23. Índice anterior de cola.
24. Orden aleatorio reproducible.
25. Etiqueta de repetición.
26. Etiqueta de velocidad.
27. Porcentaje de volumen.
28. Volumen desde porcentaje.
29. Ganancia en dB.
30. Milisegundos de crossfade.
31. Hora estimada de fin del temporizador.
32. Etiqueta de tiempo restante.
33. Progreso porcentual.
34. Detección de fin próximo.
35. Búsqueda segura dentro de la duración.
36. Índice de letra por posición.
37. Fracción de karaoke.

#### Descargas y proveedores (38–55)

38. Resumen de cola.
39. Etiqueta de salto de silencio.
40. Volumen recomendado según ahorro de batería.
41. Extensión según formato.
42. Formato inferido de una URL.
43. Detección de URL directa de audio.
44. Validación de proveedor legal.
45. Nombre seguro de descarga.
46. Estimación de bytes por bitrate y duración.
47. Etiqueta de calidad.
48. Mejor bitrate disponible.
49. MIME por extensión.
50. Detección de formato sin pérdida.
51. Limpieza de query string.
52. Etiqueta de proveedor.
53. Retroceso exponencial de reintentos.
54. Validación de bitrate.
55. Etiqueta de formato.

#### Playlists y letras (56–75)

56. Cabecera M3U.
57. Entrada M3U con `EXTINF`.
58. Cabecera CSV.
59. Fila CSV con escapado.
60. Escape JSON.
61. Unión sin duplicados.
62. Deduplicación de pistas.
63. Orden configurable de pistas.
64. Filtrado de pistas por consulta.
65. Nombre automático de playlist.
66. Parseo de timestamp LRC.
67. Parseo de línea LRC.
68. Ordenación de letras.
69. Línea activa por posición.
70. Índice de siguiente línea.
71. Eliminación de metadata LRC.
72. Letra plana sin timestamps.
73. Conteo de palabras.
74. Velocidad de lectura.
75. Desplazamiento sincronizado de letras.

#### Ajustes y mantenimiento (76–100)

76. Etiqueta de modo de tema.
77. Etiqueta de ahorro de datos.
78. Etiqueta booleana.
79. Bitrate más cercano.
80. Parseo de preferencia de bitrate.
81. Etiqueta de orden.
82. Semilla de color de acento.
83. Clave de backup por versión.
84. Validación de nombre visible.
85. Etiqueta de canal de actualización.
86. Etiqueta de tamaño de caché.
87. Política de limpieza de caché.
88. Detección de subtítulos huérfanos.
89. Antigüedad de descargas.
90. Presión de almacenamiento.
91. Etiqueta de permiso.
92. Huella de logs.
93. Puntaje de diagnóstico.
94. Recomendación de mantenimiento.
95. Etiqueta de batería.
96. Etiqueta de red.
97. Código de versión desde texto.
98. Etiqueta de funcionalidad.
99. Etiqueta de build.
100. Resumen de soporte.

### 50 mejoras sobre las funciones nuevas

1. Normalización usa `RegExp` combinadas para evitar pasadas redundantes.
2. `titleKey` colapsa espacios después de quitar corchetes.
3. `artistKey` colapsa espacios después de quitar colaboraciones.
4. `splitArtists` ignora entradas vacías.
5. `isLive` usa límites de palabra.
6. `isRemix` usa límites de palabra.
7. `isInstrumental` reconoce karaoke y backing.
8. `isCover` reconoce “versión acústica”.
9. `durationLabel` soporta horas.
10. `fileSizeLabel` usa una cifra decimal legible.
11. `bitrateLabel` sanea valores nulos o no positivos.
12. `sanitizeFileName` quita tildes en mayúsculas y minúsculas.
13. `sanitizeFileName` elimina puntos y guiones sobrantes al inicio/fin.
14. `searchTokens` descarta tokens de una letra.
15. `searchScore` prioriza coincidencia exacta y prefijo.
16. `groupByAlbum` usa “Sin album” como valor seguro.
17. `groupByArtist` conserva el orden de inserción.
18. `missingFields` reporta nombres en español.
19. `duplicateGroups` elimina grupos de una sola pista.
20. `topGenres` ordena por frecuencia y respeta `limit`.
21. `libraryHealth` devuelve porcentaje redondeado.
22. `clampDuration` es reutilizable por `seekClamp`.
23. `nextIndex` respeta repetición de cola.
24. `previousIndex` respeta repetición de cola.
25. `shuffledIndices` usa Fisher–Yates con semilla.
26. `repeatLabel` cubre los tres modos.
27. `speedLabel` fija dos decimales.
28. `volumePercent` limita el rango.
29. `volumeFromPercent` limita el rango.
30. `gainDb` devuelve −60 dB para silencio.
31. `crossfadeMs` limita a 12 segundos.
32. `remainingLabel` rellena ceros.
33. `progressPercent` evita división por cero.
34. `isNearEnd` usa un margen de 5 segundos.
35. `lyricIndexAt` busca desde el final.
36. `karaokeFraction` limita el resultado a 0..1.
37. `queueSummary` distingue cola vacía.
38. `extensionForFormat` normaliza `mpeg` a `mp3`.
39. `formatFromUrl` ignora mayúsculas en la extensión.
40. `isDirectAudioUrl` ignora query string.
41. `isLegalSource` acepta rutas locales.
42. `safeDownloadName` limpia puntos iniciales.
43. `estimateBytes` calcula KBps desde kbps.
44. `qualityLabel` escala de Estándar a Máxima.
45. `bestBitrate` elige la mejor opción ≥ preferida.
46. `mimeForExtension` cubre cinco formatos de audio.
47. `isLossless` distingue FLAC/WAV.
48. `cleanUrl` conserva la URL si no es parseable.
49. `providerLabel` nombra los seis proveedores y URL directa.
50. `retryDelaySeconds` limita el retroceso a 30 segundos.

### 50 mejoras sobre funciones anteriores

1. Búsqueda de biblioteca usa normalización sin tildes.
2. Búsqueda de biblioteca usa puntuación por tokens.
3. Detección de duplicados usa `titleKey`/`artistKey`.
4. Exportación M3U deduplica pistas.
5. Exportación M3U reutiliza la cabecera centralizada.
6. Exportación M3U reutiliza la entrada `EXTINF`.
7. Letras de LRCLIB usan claves normalizadas.
8. Letras planas eliminan metadata antes de mostrarlas.
9. User-Agent de LRCLIB refleja la versión estable.
10. `PlayerService.seek` limita la posición a la duración real.
11. `shuffleQueue` usa el orden aleatorio del toolkit.
12. `UpdateService` añade canal `stable`.
13. `channelFromName` acepta `stable`.
14. `tagPrefix` devuelve `v` para estable.
15. `buildFromTag` entiende semver estable.
16. `parseRelease` ignora prereleases en estable.
17. `pickLatest` compara builds semver.
18. `assetNameFor` sirve los APK por ABI en estable.
19. `pubspec.yaml` fija versión real `1.0.3+103`.
20. `config.dart` fija `appVersion` y canal por defecto estable.
21. Ajustes muestran “Version 1.0.3 (estable)”.
22. Ajustes incluyen el interruptor de la onda expresiva.
23. Workflow `release.yml` calcula el código desde la etiqueta.
24. Workflow `release.yml` inyecta `UPDATE_CHANNEL=stable`.
25. Workflow `release.yml` inyecta `UPDATE_BUILD`.
26. Workflow `release.yml` publica `prerelease: false`.
27. Workflow `check.yml` valida ramas `release/**`.
28. Tests de actualizaciones cubren estable y semver.
29. Tests del toolkit cubren las 100 funciones.
30. README elimina referencias al dock flotante.
31. README documenta el reproductor centrado.
32. README documenta el gusanito Material Expressive.
33. README documenta los 100 métodos y 100 mejoras.
34. Se mantiene la advertencia literal de bienvenida.
35. Se mantiene solo audio, sin vídeo.
36. Se mantienen los seis proveedores legales.
37. Se mantiene LRCLIB (Recomendado), sin IA local.
38. No se reintroduce `floating_dock.dart`.
39. No se reintroducen animaciones globales.
40. La onda aparece solo dentro del reproductor.
41. La onda desaparece al pausar.
42. La onda respeta la preferencia del usuario.
43. El reproductor usa `FittedBox` en pantallas bajas.
44. El reproductor usa `SafeArea`.
45. El reproductor conserva gestos y doble toque.
46. El reproductor conserva mini reproductor fijo.
47. El reproductor conserva cola y volumen en pantallas altas.
48. El CI ejecuta `flutter analyze` y `flutter test`.
49. El CI construye APK por ABI con firma debug disponible.
50. Las ramas `main`, `alpha` y `develop` se sincronizan al release final.
