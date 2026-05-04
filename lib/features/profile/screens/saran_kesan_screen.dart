// lib/features/profile/screens/saran_kesan_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/storage_service.dart';

class SaranKesanScreen extends StatefulWidget {
  const SaranKesanScreen({super.key});
  @override
  State<SaranKesanScreen> createState() => _SaranKesanScreenState();
}

class _SaranKesanScreenState extends State<SaranKesanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _komentarCtrl = TextEditingController();
  int _rating = 5;
  bool _isSubmitting = false;
  late final Future<Box> _boxFuture;

  @override
  void initState() {
    super.initState();
    _boxFuture = Hive.openBox('feedback');
  }

  // ✅ FEEDBACK DENGAN FK USERNAME
  Future<void> _submitFeedback(Box box) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    try {
      final storage = StorageService();
      final username = storage.currentUsername;
      
      if (username == null) return;
      
      final key = '${username}_${DateTime.now().millisecondsSinceEpoch}';
      
      await box.put(key, {
        'username': username,
        'rating': _rating,
        'komentar': _komentarCtrl.text.trim(),
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      setState(() { _rating = 5; _komentarCtrl.clear(); _isSubmitting = false; });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Terima kasih! Saran Anda telah kami terima 🙏'), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), backgroundColor: AppColors.success),
      );
    } catch (e) {
      debugPrint('❌ Error submit feedback: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Gagal mengirim saran'), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  void dispose() {
    _komentarCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Saran & Kesan'), backgroundColor: AppColors.secondary, foregroundColor: AppColors.primaryLight),
      body: FutureBuilder<Box>(
        future: _boxFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done || !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final box = snapshot.data!;
          return Form(
            key: _formKey,
            child: ListView(padding: const EdgeInsets.all(20), children: [
              const Text('Bagaimana pengalaman Anda?', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Beri Rating & Masukan', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => GestureDetector(onTap: () => setState(() => _rating = i + 1), child: AnimatedScale(scale: i < _rating ? 1.1 : 1.0, duration: const Duration(milliseconds: 300), child: Icon(i < _rating ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber[700], size: 40))))),
              ),
              const SizedBox(height: 24),
              TextFormField(controller: _komentarCtrl, maxLines: 4, style: const TextStyle(color: AppColors.textPrimary), decoration: InputDecoration(hintText: 'Tulis saran & kesan Anda...', hintStyle: const TextStyle(color: AppColors.textHint), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), filled: true, fillColor: AppColors.surface), validator: (v) => v == null || v.trim().isEmpty ? 'Mohon isi saran Anda' : null),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isSubmitting ? null : () => _submitFeedback(box), child: _isSubmitting ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : const Text('Kirim Saran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
              const SizedBox(height: 32), const Divider(), const SizedBox(height: 16),
              ValueListenableBuilder(
                valueListenable: box.listenable(),
                builder: (context, Box b, _) {
                  if (b.isEmpty) return Container(padding: const EdgeInsets.all(30), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)), child: const Center(child: Text('Belum ada saran yang dikirim', style: TextStyle(color: AppColors.textSecondary))));
                  
                  final storage = StorageService();
                  final username = storage.currentUsername ?? '';
                  final allKeys = b.keys.toList();
                  allKeys.sort((a, b) => b.toString().compareTo(a.toString()));
                  final userKeys = allKeys.where((key) => key.toString().startsWith('${username}_')).toList();
                  
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Riwayat Masukan', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('${userKeys.length} item', style: const TextStyle(color: AppColors.textHint)),
                    ]),
                    const SizedBox(height: 16),
                    ListView.separated(
                      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                      itemCount: userKeys.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final key = userKeys[index];
                        final item = b.get(key);
                        if (item == null) return const SizedBox.shrink();
                        final date = DateTime.tryParse(item['timestamp'] ?? '') ?? DateTime.now();
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4))]),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Row(children: List.generate(5, (i) => Icon(i < (item['rating'] ?? 0) ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber[700], size: 16))),
                              Text(DateFormat('dd MMM yyyy').format(date), style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                            ]),
                            const SizedBox(height: 10),
                            Text(item['komentar'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.4)),
                          ]),
                        );
                      },
                    ),
                  ]);
                },
              ),
            ]),
          );
        },
      ),
    );
  }
}