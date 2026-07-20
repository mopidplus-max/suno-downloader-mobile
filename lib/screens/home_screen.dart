import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:suno_downloader_mobile/models/track_metadata.dart';
import 'package:suno_downloader_mobile/services/download_service.dart';
import 'package:suno_downloader_mobile/services/id3_writer.dart';
import 'package:suno_downloader_mobile/services/storage_service.dart';
import 'package:suno_downloader_mobile/services/suno_service.dart';
import 'package:suno_downloader_mobile/theme.dart';

enum ScreenState { idle, loading, editing, saving, done }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _url = TextEditingController();
  final _title = TextEditingController();
  final _artist = TextEditingController();
  final _album = TextEditingController();
  final _year = TextEditingController();
  final _fileName = TextEditingController();
  final _suno = SunoService();
  final _download = DownloadService();
  final _storage = StorageService();
  TrackMetadata? _track;
  ScreenState _state = ScreenState.idle;
  String _folder = 'Папка не выбрана';
  String? _error;
  File? _shareFile;

  @override
  void initState() {
    super.initState();
    _storage.folderName().then((value) {
      if (mounted) setState(() => _folder = value);
    });
  }

  @override
  void dispose() {
    for (final controller in [_url, _title, _artist, _album, _year, _fileName]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() { _state = ScreenState.loading; _error = null; });
    try {
      var track = await _suno.fetchTrack(_url.text);
      if (track.coverUrl != null) {
        try { track = track.copyWith(coverBytes: await _download.bytes(track.coverUrl!)); } catch (_) {}
      }
      _title.text = track.title;
      _artist.text = track.artist;
      _album.text = track.album;
      _year.text = track.year;
      _fileName.text = track.fileName;
      setState(() { _track = track; _state = ScreenState.editing; });
    } catch (error) {
      setState(() { _error = error.toString(); _state = ScreenState.idle; });
    }
  }

  Future<void> _pickCover() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 92);
    if (image == null || _track == null) return;
    final bytes = await image.readAsBytes();
    setState(() => _track = _track!.copyWith(coverBytes: bytes));
  }

  Future<void> _chooseFolder() async {
    final name = await _storage.chooseFolder();
    if (name != null && mounted) setState(() => _folder = name);
  }

  Future<void> _save() async {
    if (_track == null) return;
    if (_folder == 'Папка не выбрана') {
      await _chooseFolder();
      if (_folder == 'Папка не выбрана') return;
    }
    setState(() { _state = ScreenState.saving; _error = null; });
    try {
      final fileName = _fileName.text.toLowerCase().endsWith('.mp3')
          ? _fileName.text
          : '${_fileName.text}.mp3';
      final edited = TrackMetadata(
        audioUrl: _track!.audioUrl,
        coverUrl: _track!.coverUrl,
        coverBytes: _track!.coverBytes,
        title: _title.text.trim(), artist: _artist.text.trim(),
        album: _album.text.trim(), year: _year.text.trim(),
        fileName: '${SunoService.sanitizeFileName(fileName.replaceAll(RegExp(r'\.mp3$', caseSensitive: false), ''))}.mp3',
      );
      final audio = await _download.bytes(edited.audioUrl);
      final tagged = Id3Writer.tag(audio, edited);
      final savedName = await _storage.save(edited.fileName, tagged);
      _shareFile = await _storage.createShareFile(edited.fileName, tagged);
      await HapticFeedback.mediumImpact();
      setState(() { _folder = savedName; _state = ScreenState.done; });
    } catch (error) {
      setState(() { _error = 'Не удалось сохранить: $error'; _state = ScreenState.editing; });
    }
  }

  Future<void> _share() async {
    if (_shareFile == null) return;
    await Share.shareXFiles([XFile(_shareFile!.path)], text: _title.text);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: CustomScrollView(slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
          sliver: SliverList.list(children: [
            _Header(folder: _folder, onFolder: _chooseFolder),
            const SizedBox(height: 34),
            const Text('Скачайте свой\nтрек из Suno', style: TextStyle(fontSize: 38, height: 1.02, fontWeight: FontWeight.w900, letterSpacing: -1.5)),
            const SizedBox(height: 12),
            const Text('Вставьте ссылку, проверьте метаданные и сохраните MP3 в выбранную папку.', style: TextStyle(fontSize: 16, height: 1.5, color: AppTheme.muted)),
            const SizedBox(height: 24),
            TextField(controller: _url, keyboardType: TextInputType.url, textInputAction: TextInputAction.go, onSubmitted: (_) => _state == ScreenState.idle ? _load() : null, decoration: const InputDecoration(labelText: 'Ссылка Suno', hintText: 'https://suno.com/song/...', prefixIcon: Icon(Icons.link_rounded))),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: _state == ScreenState.idle ? _load : null, icon: const Icon(Icons.arrow_downward_rounded), label: const Text('Получить песню'), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)))),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 14), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
            const SizedBox(height: 24),
            AnimatedSwitcher(duration: const Duration(milliseconds: 420), switchInCurve: Curves.easeOutCubic, child: _content()),
          ]),
        ),
      ]),
    ),
  );

  Widget _content() {
    if (_state == ScreenState.loading) return const _LoadingCard(key: ValueKey('loading'), label: 'Подождите…\nИщем аудио и обложку');
    if (_state == ScreenState.saving) return const _LoadingCard(key: ValueKey('saving'), label: 'Сохраняем…\nДобавляем обложку и теги');
    if (_state == ScreenState.done) return _DoneCard(key: const ValueKey('done'), folder: _folder, onShare: _share, onAgain: () => setState(() { _state = ScreenState.idle; _track = null; _url.clear(); }));
    if (_track != null) return _EditorCard(key: const ValueKey('editor'), track: _track!, title: _title, artist: _artist, album: _album, year: _year, fileName: _fileName, onCover: _pickCover, onSave: _save);
    return const SizedBox.shrink(key: ValueKey('empty'));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.folder, required this.onFolder});
  final String folder; final VoidCallback onFolder;
  @override Widget build(BuildContext context) => Row(children: [
    Container(width: 44, height: 44, decoration: BoxDecoration(color: AppTheme.ink, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.graphic_eq_rounded, color: AppTheme.lime)),
    const SizedBox(width: 12),
    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('SUNO DOWNLOADER', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: .5)), Text('Только ваши и разрешённые треки', style: TextStyle(fontSize: 12, color: AppTheme.muted))])),
    IconButton.filledTonal(onPressed: onFolder, tooltip: 'Выбрать папку', icon: const Icon(Icons.folder_open_rounded)),
  ]);
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({super.key, required this.label}); final String label;
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: AppTheme.ink, borderRadius: BorderRadius.circular(28)), child: Row(children: [const SizedBox(width: 44, height: 44, child: CircularProgressIndicator(color: AppTheme.lime, strokeWidth: 3)), const SizedBox(width: 18), Expanded(child: Text(label, style: const TextStyle(color: AppTheme.paper, fontSize: 18, height: 1.4, fontWeight: FontWeight.w700)))]));
}

