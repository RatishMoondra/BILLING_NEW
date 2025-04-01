import 'package:intl/intl.dart';

class Formatter {
  

  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _timeFormat = DateFormat('hh:mm a');
  static final _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');

  static String formatCurrency(num amount, {String symbol = '₹'}) {
    final format = NumberFormat.currency(locale: 'en_IN', symbol: symbol);
    return format.format(amount);
  }

  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  static String formatTime(DateTime time) {
    return _timeFormat.format(time);
  }

  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }

  static String formatQuantity(int quantity) {
    return NumberFormat.decimalPattern().format(quantity);
  }

  static String formatPhoneNumber(String number) {
    if (number.length != 10) return number;
    return '${number.substring(0, 5)} ${number.substring(5)}';
  }
}
