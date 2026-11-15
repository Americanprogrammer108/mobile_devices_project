DateTime? calculateExpiryReminder(
  DateTime? expirationDate, {
  int daysBefore = 3,
  DateTime? currentTime,
}) {
  if (expirationDate == null) return null;

  if (![1, 3, 7].contains(daysBefore)) {
    throw ArgumentError.value(daysBefore, 'daysBefore', 'Must be 1, 3, or 7');
  }

  final now = currentTime ?? DateTime.now();

  final expiryDay = DateTime(
    expirationDate.year,
    expirationDate.month,
    expirationDate.day,
  );

  final today = DateTime(now.year, now.month, now.day);

  // Do not schedule reminders for expired products.
  if (expiryDay.isBefore(today)) return null;

  // Schedule at 9:00 AM local time.
  final reminder = DateTime(
    expiryDay.year,
    expiryDay.month,
    expiryDay.day - daysBefore,
    9,
  );

  if (reminder.isAfter(now)) {
    return reminder;
  }

  // Reminder time has passed, but the product hasn't expired.
  return null;
}
