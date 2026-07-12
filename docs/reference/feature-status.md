# Reference — Feature status

What's shipped, what's built-but-unwired, and what's not built, as of the July 2026
forecaster-duel build. This is the honest per-area breakdown behind the
[vision scorecard](../../VISION.md). Legend: **Live** = wired and usable in-app ·
**Built (unwired)** = code exists and is tested but nothing instantiates it ·
**Not built**.

## The personal Reckon loop

| Area | Status | Where |
|---|---|---|
| Onboarding (auth → model → first case) | Live | `features/onboarding/presentation/` |
| Intake (streaming, on-device LLM) | Live | `features/case/presentation/intake_screen.dart`, `core/llm/private_mode_impl.dart` |
| Case create / summary / detail | Live | `features/case/` |
| Blinded re-poll | Live | `features/case/presentation/repoll_screen.dart` |
| Reveal (drift chart + observation) | Live | `features/reveal/` |
| Resolution date + check-in | Live | `features/reveal/presentation/resolution_*` |
| Outside view + stratification | Live | `features/outside_view/` |
| Record: Clarity Score, calibration, base rates, insight cards, update quality | Live | `features/record/domain/usecases/` |
| Technique glossary | Live | `features/glossary/`, `assets/glossary.json` |
| Deference map (`/forecasters`; `/model-scorecard` redirects to it) | Live | `features/predictions/` |
| Export (Markdown / JSON, plaintext) | Live | `features/export/` |
| Encrypted backup (.ohbk export/import, restorable) | Live | `features/sanctuary_backup/`, `features/export/data/import_service.dart` |
| Notifications (re-poll + resolution, deadline-aware, lockscreen-private) | Live | `core/notifications/` |
| Reference-class database | Live — **~15 of ~20** target categories | `assets/reference_classes.json`, `core/database/seed/` |

## The forecaster duel

| Area | Status | Where |
|---|---|---|
| Forecaster roster (add / edit / enable / delete; lazy default personas) | Live | `features/forecasters/`, Settings § Forecasters |
| Run the duel (sealed, idempotent, sentinel-guarded) | Live | `features/forecasters/domain/usecases/run_duel.dart`, case detail |
| Sealed chip on open cases · duel table at the reveal | Live | `features/case/`, `features/reveal/` |
| Per-prediction alignment scoring at resolution | Live | `features/predictions/data/prediction_repository_impl.dart` |
| Deference map (earned weights, n ≥ 5 gate, user entry on-read) | Live | `features/predictions/domain/usecases/compute_forecaster_weights.dart` |

## The bounty interface (reckonBounty client)

| Area | Status | Where |
|---|---|---|
| Export: de-identified request file (redaction draft + mandatory preview, share/copy) | Live — open cases only | `features/bounty/`, `/bounty/:caseId` |
| Import: paste BountyResponse JSON → sealed duel forecasts | Live — open cases only | `features/bounty/domain/usecases/import_bounty_responses.dart` |
| Directory fetch / any network transport | Not built (deliberate — [ADR-0009](../adr/0009-bounty-client-paste-import.md)) | — |
| Payments (bounty rail) | Not built (`rail: none`) | — |

## LLM backends

| Backend | Status | Where |
|---|---|---|
| On-device (`PrivateModeImpl`, multi-model) | Live | `core/llm/private_mode_impl.dart`, `llm_providers.dart` |
| Resumable / 416-recovering model download | Live | `core/llm/model_download_service.dart` |
| BYOK (user's Anthropic key) | **Live in the duel** (per-forecaster; key card in Settings) — still unwired for the core loop | `core/llm/byok_mode_impl.dart`, `anthropic_key_store.dart`, `forecaster_llm.dart` |
| OpenAI-compatible endpoint (llamafile / Ollama / vLLM) | **Live in the duel** (per-forecaster; web-safe) | `core/llm/openai_compat_*.dart` |
| Connected (Cloudflare Worker proxy) | **Built (unwired)** — no proxy deployed | `core/llm/connected_mode_impl.dart` |

The core loop's `LlmService` (intake, outside view, reveal) is always the on-device one;
there is no in-app switch to run the *loop* on a cloud backend yet. The duel resolves
backends per-forecaster. See [model architecture](model-architecture.md),
[ADR-0002](../adr/0002-pluggable-llm-backends.md), and
[ADR-0007](../adr/0007-forecaster-duel-alignment-scoring.md).

## Auth tiers

| Tier | Status |
|---|---|
| Ghost (no identity, on-device only) | Live |
| Token (recoverable anonymous account) | Not built (enum value only) |
| Named (standard login) | Not built (enum value only) |

Only `AuthTier.ghost` is implemented ([ADR-0003](../adr/0003-local-first-ghost-tier.md)).

## ReckonParty (group mode)

| Area | Status | Where |
|---|---|---|
| Create / join / vote / result screens | Live (routed) | `features/party/presentation/` |
| Approval + ranked-choice tallies | Live | `features/party/domain/usecases/` |
| AES-GCM-256 encryption, key-in-fragment link | Live | `features/party/sync/party_crypto.dart`, `party_link.dart` |
| Encrypted-blob relay client — **and the UI actually pushes/pulls now** (vote pushes, result screen pulls, close reaches the relay) | Live | `features/party/sync/party_relay.dart`, `party_sync_service.dart` |
| Self-hostable relay server | Live | `relay/` |
| LAN discovery (mDNS/DNS-SD) + socket sync | Live | `features/party/sync/transport/` |
| Persistent groups (`/groups`, `/group/:id`, attributed ballots, roster gossip) | Live | `features/party/`, schema v5 |
| Considered mode (tallies sealed until close → mutual reveal) | Live — UI gating, not cryptography | `features/party/presentation/party_result_screen.dart` |
| Group keys in use / group-manifest blobs on a relay | **Built (unwired)** — namespace exists and is tested; nothing populates it (deferred with relay deployment) | `features/party/sync/party_key_store.dart` |
| Offline re-push queue for failed ballot pushes | Not built — a failed push saves locally and warns | — |

## Not built

| Feature | Note |
|---|---|
| A community *server* | The old "community forecasting + AI seed bots" row shipped as the local duel + the file-transported bounty client; no server exists and none is required |
| Cloud backend for the core loop | The duel runs BYOK/OpenAI-compatible per-forecaster; intake/outside view/reveal have no cloud switch |
| Per-member calibration in groups | Deference map is personal-record only |
| Cross-device sync / account recovery | Depends on the unbuilt Token/Named tiers |
| iOS build / full PWA | On-device model is Android-only; the web PWA's only AI path is the duel via BYOK/OpenAI-compatible forecasters |
| Voice input | Product goal, not delivered |

## Known engineering debts

- Release build is **debug-signed**; R8/minify off (needs MediaPipe keep-rules).
- `SCHEDULE_EXACT_ALARM` declared but scheduling uses inexact alarms — the permission is
  effectively unused and a candidate for removal.

See [limitations](../limitations.md) for the user-facing consequences.
