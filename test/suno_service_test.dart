import 'package:flutter_test/flutter_test.dart';
import 'package:suno_downloader_mobile/services/suno_service.dart';

void main() {
  group('SunoService', () {
    test('validates Suno song URLs', () {
      expect(SunoService.isValidUrl('https://suno.com/song/abc'), isTrue);
      expect(SunoService.isValidUrl('https://suno.com/s/abc'), isTrue);
      expect(SunoService.isValidUrl('https://example.com/s/abc'), isFalse);
      expect(SunoService.isValidUrl('https://example.com/song/abc'), isFalse);
    });

    test('extracts a balanced clip object and metadata', () {
      const html =
          '''<script>self.__next_f.push([1,"{\\"clip\\":{\\"audio_url\\":\\"https://cdn.test/song.mp3\\",\\"image_large_url\\":\\"https://cdn.test/cover.jpeg\\",\\"title\\":\\"Песня\\",\\"display_name\\":\\"Автор\\",\\"created_at\\":\\"2025-03-10T12:00:00Z\\",\\"metadata\\":{\\"album\\":\\"Альбом\\"}}}"])</script>''';
      final track = SunoService().parseHtml(html);
      expect(track.title, 'Песня');
      expect(track.artist, 'Автор');
      expect(track.album, 'Альбом');
      expect(track.year, '2025');
      expect(track.fileName, 'Песня.mp3');
    });

    test('sanitizes Android file names', () {
      expect(SunoService.sanitizeFileName('  A/B: C?  '), 'AB C');
      expect(SunoService.sanitizeFileName('...'), 'song');
    });
  });
}
