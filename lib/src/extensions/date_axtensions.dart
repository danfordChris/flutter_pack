import 'package:intl/intl.dart';

extension DateExtension on DateTime? {
  ///TODO: Need to review for new logics

  String toFormat(String pattern) {
    if (this == null) return "";
    return DateFormat(pattern).format(this!);
  }

  int get daysInMonth {
    if (this == null) return 0;
    DateTime? start = _startOfMonth(this!.month);
    DateTime? end = _endOfMonth(this!.month);
    if (start == null || end == null) return 0;
    return end.difference(start).inDays;
  }

  DateTime? get startOfMonth => _startOfMonth(this?.month);

  DateTime? get endOfMonth => _endOfMonth(this?.month);

  DateTime? firstOfMonth(int month) => _startOfMonth(month);

  DateTime? lastOfMonth(int month) => _endOfMonth(month);

  DateTime? _startOfMonth(int? month) {
    if (this == null || month == null) return null;
    return DateTime(this!.year, month, 1, 0, 0, 0, 0);
  }

  DateTime? _endOfMonth(int? month) {
    if (this == null || month == null) return null;
    return DateTime(this!.year, month + 1, 1, 23, 59, 59, 999).subtract(Duration(days: 1));
  }

  DateTime? get startOfDay => _startOfDay(this?.day);

  DateTime? get endOfDay => _endOfDay(this?.day);

  DateTime? _startOfDay(int? day) {
    if (this == null || day == null) return null;
    return DateTime(this!.year, this!.month, day, 0, 0, 0, 0);
  }

  DateTime? _endOfDay(int? day) {
    if (this == null || day == null) return null;
    return DateTime(this!.year, this!.month, day, 23, 59, 59, 999);
  }

  DateTime? onDay(int? day) {
    if (this == null) return null;
    DateTime now = DateTime.now();
    return DateTime(this!.year, this!.month, day ?? now.day);
  }
}

extension TimeAgo on Object {
  String get timeAgo {
    DateTime? date;

    // Handle both DateTime and String types
    if (this is DateTime) {
      date = this as DateTime;
    } else if (this is String) {
      try {
        date = DateTime.parse(this as String);
      } catch (_) {
        return 'Invalid date';
      }
    } else {
      return 'Invalid type';
    }

    final Duration diff = DateTime.now().difference(date);

    if (diff.inSeconds < 0) return 'in the future';

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}hr ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()}w ago';
    } else if (diff.inDays < 365) {
      return '${(diff.inDays / 30).floor()}mo ago';
    } else {
      return '${(diff.inDays / 365).floor()}y ago';
    }
  }
}
