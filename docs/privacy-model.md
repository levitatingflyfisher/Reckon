# Privacy model

Reckon holds a record of your most consequential decisions. This page says exactly what
does and does not leave your device, per mode and per backend, and how you can check it.
The short version: **in the default configuration, nothing about your decisions ever
leaves the device.**

## What Reckon stores, and where

| Data | Where it lives |
|---|---|
| Cases, polls, resolutions, outside views, forecaster roster + predictions, groups, the record | Local **Drift/SQLite** database on the device |
| Reference-class data, glossary | Bundled app assets, seeded into the local DB |
| Selected model id, HuggingFace token (if any), the BYOK Anthropic key (if you added one), ReckonParty keys | Device **secure storage** (`flutter_secure_storage`) |
| Downloaded model weights | The app's documents directory |

There is **no analytics SDK and no telemetry endpoint** in the app. There is nothing to
opt out of because there is nothing collecting.

## What crosses the network, per mode

### Ghost + on-device model (the default)

The complete decision loop — intake, re-polls, outside view, reveal, resolution, record
— runs **entirely on-device**. The model does the language work locally. The **only**
network request Reckon makes in this mode is:

- **Downloading the model weights**, once, over HTTPS from a public model host
  (HuggingFace). The request carries no decision content — it's a file fetch. A
  HuggingFace token is sent only if you chose a *gated* model that needs one (the
  default models are ungated and need no token). After the download, you can run the
  entire app in airplane mode.

Your decisions are never transmitted anywhere in this configuration. A breach or
subpoena of any server reveals nothing, because Reckon isn't talking to one.

### The duel's cloud forecasters — opt-in, per-forecaster

The forecaster duel is the one place a cloud model can run, and only for forecasters
**you created**:

- **BYOK (bring your own key).** If you store your own Anthropic key (Settings) and add
  a BYOK forecaster, running a duel sends **that case's decision brief** (question,
  options, criteria, stakes) to the **Anthropic Messages API** under your account and
  nowhere else; the key (secure storage, `reckon.anthropic_api_key`) goes only to
  `api.anthropic.com`. An explicit, opt-in trade of some privacy for a stronger
  forecaster.
- **OpenAI-compatible endpoints.** A forecaster can point at any
  `/v1/chat/completions` endpoint **you configure** — typically a llamafile or Ollama
  on your own machine, which keeps everything on your LAN. The case brief goes to that
  base URL and nowhere else. (On Android, platform-level cleartext is pinned to
  loopback addresses; see `network_security_config.xml`.)

With no key stored and no endpoint configured, a duel runs entirely on-device (persona
forecasters) — the default configuration sends nothing.

**The core loop stays on-device regardless.** Intake, the outside view, and the reveal
have no cloud switch: the built-and-tested BYOK wrapper for the *loop* is still not
instantiated anywhere.

### Connected (proxy) — built, not deployed

Routes the same Messages-API calls through a proxy (a Cloudflare Worker) that holds a
key server-side, so the user never sees it. Same data-exposure shape as BYOK, plus the
proxy operator. *No proxy is deployed and nothing in the app instantiates this backend.*

### ReckonParty sync — opt-in, and zero-knowledge

Group voting is local-first: over the LAN it uses **no server at all** (mDNS/DNS-SD peer
discovery + a socket channel). For remote participants it uses an **optional relay** that
sees only **ciphertext**:

- The party definition and every ballot are encrypted **on-device** with **AES-GCM-256**
  before upload.
- The decryption key travels **only in the join link's URL fragment** (`…/join/<id>#k=<key>`).
  Browsers never send fragments to servers, so the key never reaches the relay.
- The relay stores and returns opaque blobs keyed by client-chosen ids. It cannot read
  options, tally votes, or learn who voted what. A breach or subpoena of it yields
  ciphertext and nothing else.

The relay is optional and self-hostable — you can run your own (see
[how-to/host-a-relay.md](how-to/host-a-relay.md)). Details and the formal statement are
in [ADR-0004](adr/0004-reckonparty-zero-knowledge-sync.md) and the
[yellow paper](spec/yellow-paper.md).

