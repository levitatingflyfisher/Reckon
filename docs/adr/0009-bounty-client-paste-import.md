# ADR-0009 — The bounty client: files and paste first, redaction preview mandatory

**Status:** Accepted (enforced in `features/bounty/`).

## Context

The **reckonBounty** protocol (its own repository; the spec there is the wire law) lets
outside bots answer a de-identified decision question and earn a place in the asker's
record. Reckon wants to be its first client — but two of this project's load-bearing
claims sit directly in the path:

1. [privacy-model.md](../privacy-model.md) opens with "in the default configuration,
   nothing about your decisions ever leaves the device", and VISION commitment 3 requires
   egress to be **opt-in and checkable**. A bounty export is, by definition, decision text
   leaving the device.
2. R1 (blinded elicitation) — outside forecasts must not anchor the user any more than the
   duel's may.

Also practical: the web PWA must be a full client, and every new dependency or network
caller enlarges the surface privacy-model.md has to enumerate.

## Decision

- **The user is the transport.** Export composes a BountyRequest *file*; it leaves the
  device only through the system share sheet or the clipboard, by an explicit user action.
  Import v0 is a **paste screen**. The app makes **zero new network calls** — the
  privacy-model's network-caller enumeration is unchanged by this feature.
- **Redaction preview is mandatory, in every path.** The on-device model drafts a
  de-identified rewrite (`redactQuestion`, now on the `LlmService` interface — a backend
  capability like the seed call); any failure — no model, sentinel, half-rewrite — falls
  back to the *original* text flagged `redaction: manual`, because text that *looks*
  redacted while one field kept the original is worse than an honest manual job. Either
  way the user edits and signs off in a preview before the file exists. Options travel
  as-is (and the screen says so): responses are matched by option text, so redacting the
  options would orphan every answer.
- **Open cases only.** The ask/import surfaces exist only while a case is open: a
  post-decision import cannot be sealed against elicitation, and scoring responses
  imported after the choice would let selection bias into the record.
- **Imported responses join the duel.** Each accepted response upserts a `bountyBot`
  forecaster (`bounty:<bot.name>` — created only if absent, so a user's rename/disable
  survives re-pastes) and logs one sealed `duelForecast` row with the duel's exact payload
  shape. From there the existing machinery does everything: sealed under R1, scored at
  resolution under R4, weighted under R5. Rejection rules (wrong `request_id`, after
  `reply_by`, unmatchable options, one-per-bot) are enforced per the spec with per-bot
  reasons; one bad entry never blocks the rest of a paste.
- **Sentinel rule scoped deliberately:** empty-rationale *imports* are accepted (a pasted
  wire file is a deliberate act, unlike a resident model's hiccup); duel sentinels remain
  banned.

**Alternatives rejected:** fetching responses over HTTP in v0 (a new egress surface before
the redaction practice has proven out — and needless, since files already work on every
platform including web); auto-redaction without a preview (an unverifiable privacy claim in
the wire format); allowing post-decision imports (selection bias); a bounty-private
redaction seam off the interface (backends would diverge).

## Consequences

- **Positive:** "nothing leaves the device" stays checkable — the boundary is the share
  sheet, which the user can see. The PWA is a full bounty client with zero new
  dependencies.
- **Positive:** outside bots compete on the same scored terms as resident forecasters; no
  parallel scoring path to maintain.
- **Cost:** manual transport friction (export a file, paste the answers). Accepted for v0;
  any future fetch transport is a new ADR with a new privacy-model entry.
- **Honest limit:** R1 for the pasted text itself is out of the app's control — the app
  renders nothing before the reveal (counts and rejection reasons only), but a user can
  read the raw file in any editor (yellow paper §9). De-identification is drafted by a
  small model and reviewed by a human; it is not guaranteed re-identification-proof.
- **Constraint (do not break):** nothing may leave the device without passing the editable
  preview, and no import may bypass the open-case gate or the idempotence guard.
