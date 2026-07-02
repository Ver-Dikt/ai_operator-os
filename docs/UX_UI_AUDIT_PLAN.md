# UX/UI Audit & Redesign Plan

## Executive Summary

FLUTEN already has the core MVP workflow in place: prepare a prompt, choose a provider route, open an external service or local runtime, save the result manually, and review it in History / Assets. The biggest UX issue is not missing functionality. The issue is that the interface presents too many destinations, statuses, provider concepts, and future promises at the same visual weight.

The redesign should make the product feel like one calm execution workspace instead of a collection of studio experiments. The first implementation patch should focus on navigation, terminology, and visible state language because those changes reduce confusion across every screen without touching execution logic.

This audit used the current Flutter source plus one quick Lazyweb reference search for desktop creative dashboards. The strongest comparable patterns emphasize a clear first action, fewer equal-weight tiles, visible state hierarchy, and progressive disclosure for advanced configuration.

## Biggest Problems

1. Primary navigation mixes working MVP surfaces with future/lab surfaces.
   `AI Chat`, `Image`, `Video`, `Audio`, `Cinema`, `Marketing`, `Workflows`, `Browser`, `History`, `Agents`, and `Apps` compete in the top bar. Disabled or not-yet-connected destinations still consume attention.

2. State language is inconsistent.
   The UI mixes `Ready now`, `Требует настройки`, `Через сайт / вручную`, `Экспериментально`, `API placeholder`, `Browser handoff`, `Manual`, `Provider handoff`, and `Local prep mode`. Users need one shared vocabulary.

3. The app overuses equal-weight panels and cards.
   Command Center, provider panels, studio sidebars, and settings cards often give secondary actions the same emphasis as the next required action. The user has to infer the workflow.

4. The execution workflow is present but not consistently visible.
   The intended path is clear in copy, but each screen expresses it differently. `AI Chat -> Studio -> Browser/manual provider -> Save result -> History` should become a persistent product pattern.

5. Provider configuration is too dense for first-time use.
   Settings exposes API keys, Base URL, models, health checks, local endpoints, workflows, output folders, and safety copy in one long surface. This is accurate but heavy.

6. Russian and English terminology are mixed in high-value controls.
   Product names can stay English, but workflow terms should be standardized in Russian. Mixed labels like `Open AI Chat`, `History / Assets`, `Provider / model`, and `Local prep mode` make the app feel less finished.

7. Some files display mojibake in terminal inspection.
   The app source may be UTF-8, but PowerShell output shows corrupted Cyrillic in several files. This should be verified before large UI copy work so the next patch does not accidentally preserve or worsen encoding artifacts.

## Screen-by-Screen Audit

### Global Navigation

Current state: The top bar lives in `lib/src/shell/app_shell.dart`. It includes active studios, future sections, icon-only providers/settings, the `OpenGenerativeAI` wordmark, and a `Local prep mode` pill.

Problems:
- Too many top-level choices for an MVP.
- Disabled `Workflows`, `Agents`, and `Apps` look like product debt in the primary nav.
- Settings and Providers are important, but they are only icon buttons.
- Labels mix English and Russian.

Recommendation:
- Use a smaller primary nav: `Командный центр`, `Промпт-чат`, `Создание`, `Внешние сервисы`, `Библиотека`, `Провайдеры`.
- Move future items to a secondary `Лаборатория` or `Скоро` area inside Command Center.
- Rename the status pill to `Ручной режим MVP` or remove it if the screen already explains manual execution.
- Keep `Settings` reachable, but name it `Провайдеры и ключи` if it is primarily execution configuration.

### Command Center

Current state: `lib/src/screens/command_center_screen.dart` has a hero, current MVP status panel, studio grid, workflow guide, and workflow strip. It already states the honest manual production flow.

Problems:
- The screen repeats the same destinations in multiple places.
- Hero, current MVP panel, studio grid, and guided workflow all compete.
- Status labels are inconsistent: `Ready now`, `Требует настройки`, `Через сайт / вручную`, `Справочник`, `Экспериментально`.
- `MVP` and `production flow` copy is useful internally but less polished for an end user.

