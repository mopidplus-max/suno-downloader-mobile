import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:suno_downloader_mobile/models/track_metadata.dart';

class SunoException implements Exception {
  const SunoException(this.message);
  final String message;
  @override
  String toString() => message;
}

class SunoService {
  SunoService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  static bool isValidUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
        (uri.host == 'suno.com' || uri.host.endsWith('.suno.com')) &&
        uri.pathSegments.contains('song');
  }

  Future<TrackMetadata> fetchTrack(String url) async {
    if (!isValidUrl(url)) {
      throw const SunoException('Вставьте корректную ссылку suno.com/song/…');
    }
    final response = await _client.get(
      Uri.parse(url.trim()),
      headers: const {'User-Agent': 'Mozilla/5.0 SunoDownloaderMobile/1.0'},
    );
    if (response.statusCode != 200) {
      throw SunoException('Suno вернул ошибку ${response.statusCode}.');
    }
    return parseHtml(response.body);
  }

  TrackMetadata parseHtml(String html) {
    final candidates = <Map<String, dynamic>>[];
    final decodedHtml = html.replaceAll(r'\"', '"').replaceAll(r'\\', r'\');
    for (final source in [html, decodedHtml]) {
      var cursor = 0;
      while (true) {
        final key = source.indexOf('"clip"', cursor);
        if (key < 0) break;
        final start = source.indexOf('{', key + 6);
        if (start < 0) break;
        final jsonText = _balancedObject(source, start);
        if (jsonText != null) {
          try {
            final value = jsonDecode(jsonText);
            if (value is Map<String, dynamic>) candidates.add(value);
          } catch (_) {}
          cursor = start + jsonText.length;
        } else {
          cursor = start + 1;
        }
      }
    }
    final clip = candidates.cast<Map<String, dynamic>?>().firstWhere(
      (item) => _string(item?['audio_url']).isNotEmpty,
      orElse: () => null,
    );
    if (clip == null) {
      throw const SunoException(
        'Не удалось найти аудио. Возможно, Suno изменил страницу.',
      );
    }
    final metadata = clip['metadata'] is Map
        ? Map<String, dynamic>.from(clip['metadata'] as Map)
        : <String, dynamic>{};
    final title = _first([clip['title'], metadata['title']], 'Песня');
    final artist = _first([
      clip['display_name'],
      clip['handle'],
      metadata['artist'],
    ], 'Автор');
    final created = DateTime.tryParse(_string(clip['created_at']));
    return TrackMetadata(
      audioUrl: _string(clip['audio_url']),
      coverUrl: _nullableFirst([
        clip['image_large_url'],
        clip['image_url'],
        metadata['image_url'],
      ]),
      title: title,
      artist: artist,
      album: _first([metadata['album']], 'Suno'),
      year: (created?.year ?? DateTime.now().year).toString(),
      fileName: '${sanitizeFileName(title)}.mp3',
    );
  }

  static String sanitizeFileName(String value) {
    final cleaned = value
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .replaceAll(RegExp(r'[. ]+$'), '');
    return cleaned.isEmpty ? 'song' : cleaned;
  }

  static String? _balancedObject(String source, int start) {
    var depth = 0;
    var inString = false;
    var escaped = false;
    for (var i = start; i < source.length; i++) {
      final char = source[i];
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (char == r'\') {
          escaped = true;
        } else if (char == '"') {
          inString = false;
        }
      } else if (char == '"') {
        inString = true;
      } else if (char == '{') {
        depth++;
      } else if (char == '}') {
        depth--;
        if (depth == 0) return source.substring(start, i + 1);
      }
    }
    return null;
  }

  static String _string(Object? value) => value?.toString().trim() ?? '';
  static String _first(List<Object?> values, String fallback) => values
      .map(_string)
      .firstWhere((value) => value.isNotEmpty, orElse: () => fallback);
  static String? _nullableFirst(List<Object?> values) {
    final result = _first(values, '');
    return result.isEmpty ? null : result;
  }
}
