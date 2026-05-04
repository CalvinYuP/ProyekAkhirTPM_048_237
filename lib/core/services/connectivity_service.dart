// lib/core/services/connectivity_service.dart
import 'package:dio/dio.dart';

class ConnectivityService {
  final Dio _dio = Dio();

  ConnectivityService() {
    // Set timeout singkat untuk pengecekan koneksi
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 5);
  }

  /// Mengecek apakah perangkat terhubung ke internet
  /// Mencoba ping ke beberapa server untuk memastikan koneksi
  Future<bool> isConnected() async {
    // Daftar URL yang akan di-ping
    final urls = [
      'https://www.google.com',
      'https://www.cloudflare.com',
      'https://api.frankfurter.app',
    ];

    for (final url in urls) {
      try {
        final response = await _dio.get(
          url,
          options: Options(
            validateStatus: (status) => true, // Terima semua status code
          ),
        );
        // Jika berhasil terhubung (status code 2xx atau 3xx)
        if (response.statusCode != null && response.statusCode! < 400) {
          return true;
        }
      } catch (e) {
        // Coba URL berikutnya
        continue;
      }
    }

    // Jika semua URL gagal, kemungkinan offline
    return false;
  }

  /// Mengecek koneksi dengan cepat (hanya 1 URL)
  Future<bool> quickCheck() async {
    try {
      final response = await _dio.get(
        'https://www.google.com',
        options: Options(
          validateStatus: (status) => true,
          receiveTimeout: const Duration(seconds: 3),
        ),
      );
      return response.statusCode != null && response.statusCode! < 400;
    } catch (e) {
      return false;
    }
  }
}