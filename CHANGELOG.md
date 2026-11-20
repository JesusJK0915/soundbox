# Changelog

## 1.1.0 (estable)

Release estable. No es alpha ni beta. Construida sobre `v1.0.3` sin reintroducir el dock flotante.

### Reproductor, navegación e historial

1. El gusanito Material Expressive 3 se dibuja ahora sobre el control deslizante del tiempo, en la posición del pulgar.
2. El pulgar del slider se oculta mientras el gusanito está visible para que no se vea un círculo detrás de la onda.
3. La onda sigue apareciendo solo cuando `player.isPlaying` y `prefs.expressiveWorm` están activos.
4. El interruptor de Ajustes ahora describe explícitamente que la onda va sobre el control del tiempo.
5. Se añadió deslizamiento horizontal entre las cinco pestañas, respetando el ajuste `Gestos`.
6. El cambio de pestaña por swipe usa el mismo `_goTo` que la barra inferior, con háptico opcional.
7. El Historial muestra botones rellenos estilo Material Expressive en lugar de filas planas.
8. Cada botón del Historial responde con animación de escala y onda de tinta al tocarlo.
9. Los botones del Historial mantienen carátula, título, artista y posición.
10. Versión real de Android `1.1.0` con `versionCode 110`.

### 200 funciones nuevas

`lib/core/pro_toolkit.dart` pasa de 100 a 300 utilidades puras. Las 200 nuevas se agrupan por área:

#### Biblioteca avanzada (1–20)

1. `uniqueTitles` cuenta títulos únicos tras normalizar.
2. `uniqueArtists` cuenta artistas únicos.
3. `uniqueAlbums` cuenta álbumes únicos.
4. `trackCountByArtist` cuenta pistas de un artista.
5. `trackCountByAlbum` cuenta pistas de un álbum.
6. `longestTitle` devuelve el título más largo.
7. `shortestTitle` devuelve el título más corto.
8. `averageDuration` calcula la duración media.
9. `totalDurationLabel` etiqueta la duración total.
10. `localCount` cuenta pistas locales.
11. `onlineCount` cuenta pistas online.
12. `downloadedCount` cuenta pistas descargadas.
13. `missingArtworkCount` cuenta carátulas ausentes.
14. `missingGenreCount` cuenta géneros ausentes.
15. `taggedCount` cuenta pistas con etiquetas leídas.
16. `untaggedCount` cuenta pistas sin etiquetas.
17. `oldestYear` devuelve el año más antiguo.
18. `newestYear` devuelve el año más reciente.
19. `yearRangeLabel` forma un rango de años legible.
20. `libraryScore` puntúa la salud de la biblioteca.

#### Reproducción avanzada (21–40)

21. `isTrackFinished` detecta el final de la pista.
22. `isTrackStarting` detecta el inicio de la pista.
23. `forwardSeek` aplica un salto hacia adelante limitado.
24. `backwardSeek` aplica un salto hacia atrás limitado.
25. `replaySeconds` calcula el punto de repetición final.
26. `loopIndex` devuelve un índice circular seguro.
27. `bounceIndex` devuelve un índice en vaivén.
28. `queuePositionLabel` formatea la posición de la cola.
29. `remainingTracks` cuenta las pistas restantes.
30. `playedFraction` calcula la fracción reproducida.
31. `volumeStep` ajusta el volumen con límite.
32. `normalizedGain` limita la ganancia a ±20 dB.
33. `isSilent` detecta volumen silencioso.
34. `shuffleSeed` genera una semilla determinista.
35. `repeatCycle` rota apagado/todo/uno.
36. `speedStep` ajusta la velocidad de forma segura.
37. `speedLabelShort` da una etiqueta corta de velocidad.
38. `sleepMinutesLabel` etiqueta el temporizador.
39. `isLongTrack` detecta pistas largas.
40. `isShortTrack` detecta pistas cortas.

#### Búsqueda avanzada (41–60)

