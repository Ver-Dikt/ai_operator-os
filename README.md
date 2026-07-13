# FLUTEN / AI Operator OS — MVP

FLUTEN сейчас зафиксирован как Windows-first Flutter MVP без собственного backend. Он объединяет прямые API-маршруты, локальные AI runtime и безопасную ручную передачу во внешние сервисы.

## Что уже работает

- Промпт-чат: OpenRouter и OmniRoute как реальные OpenAI-compatible text routes при наличии настроек.
- Провайдеры и ключи: API-ключи, Base URL, модель/роутер и проверка подключений.
- Внешние сервисы: каталог AI-инструментов, копирование prompt и ручной переход на сайт.
- Изображения: прямой OpenAI GPT Image API, локальный ComfyUI API-workflow и ручная передача в другие сервисы.
- Видео: прямой Veo 3.1 text-to-video API, подготовка плана кадров и ручная передача в другие сервисы.
- Аудио: прямой ElevenLabs TTS, локальная генерация музыки ACE-Step и ручная передача в другие сервисы.
- Библиотека: сохранённые prompts, передачи, текстовые и ручные результаты.
- Локальные маршруты: Ollama для prompt improvement, ComfyUI для изображений и ACE-Step для музыки.

Прямые генерации сохраняются по умолчанию в `%APPDATA%\FLUTEN\outputs` и автоматически регистрируются в Библиотеке.

## Как запустить в dev mode

```powershell
powershell -ExecutionPolicy Bypass -File .\run_fluten.ps1
```

Скрипт использует локальный Flutter из `.tools\flutter\bin\flutter.bat`, при необходимости запускает `pub get`, затем открывает приложение через:

```powershell
flutter run -d windows
```

## Как собрать Windows release

```powershell
powershell -ExecutionPolicy Bypass -File .\build_fluten_windows.ps1
```

Скрипт выполняет:

```powershell
.\.tools\flutter\bin\flutter.bat pub get
.\.tools\flutter\bin\flutter.bat analyze --no-pub
.\.tools\flutter\bin\flutter.bat build windows
```

Если путь к репозиторию содержит пробелы, build script пытается использовать no-spaces junction:

```text
G:\AI\STUDIO_WORK
```

Flutter Windows build может ломаться в путях с пробелами. Junction нужен только как безопасная рабочая точка для сборки; исходники остаются в текущем репозитории.

## Как открыть release

```powershell
powershell -ExecutionPolicy Bypass -File .\open_fluten_release.ps1
```

Если release ещё не собран, скрипт напечатает:

```text
Release build not found. Run build_fluten_windows.ps1 first.
```

## Где лежит exe

```text
build\windows\x64\runner\Release\ai_operator_os.exe
```

## Что требует API keys

- OpenRouter: нужен API key, Base URL и model/router profile.
- OmniRoute: нужен API key и настроенный Base URL, если используется remote/router endpoint.
- OpenAI: нужен API key; Image Studio использует модель `gpt-image-2`.
- ElevenLabs: нужен API key и Voice ID.
- Gemini: нужен API key с доступом к Veo; Video Studio сохраняет готовый MP4 локально.
- ComfyUI и ACE-Step работают локально без внешнего ключа, если локальный runtime не защищён собственным токеном.
- Остальные external providers работают через Browser Hub/manual handoff до подключения проверенного API-контракта.

API keys не попадают в History, логи и результаты. На текущем MVP-этапе они хранятся локально через SharedPreferences; перед публичным релизом требуется перенос в Windows Credential Manager/secure storage.

## Что пока manual/browser

- Browser Hub providers: открыть сайт, вставить prompt, сохранить результат вручную.
- Неподключённые Image / Video / Audio tools: prompt подготовлен в FLUTEN, генерация выполняется во внешнем сервисе.
- Local services без запущенного runtime показываются как недоступные или экспериментальные.

## Что не коммитить

```text
build/
.dart_tool/
windows/flutter/ephemeral/
ios/Flutter/Generated.xcconfig
ios/Flutter/flutter_export_environment.sh
.dart_appdata/
*.log
build_windows_verbose*.log
STUDIO.code-workspace
```

## MVP workflow

1. Открой Промпт-чат.
2. Выбери OpenRouter или OmniRoute и проверь статус провайдера.
3. Собери prompt.
4. Отправь prompt в Изображения, Видео или Аудио.
5. Запусти подключённый API/local route или открой внешний сервис.
6. Прямой результат попадёт в Библиотеку автоматически; внешний можно сохранить вручную.
7. Вернись к сохранённому результату позже и переиспользуй prompt/result.
