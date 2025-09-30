import 'package:intl/intl.dart';

extension StringExtension on String? {
  String get toSnakeCase {
    if (this == null) return "";
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < this!.length; i++) {
      if (i == 0) {
        buffer.write(this![i].toLowerCase());
        continue;
      }
      bool uppercaseApplicable = this![i].toUpperCase() == this![i];
      buffer.write(uppercaseApplicable ? '_${this![i].toLowerCase()}' : this![i]);
    }
    return buffer.toString();
  }

  String get toPascalCase {
    if (this == null) return "";
    RegExp regex = RegExp(r'(?<=[a-zA-Z])[A-Z0-9]');
    String capWords = this!
        .replaceAllMapped(regex, (match) {
          return ' ${match.group(0)}';
        })
        .replaceAll("_", " ");
    return capWords
        .split(' ')
        .map((word) {
          return '${word[0].toUpperCase()}${word.substring(1)}';
        })
        .join(' ');
  }

  String get toCamelCase {
    if (this == null) return "";
    List<String> words = this!.split(RegExp(r'[_\s]'));
    if (words.isEmpty) return this!;
    words[0] = words[0].toLowerCase();
    for (int i = 1; i < words.length; i++) {
      words[i] = words[i][0].toUpperCase() + words[i].substring(1);
    }
    return words.join('');
  }

  DateTime? get toDateTime {
    if (this == null) return null;
    return DateTime.parse(this!);
  }

  String? toFormattedDateTime(String pattern) {
    if (toDateTime == null) return null;
    DateFormat format = DateFormat(pattern);
    return format.format(toDateTime!);
  }

  bool isInDate(String? date) {
    if (this == null || this!.isEmpty || date == null || date.isEmpty) {
      throw Exception("Could not parse date");
    }
    DateTime? thisTime = toDateTime;
    if (thisTime == null) throw Exception("Could not convert to date");
    DateTime beginning = DateTime(thisTime.year, thisTime.month, thisTime.day, 0, 0, 0, 0);
    DateTime end = DateTime(thisTime.year, thisTime.month, thisTime.day, 23, 59, 59, 999);
    DateTime? dateTime = date.toDateTime;
    if (dateTime == null) throw Exception("Could not convert target date");
    return dateTime.isAtSameMomentAs(thisTime) || (dateTime.isAfter(beginning) && dateTime.isBefore(end));
  }

  bool get isToday {
    if (this == null || this!.isEmpty) throw Exception("Value not found");
    DateTime? thisTime = toDateTime;
    if (thisTime == null) throw Exception("Could not convert date");
    DateTime beginning = DateTime(thisTime.year, thisTime.month, thisTime.day, 0, 0, 0, 0);
    DateTime end = DateTime(thisTime.year, thisTime.month, thisTime.day, 23, 59, 59, 999);
    return thisTime.isAtSameMomentAs(DateTime.now()) || (thisTime.isAfter(beginning) && thisTime.isBefore(end));
  }

  bool get isBeforeToday {
    if (this == null || this!.isEmpty) throw Exception("Value not found");
    DateTime? thisTime = toDateTime;
    if (thisTime == null) throw Exception("Could not convert date");
    DateTime beginning = DateTime(thisTime.year, thisTime.month, thisTime.day, 0, 0, 0, 0);
    return thisTime.isBefore(beginning);
  }

  bool get isAfterToday {
    if (this == null || this!.isEmpty) throw Exception("Value not found");
    DateTime? thisTime = toDateTime;
    if (thisTime == null) throw Exception("Could not convert date");
    DateTime end = DateTime(thisTime.year, thisTime.month, thisTime.day, 23, 59, 59, 999);
    return thisTime.isAfter(end);
  }

  bool dateBetween(String? startDate, String? endDate) {
    if (this == null || this!.isEmpty) throw Exception("Value not found");
    if (startDate == null || startDate.isEmpty) {
      throw Exception("Start date not found");
    }
    if (endDate == null || endDate.isEmpty) {
      throw Exception("End date not found");
    }
    DateTime? startTime = startDate.toDateTime;
    if (startTime == null) throw Exception("Could not convert start date");
    DateTime? endTime = endDate.toDateTime;
    if (endTime == null) throw Exception("Could not convert end date");
    DateTime beginning = DateTime(startTime.year, startTime.month, startTime.day, 0, 0, 0, 0);
    DateTime end = DateTime(endTime.year, endTime.month, endTime.day, 23, 59, 59, 999);
    DateTime? dateTime = this.toDateTime;
    if (dateTime == null) throw Exception("Could not convert date");
    return dateTime.isAfter(beginning) && dateTime.isBefore(end);
  }

  int get daysFromNow {
    DateTime? dateTime = toDateTime;
    if (dateTime == null) throw Exception("Could not convert date");
    DateTime now = DateTime.now();
    if (now.isAfter(dateTime)) return 0;
    return dateTime.difference(now).inDays;
  }
}
