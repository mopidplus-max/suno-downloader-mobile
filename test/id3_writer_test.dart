import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:suno_downloader_mobile/models/track_metadata.dart';
import 'package:suno_downloader_mobile/services/id3_writer.dart';

void main() {
  test('prepends ID3v2 metadata and preserves audio bytes', () {
    final audio = Uint8List.fromList([1, 2, 3, 4]);
    final result = Id3Writer.tag(audio, TrackMetadata(
      audioUrl: 'https://example.test/audio.mp3',
      title: 'Песня', artist: 'Автор', album: 'Альбом', year: '2026', fileName: 'song.mp3',
    ));
    expect(ascii.decode(result.sublist(0, 3)), 'ID3');
    expect(result.sublist(result.length - 4), audio);
  });
}
