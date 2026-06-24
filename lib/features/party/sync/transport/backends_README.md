# Peer-to-peer transport backends

All P2P transports reuse one tested engine — the relay protocol over a
`DuplexChannel` (`ChannelPartyRelay` ⇄ `ChannelRelayHost`) — plus the
`PeerDiscovery` seam for finding hosts. A backend only has to provide a
`DuplexChannel` (and optionally a `PeerDiscovery`); nothing above it changes.

| Backend | Discovery | Channel | Status |
|---|---|---|---|
| **LAN** (same Wi-Fi) | `PeerDiscovery` (mDNS) / QR | `SocketDuplexChannel` (TCP) | ✅ data path done + tested over loopback; mDNS = drop-in below |
| **Nearby** (BT / Wi-Fi Direct) | Nearby Connections | wraps payload stream | ⏭️ device-only adapter |
| **WebRTC** (internet) | signaling rendezvous | `RTCDataChannel` | ⏭️ device-only adapter |

These three are **device-only**: they wrap platform plugins that cannot run or
be verified in CI/sandbox (no radio, no second device, no browser RTC). Each is
a thin adapter over the already-tested engine, so the work is wiring + a device
check, not new protocol logic.

## mDNS discovery (LAN auto-discovery)

Implement `PeerDiscovery` with a plugin such as [`nsd`] or [`bonsoir`]:

- `advertise(...)` → register a service of type `_reckonparty._tcp` on `port`,
  putting `partyId` in a TXT record.
- `browse()` → resolve discovered services into `DiscoveredHost(address, port,
  partyId)`.

Then point the LAN join flow at `DiscoveredHost.baseUrl` instead of a pasted
link. The manual QR/link path already works without this.

## Nearby Connections (Android-first)

Plugin: [`nearby_connections`]. Map its lifecycle onto the seams:

- Advertiser/discoverer ↔ `PeerDiscovery`.
- On a connected endpoint, wrap `sendBytesPayload` / the payload-received
  callback in a `DuplexChannel` (it is already message-oriented — no framing
  needed). Host attaches a `ChannelRelayHost`; joiner uses `ChannelPartyRelay`.

Manifest: `BLUETOOTH_*`, `ACCESS_FINE_LOCATION` (or `NEARBY_WIFI_DEVICES` on
API 33+), `ACCESS_WIFI_STATE`, `CHANGE_WIFI_STATE`; request at runtime.

## WebRTC (internet P2P, scaffolded for later)

Plugin: [`flutter_webrtc`]. Wrap an `RTCDataChannel` in a `DuplexChannel`
(`onMessage` → `incoming`, `send` → `channel.send`). Needs a small signaling
rendezvous (the existing relay can carry SDP/ICE) plus a STUN server, and a
TURN relay fallback for symmetric NATs.

[`nsd`]: https://pub.dev/packages/nsd
[`bonsoir`]: https://pub.dev/packages/bonsoir
[`nearby_connections`]: https://pub.dev/packages/nearby_connections
[`flutter_webrtc`]: https://pub.dev/packages/flutter_webrtc
