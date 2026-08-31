import '../../../core/clock/chart_time_label.dart';

const inboxDateToday = 'Today';
const inboxDateYesterday = 'Yesterday';

/// Calendar bucket for activity rows. Uses UTC days so tests stay stable.
String inboxDateLabel(DateTime occurredAt, DateTime now) {
  final at = occurredAt.toUtc();
  final current = now.toUtc();
  final atDay = DateTime.utc(at.year, at.month, at.day);
  final currentDay = DateTime.utc(current.year, current.month, current.day);
  final days = currentDay.difference(atDay).inDays;
  if (days == 0) {
    return inboxDateToday;
  }
  if (days == 1) {
    return inboxDateYesterday;
  }
  return chartTimeLabel(occurredAt, includeTime: false);
}
