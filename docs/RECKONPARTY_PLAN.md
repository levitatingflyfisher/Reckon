# ReckonParty — Workflow Implementation Plan (Phase 3)

**Date:** 2026-06-12
**Status:** Stage 1 (domain + voting math) **done**. Local-first data layer
(Drift-backed `LocalPartyRepository`) **done** — a party now works fully
on-device with no server. Remaining: UI (Stage 2 surfaces) and the optional
sync relay (Stage 0, deliberately deferred).

## Architecture decision: local-first, server-optional

Recorded per project ethos (local-first, "an app is a homemade meal", FLOSS,
practical privacy). **ReckonParty works on-device first.** The unit of truth is
the on-device Drift database; a party is created, voted on (pass-the-phone /
same-room), and tallied with zero network. This is already implemented and
tested (`LocalPartyRepository`).

Any networked multi-device / no-account-web participation is a **strictly
optional enhancement**, and when built it MUST be:

- **Self-hostable and FLOSS** — a small relay anyone can run; no proprietary
  vendor lock-in. Cloudflare Workers/DO are an acceptable *default deployment*,
  not a requirement — the relay protocol stays portable (plain HTTP + WS).
- **Zero-knowledge / dumb** — the server stores and returns opaque ballots and
  never interprets decision content (matches the PRD addendum's encrypted blob
  relay stance).
- **Swappable behind `PartyRepository`** — a `SyncedPartyRepository` can wrap or
  replace `LocalPartyRepository` without touching UI or the voting usecases.

Net: we ship a genuinely useful ReckonParty with no backend at all, then add
optional sync for people who want remote participants.

## Why ReckonParty is different from everything built so far

Phase 1 is single-user, local-first, fully offline. ReckonParty is the opposite on every
axis: **multi-party, real-time, and usable with no account from a browser**. Web
participants have no app and no local Drift DB, and results must aggregate across devices.
So ReckonParty is the feature that forces Reckon's **first server**.

Its product job (PRD §3.2, §9.8) is top-of-funnel: someone receives a "where should we
eat?" link, uses it without an account, thinks "this is clean," and that becomes the
Reckon onramp. Fast, viral, resolves in minutes. Approval voting or ranked choice. No
rationales, no time-series, no calibration.

## Sync relay (optional, deferred — see decision above)

When/if remote participation is built, the candidates are **Cloudflare Durable Objects +
Workers** (one DO per party = live session state + WebSocket fan-out) or a simpler
**Worker + R2/KV with client polling**. Either is just a deployment of the portable,
self-hostable relay protocol; the local-first path never depends on it. The relay
**stores and returns opaque ballots** and never interprets decision content.

---

## Stages

### Stage 0 — Sync relay skeleton  ·  🟡 server done; client sync next
- ✅ **Reference relay server** (`relay/`): self-hostable, FLOSS, content-agnostic
  Dart `shelf` server. Stores/returns opaque encrypted blobs keyed by
  party/ballot id; endpoints `GET /healthz`, `PUT|GET /parties/{id}`,
  `PUT /parties/{id}/ballots/{ballotId}`, `POST /parties/{id}/close`; 256 KB
  blob cap; 8 in-process HTTP integration tests; covered by a CI job. Run with
  `dart run bin/server.dart` — deploy anywhere, no vendor.
- ✅ **Client sync core** (`lib/features/party/sync/`): on-device **AES-GCM**
  encryption (`PartyCrypto`), join links with the key in the URL fragment
  (`PartyJoinLink`), a `PartyRelay` client (`HttpPartyRelay` + in-memory fake),
  per-party key persistence (`PartyKeyStore`), and `PartySyncService`
  (`shareParty` / `joinParty` / `pushBallot` / `pull` / `closeSynced`) over the
  local store. 13 unit tests (incl. a two-device share→vote→tally simulation and
  a zero-knowledge assertion that the relay holds only ciphertext) + an
  in-process HTTP integration test of `HttpPartyRelay` against the real server.
