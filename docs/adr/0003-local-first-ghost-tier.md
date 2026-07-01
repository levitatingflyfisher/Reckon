# ADR-0003 — Local-first, Ghost tier: no account, no server for core use

**Status:** Accepted (Ghost is the only implemented tier).

## Context

Reckon holds a private record of someone's most consequential decisions and how their
judgment played out. The strongest privacy guarantee is the one that needs no trust:
if nothing is stored server-side and there is no identity, a breach or a subpoena
reveals nothing. The product design offers three tiers as an explicit values choice —
**Ghost** (zero identity, on-device only), **Token** (recoverable anonymous account),
and **Named** (standard login) — with no nudge toward the data-collecting option.

## Decision

**Ship Ghost as the product; everything else is a bonus.** The complete decision loop
runs on-device against a local Drift/SQLite database, with an account token generated
locally into secure storage. `AuthRepository.currentTier` returns `AuthTier.ghost`.
No email, no password, no push, no server. The `token` and `named` tiers are named in
the `AuthTier` enum but are **not implemented** — they wait on a server that does not
yet exist.

## Consequences

- **Positive:** Core functionality has no account gate and no backend to run or breach.
- **Positive:** The storage layer is dead simple — local SQLite, no sync conflicts, no
  RLS policies. (The original PRD proposed a Supabase/Postgres backend; that was
  dropped in favour of local-only Drift.)
- **Cost:** Ghost has no cross-device sync and no recovery — lose the device, lose the
  journal. This is stated plainly in onboarding and [limitations](../limitations.md).
- **Constraint:** Anything that would require an account for core use is off-thesis. A
  future Token/Named tier must be *additive* and must not degrade the Ghost path.
- **Relation:** Group sync (ReckonParty) is the one networked feature, and it too
  avoids a BaaS — see [ADR-0004](0004-reckonparty-zero-knowledge-sync.md).