**Groups change what your *peers* see, not what the relay sees.** A group decision's
ballots carry your member id and display name — *inside* the encrypted blob, visible to
the people you're deciding with (that's the point) and to no server. A test pins that no
group name, member id, or display name ever appears in relay bytes. One-shot parties
stay anonymous even to other voters.

### Bounty export/import — files only; the app transmits nothing

"Ask outside bots" ([ADR-0009](adr/0009-bounty-client-paste-import.md)) adds **no
network caller**. Exporting composes a de-identified request *file*: the rewrite is
drafted on-device, **always** shown in an editable preview ("check it reads like a
stranger wrote it"), and leaves the device only when *you* share or copy it — the system
share sheet or clipboard is the transport, and you choose the destination. Importing is
pasting response JSON into a text field. The de-identification is a small model's draft
plus your review; treat the preview as the guarantee, not the model.

### Encrypted backup — files only; the key never leaves the device

Settings → **Encrypted Backup** produces a `.ohbk` file: your cases, polls, outside
views, resolutions, and profile, encrypted with a key derived from a **12-word recovery
phrase generated on-device**. Reckon transmits nothing to make this backup — you choose
where the file goes (the system share sheet), exactly like the plaintext exports.

What the honesty copy in-app says plainly, and this page repeats for the record:

- **The recovery words are the only way to decrypt the backup.** Reckon stores no
  copy anywhere else — no server, no account, no "forgot your words?" recovery.
  Lose them and lose the backup; the app can't help.
- **Restore is destructive.** It replaces every case, poll, outside view, resolution,
  and model prediction currently on the device with the contents of the backup file,
  inside a single transaction — never a partial restore. The confirm dialog states
  this before it happens.
- **It is not a ReckonParty join link.** A join link shares one decision's key with
  someone else you're deciding with; a recovery phrase recovers *your* backup on a
  *new device*. The two live in visibly separate settings sections so they're never
  confused.
- **What it does *not* cover:** the ReckonParty forecaster roster, groups, and any
  in-flight party data are not part of this backup — those are a separate,
  ephemeral, link-carried key system (`features/party/sync/party_crypto.dart`,
  AES-GCM-256) with nothing in common with a durable single-user backup, and are left
  untouched by both export and restore.
- **A wrong phrase fails closed with a specific, calm message** — never a silent
  partial restore. The blob's ChaCha20-Poly1305 authentication tag alone rules out a
  tampered or foreign file before any data is touched.

## Android permissions, and why

| Permission | Why |
|---|---|
| `INTERNET` | Model download; ReckonParty sync (LAN + relay); BYOK/Connected when enabled |
| `POST_NOTIFICATIONS` | Re-poll and resolution reminders |
| `RECEIVE_BOOT_COMPLETED` | Re-schedule those reminders after a reboot |
| `SCHEDULE_EXACT_ALARM` | Declared, but scheduling currently uses inexact alarms — this permission is effectively unused and is a candidate for removal (see [limitations](limitations.md)) |

Notifications are written to **keep private case details off the lockscreen and history**
— the reminder tells you a case needs attention without leaking what it's about.

## How to verify these claims

Reckon is FLOSS — you don't have to take this page's word for it:

1. **Airplane-mode test.** Download a model on Wi-Fi, then enable airplane mode and run a
   full case end to end. It works; nothing is being sent.
2. **Read the code.** The only network callers are `model_download_service.dart` (the
   HTTPS weight download), the ReckonParty sync layer (`party_relay.dart` / the LAN
   transport — ciphertext only), and the duel's per-forecaster backends
   (`anthropic_client.dart`, instantiated only when *you* stored a key and added a BYOK
   forecaster; `openai_compat_client.dart`, only against a base URL *you* configured;
   `connected_mode_impl.dart`, which nothing instantiates). The bounty feature has no
   network code at all. There is no analytics or telemetry module to find.
3. **Watch the traffic.** Proxy the device; in Ghost mode you'll see the one-time model
   fetch and, if you use ReckonParty remotely, opaque blobs — never decision plaintext.
   Run a duel with only persona forecasters and you'll see nothing at all.
