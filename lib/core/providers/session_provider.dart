// lib/core/providers/session_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import '../constants/session_config.dart';
import '../router/app_router.dart';
import '../../features/auth/providers/auth_provider.dart'; // ✅ Import authProvider

/// Provider untuk session timer
final sessionTimerProvider = Provider.autoDispose<SessionTimer>((ref) {
  return SessionTimer(ref);
});

class SessionTimer {
  Timer? _timer;
  final StorageService _storageService = StorageService();
  final Ref _ref;

  SessionTimer(this._ref);

  /// Mulai timer
  void startSessionCheck() {
    _timer?.cancel();
    // Cek setiap 15 detik
    _timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _checkSession();
    });
    print('⏰ Session timer dimulai (cek setiap 15 detik)');
    print('⏱️ Session timeout: ${SessionConfig.sessionTimeout.inMinutes} menit');
  }

  /// Hentikan timer
  void stopSessionCheck() {
    _timer?.cancel();
    print('⏰ Session timer dihentikan');
  }

  /// Cek session
  void _checkSession() {
    final isLoggedIn = _storageService.isLoggedIn();
    print('🔍 Cek session: isLoggedIn=$isLoggedIn');
    
    final isExpired = _storageService.isSessionExpired();
    
    if (!isLoggedIn) {
      print('❌ Tidak ada session!');
      _timer?.cancel();
      _navigateToLogin();
      return;
    }
    
    if (isExpired) {
      print('❌ Session EXPIRED!');
      
      // 1. Hapus Hive
      _storageService.clearSession();
      print('   Hive session dihapus');
      
      // 2. Stop timer
      _timer?.cancel();
      
      // 3. ✅ RESET AUTH STATE RIVERPOD
      try {
        _ref.read(authProvider.notifier).resetState();
        print('   AuthState Riverpod di-reset');
      } catch (e) {
        print('   ❌ Gagal reset AuthState: $e');
      }
      
      // 4. Navigasi ke login
      _navigateToLogin();
    } else {
      final remaining = _storageService.getSessionRemainingTime();
      if (remaining != null) {
        print('✅ Session aktif - Sisa: ${remaining.inMinutes}m ${remaining.inSeconds.remainder(60)}s');
      }
    }
  }

  /// Navigasi ke login
  void _navigateToLogin() {
    print('🔄 Mencoba navigasi ke login...');
    
    final navigator = rootNavigatorKey.currentState;
    print('   rootNavigatorKey.currentState = $navigator');
    
    if (navigator != null) {
      print('   Menggunakan Navigator.pushAndRemoveUntil');
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SessionExpiredPage()),
        (route) => false,
      );
    } else {
      print('   Navigator null, mencoba GoRouter...');
      try {
        appRouter.go('/auth');
      } catch (e) {
        print('   ❌ Gagal navigasi: $e');
      }
    }
  }
}

/// Halaman session expired
class SessionExpiredPage extends StatefulWidget {
  const SessionExpiredPage({super.key});

  @override
  State<SessionExpiredPage> createState() => _SessionExpiredPageState();
}

class _SessionExpiredPageState extends State<SessionExpiredPage> {
  @override
  void initState() {
    super.initState();
    print('📄 SessionExpiredPage ditampilkan');
    
    // Auto redirect setelah 1.5 detik
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        print('🔄 Auto-redirect ke /auth...');
        appRouter.go('/auth');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFAF5),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.timer_off_rounded,
                  color: Colors.orange,
                  size: 64,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Sesi Berakhir',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sesi Anda telah berakhir setelah\n${SessionConfig.sessionTimeout.inMinutes} menit tidak aktif.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Silakan login kembali untuk melanjutkan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B6B6B),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    print('👆 Tombol Login Kembali ditekan');
                    appRouter.go('/auth');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC9A334),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Login Kembali',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}