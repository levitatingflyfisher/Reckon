# Reference — Feature status

What's shipped, what's built-but-unwired, and what's not built, as of `0.1.0`. This is
the honest per-area breakdown behind the [vision scorecard](../../VISION.md). Legend:
**Live** = wired and usable in-app · **Built (unwired)** = code exists and is tested but
nothing instantiates it · **Not built**.

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
| Record: Clarity Score, calibration, base rates, insight cards | Live | `features/record/domain/usecases/` |
| Technique glossary | Live | `features/glossary/`, `assets/glossary.json` |
| Model-prediction scorecard | Live | `features/predictions/` |
| Export (Markdown / JSON) | Live | `features/export/` |
| Notifications (re-poll + resolution, deadline-aware, lockscreen-private) | Live | `core/notifications/` |
| Reference-class database | Live — **~15 of ~20** target categories | `assets/reference_classes.json`, `core/database/seed/` |

## LLM backends

| Backend | Status | Where |
|---|---|---|
| On-device (`PrivateModeImpl`, multi-model) | Live | `core/llm/private_mode_impl.dart`, `llm_providers.dart` |
| Resumable / 416-recovering model download | Live | `core/llm/model_download_service.dart` |
| BYOK (user's Anthropic key) | **Built (unwired)** | `core/llm/byok_mode_impl.dart`, `anthropic_*.dart` |
| Connected (Cloudflare Worker proxy) | **Built (unwired)** — no proxy deployed | `core/llm/connected_mode_impl.dart` |

The live `LlmService` is always the on-device one; there is no in-app switch to a cloud
backend yet. See [model architecture](model-architecture.md) and
[ADR-0002](../adr/0002-pluggable-llm-backends.md).

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
| Encrypted-blob relay client | Live | `features/party/sync/party_relay.dart` |
| Self-hostable relay server | Live | `relay/` |
| LAN discovery (mDNS/DNS-SD) + socket sync | Live | `features/party/sync/transport/` |

## Not built

| Feature | Note |
|---|---|
| Community forecasting + AI seed bots | Tables exist locally; feature and server do not |
| Cross-device sync / account recovery | Depends on the unbuilt Token/Named tiers |
| iOS build / full PWA | On-device model is Android-only; web scaffold only |
| Voice input | Product goal, not delivered |

## Known engineering debts

- Release build is **debug-signed**; R8/minify off (needs MediaPipe keep-rules).
- `SCHEDULE_EXACT_ALARM` declared but scheduling uses inexact alarms — the permission is
  effectively unused and a candidate for removal.

See [limitations](../limitations.md) for the user-facing consequences.
