import 'package:intl/intl.dart';

extension DateTimeX on DateTime {
  DateTime get dateOnly => DateTime(year, month, day);

  bool get isToday => dateOnly == DateTime.now().dateOnly;

  bool isSameDay(DateTime other) => dateOnly == other.dateOnly;

  String get dayKey => DateFormat('yyyy-MM-dd').format(this);

  String get friendlyDay {
    final today = DateTime.now().dateOnly;
    final d = dateOnly;
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('EEE, d MMM').format(this);
  }

  String get timeLabel => DateFormat('HH:mm').format(this);
}

extension NumX on num {
  String get compact => NumberFormat.compact().format(this);

  String toKcal() => '${round()} kcal';

  String trimZeros([int decimals = 1]) {
    final s = toStringAsFixed(decimals);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }
}

extension StringX on String {
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
