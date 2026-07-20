import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _channel = MethodChannel('com.sunodownloader.mobile/storage');
  static const _folderNameKey = 'folder_name';

  Future<String?> chooseFolder() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'chooseFolder',
    );
    final name = result?['name'] as String?;
    if (name != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_folderNameKey, name);
    }
    return name;
  }

  Future<String> folderName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_folderNameKey) ?? 'Папка не выбрана';
  }

  Future<String> save(String fileName, Uint8List bytes) async {
    final result = await _channel.invokeMethod<String>('saveFile', {
      'fileName': fileName,
      'bytes': bytes,
    });
    if (result == null)
      throw const FileSystemException('Не удалось сохранить файл');
    return result;
  }

  Future<File> createShareFile(String fileName, Uint8List bytes) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    return file.writeAsBytes(bytes, flush: true);
  }
}
