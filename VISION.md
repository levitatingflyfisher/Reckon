# Vision

> The north star for Reckon. If you (person or agent) are about to change something
> load-bearing, read this first — it says what must stay true and why. For *how it's
> built*, see [docs/architecture/OVERVIEW.md](docs/architecture/OVERVIEW.md); for *why
> each decision was made*, [docs/adr/](docs/adr/).

## The one idea

**Reckon does not tell you what to decide. It shows you what you already think —
more clearly than you could see it alone, and across time.**

Most people have never seen their own decision quality plotted. They carry vague
self-stories ("I'm bad at career moves", "my gut is usually right") and no data.
Reckon builds the mirror: it runs a structured protocol over a real decision —
a conversational intake, blinded re-polls spread over days or weeks, a reveal of
how your position actually drifted, a delayed check on how it turned out — and it
keeps the record. The longer you use it, the sharper the mirror gets.

> **The killer feature is not any single technique. It is your own track record
> confronting you.**

Reckon is a *protocol enforcer and a longitudinal record keeper*, not an AI oracle.
The model in the loop never decides. It interviews, it synthesises an outside view,
it notices when today's rationale contradicts yesterday's lean. The judgment stays
yours; Reckon just refuses to let you forget what you actually said.

## What this is

A **local-first personal decision journal for Android**. The whole loop —
intake → blinded re-poll → reveal → resolution → a calibrated record — runs
on-device, with no account and no server, powered by a small **on-device LLM**.
A second mode, **ReckonParty**, aggregates a group's preferences (approval or
ranked-choice voting) and syncs over the LAN or through an optional
zero-knowledge relay.

```
   you, deciding                 Reckon, the protocol              the mirror
  ─────────────────           ───────────────────────         ───────────────
  a real two-option    ──▶    intake · blinded re-polls  ──▶   your drift, charted
  decision, over weeks         outside view · reveal            your calibration,
                               resolution check-in              honestly scored
```

The lineage is **inner-crowd / superforecasting practice** — reference classes and
the outside view, blinded re-elicitation to defeat anchoring, calibration tracking —
packaged as a private app instead of a spreadsheet discipline. The novelty isn't the
techniques; it's making them ambient, longitudinal, and free of any cloud.

## Design commitments (do not break these)

These are the load-bearing beliefs. Breaking one is a design regression, not a
feature. Each is enforced in the code and recorded as an ADR.

1. **Local-first, Ghost by default.** The complete decision loop runs on-device with
   zero identity and zero server contact. No account is ever required for core use.
   Any sync (ReckonParty) is opt-in and carries **encrypted blobs through a dumb
   relay** — never plaintext, never a BaaS. ([ADR-0003](docs/adr/0003-local-first-ghost-tier.md),
   [ADR-0004](docs/adr/0004-reckonparty-zero-knowledge-sync.md))
2. **The AI is a means, not the oracle.** The model structures intake, synthesises a
   base-rate outside view, and observes drift. It never issues a verdict. It runs on
   a **free, private, offline on-device model** by default; a Bring-Your-Own-Key
   Claude backend is an *upgrade*, never a requirement. ([ADR-0001](docs/adr/0001-on-device-llm-first.md),
   [ADR-0002](docs/adr/0002-pluggable-llm-backends.md))
3. **Nothing leaves the device unless you opt in — and it's checkable.** Ghost mode
   makes no network call except downloading the model weights over HTTPS. BYOK sends
   your case text to Anthropic under *your* key and nowhere else. The ReckonParty
   relay only ever holds ciphertext. This is stated concretely in
   [docs/privacy-model.md](docs/privacy-model.md) and enforced in code.
4. **No ads, no tracking, no data sales** — architecturally, not just as a promise.
   There is no analytics SDK and no telemetry endpoint to disable.
5. **Keep the data model honest.** Your Clarity Score and calibration are **computed
   from closed cases on query, never stored or inflated**; a re-poll is **blinded** —
   the app must not show you your prior answers before you re-answer. A mirror that
   flatters is worse than no mirror. ([ADR-0006](docs/adr/0006-honest-record-blinded-repolls.md))
