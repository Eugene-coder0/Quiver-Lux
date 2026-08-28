import 'package:intl/intl.dart';

/// Formatting rules shared by every surface that displays money.
final nairaFormatter = NumberFormat.currency(
  locale: 'en_NG',
  symbol: '₦',
  decimalDigits: 0,
);

String formatNaira(num value) => nairaFormatter.format(value);
