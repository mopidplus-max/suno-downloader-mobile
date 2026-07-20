import 'dart:typed_data';

class TrackMetadata {
  TrackMetadata({
    required this.audioUrl,
    required this.title,
    required this.artist,
    required this.album,
    required this.year,
    required this.fileName,
    this.coverUrl,
    this.coverBytes,
  });

  final String audioUrl;
  final String? coverUrl;
  String title;
  String artist;
  String album;
  String year;
  String fileName;
  Uint8List? coverBytes;

  TrackMetadata copyWith({Uint8List? coverBytes}) => TrackMetadata(
        audioUrl: audioUrl,
        coverUrl: coverUrl,
        title: title,
        artist: artist,
        album: album,
        year: year,
        fileName: fileName,
        coverBytes: coverBytes ?? this.coverBytes,
      );
}