Recommendation:
- Make the first viewport one clear launch panel: current step, primary CTA `Начать в промпт-чате`, secondary `Открыть внешние сервисы`.
- Replace the studio grid with grouped workflow lanes: `1. Промпт`, `2. Создание`, `3. Запуск`, `4. Библиотека`.
- Move future/lab modules below the main workflow with muted styling.
- Standardize statuses with the shared state language below.

### AI Chat / Text Workspace

Current state: `lib/src/screens/text_workspace/text_workspace_screen.dart` supports Ollama local, browser handoff to ChatGPT/Gemini/Claude, OpenRouter/OmniRoute API, prompt builders for Image/Video, inline handoff panels, provider runtime status, and manual saving.

Problems:
- The right/control area contains provider selection, status, settings, prompt builders, copy, Browser Hub, Image Studio, and Video Studio actions.
- Browser handoff and API execution are both valid, but the mode shift is cognitively heavy.
- The main composer primary button changes between `Отправить` and `Подготовить handoff`, which is correct but needs stronger surrounding explanation.
- `Health` remains English in the runtime status panel.

Recommendation:
- Keep the chat as the main creation surface with one primary action.
- Put provider state in a compact header row: provider name, route, readiness, settings link.
- Group secondary actions under `Отправить в студию`: `Изображение`, `Видео`, later `Аудио`.
- When browser route is selected, show one inline handoff card with three actions only: `Скопировать`, `Открыть сайт`, `Сохранить результат`.
- Rename `AI Chat` to `Промпт-чат`.

### Execution Settings

Current state: `lib/src/screens/settings_screen.dart` stores API provider keys, Base URL, models, health checks, local provider endpoints, ComfyUI workflow paths, ACE-Step endpoints, and safety notes.

Problems:
- Useful controls are buried in many card fields.
- API provider cards and local provider cards use different layouts and state signals.
- Some copy says real API calls are not connected, while OpenRouter/OmniRoute text execution appears connected elsewhere. This needs product-level clarity.
- Technical fields are exposed before the user understands whether the provider is usable.

Recommendation:
- Rename to `Провайдеры и ключи`.
- Split into tabs or sections: `Текст`, `Изображения`, `Видео`, `Аудио`, `Локальные`.
- Each provider card should have a collapsed summary: name, route, status, model, last check, primary action.
- Expand advanced fields only when the user chooses `Настроить`.
- Move safety copy into an info disclosure unless it blocks the current action.

### Browser Hub

Current state: `lib/src/screens/browser/browser_hub_screen.dart` provides tool search/filtering, selected service workspace, prompt handoff, external open, GitHub/notes actions, and manual result saving.

Problems:
- Filter taxonomy is broad and technical: `API Candidates`, `Experimental`, `Research only`, `Local/Self-host`.
- The selected service workspace and the tool list have comparable weight.
- Internal browser placeholder actions are visible even though the real route is external/manual.
- The default prompt and status text make the page feel like a demo rather than a task workspace.

Recommendation:
- Make the selected service and prompt handoff the primary pane.
- Put discovery filters in a secondary sidebar with fewer categories: `Текст`, `Изображения`, `Видео`, `Аудио`, `Локально`, `Исследование`.
- Use one primary action: `Открыть сайт`.
- Keep `Скопировать prompt` and `Сохранить результат` as secondary actions.
- Hide or clearly disable internal browser actions under `Скоро`.

### Image Studio

Current state: `lib/src/screens/generation/image_generation_screen.dart` has capability modes, prompt composer, local prompt improvement, provider panel, ComfyUI route card, result canvas, and render history rail.

Problems:
- `Prepare`, `Copy`, `Open`, `Save manual`, provider type chips, and result canvas compete.
- The status model is better here than elsewhere, but still uses mixed product vocabulary.
- Result canvas can imply internal generation even when the actual route is prompt handoff.

Recommendation:
- Title the workflow `Изображения`.
- Use the primary action based on route:
  - Browser/external: `Подготовить и открыть сервис`.
  - API not configured: `Настроить API-ключ`.
  - Local unavailable: `Проверить локальный сервис`.
- Keep manual save attached to the result/handoff area, not duplicated in both composer and provider panel.
- Rename `Собранный image prompt` to `Готовый prompt для изображения`.

### Video Studio

Current state: `lib/src/screens/generation/video_generation_screen.dart` includes capability modes, cinematic controls, shot planning, prompt improvement, browser workspace panel, provider panel, result canvas, and history rail.

