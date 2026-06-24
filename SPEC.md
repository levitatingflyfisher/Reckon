# Reckon — Engineering Spec (reconstructed from PRD + as-built code)

**Date:** 2026-06-11
**Status of record:** Phase 1 implemented and green (analyze clean, 64/64 tests pass).
**Source of truth:** This document reconciles `reckonPRD.md` (the product vision) with
what is *actually built* in `lib/`. Where the two diverge, the code wins and the
divergence is called out. Intended as the working charter for ongoing development
and, if ever needed, a clean-room rebuild reference.

---

## 1. What Reckon is (today)

A **local-first personal decision journal** for Android (PWA/iOS later). It runs the
"inner crowd" protocol over a real decision: structured intake → blinded time-series
re-polls → a reveal of your own drift → a delayed resolution check-in that feeds a
calibration record. The killer feature is your own track record confronting you.

**Today it runs entirely on-device, no server, no account** (Ghost tier). The on-device
LLM (Gemma 3 1B IT via `flutter_gemma`) powers intake, outside-view synthesis, re-poll
sentiment detection, and the reveal observation.

---

## 2. Architecture as-built

**Stack:** Flutter 3.29.x · Dart 3.4+ · Riverpod (plain providers, *not* codegen) ·
go_router · Drift (SQLite) · flutter_secure_storage · flutter_gemma ·
flutter_local_notifications + timezone · fl_chart · share_plus.

**Layering (clean architecture, per feature):**

```
lib/
  app/                      app root, router, shell
  core/
    auth/                   three-tier auth model; ghost impl is live
    database/               Drift DB, tables, converters, reference-class seeder
    llm/                    LlmService + 3 backends (private live; connected/byok stubbed)
    notifications/          local notifications, repoll scheduling, stable ids
    theme/                  ThemePreference (tri-theme), persisted
  features/<feature>/
    domain/                 entities, repository interfaces, usecases (pure, tested)
    data/                   repository impls over Drift/secure-storage, providers
    presentation/           screens/widgets
  shared/widgets/           OH* design-system adapters (OHCard, OHButton, …)
packages/
  openhearth_design/        in-repo design system (tri-theme, palette, type ramp)
```

**Design system:** `packages/openhearth_design` is an **in-repo reconstruction** of the
shared `../ohStyle/openhearth_design` package. The original sibling package was a
path dependency outside the repo, so a fresh clone / CI / any second machine could not
`pub get` or build. It is reconstructed faithfully from the documented grammar (hearth
terracotta on linen; sage night accent; Lora serif for decision text, Nunito sans for
chrome) and exposes the identical public API (`OhTheme`, `OhColors`, `OhRadii`,
`OhTypography`) so it can be swapped back for the canonical package later with no
consumer changes. **If the canonical ohStyle becomes available in-tree, reconcile the
tokens.**

---

## 3. Feature inventory (as-built)

| Area | Status | Key files |
|------|--------|-----------|
| Onboarding (auth tier → model → first case) | Built | `features/onboarding/presentation/*` |
| Intake (conversational, on-device LLM) | Built | `features/case/presentation/intake_screen.dart`, `core/llm/private_mode_impl.dart` |
| Case create / summary / detail | Built | `features/case/{domain,data,presentation}` |
| Blinded re-poll | Built | `features/case/presentation/repoll_screen.dart` |
| Reveal (time-series chart + observation) | Built | `features/reveal/*` |
| Resolution date + check-in | Built | `features/reveal/presentation/resolution_*` |
| Outside view + stratification profile | Built | `features/outside_view/*` |
| Record: Clarity Score, calibration, insight cards | Built | `features/record/*` |
| Technique glossary (8 entries) | Built | `features/glossary/*`, `assets/glossary.json` |
| Model prediction scorecard | Built | `features/predictions/*` |
| Export (markdown / JSON) | Built | `features/export/*` |
| Notifications (repoll + resolution, deadline-aware) | Built | `core/notifications/*` |
| Reference-class DB (seeded from asset) | Built (15 entries) | `assets/reference_classes.json`, `core/database/seed/*` |
| Connected mode (cloud LLM) | **Stub** (Phase 2) | `core/llm/connected_mode_impl.dart` |
| BYOK mode | **Stub** (Phase 2) | `core/llm/byok_mode_impl.dart` |
| Community forecasting + seed bot | **Not built** (Phase 3) | — |
| ReckonParty (group coordination) | **Not built** (Phase 3) | see `docs/RECKONPARTY_PLAN.md` |

