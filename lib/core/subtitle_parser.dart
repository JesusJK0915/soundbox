class SubtitleCue {
  final Duration start;
  final Duration end;
  final String text;

  const SubtitleCue({
    required this.start,
    required this.end,
    required this.text,
  });
}

Duration _parseTime(String raw) {
  final normalized = raw.replaceFirst(',', '.');
  final parts = normalized.split(':');
  final hours = int.tryParse(parts[0]) ?? 0;
  final minutes = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
  final secondsPart = parts.length > 2 ? parts[2] : '0';
  final dot = secondsPart.indexOf('.');
  final seconds = int.tryParse(
        dot == -1 ? secondsPart : secondsPart.substring(0, dot),
      ) ??
      0;
  var millis = 0;
  if (dot != -1) {
    final fraction = secondsPart.substring(dot + 1).padRight(3, '0');
    millis = int.tryParse(fraction.substring(0, 3)) ?? 0;
  }
  return Duration(
    hours: hours,
    minutes: minutes,
    seconds: seconds,
    milliseconds: millis,
  );
}

final RegExp _vttTime = RegExp(
  r'(\d{1,3}:\d{2}:\d{2}[,.]\d{1,3})\s*-->\s*(\d{1,3}:\d{2}:\d{2}[,.]\d{1,3})',
);

final RegExp _lrcTime = RegExp(r'\[(\d{1,3}):(\d{2})(?:[.:](\d{1,3}))?\]');

bool looksLikeLrc(String content) =>
    _lrcTime.hasMatch(content) && !_vttTime.hasMatch(content);

List<SubtitleCue> parseLrc(String content) {
  final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final raw = <SubtitleCue>[];

  for (final line in normalized.split('\n')) {
    final matches = _lrcTime.allMatches(line).toList();
    if (matches.isEmpty) continue;
    final start = _parseTime(
      '0:${matches.first.group(1)!}:${matches.first.group(2)!}'
      '.${(matches.first.group(3) ?? '0').padRight(3, '0').substring(0, 3)}',
    );
    final textStart = matches.last.end;
    final text = line.substring(textStart).trim();
    if (text.isEmpty) continue;
    for (final _ in matches) {
      raw.add(SubtitleCue(start: start, end: start, text: text));
    }
  }

  raw.sort((a, b) => a.start.compareTo(b.start));

  for (var i = 0; i < raw.length; i++) {
    if (raw[i].end != raw[i].start) continue;
    var end = raw[i].start + const Duration(seconds: 4);
    for (var j = i + 1; j < raw.length; j++) {
      if (raw[j].start > raw[i].start) {
        end = raw[j].start;
        break;
      }
    }
    raw[i] = SubtitleCue(start: raw[i].start, end: end, text: raw[i].text);
  }


  final unique = <SubtitleCue>[];
  for (final cue in raw) {
    if (unique.isNotEmpty && unique.last.start == cue.start) continue;
    unique.add(cue);
  }
  return unique;
}

List<SubtitleCue> parseSubtitles(String content) {
  if (looksLikeLrc(content)) return parseLrc(content);

  final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final blocks = normalized.split(RegExp(r'\n\s*\n'));
  final cues = <SubtitleCue>[];

  for (final block in blocks) {
    final match = _vttTime.firstMatch(block);
    if (match == null) continue;
    final text = block
        .substring(match.end)
        .trim()
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n');
    if (text.isEmpty) continue;
    cues.add(
      SubtitleCue(
        start: _parseTime(match.group(1)!),
        end: _parseTime(match.group(2)!),
        text: text,
      ),
    );
  }

  cues.sort((a, b) => a.start.compareTo(b.start));
  return cues;
}

String? cueAt(List<SubtitleCue> cues, Duration position) {
  for (final cue in cues) {
    if (position >= cue.start && position <= cue.end) return cue.text;
  }
  return null;
}
