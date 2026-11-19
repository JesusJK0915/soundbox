import 'package:flutter_test/flutter_test.dart';
import 'package:soundbox/core/youtube_service.dart';

void main() {
  group('YouTubeService.videoId', () {
    test('extrae IDs de watch, youtu.be, shorts, embed y live', () {
      expect(
        YouTubeService.videoId('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
      expect(
        YouTubeService.videoId('https://youtu.be/dQw4w9WgXcQ?t=42'),
        'dQw4w9WgXcQ',
      );
      expect(
        YouTubeService.videoId('https://www.youtube.com/shorts/dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
      expect(
        YouTubeService.videoId('https://www.youtube.com/embed/dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
      expect(
        YouTubeService.videoId('https://m.youtube.com/live/dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
    });

    test('rechaza otros hosts e IDs invalidos', () {
      expect(YouTubeService.isYouTubeUrl('https://vimeo.com/123'), isFalse);
      expect(
        YouTubeService.videoId('https://www.youtube.com/watch?v=corto'),
        isNull,
      );
      expect(YouTubeService.videoId('youtube.com/watch?v=dQw4w9WgXcQ'), isNull);
    });
  });

  group('YouTubeVideo.searchQuery', () {
    test('separa artista y cancion y quita etiquetas del titulo', () {
      const video = YouTubeVideo(
        id: 'dQw4w9WgXcQ',
        title: 'Rick Astley - Never Gonna Give You Up (Official Music Video)',
        channel: 'Rick Astley - Topic',
      );
      expect(video.searchQuery, 'Never Gonna Give You Up Rick Astley');
    });

    test('usa el canal cuando el titulo no trae artista', () {
      const video = YouTubeVideo(
        id: 'abcdefghijk',
        title: 'Cancion libre [Audio]',
        channel: 'Canal de prueba VEVO',
      );
      expect(video.searchQuery, 'Cancion libre Canal de prueba');
    });
  });
}
