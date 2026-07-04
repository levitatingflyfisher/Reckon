# ADR-0005 — Flutter Clean Architecture with Riverpod and Drift

**Status:** Accepted (the whole codebase follows it).

## Context

Reckon has real domain logic that must be correct and testable independently of the
UI: voting tallies, calibration statistics, the Clarity Score, blinded-poll rules,
reference-class stratification. It also has several backing stores (SQLite, secure
storage) and swappable LLM backends. A UI-centric layout would entangle that logic
with widgets and make it hard to test or re-back.

## Decision

Adopt **Clean Architecture, feature-first**. Each feature under `lib/features/<name>/`
carries three layers:

- **`domain/`** — pure Dart: entities, abstract repository interfaces, and usecases.
  No Flutter, no Drift, no `flutter_gemma` imports. This is where the maths lives and
  where it's unit-tested.
- **`data/`** — repository implementations over Drift DAOs / secure storage, plus the
  Riverpod providers that expose them.
- **`presentation/`** — screens, widgets, and Riverpod controllers.

Cross-cutting infrastructure lives in `lib/core/` (`database`, `llm`, `auth`,
`notifications`, `theme`). State is **Riverpod**; storage is **Drift over SQLite**
(`app_database.g.dart` is committed; regenerate with `build_runner`); routing is
`go_router`. The design system is `packages/openhearth_design`, an **in-repo
reconstruction** of the shared OpenHearth style package so the app builds standalone
(fresh clone, CI) without a sibling checkout.

## Consequences

- **Positive:** Domain logic is tested in isolation with plain Dart; repository tests
  use `NativeDatabase.memory()` (no mocking needed).
- **Positive:** Swapping a backing store or an LLM backend is a `data/`-layer change;
  screens don't move.
- **Cost:** More files and ceremony per feature (three folders, an interface + an
  impl) than a flat layout. Worth it for a domain this logic-heavy.
- **Note:** Providers are hand-written where clarity wins and code-generated
  (`riverpod_generator`) elsewhere; follow the surrounding feature's choice rather than
  converting one wholesale. The in-repo `openhearth_design` should be reconciled with
  the canonical package if that ever lands in-tree.
