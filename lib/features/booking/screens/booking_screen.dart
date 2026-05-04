// lib/features/booking/screens/booking_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../data/models/destination_model.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final Destination destination;
  const BookingScreen({super.key, required this.destination});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  int _adultCount = 2;
  int _childCount = 0;
  String _selectedTimeSlot = '08:00';
  
  final List<String> _timeSlots = ['08:00', '09:00', '10:00', '11:00', '12:00', '13:00', '14:00'];

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      // ✅ Gunakan locale yang sudah didukung
      locale: const Locale('id', 'ID'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  int get _totalPeople => _adultCount + _childCount;
  double get _subtotal => widget.destination.price * _totalPeople;
  double get _tax => _subtotal * 0.1;
  double get _total => _subtotal + _tax;

  // ✅ Helper untuk format tanggal yang aman
  String _formatDate(DateTime date) {
    try {
      return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      // Fallback jika intl gagal
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyNotifier = ref.read(currencyProvider.notifier);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryLight),
          onPressed: () => context.pop(),
        ),
        title: const Text('Pesan Tiket', style: TextStyle(color: AppColors.primaryLight)),
        backgroundColor: AppColors.secondary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Destination Info
            Container(
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
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      widget.destination.imageUrl,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 70,
                        height: 70,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.destination.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB300)),
                            const SizedBox(width: 4),
                            Text(
                              widget.destination.rating.toString(),
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${currencyNotifier.formatPrice(widget.destination.price)} / orang',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Pilih Tanggal
            _buildSectionTitle('Pilih Tanggal Kunjungan'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 24),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(_selectedDate),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${_selectedDate.difference(DateTime.now()).inDays} hari lagi',
                          style: TextStyle(color: AppColors.textHint, fontSize: 12),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.edit_rounded, color: AppColors.primary),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Pilih Jam
            _buildSectionTitle('Pilih Jam Masuk'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _timeSlots.map((time) => GestureDetector(
                      onTap: () => setState(() => _selectedTimeSlot = time),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedTimeSlot == time ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedTimeSlot == time
                                ? AppColors.primary
                                : AppColors.textHint.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          time,
                          style: TextStyle(
                            color: _selectedTimeSlot == time ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Jumlah Orang
            _buildSectionTitle('Jumlah Pengunjung'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  _buildCounter('Dewasa', _adultCount, (v) => setState(() => _adultCount = v)),
                  const Divider(),
                  _buildCounter('Anak-anak', _childCount, (v) => setState(() => _childCount = v), min: 0),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Rincian Biaya
            _buildSectionTitle('Rincian Biaya'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  _buildPriceRow(
                    'Harga Tiket ($_totalPeople orang)',
                    currencyNotifier.formatPrice(_subtotal),
                  ),
                  const SizedBox(height: 8),
                  _buildPriceRow(
                    'Pajak (10%)',
                    currencyNotifier.formatPrice(_tax),
                  ),
                  const Divider(),
                  _buildPriceRow(
                    'Total',
                    currencyNotifier.formatPrice(_total),
                    isTotal: true,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Tombol Lanjut
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final bookingData = {
                    'destination': widget.destination,
                    'date': _formatDate(_selectedDate),
                    'time': _selectedTimeSlot,
                    'adult': _adultCount,
                    'child': _childCount,
                    'totalPeople': _totalPeople,
                    'subtotal': _subtotal,
                    'tax': _tax,
                    'total': _total,
                  };
                  context.push('/booking-detail', extra: bookingData);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'Lanjut ke Rincian',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(
    title,
    style: const TextStyle(
      color: AppColors.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
  );

  Widget _buildCounter(String label, int count, Function(int) onChanged, {int min = 1, int max = 10}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('$label (min. $min)', style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
        Row(
          children: [
            IconButton(
              onPressed: count > min ? () => onChanged(count - 1) : null,
              icon: Icon(
                Icons.remove_circle_outline,
                color: count > min ? AppColors.primary : AppColors.textHint,
              ),
            ),
            SizedBox(
              width: 40,
              child: Text(
                '$count',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              onPressed: count < max ? () => onChanged(count + 1) : null,
              icon: Icon(
                Icons.add_circle_outline,
                color: count < max ? AppColors.primary : AppColors.textHint,
              ),
            ),
          ],
        ),
      ],
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