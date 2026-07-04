# Reckon — White Paper

*A capable decision journal whose AI is free, private, offline, and yours to upgrade:
no subscription, no account, and no data leaves the device unless you opt into your own
key.*

**Status:** conceptual/strategic overview. For the design commitments see
[VISION.md](../VISION.md); for the mechanics, [architecture/OVERVIEW.md](architecture/OVERVIEW.md);
for the protocol, [concepts.md](concepts.md); for the formal sync/record spec, the
[yellow paper](spec/yellow-paper.md). This document is honest about the line between
what is built and what is aspirational — see §7.

---

## Abstract

People make their most consequential decisions — career, family, health, where to live
— with worse tooling than they use to pick a restaurant. The two things on offer are a
*dumb journal* (a notes app that records but never reflects back) and a *cloud AI coach*
(a chatbot that will happily reason about your life, in exchange for shipping the most
private text you'll ever write to someone else's servers under a subscription). Reckon
takes a third path: a **structured decision protocol** with an **honest longitudinal
record**, powered by a **small model that runs on the device**. The AI is real and
useful, but it is an *instrument of the protocol, not an oracle* — which is exactly why
it can be small, local, free, and private. A power user who wants a stronger model can
supply their own key; the architecture treats the model as a swappable part, not a moat.

## 1. The problem

