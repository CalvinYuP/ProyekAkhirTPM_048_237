// lib/core/utils/currency_converter.dart
import 'package:intl/intl.dart';

class CurrencyConverter {
  // 🎴 KURS STATIS UNTUK PREVIEW CARD (tidak real-time, hanya untuk tampilan cepat)
  static const Map<String, double> previewRates = {
    'IDR': 1.0,
    'USD': 0.000064,
    'EUR': 0.000059,
    'MYR': 0.00030,
    'SGD': 0.000086,
  };

  // 💱 SIMBOL MATA UANG
  static const Map<String, String> symbols = {
    'IDR': 'Rp',
    'USD': '\$',
    'EUR': '€',
    'MYR': 'RM',
    'SGD': 'S\$',
  };

  // 🎴 METHOD KHUSUS CARD: Konversi + Format dengan kurs statis
  static String convertPreview(double amountInIDR, String targetCurrency) {
    final rate = previewRates[targetCurrency] ?? 1.0;
    final converted = amountInIDR * rate;
    return format(converted, targetCurrency);
  }

  // 🧮 FORMAT ANGKA SAJA (tanpa konversi)
  static String format(double amount, String currencyCode) {
    final symbol = symbols[currencyCode] ?? currencyCode;
    
    switch (currencyCode) {
      case 'IDR':
        return '$symbol ${NumberFormat('#,##0', 'id_ID').format(amount)}';
      case 'USD':
      case 'EUR':
      case 'MYR':
      case 'SGD':
        return '$symbol ${NumberFormat('#,##0.00', 'en_US').format(amount)}';
      default:
        return '$symbol ${NumberFormat('#,##0.00').format(amount)}';
    }
  }
}