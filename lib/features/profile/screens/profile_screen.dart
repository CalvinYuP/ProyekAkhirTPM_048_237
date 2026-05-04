// lib/features/profile/screens/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../data/models/destination_model.dart';

class FavoriteItem {
  final String id;
  final String name;
  final String imageUrl;
  final String category;
  FavoriteItem({required this.id, required this.name, required this.imageUrl, required this.category});
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  File? _profileImage;
  String? _email;
  final ImagePicker _picker = ImagePicker();
  Box<dynamic>? _favBox;

  @override
  void initState() {
    super.initState();
    _initHive();
    _loadUserData();
  }

  Future<void> _initHive() async {
    final box = await Hive.openBox('favorites');
    if (mounted) setState(() => _favBox = box);
  }

  Future<void> _loadUserData() async {
    final storage = StorageService();
    final username = storage.getUsername();
    if (username != null) {
      final userData = storage.getUser(username);
      if (mounted) setState(() => _email = userData?['email'] ?? 'email@tidak.ditemukan');
    }
    await _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final storage = StorageService();
    final username = storage.getUsername();
    if (username != null) {
      final box = await Hive.openBox('user_profile');
      final imagePath = box.get('profile_image_$username');
      if (imagePath != null && imagePath is String && File(imagePath).existsSync()) {
        if (mounted) setState(() => _profileImage = File(imagePath));
      }
    }
  }

  Future<void> _logout() async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)));
    try {
      ref.read(authProvider.notifier).logout();
      final storage = StorageService();
      await storage.clearSession();
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) context.go('/auth');
    } catch (e) {
      debugPrint("Logout Error: $e");
    } finally {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (mounted) setState(() => _profileImage = File(picked.path));
      final storage = StorageService();
      final username = storage.getUsername();
      if (username != null) {
        final box = await Hive.openBox('user_profile');
        await box.put('profile_image_$username', picked.path);
      }
    }
  }

  void _navigateToDetail(FavoriteItem item) {
    final destination = Destination(
      id: item.id, name: item.name, category: item.category,
      description: '', price: 0, rating: 0, imageUrl: item.imageUrl,
      address: '', openTime: '', closeTime: '', latitude: 0, longitude: 0,
    );
    context.push('/detail/${item.id}', extra: destination);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final username = authState.username ?? 'User';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.primaryLight,
        actions: [
          IconButton(icon: const Icon(Icons.settings_rounded, color: AppColors.primaryLight), onPressed: () => context.push('/settings'), tooltip: 'Pengaturan'),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Stack(clipBehavior: Clip.none, children: [
                Container(
                  width: 110, height: 110,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primary, width: 4), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))], image: _profileImage != null ? DecorationImage(image: FileImage(_profileImage!), fit: BoxFit.cover) : null, color: _profileImage == null ? AppColors.primaryLight : null),
                  child: _profileImage == null ? const Icon(Icons.person_rounded, size: 55, color: AppColors.secondary) : null,
                ),
                Positioned(bottom: 0, right: -5, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle, border: Border.all(color: AppColors.background, width: 3)), child: const Icon(Icons.edit_rounded, size: 16, color: AppColors.primaryLight))),
              ]),
            ),
          ),
          const SizedBox(height: 30),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))]),
            child: Column(children: [
              _buildInfoRow(Icons.person_outline_rounded, 'Username', username),
              const SizedBox(height: 16), const Divider(height: 1, color: AppColors.background), const SizedBox(height: 16),
              _buildInfoRow(Icons.email_outlined, 'Email', _email ?? 'Memuat...'),
            ]),
          ),
          const SizedBox(height: 30),
          const Text('Pengaturan', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => context.push('/settings'),
            child: Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4))]),
              child: Row(children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.currency_exchange_rounded, color: AppColors.primary, size: 24)),
                const SizedBox(width: 16),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Mata Uang Default', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)), SizedBox(height: 4), Text('Pilih mata uang untuk menampilkan harga', style: TextStyle(color: AppColors.textHint, fontSize: 12))])),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
              ]),
            ),
          ),
          const SizedBox(height: 30),
          _favBox == null
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : ValueListenableBuilder(
                  valueListenable: _favBox!.listenable(),
                  builder: (context, Box box, _) {
                    final storage = StorageService();
                    final currentUsername = storage.currentUsername ?? '';
                    final favs = <FavoriteItem>[];
                    
                    // ✅ HANYA AMBIL FAVORIT MILIK USER INI
                    for (var key in box.keys) {
                      if (key.toString().startsWith('${currentUsername}_')) {
                        final val = box.get(key);
                        if (val is Map) {
                          favs.add(FavoriteItem(
                            id: val['id']?.toString() ?? '',
                            name: val['name']?.toString() ?? 'Unknown',
                            imageUrl: val['imageUrl']?.toString() ?? '',
                            category: val['category']?.toString() ?? 'Umum',
                          ));
                        }
                      }
                    }
                    
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Destinasi Favorit', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('${favs.length} item', style: const TextStyle(color: AppColors.textHint, fontSize: 13)),
                      ]),
                      const SizedBox(height: 16),
                      favs.isEmpty
                          ? Container(padding: const EdgeInsets.all(30), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)), child: const Center(child: Text('Belum ada destinasi favorit.\n❤️ dari halaman detail untuk menambahkan!', style: TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center)))
                          : SizedBox(
                              height: 130,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: favs.length,
                                separatorBuilder: (_, _) => const SizedBox(width: 16),
                                itemBuilder: (context, index) {
                                  final fav = favs[index];
                                  return GestureDetector(
                                    onTap: () => _navigateToDetail(fav),
                                    child: Container(
                                      width: 110,
                                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4))]),
                                      clipBehavior: Clip.antiAlias,
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: Image.asset(fav.imageUrl, height: 70, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(height: 70, color: AppColors.primaryLight, child: const Icon(Icons.image_not_supported, size: 30, color: AppColors.textHint)))),
                                        Padding(padding: const EdgeInsets.all(10), child: Text(fav.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                      ]),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ]);
                  },
                ),
          const SizedBox(height: 40),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _logout, icon: const Icon(Icons.logout_rounded), label: const Text('Keluar Aplikasi'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50, foregroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 16)))),
        ]),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(children: [
      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primaryLight.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: AppColors.primary, size: 20)),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: AppColors.textHint, fontSize: 12)), const SizedBox(height: 2), Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w500))])),
    ]);
  }
}