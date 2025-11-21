import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CommaSeparatedFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final value = newValue.text.replaceAll(',', '');
    final number = int.tryParse(value);
    if (number == null) return oldValue;
    final newText = NumberFormat('#,###').format(number);
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class TimeTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.length > 4) {
      digitsOnly = digitsOnly.substring(0, 4);
    }

    String formatted = digitsOnly;
    if (digitsOnly.length >= 3) {
      formatted = '${digitsOnly.substring(0, 2)}:${digitsOnly.substring(2)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

extension IntSocialFormat on int {
  String get socialFormattedCount {
    if (this < 1000) {
      return toString();
    } else if (this < 1000000) {
      double value = this / 1000;
      return value % 1 == 0 ? '${value.toStringAsFixed(0)}k' : '${value.toStringAsFixed(1)}k';
    } else if (this < 1000000000) {
      double value = this / 1000000;
      return value % 1 == 0 ? '${value.toStringAsFixed(0)}M' : '${value.toStringAsFixed(1)}M';
    } else {
      double value = this / 1000000000;
      return value % 1 == 0 ? '${value.toStringAsFixed(0)}B' : '${value.toStringAsFixed(1)}B';
    }
  }
}
