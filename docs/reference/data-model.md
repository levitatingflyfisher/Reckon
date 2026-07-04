# Reference — Data model

What Reckon persists, what it computes on the fly, and the shape of the core domain
entities. Storage is **Drift over SQLite**, entirely on-device. The generated
`app_database.g.dart` is committed; regenerate after schema changes with
`dart run build_runner build --delete-conflicting-outputs`. Table definitions live in
`lib/core/database/tables/` — treat those files as the exact column-level truth; this
page describes the shapes and the rules.

## Stored tables

| Table (`…_table.dart`) | Holds |
|---|---|
| `cases` | One row per decision — question, two options, stated criteria, stakes, regret horizon, category, lifecycle status |
| `polls` | Each blinded re-poll for a case — lean (0–100), confidence, optional rationale, poll number, `revealed` flag |
| `resolutions` | The delayed check-in that closes a case (satisfaction, when it resolved) |
| `outside_views` | Persisted outside-view syntheses for a case (base-rate summary, reference class used, uncertainty, stratification) |
| `reference_classes` | The seeded reference-class database (category/subcategory, base-rate description, uncertainty level, stratification variables) |
| `user_profile` | The light stratification profile (e.g. SES bracket, relationship status) used to tailor the outside view |
| `model_predictions` | Logged model outputs, attributed by `modelVersion`, for the prediction scorecard |
| `community_forecasts` | Reserved for the Phase-3 community layer (persisted, not surfaced) |
| `parties`, `party_ballots` | ReckonParty local state (a party definition; ballots) |

`reference_classes` is seeded from `assets/reference_classes.json` by
`core/database/seed/reference_class_seeder.dart` (~15 entries today).

## Computed on query — never stored

The record metrics are **derived from closed cases each time they're shown**, never
persisted as ground-truth ([ADR-0006](../adr/0006-honest-record-blinded-repolls.md)).
They live as usecases in `lib/features/record/domain/usecases/`:

| Metric | Usecase | Shape |
|---|---|---|
| **Clarity Score** | `ComputeClarityScore` | `value` 0–100 = `round((avgSatisfaction + 2) / 4 × 100)` over a `-2…+2` scale, plus `caseCount` |
| **Calibration report** | `ComputeCalibrationReport` | per-category mean satisfaction, mean satisfaction bucketed by decision-time confidence, and mean lean drift (max−min lean per case) |
| **Personal base rates** | `ComputePersonalBaseRates` | your own rates across your history |
| **Insight cards** | `ComputeInsightCards` | surfaced patterns ("most satisfied with… least with…") |

There is no "score" column to inflate: change the inputs (close more cases) and the
numbers move deterministically.

## Core domain entities

Pure Dart, in each feature's `domain/entities/`.

**`Case`** (`features/case/domain/entities/case.dart`)
- `id`, `createdAt`, `deadline?`
- `question`, `optionA`, `optionB`
- `statedCriteria: List<Criterion>`
- `stakes`: `low | medium | high`
- `regretHorizon`: `weeks | months | years`
- `status`: `open | decided | resolving | closed`
- `category?`, `communityVisible` (reserved for Phase 3)

**`Poll`** (`features/case/domain/entities/poll.dart`)
- `id`, `caseId`, `createdAt`, `pollNumber`
- `lean`: `int` 0–100 (all-A … all-B)
- `confidence`: `low | medium | high`
- `rationale?`
- `revealed`: `bool` — priors stay hidden until the reveal (blinding invariant)

**Outside view** (`features/outside_view/domain/`): `ReferenceClassEntry` (category,
subcategory, base-rate description, uncertainty level, stratification variables),
`UserProfile` (SES bracket, religiosity, relationship status — all optional), and the
resulting `OutsideView`.

**Reveal** (`features/reveal/domain/`): `CaseTimeSeries` (the ordered polls + criteria +
deadline + final choice) and `RevealObservation` (the model's one-line note).

**Record** (`features/record/domain/entities/`): `ClarityScore`, `CalibrationReport`
(`CategoryStat`, `ConfidenceBucket`, `meanLeanDrift`, `sampleCount`),
`PersonalBaseRates`, `InsightCard`, and `ClosedCaseRecord` (the closed case + its polls
+ satisfaction score) that feeds the computations above.

## Note on the historical PRD schema

An early PRD described a Supabase/Postgres schema with row-level security and a server.
That was dropped: persistence is **local Drift only** ([ADR-0003](../adr/0003-local-first-ghost-tier.md)).
`community_forecasts` and `model_predictions` exist locally, but no sync/community server
does. Where the code and any older design doc disagree, the code is the truth.
