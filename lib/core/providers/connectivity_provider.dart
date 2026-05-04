// lib/core/providers/connectivity_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/connectivity_service.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final connectivityProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(connectivityServiceProvider);
  return await service.isConnected();
});