41. `queryWords` extrae las palabras de una consulta.
42. `queryIsEmpty` detecta consultas vacías.
43. `matchesAllTokens` exige que todas las palabras coincidan.
44. `matchesAnyToken` admite que coincida una sola palabra.
45. `highlightRanges` devuelve posiciones para resaltar.
46. `tokenOverlapScore` mide similitud de tokens.
47. `fuzzyContains` realiza coincidencia difusa.
48. `titleStartsWith` comprueba el inicio del título.
49. `artistStartsWith` comprueba el inicio del artista.
50. `albumContains` busca dentro del álbum.
51. `bestMatchIndex` localiza el mejor resultado.
52. `sortedByQuery` ordena por relevancia sin mutar.
53. `normalizeQuery` normaliza la consulta.
54. `stripQuotes` elimina comillas.
55. `expandWildcard` elimina comodines.
56. `isExactPhrase` detecta frases exactas.
57. `phraseTokens` obtiene las palabras de la frase.
58. `searchHint` genera una pista contextual.
59. `resultCountLabel` etiqueta el número de resultados.
60. `noResultsMessage` genera el mensaje sin resultados.

#### Descargas y proveedores (61–80)

61. `isAudioExtension` valida extensiones de audio.
62. `isVideoExtension` detecta extensiones de vídeo rechazadas.
63. `isSubtitleExtension` detecta subtítulos.
64. `safeFormat` elige un formato seguro.
65. `providerKey` identifica el proveedor.
66. `providerNeedsAttribution` marca atribución obligatoria.
67. `attributionText` genera el crédito.
68. `isPlainFileUrl` detecta URL directa a archivo.
69. `hostFromUrl` extrae el dominio.
70. `urlWithoutQuery` limpia parámetros y fragmentos.
71. `urlScheme` devuelve el esquema.
72. `isSecureUrl` exige HTTPS.
73. `qualityRank` prioriza la calidad.
74. `bestQualityUrl` elige la mejor URL.
75. `fileNameFromUrl` sanitiza el nombre del archivo.
76. `fileExtensionFromName` extrae la extensión.
77. `downloadStateLabel` nombra los siete estados.
78. `isTerminalStatus` detecta estados finales.
79. `progressPercentDone` calcula el progreso.
80. `etaLabel` estima el tiempo restante.

#### Playlists y colas (81–100)

81. `playlistSlug` genera un slug.
82. `playlistColorSeed` da un color estable.
83. `trackIds` extrae identificadores.
84. `uniqueTrackIds` quita duplicados.
85. `playlistDuration` suma duraciones.
86. `isPlaylistEmpty` detecta listas vacías.
87. `playlistSizeLabel` etiqueta el tamaño.
88. `insertAtIndex` inserta una pista.
89. `removeFirstWhere` quita una pista por ID.
90. `moveTrack` mueve una pista.
91. `swapTracks` intercambia dos pistas.
92. `rotateQueue` rota la cola.
93. `chunkTracks` divide en bloques.
94. `interleave` intercala dos listas.
95. `repeatTracks` repite pistas.
96. `takeEveryNth` toma cada N pistas.
97. `playlistOverlap` mide solapamiento.
98. `mergePlaylists` une sin duplicados.
99. `shuffleWithSeed` aplica aleatorio con semilla.
100. `playlistChecksum` calcula una suma de control.

#### Letras y sincronización (101–120)

101. `lrcLineCount` cuenta líneas de letra.
102. `hasTimestamps` detecta marcas de tiempo.
103. `firstTimestamp` lee la primera marca.
104. `lastTimestamp` lee la última marca.
105. `lyricsDurationLabel` etiqueta la duración de la letra.
106. `lineAtPercent` elige una línea por porcentaje.
107. `activeLineWindow` devuelve la ventana activa.
108. `lineBefore` devuelve la línea anterior.
109. `lineAfter` devuelve la línea siguiente.
110. `isBlankLine` detecta líneas vacías.
111. `trimLrcLine` quita la marca de tiempo.
112. `lrcTagValue` lee una etiqueta LRC.
113. `metadataTags` reúne los metadatos.
114. `stripMetadataTags` limpia cabeceras.
115. `dedupeLines` elimina líneas repetidas.
116. `karaokeWordCount` cuenta palabras por línea.
117. `estimateSingingSeconds` estima segundos de canto.
118. `syncOffsetFromTap` calcula el desfase de un toque.
119. `lyricSearchQuery` prepara la consulta LRCLIB.
120. `tooFastWarning` avisa de letra demasiado rápida.

