# UX/UI MVP implementation status

Branch: `codex/mvp-ux-completion`

Base: `7cc9198 Add UX UI audit plan`

## Completed scope

### UX Patch 1 — Navigation, hierarchy, terminology

- Primary navigation now contains only the frozen MVP path.
- Command Center, Prompt Chat, Images, Video, Audio, External Services,
  Library, Providers, and settings use consistent Russian product labels.
- Future sections no longer compete in the primary navigation.
- Command Center has one primary start action and a visible workflow.

### UX Patch 2 — Provider state system

- Added `ProviderUiState` as the shared presentation vocabulary.
- Added a reusable `ProviderStateBadge`.
- Standardized ready, API-key, setup, browser, manual, local, checking,
  experimental, research, and coming-soon states.
- Provider settings use collapsed summaries before technical fields.

### UX Patch 3 — Prompt Chat polish

- Prompt Chat is the named MVP entry point.
- Provider mode, model, readiness, and connection state are grouped.
- Studio and external-service handoff actions use the shared terminology.
- Visible `Health`, `API placeholder`, and old workspace names were removed.

### UX Patch 4 — External Services

- Simplified discovery labels and filters.
- Selected service and prompt remain the primary workspace.
- `Open site` is the primary action.
- The unavailable embedded browser is a disabled `Coming soon` action.
- Manual results are saved to Library using consistent copy.

### UX Patch 5 — Studio consistency

- Images, Video, and Audio use a shared workflow-step component.
- Each composer has one primary next action.
- Video includes the shot-plan step explicitly.
- Browser/manual result actions use the same labels across studios.
- Studio titles and result/library language are consistent.

### UX Patch 6 — Visual and responsive polish

- Reused the existing dark professional theme with one functional panel
  language, compact badges, 10–14 px radii, and reduced action emphasis.
- Technical settings are progressively disclosed with expansion panels.
- Workflow steps wrap on narrow layouts.
- Widget tests were updated for the new primary labels.

### Execution routes added after UX freeze

- OpenAI GPT Image: direct Windows API call, PNG persistence, queue status,
  preview, and automatic Library asset.
- ComfyUI: API-workflow token replacement, `/prompt` submit, `/history`
  polling, `/view` download, and automatic Library asset.
- ElevenLabs: direct text-to-speech request, configurable Voice ID, MP3
  persistence, and automatic Library asset.
- ACE-Step 1.5: `/release_task` submit, `/query_result` polling, `/v1/audio`
  download, and automatic Library asset.
- Gemini Veo 3.1: long-running text-to-video request, operation polling, MP4
  download, and automatic Library asset.
- Direct secret-bearing routes intentionally return an unsupported message in
  web builds; Browser/manual handoff remains available there.

## Validation

- `git diff --check`: required and expected to pass before publishing.
- Flutter formatting, analyzer, widget tests, and Windows release build must be
  run with the project Flutter toolchain on Windows before merging.

Recommended Windows verification:

```powershell
.\.tools\flutter\bin\dart.bat format lib test
.\.tools\flutter\bin\flutter.bat pub get
.\.tools\flutter\bin\flutter.bat analyze --no-pub
.\.tools\flutter\bin\flutter.bat test
powershell -ExecutionPolicy Bypass -File .\build_fluten_windows.ps1
```
