// lib/core/services/currency_service.dart
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart'; // Untuk debug print

class CurrencyService {
  final Dio _dio = Dio();
  static const String _cacheBoxName = 'currency_cache';
  static const String _cacheKeyRates = 'rates';
  static const String _cacheKeyTimestamp = 'timestamp';
  static const int _cacheDurationHours = 24;

  // Mendapatkan kurs dari API atau Cache
  Future<Map<String, double>> getRates() async {
    Box box = await Hive.openBox(_cacheBoxName);
    
    // 1. Cek Cache
    if (_isCacheValid(box)) {
      debugPrint('💱 Menggunakan kurs dari Cache');
      return Map<String, double>.from(box.get(_cacheKeyRates) ?? {});
    }

    // 2. Fetch dari API Frankfurter (Base IDR)
    debugPrint(' Mengambil kurs dari Frankfurter API...');
    try {
      final response = await _dio.get(
        'https://api.frankfurter.app/latest',
        queryParameters: {
          'from': 'IDR',
          'to': 'USD,EUR,MYR,SGD',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['rates'] as Map<String, dynamic>;
        final rates = data.map((key, value) => MapEntry(key, (value as num).toDouble()));
        
        // Tambahkan IDR sendiri (1:1)
        rates['IDR'] = 1.0;

        // 3. Simpan ke Cache
        await box.put(_cacheKeyRates, rates);
        await box.put(_cacheKeyTimestamp, DateTime.now().toIso8601String());
        
        return rates;
      } else {
        throw Exception('API Error');
      }
    } catch (e) {
      debugPrint('❌ Gagal ambil API, pakai cache lama atau default.');
      // Fallback ke cache lama jika ada, atau kembalikan map kosong
      return Map<String, double>.from(box.get(_cacheKeyRates) ?? {'IDR': 1.0});
    }
  }

  bool _isCacheValid(Box box) {
    final timestamp = box.get(_cacheKeyTimestamp);
    if (timestamp == null) return false;
    
    final cacheTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    return now.difference(cacheTime).inHours < _cacheDurationHours;
  }
}