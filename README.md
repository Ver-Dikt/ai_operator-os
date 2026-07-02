# FLUTEN / AI Operator OS — MVP

FLUTEN сейчас зафиксирован как локальный MVP: один Flutter Desktop проект без backend, Docker и сторонних runtime-репозиториев. Основной сценарий — подготовить prompt, открыть нужный внешний сервис вручную, сохранить результат в History / Assets.

## Что уже работает

- AI Chat: OpenRouter и OmniRoute как реальные OpenAI-compatible text routes при наличии настроек.
- Execution Settings: API keys, Base URL, model/router profile и health checks.
- Browser Hub: каталог внешних AI tools, copy/open handoff, ручной переход на сайт.
- Image Studio: подготовка prompt, provider handoff, manual result saving.
- Video Studio: подготовка prompt/shot plan, provider handoff, manual result saving.
- Audio Studio: подготовка music/voice/sound prompt, provider handoff, manual result saving.
- History / Assets: сохранённые prompt, handoff, text results и ручные результаты.
- Local health foundation: Ollama, ComfyUI, ACE-Step checks/settings как основа для следующих этапов.

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
- Остальные external providers зависят от своих сайтов/API и сейчас в основном работают через Browser Hub/manual handoff.

API keys не должны попадать в UI, History, logs, console output, screenshots, GitHub или README.

## Что пока manual/browser

- Browser Hub providers: открыть сайт, вставить prompt, сохранить результат вручную.
- Image / Video / Audio external tools: prompt подготовлен в FLUTEN, генерация выполняется во внешнем сервисе.
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

1. Открой AI Chat.
2. Выбери OpenRouter или OmniRoute и проверь статус провайдера.
3. Собери prompt.
4. Отправь prompt в Image / Video / Audio Studio.
5. Открой внешний provider через Browser Hub или кнопку handoff.
6. Сохрани готовый результат вручную в History / Assets.
7. Вернись к сохранённому результату позже и переиспользуй prompt/result.
