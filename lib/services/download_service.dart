import 'dart:typed_data';

import 'package:http/http.dart' as http;

class DownloadService {
  DownloadService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<Uint8List> bytes(String url) async {
    final response = await _client.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Ошибка загрузки: ${response.statusCode}');
    }
    return response.bodyBytes;
  }
}
