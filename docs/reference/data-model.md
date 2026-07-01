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
| `model_predictions` | Logged model outputs, attributed by `modelVersion` (`<backend-model>#<forecasterId>` for duel rows), with a per-row `score` written once at resolution for `duelForecast` rows (the one sanctioned persisted score — yellow paper R4) |
| `forecasters` | The forecaster roster — id, display name, kind (`persona` / `localModel` / `anthropicByok` / `openaiCompat` / `bountyBot`), non-secret `configJson`, enabled flag. Secrets (the BYOK key) live in secure storage, never here |
| `groups`, `group_members` | Persistent ReckonParty circles and their rosters (member id = the ghost `account_id`; unique per `(groupId, memberId)`) |
| `community_forecasts` | An id-only stub left from Phase-3 planning — **no forecast schema exists here**; the real multi-forecaster substrate is `forecasters` + `model_predictions` |
| `parties`, `party_ballots` | ReckonParty local state. `parties` carries a nullable `groupId` (FK to `groups`) and a `considered` flag; `party_ballots` a nullable `memberId` for attributed group votes |

`reference_classes` is seeded from `assets/reference_classes.json` by
`core/database/seed/reference_class_seeder.dart` (~15 entries today).

**Schema version 5** (one migration) added `forecasters`, `groups`, and `group_members`,
plus `parties.group_id` / `parties.considered` and `party_ballots.member_id`. There is no
data seeding in the migration — the two default persona forecasters are created lazily on
first roster read.

## Computed on query — never stored

The record metrics are **derived from closed cases each time they're shown**, never
persisted as ground-truth ([ADR-0006](../adr/0006-honest-record-blinded-repolls.md),
[ADR-0007](../adr/0007-forecaster-duel-alignment-scoring.md)). They live as usecases in
`lib/features/record/domain/usecases/` and `lib/features/predictions/domain/usecases/`:

| Metric | Usecase | Shape |
|---|---|---|
| **Clarity Score** | `ComputeClarityScore` | `value` 0–100 = `round((avgSatisfaction + 2) / 4 × 100)` over a `-2…+2` scale, plus `caseCount` |
| **Calibration report** | `ComputeCalibrationReport` | per-category mean satisfaction, mean satisfaction bucketed by decision-time confidence, and mean lean drift (max−min lean per case) |
| **Personal base rates** | `ComputePersonalBaseRates` | your own rates across your history |
| **Insight cards** | `ComputeInsightCards` | surfaced patterns ("most satisfied with… least with…") |
| **Deference map** | `ComputeForecasterWeights` | per-forecaster mean alignment score, sample count, per-category split, and a normalised **earned weight** (n ≥ 5 to carry weight); the **user's own entry is scored on read** with the same formula, never persisted (yellow paper R5) |
| **Update quality** | `ComputeUpdateQuality` | did your re-polls move *toward* the option you ended up glad about — `clamp((pChosen(last) − pChosen(first)) × satisfaction, −1, 1)`, mean + sample count (yellow paper R6) |

There is no user-record "score" column to inflate: change the inputs (close more cases)
and the numbers move deterministically. The single persisted score in the schema is
`model_predictions.score` — a per-*forecast* alignment score written once at resolution
(yellow paper R4), an input to the computed-on-read aggregates above, never a user metric.

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
`PersonalBaseRates`, `InsightCard`, `UpdateQuality`, and `ClosedCaseRecord` (the closed
case + its polls + chosen option + satisfaction score) that feeds the computations above.

**Forecasters** (`features/forecasters/domain/entities/`): `Forecaster` (id, display name,
`ForecasterKind`, non-secret config map, enabled) — anyone who may duel the user and earn a
track record. **Predictions** (`features/predictions/domain/entities/`): `ModelPrediction`
(kind `outsideView | revealObservation | duelForecast`; duel payloads carry
`{lean, rationale, forecasterId, forecasterName}`) and `ForecasterWeights` (the deference
map — entries with mean, n, per-category split, nullable earned weight).

**Groups** (`features/party/domain/entities/`): `Group`, `GroupMember`, and the `Party`
additions (`groupId?`, `considered`, `resultsSealed = considered && !closed`). `Ballot`
gains a nullable `memberId`.

**Bounty** (`features/bounty/domain/`): wire shapes live in `bounty_codec.dart` only —
nothing outside `features/bounty` touches raw reckonBounty JSON. Imported responses are
stored as ordinary `duelForecast` predictions attributed to a `bounty:<bot.name>`
forecaster; there is no separate bounty table.

## Note on the historical PRD schema

An early PRD described a Supabase/Postgres schema with row-level security and a server.
That was dropped: persistence is **local Drift only** ([ADR-0003](../adr/0003-local-first-ghost-tier.md)).
The multi-forecaster layer that PRD imagined as a community server shipped instead as the
local duel + the file-transported bounty interface ([ADR-0009](../adr/0009-bounty-client-paste-import.md));
no community server exists. Where the code and any older design doc disagree, the code is
the truth.
