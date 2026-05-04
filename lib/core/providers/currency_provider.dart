// lib/core/providers/currency_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/currency_service.dart';
import '../services/storage_service.dart';

class CurrencyState {
  final String selectedCurrency;
  final Map<String, double> rates;
  final bool isLoading;
  final String? error;

  CurrencyState({this.selectedCurrency = 'IDR', this.rates = const {'IDR': 1.0}, this.isLoading = false, this.error});

  CurrencyState copyWith({String? selectedCurrency, Map<String, double>? rates, bool? isLoading, String? error}) {
    return CurrencyState(selectedCurrency: selectedCurrency ?? this.selectedCurrency, rates: rates ?? this.rates, isLoading: isLoading ?? this.isLoading, error: error);
  }
}

final currencyProvider = StateNotifierProvider<CurrencyNotifier, CurrencyState>((ref) => CurrencyNotifier());

class CurrencyNotifier extends StateNotifier<CurrencyState> {
  final CurrencyService _currencyService = CurrencyService();

  CurrencyNotifier() : super(CurrencyState()) { _initCurrency(); }

  Future<void> _initCurrency() async {
    final storage = StorageService();
    final username = storage.currentUsername ?? 'default';
    final key = '${username}_default_currency';
    
    final settingsBox = await Hive.openBox('settings');
    final savedCurrency = settingsBox.get(key, defaultValue: 'IDR');
    
    state = state.copyWith(selectedCurrency: savedCurrency);
    await loadRates();
  }

  Future<void> loadRates() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final rates = await _currencyService.getRates();
      if (rates.isNotEmpty) {
        state = state.copyWith(rates: rates, isLoading: false);
      } else {
        state = state.copyWith(rates: {'IDR': 1.0, 'USD': 0.000064, 'EUR': 0.000059, 'MYR': 0.00030, 'SGD': 0.000086}, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(rates: {'IDR': 1.0, 'USD': 0.000064, 'EUR': 0.000059, 'MYR': 0.00030, 'SGD': 0.000086}, isLoading: false, error: 'Gagal memuat kurs.');
    }
  }

  // ✅ SET CURRENCY DENGAN FK USERNAME
  Future<void> setCurrency(String currency, [String? username]) async {
    final storage = StorageService();
    final user = username ?? storage.currentUsername ?? 'default';
    final key = '${user}_default_currency';
    
    state = state.copyWith(selectedCurrency: currency);
    
    final settingsBox = await Hive.openBox('settings');
    await settingsBox.put(key, currency);
  }

  double convertPrice(double priceInIDR) {
    final rate = state.rates[state.selectedCurrency] ?? 1.0;
    return priceInIDR * rate;
  }

  String formatPrice(double priceInIDR) {
    final converted = convertPrice(priceInIDR);
    final symbol = _getCurrencySymbol(state.selectedCurrency);
    switch (state.selectedCurrency) {
      case 'IDR': return '$symbol ${converted.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
      default: return '$symbol ${converted.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    }
  }

  String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'MYR': return 'RM';
      case 'SGD': return 'S\$';
      default: return 'Rp';
    }
  }
}