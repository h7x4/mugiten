DateTime roundToDay(final DateTime date) =>
    DateTime(date.year, date.month, date.day);

bool dateIsEqual(final DateTime date1, final DateTime date2) =>
    roundToDay(date1) == roundToDay(date2);

DateTime get today => roundToDay(DateTime.now());
DateTime get yesterday =>
    roundToDay(DateTime.now().subtract(const Duration(days: 1)));

String formatTime(final DateTime timestamp) {
  final hours = timestamp.hour.toString().padLeft(2, '0');
  final mins = timestamp.minute.toString().padLeft(2, '0');
  return '$hours:$mins';
}

String formatDate(final DateTime date) {
  if (date == today) return 'Today';
  if (date == yesterday) return 'Yesterday';

  const List<String> monthTable = [
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

  final int day = date.day;
  final String month = monthTable[date.month - 1];
  final int year = date.year;
  return '$day. $month $year';
}