#### Ajustes y accesibilidad (121–140)

121. `themeLabelShort` reduce el tema a tres nombres.
122. `contrastLabel` describe el contraste.
123. `reduceMotionLabel` describe el movimiento reducido.
124. `hapticsLabel` describe la vibración.
125. `gesturesLabel` describe los gestos.
126. `wifiOnlyLabel` indica uso de solo Wi-Fi.
127. `dataSaverNote` explica el ahorro de datos.
128. `autoLyricsLabel` describe las letras automáticas.
129. `wormLabel` describe la onda del tiempo.
130. `miniPlayerLabel` describe el mini reproductor.
131. `shuffleByDefaultLabel` describe el aleatorio inicial.
132. `sortModeLabel` nombra los cinco modos de orden.
133. `gridLabel` describe la vista de cuadrícula.
134. `notificationLabel` describe la notificación.
135. `batterySaverLabel` describe el ahorro de batería.
136. `privacyLabel` indica el ámbito de los datos.
137. `languageLabel` nombra el idioma.
138. `accentColorName` nombra el color de acento.
139. `settingsSearchTerm` normaliza la búsqueda de ajustes.
140. `resetSummary` resume un reinicio.

#### Estadísticas y hábitos (141–160)

141. `incrementPlayCount` incrementa sin mutar el mapa.
142. `playCount` lee el conteo de una pista.
143. `topTrackId` encuentra la pista favorita.
144. `totalPlays` suma todas las reproducciones.
145. `averagePlays` calcula la media.
146. `playRateLabel` calcula reproducciones por día.
147. `streakDays` calcula días consecutivos.
148. `lastPlayedLabel` formatea la última escucha.
149. `listeningMinutesLabel` formatea minutos escuchados.
150. `favoriteRatio` calcula la proporción de favoritas.
151. `completionRate` calcula finalizaciones.
152. `skipRate` calcula saltos.
153. `dailyGoalLabel` describe la meta diaria.
154. `weeklyGoalLabel` describe la meta semanal.
155. `moodFromGenre` infiere un estado del género.
156. `moodLabel` etiqueta el estado.
157. `listeningSlotLabel` nombra la franja horaria.
158. `peakHour` detecta la hora pico.
159. `recommendationReason` explica una recomendación.
160. `statsBadge` asigna una insignia.

#### Mantenimiento y diagnóstico (161–180)

161. `bytesToGb` formatea gigabytes.
162. `freeSpaceWarning` avisa de poco espacio.
163. `isLowStorage` detecta almacenamiento crítico.
164. `cacheEntriesLabel` cuenta entradas de caché.
165. `clearCacheNote` calcula espacio liberable.
166. `orphanCount` cuenta subtítulos huérfanos.
167. `duplicatePathCount` detecta rutas repetidas.
168. `safePathJoin` une rutas de forma segura.
169. `isValidFileName` valida nombres de archivo.
170. `truncatedName` recorta con elipsis.
171. `logLine` formatea una línea de log.
172. `errorSummary` resume incidencias.
173. `healthLabel` nombra el estado de salud.
174. `repairAction` recomienda una reparación.
175. `backupName` nombra la copia de seguridad.
176. `restoreNote` indica si hay copia.
177. `diagnosticLine` formatea un diagnóstico.
178. `permissionStatusLabel` describe un permiso.
179. `crashMarker` extrae la primera línea de un stack.
180. `supportTicketId` genera un ID de soporte.

#### Exportación y metadatos (181–200)

181. `m3uExtendedLine` genera una línea EXTINF.
182. `m3uComment` genera un comentario M3U.
183. `m3uTitle` genera el título M3U.
184. `xspfTrackLine` genera una pista XSPF.
185. `csvEscape` escapa valores CSV.
186. `shareText` prepara texto para compartir.
187. `shareSubject` prepara el asunto.
188. `attributionFooter` genera el pie de atribución.
189. `licenseBadge` nombra la licencia.
190. `legalProvidersCsv` enumera proveedores legales.
191. `youtubeNotice` recuerda la restricción de audio.
192. `directUrlHint` explica las URL directas.
193. `fileUri` construye una URI de archivo.
194. `encodedQuery` codifica parámetros.
195. `decodeQuery` decodifica parámetros.
196. `trackFingerprint` calcula una huella de pista.
197. `playlistExportName` nombra la exportación.
198. `metadataSummary` resume los metadatos.
199. `bitrateQualityLabel` nombra la calidad por bitrate.
200. `sampleRateLabel` formatea la frecuencia de muestreo.

