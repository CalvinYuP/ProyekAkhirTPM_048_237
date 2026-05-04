// lib/features/payment/screens/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/providers/connectivity_provider.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String _selectedPaymentMethod = '';
  bool _isProcessing = false;
  bool _isCheckingConnection = false;
  
  final List<Map<String, dynamic>> _paymentMethods = [
    {'name': 'GoPay', 'icon': Icons.account_balance_wallet_rounded, 'color': Colors.blue},
    {'name': 'OVO', 'icon': Icons.account_balance_wallet_rounded, 'color': Colors.purple},
    {'name': 'DANA', 'icon': Icons.account_balance_wallet_rounded, 'color': Colors.blueAccent},
    {'name': 'ShopeePay', 'icon': Icons.account_balance_wallet_rounded, 'color': Colors.orange},
    {'name': 'Transfer Bank BCA', 'icon': Icons.account_balance_rounded, 'color': Colors.blueGrey},
    {'name': 'Transfer Bank Mandiri', 'icon': Icons.account_balance_rounded, 'color': Colors.indigo},
    {'name': 'Transfer Bank BNI', 'icon': Icons.account_balance_rounded, 'color': Colors.teal},
  ];

  // ✅ PROSES PEMBAYARAN DENGAN PENGECEKAN KONEKSI
  Future<void> _processPayment() async {
    // Validasi metode pembayaran dipilih
    if (_selectedPaymentMethod.isEmpty) {
      _showSnackBar('Pilih metode pembayaran terlebih dahulu', AppColors.warning);
      return;
    }

    // ✅ PENGECEKAN KONEKSI INTERNET
    setState(() => _isCheckingConnection = true);
    
    final connectivityService = ref.read(connectivityServiceProvider);
    final isConnected = await connectivityService.isConnected();
    
    setState(() => _isCheckingConnection = false);

    if (!isConnected) {
      // ❌ TIDAK ADA KONEKSI - Tampilkan dialog error
      _showNoConnectionDialog();
      return;
    }

    // ✅ ADA KONEKSI - Lanjutkan pembayaran
    setState(() => _isProcessing = true);
    
    // Simulasi proses pembayaran
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showSuccessDialog();
      }
    });
  }

  // ✅ DIALOG ERROR TIDAK ADA KONEKSI
  void _showNoConnectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.surface,
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: AppColors.error,
                size: 50,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tidak Ada Koneksi Internet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Maaf, pembayaran tidak dapat diproses karena perangkat Anda tidak terhubung ke internet.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: AppColors.accent, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tips: Pastikan Wi-Fi atau data seluler Anda aktif dan perangkat terhubung ke internet.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                // Coba lagi
                _processPayment();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Coba Lagi',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Tutup'),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ DIALOG PEMBAYARAN BERHASIL
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.surface,
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 60,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pembayaran Berhasil!',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tiket Anda telah berhasil dipesan. Selamat menikmati kunjungan Anda! 🎉',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/home');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Kembali ke Home',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Tutup'),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ SNACKBAR HELPER
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == AppColors.warning ? Icons.warning_rounded : Icons.info_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingData = GoRouterState.of(context).extra as Map<String, dynamic>;
    final currencyNotifier = ref.read(currencyProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryLight),
          onPressed: () => context.pop(),
        ),
        title: const Text('Pembayaran', style: TextStyle(color: AppColors.primaryLight)),
        backgroundColor: AppColors.secondary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Tagihan
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.secondary,
                    AppColors.secondary.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    'Total Tagihan',
                    style: TextStyle(color: AppColors.primaryLight, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyNotifier.formatPrice((bookingData['total'] as double)),
                    style: const TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${bookingData['destination'].name} • ${bookingData['totalPeople']} orang',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'Pilih Metode Pembayaran',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // E-Wallet Section
            const Text('E-Wallet', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
            const SizedBox(height: 8),
            ..._paymentMethods
                .where((m) => ['GoPay', 'OVO', 'DANA', 'ShopeePay'].contains(m['name']))
                .map((method) => _buildPaymentMethod(method)),
            
            const SizedBox(height: 16),
            const Text('Transfer Bank', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
            const SizedBox(height: 8),
            ..._paymentMethods
                .where((m) => ['Transfer Bank BCA', 'Transfer Bank Mandiri', 'Transfer Bank BNI'].contains(m['name']))
                .map((method) => _buildPaymentMethod(method)),
            
            const SizedBox(height: 24),
            
            // ✅ TOMBOL BAYAR DENGAN STATUS KONEKSI
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isProcessing || _isCheckingConnection) ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isCheckingConnection
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Memeriksa Koneksi...',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      )
                    : _isProcessing
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'BAYAR',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
              ),
            ),
            
            // ✅ INDIKATOR KONEKSI
            const SizedBox(height: 12),
            Center(
              child: Text(
                '🔒 Pembayaran memerlukan koneksi internet yang stabil',
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethod(Map<String, dynamic> method) {
    final isSelected = _selectedPaymentMethod == method['name'];
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = method['name']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? (method['color'] as Color).withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? (method['color'] as Color) : AppColors.textHint.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (method['color'] as Color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(method['icon'] as IconData, color: method['color'] as Color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                method['name'] as String,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: method['color'] as Color),
          ],
        ),
      ),
    );
  }
}