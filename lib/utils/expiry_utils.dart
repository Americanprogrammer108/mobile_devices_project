import '../models/pantry_item.dart';

const expiringSoonDays = 5;

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'July', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

int? daysUntilExpiry(PantryItem item) {
  final expiry = item.expirationDate;
  if (expiry == null) return null;
  final now = DateTime.now();
  return DateTime.utc(expiry.year,expiry.month, expiry.day).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
}

List<PantryItem> expiringSooon(List<PantryItem> items) {
  final soon = items.where((item) {
    final days = daysUntilExpiry(item);
    return days != null && days <= expiringSoonDays;
  }).toList();
  soon.sort(compareByExpiry);
  return soon;
}

int compareByExpiry(PantryItem a, PantryItem b) {
  final aDays = daysUntilExpiry(a);
  final bDays = daysUntilExpiry(b);
  if(aDays == null) return bDays == null ? 0 : 1;
  if (bDays == null) return -1;
  return aDays.compareTo(bDays);
}

String formateDate(DateTime date) => 
'${_months[date.month - 1]} ${date.day}, ${date.year}';

String quantityLabel(PantryItem item) =>  
item.unit.isEmpty ? '${item.quantity}' : '${item.quantity} ${item.unit}';

String expiresLabel(int days) {
  if (days < -1) return 'Expired ${-days} days ago';
  if (days == -1) return 'Expired yesterday';
  if (days == 0) return 'Expires today';
  if (days == 1) return 'Expires tomorrow';

  return 'Expires in $days days';
}