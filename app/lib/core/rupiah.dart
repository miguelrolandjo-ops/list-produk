import 'package:intl/intl.dart';

final _rupiah = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

/// `15000` -> `Rp 15.000`
String formatRupiah(int amount) => _rupiah.format(amount);
