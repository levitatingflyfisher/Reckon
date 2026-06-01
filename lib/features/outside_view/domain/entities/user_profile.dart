class UserProfile {
  const UserProfile({
    this.sesBracket,
    this.religiosity,
    this.relationshipStatus,
  });

  final String? sesBracket;
  final String? religiosity;
  final String? relationshipStatus;

  bool get hasAny =>
      sesBracket != null || religiosity != null || relationshipStatus != null;
}
