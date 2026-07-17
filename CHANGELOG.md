# Changelog

All notable changes to Reckon will be documented in this file.

## [Unreleased]

### Added
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
