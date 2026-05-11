# AI Operator OS

Flutter-приложение-каталог AI-инструментов. Один код используется для web, Android и будущих desktop-сборок.

## Локальный запуск

```powershell
flutter pub get
flutter run -d chrome
```

## Проверка

```powershell
flutter analyze
flutter test
flutter build web --release --base-href /ai_operator-os/
```

## Android APK

Стабильный Android package:

```text
com.verdikt.aioperatoros
```

Это значение нельзя менять после первой раздачи APK, иначе Android будет считать сборку другим приложением.

Локальная сборка installable APK:

```powershell
flutter build apk --release
```

Готовый файл появится здесь:

```text
build/app/outputs/flutter-apk/app-release.apk
```

В репозитории есть workflow `.github/workflows/build-android-apk.yml`. После push в `main` или ручного запуска через `Actions -> Build Android APK` GitHub соберет APK и прикрепит его как artifact `ai-operator-os-apk`.

Текущая release-сборка подписывается debug-ключом, чтобы APK можно было быстро ставить вручную. Перед публичной раздачей нужно один раз завести приватный release-keystore и хранить его вне git или в GitHub Secrets.

## GitHub Pages

Workflow `.github/workflows/deploy-pages.yml` собирает Flutter Web и публикует сайт через ветку `gh-pages`.

Рабочий адрес:

```text
https://ver-dikt.github.io/ai_operator-os/
```

## Платформенные заметки

- Android: нужен установленный Android SDK для локальной сборки APK.
- Windows: для сборки с Flutter-плагинами нужно включить Developer Mode в Windows, чтобы работали symlink.
- iOS: bundle id уже приведен к `com.verdikt.aioperatoros`, но сборка требует macOS/Xcode.
