# MediaPipe Flutter Plugin Verification Spike

**Date:** 2026-04-09
**Task:** Phase A Task 1 of `docs/superpowers/plans/2026-04-02-reckon-phase1.md`
**Gate decision:** ESCALATE — the plan's assumed plugin does not exist under the pinned name, the closest official plugin is stale and has a known broken-session bug, and the maintained third-party alternative does not list Phi-3 Mini among its supported models. User input required before continuing.

---

## Step 1 — pub.dev search results

`dart pub search` was removed from the Dart SDK, so the verification was done by direct
lookups against pub.dev and GitHub. Three candidate package names were checked:

| Package name | Exists on pub.dev? | Notes |
|---|---|---|
| `mediapipe_task_genai` | **No (HTTP 404)** | This is the name the plan's pubspec pinned. It does not exist. |
| `mediapipe_genai` | Yes, v0.0.1 | Google's official MediaPipe GenAI Flutter plugin. Single version, published May 14 2024, unverified uploader but the repo linked is `github.com/google/flutter-mediapipe`. |
| `flutter_mediapipe` | Yes, v0.0.7 | Unrelated face-mesh plugin from 2021. Not GenAI. Unmaintained. |
| `flutter_gemma` (bonus, surfaced via web search) | Yes, v0.13.2, published 2026-04-06 | Verified publisher `mobilepeople.dev`. Actively maintained. Built on top of MediaPipe GenAI internally. Supports `.task` files and streaming. |
| `ai_edge` (bonus, surfaced via web search) | Yes | Newer entrant, not investigated in depth for this gate. |

Sources:
- <https://pub.dev/packages/mediapipe_task_genai> (404)
- <https://pub.dev/packages/mediapipe_genai>
- <https://pub.dev/packages/mediapipe_genai/versions>
- <https://pub.dev/documentation/mediapipe_genai/latest/>
- <https://pub.dev/packages/flutter_mediapipe>
- <https://pub.dev/packages/flutter_gemma>
- <https://github.com/google/flutter-mediapipe>
- <https://github.com/google/flutter-mediapipe/issues>
- <https://github.com/DenisovAV/flutter_gemma>

---

## Step 2 — Findings per candidate

### Candidate A: `mediapipe_genai` (Google official)

- **Plugin name / version:** `mediapipe_genai` 0.0.1
- **Pub.dev page:** <https://pub.dev/packages/mediapipe_genai>
- **Upstream repo:** <https://github.com/google/flutter-mediapipe> (monorepo also hosting `mediapipe_core`, `mediapipe_text`)
- **Publisher:** "unverified uploader" on pub.dev, but repo URL is Google's official `google/flutter-mediapipe`.
- **Publication history:** A single version, `0.0.1`, published 2024-05-14. No subsequent releases in roughly 23 months.
- **`.task` file loading:** **Not documented.** The README states "generative AI models must be downloaded at runtime from a URL hosted by the developer" and directs users to Kaggle. The API reference exposes `LlmInferenceEngine(LlmInferenceOptions.cpu(...))` / `.gpu(...)` but the constructors are not documented in a way that confirms local-path `.task` loading versus URL-only.
- **Streaming generation:** **Yes.** `LlmInferenceEngine.generateResponse(String prompt)` returns `Stream<String>`; the README shows `await for (final chunk in responseStream) { ... }`.
- **Minimum Dart/Flutter SDK:** Dart 3.4 (per pub.dev metadata). Minimum Flutter SDK not stated.
- **Minimum Android SDK:** Not stated on pub.dev or in the README excerpt reviewed.
- **Minimum iOS:** 16.0 (required by the underlying MediaPipe GenAI native SDK).
- **Platforms listed:** Android, iOS, macOS.
- **Known issues (open on upstream tracker, 27 total):**
  - **#76 (2025-06-30)** — `LlmInferenceEngine_CreateSession` errors when loading `gemma-3N-E2B-IT-INT4.task`. This directly hits the `.task` loading path the plan depends on.
  - **#73 (2025-01-30)** — `mediapipe_text` and `mediapipe_genai` cannot be used in the same app (symbol clash).
  - **#71 (2024-09-09)** — Flutter master branch compatibility.
  - **#67** — missing framework files during macOS builds of the genai plugin.
  - **#56** — Android validation failures loading `gemma-2b-it-gpu-int8.bin`.

Summary: this is the "correct" plugin by lineage, but it has been untouched on pub.dev for ~23 months, has an open bug specifically about `.task` session creation, and has not published a fix. Using it as the foundation for Phase 1 is risky.

### Candidate B: `flutter_gemma` (community, actively maintained)

