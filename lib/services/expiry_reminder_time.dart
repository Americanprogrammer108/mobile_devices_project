DateTime? calculateExpiryReminder(DateTime? expirationDate) {
  if (expirationDate == null) return null;

  final now = DateTime.now();

  final expiryDay = DateTime(
    expirationDate.year,
    expirationDate.month,
    expirationDate.day,
  );

  final today = DateTime(now.year, now.month, now.day);

  // Do not schedule reminders for expired items.
  if (expiryDay.isBefore(today)) return null;

  final reminder = DateTime(
    expiryDay.year,
    expiryDay.month,
    expiryDay.day - 1,
    9,
  );

  if (reminder.isAfter(now)) return reminder;

  // The normal reminder time has passed.
  return now.add(const Duration(minutes: 1));
}
