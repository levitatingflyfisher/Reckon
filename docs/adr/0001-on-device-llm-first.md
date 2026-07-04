# ADR-0001 — On-device LLM first: free, private, offline by default

**Status:** Accepted (implemented; the live backend is on-device).

## Context

Reckon's language work — interviewing the user into a crisp case, synthesising an
outside view, observing how a position drifted — needs an LLM. The obvious default is
a cloud API. But Reckon's whole premise is a **private** journal of a household's most
consequential decisions (career, health, where to live). Sending that text to a
third-party server by default contradicts the product. A cloud default also means a
running API bill, an account, and a network dependency for the core loop.

The alternative — run a small model **on the device** — became viable on Android via
MediaPipe's GenAI runtime, exposed through the `flutter_gemma` plugin, with quantised
1–4B models that fit in phone RAM.

## Decision

**The default and only live LLM backend is on-device.** `PrivateModeImpl` runs the
selected model through `flutter_gemma`; the app ships no key and makes no LLM network
call. Model weights download once over HTTPS on first use, then the loop is fully
offline. The user can pick among several models (Gemma 3 1B, Qwen 2.5 1.5B, Phi-4
Mini) trading size for reasoning quality. minSdk is 24 (a MediaPipe requirement).

## Consequences

- **Positive:** No account, no bill, no telemetry surface, and nothing leaves the
  device for core use. The privacy story is architectural, not a promise.
- **Positive:** Works on a plane, in a clinic waiting room, anywhere — offline.
- **Cost:** A small on-device model is weaker than a frontier cloud model; intake and
  the reveal observation must be robust to terse or imperfect output (hence the
  recoverable-sentinel error policy, and the BYOK upgrade path in
  [ADR-0002](0002-pluggable-llm-backends.md)).
- **Cost:** First use hits a hundreds-of-MB-to-~4GB download — the first hard
  dependency a new user meets. It is made **resumable and 416-recovering**, but the UX
  of that gate matters (see [limitations](../limitations.md)).
- **Constraint:** The differentiating experience is **Android-only** — iOS/web cannot
  run the MediaPipe on-device path today.
