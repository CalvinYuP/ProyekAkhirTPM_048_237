import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/password_criteria_list.dart';
import '../../../core/utils/password_validator.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/auth_service.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  
  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;
  bool _isLoading = false;

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (!PasswordValidator.isValid(_newPassController.text)) {
      CustomDialog.showError(context, 'Password baru belum memenuhi semua kriteria');
      return;
    }

    setState(() => _isLoading = true);
    
    final email = _emailController.text.trim().toLowerCase();
    final newPass = _newPassController.text;
    
    // Cari user berdasarkan email di Hive
    final storage = StorageService();
    final authService = AuthService(storage);
    String? foundUsername;

    for (var key in storage.userBox.keys) {
      final user = storage.userBox.get(key);
      if (user != null && user['email']?.toLowerCase() == email) {
        foundUsername = key.toString();
        break;
      }
    }

    setState(() => _isLoading = false);

    if (foundUsername == null) {
      CustomDialog.showError(context, 'Email tidak ditemukan dalam database');
      return;
    }

    // Update password
    final newHash = authService.hashPassword(newPass);
    final userData = storage.userBox.get(foundUsername);
    if (userData != null) {
      storage.userBox.put(foundUsername, {...userData, 'password': newHash});
    }

    CustomDialog.showSuccess(context, 'Password berhasil direset! Silakan login.');
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) context.go('/auth');
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final newPass = _newPassController.text;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.primary,
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
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withValues(alpha: 0.2)),
                    child: const Icon(Icons.lock_reset, size: 40, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 30),
                const Center(
                  child: Text(
                    'Masukkan email terdaftar dan buat password baru',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Terdaftar',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Wajib diisi';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return 'Format email salah';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // New Password dengan Toggle & Checklist
                TextFormField(
                  controller: _newPassController,
                  obscureText: _obscureNewPass,
                  decoration: InputDecoration(
                    labelText: 'Password Baru',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNewPass ? Icons.visibility_off : Icons.visibility, color: AppColors.primary),
                      onPressed: () => setState(() => _obscureNewPass = !_obscureNewPass),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                // ✅ PASSWORD CRITERIA CHECKLIST
                PasswordCriteriaList(password: newPass),
                const SizedBox(height: 16),
                
                // Confirm Password
                TextFormField(
                  controller: _confirmPassController,
                  obscureText: _obscureConfirmPass,
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Password Baru',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPass ? Icons.visibility_off : Icons.visibility, color: AppColors.primary),
                      onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => (v != _newPassController.text) ? 'Password tidak sama' : null,
                ),
                const SizedBox(height: 32),
                
                // Reset Button - Full Width
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleResetPassword,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('RESET PASSWORD', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Kembali ke Login', style: TextStyle(color: AppColors.primary)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}