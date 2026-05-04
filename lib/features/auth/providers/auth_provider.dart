import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/biometric_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());
final authServiceProvider = Provider<AuthService>((ref) => AuthService(ref.watch(storageServiceProvider)));
final biometricServiceProvider = Provider<BiometricService>((ref) => BiometricService(ref.watch(storageServiceProvider)));

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? username;
  final String? error;
  final String? sessionInfo;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.username,
    this.error,
    this.sessionInfo,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? username,
    String? error,
    String? sessionInfo,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      username: username ?? this.username,
      error: error,
      sessionInfo: sessionInfo ?? this.sessionInfo,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider), ref.watch(biometricServiceProvider));
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final BiometricService _biometricService;
  final StorageService _storageService = StorageService();

  AuthNotifier(this._authService, this._biometricService) : super(AuthState()) {
    checkSession();
  }

  Future<void> checkSession() async {
    print('🔍 Memeriksa session...');
    
    if (_authService.hasActiveSession()) {
      if (_storageService.isSessionExpired()) {
        print('⏰ Session expired, auto logout...');
        await _authService.logout();
        state = AuthState(error: 'Session telah berakhir. Silakan login kembali.');
        return;
      }
      
      final username = _authService.getCurrentUsername();
      final sessionInfo = _storageService.getSessionInfo();
      
      print('✅ Session valid: $sessionInfo');
      
      state = state.copyWith(
        isAuthenticated: true,
        username: username,
        sessionInfo: sessionInfo,
      );
    } else {
      print('❌ Tidak ada session aktif');
      state = AuthState();
    }
  }

  /// ✅ RESET STATE - Untuk session expired
  void resetState() {
    state = AuthState(error: 'Session telah berakhir. Silakan login kembali.');
    print('🔄 AuthState di-reset: isAuthenticated = false, error = "${state.error}"');
  }

  Future<bool> register(String username, String password, String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _authService.register(username, password, email);
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Registrasi gagal: ${e.toString()}');
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _authService.login(username, password);
      if (success) {
        print('✅ Login berhasil untuk: $username');
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          username: username,
          error: null,
          sessionInfo: _storageService.getSessionInfo(),
        );
      } else {
        state = state.copyWith(isLoading: false, error: 'Username atau password salah');
      }
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Login gagal');
      return false;
    }
  }

  Future<bool> loginWithBiometric() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      print('🔐 Memulai login biometric...');
      
      final canUseBiometric = await _biometricService.canCheckBiometrics();
      if (!canUseBiometric) {
        state = state.copyWith(isLoading: false, error: 'Biometric tidak tersedia di perangkat ini');
        return false;
      }

      final biometricUsername = _storageService.getBiometricUsername();
      
      if (biometricUsername == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Belum ada akun yang terdaftar untuk biometric. Silakan login dengan password terlebih dahulu.',
        );
        return false;
      }

      final userData = _storageService.getUser(biometricUsername);
      if (userData == null) {
        state = state.copyWith(isLoading: false, error: 'Akun tidak ditemukan');
        return false;
      }

      final success = await _biometricService.authenticate();
      
      if (success) {
        await _storageService.saveSession(biometricUsername);
        
        print('✅ Login biometric berhasil untuk: $biometricUsername');
        
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          username: biometricUsername,
          error: null,
          sessionInfo: _storageService.getSessionInfo(),
        );
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: 'Autentikasi sidik jari gagal. Coba lagi.');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Terjadi kesalahan: ${e.toString()}');
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = AuthState();
    print('🚪 User telah logout');
  }

  Future<bool> canUseBiometric() async => await _biometricService.canCheckBiometrics();
  
  String getSessionInfo() {
    return _storageService.getSessionInfo();
  }
}