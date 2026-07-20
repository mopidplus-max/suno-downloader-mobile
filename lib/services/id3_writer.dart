import 'dart:convert';
import 'dart:typed_data';

import 'package:suno_downloader_mobile/models/track_metadata.dart';

class Id3Writer {
  static Uint8List tag(Uint8List audio, TrackMetadata track) {
    final frames = <int>[
      ..._textFrame('TIT2', track.title),
      ..._textFrame('TPE1', track.artist),
      ..._textFrame('TALB', track.album),
      ..._textFrame('TDRC', track.year),
      if (track.coverBytes != null) ..._coverFrame(track.coverBytes!),
    ];
    final header = <int>[
      ...ascii.encode('ID3'),
      3,
      0,
      0,
      ..._syncSafe(frames.length),
    ];
    return Uint8List.fromList([...header, ...frames, ...audio]);
  }

  static List<int> _textFrame(String id, String value) {
    final data = <int>[3, ...utf8.encode(value)];
    return _frame(id, data);
  }

  static List<int> _coverFrame(Uint8List bytes) {
    final png = bytes.length > 8 && bytes[0] == 0x89 && bytes[1] == 0x50;
    final data = <int>[
      0,
      ...latin1.encode(png ? 'image/png' : 'image/jpeg'),
      0,
      3,
      0,
      ...bytes,
    ];
    return _frame('APIC', data);
  }

  static List<int> _frame(String id, List<int> data) => [
    ...ascii.encode(id),
    (data.length >> 24) & 0xff,
    (data.length >> 16) & 0xff,
    (data.length >> 8) & 0xff,
    data.length & 0xff,
    0,
    0,
    ...data,
  ];

  static List<int> _syncSafe(int value) => [
    (value >> 21) & 0x7f,
    (value >> 14) & 0x7f,
    (value >> 7) & 0x7f,
    value & 0x7f,
  ];
}
