# AI Operator OS

Flutter-приложение-каталог AI-инструментов с web-сборкой для публикации как сайт.

## Локальный запуск

```powershell
flutter pub get
flutter run -d chrome
```

## Проверка

```powershell
flutter analyze
flutter test
```

## Публикация на GitHub Pages

В репозитории есть workflow `.github/workflows/deploy-pages.yml`. После push в ветку
`main` GitHub Actions соберет Flutter Web и опубликует сайт через GitHub Pages.

Ожидаемый адрес после включения Pages:

```text
https://ver-dikt.github.io/ai_operator-os/
```

В настройках репозитория GitHub откройте `Settings -> Pages` и выберите источник
`GitHub Actions`, если он не выбран автоматически.
