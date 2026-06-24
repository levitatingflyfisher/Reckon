/// Derives a stable notification ID from a case ID string and a slot index.
///
/// Android notification IDs are signed 32-bit Java ints. Dart's [String.hashCode]
/// can return values outside that range on 64-bit VMs, which wrap unpredictably
/// when crossed over the platform channel. Mask the hash to a positive 31-bit
/// space before adding the slot so IDs stay valid and don't alias to negative
/// values or collide with ordinary small integers.
///
/// Collisions are still possible across a large corpus of cases (birthday
/// problem at ~46k cases for 50% collision in 2^31), but until a persistent
/// case→notification mapping table exists, this mask keeps the common case
/// correct.
int notificationIdFor(String caseId, int slot) {
  const mask = 0x3FFFFFFF; // 30-bit positive space, leaves 2 bits of headroom
  return (caseId.hashCode & mask) + slot;
}

/// Slot number reserved for the single resolution check-in notification.
/// Large enough to sit outside the range any realistic repoll schedule
/// produces (see [kMaxRepollSlots]), so it never collides with a repoll id.
const int resolutionSlot = 10000;

/// Hard cap on repoll notifications per case. Android imposes per-app
/// alarm quotas (~500), and a five-year deadline with 5-day gaps could
/// otherwise produce ~350+ pending alarms from a single case.
const int kMaxRepollSlots = 30;
