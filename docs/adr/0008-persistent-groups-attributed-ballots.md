# ADR-0008 — Persistent groups: a local container over per-party sync, attributed ballots, the considered reveal

**Status:** Accepted (schema v5; enforced in `features/party/`).

## Context

ReckonParty was built for one-shot, anonymous questions — where to eat, what to watch. The
decisions a household actually agonises over (where do we live, do we take the job) need
three things the one-shot mode refused on principle: a **persistent circle** (the same
people, a shared history), **names on votes** (a family deciding together wants to know who
leans where), and a **blind-then-reveal** move (everyone answers before anyone anchors —
the same reason re-polls are blinded). Meanwhile the relay is deliberately dumb
([ADR-0004](0004-reckonparty-zero-knowledge-sync.md)), no relay is deployed yet, and the
zero-knowledge property (Z) is a headline claim we must not dent.

A prerequisite fix landed first: `pushBallot`/`pull` had zero UI callers — a joined guest's
vote never reached the host. The vote screen now pushes, the result screen pulls, and
"Close voting" reaches the relay. ADR-0004's "implemented" claim was true only of the
service layer until this.

## Decision

**Groups are a client-side container over the existing per-party protocol.** The relay
gained no operation, no state, and no schema; everything new travels *inside* the encrypted
blobs.

- **Local tables** `Groups` / `GroupMembers`; `Parties` gains a nullable `groupId` (real FK)
  and a `considered` flag; `PartyBallots` gains a nullable `memberId`.
- **The wire deltas are optional keys** in the party/ballot JSON (yellow paper §5.1):
  `group: {id, name}` (the manifest a joiner uses to create the group locally),
  `considered: bool` (travels in the party blob so guests seal too), and
  `member: {id, displayName?}` on ballots. Absent keys mean legacy anonymous; pre-group
  blobs decode unchanged. The codec never invents a manifest — encoding is driven only by
  an explicit argument, with the sync service doing the roster lookup.
- **Attribution:** `memberId` is the ghost `account_id` — stable per install, transmitted
  only inside AES-GCM blobs. Display name is user-entered and optional (declining is fine;
  you vote attributed-but-unnamed).
- **Roster propagation is gossip-via-ballots:** on every merge, `{memberId, displayName}`
  is upserted through the idempotent `addMember` (first display name wins). No roster blob,
  no reconciliation protocol.
- **Considered mode is UI gating:** `resultsSealed = considered ∧ ¬closed` hides tallies
  and shows only the who-has-voted count; the host's "Close voting" is the mutual reveal.
  It is a client-side courtesy, not cryptography — every key holder *can* decrypt every
  ballot (yellow paper §9).
- **A group-key namespace exists but is deliberately unpopulated** (`reckon.group_key.<id>`
  in the key store, tested). Its only honest consumer — a group-manifest blob on a relay —
  is deferred with relay deployment; a joiner cannot learn a group key from a party link,
  which carries per-party keys only.

**Alternatives rejected:** group-level relay namespaces (needs a relay deploy and a delta
protocol tonight); roster manifest blobs (reconciliation complexity gossip makes
unnecessary at household scale); cryptographic sealed-until-close (a commitment scheme —
real cost, no current threat model).

## Consequences

- **Positive:** households get named, persistent decision history and the blind-then-reveal
  move with **zero new relay surface** — Z holds verbatim and is pinned by a test (no group
  name, member id, or display name in relay bytes).
- **Anonymity model change (documented, deliberate):** the old "ballots are anonymous even
  to other voters" claim is now scoped to *ungrouped* parties. Grouped ballots are
  attributed by design and member ids are self-asserted — there is still no identity layer
  (yellow paper §9).
- **Deferred honestly:** group blobs on a relay / long-lived group keys in use; an offline
  re-push queue (a failed push saves locally and warns — nothing retries automatically);
  per-member calibration; names-who-voted in the sealed view (count only).
- **Constraint (do not break):** no plaintext group or member data may ever reach relay
  bytes, and the group row must be created before `importParty` (enforced FK).
