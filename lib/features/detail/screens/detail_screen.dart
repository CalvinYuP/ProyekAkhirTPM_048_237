// lib/features/detail/screens/detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/time_converter.dart';
import '../../../../data/models/destination_model.dart';
import '../widgets/location_map.dart';

class DetailScreen extends ConsumerStatefulWidget {
  final Destination destination;
  const DetailScreen({super.key, required this.destination});

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  bool _isFavorite = false;
  String _selectedTimeZone = 'WIB';
  bool _isReminderActive = false;
  bool _isLoadingReminder = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
    _checkReminderStatus();
  }

  // ✅ FAVORIT DENGAN FK USERNAME
  Future<void> _checkFavoriteStatus() async {
    final box = await Hive.openBox('favorites');
    final storage = StorageService();
    final username = storage.currentUsername;
    
    if (username == null) return;
    
    final key = '${username}_${widget.destination.id}';
    
    if (mounted) {
      setState(() => _isFavorite = box.containsKey(key));
    }
  }

  Future<void> _toggleFavorite() async {
    final box = await Hive.openBox('favorites');
    final storage = StorageService();
    final username = storage.currentUsername;
    
    if (username == null) return;
    
    setState(() => _isFavorite = !_isFavorite);

    final key = '${username}_${widget.destination.id}';

    if (_isFavorite) {
      await box.put(key, {
        'id': widget.destination.id,
        'username': username,
        'name': widget.destination.name,
        'imageUrl': widget.destination.imageUrl,
        'category': widget.destination.category,
      });
    } else {
      await box.delete(key);
    }
  }

  // ✅ REMINDER DENGAN FK USERNAME
  Future<void> _checkReminderStatus() async {
    final box = await Hive.openBox('reminders');
    final storage = StorageService();
    final username = storage.currentUsername;
    
    if (username == null) return;
    
    final reminderKey = '${username}_reminder_${widget.destination.id}';
    
    if (mounted) {
      setState(() => _isReminderActive = box.get(reminderKey, defaultValue: false));
    }
  }

  Future<void> _toggleReminder() async {
    setState(() => _isLoadingReminder = true);
    try {
      final box = await Hive.openBox('reminders');
      final notificationBox = await Hive.openBox('notifications');
      final storage = StorageService();
      final username = storage.currentUsername;
      
      if (username == null) return;
      
      final reminderKey = '${username}_reminder_${widget.destination.id}';

      if (_isReminderActive) {
        await box.put(reminderKey, false);
        if (mounted) {
          setState(() => _isReminderActive = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Icon(Icons.notifications_off_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Text('Reminder ${widget.destination.name} dinonaktifkan'),
              ]),
              backgroundColor: AppColors.textSecondary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 2),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } else {
        await box.put(reminderKey, true);
        
        final notificationKey = '${username}_${DateTime.now().millisecondsSinceEpoch}';
        await notificationBox.put(notificationKey, {
          'username': username,
          'title': '🔔 Reminder Aktif',
          'message': 'Kami akan mengingatkan Anda saat ${widget.destination.name} buka pukul ${widget.destination.openTime}',
          'timestamp': DateTime.now().toIso8601String(),
          'read': false,
          'destinationId': widget.destination.id,
          'destinationName': widget.destination.name,
        });
        
        await NotificationService.showInstantNotification(
          '🔔 Reminder Jam Buka',
          '${widget.destination.name} buka pukul ${widget.destination.openTime}. Kami akan mengingatkan Anda!',
        );
        
        if (mounted) {
          setState(() => _isReminderActive = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Icon(Icons.notifications_active_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Reminder aktif! Anda akan diingatkan saat ${widget.destination.name} buka')),
              ]),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 3),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error toggle reminder: $e');
    } finally {
      if (mounted) setState(() => _isLoadingReminder = false);
    }
  }

  // ✅ DIALOG UNTUK DESTINASI GRATIS
  void _showFreeEntryDialog() {
    showDialog(
      context: context,
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
              child: const Icon(Icons.celebration_rounded, color: AppColors.success, size: 50),
            ),
            const SizedBox(height: 16),
            const Text(
              'Kabar Baik! 🎉',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${widget.destination.name} adalah destinasi wisata GRATIS!',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.accent, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Destinasi ini tidak memerlukan tiket masuk. Anda bisa langsung berkunjung tanpa perlu memesan tiket.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Jam Operasional: ${widget.destination.openTime} - ${widget.destination.closeTime}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Mengerti, Terima Kasih!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _openInGoogleMaps();
              },
              icon: const Icon(Icons.navigation_rounded, size: 18),
              label: const Text('Navigasi ke Lokasi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openInGoogleMaps() async {
    final latitude = widget.destination.latitude;
    final longitude = widget.destination.longitude;
    final urls = [
      'geo:$latitude,$longitude?q=$latitude,$longitude',
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
    ];
    bool opened = false;
    for (final url in urls) {
      try {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          opened = true;
          break;
        }
      } catch (e) {
        continue;
      }
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tidak dapat membuka Google Maps'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _shareDestination() {
    final text = "Yuk kunjungi ${widget.destination.name} di Jogja EthnoTrip! 🇮🇩\n\n"
        "📍 ${widget.destination.address}\n"
        "⭐ Rating: ${widget.destination.rating}";
    Share.share(text);
  }

  String get _formattedTime {
    return TimeConverter.formatTimeRange(
      widget.destination.openTime,
      widget.destination.closeTime,
      _selectedTimeZone,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyNotifier = ref.read(currencyProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.secondary,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), shape: BoxShape.circle),
              child: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => context.pop()),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), shape: BoxShape.circle),
                child: IconButton(icon: const Icon(Icons.share_rounded, color: Colors.white), onPressed: _shareDestination),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(fit: StackFit.expand, children: [
                Image.asset(widget.destination.imageUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(color: AppColors.primaryLight, child: const Center(child: Icon(Icons.image_not_supported_rounded, size: 60, color: AppColors.textHint)))),
                Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent, Colors.black.withValues(alpha: 0.3)]))),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(child: Text(widget.destination.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.bold, height: 1.2))),
                  Container(
                    decoration: BoxDecoration(color: _isFavorite ? Colors.red.withValues(alpha: 0.1) : AppColors.primaryLight.withValues(alpha: 0.3), shape: BoxShape.circle),
                    child: IconButton(icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border_rounded, color: _isFavorite ? Colors.red : AppColors.primary, size: 28), onPressed: _toggleFavorite),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)), child: Text(widget.destination.category, style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600, fontSize: 12))),
                  const SizedBox(width: 12),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 18), const SizedBox(width: 4), Text(widget.destination.rating.toString(), style: const TextStyle(color: Color(0xFFFFB300), fontWeight: FontWeight.bold))])),
                ]),
                const SizedBox(height: 24),
                _buildSectionCard(title: "Harga Tiket Masuk", child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(widget.destination.price == 0 ? 'GRATIS' : currencyNotifier.formatPrice(widget.destination.price), style: TextStyle(color: widget.destination.price == 0 ? AppColors.success : AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('per orang', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                ])),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () {
                    if (widget.destination.price == 0) {
                      _showFreeEntryDialog();
                    } else {
                      context.push('/booking/${widget.destination.id}', extra: widget.destination);
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.9), AppColors.primary]), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(widget.destination.price == 0 ? Icons.info_outline_rounded : Icons.confirmation_number_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Text(widget.destination.price == 0 ? 'Info Tiket' : 'Pesan Tiket', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(title: "Jam Operasional", child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Row(children: [const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 20), const SizedBox(width: 8), Text(_formattedTime, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)), const SizedBox(width: 8), _buildTimeZoneDropdown()]),
                  ]),
                  const SizedBox(height: 16), const Divider(), const SizedBox(height: 8),
                  _buildReminderButton(),
                  if (_isReminderActive) ...[
                    const SizedBox(height: 8),
                    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.success.withValues(alpha: 0.3))), child: Row(children: [const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20), const SizedBox(width: 8), Expanded(child: Text('Anda akan diingatkan saat ${widget.destination.name} buka pukul ${widget.destination.openTime}', style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w500)))]),),
                  ],
                ])),
                const SizedBox(height: 24),
                const Text("Deskripsi", style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(widget.destination.description, style: const TextStyle(color: AppColors.textSecondary, height: 1.6, fontSize: 15)),
                const SizedBox(height: 24),
                const Text("Lokasi", style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                LocationMap(destination: widget.destination),
                const SizedBox(height: 16),
                _buildNavigationButton(),
                const SizedBox(height: 12),
                Row(children: [const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18), const SizedBox(width: 8), Expanded(child: Text(widget.destination.address, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)))]),
                const SizedBox(height: 30),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))], border: Border.all(color: AppColors.primary.withValues(alpha: 0.1))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: AppColors.textHint, fontSize: 12, fontWeight: FontWeight.w500)), const SizedBox(height: 12), child]));
  }

  Widget _buildReminderButton() {
    return InkWell(
      onTap: _isLoadingReminder ? null : _toggleReminder,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          gradient: _isReminderActive ? LinearGradient(colors: [AppColors.success.withValues(alpha: 0.9), AppColors.success]) : LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.9), AppColors.primary]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: (_isReminderActive ? AppColors.success : AppColors.primary).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: _isLoadingReminder
            ? const SizedBox(height: 20, width: 20, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(_isReminderActive ? Icons.notifications_active_rounded : Icons.notifications_off_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(_isReminderActive ? 'Reminder Aktif - Buka ${widget.destination.openTime}' : 'Ingatkan Saya Saat Jam Buka', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              ]),
      ),
    );
  }

  Widget _buildNavigationButton() {
    return InkWell(
      onTap: _openInGoogleMaps,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.accent.withValues(alpha: 0.9), AppColors.accent]), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.navigation_rounded, color: Colors.white, size: 24), SizedBox(width: 10), Text('Navigasi dengan Google Maps', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))]),
      ),
    );
  }

  Widget _buildTimeZoneDropdown() {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.textHint.withValues(alpha: 0.3))), child: DropdownButton<String>(value: _selectedTimeZone, underline: const SizedBox(), icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary), items: TimeConverter.getAvailableTimeZones().map((tz) => DropdownMenuItem<String>(value: tz, child: Text(TimeConverter.timeZoneLabels[tz] ?? tz, style: const TextStyle(fontSize: 12)))).toList(), onChanged: (v) { if (v != null) setState(() => _selectedTimeZone = v); }));
  }
}