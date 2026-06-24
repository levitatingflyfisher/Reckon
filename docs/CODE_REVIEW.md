# Reckon — Runtime / Correctness Code Review

**Date:** 2026-06-11
**Reviewer:** Automated deep review (Claude)
**Scope:** On-device runtime bugs — Riverpod lifecycle, navigation, persistence/state-invalidation, notifications, on-device LLM, and the intake → re-poll → reveal → resolution flow.
**Baseline:** `flutter analyze` clean; all 64 tests pass. This report deliberately ignores lint/style and targets behavior that only shows up on a device.

---

## Summary of findings

| # | Severity | Area | One-line |
|---|----------|------|----------|
| 1 | **High** | Notifications | Repoll/resolution notifications have no tap handler and carry no caseId — tapping a reminder never opens the relevant case. |
| 2 | **High** | State invalidation | Resolution-date confirm sets status `resolving` but never invalidates `caseByIdProvider`; returning to Case Detail shows stale `decided` state. |
| 3 | **High** | LLM model gating | `isDownloaded()` deletes any model file smaller than 80% of a hard-coded `approximateSizeBytes`; if the declared size is wrong the real model is silently nuked and the app loops "download a model first". |
| 4 | **Medium** | Async/lifecycle | Intake stream callbacks (`onDone`/`onError`) and `_checkForCompletion`'s `context.go` run with no `mounted` guard — popping the screen mid-stream throws / red-screens. |
| 5 | **Medium** | Persistence | Outside-view generation runs on every screen entry and `save()` is an `insert` with no uniqueness on `caseId` — duplicate rows + duplicate prediction logs accumulate per case. |
| 6 | **Medium** | State invalidation | Record tab providers (clarity / calibration / insights / closed) are non-autodispose `FutureProvider`s never invalidated after a case closes — stale Record screen until app restart. |
| 7 | **Medium** | State invalidation | Resolution check-in closes the case but does not invalidate `caseByIdProvider`; the case (still cached) shows a stale status if revisited. |
| 8 | **Low** | LLM | `gemma3_1b.approximateSizeBytes` (780 MB) disagrees with onboarding/intake copy ("~500MB") and is the basis for the 80%-corruption gate in #3. |
| 9 | **Low** | Reveal flow | `decided`-state Case Detail re-enters `/reveal`, which re-runs the LLM reveal + logs another prediction every time. |
| 10 | **Low** | Notifications | `requestPermissions()` returning false silently drops *all* reminders for the case with no user feedback; Android 13+ first-run denial = no reminders, ever, silently. |

---

## Detailed findings

### 1. (High) Notifications are fire-and-forget — no tap routing, no caseId payload
**Files:** `lib/core/notifications/local_notification_service.dart:14-21, 40-94`

`init()` calls `_plugin.initialize(settings)` with **no** `onDidReceiveNotificationResponse` callback, and nothing in the app calls `getNotificationAppLaunchDetails()`. Both schedulers set a static `payload: 'repoll'` / `'resolution'` that contains no case identifier.

**Runtime effect:** A repoll/resolution reminder fires, the user taps it, the app opens to `/` (Home). It does **not** open the re-poll screen for that case. The entire value proposition of the reminders ("Time to check in") is broken on device — and even a future fix can't deep-link because the payload doesn't carry `caseId`.

**Repro:** Create a case with a near deadline, let a reminder fire, tap it. You land on Home, not on `/repoll/<caseId>`.

**Fix:** Put the caseId (and kind) in the payload, e.g. `payload: 'repoll:$caseId'`; pass `onDidReceiveNotificationResponse:` to `initialize()` and route via the GoRouter to `/repoll/$caseId` (or `/resolution-checkin/$caseId`); on cold start, check `getNotificationAppLaunchDetails()` and set the router's initial location accordingly.

---

### 2. (High) Resolution-date confirm leaves Case Detail showing a stale status
**Files:** `lib/features/reveal/presentation/resolution_date_screen.dart:35-63`, `lib/features/reveal/data/resolution_repository_impl.dart:47-49`, `lib/features/case/data/case_providers.dart:34-37`

`_confirm()` calls `repo.create(...)` which flips the case status to `resolving` in the DB, then `context.go('/case/${widget.caseId}')`. But it never invalidates `caseByIdProvider(caseId)`. That provider is a plain (non-autodispose) `FutureProvider.family` and was already cached as `decided` when the reveal screen read it.

