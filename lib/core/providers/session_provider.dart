import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import '../constants/session_config.dart';
import '../router/app_router.dart';
import '../../features/auth/providers/auth_provider.dart';

// ✅ PERBAIKAN 1: Tambahkan onDispose agar Timer benar-benar dihancurkan 
// saat pindah halaman/logout, mencegah Ghost Timer dan Memory Leak.
final sessionTimerProvider = Provider<SessionTimer>((ref) {
  final timer = SessionTimer(ref);
  ref.onDispose(() {
    timer.dispose();
  });
  return timer;
});

class SessionTimer {
  Timer? _timer;
  final StorageService _storageService = StorageService();
  final Ref _ref;
  bool _isNavigating = false;

  SessionTimer(this._ref);

  void startSessionCheck() {
    _timer?.cancel();
    _timer = null;
    _isNavigating = false;

    _timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _checkSession();
    });
  }

  void stopSessionCheck() {
    _timer?.cancel();
    _timer = null;
    _isNavigating = false;
  }

  void _checkSession() {
    if (_isNavigating) return;

    final isLoggedIn = _storageService.isLoggedIn();

    // ✅ PERBAIKAN 2: Jika user sudah tidak login (misal habis logout manual),
    // cukup matikan timer. JANGAN panggil _navigateToLogin() untuk memunculkan layar expired!
    if (!isLoggedIn) {
      _timer?.cancel();
      _timer = null;
      return; 
    }

    final isExpired = _storageService.isSessionExpired();

    if (isExpired) {
      _isNavigating = true;

      _storageService.clearSession();
      _timer?.cancel();
      _timer = null;

      try {
        _ref.read(authProvider.notifier).resetState();
      } catch (e) {
        // ignore
      }

      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    final navigator = rootNavigatorKey.currentState;

    if (navigator != null) {
      final timeoutMinutes = SessionConfig.sessionTimeout.inMinutes;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => SessionExpiredPage(timeoutMinutes: timeoutMinutes),
        ),
        (route) => false,
      );
    } else {
      try {
        appRouter.go('/auth');
      } catch (e) {
        // ignore
      }
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

class SessionExpiredPage extends StatefulWidget {
  final int timeoutMinutes;

  const SessionExpiredPage({super.key, required this.timeoutMinutes});

  @override
  State<SessionExpiredPage> createState() => _SessionExpiredPageState();
}

class _SessionExpiredPageState extends State<SessionExpiredPage> {
  bool _isNavigating = false;

  void _goToLogin() {
    if (_isNavigating) return;
    
    // ✅ PERBAIKAN 3: Bungkus dengan setState agar UI benar-benar merender animasi loading
    setState(() {
      _isNavigating = true;
    });

    try {
      appRouter.go('/auth');
    } catch (e) {
      // ✅ Matikan loading jika gagal
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Silakan buka ulang aplikasi untuk login kembali.'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
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
                'Sesi Anda telah berakhir setelah\n${widget.timeoutMinutes} menit tidak aktif.',
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
                style: TextStyle(fontSize: 13, color: Color(0xFF6B6B6B)),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isNavigating ? null : _goToLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC9A334),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isNavigating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Login Kembali',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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