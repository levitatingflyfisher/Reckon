# AGENTS.md

Guidance for AI coding agents (and humans) working in this repo. This is the
top-level map; when a subdirectory carries its own notes (e.g.
`lib/features/party/sync/transport/backends_README.md`), the closest one to the
file you're editing wins.

**Read these three, in order, before non-trivial work:**
1. [VISION.md](VISION.md) — what must stay true and why (the design commitments).
2. [docs/architecture/OVERVIEW.md](docs/architecture/OVERVIEW.md) — how it fits together, with diagrams.
3. [docs/concepts.md](docs/concepts.md) — the inner-crowd protocol and the domain model.

## Take the code as current-state, not gospel

Every line of source and every comment here was written by an AI assistant. Treat
it as **an accurate record of what currently exists, offered with gratitude and a
grain of salt** — not as a specification and not as guaranteed-correct. A comment
claiming an invariant is a *hypothesis to verify*, not a proof. If a comment and the
tests disagree, the tests win; if the tests and reality disagree, reality wins. When
you rely on a claim, confirm it (read the code, run the test) first.

## What this is

A **local-first personal decision journal for Android**. It runs a structured
"inner-crowd" protocol over a real decision — conversational intake → blinded
time-series re-polls → a reveal of your own drift → a delayed resolution check-in →
a calibrated record — entirely on-device, with no account and a small on-device LLM.
A roster of **forecasters** (personas on the local model, BYOK/OpenAI-compatible
backends, imported bounty bots) can *duel* the user on open cases: sealed forecasts,
scored per-prediction at resolution, earning weight on a deference map. A second mode,
**ReckonParty**, does group preference voting — one-shot anonymous parties or
persistent groups with attributed ballots — over LAN or an optional zero-knowledge
relay. Flutter · Riverpod · Drift · `flutter_gemma`.

## Non-negotiables (breaking one is a regression, not a feature)

- **The model never decides.** It structures, synthesises, observes — and, in the
  duel, forecasts. A forecast stays **sealed until the user's own reveal** (never
  surface a lean/rationale on an open case), earns standing only through its scored
  track record, and sentinel outputs are never logged. Any change that turns an LLM
  output into a verdict ("you should pick B") is off-thesis. See
  [ADR-0007](docs/adr/0007-forecaster-duel-alignment-scoring.md).
- **Ghost works with zero server contact.** The full decision loop must keep running
  offline with no account. The only network call Ghost mode makes is downloading
  model weights over HTTPS. Don't add a telemetry endpoint, an analytics SDK, or a
  required sign-in.
- **The record stays honest.** Clarity Score, calibration, and the deference map are
  **computed from closed cases on query, never stored** — the one persisted score is
  the per-forecast alignment score (`ModelPredictions.score`, written once at
  resolution; a log entry, not a metric). A re-poll is **blinded** — never surface a
  user's prior polls before they re-answer. See
  [ADR-0006](docs/adr/0006-honest-record-blinded-repolls.md) and yellow paper R4/R5.
- **The relay only ever sees ciphertext.** ReckonParty encrypts on-device (AES-GCM-256);
  the key travels in the join link's URL **fragment** and must never reach the server.
  Don't move the key into the path/query or add a plaintext field — group names and
  member ids ride **only inside encrypted blobs**. See
  [ADR-0004](docs/adr/0004-reckonparty-zero-knowledge-sync.md) /
  [ADR-0008](docs/adr/0008-persistent-groups-attributed-ballots.md).
- **Cloud is opt-in and BYOK-first.** A cloud backend may only ever run against a key
  the *user* supplied (BYOK), an endpoint they configured (OpenAI-compatible), or a
  proxy they chose (Connected) — and today only *inside the duel*, per-forecaster.
  Never bake a key into the binary; never default a user onto the cloud.
- **Nothing leaves without a preview.** A bounty export exists only as a file the user
  reviewed and shared themselves; the bounty feature adds zero network callers. See
  [ADR-0009](docs/adr/0009-bounty-client-paste-import.md).
- **TDD, always.** Reproduce → failing test → fix → `flutter test` green → commit.
  Every bugfix ships with a regression test (Drift repos test against
  `NativeDatabase.memory()`).
- **Atomic commits, one concern each.** Commit messages state the *why* and the
  failure mode fixed. **No AI-attribution lines** in commit messages — deliberate
  project policy.
- **Never commit** `docs/superpowers/`, `CLAUDE.md`, or `GEMINI.md` — they're
  gitignored working artifacts. This repo ships `AGENTS.md`.

