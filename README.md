# Reckon

**A local-first personal decision journal for Android.** Reckon runs a structured
"inner-crowd" protocol over a real decision — and then keeps the record, so your own
track record can confront you.

> **Reckon does not tell you what to decide. It shows you what you already think —
> more clearly than you could see it alone, and across time.**

The whole loop runs **on your device**, with **no account** and a small **on-device
LLM** — free, private, offline. See [VISION.md](VISION.md) for the north star and
[docs/](docs/README.md) for the full documentation.

## What it does

You bring a real, consequential, slow decision — a career move, a big purchase, where
to live. Reckon walks it through a protocol drawn from superforecasting practice:

1. **Intake.** A conversational interview (run by the on-device model) turns your
   dilemma into a crisp two-option case with stated criteria, stakes, and a regret
   horizon.
2. **Blinded re-polls.** Over the following days or weeks, Reckon asks where you lean
   now — **without showing you your previous answers**, so anchoring can't quietly
   pull you back to yesterday's position.
3. **Outside view.** It pulls a base rate from a reference-class database and (with the
   model) synthesises an outside view, stratified by your profile.
4. **Reveal.** When you decide, it charts how your position actually drifted and offers
   a one-line observation about it.
5. **Resolution.** A delayed check-in asks how it turned out — and that answer feeds
   your longitudinal record.
6. **Record.** Your **Clarity Score**, calibration, personal base rates, and insight
   cards, computed honestly from your closed cases.

There is also **ReckonParty** — a fast group-decision mode (approval or ranked-choice
voting) that syncs over your LAN or an optional zero-knowledge relay, no account
required.

## Quickstart

Prerequisites: the [Flutter SDK](https://docs.flutter.dev/get-started/install)
(3.32+; CI builds on 3.44.x), and an Android device or emulator (minSdk 24).

```bash
git clone git@github.com:levitatingflyfisher/Reckon.git
cd Reckon
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # generate Drift/Riverpod code
flutter run                                                 # on an attached Android device
```

On first use, pick a model in onboarding and let it download (a few hundred MB to
~4 GB depending on the model — Wi-Fi recommended). After that, everything works
offline. Full instructions: [docs/how-to/build-and-run.md](docs/how-to/build-and-run.md).

## See the docs

- **[VISION.md](VISION.md)** — the one idea, the design commitments, an honest
  scorecard of what's built vs. aspirational.
- **[docs/](docs/README.md)** — the documentation hub (Diátaxis-organised):
  tutorials, how-to guides, reference, and explanation.
- **[docs/concepts.md](docs/concepts.md)** — the inner-crowd protocol explained.
- **[docs/privacy-model.md](docs/privacy-model.md)** — exactly what does and doesn't
  leave your device.
- **[AGENTS.md](AGENTS.md)** — if you're an agent or a contributor, read this first.
- **[CONTRIBUTING.md](CONTRIBUTING.md)** — how to file issues and open PRs.

## Tech

Flutter · Riverpod · Drift (SQLite) · `flutter_gemma` (MediaPipe on-device LLM) ·
`go_router` · `flutter_local_notifications`. Clean Architecture, feature-first.

## License

[MIT](LICENSE).
