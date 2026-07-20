# Suno Downloader Mobile

Красивое Android-приложение на Flutter для сохранения собственных или разрешённых к скачиванию треков Suno.

## Возможности

- извлечение аудио, названия, автора, альбома, года и обложки из URL `suno.com/song/...`;
- редактирование всех метаданных и замена обложки PNG/JPEG;
- запись ID3v2-тегов и обложки внутрь MP3;
- выбор постоянной папки через Android Storage Access Framework;
- системное меню «Поделиться» после сохранения;
- анимированные состояния загрузки, сохранения и успеха.

Используйте приложение только для своих треков или материалов, на скачивание которых у вас есть разрешение. Пользователь отвечает за соблюдение авторских прав и условий Suno.

## Локальный запуск

Требуются Flutter stable, Android SDK и Java 17.

```bash
flutter pub get
flutter test
flutter run
```

## Подписанная сборка

Создайте `android/key.properties` (файл исключён из git):

```properties
storePassword=...
keyPassword=...
keyAlias=suno-downloader
storeFile=upload-keystore.jks
```

Поместите keystore в `android/app/upload-keystore.jks`, затем выполните `flutter build apk --release`.

## GitHub Actions

Workflow `.github/workflows/release.yml` ожидает secrets:

- `KEYSTORE_BASE64` — base64-содержимое JKS;
- `KEY_ALIAS`;
- `STORE_PASSWORD`;
- `KEY_PASSWORD`.

При отправке тега `v*` workflow проверяет форматирование, анализ и тесты, собирает подписанный APK и прикладывает его к GitHub Release.
