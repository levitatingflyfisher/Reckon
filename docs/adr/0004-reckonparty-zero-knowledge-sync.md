# ADR-0004 — ReckonParty sync is zero-knowledge: encrypted blobs, key in the fragment

**Status:** Accepted (implemented: crypto, relay client, self-hostable server, LAN transport).

## Context

ReckonParty lets a group vote (approval or ranked-choice) on a shared question. It must
work with **no account** and, when participants aren't in the same room, sync across
devices. The easy path — a BaaS with a database of votes — would give the server plaintext
access to who voted for what, exactly the thing a "converge without politics" tool must
not leak, and exactly the BaaS dependency the OpenHearth ethos rejects.

## Decision

**Sync opaque, client-encrypted blobs through a dumb relay; keep the key off the wire.**

- Encrypt the party definition and every ballot **on-device** with **AES-GCM-256**
  (`party_crypto.dart`), producing a self-contained blob (`nonce ‖ ciphertext ‖ mac`).
- The symmetric key travels only in the **join link's URL fragment**
  (`…/join/<id>#k=<key>`, `party_link.dart`). Browsers never transmit fragments, so the
  key never reaches the relay.
- The **relay** (`relay/`, a standalone Dart + shelf server; client in `party_relay.dart`)
  is content-agnostic: it stores blobs keyed by client-chosen ids and hands them back.
  It cannot read options, tally votes, or learn who voted what. Ballot ids are
  idempotent (re-submit to change a vote); blobs are size-capped; parties expire.
- For same-network use, skip the relay entirely: **LAN transport** advertises and
  discovers peers via mDNS/DNS-SD and syncs over a socket channel
  (`sync/transport/`). Tallies are computed locally by pure usecases.

## Consequences

- **Positive:** A breach or subpoena of the relay yields ciphertext and nothing else —
  zero-knowledge *by construction*, not by policy.
- **Positive:** The relay is trivially self-hostable (a `$5` VPS, a container, Cloud
  Run) with no vendor lock-in and no database required for small instances.
- **Positive:** LAN mode needs no server at all.
- **Cost:** No server-side validation of blobs (it can't read them), so integrity is
  the client's job; the client caps relay responses to reject hostile/oversized bodies.
- **Constraint:** The key must **never** move into the path/query, and no plaintext
  field may be added to a relay payload. The relay stays content-agnostic. Formalised
  in the [yellow paper](../spec/yellow-paper.md).