Problems:
- The screen has the most complex workflow but not the clearest step structure.
- Shot planning is valuable but appears alongside many execution controls.
- Browser/external provider mode changes the center panel substantially, which can feel like a jump.

Recommendation:
- Title the workflow `Видео`.
- Use a visible stepper: `Идея`, `План кадров`, `Prompt`, `Сервис`, `Сохранение`.
- Treat shot plan as an expandable planning section, not a peer to provider execution.
- Make `Подготовить prompt для генерации` the one primary action until a provider is ready.
- Keep provider and manual result actions consistent with Image Studio.

### Audio Studio

Current state: `lib/src/screens/generation/audio_generation_screen.dart` supports music, voice, and sound design modes, external audio providers, ACE-Step local route, composed prompt, local status, and a local audio history list.

Problems:
- Audio uses a separate history implementation rather than the shared generation rail pattern.
- ACE-Step state is useful but visually competes with the main external provider flow.
- Labels mix `Audio Studio`, `Music`, `Voice`, `Sound Design`, `Selected provider`, and Russian action copy.

Recommendation:
- Title the workflow `Аудио`.
- Use mode labels `Музыка`, `Голос`, `Звук`.
- Put ACE-Step under a local route panel with status `Локально недоступно`, `Проверяется`, or `Готово`.
- Replace the local audio history list with shared Library/History language.
- Keep one primary action: `Подготовить prompt` or `Открыть сайт`, depending on selected provider readiness.

### History / Assets

Current state: `lib/src/screens/history/render_history_screen.dart` aggregates execution jobs, runtime jobs, manual assets, and meaningful events. It filters by `All`, `Image`, `Video`, `Audio`, `Director`, `Provider handoff`, and `Manual`.

Problems:
- The screen title `History / Assets` is accurate but not product-polished.
- Filters are English and technically framed.
- Provider handoff, prompt draft, manual result, and session event need clearer visual distinction.
- Empty and list states need one clear reuse action.

Recommendation:
- Rename to `Библиотека`.
- Use filters: `Все`, `Изображения`, `Видео`, `Аудио`, `Планы`, `Провайдеры`, `Вручную`.
- Each entry should expose type, provider, source workspace, status, and one primary reuse action.
- Empty state should say what will appear and offer `Создать первый prompt`.

### Local Service / Provider Status

Current state: Local status is spread across Settings, Image Studio ComfyUI, Audio Studio ACE-Step, AI Chat provider runtime status, and current session strip.

Problems:
- The same provider can be described differently on different screens.
- Local health checks are useful but not always tied to the next user action.
- Status colors and labels are not centralized.

Recommendation:
- Create a shared provider state vocabulary before deeper visual redesign.
- Show provider status at three levels:
  - Compact pill in nav/current session.
  - One-line summary in studio/provider cards.
  - Detailed diagnostics in `Провайдеры и ключи`.
- Never show a disabled/future local route as an equal peer to a ready browser route.

## Information Architecture Recommendation

Use a workflow-first IA:

1. `Командный центр`
   Start, current workflow, quick status, and lab/future links.

2. `Промпт-чат`
   Text execution, prompt drafting, and send-to-studio actions.

3. `Создание`
   A grouped destination for `Изображения`, `Видео`, `Аудио`, and later `Режиссер`.

4. `Внешние сервисы`
   Browser/manual provider handoff and discovery.

5. `Библиотека`
   Saved manual results, prompt drafts, handoffs, and plans.

6. `Провайдеры и ключи`
   API keys, endpoints, local health checks, and advanced setup.

Future surfaces such as Agents, Apps, Workflows, Marketing, and broader tools should move out of the primary nav until they are part of the frozen MVP path.

## Provider / Tool State Language

Use these labels everywhere:

| State | Russian label | Meaning | Visual treatment |
| --- | --- | --- | --- |
| Ready | `Готово` | The route can be used now. | Positive, quiet green/cyan. |
| Needs API key | `Нужен API-ключ` | The user must add a key. | Amber, actionable. |
| Needs setup | `Нужна настройка` | Endpoint/model/config is incomplete. | Amber, actionable. |
| Browser/manual | `Через сайт` | Copy/open/manual workflow is valid. | Neutral blue/gray, not a warning. |
| Manual save | `Вручную` | User records an external result. | Neutral gray. |
| Local unavailable | `Локально недоступно` | Local runtime is disabled or offline. | Muted amber/red in diagnostics only. |
| Checking | `Проверяется` | Health check in progress. | Neutral progress state. |
| Experimental | `Эксперимент` | Available but not core MVP. | Muted violet/gray. |
| Research only | `Только исследование` | Informational/tool reference only. | Quiet gray, not primary. |
| Coming soon | `Скоро` | Not usable yet. | Disabled gray. |

Avoid `Ready now`, `API placeholder`, `manualOnly`, `Provider handoff`, and `Local prep mode` in visible UI.

## Workflow UX Plan

The app should consistently communicate this MVP flow:

1. `Идея`
   The user writes or imports the starting idea.

2. `Prompt`
   The user improves, composes, or converts the idea.

3. `Сервис`
   The user chooses API, local, browser, or manual route.

4. `Результат`
   The user creates the result in the external or local service.

5. `Библиотека`
   The user saves and reuses the output.

Every major screen should have one primary action:

| Screen | Primary action |
| --- | --- |
| Command Center | `Начать в промпт-чате` |
| Prompt Chat | `Отправить` or `Подготовить handoff` |
| Image Studio | `Подготовить prompt` or `Открыть сервис` |
| Video Studio | `Подготовить prompt` |
| Audio Studio | `Подготовить prompt` |
| Browser Hub | `Открыть сайт` |
| Providers | `Настроить` or `Проверить подключение` |
| Library | `Переиспользовать` |

Manual result saving should be present wherever external execution is expected, but it should not be repeated in every panel on the same screen.

## Visual System Direction

- Keep the dark professional base, but reduce gradients and glass-panel variation.
- Use one dominant accent for active workflow state and reserve secondary accents for media type.
- Use cards only for individual items, provider cards, and modal-like panels. Avoid card-inside-card layouts.
- Prefer 8-12 px radius for functional panels.
- Use one elevation/border style for standard panels and a slightly stronger style for the active step.
- Typography:
  - Page title: 28-32 px.
  - Section title: 18-20 px.
  - Panel title: 14-16 px.
  - Body/help text: 13-14 px.
  - Badge text: 11 px.
- Buttons:
  - Filled button only for the next step.
  - Outlined buttons for secondary actions.
  - Icon buttons for compact utility actions.
  - Disabled future actions should be visibly disabled and not styled like live actions.
- Empty states should include one icon, one sentence, and one CTA.
- Mobile layouts should collapse sidebars below the main task and keep status pills wrapping cleanly.

## Russian Terminology Standard

Use these visible labels:

| Current / mixed label | Standard label |
| --- | --- |
| AI Chat | `Промпт-чат` |
| Text Workspace | `Промпт-чат` |
| Execution Settings | `Провайдеры и ключи` |
| Provider settings | `Провайдеры и ключи` |
| Browser Hub | `Внешние сервисы` |
| Image Studio | `Изображения` |
| Video Studio | `Видео` |
| Audio Studio | `Аудио` |
| History / Assets | `Библиотека` |
| Manual Result | `Результат вручную` |
| Save manual result | `Сохранить результат вручную` |
| Provider | `Провайдер` |
| Health Check | `Проверить подключение` |
| API Key | `API-ключ` |
| Base URL | `Адрес API (Base URL)` |
| Model / Router profile | `Модель / роутер` |
| Browser handoff | `Через сайт` |
| Provider handoff | `Передача в сервис` |
| Local prep mode | `Ручной режим MVP` |

Keep product names and technical identifiers in English where users expect them: OpenRouter, OmniRoute, Ollama, ComfyUI, ACE-Step, ChatGPT, Gemini, Claude, API, URL.

## Prioritized Implementation Roadmap

### UX Patch 1: Navigation, Hierarchy, and Terminology

Goal: Make the app immediately understandable without changing execution behavior.

Likely files:
- `lib/src/shell/app_shell.dart`
- `lib/src/screens/command_center_screen.dart`
- shared status/label widgets if already available

Changes:
- Reduce primary nav to MVP destinations.
- Move disabled/future sections out of the top bar.
- Rename visible labels using the terminology table.
- Standardize status pills on Command Center.
- Make Command Center one clear start screen with one primary CTA.

