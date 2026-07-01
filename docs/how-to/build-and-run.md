# How to build & run Reckon

Task-oriented. Assumes you know Flutter basics. For the *why* behind the stack, see the
[architecture overview](../architecture/OVERVIEW.md).

## Prerequisites

- **Flutter SDK 3.32+** (Dart 3.8+). CI builds on **Flutter 3.44.x** — match that if you
  hit a resolution error.
- **An Android device or emulator, minSdk 24** (a MediaPipe / `flutter_gemma`
  requirement). The on-device model does not run on iOS or web.
- **JDK 17** for the Android build (as CI uses).

## Set up and run

```bash
git clone git@github.com:levitatingflyfisher/Reckon.git
cd Reckon
flutter pub get

# Generate Drift + Riverpod code. app_database.g.dart is committed, but regenerate
# after any table/provider change:
dart run build_runner build --delete-conflicting-outputs

flutter run        # on an attached Android device/emulator
```

On first launch, onboarding asks you to choose an auth mode (Ghost is the live one),
pick a model, and download it. Prefer Wi-Fi — the download is a few hundred MB (Gemma 3
1B) to ~4 GB (Phi-4 Mini). Once downloaded, the app runs fully offline.

## Verify your change

```bash
flutter analyze     # must report zero issues
flutter test        # the full suite — unit, widget, golden
```

Golden (visual) tests live in `test/visual/`. If you intentionally change UI, update
goldens with `flutter test --update-goldens` and review the diffs.

The ReckonParty relay is a separate Dart package with its own suite:

```bash
cd relay && dart pub get && dart analyze && dart test
```

CI (`.github/workflows/ci.yml`) runs analyze + test, a debug-APK smoke build, a
web-release smoke build (with the deploy's `--base-href`, so the 8 web/native
conditional-import trios stay honest), and the relay suite on every push and PR.

## Build an APK

```bash
flutter build apk --debug         # what CI smoke-builds
flutter build apk --release       # NOTE: currently debug-signed (see below)
```

The release build is **debug-signed** today — fine for sideloading, **not** ready for
Play Store distribution. Wiring a real signing config (and MediaPipe keep-rules if you
enable R8/minify) is a prerequisite for release; see
[limitations](../limitations.md).

## Build & deploy the web PWA

The PWA is served from this repo's `gh-pages` branch at
`https://levitatingflyfisher.github.io/Reckon/`. The journal runs on drift-wasm; the
on-device model does not run on web (the duel via BYOK / OpenAI-compatible forecasters
is the web build's one AI path).

```bash
flutter build web --release --base-href /Reckon/
```

- **`--base-href /Reckon/` is not optional.** The site lives under a `/Reckon/` path,
  and a build without it 404s every asset once deployed — the app serves `index.html`
  and then never boots. (This exact regression took the live PWA down on 2026-07-10;
  CI now smoke-builds with the flag.)
- **The drift worker is compiled, not copied.** `web/drift_worker.js` is compiled from
  `web/drift_worker.dart` against this project's exact `drift`/`sqlite3` versions —
  the prebuilt worker from a drift release bundles a different sqlite3 and fails at
  runtime with `LinkError … Import "dart" "localtime"`. After bumping `drift` or
  `sqlite3`, recompile:

  ```bash
  dart compile js -O2 -o web/drift_worker.js web/drift_worker.dart
  ```

- **Don't touch `web/index.html` casually** — it carries the boot spinner, the
  service-worker self-heal, and the `navigator.storage.persist()` call that keeps a
  PWA's local journal from being evicted.

Deploy is a manual rsync of the build onto `gh-pages` (never mix it into `master`):

```bash
git fetch origin gh-pages
git worktree add /tmp/ghp-Reckon gh-pages
rsync -a --delete --exclude='.git' build/web/ /tmp/ghp-Reckon/
touch /tmp/ghp-Reckon/.nojekyll
cd /tmp/ghp-Reckon && git add -A && git commit -m "deploy: Reckon web PWA" \
  && git push origin HEAD:gh-pages
cd - && git worktree remove /tmp/ghp-Reckon
```

**Verify the deploy with a headless boot probe** — an HTTP 200 is not a booted app (a
missing base-href still serves `index.html` perfectly while the app never starts).
Load the live URL in a headless browser and wait for Flutter's render root:

```js
// node probe.mjs  (npm i playwright)
import { chromium } from 'playwright';
const browser = await chromium.launch();
const page = await browser.newPage();
await page.goto('https://levitatingflyfisher.github.io/Reckon/',
    { waitUntil: 'domcontentloaded' });
await page.waitForSelector('flt-glass-pane, flutter-view',
    { timeout: 30000, state: 'attached' });   // throws = NO-BOOT
console.log('BOOTED');
await browser.close();
```

## Toolchain notes

- **`sqlite3` override.** `flutter_gemma` pulls `sqlite3 ^3.x` while `drift_dev` pins
  `^2.x`; `pubspec.yaml` has a `dependency_overrides: sqlite3: ^3.1.0` to unblock
  resolution. Leave it unless `build_runner` surfaces a real incompatibility.
- **Model files** land in the app documents directory as `.task` files; an interrupted
  download leaves a resumable `.part` (see
  [model architecture](../reference/model-architecture.md)).

## Enabling a cloud model

**In the duel (user-facing, live):** store your Anthropic key in Settings and add a
BYOK forecaster, or add an OpenAI-compatible forecaster pointing at a llamafile/Ollama
`base_url`. Cloud backends run *only* there, per-forecaster
([ADR-0007](../adr/0007-forecaster-duel-alignment-scoring.md)).

**For the core loop (developer note):** intake/outside-view/reveal have no cloud
switch — `llmServiceProvider` always returns the on-device `PrivateModeImpl`. To
experiment, construct `ByokModeImpl(apiKey: …)` (or
`ConnectedModeImpl(workerBaseUrl: …)`) and override `llmServiceProvider`. Never bake a
key into the binary or default users onto the cloud — that's a hard non-negotiable
([ADR-0002](../adr/0002-pluggable-llm-backends.md)).
