# ADR-0002 — One `LlmService` interface, three interchangeable backends

**Status:** Accepted. On-device backend live; BYOK/Connected implemented and
unit-tested, not yet wired into the app.

## Context

[ADR-0001](0001-on-device-llm-first.md) makes on-device the default. But a small local
model is genuinely weaker at synthesis, and some users would happily trade a little
privacy for a frontier model — *using their own key*, so no cost or data flows to the
project. We want that upgrade to be possible without the rest of the app knowing which
model answered, and without ever baking a key into the binary or defaulting a user
onto the cloud.

## Decision

Define a single seam, **`LlmService`** (`conductIntake`, `synthesizeOutsideView`,
`detectRepollSentiment`, `generateRevealObservation`, `generateCommunitySeed`). Provide
three implementations behind it:

- **`PrivateModeImpl`** — on-device via `flutter_gemma` (live).
- **`ByokModeImpl`** — the user's own Anthropic key, held in secure storage, calling
  `api.anthropic.com` directly and nowhere else.
- **`ConnectedModeImpl`** — a proxy the user opts into (a Cloudflare Worker that holds
  a key server-side), same Messages-API shape.

BYOK and Connected share one `AnthropicLlmService` + `AnthropicClient`; they differ
only in base URL and auth headers. All three reuse the **same system prompts**
(`llm_prompts.dart`) so outputs stay consistent across backends. Every method returns
**recoverable sentinels** on failure (empty stream / fallback text), never a crash.

## Consequences

- **Positive:** The upgrade is a swap at one provider, invisible to every feature.
- **Positive:** The cloud path is testable without the wire (the `http.Client` is
  injected), and it exists today as tested code.
- **Honest current state:** Nothing in `lib/` instantiates the cloud backends yet —
  `llmServiceProvider` always returns `PrivateModeImpl`, and there is no settings
  toggle or hosted Connected proxy. The plumbing is real; the switch is Phase 2. This
  is called out in [feature-status.md](../reference/feature-status.md) and the
  [vision scorecard](../../VISION.md).
- **Constraint:** A cloud backend must only ever run against a **user-supplied key**
  (BYOK) or a **user-chosen proxy** (Connected). No key in the binary; no silent
  cloud default. This is a non-negotiable, not a preference.