### 100 mejoras nuevas sobre funciones recientes

#### Salud y biblioteca (1–10)

1. `libraryScore` combina carátulas, géneros, etiquetas y duplicados.
2. `averageDuration` ignora pistas sin duración.
3. `yearRangeLabel` une años iguales en una sola cifra.
4. `missingArtworkCount` respeta carátulas locales y remotas.
5. `taggedCount` distingue etiquetas leídas de sin leer.
6. `uniqueTitles` usa claves normalizadas en vez de texto crudo.
7. `trackCountByArtist` compara sin tildes ni `feat.`.
8. `libraryHealth` y `libraryScore` comparten criterios.
9. `totalDurationLabel` reutiliza el formateo de duración.
10. `duplicateGroups` alimenta el diagnóstico de salud.

#### Reproducción y cola (11–20)

11. `forwardSeek` nunca supera la duración.
12. `backwardSeek` nunca baja de cero.
13. `loopIndex` admite índices negativos.
14. `bounceIndex` evita repetir extremos.
15. `playedFraction` devuelve siempre entre 0 y 1.
16. `volumeStep` y `speedStep` acotan el rango.
17. `repeatCycle` cierra el ciclo apagado/todo/uno.
18. `isNearEnd` e `isTrackFinished` usan umbrales distintos.
19. `queuePositionLabel` maneja colas vacías.
20. `shuffleSeed` es determinista por lista.

#### Búsqueda (21–30)

21. `queryWords` elimina espacios repetidos.
22. `normalizeQuery` reutiliza la normalización global.
23. `fuzzyContains` tolera caracteres intercalados.
24. `tokenOverlapScore` usa intersección sobre unión.
25. `matchesAllTokens` y `matchesAnyToken` comparten tokenizer.
26. `bestMatchIndex` devuelve -1 sin resultados.
27. `sortedByQuery` no muta la lista original.
28. `stripQuotes` limpia comillas dobles y simples.
29. `expandWildcard` elimina `*` y `%`.
30. `searchHint` cambia con la consulta.

#### Descargas (31–40)

31. `providerKey` reconoce seis proveedores y directo.
32. `providerNeedsAttribution` marca los que exigen crédito.
33. `attributionText` cae a fuente desconocida.
34. `hostFromUrl` usa `Uri.tryParse` sin lanzar.
35. `urlWithoutQuery` limpia también fragmentos.
36. `isSecureUrl` exige HTTPS.
37. `bestQualityUrl` elige por `qualityRank`.
38. `fileNameFromUrl` sanitiza el nombre final.
39. `downloadStateLabel` cubre los siete estados.
40. `etaLabel` muestra segundos o minutos.

#### Playlists (41–50)

41. `playlistSlug` quita acentos y guiones sobrantes.
42. `playlistColorSeed` da color estable por nombre.
43. `uniqueTrackIds` evita duplicados al exportar.
44. `moveTrack` acota el destino.
45. `swapTracks` valida ambos índices.
46. `chunkTracks` respeta el tamaño del último bloque.
47. `interleave` conserva listas desiguales.
48. `mergePlaylists` usa `mergeUnique`.
49. `shuffleWithSeed` reutiliza Fisher–Yates.
50. `playlistChecksum` cambia con el orden.

#### Letras (51–60)

51. `lrcLineCount` ignora líneas vacías.
52. `hasTimestamps` acepta puntos y comas decimales.
53. `firstTimestamp` y `lastTimestamp` comparten parser.
54. `lineAtPercent` acota el porcentaje.
55. `activeLineWindow` recorta en los extremos.
56. `metadataTags` lee cinco etiquetas LRC.
57. `stripMetadataTags` conserva líneas con tiempo.
58. `dedupeLines` elimina repeticiones.
59. `syncOffsetFromTap` firma el desfase.
60. `lyricSearchQuery` prepara la búsqueda LRCLIB.

