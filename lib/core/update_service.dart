import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';

/// Canal de publicacion. Alpha usa el APK debug y beta los APK por ABI.
enum UpdateChannel { alpha, beta }

enum UpdateStatus {
  idle,
  checking,
  available,
  upToDate,
  unknown,
  error,
  downloading,
  installing,
  installed,
}

/// Un release de GitHub ya adaptado al canal y al ABI del dispositivo.
class UpdateRelease {
  const UpdateRelease({
    required this.tag,
    required this.name,
    required this.notes,
    required this.pageUrl,
    required this.channel,
    required this.buildNumber,
    this.assetName,
    this.assetUrl,
    this.assetSize = 0,
    this.publishedAt,
  });

  final String tag;
  final String name;
  final String notes;
  final String pageUrl;
  final UpdateChannel channel;
  final int buildNumber;
  final String? assetName;
  final String? assetUrl;
  final int assetSize;
  final DateTime? publishedAt;

  String get sizeLabel => assetSize <= 0
      ? 'tamano desconocido'
      : '${(assetSize / 1024 / 1024).toStringAsFixed(1)} MB';
}

/// Comprueba los prereleases de GitHub y descarga el APK correspondiente.
///
/// La comparacion se hace con el numero de build inyectado por GitHub Actions
/// (`--dart-define=UPDATE_BUILD=<run_number>`), que es el mismo numero que
/// aparece al final de la etiqueta `v0.2.0-beta.<n>`.
class UpdateService extends ChangeNotifier {
  UpdateService([SharedPreferences? prefs]) : _prefs = prefs {
    _autoCheck = _prefs?.getBool(autoCheckKey) ?? true;
    _skippedTag = _prefs?.getString(skipKey) ?? '';
    _channel = channelFromName(updateChannelName);
  }

  static const MethodChannel _platform = MethodChannel('com.soundbox.app/update');
  static const autoCheckKey = 'updates.auto_check';
  static const lastCheckKey = 'updates.last_check';
  static const skipKey = 'updates.skip_tag';
  static const checkInterval = Duration(hours: 6);