6. **Genuine craft.** Flutter Clean Architecture (domain / data / presentation),
   Riverpod, Drift; a broad test suite is the norm. Warm, not sterile — home-cooked
   software for a household's real decisions. ([ADR-0005](docs/adr/0005-flutter-clean-architecture.md))

## Honest scorecard — built vs. aspirational

A guiding light has to tell the truth about where the light reaches. This code and
its comments were written by an AI assistant; treat them as **an accurate record of
what currently exists, offered with gratitude and a grain of salt** — verify a claim
before you rely on it. As of `0.1.0`:

**Real, tested, load-bearing (the whole Ghost loop is live in-app):**
- Intake → case → blinded re-poll → reveal → resolution check-in → record, all
  on-device, no account. Streaming conversational intake, a drift chart, and a
  one-line reveal observation, all from the local model.
- Outside view over a **seeded reference-class database** (15 entries today) with
  profile stratification; the record computes **Clarity Score, calibration buckets,
  personal base rates, and insight cards** from closed cases.
- Technique glossary, model-prediction scorecard, and Markdown/JSON export.
- Deadline-aware local notifications for re-polls and resolution check-ins.
- **Multi-model on-device backend** (Gemma 3 1B / Qwen 2.5 1.5B / Phi-4 Mini via
  `flutter_gemma` + MediaPipe) with **resumable, 416-recovering downloads**.
- **ReckonParty**: create / join / vote (approval + ranked-choice) / result, wired
  into the router, with AES-GCM-256 encryption, a self-hostable encrypted-blob relay
  (client + Dart server), LAN mDNS/DNS-SD discovery, and a key-in-URL-fragment join
  link. CI runs analyze + test + a debug-APK smoke build + the relay suite on every push.

**Aspirational — code exists, not yet wired or hosted:**
- **BYOK and Connected (cloud) LLM backends.** The Anthropic Messages-API client and
  service — and both the BYOK and Cloudflare-Worker "Connected" wrappers — are
  *implemented and unit-tested*, but **nothing in the app instantiates them yet**:
  the live `LlmService` is always the on-device one, there is no settings toggle to
  pick a cloud backend, and no Connected proxy is deployed. This is the honest state
  behind the "BYOK-upgradeable" thesis — the plumbing is real, the switch is not.
- **Account tiers beyond Ghost.** `AuthTier` names `token` and `named`, but only
  `ghost` is implemented. No server, no recovery, no cross-device sync.
- **Community forecasting and AI seed bots** — not built.
- **iOS / a full PWA.** The on-device model needs Android's native MediaPipe, so the
  differentiating experience is Android-only today (a web scaffold exists).

The Ghost decision loop is real. Anything with a *cloud key*, an *account*, or a
*community server* attached is still ahead of us. Keep that line bright.

## Horizons (problems, not a feature list)

Framed as *problems* on purpose — a dated feature list self-destructs.

- **Near** — Wire the already-built cloud backends to a real settings switch so BYOK
  is a one-paste upgrade. Round out the reference-class database to its target breadth
  so the outside view stops thinning out on common decisions.
- **Mid** — The trust question for a small on-device model: how do you *earn* a user's
  confidence in a 1B-parameter interviewer's outside view without overclaiming? The
  answer is probably calibration made visible — show the model its own track record,
  the same way Reckon shows the user theirs.
- **Far** — The unsolved one worth naming: **honest calibration on sparse data.** A
  household makes a handful of big decisions a year. How do you say something true and
  useful about someone's judgment from a dozen closed cases without either flattering
  them or pretending to a precision you don't have? Getting the statistics *and the
  copy* right on small samples is the real research problem under the whole product.

## The name

**Reckon** — to conclude or judge *after calculation*; and *a reckoning*, a settling
of accounts. Both senses are the product. You reckon a decision by working it through
the protocol, and in time your record delivers the reckoning: your intuitions,
confronted with what actually happened. Not a verdict handed down — an account
settled with yourself.
