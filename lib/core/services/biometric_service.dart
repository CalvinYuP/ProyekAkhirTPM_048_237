// ignore_for_file: avoid_print

import 'package:local_auth/local_auth.dart';
import 'storage_service.dart';

class BiometricService {
  final LocalAuthentication _localAuth;
  final StorageService _storage;

  BiometricService(this._storage) : _localAuth = LocalAuthentication();

  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return <BiometricType>[];
    }
  }

  Future<bool> authenticate() async {
    try {
      // Cek apakah biometric tersedia
      final canAuthenticate = await _localAuth.canCheckBiometrics;
      if (!canAuthenticate) {
        print('❌ Biometric tidak tersedia di perangkat');
        return false;
      }

      // Cek jenis biometric yang tersedia
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        print('❌ Tidak ada biometric yang terdaftar');
        return false;
      }

      print('🔐 Memulai autentikasi biometric...');
      print('📱 Biometric tersedia: $availableBiometrics');

      // Lakukan autentikasi
      final bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Gunakan sidik jari untuk masuk ke Jogja EthnoTrip',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );
      
      if (authenticated) {
        print('✅ Autentikasi biometric berhasil');
        await _storage.setBiometricEnabled(true);
      } else {
        print('❌ Autentikasi biometric gagal');
      }
      
      return authenticated;
    } catch (e) {
      print('❌ Biometric auth error: $e');
      return false;
    }
  }

  Future<bool> isBiometricEnabled() async {
    return _storage.isBiometricEnabled();
  }

  Future<void> disableBiometric() async {
    await _storage.setBiometricEnabled(false);
    await _storage.clearBiometric();
  }
}