#### Ajustes (61–70)

61. `themeLabelShort` unifica sistema, claro y oscuro.
62. `wormLabel` describe la nueva ubicación del gusanito.
63. `miniPlayerLabel` refleja el reproductor fijo.
64. `sortModeLabel` comparte los cinco modos.
65. `accentColorName` elige entre seis nombres.
66. `languageLabel` prioriza español.
67. `dataSaverNote` explica la calidad elegida.
68. `batterySaverLabel` distingue ahorro y rendimiento.
69. `privacyLabel` indica sincronización.
70. `resetSummary` singulariza el conteo.

#### Estadísticas (71–80)

71. `incrementPlayCount` no muta el mapa original.
72. `topTrackId` devuelve null sin datos.
73. `streakDays` reinicia la racha tras huecos.
74. `lastPlayedLabel` entrega solo la fecha.
75. `favoriteRatio` acota el resultado.
76. `completionRate` evita división por cero.
77. `skipRate` acota entre 0 y 1.
78. `moodFromGenre` normaliza el género.
79. `peakHour` elige la hora más frecuente.
80. `statsBadge` reparte tres niveles.

#### Mantenimiento (81–90)

81. `freeSpaceWarning` avisa por debajo de 1 GB.
82. `isLowStorage` usa un umbral más estricto.
83. `cacheEntriesLabel` singulariza.
84. `duplicatePathCount` usa un `Set`.
85. `safePathJoin` normaliza barras finales.
86. `isValidFileName` rechaza caracteres prohibidos.
87. `truncatedName` conserva la elipsis.
88. `errorSummary` distingue cero errores.
89. `repairAction` escala con la puntuación.
90. `supportTicketId` rellena con ceros.

#### Exportación (91–100)

91. `m3uExtendedLine` calcula segundos desde milisegundos.
92. `m3uTitle` y `m3uComment` siguen el estándar.
93. `csvEscape` duplica comillas internas.
94. `shareText` nombra la app.
95. `licenseBadge` reconoce Creative Commons.
96. `legalProvidersCsv` enumera solo fuentes legales.
97. `youtubeNotice` recuerda la restricción de audio.
98. `encodedQuery` y `decodeQuery` son simétricas.
99. `trackFingerprint` usa claves normalizadas.
100. `sampleRateLabel` convierte a kHz.

### 100 mejoras nuevas sobre funciones anteriores

#### Utilidades base (1–10)

1. `seekClamp` sigue usando `clampDuration`.
2. `durationLabel` mantiene `mm:ss` y `h:mm:ss`.
3. `fileSizeLabel` conserva B, KB y MB.
4. `safeDownloadName` reutiliza `sanitizeFileName`.
5. `cacheSizeLabel` delega en `fileSizeLabel`.
6. `filterTracks` usa `searchScore` normalizado.
7. `playlistName` limpia artistas con `splitArtists`.
8. `sortTracks` no pierde pistas.
9. `dedupeTracks` conserva el primer elemento.
10. `mergeUnique` mantiene el orden de llegada.

#### Reproducción anterior (11–20)

11. `nextIndex` y `previousIndex` siguen siendo circulares.
12. `repeatLabel` mantiene tres estados en español.
13. `speedLabel` conserva dos decimales.
14. `volumePercent` acota entre 0 y 100.
15. `volumeFromPercent` invierte la conversión.
16. `gainDb` redondea a un decimal.
17. `crossfadeMs` limita el solapamiento.
18. `sleepFinish` calcula la hora de fin.
19. `remainingLabel` conserva el formato de duración.
20. `progressPercent` acota entre 0 y 100.

#### Descargas anteriores (21–30)

21. `extensionForFormat` sigue priorizando MP3.
22. `mimeForExtension` mantiene los MIME de audio.
23. `formatFromUrl` lee la extensión sin query.
24. `cleanUrl` elimina parámetros de seguimiento.
25. `isDirectAudioUrl` sigue rechazando vídeo.
26. `isLegalSource` mantiene la lista de proveedores.
27. `providerLabel` conserva nombres completos.
28. `qualityLabel` sigue los cuatro niveles.
29. `retryDelaySeconds` aplica espera exponencial.
30. `estimateBytes` usa el bitrate declarado.

