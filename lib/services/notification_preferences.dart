class NotificationPreferences {
  const NotificationPreferences({
    this.expirationWarnings = true,
    this.daysBeforeExpiry = 3,
  });

  final bool expirationWarnings;
  final int daysBeforeExpiry;

  factory NotificationPreferences.fromMap(Map<String, dynamic>? data) {
    final rawDays = data?['daysBeforeExpiry'];

    return NotificationPreferences(
      expirationWarnings: data?['expirationWarnings'] is bool
          ? data!['expirationWarnings'] as bool
          : true,
      daysBeforeExpiry: rawDays is int && [1, 3, 7].contains(rawDays)
          ? rawDays
          : 3,
    );
  }

  Map<String, dynamic> toMap() => {
    'expirationWarnings': expirationWarnings,
    'daysBeforeExpiry': daysBeforeExpiry,
  };

  NotificationPreferences copyWith({
    bool? expirationWarnings,
    int? daysBeforeExpiry,
  }) {
    return NotificationPreferences(
      expirationWarnings: expirationWarnings ?? this.expirationWarnings,
      daysBeforeExpiry: daysBeforeExpiry ?? this.daysBeforeExpiry,
    );
  }
}
