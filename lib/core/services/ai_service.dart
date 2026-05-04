// lib/core/services/ai_service.dart
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  final Dio _dio;
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  
  AIService() : _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      // ✅ Ambil API Key dari .env
      'Authorization': 'Bearer ${dotenv.env['GROQ_API_KEY'] ?? ''}',
      'Content-Type': 'application/json',
    },
  ));

  Future<String> chat(String userMessage) async {
    try {
      final response = await _dio.post(
        _baseUrl,
        data: {
          'model': 'groq/compound',
          'messages': [
            {
              'role': 'system',
              'content': 'Kamu adalah pemandu wisata budaya Yogyakarta yang ramah dan ahli. Jawab pertanyaan seputar destinasi, sejarah, kuliner, adat istiadat, dan tips wisata di Yogyakarta. Gunakan bahasa Indonesia yang sopan, informatif, dan bersahabat. Maksimal 3-4 kalimat per jawaban. Jika pertanyaan tidak relevan, arahkan kembali ke topik wisata Yogyakarta.'
            },
            {
              'role': 'user',
              'content': userMessage,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 256,
        },
      );

      if (response.statusCode == 200) {
        final content = response.data['choices'][0]['message']['content'] as String;
        return content.trim();
      } else {
        return '⚠️ Error: Gagal terhubung ke AI (kode ${response.statusCode})';
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.receiveTimeout) {
        return '⏱️ Timeout: Koneksi lambat. Silakan coba lagi.';
      } else if (e.response?.statusCode == 401) {
        return '🔑 Error: API Key tidak valid. Periksa konfigurasi.';
      } else if (e.response?.statusCode == 429) {
        return '🔄 Rate limit: Terlalu banyak request. Tunggu sebentar.';
      }
      return '⚠️ Error: ${e.message ?? "Terjadi kesalahan"}';
    } catch (e) {
      return '⚠️ Error: Terjadi kesalahan tak terduga.';
    }
  }
}