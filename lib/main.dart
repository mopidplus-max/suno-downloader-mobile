import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:suno_downloader_mobile/screens/home_screen.dart';
import 'package:suno_downloader_mobile/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: AppTheme.paper,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(const SunoDownloaderApp());
}

class SunoDownloaderApp extends StatelessWidget {
  const SunoDownloaderApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Suno Downloader',
        theme: AppTheme.light,
        home: const HomeScreen(),
      );
}
