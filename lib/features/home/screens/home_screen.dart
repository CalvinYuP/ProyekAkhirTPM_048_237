// lib/features/home/screens/home_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/session_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/filter_chips.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/destination_card.dart';
import '../widgets/notification_badge.dart';
import '../widgets/notification_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  StreamSubscription? _accelerometerSub;
  bool _isShaking = false;
  DateTime? _lastShakeTime;

  @override
  void initState() {
    super.initState();
    _initShakeDetection();
    _startSessionCheck();
  }

  /// ✅ Mulai pengecekan session timeout
  void _startSessionCheck() {
    final sessionTimer = ref.read(sessionTimerProvider);
    sessionTimer.startSessionCheck();
    print('🔒 Session check dimulai di Home Screen');
  }

  // ✅ FITUR SHAKE UNTUK DESTINASI RANDOM
  void _initShakeDetection() {
    _accelerometerSub = userAccelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 100),
    ).listen((event) {
      final now = DateTime.now();
      
      if (_lastShakeTime != null && 
          now.difference(_lastShakeTime!) < const Duration(seconds: 3)) {
        return;
      }

      final double magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z
      );

      if (magnitude > 15.0 && !_isShaking) {
        _lastShakeTime = now;
        _onShakeDetected();
      }
    });
  }

  void _onShakeDetected() {
    setState(() => _isShaking = true);

    final homeState = ref.read(homeProvider);

    if (homeState.filteredDestinations.isEmpty) return;

    final random = Random();
    final randomIndex = random.nextInt(homeState.filteredDestinations.length);
    final randomDestination = homeState.filteredDestinations[randomIndex];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.casino_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '🎯 Rekomendasi: ${randomDestination.name}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'LIHAT',
          textColor: Colors.white,
          onPressed: () {
            GoRouter.of(context).push(
              '/detail/${randomDestination.id}',
              extra: randomDestination,
            );
          },
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isShaking = false);
      }
    });
  }

  @override
  void dispose() {
    _accelerometerSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);
    final notifier = ref.read(homeProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Jogja EthnoTrip',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          if (_isShaking)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.vibration_rounded, color: AppColors.primary, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Shake!',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Container(
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.currency_exchange_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                              onPressed: () => GoRouter.of(context).push('/currency'),
                              tooltip: 'Konversi Mata Uang',
                              padding: const EdgeInsets.all(10),
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                              onPressed: () => GoRouter.of(context).push('/chat'),
                              tooltip: 'Tanya Pemandu AI',
                              padding: const EdgeInsets.all(10),
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: NotificationBadge(
                              onTap: () => showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => const NotificationSheet(),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Jelajahi Budaya Yogyakarta ✨\n📳 Goyangkan HP untuk rekomendasi acak!',
                    style: TextStyle(
                      color: AppColors.primary.withValues(alpha: 0.9),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 20),

                  CustomSearchBar(
                    query: homeState.searchQuery,
                    onChanged: notifier.updateSearchQuery,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilterChips(
                selectedCategory: homeState.selectedCategory,
                onCategorySelected: notifier.updateCategory,
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: _buildContent(homeState, notifier),
            ),
          ],
        ),
      ),

      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 8, right: 8),
        child: FloatingActionButton.extended(
          elevation: 8,
          onPressed: () => GoRouter.of(context).push('/game'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.secondary,
          icon: const Icon(Icons.games_rounded, size: 24),
          label: const Text(
            'Main Game Batik',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(HomeState homeState, HomeNotifier notifier) {
    if (homeState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (homeState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, color: AppColors.error.withValues(alpha: 0.8), size: 60),
            const SizedBox(height: 12),
            Text(
              homeState.error!,
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => notifier.refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.secondary,
              ),
            ),
          ],
        ),
      );
    }

    if (homeState.filteredDestinations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: AppColors.textSecondary),
            SizedBox(height: 12),
            Text(
              'Tidak ada destinasi ditemukan',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => notifier.refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        itemCount: homeState.filteredDestinations.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: DestinationCard(
              destination: homeState.filteredDestinations[index],
            ),
          );
        },
      ),
    );
  }
}