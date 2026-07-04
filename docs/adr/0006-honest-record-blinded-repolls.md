# ADR-0006 — Keep the record honest: computed-on-query calibration and blinded re-polls

**Status:** Accepted (enforced in the domain and data layers).

## Context

Reckon's entire value is a *truthful* mirror. Two ways to quietly corrupt it:

1. **A flattering record.** If the Clarity Score or calibration were a stored, mutable
   number, it could drift, be back-filled, or be inflated — and a decision-quality
   metric that lies is worse than none.
2. **Anchored re-polls.** If a re-poll showed you your previous lean before you
   re-answered, you'd anchor to it. The time-series would measure your memory, not your
   evolving judgment — defeating the point of blinded re-elicitation.

## Decision

- **Compute the record on query, never store it.** Clarity Score, calibration buckets,
  personal base rates, and insight cards are derived from **closed cases** each time
  they're shown (`features/record/domain/usecases/`), from the raw polls and
  resolutions. There is no stored "score" column to inflate.
- **Blind the re-poll.** The re-poll flow must not surface prior polls before the user
  re-answers; the poll's `revealed` flag and the data layer enforce that priors stay
  hidden until the reveal. The reveal is the *only* place the full time-series appears.

## Consequences

- **Positive:** The metrics can't lie — change the inputs (close more cases) and the
  numbers move deterministically; there's nothing to tamper with.
- **Positive:** The time-series measures genuine drift, so the reveal's "oh" moment is
  real.
- **Cost:** Recomputing on query is slightly more work than reading a cached number —
  negligible at a household's case volume, and it keeps the data model honest.
- **Constraint (do not break):** No usecase may persist a computed score as
  ground-truth, and no screen may show a user their prior lean during a re-poll. Both
  are load-bearing invariants, tested, and echoed in [AGENTS.md](../../AGENTS.md).
- **Honesty about honesty:** calibration on a household's *sparse* case history is
  itself a hard problem — see [limitations](../limitations.md). The commitment here is
  that the maths is truthful, not that a dozen cases yield a precise verdict.
