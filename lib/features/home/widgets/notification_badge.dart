// lib/features/home/widgets/notification_badge.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/storage_service.dart';

class NotificationBadge extends StatefulWidget {
  final VoidCallback onTap;
  const NotificationBadge({super.key, required this.onTap});

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  // ✅ FILTER PER USER
  Future<void> _loadUnreadCount() async {
    final box = await Hive.openBox('notifications');
    final storage = StorageService();
    final username = storage.currentUsername ?? '';
    
    int unread = 0;
    
    for (var key in box.keys) {
      if (key.toString().startsWith('${username}_')) {
        final notification = box.get(key);
        if (notification != null && notification['read'] == false) {
          unread++;
        }
      }
    }
    
    if (mounted) {
      setState(() => _unreadCount = unread);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: AppColors.primary, size: 22),
          onPressed: () {
            widget.onTap();
            _loadUnreadCount();
          },
          padding: const EdgeInsets.all(10),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 6, top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                _unreadCount > 9 ? '9+' : '$_unreadCount',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}