class NumberFormatter {
  /// Converts English digits (0-9) to Persian digits (۰-۹)
  static String convertToPersianNumber(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

    for (int i = 0; i < english.length; i++) {
      input = input.replaceAll(english[i], persian[i]);
    }

    return input;
  }

  /// Converts a number to Persian digit string
  static String toPersian(num number) {
    return convertToPersianNumber(number.toString());
  }

  /// Formats a price with Persian digits and separators
  static String formatPersianPrice(double price) {
    // Format with 2 decimal places
    String formatted = price.toStringAsFixed(2);

    // Add thousand separators
    final parts = formatted.split('.');
    final wholePart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '';

    // Add thousand separators to the whole part
    final chars = wholePart.split('');
    String result = '';

    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && (chars.length - i) % 3 == 0) {
        result += ',';
      }
      result += chars[i];
    }

    // Reassemble the number
    if (decimalPart.isNotEmpty) {
      result += '.$decimalPart';
    }

    // Convert to Persian digits
    return convertToPersianNumber(result);
  }

  /// Format Persian price with currency symbol
  static String formatPersianCurrency(double price, {String symbol = '\$'}) {
    return symbol + formatPersianPrice(price);
  }

  /// Converts Persian digits (۰-۹) to English digits (0-9)
  static String convertToEnglishNumber(String input) {
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

    for (int i = 0; i < persian.length; i++) {
      input = input.replaceAll(persian[i], english[i]);
    }

    return input;
  }
}
