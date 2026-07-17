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

### Changed
- Backup envelope validation now goes through the shared
  `sanctuary_backup_ui` v0.2.0 helper; preview and restore share one
  validation gate, so the preview can never accept a file the restore
  would reject.
