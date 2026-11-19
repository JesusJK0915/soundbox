import 'dart:io';

import 'package:flutter/material.dart';

import '../core/subtitle_parser.dart';

class SubtitleOverlay extends StatefulWidget {
  final String? subtitlePath;
  final Duration position;

  const SubtitleOverlay({
    super.key,
    required this.subtitlePath,
    required this.position,
  });

  @override
  State<SubtitleOverlay> createState() => _SubtitleOverlayState();
}

class _SubtitleOverlayState extends State<SubtitleOverlay> {
  List<SubtitleCue> _cues = const <SubtitleCue>[];
  String? _loadedPath;

  @override
  void didUpdateWidget(covariant SubtitleOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.subtitlePath != _loadedPath) {
      _load(widget.subtitlePath);
    }
  }

  @override
  void initState() {
    super.initState();
    _load(widget.subtitlePath);
  }

  Future<void> _load(String? path) async {
    _loadedPath = path;
    if (path == null) {
      _cues = const <SubtitleCue>[];
      if (mounted) setState(() {});
      return;
    }
    try {
      final content = await File(path).readAsString();
      _cues = parseSubtitles(content);
    } catch (_) {
      _cues = const <SubtitleCue>[];
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final text = cueAt(_cues, widget.position);
    if (text == null) return const SizedBox.shrink();

    return Positioned(
      left: 16,
      right: 16,
      bottom: 24,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.75),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