Decision quality is invisible to the person deciding. We carry self-stories ("I'm bad at
career moves") with no data behind them, and we decide from whichever biased snapshot of
our judgment happens to be loaded when the deadline hits. Two failure modes dominate:

- **Anchoring.** Re-ask yourself a hard question and you drift back toward your last
  answer instead of re-forming a real one.
- **The inside view.** You reason from the vivid specifics of *your* case and ignore the
  base rate for cases like it.

The tools that could help have a distribution problem. A private journal doesn't reflect
anything back. A cloud AI could run the protocol — but decision journals are the single
most sensitive corpus a person could hand a server, and gating that behind an account
and a subscription is both a privacy cost and a moat that makes the *model*, not the
user's *record*, the product.

## 2. The idea

**Make the protocol the product, and put the model on the device.**

- The value is a *protocol* (blinded re-polling to defeat anchoring; an injected outside
  view to defeat the inside view) plus an *honest record* (your calibration over closed
  cases). Neither requires a frontier model.
- The model does the language-shaped parts — interviewing you into a crisp case,
  summarising a base rate, observing your drift — and nothing more. It never issues a
  verdict.

Because the model's job is bounded, a quantised 1–4B model running locally is *enough*.
That single fact unlocks the whole ethos: free, offline, no account, and nothing leaving
the device.

## 3. Why local-first matters *here*

Local-first is a general OpenHearth value, but the case is unusually strong for a
decision journal:

- **The data is uniquely sensitive.** This is the record of your doubts and how your
  judgment actually performed. The strongest privacy guarantee is the one that needs no
  trust: if nothing is stored server-side and there's no identity, a breach or a subpoena
  reveals nothing. Reckon's Ghost mode is exactly that.
- **Cost and access.** On-device inference is free and works offline — on a plane, in a
  waiting room, with no bill and no rate limit. A cloud coach can't say that.
- **No lock-in.** There's no account to hold your history hostage and no subscription to
  lapse. Your journal is a local database and an export button.

## 4. The architecture (in brief)

A real decision becomes a typed **Case**; a protocol runs over it (intake → blinded
re-poll → outside view → reveal → resolution) against a local SQLite store; the **record**
is computed from closed cases *on query*, never stored, so it can't be inflated. The LLM
sits behind a single `LlmService` interface with interchangeable backends. A second mode,
**ReckonParty**, does group voting and syncs opaque encrypted blobs over the LAN or a
zero-knowledge relay. Full detail in [architecture/OVERVIEW.md](architecture/OVERVIEW.md).

## 5. BYOK-upgradeable: the model is an instrument, not a moat

Some users will want a stronger model for the synthesis, and will happily trade a little
privacy to get it — *on their own terms*. Reckon's LLM layer is one interface with three
implementations (on-device; the user's own Anthropic key; an opt-in proxy). Upgrading is
a swap at a single seam, invisible to every feature, using the **same prompts** so the
experience is continuous. The non-negotiable: a cloud backend only ever runs against a
**key the user supplied** or a **proxy they chose** — never a key baked into the binary,
never a silent cloud default. The model is a part you can replace, not a subscription you
must keep.

## 6. Positioning: protocol-and-record, not a chatbot

The gravity in "AI for decisions" pulls every product toward *being the smart friend you
ask what to do*. Reckon deliberately isn't that:

- **vs. a cloud AI coach** — a chatbot optimises for a satisfying answer *now*; Reckon
  optimises for a truthful record *over time*. It refuses to tell you what to decide,
  because the durable value is your own calibration, not a fluent opinion. And it does
  its work without your life's decisions leaving the device.
- **vs. a plain journal** — a journal records; Reckon reflects: blinded re-polls, an
  outside view, a drift chart, a calibrated record. The structure is the point.

A chatbot's moat is its model. Reckon has no interest in that moat — the model is
swappable — because its value is the *user's* accumulating record, which no competitor
holds.

## 7. What is built, and what is not

A white paper that overclaims is marketing. Honestly, as of `0.1.0`:

**Built, tested, live in-app:** the entire on-device Ghost loop — streaming intake, case
model, blinded re-polls, outside view with stratification, reveal (drift chart +
observation), resolution check-in, and the computed-on-query record (Clarity Score,
calibration, base rates, insight cards); glossary, prediction scorecard, and export;
deadline-aware, lockscreen-private notifications; a multi-model on-device backend
(Gemma 3 1B / Qwen 2.5 1.5B / Phi-4 Mini) with resumable, 416-recovering downloads; and
**ReckonParty** — approval/ranked-choice voting with AES-GCM-256 encryption, a
self-hostable zero-knowledge relay, and LAN sync. CI runs analyze + test + a debug-APK
smoke build + the relay suite on every push.

**Aspirational — code exists, not yet wired or hosted:** the **BYOK and Connected cloud
backends** are implemented and unit-tested, but nothing in the app instantiates them
yet — the live service is always on-device, there's no cloud toggle, and no Connected
proxy is deployed. The **Token/Named account tiers** are enum values only. **Community
forecasting** is unbuilt. The experience is **Android-only** (the on-device model needs
MediaPipe); there is no iOS build and only a web scaffold. The release build is
debug-signed.

The honest boundary: the "BYOK-upgradeable" claim describes real, tested plumbing behind
an unbuilt switch — the *capability* is there, the *user-facing upgrade* is Phase 2. And
calibration on a household's sparse case history is a genuine open problem, not a solved
one (see [limitations](limitations.md)).

## 8. Why it's worth doing

Because the alternative — running the most sensitive reasoning of your life through a
subscription chatbot that keeps the data and owns the model — is the default everyone is
building toward, and it's the wrong default for this corpus. The contribution isn't a new
model or a new solver. It's the demonstration that a genuinely useful decision tool can
put a capable-enough model *on the device*, keep the private record *local and honest*,
and treat the model as a *replaceable instrument the user controls* — free, offline, and
account-free, with a stronger model one pasted key away for anyone who wants it.

---

## References

- Kahneman, D., Lovallo, D. & Sibony, O. — the *inside view vs. outside view* distinction
  behind reference-class forecasting.
- Tetlock, P. & Gardner, D. *Superforecasting* — calibration, the outside view, and
  updating as trainable decision skills.
- Vul, E. & Pashler, H. (2008). *Measuring the crowd within* — aggregating multiple
  estimates from a single mind (the "inner crowd").
- Diátaxis (Procida, D.) — the documentation framework this project's [docs](README.md)
  follow.

*The code and comments referenced here were authored by an AI assistant and describe what
currently exists — take them with gratitude and a grain of salt, and verify before
relying.*