Risk: Low to medium. Mostly copy/layout, but navigation tests may need updates.

Validation:
- `flutter analyze`
- widget tests if current local toolchain allows them
- desktop and mobile screenshot smoke checks
- manual route check for each active destination

Acceptance criteria:
- No future/disabled routes appear as primary nav peers.
- First viewport has one obvious start action.
- No visible `Ready now`, `Local prep mode`, `History / Assets`, or `AI Chat` unless intentionally kept as product copy.

### UX Patch 2: Provider State System

Goal: Centralize provider readiness language and reduce contradictory statuses.

Likely files:
- `lib/src/screens/settings_screen.dart`
- `lib/src/screens/text_workspace/text_workspace_screen.dart`
- `lib/src/screens/generation/image_generation_screen.dart`
- `lib/src/screens/generation/video_generation_screen.dart`
- `lib/src/screens/generation/audio_generation_screen.dart`
- provider/status shared widgets or models

Changes:
- Add shared visible labels for provider states.
- Convert provider cards to summary-first layout.
- Unify API/local/browser/manual wording.
- Make health diagnostics secondary to the next action.

Risk: Medium because status text appears across many screens.

### UX Patch 3: Prompt-Chat Workflow Polish

Goal: Make chat the clear entry point for prompt creation and studio handoff.

Likely files:
- `lib/src/screens/text_workspace/text_workspace_screen.dart`

Changes:
- Simplify control panel hierarchy.
- Group send-to-studio actions.
- Clarify browser handoff card actions.
- Rename `Health` and other mixed labels.

Risk: Medium.

### UX Patch 4: Browser Hub Redesign

Goal: Make external execution feel deliberate, not like a workaround.

Likely files:
- `lib/src/screens/browser/browser_hub_screen.dart`
- `lib/src/data/seed_browser_ai_tools.dart`
- `lib/src/widgets/generation/browser_workspace_panel.dart`

Changes:
- Promote selected service + prompt handoff.
- Simplify filters.
- Hide unavailable internal browser route under a clear disabled state.
- Align manual save language with studios.

Risk: Medium.

### UX Patch 5: Studio Consistency

Goal: Make Image, Video, and Audio share a recognizable creation system.

Likely files:
- `lib/src/screens/generation/image_generation_screen.dart`
- `lib/src/screens/generation/video_generation_screen.dart`
- `lib/src/screens/generation/audio_generation_screen.dart`
- `lib/src/widgets/generation/*`

Changes:
- Shared stepper/rail vocabulary.
- One primary action per provider state.
- Shared manual result placement.
- Shared history/library language.

Risk: Medium to high due to large screen files.

### UX Patch 6: Visual Polish and Responsive QA

Goal: Make the MVP feel premium and stable.

Likely files:
- theme files
- shared cards/buttons/badges
- affected screens from previous patches

Changes:
- Normalize panel borders, radii, spacing, text sizes, and badge colors.
- Reduce decorative gradients where they compete with content.
- Screenshot QA for desktop and mobile.

Risk: Medium.

## First Implementation Patch Recommendation

Start with UX Patch 1: navigation, Command Center hierarchy, and terminology.

Why first:
- It improves every session immediately.
- It does not require changing provider execution, storage, local services, or API behavior.
- It creates the vocabulary that later provider and studio patches can reuse.
- It reduces the perceived unfinished state by moving disabled/future features out of the primary path.

Recommended first patch scope:
- Rename top-level labels:
  - `AI Chat` -> `Промпт-чат`
  - `Image` -> `Изображения`
  - `Video` -> `Видео`
  - `Audio` -> `Аудио`
  - `Browser` -> `Внешние сервисы`
  - `History` -> `Библиотека`
- Remove `Workflows`, `Agents`, and `Apps` from the primary nav or move them to a muted `Скоро` area on Command Center.
- Replace `Local prep mode` with `Ручной режим MVP` or remove it.
- Rework Command Center so the first CTA is `Начать в промпт-чате`.
- Convert Command Center status labels to the shared vocabulary.
- Add a short `MVP flow` strip using: `Идея -> Prompt -> Сервис -> Результат -> Библиотека`.

Do not include deeper provider settings or studio rewrites in the first patch. Those should follow after the shared language is visible and accepted.
