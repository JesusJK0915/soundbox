import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../core/library_service.dart';
import '../core/models.dart';
import '../widgets/subtitle_overlay.dart';

class VideoScreen extends StatefulWidget {
  final Track track;

  const VideoScreen({super.key, required this.track});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  late VideoPlayerController _controller;
  late Future<void> _initialize;
  String? _subtitlePath;

  @override
  void initState() {
    super.initState();
    _subtitlePath = widget.track.subtitlePath;
    _controller = VideoPlayerController.file(File(widget.track.sourceUrl));
    _initialize = _controller.initialize().then((_) {
      _controller.setLooping(true);
      _controller.play();
      _controller.addListener(() {
        if (mounted) setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickSubtitle() async {
    final path = await context.read<LibraryService>().pickSubtitlePath();
    if (path == null) return;
    await context.read<LibraryService>().attachSubtitle(widget.track.id, path);
    if (!mounted) return;
    setState(() => _subtitlePath = path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.track.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.subtitles),
            onPressed: _pickSubtitle,
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _initialize,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          return Stack(
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio == 0
                      ? 16 / 9
                      : _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              ),
              SubtitleOverlay(
                subtitlePath: _subtitlePath,
                position: _controller.value.position,
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_controller.value.isPlaying) {
            _controller.pause();
          } else {
            _controller.play();
          }
          setState(() {});
        },
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}
