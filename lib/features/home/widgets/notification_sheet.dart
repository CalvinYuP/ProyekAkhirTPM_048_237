// lib/features/home/widgets/notification_sheet.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/storage_service.dart';

class NotificationSheet extends StatefulWidget {
  const NotificationSheet({super.key});

  @override
  State<NotificationSheet> createState() => _NotificationSheetState();
}

class _NotificationSheetState extends State<NotificationSheet> {
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  // ✅ FILTER PER USER
  Future<void> _loadNotifications() async {
    final box = await Hive.openBox('notifications');
    final storage = StorageService();
    final username = storage.currentUsername ?? '';
    
    final List<Map<String, dynamic>> notifs = [];
    
    final allKeys = box.keys.toList();
    allKeys.sort((a, b) => b.toString().compareTo(a.toString()));
    
    for (var key in allKeys) {
      if (key.toString().startsWith('${username}_')) {
        final data = box.get(key);
        if (data != null) {
          notifs.add({'id': key, ...data});
        }
      }
    }
    
    if (mounted) {
      setState(() => _notifications = notifs);
    }
  }

  Future<void> _markAsRead(dynamic id) async {
    final box = await Hive.openBox('notifications');
    final data = box.get(id);
    if (data != null) {
      data['read'] = true;
      await box.put(id, data);
      _loadNotifications();
    }
  }

  Future<void> _clearAll() async {
    final box = await Hive.openBox('notifications');
    final storage = StorageService();
    final username = storage.currentUsername ?? '';
    
    // Hanya hapus notifikasi milik user ini
    for (var key in box.keys.toList()) {
      if (key.toString().startsWith('${username}_')) {
        await box.delete(key);
      }
    }
    
    _loadNotifications();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Notifikasi', style: TextStyle(color: AppColors.secondary, fontSize: 18, fontWeight: FontWeight.bold)),
          TextButton(onPressed: _notifications.isEmpty ? null : _clearAll, child: const Text('Hapus Semua', style: TextStyle(color: AppColors.primary, fontSize: 12))),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          height: 300,
          child: _notifications.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.notifications_none, size: 40, color: AppColors.textSecondary.withValues(alpha: 0.5)), const SizedBox(height: 8), Text('Tidak ada notifikasi', style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7), fontSize: 13))]))
              : ListView.separated(
                  itemCount: _notifications.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final notif = _notifications[index];
                    final date = DateTime.tryParse(notif['timestamp'] ?? '') ?? DateTime.now();
                    final isRead = notif['read'] == true;
                    
                    return GestureDetector(
                      onTap: () => _markAsRead(notif['id']),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isRead ? AppColors.surface : AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isRead ? Colors.transparent : AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text(notif['title'] ?? 'Notifikasi', style: TextStyle(color: AppColors.secondary, fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
                            Text(DateFormat('HH:mm').format(date), style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7), fontSize: 11)),
                          ]),
                          if (notif['message'] != null) ...[
                            const SizedBox(height: 4),
                            Text(notif['message'], style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ]),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}