---

## 4. Data model as-built (Drift)

Tables under `core/database/tables/`: `cases`, `polls`, `resolutions`, `outside_views`,
`community_forecasts`, `model_predictions`, `reference_classes`, `user_profile`.
Calibration / Clarity Score are **computed on query** from closed cases (not stored),
per the PRD's "keep the data model honest" principle. Blinded-poll integrity is enforced
at the data layer (prior polls are not surfaced during a re-poll).

> **Divergence from PRD:** PRD §6 describes a Supabase/Postgres schema with RLS. The
> April-2026 addendum drops Supabase; the as-built persistence is **local Drift only**.
> `community_forecasts` and `model_predictions` exist locally but the sync/community
> server layer does not.

---

## 5. LLM architecture as-built

`LlmService` interface with three backends:

- **Private (live):** `PrivateModeImpl` over `flutter_gemma`, **Gemma 3 1B IT**. Chosen
  over the PRD's Phi-3 Mini after the `tool/spike/mediapipe_check.md` evaluation (plugin
  maintenance + supported-model matrix). Handles intake (streaming), outside-view
  synthesis, re-poll sentiment mismatch, reveal observation. Community seed is a Phase-3
  stub. Model weights (~hundreds of MB) download on first use.
- **Connected (stub):** intended to proxy the Anthropic API through a **Cloudflare
  Worker** (per addendum; *not* Supabase Edge Functions). Every method throws
  `UnimplementedError('… Phase 2')`.
- **BYOK (stub):** user's own Anthropic key in secure storage. Phase 2.

The five system prompts (intake interviewer, outside-view synthesizer, re-poll sentiment
detector, reveal observation, community seed bot) live in `core/llm/llm_prompts.dart`.

---

## 6. Roadmap / phases

- **Phase 1 — Local-first personal Reckon loop. ✅ Complete & green.**
  Ghost tier, on-device LLM, full intake→repoll→reveal→resolution loop, record/clarity,
  glossary, outside view, export, notifications.
- **Phase 2 — Cloud intelligence.** Implement Connected mode (Cloudflare Worker LLM
  proxy holding the API key) + BYOK. Free/paid split becomes real.
- **Phase 3 — Community & ReckonParty.** Community forecasting + AI seed bots, and the
  ReckonParty group-coordination mode with a no-account web-link flow (top-of-funnel).
  Requires the first real server (encrypted blob relay + realtime). See
  `docs/RECKONPARTY_PLAN.md`.

### Launch-criteria gaps (PRD §14)

| # | Criterion | Status |
|---|-----------|--------|
| 1 | Intake <2 min, voice+text, Android+PWA | Built; verify voice input + PWA target |
| 2 | Blinded re-poll <30 s, warm copy, deadline-aware | ✅ |
| 3 | Reveal "oh" moment, 10 real-user validation | Built; user validation outstanding |
| 4 | Community forecasting + seed bots | ❌ Phase 3 |
| 5 | Web link flow (party + invites), no account | ❌ Phase 3 |
| 6 | Reference class top-20 categories | ⚠️ 15 entries today |
| 7 | Glossary 8 entries + interactive demos | ✅ entries; confirm demos |
| 8 | Clarity Score screen, honest about sparseness | ✅ |

---

## 7. Build & toolchain

- `flutter pub get && flutter analyze && flutter test` — all green as of this date.
- Drift codegen: `dart run build_runner build --delete-conflicting-outputs`
  (`app_database.g.dart` is committed).
- **CI:** `.github/workflows/ci.yml` runs analyze + test + a debug-APK smoke build on
  every push/PR. `.github/workflows/release.yml` builds split APKs + AAB on a `v*.*.*`
  tag (no longer depends on an external ohStyle checkout).
- minSdk 24 (flutter_gemma/MediaPipe). Release build is currently **debug-signed** — a
  real signing config is required before Play distribution.

---

## 8. Known risks (see `docs/CODE_REVIEW.md` for the full audit)

- Release build is debug-signed (TODO in `android/app/build.gradle.kts`).
- `SCHEDULE_EXACT_ALARM` is declared but scheduling uses `inexactAllowWhileIdle` — the
  permission is unused and should be dropped (Play flags it for non-clock apps).
- R8/minify is off; enabling it later needs MediaPipe keep-rules in `proguard-rules.pro`.
- On-device model download is the first hard dependency a new user hits — intake/reveal
  fail until it completes; verify the UX of that path.
- Reference-class DB is 15/20 categories vs the launch target.
