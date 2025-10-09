import 'package:intl/intl.dart';

/// Formats a [date] string into 'MMM d, yyyy' format.
/// Returns '-' if [date] is null or empty.
/// Returns the original [date] if parsing fails.
String formatDate(String? date) {
  if (date == null || date.isEmpty) return '-';
  try {
    final parsedDate = DateTime.parse(date);
    return DateFormat('MMM d, yyyy').format(parsedDate);
  } catch (_) {
    return date;
  }
}
