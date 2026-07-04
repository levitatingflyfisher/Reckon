# Limitations

Read before adopting. What Reckon does *not* do, and where the edges are. This is
deliberately honest — see the [vision scorecard](../VISION.md) for the built-vs-aspirational
split and [feature status](reference/feature-status.md) for the per-area detail.

## By design (these are features, not gaps)

- **It won't tell you what to decide.** Reckon is a protocol and a record, not an
  advisor. If you want a recommendation, this is the wrong tool.
- **It's slow on purpose.** The value comes from re-polling over days to weeks and
  resolving over weeks to years. There is no fast answer, and the record means little
  until several cases have *closed*.
- **No streaks, badges, feed, or social layer.** Engagement mechanics would corrupt the
  honesty of the mirror.

## Platform and reach

- **Android-only for the real experience.** The on-device model runs on Android's
  MediaPipe runtime (`flutter_gemma`), minSdk 24. There is no iOS build and only a web
  scaffold; neither can run the on-device path.
- **First use requires a model download.** Before intake or the reveal work, the chosen
  model must download — a few hundred MB (Gemma 3 1B) to ~4 GB (Phi-4 Mini) over HTTPS.
  It's resumable and recovers from a stale partial, but a new user on cellular will feel
  it. This is the first hard dependency the app has.
- **Release build is debug-signed** today. A real signing config is required before Play
  Store distribution; R8/minification is off (enabling it later needs MediaPipe
  keep-rules).

## Model quality

- **A small on-device model is a small model.** Intake can be terse; the outside-view
  summary and reveal observation are best-effort. Every LLM call degrades to a
  recoverable fallback (empty stream / canned text) rather than crashing, so a weak or
  failed generation shows up as a bland result, not an error screen.
- **The BYOK/Connected upgrade isn't wired yet.** The Anthropic backends are built and
  tested but nothing in the app instantiates them — there is no setting to switch to a
  cloud model, and no Connected proxy is deployed. Until that lands, you get on-device
  quality only.

## Data, accounts, and sync

- **Ghost has no sync and no recovery.** There is no account and no server for the core
  loop. Lose or wipe the device and the journal is gone. The `token` and `named` tiers
  are named in the code but not implemented.
- **The reference-class database is partial** — ~15 categories against a ~20 target, so
  the outside view thins out on decisions outside the seeded classes.
- **Calibration on sparse data is genuinely hard.** A household closes a handful of big
  cases a year. Clarity Score and calibration always report their **case count** so you
  can discount a confident-looking number built on two cases — but drawing a real
  conclusion about your judgment from a small sample is an open problem, not a solved
  one. Treat early numbers as suggestive, not diagnostic.

## ReckonParty (group mode)

- **The relay can't validate content** — it holds ciphertext by design, so integrity is
  the client's job (the client caps oversized/hostile responses). The bundled relay
  store is in-memory: fine for small, ephemeral parties, but it loses data on restart
  and parties expire within a week regardless. A durable deployment needs a real
  `BlobStore`.
- **Anyone with the join link can participate.** Access control *is* possession of the
  link (and the key in its fragment); there's no per-voter authentication.

## Not built

- **Community forecasting and AI seed bots** — the tables exist locally but the feature
  and any community server do not.
- **Voice input and a full PWA** were product goals; the on-device dependency and the
  Android-only runtime mean they are not delivered today.

If a limitation here surprises you against the code, the code wins — file it, because
the docs were written to match reality and reality moves.
