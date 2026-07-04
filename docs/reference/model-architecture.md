# Reference — Model architecture (LLM backends, selection, and routing)

Precise lookup material for Reckon's LLM layer: the interface, the backends, how one is
selected, the model roster, and the download pipeline. All of it lives in
`lib/core/llm/`. For the *why*, see [ADR-0001](../adr/0001-on-device-llm-first.md) and
[ADR-0002](../adr/0002-pluggable-llm-backends.md).

## The interface: `LlmService`

Every backend implements one interface (`llm_service.dart`). Callers never know which
model answered.

| Method | Returns | Used by |
|---|---|---|
| `conductIntake(IntakeContext)` | `Stream<String>` | Intake — streaming interview |
| `synthesizeOutsideView(Case, ReferenceClassEntry, UserProfile)` | `OutsideViewResult` | Outside view |
| `detectRepollSentiment(int lean, String rationale)` | `MismatchResult` | Re-poll contradiction check |
| `generateRevealObservation(CaseTimeSeries)` | `RevealObservation` | Reveal |
| `generateCommunitySeed(Case)` | `CommunitySeed` | Community seed bot (Phase 3) |

`modelVersion` (a getter) identifies the active model; it is stamped into structured
outputs so the [prediction scorecard](feature-status.md) can attribute a result to the
model that produced it.

**Error policy (all backends):** a failed generation returns a **recoverable sentinel** —
an empty stream, or fallback text ("Unable to generate observation…") — never an
exception that reaches the UI. A model hiccup degrades gracefully; it never crashes the
app.

## The three backends

| Backend | Class | Transport | Status |
|---|---|---|---|
| **On-device** | `PrivateModeImpl` | `flutter_gemma` (MediaPipe) | **Live** — the only backend the app instantiates |
| **BYOK** | `ByokModeImpl` → `AnthropicLlmService` | Anthropic Messages API, user's key | Built + unit-tested, **not wired** |
| **Connected** | `ConnectedModeImpl` → `AnthropicLlmService` | Cloudflare Worker proxy → Anthropic | Built + unit-tested, **not wired / not deployed** |

`ByokModeImpl` and `ConnectedModeImpl` are thin wrappers over the same
`AnthropicLlmService` + `AnthropicClient`; they differ only in **base URL** and **auth
headers** (BYOK sends `x-api-key: <user key>` to `api.anthropic.com`; Connected sends an
optional `Authorization: Bearer <app token>` to the Worker origin). The client adds
`content-type` and `anthropic-version: 2023-06-01` and posts to `v1/messages`. The
code's default cloud model is `claude-sonnet-4-6` (a user could pick another Claude
model in settings). The `http.Client` is injectable, so the whole cloud stack is
testable without the wire.

All three backends reuse the **same five system prompts** (`llm_prompts.dart`: intake
interviewer, outside-view synthesizer, re-poll sentiment detector, reveal observation,
community seed bot), so outputs stay consistent if a user upgrades.

## How the active backend is selected

Today, selection is **on-device only** — no runtime routing to a cloud model exists yet.
The providers in `llm_providers.dart`:

```
selectedModelIdProvider  ──▶  activeModelSpecProvider  ──▶  llmServiceProvider
 (secure storage: the           (ReckonModelSpec.byId,       (verify file on disk →
  user's chosen model id)         falls back to Gemma 1B)     install into flutter_gemma →
                                                              create InferenceModel →
                                                              PrivateModeImpl)
```

- `llmServiceProvider` is `keepAlive`d — installing the `.task` model and creating the
  native `InferenceModel` takes seconds and pins the file, so it survives route changes.
- The inference model is created with `maxTokens: 4096` (a smaller context starved
  multi-turn intake and produced empty/garbled output) and `PreferredBackend.gpu`.
- Intake replays only the **last ~12 turns** of the transcript — a small model's context
  is tiny, and feeding an ever-growing transcript is what made it go silent after a
  couple of exchanges.

Wiring a BYOK/Connected switch means overriding `llmServiceProvider` to return the
appropriate service based on a persisted user choice — the seam is ready; the toggle is
the Phase-2 work.

## The model roster (`ReckonModelSpec`)

`ReckonModelSpec` is **pure Dart** (no `flutter_gemma` import, so it's unit-testable);
its `modelType` string is mapped to the plugin's `ModelType` enum in `llm_providers.dart`.
Add an entry to `availableModels` and it appears in Settings automatically.

| id | Display | ~Size | `modelType` | Source | Token? |
|---|---|---|---|---|---|
| `gemma-3-1b-it` | Gemma 3 1B | ~555 MB | `gemmaIt` | community mirror | no (default) |
| `qwen-2.5-1.5b-it` | Qwen 2.5 1.5B | ~1.6 GB | `qwen` | `litert-community` | no (open weights) |
| `phi-4-mini-it` | Phi-4 Mini | ~4 GB | `phi` | `litert-community` | no (open weights) |

**Trust/token story:** the shipped models are on trusted, **ungated** hosts
(`litert-community` for Qwen/Phi-4; a community mirror for Gemma), so an unauthenticated
`resolve` succeeds and **no HuggingFace token is needed**. `requiresToken` stays `false`
for them, so Settings shows no token UI. If a future spec points at a *gated* model, set
`requiresToken: true`; the download and onboarding flows then prompt for a HF token via
`hf_token.dart` and store it in secure storage. (`approximateSizeBytes` is for the
progress bar only — never for completeness validation.)

## The download pipeline (`ModelDownloadService`)

Robustness matters because the download is the first hard dependency a user hits.

- **Atomic completion.** Bytes stream to `<file>.task.part`; only a fully-finished
  transfer is renamed to the final `.task`. So the mere existence of the final file
  means the download completed — completeness is **never** inferred from a guessed size
  (doing so once deleted correctly-sized models and soft-bricked the LLM). `isDownloaded`
  only rejects an empty/garbage file (< 1 MB).
- **Resumable.** An interrupted attempt leaves the `.part` on disk; the next attempt
  sends an HTTP `Range` request for the remaining bytes and appends, instead of
  restarting from zero (which kept happening when the phone slept mid-download and
  Android suspended the process). A **wakelock** is also held during downloads to avoid
  the interruption in the first place.
- **416 recovery.** If a stale `.part` is larger than the resource, the `Range` request
  is unsatisfiable (HTTP 416); the service discards the partial and restarts from byte 0
  instead of looping on the error every retry.
- **Ignored-range recovery.** If the server ignores the `Range` and returns `200` instead
  of `206`, the appended bytes would corrupt the file — the service detects this, discards
  the partial, and pulls a clean copy.

## Failure messaging (`model_error.dart`)

`modelStartErrorMessage` distinguishes *missing* from *broken*: it only tells the user to
download when the model file is genuinely absent; when the file is present but the runtime
failed to start (plugin init, incompatible build, low memory) it surfaces the real error
rather than misleadingly asking them to re-download a model they already have.

## Platform constraint

The on-device path is **Android-only** (MediaPipe GenAI, minSdk 24). The cloud backends
are plain HTTPS and would work anywhere, but they are not wired into the app today — so
in practice Reckon's model layer is Android-only.