class _EditorCard extends StatelessWidget {
  const _EditorCard({super.key, required this.track, required this.title, required this.artist, required this.album, required this.year, required this.fileName, required this.onCover, required this.onSave});
  final TrackMetadata track; final TextEditingController title, artist, album, year, fileName; final VoidCallback onCover, onSave;
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 28, offset: Offset(0, 12))]), child: Column(children: [
    GestureDetector(onTap: onCover, child: AspectRatio(aspectRatio: 1, child: ClipRRect(borderRadius: BorderRadius.circular(20), child: track.coverBytes == null ? Container(color: AppTheme.ink, child: const Icon(Icons.add_photo_alternate_rounded, color: AppTheme.lime, size: 52)) : Image.memory(track.coverBytes!, fit: BoxFit.cover)))),
    const SizedBox(height: 8), TextButton.icon(onPressed: onCover, icon: const Icon(Icons.image_rounded), label: const Text('Заменить обложку PNG / JPEG')),
    const SizedBox(height: 8),
    _field(fileName, 'Название файла', Icons.audio_file_rounded), _field(title, 'Название', Icons.music_note_rounded), _field(artist, 'Автор', Icons.person_rounded), _field(album, 'Альбом', Icons.album_rounded), _field(year, 'Год', Icons.calendar_today_rounded, keyboard: TextInputType.number),
    const SizedBox(height: 4), FilledButton.icon(onPressed: onSave, icon: const Icon(Icons.save_alt_rounded), label: const Text('Сохранить'), style: FilledButton.styleFrom(backgroundColor: AppTheme.lime, foregroundColor: AppTheme.ink, minimumSize: const Size.fromHeight(56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)))),
  ]));
  Widget _field(TextEditingController controller, String label, IconData icon, {TextInputType? keyboard}) => Padding(padding: const EdgeInsets.only(bottom: 12), child: TextField(controller: controller, keyboardType: keyboard, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon))));
}

class _DoneCard extends StatelessWidget {
  const _DoneCard({super.key, required this.folder, required this.onShare, required this.onAgain}); final String folder; final VoidCallback onShare, onAgain;
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: AppTheme.ink, borderRadius: BorderRadius.circular(28)), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Align(alignment: Alignment.centerLeft, child: CircleAvatar(radius: 30, backgroundColor: AppTheme.lime, child: Icon(Icons.check_rounded, color: AppTheme.ink, size: 34))), const SizedBox(height: 18),
    const Text('Готово!', style: TextStyle(color: AppTheme.paper, fontWeight: FontWeight.w900, fontSize: 30)), const SizedBox(height: 8), Text('Сохранено в папку\n$folder', style: const TextStyle(color: Color(0xFFC9CEC9), height: 1.5)), const SizedBox(height: 22),
    FilledButton.icon(onPressed: onShare, icon: const Icon(Icons.ios_share_rounded), label: const Text('Поделиться'), style: FilledButton.styleFrom(backgroundColor: AppTheme.lime, foregroundColor: AppTheme.ink, minimumSize: const Size.fromHeight(54))), const SizedBox(height: 8),
    TextButton(onPressed: onAgain, child: const Text('Скачать ещё', style: TextStyle(color: AppTheme.paper))),
  ]));
}
