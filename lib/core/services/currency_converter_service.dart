// lib/core/services/currency_converter_service.dart
import 'package:dio/dio.dart';

class CurrencyConverterService {
  final Dio _dio = Dio();
  
  // ✅ Konversi mata uang menggunakan Frankfurter API
  Future<Map<String, dynamic>?> convertCurrency({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    try {
      final response = await _dio.get(
        'https://api.frankfurter.app/latest',
        queryParameters: {
          'from': fromCurrency,
          'to': toCurrency,
          'amount': amount,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'amount': amount,
          'from': fromCurrency,
          'to': toCurrency,
          'result': data['rates'][toCurrency],
          'rate': data['rates'][toCurrency],
          'date': data['date'],
        };
      }
      return null;
    } on DioException catch (e) {
      debugPrint('Error converting currency: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Unexpected error: $e');
      return null;
    }
  }

  // ✅ Get semua rates untuk satu currency
  Future<Map<String, double>?> getRates(String baseCurrency) async {
    try {
      final response = await _dio.get(
        'https://api.frankfurter.app/latest',
        queryParameters: {
          'from': baseCurrency,
          'to': 'USD,EUR,IDR,GBP,JPY,CNY,SGD,MYR,AUD,CAD',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['rates'] as Map<String, dynamic>;
        return data.map((key, value) => MapEntry(key, (value as num).toDouble()));
      }
      return null;
    } catch (e) {
      debugPrint('Error getting rates: $e');
      return null;
    }
  }
}

void debugPrint(String message) {
  // ignore: avoid_print
  print(message);
}