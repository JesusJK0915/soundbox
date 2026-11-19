import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Sesión de escucha agrupada por día.
class ListeningSession {
  final String day;
  final int seconds;
  final int plays;

  const ListeningSession({
    required this.day,
    required this.seconds,
    required this.plays,
  });

  Map<String, dynamic> toJson() => {
        'day': day,
        'seconds': seconds,
        'plays': plays,
      };

  factory ListeningSession.fromJson(Map<String, dynamic> json) =>
      ListeningSession(
        day: (json['day'] as String?) ?? '',
        seconds: (json['seconds'] as num?)?.toInt() ?? 0,
        plays: (json['plays'] as num?)?.toInt() ?? 0,
      );
}

/// Estadísticas de escucha: tiempo por día, racha y récord.
class ListeningStatsService extends ChangeNotifier {
  static const sessionsKey = 'stats.sessions';
  static const streakKey = 'stats.streak';
  static const bestStreakKey = 'stats.best_streak';

  final SharedPreferences _prefs;
  final List<ListeningSession> _sessions = <ListeningSession>[];
  int _streak = 0;
  int _bestStreak = 0;
  DateTime? _lastDay;

  ListeningStatsService(this._prefs) {
    final raw = _prefs.getStringList(sessionsKey) ?? <String>[];
    _sessions.addAll(
      raw
          .map((value) => jsonDecode(value) as Map<String, dynamic>)
          .map(ListeningSession.fromJson),
    );
    _streak = _prefs.getInt(streakKey) ?? 0;
    _bestStreak = _prefs.getInt(bestStreakKey) ?? 0;
  }

  List<ListeningSession> get sessions => List.unmodifiable(_sessions);
  int get streak => _streak;
  int get bestStreak => _bestStreak;

  int get totalSeconds =>
      _sessions.fold<int>(0, (sum, session) => sum + session.seconds);

  int get todaySeconds {
    final today = _dayKey(DateTime.now());
    return _sessions
        .where((session) => session.day == today)
        .fold<int>(0, (sum, session) => sum + session.seconds);
  }

  static String _dayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Registra segundos escuchados hoy. Se llama periódicamente desde el player.
  Future<void> addListeningTime(Duration delta, {int plays = 0}) async {
    if (delta.inSeconds <= 0 && plays == 0) return;
    final today = _dayKey(DateTime.now());
    final now = DateTime.now();
    final yesterday = _dayKey(now.subtract(const Duration(days: 1)));

    if (_lastDay == null || _dayKey(_lastDay!) != today) {
      final lastSession = _sessions.isEmpty ? null : _sessions.last;
      if (lastSession != null) {
        if (lastSession.day == today) {
          _streak = _streak > 0 ? _streak : 1;
        } else if (lastSession.day == yesterday) {
          _streak += 1;
        } else {
          _streak = 1;
        }
      } else {
        _streak = 1;
      }
      if (_streak > _bestStreak) _bestStreak = _streak;
      _lastDay = now;
      await _prefs.setInt(streakKey, _streak);
      await _prefs.setInt(bestStreakKey, _bestStreak);
    }

    final index = _sessions.indexWhere((session) => session.day == today);
    if (index >= 0) {
      final old = _sessions[index];
      _sessions[index] = ListeningSession(
        day: old.day,
        seconds: old.seconds + delta.inSeconds,
        plays: old.plays + plays,
      );
    } else {
      _sessions.add(
        ListeningSession(
          day: today,
          seconds: delta.inSeconds,
          plays: plays,
        ),
      );
    }
    if (_sessions.length > 365) {
      _sessions.removeRange(0, _sessions.length - 365);
    }
    await _persist();
  }

  Future<void> _persist() async {
    await _prefs.setStringList(
      sessionsKey,
      _sessions.map((session) => jsonEncode(session.toJson())).toList(),
    );
    notifyListeners();
  }

  /// Exporta el historial como CSV (día, segundos, reproducciones).
  String toCsv() {
    final buffer = StringBuffer('dia,segundos,reproducciones\n');
    for (final session in _sessions) {
      buffer.writeln('${session.day},${session.seconds},${session.plays}');
    }
    return buffer.toString();
  }

  List<Track> topTracks(
    Iterable<Track> tracks,
    int Function(String id) playCount,
  ) {
    final sorted = tracks.toList()
      ..sort((a, b) => playCount(b.id).compareTo(playCount(a.id)));
    return sorted.take(10).toList();
  }

  Future<void> reset() async {
    _sessions.clear();
    _streak = 0;
    _bestStreak = 0;
    _lastDay = null;
    await _prefs.remove(sessionsKey);
    await _prefs.remove(streakKey);
    await _prefs.remove(bestStreakKey);
    notifyListeners();
  }
}
