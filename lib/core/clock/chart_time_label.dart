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

/// UTC timestamp for chart scrub labels. No [double], no `intl`.
String chartTimeLabel(DateTime at, {required bool includeTime}) {
  final t = at.toUtc();
  final date = '${_months[t.month - 1]} ${t.day}, ${t.year}';
  if (!includeTime) {
    return date;
  }
  final hour = t.hour.toString().padLeft(2, '0');
  final minute = t.minute.toString().padLeft(2, '0');
  return '$date $hour:$minute';
}
