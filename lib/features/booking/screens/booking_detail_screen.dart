// lib/features/booking/screens/booking_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../data/models/destination_model.dart';

class BookingDetailScreen extends ConsumerWidget {
  const BookingDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingData = GoRouterState.of(context).extra as Map<String, dynamic>;
    final destination = bookingData['destination'] as Destination;
    
    // ✅ Gunakan currencyNotifier yang memiliki method formatPrice
    final currencyNotifier = ref.read(currencyProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryLight),
          onPressed: () => context.pop(),
        ),
        title: const Text('Rincian Booking', style: TextStyle(color: AppColors.primaryLight)),
        backgroundColor: AppColors.secondary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.9),
                    AppColors.primary,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Icon(Icons.receipt_long_rounded, color: Colors.white, size: 40),
                  SizedBox(height: 12),
                  Text(
                    'Rincian Pemesanan',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Mohon periksa kembali data Anda',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Detail Destinasi
            _buildSectionCard(
              'Destinasi',
              Column(
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          destination.imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 60,
                            height: 60,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              destination.name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFFB300)),
                                const SizedBox(width: 4),
                                Text(
                                  destination.rating.toString(),
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Detail Booking
            _buildSectionCard(
              'Detail Kunjungan',
              Column(
                children: [
                  _buildDetailRow(
                    Icons.calendar_month_rounded,
                    'Tanggal',
                    bookingData['date'] as String,
                  ),
                  const Divider(),
                  _buildDetailRow(
                    Icons.access_time_rounded,
                    'Jam Masuk',
                    bookingData['time'] as String,
                  ),
                  const Divider(),
                  _buildDetailRow(
                    Icons.people_rounded,
                    'Dewasa',
                    '${bookingData['adult']} orang',
                  ),
                  const Divider(),
                  _buildDetailRow(
                    Icons.child_care_rounded,
                    'Anak-anak',
                    '${bookingData['child']} orang',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Rincian Biaya
            _buildSectionCard(
              'Rincian Biaya',
              Column(
                children: [
                  // ✅ Gunakan currencyNotifier.formatPrice()
                  _buildPriceRow(
                    'Harga Tiket (${bookingData['totalPeople']} orang)',
                    currencyNotifier.formatPrice((bookingData['subtotal'] as double)),
                  ),
                  const SizedBox(height: 8),
                  _buildPriceRow(
                    'Pajak 10%',
                    currencyNotifier.formatPrice((bookingData['tax'] as double)),
                  ),
                  const Divider(),
                  _buildPriceRow(
                    'Total Pembayaran',
                    currencyNotifier.formatPrice((bookingData['total'] as double)),
                    isTotal: true,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Tombol Bayar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/payment', extra: bookingData),
                icon: const Icon(Icons.payment_rounded, color: Colors.white),
                label: const Text(
                  'Lanjut ke Pembayaran',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            color: isTotal ? AppColors.primary : AppColors.textPrimary,
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}