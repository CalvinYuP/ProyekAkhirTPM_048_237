import 'package:hive_flutter/hive_flutter.dart';
import '../constants/session_config.dart';

class StorageService {
  static const String userBoxName = 'user_box';
  static const String biometricBoxName = 'biometric_box';

  Future<void> init() async {
    await Hive.initFlutter();
    
    final boxesToOpen = [
      userBoxName,
      SessionConfig.sessionBoxName,
      biometricBoxName,
      'favorites',
      'notifications',
      'reminders',
      'feedback',
      'game_scores',
      'currency_cache',
      'settings',
      'user_profile',
    ];
    
    for (final boxName in boxesToOpen) {
      if (!Hive.isBoxOpen(boxName)) {
        await Hive.openBox(boxName);
      }
    }
  }

  // ==================== USER BOX ====================
  Box get userBox => Hive.box(userBoxName);
  
  Future<void> saveUser(String username, String passwordHash, String email) async {
    await userBox.put(username, {
      'username': username,
      'password': passwordHash,
      'email': email,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Map? getUser(String username) {
    return userBox.get(username);
  }

  // ==================== SESSION BOX ====================
  Box get sessionBox => Hive.box(SessionConfig.sessionBoxName);
  
  /// Menyimpan session setelah login berhasil
  Future<void> saveSession(String username) async {
    final now = DateTime.now();
    
    await sessionBox.put(SessionConfig.isLoggedInKey, true);
    await sessionBox.put(SessionConfig.usernameKey, username);
    await sessionBox.put(SessionConfig.loginTimeKey, now.toIso8601String());
    
    // ✅ Debug print
    print('✅ Session disimpan untuk: $username');
    print('⏰ Waktu login: $now');
    print('⏱️ Session timeout: ${SessionConfig.sessionTimeout.inMinutes} menit');
    print('🔴 Akan expired pada: ${now.add(SessionConfig.sessionTimeout)}');
    
    await saveBiometricUsername(username);
  }

  /// Menghapus session (logout)
  Future<void> clearSession() async {
    print('🚪 Session dihapus (logout)');
    await sessionBox.clear();
  }

  /// Mengecek apakah user masih login
  bool isLoggedIn() {
    return sessionBox.get(SessionConfig.isLoggedInKey, defaultValue: false);
  }

  /// Mendapatkan username yang sedang login
  String? getUsername() {
    return sessionBox.get(SessionConfig.usernameKey);
  }

  /// ✅ MENGECEK APAKAH SESSION SUDAH EXPIRED
  bool isSessionExpired() {
    final isLoggedIn = sessionBox.get(SessionConfig.isLoggedInKey, defaultValue: false);
    if (!isLoggedIn) return true; // Tidak ada session = expired
    
    final loginTimeStr = sessionBox.get(SessionConfig.loginTimeKey);
    if (loginTimeStr == null) return true; // Tidak ada waktu login = expired
    
    final loginTime = DateTime.tryParse(loginTimeStr);
    if (loginTime == null) return true; // Format tidak valid = expired
    
    final now = DateTime.now();
    final expiryTime = loginTime.add(SessionConfig.sessionTimeout);
    final isExpired = now.isAfter(expiryTime);
    
    // ✅ Debug print
    if (isExpired) {
      print('❌ Session EXPIRED!');
      print('   Login: $loginTime');
      print('   Expiry: $expiryTime');
      print('   Now: $now');
      print('   Selisih: ${now.difference(expiryTime).inMinutes} menit setelah expiry');
    } else {
      final remaining = expiryTime.difference(now);
      print('✅ Session masih aktif');
      print('   Sisa waktu: ${remaining.inHours} jam ${remaining.inMinutes.remainder(60)} menit');
    }
    
    return isExpired;
  }

  /// ✅ Mendapatkan sisa waktu session
  Duration? getSessionRemainingTime() {
    final loginTimeStr = sessionBox.get(SessionConfig.loginTimeKey);
    if (loginTimeStr == null) return null;
    
    final loginTime = DateTime.tryParse(loginTimeStr);
    if (loginTime == null) return null;
    
    final expiryTime = loginTime.add(SessionConfig.sessionTimeout);
    final now = DateTime.now();
    
    if (now.isAfter(expiryTime)) return Duration.zero;
    return expiryTime.difference(now);
  }

  /// ✅ Mendapatkan info session dalam format string
  String getSessionInfo() {
    if (!isLoggedIn()) return 'Tidak ada session aktif';
    
    final username = getUsername();
    final remaining = getSessionRemainingTime();
    
    if (remaining == null) return 'Session tidak valid';
    if (remaining == Duration.zero) return 'Session sudah expired';
    
    return 'User: $username | Sisa: ${remaining.inHours}j ${remaining.inMinutes.remainder(60)}m';
  }

  // ✅ HELPER: Username yang sedang login
  String? get currentUsername {
    return sessionBox.get(SessionConfig.usernameKey);
  }

  // ==================== BIOMETRIC BOX ====================
  Box get biometricBox => Hive.box(biometricBoxName);

  Future<void> saveBiometricUsername(String username) async {
    await biometricBox.put('biometric_username', username);
    await biometricBox.put('biometric_enabled', true);
  }

  String? getBiometricUsername() {
    final enabled = biometricBox.get('biometric_enabled', defaultValue: false);
    if (enabled == true) {
      return biometricBox.get('biometric_username');
    }
    return null;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await biometricBox.put('biometric_enabled', enabled);
    if (!enabled) {
      await biometricBox.delete('biometric_username');
    }
  }

  bool isBiometricEnabled() {
    return biometricBox.get('biometric_enabled', defaultValue: false);
  }

  Future<void> clearBiometric() async {
    await biometricBox.clear();
  }
}