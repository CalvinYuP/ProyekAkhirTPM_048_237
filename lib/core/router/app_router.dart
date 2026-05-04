// lib/core/router/app_router.dart
// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Auth Screens
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';

// Main Screens
import '../../features/home/screens/home_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/saran_kesan_screen.dart';
import '../../features/profile/screens/settings_screen.dart';
import '../../features/game/screens/game_screen.dart';

// Detail Screen
import '../../features/detail/screens/detail_screen.dart';
import '../../features/chat/screens/chat_screen.dart';

// Currency Screen
import '../../features/currency/screens/currency_converter_screen.dart';

// Booking Screens
import '../../features/booking/screens/booking_screen.dart';
import '../../features/booking/screens/booking_detail_screen.dart';

// Payment Screen
import '../../features/payment/screens/payment_screen.dart';

// Main Scaffold
import '../../features/main_scaffold/main_scaffold.dart';

// Model
import '../../data/models/destination_model.dart';

// ✅ EKSPOR NAVIGATOR KEY GLOBAL
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    // ✅ Splash Screen
    GoRoute(
      path: '/splash',
      builder: (_, __) => const SplashScreen(),
    ),
    
    // ✅ Auth Screens (tanpa Bottom Nav)
    GoRoute(
      name: 'auth',
      path: '/auth',
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (_, __) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (_, __) => const ForgotPasswordScreen(),
    ),
    
    // ✅ ROUTE DETAIL
    GoRoute(
      path: '/detail/:id',
      builder: (context, state) {
        final destination = state.extra as Destination;
        return DetailScreen(destination: destination);
      },
    ),
    
    // ✅ CHAT SCREEN
    GoRoute(
      path: '/chat', 
      builder: (context, state) => const ChatScreen(),
    ),

    // ✅ GAME SCREEN
    GoRoute(
      path: '/game',
      builder: (_, __) => const GameScreen(),
    ),
    
    // ✅ CURRENCY CONVERTER SCREEN
    GoRoute(
      path: '/currency',
      builder: (_, __) => const CurrencyConverterScreen(),
    ),
    
    // ✅ BOOKING SCREEN
    GoRoute(
      path: '/booking/:id',
      builder: (context, state) {
        final destination = state.extra as Destination;
        return BookingScreen(destination: destination);
      },
    ),
    
    // ✅ BOOKING DETAIL SCREEN
    GoRoute(
      path: '/booking-detail',
      builder: (_, __) => const BookingDetailScreen(),
    ),
    
    // ✅ PAYMENT SCREEN
    GoRoute(
      path: '/payment',
      builder: (_, __) => const PaymentScreen(),
    ),
    
    // ✅ SETTINGS SCREEN
    GoRoute(
      path: '/settings',
      builder: (_, __) => const SettingsScreen(),
    ),
    
    // ✅ MAIN SCAFFOLD dengan Bottom Navigation
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainScaffold(navigationShell: navigationShell);
      },
      branches: [
        // Branch 1: Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (context, state) {
                return NoTransitionPage(child: HomeScreen());
              },
            ),
          ],
        ),
        
        // Branch 2: Profil
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              pageBuilder: (context, state) {
                return NoTransitionPage(child: ProfileScreen());
              },
            ),
          ],
        ),
        
        // Branch 3: Saran
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/saran',
              pageBuilder: (context, state) {
                return NoTransitionPage(child: SaranKesanScreen());
              },
            ),
          ],
        ),
      ],
    ),
  ],
);