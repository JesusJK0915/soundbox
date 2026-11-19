import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';

enum ProviderKind {
  internetArchive,
  wikimedia,
  jamendo,
  soundCloud,
  pixabay,
  directUrl,
}

class ProviderDefinition {
  final ProviderKind kind;
  final String label;
  final String description;
  final IconData icon;
  final bool requiresKey;
  final String? keyLabel;
  final String? keyHint;
  final bool defaultEnabled;

  const ProviderDefinition({
    required this.kind,
    required this.label,
    required this.description,
    required this.icon,
    this.requiresKey = false,
    this.keyLabel,
    this.keyHint,
    this.defaultEnabled = false,
  });

  String get enabledPref => 'source.${kind.name}.enabled';
  String get keyPref => 'source.${kind.name}.key';
}

const List<ProviderDefinition> providerDefinitions = [
  ProviderDefinition(
    kind: ProviderKind.internetArchive,
    label: 'Internet Archive',
    description: 'Musica Creative Commons y dominio publico',
    icon: Icons.archive,
    defaultEnabled: true,
  ),
  ProviderDefinition(
    kind: ProviderKind.wikimedia,
    label: 'Wikimedia Commons',
    description: 'Audio con licencia libre',
    icon: Icons.public,
    defaultEnabled: true,
  ),
  ProviderDefinition(
    kind: ProviderKind.jamendo,
    label: 'Jamendo',
    description: 'Musica Creative Commons',
    icon: Icons.audiotrack,
    requiresKey: true,
    keyLabel: 'Client ID',
    keyHint: 'developer.jamendo.com',
  ),
  ProviderDefinition(
    kind: ProviderKind.soundCloud,
    label: 'SoundCloud',
    description: 'Solo pistas marcadas como descargables por su autor',
    icon: Icons.cloud,
    requiresKey: true,
    keyLabel: 'Client ID',
    keyHint: 'developers.soundcloud.com',
  ),
  ProviderDefinition(
    kind: ProviderKind.pixabay,
    label: 'Pixabay',
    description: 'Musica libre de regalias',
    icon: Icons.music_note,
    requiresKey: true,
    keyLabel: 'API key',
    keyHint: 'pixabay.com/api/docs',
  ),
  ProviderDefinition(
    kind: ProviderKind.directUrl,
    label: 'URL directa',
    description: 'Pega un enlace a un archivo de audio propio',
    icon: Icons.link,
    defaultEnabled: true,
  ),
];

ProviderDefinition definitionFor(ProviderKind kind) =>
    providerDefinitions.firstWhere((item) => item.kind == kind);

String _defaultKey(ProviderKind kind) {
  switch (kind) {
    case ProviderKind.jamendo:
      return jamendoClientId;
    case ProviderKind.soundCloud:
      return soundCloudClientId;
    case ProviderKind.pixabay:
      return pixabayApiKey;
    default:
      return '';
  }
}

/// Preferencias de fuentes de descarga, persistentes y editables en Ajustes.
class ProviderSettingsService extends ChangeNotifier {
  final SharedPreferences? _prefs;
  final Map<ProviderKind, bool> _enabled = <ProviderKind, bool>{};
  final Map<ProviderKind, String> _keys = <ProviderKind, String>{};

  ProviderSettingsService([SharedPreferences? prefs]) : _prefs = prefs {
    for (final definition in providerDefinitions) {
      final key = _prefs?.getString(definition.keyPref) ??
          _defaultKey(definition.kind);
      _keys[definition.kind] = key;
      _enabled[definition.kind] =
          _prefs?.getBool(definition.enabledPref) ??
          (definition.defaultEnabled && (!definition.requiresKey || key.isNotEmpty));
    }
  }

  static Future<ProviderSettingsService> load() async =>
      ProviderSettingsService(await SharedPreferences.getInstance());

  bool isEnabled(ProviderKind kind) => _enabled[kind] ?? false;

  String key(ProviderKind kind) => _keys[kind] ?? '';

  bool get hasAnyKey => _keys.values.any((value) => value.trim().isNotEmpty);

  List<ProviderKind> get activeSearchProviders => providerDefinitions
      .where((definition) =>
          definition.kind != ProviderKind.directUrl &&
          isEnabled(definition.kind) &&
          (!definition.requiresKey || key(definition.kind).isNotEmpty))
      .map((definition) => definition.kind)
      .toList();

  void setEnabled(ProviderKind kind, bool value) {
    if (_enabled[kind] == value) return;
    _enabled[kind] = value;
    _prefs?.setBool(definitionFor(kind).enabledPref, value);
    notifyListeners();
  }

  void setKey(ProviderKind kind, String value) {
    final trimmed = value.trim();
    if (_keys[kind] == trimmed) return;
    _keys[kind] = trimmed;
    _prefs?.setString(definitionFor(kind).keyPref, trimmed);
    if (trimmed.isNotEmpty && !isEnabled(kind)) {
      _enabled[kind] = true;
      _prefs?.setBool(definitionFor(kind).enabledPref, true);
    }
    if (trimmed.isEmpty) {
      _enabled[kind] = false;
      _prefs?.setBool(definitionFor(kind).enabledPref, false);
    }
    notifyListeners();
  }
}
