// lib/features/currency/screens/currency_converter_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/currency_converter_service.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() => _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final CurrencyConverterService _converterService = CurrencyConverterService();
  final TextEditingController _customAmountController = TextEditingController();
  
  String _fromCurrency = 'USD';
  String _toCurrency = 'IDR';
  double? _result;
  bool _isLoading = false;
  bool _isCustomAmount = false;
  String? _errorMessage;
  String? _conversionDate;
  double? _exchangeRate;
  
  // ✅ Preset amounts untuk quick select
  final List<double> _presetAmounts = [1, 5, 10, 50, 100, 500, 1000];
  
  final Map<String, Map<String, String>> _currencies = {
    'USD': {'name': 'US Dollar', 'symbol': '\$', 'flag': '🇺🇸'},
    'EUR': {'name': 'Euro', 'symbol': '€', 'flag': '🇪🇺'},
    'IDR': {'name': 'Indonesian Rupiah', 'symbol': 'Rp', 'flag': '🇮🇩'},
    'GBP': {'name': 'British Pound', 'symbol': '£', 'flag': '🇬🇧'},
    'JPY': {'name': 'Japanese Yen', 'symbol': '¥', 'flag': '🇯🇵'},
    'CNY': {'name': 'Chinese Yuan', 'symbol': '¥', 'flag': '🇨🇳'},
    'SGD': {'name': 'Singapore Dollar', 'symbol': 'S\$', 'flag': '🇸🇬'},
    'MYR': {'name': 'Malaysian Ringgit', 'symbol': 'RM', 'flag': '🇲🇾'},
    'AUD': {'name': 'Australian Dollar', 'symbol': 'A\$', 'flag': '🇦🇺'},
    'CAD': {'name': 'Canadian Dollar', 'symbol': 'C\$', 'flag': '🇨🇦'},
  };

  double _selectedAmount = 1;

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  // ✅ Validasi input (maksimal 10 digit)
  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nominal tidak boleh kosong';
    }
    
    // Hapus karakter non-digit
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleaned.isEmpty) {
      return 'Masukkan angka yang valid';
    }
    
    if (cleaned.length > 10) {
      return 'Maksimal 10 digit angka';
    }
    
    final amount = double.tryParse(cleaned);
    if (amount == null || amount <= 0) {
      return 'Nominal harus lebih dari 0';
    }
    
    return null;
  }

  // ✅ Format input dengan pemisah ribuan
  void _onAmountChanged(String value) {
    if (value.isEmpty) return;
    
    // Hapus karakter non-digit
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleaned.length > 10) {
      _customAmountController.text = _formatNumberString(cleaned.substring(0, 10));
      _customAmountController.selection = TextSelection.fromPosition(
        TextPosition(offset: _customAmountController.text.length),
      );
      setState(() => _errorMessage = 'Maksimal 10 digit angka');
      return;
    }
    
    setState(() => _errorMessage = null);
  }

  // ✅ Format string number dengan pemisah ribuan
  String _formatNumberString(String number) {
    if (number.isEmpty) return '';
    try {
      final value = double.parse(number);
      return value.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    } catch (e) {
      return number;
    }
  }

  // ✅ Format double number dengan pemisah ribuan
  String _formatNumberDouble(double number) {
    return number.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  // ✅ Get nominal yang akan dikonversi
  double _getAmount() {
    if (_isCustomAmount) {
      final cleaned = _customAmountController.text.replaceAll(RegExp(r'[^\d]'), '');
      return double.tryParse(cleaned) ?? 1;
    }
    return _selectedAmount;
  }

  // ✅ Konversi mata uang
  Future<void> _convertCurrency() async {
    final amount = _getAmount();
    
    if (_isCustomAmount) {
      final validation = _validateAmount(_customAmountController.text);
      if (validation != null) {
        setState(() => _errorMessage = validation);
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
    });

    try {
      final result = await _converterService.convertCurrency(
        amount: amount,
        fromCurrency: _fromCurrency,
        toCurrency: _toCurrency,
      );

      if (result != null) {
        setState(() {
          _result = (result['result'] as num).toDouble();
          _exchangeRate = (result['rate'] as num).toDouble();
          _conversionDate = result['date'] as String?;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Gagal mengambil data kurs. Periksa koneksi internet Anda.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // ✅ Swap currency
  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
      _result = null;
    });
  }

  // ✅ Format number dengan pemisah ribuan untuk display (2 desimal)
  String _formatForDisplay(double number) {
    return number.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    final fromCurrencyData = _currencies[_fromCurrency]!;
    final toCurrencyData = _currencies[_toCurrency]!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryLight),
          onPressed: () => context.pop(),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.currency_exchange_rounded, color: AppColors.primaryLight),
            SizedBox(width: 8),
            Text('Konversi Mata Uang', style: TextStyle(color: AppColors.primaryLight, fontSize: 18)),
          ],
        ),
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.primaryLight,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ FROM CURRENCY SECTION
            _buildSectionTitle('Dari Mata Uang'),
            const SizedBox(height: 8),
            _buildCurrencySelector(true),
            
            // ✅ SWAP BUTTON
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _swapCurrencies,
                  icon: const Icon(Icons.swap_vert_rounded, color: Colors.white, size: 28),
                  tooltip: 'Tukar Mata Uang',
                ),
              ),
            ),
            
            // ✅ TO CURRENCY SECTION
            _buildSectionTitle('Ke Mata Uang'),
            const SizedBox(height: 8),
            _buildCurrencySelector(false),
            
            const SizedBox(height: 24),
            
            // ✅ AMOUNT SECTION
            _buildSectionTitle('Nominal'),
            const SizedBox(height: 8),
            
            // ✅ Preset Amounts - DIPERBAIKI
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presetAmounts.map((amount) {
                final isSelected = !_isCustomAmount && _selectedAmount == amount;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _isCustomAmount = false;
                      _selectedAmount = amount;
                      _errorMessage = null;
                      _result = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.textHint.withValues(alpha: 0.3),
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ] : null,
                    ),
                    child: Text(
                      // ✅ DIPERBAIKI: Gunakan method yang tepat untuk double
                      '${fromCurrencyData['symbol']} ${_formatNumberDouble(amount)}',
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 12),
            
            // Custom Amount
            GestureDetector(
              onTap: () {
                setState(() {
                  _isCustomAmount = true;
                  _result = null;
                  _errorMessage = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isCustomAmount ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isCustomAmount ? AppColors.primary : AppColors.textHint.withValues(alpha: 0.3),
                    width: _isCustomAmount ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_rounded,
                      color: _isCustomAmount ? AppColors.primary : AppColors.textHint,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _isCustomAmount
                          ? TextField(
                              controller: _customAmountController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              onChanged: _onAmountChanged,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Masukkan nominal (maks 10 digit)',
                                hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                prefixText: '${fromCurrencyData['symbol']} ',
                                prefixStyle: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : Text(
                              'Nominal Lainnya...',
                              style: TextStyle(
                                color: AppColors.textHint,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            
            // ✅ ERROR MESSAGE
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // ✅ CONVERT BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _convertCurrency,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.primaryLight,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.primaryLight,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sync_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'KONVERSI',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // ✅ RESULT SECTION
            if (_result != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
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
                child: Column(
                  children: [
                    // ✅ DIPERBAIKI: Gunakan method yang tepat
                    Text(
                      '${fromCurrencyData['flag']} ${fromCurrencyData['symbol']} ${_formatNumberDouble(_getAmount())}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_downward_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            children: [
                              // ✅ DIPERBAIKI: Gunakan method yang tepat
                              Text(
                                '${toCurrencyData['flag']} ${toCurrencyData['symbol']} ${_formatForDisplay(_result!)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                toCurrencyData['name'] ?? '',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_exchangeRate != null) ...[
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 8),
                      // ✅ DIPERBAIKI: Gunakan method yang tepat
                      Text(
                        '1 $_fromCurrency = ${_formatForDisplay(_exchangeRate!)} $_toCurrency',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                      if (_conversionDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Kurs per: $_conversionDate',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildCurrencySelector(bool isFrom) {
    final selectedCurrency = isFrom ? _fromCurrency : _toCurrency;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCurrency,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
          items: _currencies.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Row(
                children: [
                  Text(entry.value['flag'] ?? '', style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        entry.value['name'] ?? '',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    entry.value['symbol'] ?? '',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                if (isFrom) {
                  _fromCurrency = value;
                } else {
                  _toCurrency = value;
                }
                _result = null;
              });
            }
          },
        ),
      ),
    );
  }
}