#### Playlists y letras anteriores (31–40)

31. `m3uHeader` mantiene `#EXTM3U`.
32. `m3uEntry` conserva `#EXTINF`.
33. `csvHeader` no cambia las columnas.
34. `csvRow` sigue escapando con comillas.
35. `jsonEscape` conserva saltos de línea.
36. `parseTimestamp` acepta `mm:ss` y `hh:mm:ss`.
37. `parseLrcLine` separa marca y texto.
38. `sortLyrics` ordena por tiempo.
39. `lineAt` devuelve null fuera de rango.
40. `nextLineIndex` respeta el final.

#### Letras y ajustes anteriores (41–50)

41. `stripLrcMeta` elimina cabeceras.
42. `plainLyrics` conserva el orden.
43. `wordCount` ignora espacios vacíos.
44. `readingSpeed` usa 180 palabras por minuto.
45. `syncedOffset` mantiene el desfase guardado.
46. `themeModeLabel` sigue tres opciones.
47. `dataSaverLabel` no cambia su redacción.
48. `boolLabel` mantiene Sí/No.
49. `clampBitrate` acota 64 a 320.
50. `parseBitratePreference` acepta texto libre.

#### Ajustes y diagnóstico anteriores (51–60)

51. `sortLabel` conserva los cinco modos.
52. `accentSeed` sigue derivado del artista.
53. `backupKey` mantiene el prefijo.
54. `validateDisplayName` rechaza vacíos.
55. `channelLabel` distingue alpha y stable.
56. `logFingerprint` sigue siendo corto.
57. `diagnosticScore` conserva su ponderación.
58. `recommendationFor` no cambia el criterio.
59. `batteryLabel` mantiene porcentajes.
60. `networkLabel` sigue Wi-Fi y datos.

#### Versión y agrupación anterior (61–70)

61. `versionCodeFrom` mantiene `major*100+minor*10+patch`.
62. `featureTag` conserva `on/off`.
63. `buildTag` mantiene `versión (código)`.
64. `supportSummary` sigue con estado de red.
65. `groupByAlbum` conserva el primer álbum.
66. `groupByArtist` normaliza colaboraciones.
67. `missingFields` sigue detectando carátula y género.
68. `topGenres` respeta el límite opcional.
69. `isLive`, `isRemix` e `isCover` mantienen sus regex.
70. `isInstrumental` sigue buscando palabras clave.

#### Búsqueda y archivos anteriores (71–80)

71. `titleKey` elimina paréntesis y corchetes.
72. `artistKey` quita `feat.` y `&`.
73. `searchTokens` conserva tokens únicos.
74. `searchScore` prioriza título sobre artista.
75. `sanitizeFileName` sigue reemplazando caracteres ilegales.
76. `bitrateLabel` muestra kbps redondeado.
77. `isLossless` reconoce FLAC y WAV.
78. `safeDownloadName` conserva la extensión.
79. `mimeForExtension` sigue devolviendo `audio/*`.
80. `formatLabel` mantiene las etiquetas mayúsculas.

#### Reproductor anterior (81–90)

81. `progressPercent` sigue alimentando la barra.
82. `lyricIndexAt` mantiene su búsqueda.
83. `karaokeFraction` conserva el avance por palabra.
84. `queueSummary` sigue resumiendo la cola.
85. `skipSilenceLabel` mantiene su texto.
86. `recommendedVolume` no cambia los perfiles.
87. `isNearEnd` sigue con 5 segundos.
88. `crossfadeMs` conserva el máximo.
89. `sleepFinish` sigue sumando minutos.
90. `remainingLabel` no cambia su formato.

#### Mantenimiento anterior (91–100)

91. `cacheSizeLabel` mantiene MB.
92. `cleanCachePolicy` sigue conservando lo descargado.
93. `orphanSubtitleName` conserva el sufijo.
94. `oldDownloadDays` mantiene 30 días.
95. `storagePressure` sigue con tres niveles.
96. `permissionLabel` mantiene concedido y denegado.
97. `recommendationFor` no consulta la red.
98. `channelLabel` sigue devolviendo `Beta` por defecto.
99. `versionCodeFrom` descarta versiones incompletas.
100. `supportSummary` sigue sin exponer datos personales.

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
