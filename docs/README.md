# Documentation

Organized on the [Diátaxis](https://diataxis.fr/) model — four kinds of docs for
four different needs. Find what you need by *what you're trying to do*, not by
guessing a filename.

| I want to… | I need | Go to |
|---|---|---|
| **learn by doing** | a Tutorial | [Tutorials](#tutorials) |
| **accomplish a specific task** | a How-to guide | [How-to guides](#how-to-guides) |
| **look up exact details** | Reference | [Reference](#reference) |
| **understand why** | Explanation | [Explanation](#explanation) |

New here? Start with the [README quickstart](../README.md), then
[Explanation § concepts](concepts.md) to understand the protocol, then
[Architecture overview](architecture/OVERVIEW.md).

---

## Tutorials
*Learning-oriented — take me by the hand through my first success.*

Today the entry point is the **[README quickstart](../README.md)** — clone, run, pick
a model, and reckon your first case end to end.

*Gap (contributions welcome):* a hand-held "reckon your first decision and read your
reveal in 10 minutes" walkthrough, and a "host a ReckonParty over the LAN" tutorial.
If you write one, put it in `docs/tutorials/`.

## How-to guides
*Task-oriented — how do I accomplish X (assumes you know the basics)?*

- **[Build & run](how-to/build-and-run.md)** — set up the toolchain, generate code,
  run on Android, download a model, and (optionally) enable a cloud backend.
- **[Host a ReckonParty relay](how-to/host-a-relay.md)** — run the optional
  zero-knowledge sync server for remote participants.
- Agent-guidance for working *in* this repo: **[AGENTS.md](../AGENTS.md)**.

## Reference
*Information-oriented — tell me exactly, precisely, completely.*

- **[Model architecture](reference/model-architecture.md)** — the `LlmService`
  interface, the on-device / BYOK / Connected backends, model selection and routing,
  the download pipeline, and the trust/token story.
- **[Data model](reference/data-model.md)** — the Drift tables, what's stored vs.
  computed-on-query, and the domain entities.
- **[Feature status](reference/feature-status.md)** — what's shipped, what's built but
  unwired, and what's not built, per area.
- The ReckonParty HTTP relay protocol is specified in [`relay/README.md`](../relay/README.md)
  and, formally, in the [yellow paper](spec/yellow-paper.md).

## Explanation
*Understanding-oriented — help me understand the ideas and the why.*

- **[Vision](../VISION.md)** — the one idea, the design commitments, the honest scorecard.
- **[White paper](whitepaper.md)** — why an on-device-AI decision journal, why
  local-first here, and how it differs from a cloud incumbent.
- **[Concepts](concepts.md)** — the inner-crowd protocol, blinding, the outside view,
  calibration, and the domain model.
- **[Architecture overview](architecture/OVERVIEW.md)** — the layers and data flow,
  with diagrams and a module map.
- **[Architecture Decision Records](adr/)** — why each load-bearing choice was made.
- **[Privacy model](privacy-model.md)** — the threat model and exactly what leaves the
  device, per mode and per backend.
- **[Limitations](limitations.md)** — read before adopting. What it does *not* do.

---

### The white paper & yellow paper

Two long-form documents complement this tree:
- **[White paper](whitepaper.md)** — the conceptual/strategic case (free, private,
  offline on-device AI; BYOK-upgradeable; local-first).
- **[Yellow paper / formal spec](spec/yellow-paper.md)** — the rigorous specification
  of the ReckonParty sync protocol and the record-integrity invariants (the crypto
  envelope, the zero-knowledge relay property, blinded re-polls, deterministic scoring).
