# ReckonParty persistent groups — doc deltas for the docs pass

Working notes from the groups build (2026-07-11), written for whoever updates
`docs/spec/yellow-paper.md`, `docs/adr/`, and the reference docs next. Every
claim below is pinned by a test named alongside it. Delete this file once its
substance has been lifted into the real docs.

## 1. What shipped

- **Sync wiring fix** (pre-groups, load-bearing): the vote screen now pushes
  ballots for shared/joined parties, the result screen pulls (open / manual /
  5s periodic), and Close voting routes through `closeSynced`, so a close
  reaches the relay. Before this, `pushBallot`/`pull` had zero UI callers —
  ADR-0004's "implemented" claim was true only of the service layer. Tests:
  `party_vote_screen_test`, `party_result_screen_test`,
  `lan_sync_integration_test` ("the UI-path service sequence…").
- **Persistent groups**: `Groups`/`GroupMembers` tables (schema v5), `Group` /
  `GroupMember` entities, `GroupRepository` (idempotent createGroup/addMember
  doors), screens `/groups`, `/groups/create`, `/group/:id`, and group-scoped
  party creation (`/party/create?groupId=`).
- **Attributed ballots**: `Ballot.memberId` (nullable) — the voter's ghost
  account id (`reckon.account_id`). Group decisions attribute; one-shot
  parties stay anonymous.
- **Considered mode**: `Party.considered` + `Party.resultsSealed`
  (= considered && !closed). Sealed = who-has-voted count only, no tallies,
  no share affordance; "Close voting and reveal" is the mutual reveal.
- **Group-key namespace**: `PartyKeyStore.putGroup/getGroup` under
  `reckon.group_key.<groupId>` (`PartySyncInfo` shape). A tested seam with —
  deliberately — no population flow yet; see §5.

## 2. Wire-shape changes (PartyCodec — yellow paper §3/§5 must be updated)

All new keys are optional; blobs written before groups decode unchanged
(pinned by the "legacy…" tests in `party_codec_test.dart`).

party JSON += 
  `considered: bool` (absent = false)
  `group: {id, name}` — the manifest a joiner uses to `createGroup` locally
  under the original id. Encoding is driven ONLY by the explicit manifest
  argument (the codec never invents one); the sync service/LAN host look the
  name up in `GroupRepository` and share ungrouped if the group is unknown.

ballot JSON +=
  `member: {id, displayName?}` — id comes from `Ballot.memberId`, displayName
  from the sender's roster at encode time.

Join order matters: the group row is created BEFORE `importParty` because
`parties.group_id` is a real foreign key (`PRAGMA foreign_keys = ON`).

## 3. Anonymity model change (yellow paper §5/§8 + ADR-0004 delta)

- **Unchanged — Z-property:** the relay stores ciphertext only. New test
  ("the relay sees no group name, member id, or display name",
  `party_sync_service_test.dart`) pins that group names, member ids, and
  display names never appear in relay bytes.
- **Changed — peer-facing anonymity:** original party ballots were anonymous
  even to other voters. Group-decision ballots are attributed BY DESIGN
  (a household deciding together wants names on votes). The docs' "no
  per-voter identity anywhere" statement is now scoped to ungrouped parties.
- **Roster gossip:** attributed ballots double as roster propagation — on
  merge, `{memberId, displayName}` is upserted via the idempotent `addMember`
  (first display name wins). No separate roster blob exists, so there is no
  roster-reconciliation protocol to specify.
- **Considered mode is a client-side courtesy, not cryptography:** every key
  holder can decrypt every ballot the moment it lands; `resultsSealed` gates
  what the UI shows, not what keys unlock. Say this plainly in the yellow
  paper. (A commitment-scheme upgrade is possible later if it ever matters.)

## 4. Identity

- Member id = the ghost `reckon.account_id` uuid — stable per device/install,
  never leaves the device except inside encrypted ballots.
- Display name is the first user-entered identity in the app. Entered at
  group creation or at first join of a grouped decision (declining is fine —
  you vote attributed-but-unnamed). Stored locally in `GroupMembers`,
  transmitted only inside AES-GCM blobs.

## 5. Deliberately deferred (say so honestly in the scorecard)

- **Group blobs on a relay / long-lived group keys in use** — deferred with
  relay deployment (roadmap §3.3). The `reckon.group_key.<id>` namespace
  exists and is tested; nothing writes it yet because its only honest
  consumer (a group-manifest blob) doesn't exist and a joiner cannot learn a
  group key from a party link (links carry per-party keys only).
- **Offline push queue** — a failed vote push saves locally and warns
  ("Saved on this device…"); nothing re-pushes automatically later.
- **Per-member calibration, group-level resolutions** — roadmap-deferred.
- **Names-who-voted in the sealed view** — count only for now.

## 6. ADR sketch (for ADR-0008)

Title: persistent groups + attributed ballots + considered mode.
Decision: groups are a local-first container over the existing per-party sync
(one manifest inside the party blob; no group protocol, no roster blob, no
new relay ops — the relay is untouched). Attribution rides the ballot wire
shape. Considered mode is UI gating on a `considered` flag that travels in
the party blob so guests seal too. Alternatives rejected: group-level relay
namespaces (needs relay deploy + delta protocol), roster manifest blobs
(reconciliation complexity; gossip-via-ballots is enough for households),
cryptographic sealed-until-close (commitment schemes — real cost, no current
threat model).
