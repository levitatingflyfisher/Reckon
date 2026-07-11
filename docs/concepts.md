# Concepts

The ideas Reckon is built on, and the domain model that encodes them. For the *why*
behind specific choices see the [ADRs](adr/); for the exact tables and fields see the
[data model reference](reference/data-model.md).

## The inner crowd

A single mind is a small, biased crowd. Ask yourself the same hard question on three
different days and you get three different answers — coloured by mood, by what you read
that morning, by whatever you decided last. The **inner-crowd** idea (a cousin of the
"wisdom of crowds" and of superforecasting practice) is to *sample your own judgment
over time and aggregate it*, instead of trusting whichever snapshot you happen to hold
when the decision is due.

Reckon operationalises this with a protocol. It doesn't make you smarter in the moment;
it makes your *distribution of moments* visible, and it defends that sample from the
biases that would collapse it back to a single anchored point.

## The protocol, station by station

### 1. Intake → a Case

You start with a messy dilemma. The on-device model interviews you and Reckon distils
it into a **Case**: a natural-language `question`, two named options (`optionA`,
`optionB`), a list of **stated criteria** (what actually matters, e.g. "commute",
"salary", "closeness to family"), the **stakes** (`low` / `medium` / `high`), and a
**regret horizon** (`weeks` / `months` / `years` — how far out you'll feel this). A
Case moves through a lifecycle: `open` → `decided` → `resolving` → `closed`.

Fixing the options and criteria up front is itself a debiasing move: it stops the
question from silently mutating between re-polls.

### 2. Blinded re-polls → a time series

While the Case is `open`, Reckon periodically asks: *where do you lean now?* You give a
**lean** (0–100, from all-A to all-B), a **confidence** (`low` / `medium` / `high`),
and an optional **rationale**. Each answer is a **Poll**, numbered in sequence.

The re-poll is **blinded**: you are not shown your earlier polls before you answer.
This is the load-bearing invariant ([ADR-0006](adr/0006-honest-record-blinded-repolls.md)).
If Reckon showed you yesterday's lean, you'd anchor to it and the series would measure
your memory. Blinded, the series measures your genuinely re-formed judgment — and the
model can flag when today's rationale contradicts the sentiment of an earlier one
(`detectRepollSentiment`).

### 3. The outside view

Left alone, people take the **inside view**: they reason from the specifics of *their*
case and systematically underweight the base rate. Reckon injects the **outside view**.
It matches your Case to a **reference class** — a category of comparable decisions with
a known base-rate description and an uncertainty level — from a seeded local database,
and the model synthesises a short base-rate summary. Crucially, it can **stratify** by
a light **user profile** (e.g. socio-economic bracket, relationship status) so the base
rate is for people like you, not the general population. The outside view informs; it
never overrides your inside knowledge.

### 4. The reveal

When you decide, Reckon assembles the **case time series** — every poll in order,
against your stated criteria and the deadline — and shows it: a chart of how your
position actually drifted, plus a one-line **reveal observation** from the model
("your lean swung 40 points the week you talked to your sister, then settled"). This is
the "oh" moment: seeing the shape of your own deliberation, which you could not see from
inside it.

### 5. Resolution → the record

Some weeks or months later — timed to your regret horizon — Reckon asks how it actually
turned out: a **resolution check-in** that records your satisfaction. That closes the
Case and feeds the longitudinal **record**.

## The honest record

Across your closed cases, Reckon computes (never stores — see
[ADR-0006](adr/0006-honest-record-blinded-repolls.md)):

- **Clarity Score** — a 0–100 summary of how satisfied you've been with your closed
  decisions, mapped from a `-2…+2` satisfaction scale
  (`value = round((avg + 2) / 4 × 100)`), reported alongside the **case count** so a
  high score on two cases can't masquerade as a track record.
- **Calibration report** — mean satisfaction broken down by **category** and by the
  **confidence** you held at decision time (are your "high confidence" calls actually
  the ones that pan out?), plus **mean lean drift** (how much your position typically
  moves during deliberation).
- **Personal base rates** and **insight cards** — patterns surfaced from your own
  history ("you're most satisfied with health decisions, least with career ones").
- **Update quality** — whether your re-polls tend to move *toward* the option you
  ended up glad about. Deliberation that converges on the right answer is a skill;
  this makes it visible.

The point is not a grade. It's the mirror: *your own track record confronting you*, so
your next decision is informed by evidence about your judgment instead of a flattering
story about it.

## The duel: forecasters keep score too

The same mirror now points at the models. A **forecaster** is anyone who may state a
lean on your open case and live with the consequences: a persona over the on-device
model (a base-rate skeptic, a steelman advocate), a stronger model behind your own
API key, a llamafile on your LAN, or an outside bot whose answer you pasted in through
the [bounty interface](adr/0009-bounty-client-paste-import.md).

Three rules keep the duel honest ([ADR-0007](adr/0007-forecaster-duel-alignment-scoring.md)):

1. **Sealed until your reveal.** While a case is open you see only *"N forecasts
   sealed"* — never a lean, never a rationale. A bot's opinion shown early would anchor
   you exactly the way a visible prior poll would; the same blinding that protects your
   re-polls protects your independence from the machines.
2. **Scored at resolution, individually.** When you record how the decision felt, every
   forecast is scored by how well it aligned with the option you were glad (or sorry)
   about. There is no "the AI was right" in aggregate — there is *this forecaster, on
   your cases, with this sample size*.
3. **Deference is earned, never asserted.** The deference map shows each forecaster's
   mean score and **earned weight** — and yours, computed on read by the same formula,
   because the ensemble includes you. Below five scored cases an entry is listed but
   weightless, and the screen says "not enough resolved decisions to say" instead of
   pretending. Nothing anywhere says you *should* pick what a forecaster picked.

## ReckonParty: the other mode

Some decisions aren't slow and personal — they're a group trying to converge. For the
quick kind (where to eat, what to watch), **ReckonParty** is a stripped-down mode: a
shared question, **approval** or **ranked-choice** voting, and a result computed locally
in minutes — anonymous, no rationales, no history. It's local-first (pass the phone
around) and, for remote participants, syncs opaque encrypted blobs over the LAN or a
zero-knowledge relay ([ADR-0004](adr/0004-reckonparty-zero-knowledge-sync.md)).

For the serious kind — where do we live, do we change schools — **persistent groups**
([ADR-0008](adr/0008-persistent-groups-attributed-ballots.md)) give a household a named
circle: votes carry names (a family deciding together wants to know who leans where), the
group keeps its decision history, and **considered mode** seals the tallies until
everyone has voted, then reveals mutually — the same anti-anchoring move as the blinded
re-poll, applied to a marriage. Names and group data still ride only *inside* the
encrypted blobs; the relay learns nothing new. One-shot parties stay as anonymous as they
ever were.

## What the model is (and isn't) for

Throughout, the LLM is an **instrument of the protocol, not an oracle**. It conducts the
intake interview, synthesises the outside-view summary, detects a re-poll sentiment
mismatch, writes the reveal observation, and drafts the bounty redaction. It is never
asked *what should I do?* and never answers it.

The duel sharpens this boundary rather than crossing it. A forecaster *is* asked "where
do **you** lean?" — but its answer is sealed until your own decision is on record, it is
addressed to the record rather than to you, and the only standing it can ever gain is a
scored track record on your cases. The forbidden move stays forbidden: no output is ever
rendered as "you should pick B." That boundary is the reason Reckon can run on a small
on-device model in the first place: the hard part is the protocol and the honest record,
not a super-intelligent verdict.
