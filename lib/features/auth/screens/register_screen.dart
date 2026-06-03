import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/password_criteria_list.dart';
import '../../../core/utils/password_validator.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!PasswordValidator.isValid(_passwordController.text)) {
      CustomDialog.showError(context, 'Password belum memenuhi semua kriteria');
      return;
    }

    CustomDialog.showLoading(context);
    
    final success = await ref.read(authProvider.notifier).register(
      _usernameController.text.trim(),
      _passwordController.text,
      _emailController.text.trim(),
    );

    if (!mounted) return;
    CustomDialog.hideLoading(context);

    if (success) {
      // ✅ Tutup loading dialog dulu
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // ✅ Tampilkan SnackBar sukses
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Akun berhasil dibuat! Mengalihkan ke login...'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.all(16),
          ),
        );
      }

      // ✅ Tunggu sebentar lalu redirect ke login
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // ✅ REDIRECT KE LOGIN - Gunakan GoRouter langsung
      // Pop semua route sampai ke root, lalu ganti dengan /auth
      final router = GoRouter.of(context);
      
      // Pop semua halaman yang ada di stack
      while (router.canPop()) {
        router.pop();
      }
      
      // Ganti dengan halaman login
      router.go('/auth');
      
    } else if (mounted) {
      CustomDialog.showError(context, 'Username atau Email sudah terdaftar.');
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final password = _passwordController.text;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daftar Akun'),
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.primaryLight,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                    child: const Icon(Icons.person_add, size: 40, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 30),
                
                // Username
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                    border: OutlineInputBorder(),
                    helperText: 'Digunakan untuk reset password',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Wajib diisi';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return 'Format email salah';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Password dengan Toggle & Checklist
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
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
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                PasswordCriteriaList(password: password),
                const SizedBox(height: 16),
                
                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Password',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: AppColors.primary,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => (v != _passwordController.text) ? 'Password tidak sama' : null,
                ),
                const SizedBox(height: 32),
                
                // Register Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: authState.isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'DAFTAR',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Sudah punya akun? ',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}