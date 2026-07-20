import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suno_downloader_mobile/main.dart';

void main() {
  testWidgets('shows URL entry state', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const SunoDownloaderApp());
    await tester.pumpAndSettle();
    expect(find.text('Скачайте свой\nтрек из Suno'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Получить песню'), findsOneWidget);
  });
}
