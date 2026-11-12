import 'package:intl/intl.dart';

class FormatService {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String rupiah(dynamic amount) {
    if (amount == null) return 'Rp 0';
    final val = double.tryParse(amount.toString()) ?? 0.0;
    return _currencyFormat.format(val);
  }

  static String date(dynamic date) {
    if (date == null) return '-';
    if (date is DateTime) {
      return DateFormat('dd MMM yyyy').format(date);
    }
    final parsed = DateTime.tryParse(date.toString());
    if (parsed == null) return date.toString();
    return DateFormat('dd MMM yyyy').format(parsed);
  }

  static String dateTime(dynamic date) {
    if (date == null) return '-';
    if (date is DateTime) {
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    }
    final parsed = DateTime.tryParse(date.toString());
    if (parsed == null) return date.toString();
    return DateFormat('dd MMM yyyy, HH:mm').format(parsed);
  }
}
