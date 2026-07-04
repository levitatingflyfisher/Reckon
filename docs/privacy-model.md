# Privacy model

Reckon holds a record of your most consequential decisions. This page says exactly what
does and does not leave your device, per mode and per backend, and how you can check it.
The short version: **in the default configuration, nothing about your decisions ever
leaves the device.**

## What Reckon stores, and where

| Data | Where it lives |
|---|---|
| Cases, polls, resolutions, outside views, the record | Local **Drift/SQLite** database on the device |
| Reference-class data, glossary | Bundled app assets, seeded into the local DB |
| Selected model id, HuggingFace token (if any), a future BYOK key | Device **secure storage** (`flutter_secure_storage`) |
| Downloaded model weights | The app's documents directory |

There is **no analytics SDK and no telemetry endpoint** in the app. There is nothing to
opt out of because there is nothing collecting.

## What crosses the network, per mode

### Ghost + on-device model (the default, and the only live configuration)

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

### BYOK (bring your own key) — built, not yet wired

When enabled, the LLM calls the **Anthropic Messages API directly** using **your own
key** (held in device secure storage). In this mode your case text — the intake
conversation, the outside-view prompt, the reveal series — is sent to Anthropic under
your account and **nowhere else**; the key goes only to `api.anthropic.com`. This is an
explicit, opt-in trade of some privacy for a stronger model. *Today no setting turns
this on — the backend exists and is tested but is not instantiated in the app.*

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
   transport — ciphertext only), and the cloud backends (`anthropic_client.dart`, which
   nothing instantiates yet). There is no analytics or telemetry module to find.
3. **Watch the traffic.** Proxy the device; in Ghost mode you'll see the one-time model
   fetch and, if you use ReckonParty remotely, opaque blobs — never decision plaintext.
