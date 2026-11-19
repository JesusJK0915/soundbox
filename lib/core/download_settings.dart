import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AudioFormat {
  mp3,
  m4a,
  ogg,
  flac,
  wav,
  original,
}

extension AudioFormatLabel on AudioFormat {
  String get label {
    switch (this) {
      case AudioFormat.mp3:
        return 'MP3';
      case AudioFormat.m4a:
        return 'M4A (AAC)';
      case AudioFormat.ogg:
        return 'OGG (Vorbis)';
      case AudioFormat.flac:
        return 'FLAC (sin perdida)';
      case AudioFormat.wav:
        return 'WAV (sin perdida)';
      case AudioFormat.original:
        return 'Original (sin convertir)';
    }
  }
}

/// Formato y bitrate aplicados al convertir las descargas en el dispositivo.
class DownloadSettingsService extends ChangeNotifier {
  static const _formatKey = 'download.format';
  static const _bitrateKey = 'download.bitrate';
  static const int defaultBitrate = 192;
  static const List<int> bitrates = <int>[64, 96, 128, 192, 256, 320];

  DownloadSettingsService([SharedPreferences? prefs]) : _prefs = prefs {
    final stored = _prefs?.getString(_formatKey);
    format = AudioFormat.values.firstWhere(
      (value) => value.name == stored,
      orElse: () => AudioFormat.mp3,
    );
    bitrate = _prefs?.getInt(_bitrateKey) ?? defaultBitrate;
  }

  final SharedPreferences? _prefs;

  late AudioFormat format;
  late int bitrate;

  static Future<DownloadSettingsService> load() async =>
      DownloadSettingsService(await SharedPreferences.getInstance());

  bool get isLossy => format == AudioFormat.mp3 ||
      format == AudioFormat.m4a ||
      format == AudioFormat.ogg;

  String get extension {
    switch (format) {
      case AudioFormat.mp3:
        return '.mp3';
      case AudioFormat.m4a:
        return '.m4a';
      case AudioFormat.ogg:
        return '.ogg';
      case AudioFormat.flac:
        return '.flac';
      case AudioFormat.wav:
        return '.wav';
      case AudioFormat.original:
        return '';
    }
  }

  String get mime {
    switch (format) {
      case AudioFormat.mp3:
        return 'audio/mpeg';
      case AudioFormat.m4a:
        return 'audio/mp4';
      case AudioFormat.ogg:
        return 'audio/ogg';
      case AudioFormat.flac:
        return 'audio/flac';
      case AudioFormat.wav:
        return 'audio/wav';
      case AudioFormat.original:
        return 'audio/mpeg';
    }
  }

  String get label => format.label;

  void setFormat(AudioFormat value) {
    if (format == value) return;
    format = value;
    _prefs?.setString(_formatKey, value.name);
    notifyListeners();
  }

  void setBitrate(int value) {
    if (bitrate == value) return;
    bitrate = value;
    _prefs?.setInt(_bitrateKey, value);
    notifyListeners();
  }

  /// Argumentos para FFmpeg. Se usa executeWithArguments para que los espacios
  /// en los nombres no rompan el comando.
  static List<String> argumentsFor({
    required String input,
    required String output,
    required AudioFormat format,
    required int bitrate,
  }) {
    final base = <String>['-y', '-i', input, '-vn', '-map_metadata', '0'];
    switch (format) {
      case AudioFormat.mp3:
        return <String>[
          ...base,
          '-codec:a', 'libmp3lame', '-b:a', '${bitrate}k', output,
        ];
      case AudioFormat.m4a:
        return <String>[
          ...base,
          '-codec:a', 'aac', '-b:a', '${bitrate}k', output,
        ];
      case AudioFormat.ogg:
        return <String>[
          ...base,
          '-codec:a', 'libvorbis', '-b:a', '${bitrate}k', output,
        ];
      case AudioFormat.flac:
        return <String>[...base, '-codec:a', 'flac', output];
      case AudioFormat.wav:
        return <String>[...base, '-codec:a', 'pcm_s16le', output];
      case AudioFormat.original:
        return <String>[...base, '-c', 'copy', output];
    }
  }
}
