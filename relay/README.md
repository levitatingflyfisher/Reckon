# ReckonParty Sync Relay

An **optional**, **self-hostable**, **content-agnostic** relay that lets people
join a ReckonParty from another device without an account.

ReckonParty is local-first: a party works completely offline by passing the
phone around. This relay only matters when you want *remote* participants. It is
deliberately dumb — it stores and returns **opaque, client-encrypted blobs** and
never sees or interprets your options, ballots, or results.

## Run it

```sh
dart pub get
dart run bin/server.dart           # listens on 0.0.0.0:8080
PORT=9000 dart run bin/server.dart # custom port
```

Deploy it anywhere that runs a Dart binary (a $5 VPS, a container, Cloud Run,
Fly.io…). No vendor lock-in, no database required for a small instance.

> The bundled store is in-memory: simple and fine for small/ephemeral use
> (parties expire in a week regardless), but it loses data on restart. For a
> durable deployment, implement [`BlobStore`](lib/relay.dart) over a file,
> Redis, or Postgres and pass it to `createRelayHandler`.

## Privacy model (zero-knowledge by construction)

The relay handles **bytes**, not meaning:

- The client encrypts the party definition and every ballot **on-device** before
  upload. The symmetric key travels in the share link's URL **fragment**
  (`…/join/<id>#k=<key>`), which browsers never send to a server — so the relay
  receives ciphertext and the key never reaches it.
- The server stores those blobs keyed by ids the client picks and hands them
  back. It cannot tally, read options, or learn who voted what.
- A breach or subpoena of the relay yields opaque blobs and nothing else.

(The Flutter client's encryption + sync layer is the next increment;
this server is the content-agnostic substrate it targets.)

## HTTP protocol

All blobs are opaque bytes; the server treats them as such.

| Method & path | Purpose |
|---|---|
| `GET /healthz` | Liveness check. |
| `PUT /parties/{id}` | Publish/replace the (encrypted) party blob. |
| `GET /parties/{id}` | `{ "party": <b64>, "closed": bool, "ballots": { "<ballotId>": <b64> } }`; `404` if unknown. |
| `PUT /parties/{id}/ballots/{ballotId}` | Append/replace an (encrypted) ballot blob. `404` if party unknown, `409` if closed. |
| `POST /parties/{id}/close` | Close voting. `404` if unknown. |

Blobs are capped at 256 KB. Ballot ids are client-chosen and idempotent
(re-submitting the same id overwrites — e.g. a voter changing their mind).

## Tests

```sh
dart test
```

Spins the server up in-process and exercises the full protocol over real HTTP.
