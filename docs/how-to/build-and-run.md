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

CI (`.github/workflows/ci.yml`) runs analyze + test, a debug-APK smoke build, and the
relay suite on every push and PR.

## Build an APK

```bash
flutter build apk --debug         # what CI smoke-builds
flutter build apk --release       # NOTE: currently debug-signed (see below)
```

The release build is **debug-signed** today — fine for sideloading, **not** ready for
Play Store distribution. Wiring a real signing config (and MediaPipe keep-rules if you
enable R8/minify) is a prerequisite for release; see
[limitations](../limitations.md).

## Toolchain notes

- **`sqlite3` override.** `flutter_gemma` pulls `sqlite3 ^3.x` while `drift_dev` pins
  `^2.x`; `pubspec.yaml` has a `dependency_overrides: sqlite3: ^3.1.0` to unblock
  resolution. Leave it unless `build_runner` surfaces a real incompatibility.
- **Model files** land in the app documents directory as `.task` files; an interrupted
  download leaves a resumable `.part` (see
  [model architecture](../reference/model-architecture.md)).

## Enabling a cloud model (developer note)

The BYOK and Connected backends are implemented and unit-tested but **not wired into the
app** — there is no settings toggle and `llmServiceProvider` always returns the on-device
`PrivateModeImpl`. To experiment, construct `ByokModeImpl(apiKey: …)` (or
`ConnectedModeImpl(workerBaseUrl: …)`) and override `llmServiceProvider`. Never bake a
key into the binary or default users onto the cloud — that's a hard non-negotiable
([ADR-0002](../adr/0002-pluggable-llm-backends.md)).
