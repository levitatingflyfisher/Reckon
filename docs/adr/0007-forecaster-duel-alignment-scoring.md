# ADR-0007 — The forecaster duel: sealed parallel forecasts, per-prediction alignment scoring

**Status:** Accepted (schema v5; enforced in `features/forecasters/`, `features/predictions/`,
and the record path).

## Context

Two pressures met:

1. **The vision pre-authorised it.** VISION's Mid horizon — "show the model its own track
   record, the same way Reckon shows the user theirs" — and the `ModelPredictions` table
   (built as the substrate for multi-model attribution) both pointed at forecasters that
   *earn* standing rather than assert it. `LlmService.generateCommunitySeed` was the
   designed seam.
2. **Two honesty hazards stood in the way.** (a) A bot stating a lean on your *open* case
   recreates exactly the anchoring problem blinded re-polls (R1) exist to kill — and grazes
   the "model never decides" commitment. (b) The legacy `scoreForCase` wrote one identical
   blanket score to every prediction on a case; reused for a duel, all duelists tie forever
   and the track record is noise. Worse, *observation* rows (outside views, reveal
   observations) were being scored as if they were forecasts.

## Decision

- **A forecaster registry** (`Forecasters` table; kinds `persona | localModel |
  anthropicByok | openaiCompat | bountyBot`). The roster is the user's: rename, disable,
  delete. Two persona forecasters are created lazily on first read — never seeded in a
  migration. Secrets stay in secure storage, never in a forecaster's config.
- **The duel is sealed (R1 extended).** `RunDuel` logs each enabled, runnable forecaster's
  lean exactly once per case (idempotent on `(case, forecasterId)`), and the open-case UI
  shows only a count — "N forecasts sealed". Lean and rationale render **only at the
  reveal**, after the user's own record is complete. Sentinel outputs (empty rationale) are
  counted failed and **never logged**.
- **Per-prediction alignment scoring (R4)** replaces blanket scoring for forecast rows:
  `score = (2·p_chosen − 1) · (satisfaction / 2)`, where `p_chosen` reads the forecast's
  lean toward the chosen option. The degenerate case (a fully confident correct forecast)
  reduces to `satisfaction / 2` — the old rule — so historical scores stay interpretable.
- **Observation kinds are no longer scored.** `outsideView` and `revealObservation` rows
  record what the model *said*, not a prediction of the outcome; scoring them polluted the
  record. This is a deliberate behaviour change. `scoreForCase` is retained as an uncalled,
  doc-commented bulk utility; the resolution flow calls `scoreDuelForecasts` only.
- **Deference is computed on read (R5).** `ComputeForecasterWeights` derives earned weights
  from scored duel rows and closed cases at query time; the *user's* entry is scored on
  read with the same formula (R2 — no user metric is ever persisted). Entries need n ≥ 5 to
  carry weight; below that they are listed but weightless. The one persisted number is the
  per-forecast score itself — a log entry, not a metric.
- **Per-forecaster service resolution, global wiring untouched.** `llmServiceForForecaster`
  maps persona/localModel onto the resident on-device service (persona passed per call —
  one `flutter_gemma` model, sequential duels), `anthropicByok` onto `ByokModeImpl` with the
  user's stored key, `openaiCompat` onto any OpenAI-compatible endpoint the user configured.
  `llmServiceProvider` — intake, outside view, reveal — remains exactly as it was:
  **the cloud runs only inside the duel, and only for forecasters the user created.**
- **The language is "earned weight", never verdicts.** No screen says a forecaster "beats"
  the user or that the user "should" pick anything.

## Consequences

- **Positive:** the trust question gets an honest answer — deference to a model is earned
  against *your* resolutions, visible with its sample size, instead of assumed.
- **Positive:** the web PWA gains its first real AI path (BYOK / OpenAI-compatible
  forecasters are plain HTTP); on-device intake remains Android-only.
- **Behaviour change:** new observation rows receive no score (old scores remain in place
  but are no longer written). The model scorecard screen became the deference map
  (`/forecasters`; `/model-scorecard` redirects).
- **Cost:** a duel is sequential (the resident model holds one session) and re-runs skip
  existing forecasts, so a slow backend delays the run rather than corrupting it.
- **Constraint (do not break):** nothing may surface a sealed forecast's content before the
  user's reveal, and no sentinel may enter the prediction log. Both are tested.
