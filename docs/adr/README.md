# Architecture Decision Records

Load-bearing decisions, in the lightweight [Nygard format](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)
(Status · Context · Decision · Consequences). Read one before you re-litigate the
trade-off it settles.

| # | Decision |
|---|---|
| [0001](0001-on-device-llm-first.md) | On-device LLM first — free, private, offline by default |
| [0002](0002-pluggable-llm-backends.md) | One `LlmService` interface, three interchangeable backends (on-device / BYOK / Connected) |
| [0003](0003-local-first-ghost-tier.md) | Local-first, Ghost tier — no account, no server for core use |
| [0004](0004-reckonparty-zero-knowledge-sync.md) | ReckonParty sync is zero-knowledge — encrypted blobs, key in the URL fragment, no BaaS |
| [0005](0005-flutter-clean-architecture.md) | Flutter Clean Architecture with Riverpod and Drift |
| [0006](0006-honest-record-blinded-repolls.md) | Keep the record honest — computed-on-query calibration and blinded re-polls |
