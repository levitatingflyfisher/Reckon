# Changelog

All notable changes to Reckon will be documented in this file.

## [Unreleased]

### Added
- Fleet conformance suite (`test/fleet_conformance_test.dart` via the
  shared `oh_fleet_conformance` package): Reckon's recorded posture —
  tokens style tier, exact four-permission Android surface, recorded
  tighter analyzer override, startup maintenance — plus committed size
  budgets in `budgets.json` (gzipped `main.dart.js` and arm64 APK,
  measured x 1.05).
- Snapshot vault ("Previous backups" on the backup settings section):
  every encrypted export and every restore leaves a stamped on-device
  snapshot (keep-10, pinnable) you can restore, pin or delete.
- Mandatory pre-restore snapshot: a restore refuses to run unless the
  current data was snapshotted (and the snapshot verified) first —
  restoring is now reversible.
- Preview before restore: the confirm dialog shows the backup's age and
  per-table row counts next to what's on the device now.
- Encrypted exports verify themselves by read-back before reporting
  success, and the backup envelope now carries a `createdAt` stamp —
  added additively to the shipped flat shape, so older backups still
  restore (their age falls back to the original `generatedAt` stamp)
  and older app versions still read new backups.
- Silent freshness snapshot on app boot when the newest one is older
  than 7 days.
- Plain-JSON export tile alongside the encrypted backup.

### Fixed
- A corrupt or hostile relay response to a party fetch (malformed JSON,
  wrong shape, invalid base64 blobs) now surfaces as the sync flow's
  normal transport failure instead of an unhandled decode error — the
  relay body is untrusted input (the join link picks the relay host).
- The same guard for the peer-to-peer path: a malformed peer snapshot
  over a LAN/Nearby/WebRTC channel (non-map snapshot, wrong field types,
  invalid base64 blobs) now surfaces as the channel flow's normal
  `StateError` instead of leaking a raw `TypeError`/`FormatException` —
  the peer device controls every byte of that snapshot.

### Changed
- De-forked the design package: the in-repo `packages/openhearth_design`
  reconstruction (whose every token had silently diverged from the shared
  `ohStyle` package) is deleted. Reckon's shipped look is unchanged —
  blessed as app identity in `lib/shared/theme/` (`ReckonTheme`,
  `ReckonAccents` ember hues, `ReckonPalette`/`ReckonRadii`/
  `ReckonTypography`), pinned by the golden sweeps. The canonical
  `../ohStyle/openhearth_design` sibling is now the declared dependency
  for future deliberate convergence.
- Backup envelope validation now goes through the shared
  `sanctuary_backup_ui` v0.2.0 helper; preview and restore share one
  validation gate, so the preview can never accept a file the restore
  would reject.

### Removed
- The unused `permission_handler` dependency. The notification-permission
  prompt goes through `flutter_local_notifications`'
  `requestNotificationsPermission()`; nothing imported the package.
- Unused flutter_gemma native families from the Android APK (image
  generator, vision-tasks base, gemma/gecko embedders, text chunker,
  RAG sqlite vector store — Reckon does text inference only, which loads
  just `libllm_inference_engine_jni.so`/`liblitertlm_jni.so`; verified
  against the plugin's 0.13.2 Kotlin source). Expected arm64 APK drop:
  ~85 MiB (~156 MB → ~70 MB). Excludes are a reversible `packaging`
  block in `android/app/build.gradle.kts`. On-device verification of a
  rebuilt APK (download a model, run a duel) is still pending — please
  smoke-test text inference on hardware before shipping this build.