## Where things are (progressive disclosure)

Start with the module map in
[OVERVIEW.md § Module map](docs/architecture/OVERVIEW.md#module-map-where-to-look).
The short version, by concern:

| You're touching… | Go to |
|---|---|
| **The decision protocol** (case, poll, reveal) | `lib/features/case/`, `lib/features/reveal/` |
| **The outside view** (reference classes, stratification) | `lib/features/outside_view/`, `lib/core/database/seed/`, `assets/reference_classes.json` |
| **The honest record** (Clarity Score, calibration, update quality) | `lib/features/record/domain/usecases/` |
| **Forecasters / the duel** (roster, RunDuel, settings section) | `lib/features/forecasters/`; per-forecaster backend resolution in `lib/core/llm/forecaster_llm.dart` |
| **The deference map / prediction scoring** | `lib/features/predictions/` — weights usecase in `domain/usecases/`, R4 scoring in `data/prediction_repository_impl.dart`, `/forecasters` screen |
| **The bounty interface** (reckonBounty codec, redaction, paste-import) | `lib/features/bounty/` — wire shapes stay in `domain/bounty_codec.dart` |
| **The LLM** (on-device + cloud backends, routing) | `lib/core/llm/` — start at `llm_service.dart`, then `llm_providers.dart` |
| **Model download** (resume, token, 416 recovery) | `lib/core/llm/model_download_service.dart`, `model_spec.dart` |
| **The data model / storage** | `lib/core/database/`, `lib/features/*/data/` |
| **ReckonParty** (voting, crypto, relay, LAN) | `lib/features/party/` — voting in `domain/usecases/`, sync in `sync/`, LAN in `sync/transport/` |
| **ReckonParty groups** (rosters, considered mode) | `lib/features/party/` — `Group`/`GroupMember` domain + repos, `/groups` & `/group/:id` screens |
| **The relay server** | `relay/` (a standalone Dart/shelf app; see `relay/README.md`) |
| **Notifications** | `lib/core/notifications/` |
| **Design system / theme** | `packages/openhearth_design/`, `lib/shared/widgets/`, `lib/core/theme/` |
| **Routing / app shell** | `lib/app/` |

Docs are organized [Diátaxis](https://diataxis.fr/)-style — see
[docs/README.md](docs/README.md) for the tutorials / how-to / reference / explanation split.

## How to work here

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # Drift/Riverpod codegen
flutter analyze                                             # must be zero issues
flutter test                                                # the suite — green before you commit
```

For the ReckonParty relay (a separate Dart package):

```bash
cd relay && dart pub get && dart analyze && dart test
```

- **Flutter 3.32+ / Dart 3.8+** (CI builds on Flutter 3.44.x). `flutter_gemma`'s
  transitive `sqlite3 ^3.x` conflicts with `drift_dev`'s `^2.x`; a
  `dependency_overrides` in `pubspec.yaml` pins `sqlite3 ^3.1.0` — leave it unless
  build_runner surfaces a real incompatibility.
- **minSdk 24** (MediaPipe GenAI requirement). The release build is currently
  **debug-signed** — a real signing config is required before Play distribution.
- **LLM backends implement one interface** (`LlmService` in `core/llm/llm_service.dart`):
  `PrivateModeImpl` (on-device — the whole core loop), `ByokModeImpl` and
  `OpenAiCompatLlmService` (cloud/HTTP — live **in the duel only**, resolved
  per-forecaster in `forecaster_llm.dart`), `ConnectedModeImpl` (built + tested, not
  wired, no proxy deployed). A new backend implements the same **six** methods and
  returns *recoverable sentinels* on failure — never crash the app on a model hiccup,
  and never log a sentinel as a forecast.
- **Keep `ReckonModelSpec` pure Dart** (no `flutter_gemma` import) so it stays
  unit-testable; the `modelType` string is mapped to the plugin enum in
  `llm_providers.dart`.

## When you're unsure

Prefer the honest thing to the flattering thing on the record path. Prefer a failing
test to a plausible fix. Prefer matching the surrounding feature's Clean-Architecture
layering (domain → data → presentation) to introducing a new pattern. Prefer asking
(or leaving a `TODO` with the open question) to guessing on a privacy-relevant path —
anything that touches the network, the relay, or secure storage. When in doubt about
a decision's rationale, grep [docs/adr/](docs/adr/) before reopening it; you may be
re-litigating a settled trade-off.
