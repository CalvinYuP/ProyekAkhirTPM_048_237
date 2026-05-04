// lib/features/profile/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/services/storage_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyState = ref.watch(currencyProvider);
    final currencyNotifier = ref.read(currencyProvider.notifier);
    final storage = StorageService();
    final username = storage.currentUsername ?? 'default';
    
    final currencies = {
      'IDR': {'name': 'Indonesian Rupiah', 'symbol': 'Rp', 'flag': '🇮🇩'},
      'USD': {'name': 'US Dollar', 'symbol': '\$', 'flag': '🇺🇸'},
      'EUR': {'name': 'Euro', 'symbol': '€', 'flag': '🇪🇺'},
      'SGD': {'name': 'Singapore Dollar', 'symbol': 'S\$', 'flag': '🇸🇬'},
      'MYR': {'name': 'Malaysian Ringgit', 'symbol': 'RM', 'flag': '🇲🇾'},
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryLight), onPressed: () => context.pop()),
        title: const Text('Pengaturan', style: TextStyle(color: AppColors.primaryLight)),
        backgroundColor: AppColors.secondary, elevation: 0,
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.currency_exchange_rounded, color: AppColors.primary, size: 24)),
              const SizedBox(width: 16),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Mata Uang Default', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)), SizedBox(height: 4), Text('Pilih mata uang untuk menampilkan harga', style: TextStyle(color: AppColors.textHint, fontSize: 12))])),
            ]),
            const SizedBox(height: 20),
            ...currencies.entries.map((entry) {
              final isSelected = currencyState.selectedCurrency == entry.key;
              return GestureDetector(
                onTap: () => currencyNotifier.setCurrency(entry.key, username),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.background, borderRadius: BorderRadius.circular(14), border: Border.all(color: isSelected ? AppColors.primary : AppColors.textHint.withValues(alpha: 0.2), width: isSelected ? 2 : 1)),
                  child: Row(children: [
                    Text(entry.value['flag'] ?? '', style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${entry.key} (${entry.value['symbol']})', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)), Text(entry.value['name'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))])),
                    if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 28),
                  ]),
                ),
              );
            }),
          ]),
        ),
      ]),
    );
  }
}