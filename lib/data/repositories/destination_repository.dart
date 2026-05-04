// lib/data/repositories/destination_repository.dart
import 'package:flutter/services.dart' show rootBundle;
// import 'package:dio/dio.dart'; // ← DIKOMENTARI/DIHAPUS: Tidak dipakai untuk load lokal

import '../models/destination_model.dart';

class DestinationRepository {
  // final Dio _dio; // ← DIKOMENTARI/DIHAPUS: Tidak dipakai untuk load lokal
  final String _mockApiUrl = 'assets/data/destinations.json';

  // Constructor disesuaikan (tidak perlu Dio)
  DestinationRepository(); 
  // Jika ingin tetap fleksibel untuk nanti: 
  // DestinationRepository([Dio? dio]) { if (dio != null) _dio = dio; }

  // Load dari file JSON lokal (mock API)
  Future<List<Destination>> getDestinations() async {
    try {
      // Load string dari assets
      final String jsonString = await rootBundle.loadString(_mockApiUrl);
      // Parsing JSON ditangani oleh method di Model
      return Destination.fromJsonList(jsonString);
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error loading destinations: $e');
      return [];
    }
  }

  // Filter berdasarkan kategori
  List<Destination> filterByCategory(List<Destination> destinations, String category) {
    if (category == 'Semua') return destinations;
    return destinations.where((d) => d.category == category).toList();
  }

  // Search berdasarkan nama, deskripsi, atau kategori
  List<Destination> searchDestinations(List<Destination> destinations, String query) {
    if (query.isEmpty) return destinations;
    final lowerQuery = query.toLowerCase();
    return destinations.where((d) =>
        d.name.toLowerCase().contains(lowerQuery) ||
        d.description.toLowerCase().contains(lowerQuery) ||
        d.category.toLowerCase().contains(lowerQuery)
    ).toList();
  }
}