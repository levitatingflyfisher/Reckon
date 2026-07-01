# How to host a ReckonParty relay

The relay lets people join a ReckonParty from another device without an account. It is
**optional** — a party works completely offline by passing the phone around, and on a
shared network it syncs over the LAN with no server at all. You only need a relay for
*remote* participants.

The relay is **content-agnostic**: it stores and returns opaque, client-encrypted blobs
and never sees your options, ballots, or results (see
[ADR-0004](../adr/0004-reckonparty-zero-knowledge-sync.md) and the
[yellow paper](../spec/yellow-paper.md)). Hosting one grants you no visibility into any
party that uses it.

## Run it

The relay is a standalone Dart app in [`relay/`](../../relay/):

```bash
cd relay
dart pub get
dart run bin/server.dart              # listens on 0.0.0.0:8080
PORT=9000 dart run bin/server.dart    # custom port
```

Deploy it anywhere that runs a Dart binary — a small VPS, a container, Cloud Run, Fly.io.
No vendor lock-in, and no database required for a small instance. Put it behind HTTPS in
production (a reverse proxy is fine); the payloads are already encrypted, but TLS
protects the ids and metadata in transit.

## What it exposes

All blobs are opaque bytes; the server treats them as such. Full protocol in
[`relay/README.md`](../../relay/README.md):

| Method & path | Purpose |
|---|---|
| `GET /healthz` | Liveness check |
| `PUT /parties/{id}` | Publish/replace the encrypted party blob |
| `GET /parties/{id}` | Return the party + ballots (all base64 ciphertext); `404` if unknown |
| `PUT /parties/{id}/ballots/{ballotId}` | Append/replace an encrypted ballot; `409` if closed |
| `POST /parties/{id}/close` | Close voting |

Blobs are capped (256 KB server-side; the client also caps responses at 1 MB to reject
hostile/oversized bodies). Ballot ids are client-chosen and idempotent — re-submitting an
id overwrites, which is how a voter changes their mind.

## Durability

The bundled store is **in-memory**: simple, and fine for small/ephemeral use (parties
expire within a week regardless), but it loses data on restart. For a durable
deployment, implement [`BlobStore`](../../relay/lib/relay.dart) over a file, Redis, or
Postgres and pass it to `createRelayHandler`.

## Test it

```bash
cd relay && dart test
```

That spins the server up in-process and exercises the full protocol over real HTTP.