**Runtime effect:** After scheduling the resolution check-in, the user is sent back to Case Detail, which still renders the `decided` branch — i.e. it shows the **"Set resolution date"** button again instead of **"Resolution check-in"**. The case looks like the resolution date was never set. (The Home stream is unaffected because it's a `StreamProvider`; only the FutureProvider-backed detail screen is stale.)

**Repro:** Decide a case → reveal → set resolution date → land on Case Detail → button still says "Set resolution date".

**Fix:** In `_confirm()` after `repo.create(...)`, add `ref.invalidate(caseByIdProvider(widget.caseId));` (and ideally `pollsForCaseProvider`). Same pattern that `reveal_screen._commitAndProceed` already uses correctly.

---

### 3. (High) Over-aggressive "corruption" gate can delete a perfectly good model and soft-brick the LLM
**Files:** `lib/core/llm/model_download_service.dart:39-49`, `lib/core/llm/model_spec.dart:48-57`

`isDownloaded()` treats any on-disk file smaller than `approximateSizeBytes * 0.8` as a truncated download and **deletes it**. `approximateSizeBytes` is a hand-entered constant (gemma3_1b = 780,000,000). int4/int8 `.task` files routinely differ from a guessed size, and the comment in `model_spec.dart` even says "used for progress UI, not validation" — yet here it *is* used for validation.

**Runtime effect:** If the real Gemma file is < 624 MB (the actual `gemma3-1b-it-int4.task` artifacts are commonly ~530 MB), then:
1. Download completes successfully.
2. `_ModelCard`/intake calls `isDownloaded()` → size < floor → **file deleted** → returns `false`.
3. UI flips back to "Download a model first." Intake is permanently gated. The user re-downloads, and it's deleted again — an infinite loop with a 500–780 MB download each time.

This is one of the strongest candidates for the user's "works locally but broken on device" report, because the local file you tested with may have matched the constant, while a fresh device download of the published artifact may not.

**Repro:** Point `downloadUrl` at the real ~530 MB int4 artifact while `approximateSizeBytes` stays 780 MB; download then re-enter Settings/Intake.

**Fix:** Don't validate by guessed size. Either (a) drop the size check entirely and rely on `dio`'s `deleteOnError` + a successful-completion marker file, or (b) record the *actual* `Content-Length`/final byte count on a successful download and compare against that, or (c) lower the floor drastically (e.g. a few MB) so it only catches truly empty/aborted files.

---

### 4. (Medium) Intake stream callbacks and JSON-complete navigation lack `mounted` guards
**File:** `lib/features/case/presentation/intake_screen.dart:96-115, 131-159`

Inside `_sendUserTurn`, the `listen` `onDone:` (lines 97-105) and `onError:` (106-114) call `setState(...)` with no `if (mounted)` check. `_checkForCompletion` calls `context.go('/case-summary', ...)` (line 140) with no `mounted` check either. The streaming response from Gemma can take several seconds; the user can hit the system back button while it's still generating.

**Runtime effect:** If the screen is disposed before the stream finishes, `setState`/`context.go` on a defunct `State` throws `setState() called after dispose()` / "Looking up a deactivated widget's ancestor" — surfacing as a red screen or a logged exception. The `_sub` *is* cancelled in `dispose()`, which helps, but `onDone` can still fire from an in-flight microtask, and `_checkForCompletion` runs synchronously from `onDone`.

**Repro:** Start intake, send a turn, immediately tap back while the assistant is streaming.

**Fix:** Guard every post-await `setState`/navigation with `if (!mounted) return;`. The `catch` block at 116 already does this — apply the same to `onDone`/`onError`/`_checkForCompletion`.

---

### 5. (Medium) Outside view regenerates and duplicates on every screen visit
**Files:** `lib/features/outside_view/presentation/outside_view_screen.dart:22-46`, `lib/features/outside_view/domain/usecases/get_outside_view.dart:40-53`, `lib/features/outside_view/data/outside_view_repository_impl.dart:14-28`, `lib/core/database/tables/outside_views_table.dart:18-19`

`_generate()` fires from `initState` on **every** entry to `/outside-view/:caseId`. `GetOutsideView.call` always does `_repo.save(view)` (an `insert` with a fresh UUID) and `_predictions.log(...)`. The table's primary key is `id` only — there is no unique constraint on `caseId`, and the display reads with `limit(1)`.

**Runtime effect:** Each visit runs a fresh (slow, ~seconds) on-device LLM synthesis, inserts another `OutsideView` row, and logs another `outsideView` prediction. Case Detail's "Tap to generate outside view" routes here too. Over a case's life this silently multiplies rows and pollutes the Model Scorecard's `totalPredictions` / mean with redundant entries. Wasted battery/CPU on device every time.

**Repro:** Open a case's outside view, back out, open it again — a second row and prediction are created; the scorecard count climbs.

**Fix:** Before generating, check `getForCase(caseId)` and skip if present (or pass a "force regenerate" flag). Make `save()` an upsert keyed on `caseId` (add a unique index on `caseId`). Only log a prediction when a new view is actually produced.

---

### 6. (Medium) Record tab shows stale analytics after a case closes
**File:** `lib/features/record/data/record_providers.dart:40-59`

`clarityScoreProvider`, `insightCardsProvider`, `closedCasesProvider`, and `calibrationReportProvider` are plain `FutureProvider`s (not autodispose, not streams). They're computed on first navigation to Record and then cached. Closing a case (`recordSatisfaction` → status `closed`, score written) invalidates none of them.

**Runtime effect:** User completes a resolution check-in (which is supposed to feed the Record screen), navigates to Record, and sees "No closed cases yet." / unchanged clarity score until the app is restarted. Because the bottom-nav uses `context.go` within a `ShellRoute`, the Record screen is rebuilt but reads the same cached provider values.

**Fix:** Either convert these to `StreamProvider`s backed by `watch` queries (best — they auto-update like Home does), or invalidate them in `recordSatisfaction`'s caller after closing a case. Note: there's no `watchClosed()`/`watchScoredResolutions()` today; the repositories only expose `Future` getters, so adding stream variants is the durable fix.

---

### 7. (Medium) Resolution check-in closes the case without invalidating its detail provider
**File:** `lib/features/reveal/presentation/resolution_checkin_screen.dart:37-46`, `lib/features/reveal/data/resolution_repository_impl.dart:66-93`

Same class of bug as #2: `_save()` calls `recordSatisfaction` (status → `closed`) then `context.go('/')`. It never invalidates `caseByIdProvider`. Home is a stream so the closed case correctly disappears, but if the user reaches the case again via Record → History (`/case/:id`), `caseByIdProvider` is still cached at `resolving` and shows the "Resolution check-in" button for an already-closed case.

**Fix:** `ref.invalidate(caseByIdProvider(widget.caseId));` before navigating.

---

### 8. (Low) Declared model size disagrees with UI copy and drives the deletion gate
**Files:** `lib/core/llm/model_spec.dart:47-57`, `lib/features/case/presentation/intake_screen.dart:210-211` (and the task's "~500MB" framing)

`gemma3_1b.approximateSizeBytes = 780000000` and the doc comment says "~780 MB", while user-facing onboarding copy elsewhere implies ~500 MB. Beyond cosmetics, this constant is the denominator of the 80% gate in finding #3, so getting it wrong has teeth. Reconcile the number with the actual published artifact and update the copy.

---

### 9. (Low) `decided`-state Case Detail re-runs the reveal LLM call each visit
**File:** `lib/features/case/presentation/case_detail_screen.dart:132-137`, `lib/features/reveal/presentation/reveal_screen.dart:37-65, 69-75`

When a case is `decided` (reveal committed, resolution date not yet set), Case Detail's button "Set resolution date" pushes `/reveal/:caseId` again. `RevealScreen._prepare` unconditionally re-invokes `generateRevealObservation` (slow on device) and `GenerateReveal` logs another `revealObservation` prediction. `markDecided` is idempotent (guards on `status == open`), so status is safe, but you pay for and log a redundant LLM reveal every time. Consider routing `decided` cases straight to `/resolution-date/:caseId` (you already have the chosen option persisted in the reveal payload), or caching the observation.

---

### 10. (Low) Notification-permission denial silently kills all reminders
**File:** `lib/features/case/presentation/case_summary_screen.dart:116-137`

`_confirm()` only schedules reminders `if (granted)`. On Android 13+, the runtime `POST_NOTIFICATIONS` prompt can be denied (or auto-denied if previously dismissed). When that happens, no reminder is ever scheduled and the user gets zero feedback — the case is created and the app proceeds as if reminders were set. For a journal whose loop depends on nudges, a one-time "reminders are off; enable in system settings" hint would prevent silent dead-ends.

---

## Things verified as correct (so they're not re-litigated)

- **Onboarding gate.** Router reads `onboardingCompleteProvider` once for `initialLocation`; forward progress is driven by explicit `context.go` (`auth → model → first-case → /`), so completion *does* navigate. `_Bootstrap` blocks the app until the flag has a concrete value, so the read-once pattern is safe. **No bug.**
- **Blinded-poll integrity.** The re-poll screen (`repoll_screen.dart`) never reads or renders prior polls; it only writes a new one and shows mismatch detection. Polls stay `revealed=false` until `markDecided` flips them atomically in a transaction (`case_repository_impl.dart:72-84`). Re-poll cannot leak earlier answers. **No bug.**
- **Reveal empty/one-poll states.** `polls.isEmpty` is handled (explicit message); the chart only renders for ≥1 poll; `_selectedPoll` is bounds-checked (`_selectedPoll! < polls.length`); fl_chart `spotIndex` maps 1:1 to the poll list since the single bar's spots are built in order. A 1-poll chart renders a single dot without crashing. **No bug.**
- **Notification timezone math.** `_absolute(when) = TZDateTime.from(when.toUtc(), tz.UTC)` with `UILocalNotificationDateInterpretation.absoluteTime` schedules the correct absolute instant independent of `tz.local`. The UTC routing is deliberate and correct. **No bug.**
- **Notification IDs.** `notificationIdFor` masks the string hash to 30 bits and adds the slot; repoll slots are 0–29 and `resolutionSlot=10000`, all within signed-32-bit and non-colliding for a single case. `cancelCaseNotifications` uses the same id-space. **No bug** (cross-case hash collisions are acknowledged in-code and out of scope).
- **Reference-class seeder idempotency.** `hasBeenSeeded()` short-circuits, and inserts use `InsertMode.insertOrIgnore`, so re-seeding is safe. **No bug.**
- **DB migration.** `schemaVersion=2`, `onUpgrade` creates `modelPredictions` for `from<2`; `onCreate` seeds the singleton `UserProfile` row (id=1), which `getUserProfile()` then `getSingle()`s. Consistent. **No bug.**
- **Model download stream.** `download()` correctly bridges dio into a `StreamController`, deletes partials on error (`deleteOnError`), and surfaces the missing-token `StateError`. **No bug** (aside from the size-gate in #3 that consumes it).
- **Design package.** `packages/openhearth_design` exports cohere with `theme_preference.dart`; `'Lora'`/`'Nunito'` are declared in `pubspec.yaml` with matching weight/style mappings and the `.ttf` files exist under `assets/fonts/`. The hard-coded `fontFamily: 'Lora'` in `reveal_screen.dart` resolves. **Sane.**

---

## Device-bug suspects — ranked

The user reports "builds locally but lots of little bugs on device." Ranked by likelihood of being the actual culprit(s):

1. **#3 — model file gets deleted right after download (size gate).** Strongest candidate for "the model never seems to install on my phone." A real published artifact smaller than 80% of the guessed 780 MB is deleted on the next `isDownloaded()` call, looping the user back to "download a model first." Local testing with a matching-size file would hide this entirely.
2. **#1 — tapping reminders does nothing useful.** Highly visible on device, invisible in tests (no notification harness). "I tap the reminder and it just opens the home screen."
3. **#2 / #7 — stale case status after setting a resolution date or checking in.** Reproducible by hand on device, masked in unit tests (which exercise repositories, not provider caching). Manifests as "I set the date but it still asks me to set the date."
4. **#4 — red screen if you back out of intake while Gemma is still streaming.** Easy to hit on a slower device where generation takes seconds; nearly impossible to trip in a fast local/emulator smoke test.
5. **#6 — Record tab looks empty/stale until restart.** "My closed case isn't showing up in Record" — classic non-autodispose FutureProvider caching, only obvious after a full close→navigate cycle on a real session.
6. **#5 / #9 — silent duplication + redundant slow LLM calls.** Not a visible crash, but contributes to "the app feels slow/laggy on device" and a creeping, wrong Model Scorecard.

**Recommended fix order:** #3 first (it can hard-block the whole on-device LLM), then #1 (reminders), then the invalidation trio #2/#6/#7, then #4 (crash hardening), then #5/#9 (correctness/efficiency).