- **Plugin name / version:** `flutter_gemma` 0.13.2 (published ~3 days before this spike).
- **Pub.dev page:** <https://pub.dev/packages/flutter_gemma>
- **Upstream repo:** <https://github.com/DenisovAV/flutter_gemma>
- **Publisher:** `mobilepeople.dev` — **verified** pub.dev publisher.
- **`.task` file loading:** **Yes.** The README documents `.task` as a MediaPipe-optimized mobile format and `.litertlm` as the LiteRT-LM format; the plugin auto-detects the file extension. There is a `fromNetwork()` install helper; local-file loading exists but was not surfaced clearly in the README excerpt reviewed. This needs one more read before Task 10 is implemented.
- **Streaming generation:** **Yes.** `chat.generateChatResponseAsync().listen(...)` for async streaming is documented explicitly.
- **Built on MediaPipe internally:** Yes — the setup instructions reference "MediaPipe GenAI" and the native implementation uses MediaPipe's `LlmInference` under the hood.
- **Supported model types (per `ModelType` enum reviewed on GitHub):** `gemmaIt`, `deepSeek`, `qwen`, `functionGemma`, `general`. The README's prose list also mentions Gemma 3 / 3n variants, Qwen 2.5 / 3, **Phi-4 Mini**, DeepSeek R1, SmolLM 135M. **Phi-3 Mini is not called out as a supported / tested model.** `ModelType.general` may accept arbitrary compatible `.task` files, but this is unverified.
- **Minimum iOS:** 16.0.
- **Minimum Flutter SDK / Android SDK:** Not stated on pub.dev in the excerpt reviewed; need to inspect the plugin's `android/build.gradle` before Task 2 pins anything.
- **Platforms listed:** Android, iOS, macOS, Windows, Linux, Web.
- **Active maintenance:** Yes — recent release within the last week; verified publisher.

Summary: this is the pragmatic choice. It is actively maintained, has a verified publisher, supports `.task` loading and token streaming, and internally uses the same MediaPipe GenAI native layer the plan wanted. The wrinkle is that the plan asked for **Phi-3 Mini** specifically and `flutter_gemma`'s documented / tested model list is **Phi-4 Mini**, Gemma 3 / 3n, and Qwen. We either (a) switch the Phase 1 model to Phi-4 Mini or Gemma 3 1B, or (b) attempt Phi-3 Mini through `ModelType.general` and accept the unverified path.

### Candidate C: `flutter_mediapipe`

Face-mesh only, last touched 2021, unverified uploader. Not applicable to this gate. Skipped.

### Candidate D: `ai_edge`

Surfaced in web search but not investigated in depth here. Worth a look if both A and B are rejected.

---

## Step 3 — Gate decision

**ESCALATE.** The plan as written is not executable as-is. Specifically:

1. The pubspec pin `mediapipe_task_genai: ^0.0.3` cannot be resolved — no such package name.
2. The closest-by-name official plugin (`mediapipe_genai` 0.0.1) has been effectively frozen for ~23 months and has an open upstream bug (#76) about the exact code path Reckon depends on (`LlmInferenceEngine` session creation from a `.task` file).
3. The actively maintained alternative (`flutter_gemma` 0.13.2) covers the required capabilities (`.task` loading, streaming generation, MediaPipe GenAI under the hood) but does **not** document Phi-3 Mini support. Its documented Phi variant is Phi-4 Mini.

Neither path silently matches the plan. The user should pick.

### Fallback options (per the plan's Step 3)

**Option 1 — Switch plugin AND model, keep `PrivateModeImpl` architecture.**
Swap the dependency from `mediapipe_task_genai ^0.0.3` to `flutter_gemma ^0.13.2`. Swap the Phase 1 model from Phi-3 Mini to one of the models `flutter_gemma` explicitly supports on-device — candidate choices:
  - **Gemma 3 1B IT (`.task`)** — smallest, best latency, weakest reasoning.
  - **Phi-4 Mini (`.task`)** — closest spiritual replacement for Phi-3 Mini, stronger reasoning, larger download.
  - **Qwen 2.5 1.5B / 3B (`.task`)** — solid middle ground, permissive license.
This is the lowest-risk path. It keeps the on-device Private mode dream alive and lets Task 9 / Task 10 / Task 17 stay roughly as planned. It does require rewriting the model-download constants and re-running any prompt-engineering work the plan assumed against Phi-3.

**Option 2 — Fall back to `llama.cpp` via FFI.**
Use `llama_cpp_dart` or similar and ship a GGUF build of Phi-3 Mini. Keeps the Phase 1 model target. Downsides: heavier FFI plumbing, Android NDK build complexity (the android NDK is already available at `androidDevTools`, but this is still substantially more work than a pub plugin), and we'd own the native toolchain. Push Task 10's complexity up significantly.

**Option 3 — Make `PrivateModeImpl` blocking (no streaming) and ship a one-shot generator.**
Only viable if we pick a plugin that doesn't stream, which none of the shortlisted candidates force us into — both `mediapipe_genai` and `flutter_gemma` stream. So this option is not actually required by any of the findings, but it is preserved here because the plan listed it. Worth considering only if we decide streaming UX isn't worth the extra intake-screen complexity.

**Option 4 — Defer Private mode to Phase 2; use a hardcoded mock for Phase 1.**
Keep Task 9's `LlmService` interface exactly as planned, but make the Phase 1 concrete implementation a deterministic canned-response stub (or route to a server-side dev-only endpoint behind a feature flag). Defers the entire MediaPipe spike problem until we have a working Phase 1 that proves the rest of the product. Clean, safe, but sells the "local-first LLM" headline short during the first release.

### Recommendation (for the user, not a unilateral decision)

Option 1 with **Gemma 3 1B IT** as the Phase 1 model. Rationale: it keeps the architectural shape the plan assumed (pub plugin, `.task` file, streaming Stream<String>), it ships on a verified publisher's actively maintained plugin, the model is small enough to download over mobile, and MediaPipe's test matrix actually covers it. Phi-3 Mini was always a *preference*, not a *requirement*, and Gemma 3 1B is a reasonable stand-in for Phase 1 while we re-evaluate model choice in Phase 2.

Before proceeding we still need to verify three things in a short follow-up:

1. `flutter_gemma`'s minimum Android SDK (inspect `android/build.gradle` in the repo) so Task 2 can pin `minSdkVersion` correctly.
2. `flutter_gemma`'s API for loading a `.task` file from a local file path (as opposed to `fromNetwork`), so `ModelDownloadService` in Task 10 can hand off the downloaded file.
3. Whether `flutter_gemma` exposes per-token streaming as `Stream<String>` or as a listener callback — Task 17's intake UI assumes async-stream shape.

None of those three block the gate decision itself; they are prerequisites for Task 10 design once the user picks an option.

---

## Step 4 — Follow-up spike: flutter_gemma API details

After the user chose **Option 1 with Gemma 3 1B IT** as the Phase 1 model, a follow-up
read-only spike pulled the three facts that Task 2 and Task 10 need before they can
be implemented correctly:

**Q1. Minimum Android SDK: `minSdkVersion 24`.** Confirmed from
`github.com/DenisovAV/flutter_gemma/blob/main/android/build.gradle`. The plan's existing
`minSdkVersion 24` pin in Task 2 is compatible — no bump required.

**Q2. Loading a `.task` file from a local path: fluent builder.**
```dart
await FlutterGemma.installModel(modelType: ModelType.gemmaIt)
  .fromFile(absolutePath)
  .install();
// then
final model = await FlutterGemmaPlugin.instance.createModel(
  modelType: ModelType.gemmaIt,
  maxTokens: ...,
  preferredBackend: ...,
);
final session = await model.createSession(...);
```
Source: `github.com/DenisovAV/flutter_gemma/blob/main/lib/flutter_gemma_interface.dart`.
Mobile-only (Android/iOS). Matches our flow: `dio` downloads the `.task` to app docs
directory, we pass the absolute path to `.fromFile()`.

**Q3. Streaming shape: native `Stream<String>`.**
```dart
Stream<String> getResponseAsync();
```
No StreamController wrapper needed. The `await for (final token in ...)` pattern in
Task 17's intake UI works directly. There is also a typed `Stream<ModelResponse>`
with `TextResponse` / `FunctionCallResponse` / `ThinkingResponse` variants — useful
later for thinking-token separation but not required for Phase 1.

**Q4. Gemma 3 1B IT download source.**
- `.task` file hosted at `huggingface.co/litert-community/Gemma3-1B-IT`.
- HF Hub API exposes per-file SHA-256 via `/api/models/litert-community/Gemma3-1B-IT`;
  `ModelDownloadService` should fetch the hash at download time, not hardcode it.
- **Gated model.** Requires a HuggingFace token and license acceptance before the file
  is downloadable. The download service must support injecting an `Authorization:
  Bearer <HF_TOKEN>` header; the app will prompt the user for a token on first download.

**Q5. Phi-4 Mini (secondary option).**
- `.task` at `huggingface.co/litert-community/Phi-4-mini-instruct`. Same HF-gated flow.
- Not wired up in Phase 1 UI, but the `ModelDownloadService` design must support
  multiple model specs so Phi-4 Mini can be added in a small Phase 2 patch.

---

## Final gate decision: **PROCEED**

- Plugin: `flutter_gemma ^0.13.2` (verified publisher `mobilepeople.dev`).
- Primary model: **Gemma 3 1B IT** (`ModelType.gemmaIt`).
- Secondary model (Phase 2 wire-up, design for it now): **Phi-4 Mini**.
- Plan updates required before Task 2 runs:
  1. `pubspec.yaml` dependency swap.
  2. Add a fourth Spec Deviation entry.
  3. Task 10 header banner redirecting code samples to `flutter_gemma` API.
- No `minSdkVersion` bump required.
