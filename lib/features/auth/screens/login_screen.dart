// lib/features/auth/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/session_config.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _canBiometric = false;
  bool _hasBiometricUser = false;
  bool _sessionExpired = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
    _checkSessionExpired();
  }

  Future<void> _checkBiometric() async {
    try {
      final canUse = await ref.read(biometricServiceProvider).canCheckBiometrics();
      
      final storageService = ref.read(storageServiceProvider);
      final biometricUsername = storageService.getBiometricUsername();
      
      if (!mounted) return;
      setState(() {
        _canBiometric = canUse;
        _hasBiometricUser = biometricUsername != null;
      });
      
      print('🔐 Biometric available: $canUse, Has user: $_hasBiometricUser');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _canBiometric = false;
        _hasBiometricUser = false;
      });
    }
  }

  void _checkSessionExpired() {
    final authState = ref.read(authProvider);
    print('🔍 LoginScreen: authState.isAuthenticated=${authState.isAuthenticated}, error=${authState.error}');
    
    if (authState.error != null && 
        authState.error!.contains('Session telah berakhir')) {
      setState(() => _sessionExpired = true);
      
      // Reset error setelah ditampilkan
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _sessionExpired = false);
        }
      });
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    CustomDialog.showLoading(context);
    
    final success = await ref.read(authProvider.notifier).login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    CustomDialog.hideLoading(context);

    if (success) {
      setState(() => _sessionExpired = false);
      CustomDialog.showSuccess(context, 'Selamat datang di Jogja EthnoTrip!');
      _checkBiometric();
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) context.go('/home');
      });
    } else {
      final error = ref.read(authProvider).error ?? 'Login gagal, coba lagi';
      CustomDialog.showError(context, error);
    }
  }

  Future<void> _handleBiometricLogin() async {
    CustomDialog.showLoading(context);
    
    try {
      final success = await ref.read(authProvider.notifier).loginWithBiometric();
      
      if (!mounted) return;
      CustomDialog.hideLoading(context);
      
      if (success) {
        setState(() => _sessionExpired = false);
        CustomDialog.showSuccess(context, 'Login biometric berhasil!');
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) context.go('/home');
        });
      } else {
        final error = ref.read(authProvider).error ?? 'Login biometric gagal';
        CustomDialog.showError(context, error);
      }
    } catch (e) {
      if (!mounted) return;
      CustomDialog.hideLoading(context);
      CustomDialog.showError(context, 'Terjadi kesalahan: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    print('🖼️ LoginScreen build: isAuthenticated=${authState.isAuthenticated}, error=${authState.error}');
    
    // ✅ HANYA redirect jika isAuthenticated TRUE dan TIDAK ada error
    if (authState.isAuthenticated && authState.error == null) {
      print('✅ Auto-redirect ke Home');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/home');
      });
      return const SizedBox.shrink(); // Tampilkan empty widget saat redirect
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Enhanced Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryLight,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.location_city, size: 55, color: AppColors.secondary),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Jogja EthnoTrip',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Jelajahi Budaya Yogyakarta',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                
                // ✅ PESAN SESSION EXPIRED
                if (_sessionExpired)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_off_rounded, color: AppColors.warning, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sesi Berakhir',
                                style: TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Sesi Anda telah berakhir karena tidak aktif selama ${SessionConfig.sessionTimeout.inMinutes} menit. Silakan login kembali.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                
                if (_sessionExpired) const SizedBox(height: 20),
                
                // ✅ INFO SESSION TIMEOUT
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.timer_outlined, color: AppColors.accent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Keamanan Session',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _getSessionTimeoutText(),
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Username Field
                TextFormField(
                  controller: _usernameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 20),
                
                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: AppColors.primary,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                ),
                
                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: const Text(
                      'Lupa Password?',
                      style: TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _handleLogin,
                    child: authState.isLoading
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Text('MASUK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Biometric Button
                if (_canBiometric) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: authState.isLoading ? null : _handleBiometricLogin,
                      icon: Icon(
                        _hasBiometricUser ? Icons.fingerprint : Icons.fingerprint_outlined,
                        color: _hasBiometricUser ? AppColors.primary : AppColors.textHint,
                        size: 24,
                      ),
                      label: Text(
                        _hasBiometricUser ? 'Login dengan Sidik Jari' : 'Login dengan Password Terlebih Dahulu',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _hasBiometricUser ? AppColors.primary : AppColors.textHint,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: _hasBiometricUser ? AppColors.primary : AppColors.textHint,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Belum punya akun? ', style: TextStyle(color: AppColors.textSecondary)),
                    GestureDetector(
                      onTap: () => context.push('/register'),
                      child: const Text('Daftar Sekarang', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ✅ SESSION STATUS SAAT INI
                if (authState.sessionInfo != null && !_sessionExpired)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: AppColors.success, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authState.sessionInfo!,
                            style: const TextStyle(color: AppColors.success, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 20),
                
                // Security Footer
                Center(
                  child: Text(
                    '🔐 Data diamankan dengan enkripsi SHA-256',
                    style: TextStyle(color: AppColors.textHint, fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getSessionTimeoutText() {
    final timeout = SessionConfig.sessionTimeout;
    
    if (timeout.inDays >= 1) {
      return 'Session akan otomatis berakhir setelah ${timeout.inDays} hari tidak aktif.';
    } else if (timeout.inHours >= 1) {
      return 'Session akan otomatis berakhir setelah ${timeout.inHours} jam tidak aktif.';
    } else if (timeout.inMinutes >= 1) {
      return 'Session akan otomatis berakhir setelah ${timeout.inMinutes} menit tidak aktif.';
    } else {
      return 'Session akan otomatis berakhir setelah ${timeout.inSeconds} detik tidak aktif.';
    }
  }
}