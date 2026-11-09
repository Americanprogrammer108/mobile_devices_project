import '../models/pantry_item.dart';

// Items expiring within this many days count as "expiring soon"
const expiringSoonDays = 5;

//Short month names for formatDate
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/**
 * Days until the item expires. 0 = today, neg = already expired, null = no expiry date
 */
///
int? daysUntilExpiry(PantryItem item) {
  final expiry = item.expirationDate;
  if (expiry == null) return null;
  final now = DateTime.now();

  // Compare dates only, in UTC so daylight savings can't shift the result
  return DateTime.utc(
    expiry.year,
    expiry.month,
    expiry.day,
  ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
}

/**
 * Items that are expired or expire withing [expiringSoonDays] days.
 * Sorted soonest first
 */
///
List<PantryItem> expiringSooon(List<PantryItem> items) {
  final soon = items.where((item) {
    final days = daysUntilExpiry(item);
    return days != null && days <= expiringSoonDays;
  }).toList();
  soon.sort(compareByExpiry);
  return soon;
}

// Sort order: soonest expiry first, items with no date last
int compareByExpiry(PantryItem a, PantryItem b) {
  final aDays = daysUntilExpiry(a);
  final bDays = daysUntilExpiry(b);

  if (aDays == null) return bDays == null ? 0 : 1;
  if (bDays == null) return -1;

  return aDays.compareTo(bDays);
}

// Formats a date like "Dec 10, 2027"
String formatDate(DateTime date) =>
    '${_months[date.month - 1]} ${date.day}, ${date.year}';

// Shows quantity with its unit, like "500 g" or just a number if there is no unit
String quantityLabel(PantryItem item) =>
    item.unit.isEmpty ? '${item.quantity}' : '${item.quantity} ${item.unit}';

// Text for Home's expiry line
String expiresLabel(int days) {
  if (days < -1) return 'Expired ${-days} days ago';
  if (days == -1) return 'Expired yesterday';
  if (days == 0) return 'Expires today';
  if (days == 1) return 'Expires tomorrow';

  return 'Expires in $days days';
}