- ✅ **Peer-to-peer transports** (`lib/features/party/sync/transport/`): the
  decision was P2P-first (LAN + Nearby now, WebRTC scaffolded, remote TBD). All
  P2P transports share one tested engine: the relay protocol over an abstract
  `DuplexChannel` (`ChannelPartyRelay` client + `ChannelRelayHost` host), so the
  full encrypted `PartySyncService` stack runs peer-to-peer with no server —
  proven by an in-memory two-device test. A `PartyTransport` abstraction unifies
  `CloudRelayTransport` (HTTP, done) and the channel-based `LanTransport` /
  `NearbyTransport` / `WebRtcTransport`.
  - ✅ **LAN transport is functional** (`lan_socket_channel.dart`,
    `lan_party_host.dart`): a length-framed TCP `DuplexChannel`, a
    `ServerSocket` host (`LanSocketHost` / `connectToLanHost`), and
    `LanPartyHost` serving every peer from one shared `PartyBlobStore` (so all
    guests see the same ballots). Verified end-to-end over **real loopback TCP**
    in the VM — framing, reassembly, full protocol, and multi-peer ballot
    propagation. Guests connect by host IP + port (share link / QR). 11 transport
    tests total. `dart:io` is confined to LAN-only files, so web builds are
    unaffected.
  - ⏭️ **Remaining backends are the on-device step** (can't run in this sandbox):
    mDNS auto-discovery for LAN (QR/manual-IP works without it), an Android
    Nearby Connections adapter, and an `RTCDataChannel` adapter for WebRTC — each
    a thin `DuplexChannel`/discovery adapter over the tested engine.
  - Known follow-up: `LanPartyHost._peers` isn't pruned on peer disconnect
    (negligible for short-lived parties; tidy when wiring lifecycle/UI).
  - ✅ **Transports wired into `PartySyncService`** (`party_relay_resolver.dart`,
    `lan_relay_resolver.dart`): `relayFor` is now an async, scheme-dispatched
    resolver with per-host relay caching (one LAN socket, reused) and a
    `dispose()` that releases sockets. `cloudRelayResolver` (web-safe) handles
    `http(s)://`; the mobile `lanAndCloudResolver` adds `lan://host:port`. Proven
    end-to-end over real TCP: two guests join a `LanPartyHost` by `lan://` link,
    one votes, the other tallies it (`lan_sync_integration_test`). The link
    format already carries the transport in its scheme — no link changes needed.
- ✅ **LAN UI shipped**: a **Join** screen (`/party/join`, paste a link →
  decrypt + import → vote) and an **Invite others (same Wi-Fi)** action on the
  result screen that hosts via `LanHostController`, shows a join **QR + link**
  (`qr_flutter`), and folds peer votes into the live tally. Host UI is
  platform-selected by conditional export (`party_host_action.dart`) — web gets
  a no-op stub since browsers can't host. The host data path + peer-vote merge
  are verified over real loopback TCP; the visual UX + real multi-device LAN
  want a device check.
- ✅ **Discovery seam** (`peer_discovery.dart`): `PeerDiscovery`
  (advertise/browse → `DiscoveredHost`) with a tested in-memory fake; mDNS and
  Nearby plug in here, with QR/link as the no-discovery fallback.
- ⏭️ **Device-only backends** (`backends_README.md`): mDNS auto-discovery
  (`nsd`/`bonsoir`), Nearby Connections, and WebRTC (`flutter_webrtc`) are thin
  `DuplexChannel`/`PeerDiscovery` adapters over the tested engine — wiring +
  device verification, not new protocol logic. Not added blind because they
  can't run/compile-verify in CI.
- ⏭️ **Web ballot page**: the no-account browser voting surface (cloud relay).
  - ✅ **Riverpod sync DI is in place** (`party_sync_providers.dart`):
    `partySyncServiceProvider` (auto-disposed, releases sockets),
    `partyKeyStoreProvider` (`SecurePartyKeyStore`), `partyRelayResolverProvider`
    (platform-selected via conditional import — web is cloud-only, native adds
    LAN), and `partyIsSyncedProvider`. Verified through the provider graph
    (join → imported into the resolved db). Screens can now `ref.read` the sync
    service directly.
  - Remaining UI is presentation that needs an app-run / device to verify
    visually, plus a QR package and LAN-IP discovery (`NetworkInterface`) for the
    host link.
- Remote (not-same-network) participation: decision deferred (LAN/Nearby cover
  in-person; cloud relay or WebRTC cover remote when chosen).
- Stand up a Worker exposing: `POST /party` (create), `GET /party/:id` (state),
  `POST /party/:id/ballot` (vote), `POST /party/:id/close`, and (DO option) a WebSocket
  for live tallies.
- Party auto-expires after **7 days** if not manually closed (PRD §9.8).
- Abuse controls: per-IP/token rate limits, max options (10), max participants.

### Stage 1 — Domain + voting math  ·  ✅ done (30 tests)
New `lib/features/party/` mirroring the existing clean-arch layout.
- Entities: `Party`, `PartyOption`, `Ballot` (approval set **or** ranked list),
  `PartyResult`.
- `PartyRepository` interface (impl in Stage 2 talks to the Worker).
- Usecases: `CreateParty`, `SubmitBallot`, `CloseParty`, `ComputeResult`.
- **Voting algorithms as pure functions:**
  - **Approval voting** — count approvals per option, sort, report percentages.
  - **Ranked choice (IRV)** — instant-runoff rounds with elimination + transfer; expose
    round-by-round results (the elimination story is good UX and good signal).
  - Tie-breaking rules made explicit and tested.
- This stage de-risks the hardest correctness surface with zero infra.

### Stage 1.5 — Local-first data layer  ·  ✅ done (6 tests)
Makes a party fully usable on one device, no server (the ethos decision above).
- Drift tables `parties` + `party_ballots` (schema v3, additive migration).
- `LocalPartyRepository implements PartyRepository` — create / get / submit
  ballot / close / `computeResult` (dispatches to the Stage-1 usecases);
  persisted ballots are re-validated through their factories on tally.
- `partyRepositoryProvider` (Riverpod) defaults to the local impl.

### Stage 2 — Create + participate + result UI  ·  ✅ done (local-first; 3 widget tests)
Shipped end-to-end on a single device: Home "Group decision" entry →
`PartyCreateScreen` (title, 2–10 options, approval/ranked) → `PartyVoteScreen`
(approval checkboxes / drag-to-rank, pass-the-phone) → `PartyResultScreen`
(approval %s or IRV round-by-round, share-as-text, close voting, "turn this
into a Reckon case" handoff). All against `LocalPartyRepository` — no network.
The no-account **web** participation surface remains deferred with the relay.

Original create-flow notes:
- Home entry point: "Group decision".
- Screen: name the choice, add 2–10 options, pick approval vs ranked → `CreateParty`
  → shareable link via native share sheet (`share_plus`, already a dependency).
- Target: 30 seconds end to end.

### Stage 3 — Participate flow (two surfaces, one logic core)
- **In-app:** open link → ballot screen → submit → live result.
- **Web, no account:** a lightweight web page served by the Worker so a recipient opens
  the URL in a browser, casts a ballot, and sees the distribution. Ends with the
  conversion CTA: *"This is Reckon. Want to make better decisions yourself?"*
- Reuse the Stage-1 voting logic on both surfaces.

### Stage 4 — Result + live updates
- Result screen: approval %s or IRV round-by-round; clustered-vs-bimodal read;
  **shareable as an image**; and a "turn this into a Reckon case" handoff into the
  existing intake flow when the group can't converge.
- Wire the WebSocket (DO option) so tallies update live; or poll on an interval.

### Stage 5 — Hardening
- Expiry sweeps, offline ballot queueing + sync, conversion-CTA analytics, moderation
  hooks (PRD open question §16.3), and load/abuse testing on the Worker.

---

## Sequencing notes
- **Stages 0–1 are independent** of the rest of the app and of the design-package fix —
  start there (voting math first).
- Shipping ReckonParty end-to-end was previously **blocked** behind the broken
  `openhearth_design` dependency (the app wouldn't build anywhere but the author's
  machine). That is now fixed, so the app builds in CI and for new contributors.
- ReckonParty shares the community server concern with the rest of Phase 3 — design the
  blob relay once and reuse it for community forecasting.

## Open questions to resolve before/while building
1. Cloudflare Durable Objects vs Worker+polling (latency/cost vs simplicity).
2. Same Play listing with a mode switch vs separate listing (PRD §16.2 recommends same
   listing, mode switch).
3. Community moderation policy (PRD §16.3) — needed before any public posting.
4. Web participation target: a Flutter web build of a thin ballot view, or a hand-written
   minimal HTML page served by the Worker (lighter, faster to load for a viral link).