  final SharedPreferences? _prefs;
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.github.com',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 25),
      headers: const <String, dynamic>{
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
        'User-Agent': 'SoundBox',
      },
    ),
  );

  late final UpdateChannel _channel;
  bool _autoCheck = true;
  String _skippedTag = '';
  UpdateStatus _status = UpdateStatus.idle;
  UpdateRelease? _release;
  String? _error;
  double _progress = 0;
  bool _promptShown = false;

  UpdateChannel get channel => _channel;
  bool get autoCheck => _autoCheck;
  UpdateStatus get status => _status;
  UpdateRelease? get release => _release;
  String? get error => _error;
  double get progress => _progress;
  bool get isChecking => _status == UpdateStatus.checking;
  bool get isBusy => _status == UpdateStatus.downloading ||
      _status == UpdateStatus.installing;
  bool get shouldPrompt => _status == UpdateStatus.available && !_promptShown;

  void markPromptShown() => _promptShown = true;

  Future<void> setAutoCheck(bool value) async {
    if (_autoCheck == value) return;
    _autoCheck = value;
    await _prefs?.setBool(autoCheckKey, value);
    notifyListeners();
  }

  /// Comprobacion silenciosa del arranque. Como minimo 6 horas entre intentos.
  Future<void> checkIfNeeded() async {
    if (!_autoCheck) return;
    final last = _prefs?.getInt(lastCheckKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - last < checkInterval.inMilliseconds) return;
    await check();
  }

  Future<void> check({bool force = false}) async {
    if (_status == UpdateStatus.checking || isBusy) return;
    _status = UpdateStatus.checking;
    _error = null;
    notifyListeners();

    try {
      final abi = await deviceAbi();
      final response = await _dio.get<List<dynamic>>(
        '/repos/$updateOwner/$updateRepo/releases',
        queryParameters: <String, dynamic>{'per_page': 100},
      );
      final releases = response.data ?? <dynamic>[];

      // GitHub no garantiza que /releases venga ordenado por numero de
      // version, asi que se elige el build mas alto del canal.
      final found = pickLatest(releases, _channel, abi);

      if (found == null) {
        _status = UpdateStatus.error;
        _error = 'No hay publicaciones para el canal ${_channel.name}.';
      } else if (isNewerTag(found.tag, updateBuildNumber) &&
          found.tag != _skippedTag) {
        _status = UpdateStatus.available;
      } else if (updateBuildNumber <= 0) {
        // Compilacion local: se muestra la ultima version, pero no se puede
        // comparar con un numero de build de GitHub Actions.
        _status = UpdateStatus.unknown;
      } else {
        _status = UpdateStatus.upToDate;
      }
      _release = found;
      await _prefs?.setInt(lastCheckKey, DateTime.now().millisecondsSinceEpoch);
    } catch (error) {
      _status = UpdateStatus.error;
      _error = error.toString();
    }
    notifyListeners();
  }

  Future<void> skip() async {
    final tag = _release?.tag;
    if (tag != null) {
      _skippedTag = tag;
      await _prefs?.setString(skipKey, tag);
    }
    _promptShown = true;
    _status = UpdateStatus.upToDate;
    notifyListeners();
  }

  Future<void> downloadAndInstall() async {
    final current = _release;
    if (current?.assetUrl == null || isBusy) return;

    _status = UpdateStatus.downloading;
    _progress = 0;
    _error = null;
    notifyListeners();

    try {
      final directory = await getTemporaryDirectory();
      final target = p.join(
        directory.path,
        current!.assetName ?? 'soundbox-update.apk',
      );
      await _dio.download(
        current.assetUrl!,
        target,
        onReceiveProgress: (received, total) {
          if (total <= 0) return;
          final value = received / total;
          _progress = value < 0 ? 0 : value > 1 ? 1 : value;
          notifyListeners();
        },
      );

      _status = UpdateStatus.installing;
      notifyListeners();

      final allowed = await _platform.invokeMethod<bool>('canInstall') ?? false;
      if (!allowed) {
        await _platform.invokeMethod('openInstallSettings');
        _status = UpdateStatus.available;
        _promptShown = false;
        _error = 'Activa "Instalar aplicaciones desconocidas" para SoundBox '
            'y vuelve a pulsar Instalar.';
        notifyListeners();
        return;
      }

      await _platform.invokeMethod(
        'installApk',
        <String, dynamic>{'path': target},
      );
      _status = UpdateStatus.installed;
      _promptShown = true;
      notifyListeners();
    } catch (error) {
      _status = UpdateStatus.error;
      _error = error.toString();
      notifyListeners();
    }
  }

  Future<void> openReleasePage() async {
    final url = _release?.pageUrl;
    if (url == null) return;
    try {
      await _platform.invokeMethod(
        'openUrl',
        <String, dynamic>{'url': url},
      );
    } catch (_) {}
  }

  static Future<String> deviceAbi() async {
    if (!Platform.isAndroid) return '';
    try {
      return await _platform.invokeMethod<String>('getAbi') ?? '';
    } catch (_) {
      return '';
    }
  }

  static UpdateChannel channelFromName(String value) =>
      value.toLowerCase() == 'alpha'
          ? UpdateChannel.alpha
          : UpdateChannel.beta;

  static String tagPrefix(UpdateChannel channel) => channel == UpdateChannel.alpha
      ? 'v0.1.0-alpha.'
      : 'v0.2.0-beta.';

  static int buildFromTag(String tag) =>
      int.tryParse(RegExp(r'(\d+)$').firstMatch(tag)?.group(1) ?? '') ?? 0;

  static bool isNewerTag(String tag, int currentBuild) =>
      currentBuild > 0 && buildFromTag(tag) > currentBuild;

  static String assetNameFor(UpdateChannel channel, String abi) {
    if (channel == UpdateChannel.alpha) return 'app-debug.apk';
    final normalized = abi.toLowerCase();
    if (normalized.contains('arm64')) return 'app-arm64-v8a-release.apk';
    if (normalized.contains('x86_64')) return 'app-x86_64-release.apk';
    return 'app-armeabi-v7a-release.apk';
  }

  /// Elige el release con el build mas alto, sin depender del orden de la API.
  static UpdateRelease? pickLatest(
    Iterable<dynamic> values,
    UpdateChannel channel,
    String abi,
  ) {
    UpdateRelease? best;
    for (final value in values) {
      final parsed = parseRelease(value, channel, abi);
      if (parsed == null) continue;
      if (best == null || parsed.buildNumber > best.buildNumber) best = parsed;
    }
    return best;
  }

  static UpdateRelease? parseRelease(
    dynamic value,
    UpdateChannel channel,
    String abi,
  ) {
    if (value is! Map) return null;
    final json = Map<String, dynamic>.from(value);
    final tag = json['tag_name'] as String?;
    if (tag == null || !tag.startsWith(tagPrefix(channel))) return null;

    final wanted = assetNameFor(channel, abi);
    String? assetName;
    String? assetUrl;
    var assetSize = 0;
    for (final candidate in (json['assets'] as List<dynamic>? ?? [])) {
      if (candidate is! Map) continue;
      if (candidate['name'] != wanted) continue;
      assetName = candidate['name'] as String?;
      assetUrl = candidate['browser_download_url'] as String?;
      assetSize = (candidate['size'] as num?)?.toInt() ?? 0;
      break;
    }

    return UpdateRelease(
      tag: tag,
      name: json['name'] as String? ?? tag,
      notes: json['body'] as String? ?? 'Sin notas de la version.',
      pageUrl: json['html_url'] as String? ??
          'https://github.com/$updateOwner/$updateRepo/releases',
      channel: channel,
      buildNumber: buildFromTag(tag),
      assetName: assetName,
      assetUrl: assetUrl,
      assetSize: assetSize,
      publishedAt: DateTime.tryParse(json['published_at'] as String? ?? ''),
    );
  }
}
