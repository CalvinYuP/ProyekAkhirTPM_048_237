// lib/core/constants/session_config.dart

class SessionConfig {
  // ✅ UBAH NILAI INI UNTUK DEMO:
  // Untuk produksi: Duration(hours: 24) atau Duration(days: 1)
  // Untuk demo: Duration(minutes: 5) atau Duration(minutes: 1)
  
  static const Duration sessionTimeout = Duration(minutes: 100); // 1 hari (produksi)
  // static const Duration sessionTimeout = Duration(minutes: 5); // 5 menit (demo)
  // static const Duration sessionTimeout = Duration(minutes: 1); // 1 menit (demo cepat)
  
  /// Nama box untuk menyimpan session
  static const String sessionBoxName = 'session_box';
  
  /// Key untuk menyimpan waktu login
  static const String loginTimeKey = 'loginTime';
  
  /// Key untuk menyimpan status login
  static const String isLoggedInKey = 'isLoggedIn';
  
  /// Key untuk menyimpan username
  static const String usernameKey = 'username';
}