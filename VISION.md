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
   base-rate outside view, and observes drift. It never issues a verdict. When it
   *forecasts* — the duel — its forecast stays **sealed until your own decision is on
   record**, and its only authority is a track record scored against your resolutions:
   **earned weight, never a verdict**. It runs on a **free, private, offline on-device
   model** by default; a Bring-Your-Own-Key Claude backend is an *upgrade*, never a
   requirement. ([ADR-0001](docs/adr/0001-on-device-llm-first.md),
   [ADR-0002](docs/adr/0002-pluggable-llm-backends.md),
   [ADR-0007](docs/adr/0007-forecaster-duel-alignment-scoring.md))
3. **Nothing leaves the device unless you opt in — and it's checkable.** Ghost mode
   makes no network call except downloading the model weights over HTTPS. A
   household-stove forecaster sends its prompt to a model on your own desktop, as
   encrypted frames keyed by the household phrase — it leaves the device but never
   the house. BYOK sends your case text to Anthropic under *your* key and nowhere
   else. The ReckonParty
   relay only ever holds ciphertext. A bounty export exists only as a de-identified
   file you reviewed in a preview and shared yourself — the app is never the
   transport. This is stated concretely in
   [docs/privacy-model.md](docs/privacy-model.md) and enforced in code.
   ([ADR-0009](docs/adr/0009-bounty-client-paste-import.md))
4. **No ads, no tracking, no data sales** — architecturally, not just as a promise.
   There is no analytics SDK and no telemetry endpoint to disable.
5. **Keep the data model honest.** Your Clarity Score, calibration, and the deference
   map are **computed from closed cases on query, never stored or inflated**; a
   re-poll is **blinded** — the app must not show you your prior answers before you
   re-answer. The single persisted score is the per-*forecast* alignment score — a log
   entry about a specific forecast, never a user metric. A mirror that flatters is
   worse than no mirror. ([ADR-0006](docs/adr/0006-honest-record-blinded-repolls.md),
   [ADR-0007](docs/adr/0007-forecaster-duel-alignment-scoring.md))
6. **Genuine craft.** Flutter Clean Architecture (domain / data / presentation),
   Riverpod, Drift; a broad test suite is the norm. Warm, not sterile — home-cooked
   software for a household's real decisions. ([ADR-0005](docs/adr/0005-flutter-clean-architecture.md))

## Honest scorecard — built vs. aspirational

A guiding light has to tell the truth about where the light reaches. This code and
its comments were written by an AI assistant; treat them as **an accurate record of
what currently exists, offered with gratitude and a grain of salt** — verify a claim
before you rely on it. As of the July 2026 forecaster-duel build:

**Real, tested, load-bearing (the whole Ghost loop is live in-app):**
- Intake → case → blinded re-poll → reveal → resolution check-in → record, all
  on-device, no account. Streaming conversational intake, a drift chart, and a
  one-line reveal observation, all from the local model.
- Outside view over a **seeded reference-class database** (15 entries today) with
  profile stratification; the record computes **Clarity Score, calibration buckets,
  personal base rates, insight cards, and update quality** from closed cases.
- **The forecaster duel.** A user-owned roster of forecasters — personas over the
  resident model, the household stove (a far larger model on the family's own
  desktop, encrypted end to end and keyed by the household phrase), your own
  Anthropic key (BYOK), any OpenAI-compatible endpoint (llamafile/Ollama), and
  imported bounty bots — each gives a **sealed** forecast on
  an open case (you see only "N forecasts sealed" until your own reveal). At
  resolution every forecast is scored individually against how the decision felt,
  and the **deference map** (`/forecasters`) shows each forecaster's **earned
  weight** — including *yours*, computed on read by the same formula. Never a
  verdict.
- **The bounty interface** (reckonBounty client): export a case as a de-identified
  request file — redaction drafted on-device, always behind an editable preview —
  and paste outside bots' responses back in as sealed duel forecasts that score at
  resolution like everyone else.
- Technique glossary and Markdown/JSON export.
- Deadline-aware local notifications for re-polls and resolution check-ins.
- **Multi-model on-device backend** (Gemma 3 1B / Qwen 2.5 1.5B / Phi-4 Mini via
  `flutter_gemma` + MediaPipe) with **resumable, 416-recovering downloads**.
- **ReckonParty**: create / join / vote (approval + ranked-choice) / result, wired
  into the router, with AES-GCM-256 encryption, a self-hostable encrypted-blob relay
  (client + Dart server), LAN mDNS/DNS-SD discovery, and a key-in-URL-fragment join
  link — and votes now actually sync (push on vote, pull on the result screen).
  **Persistent groups**: named circles with attributed ballots and a shared decision
  history, plus **considered mode** — tallies sealed until everyone votes, then a
  mutual reveal. Group and member data ride only inside encrypted blobs.
  CI runs analyze + test + a debug-APK smoke build + a web-release smoke build + the
  relay suite on every push.

**Aspirational — code exists, not yet wired or hosted:**
- **A cloud backend for the core loop.** BYOK and OpenAI-compatible backends are live
  *inside the duel* (per-forecaster, opt-in), but intake / outside view / reveal still
  always run on-device: there is **no settings toggle** to run the core loop on a
  cloud model, and no Connected proxy is deployed. The "BYOK-upgradeable core loop"
  remains plumbing without a switch.
- **Account tiers beyond Ghost.** `AuthTier` names `token` and `named`, but only
  `ghost` is implemented. No server, no recovery, no cross-device sync.
- **Group sync beyond the party link.** The group-key namespace exists and is tested,
  but nothing populates it: groups propagate via per-party links today, there is no
  group-manifest blob, no deployed relay, and no offline re-push queue.
- **Bounty transport beyond files.** Export is share/copy; import is paste. No
  directory fetch, no payments (the request's bounty rail is `none`).
- **iOS / full-fat PWA.** The on-device model needs Android's native MediaPipe. The
  web PWA now has its first real AI path — duels via BYOK or an OpenAI-compatible
  endpoint — but intake's on-device model remains Android-only.

The Ghost decision loop is real, and the duel now keeps score honestly. Anything with
an *account*, a *deployed server*, or *money* attached is still ahead of us. Keep that
line bright.

## Horizons (problems, not a feature list)

Framed as *problems* on purpose — a dated feature list self-destructs.

- **Near** — Wire the cloud backends to a real settings switch so BYOK upgrades the
  *core loop* too (the duel already runs them per-forecaster). Deploy a relay and give
  groups their long-lived keys and a re-push queue, so a household's circle outlives
  the party link. Round out the reference-class database to its target breadth.
- **Mid** — The trust question for a small on-device model — *earn* confidence through
  calibration made visible — now has its mechanism (the duel and the deference map);
  the open problem is what follows from it: per-member calibration inside groups,
  bounty transport that isn't hand-carried files, and whether an earned weight should
  ever *do* anything (reordering, prompting) beyond being seen.
- **Far** — The unsolved one worth naming: **honest calibration on sparse data.** A
  household makes a handful of big decisions a year. How do you say something true and
  useful about someone's judgment from a dozen closed cases without either flattering
  them or pretending to a precision you don't have? The duel sharpens the question —
  forecaster weights gate on n ≥ 5, but n stays small for years. Getting the
  statistics *and the copy* right on small samples is the real research problem under
  the whole product.

## The name

**Reckon** — to conclude or judge *after calculation*; and *a reckoning*, a settling
of accounts. Both senses are the product. You reckon a decision by working it through
the protocol, and in time your record delivers the reckoning: your intuitions,
confronted with what actually happened. Not a verdict handed down — an account
settled with yourself.
