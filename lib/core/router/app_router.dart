import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/tours/presentation/pages/tour_detail_page.dart';
import '../../features/tours/presentation/pages/tour_list_page.dart';
import '../../features/tours/presentation/pages/tour_booking_page.dart';
import '../../features/hotels/presentation/pages/hotel_detail_page.dart';
import '../../features/hotels/presentation/pages/hotel_list_page.dart';
import '../../features/hotels/presentation/pages/hotel_booking_page.dart';
import '../../features/wishlist/presentation/pages/wishlist_page.dart';
import '../../features/tour_hunter/presentation/pages/tour_hunter_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/my_bookings_page.dart';
import '../../features/ai_assistant/presentation/pages/ai_assistant_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/charters/presentation/pages/charter_list_page.dart';
import '../../features/charters/presentation/pages/charter_detail_page.dart';
import '../../features/charters/presentation/pages/charter_booking_page.dart';
import '../../features/support/presentation/pages/support_chat_page.dart';
import '../../features/charters/models/flight_model.dart';
import '../../data/models/hotel_model.dart';
import '../../domain/entities/entities.dart';
import 'main_scaffold.dart';

abstract class AppRoutes {
  static const splash                = '/';
  static const login                 = '/login';
  static const register              = '/register';
  static const home                  = '/home';
  static const search                = '/search';
  static const wishlist              = '/wishlist';
  static const tourHunter            = '/tour-hunter';
  static const profile               = '/profile';
  static const editProfile           = '/profile/edit';
  static const myBookings            = '/profile/bookings';
  static const tourList              = '/tours';
  static const tourDetail            = '/tours/:id';
  static const tourBooking           = '/tour-booking';
  static const tourBookingSuccess    = '/tour-booking-success';
  static const hotelList             = '/hotel-list';
  static const hotelDetail           = '/hotels/:id';
  static const hotelBooking          = '/hotel-booking';
  static const hotelBookingSuccess   = '/hotel-booking-success';
  static const aiAssistant           = '/ai-assistant';
  static const onboarding            = '/onboarding';
  static const charterList           = '/charter-list';
  static const charterDetail         = '/charter-detail';
  static const charterBooking        = '/charter-booking';
  static const charterBookingSuccess = '/charter-booking-success';
  static const support               = '/support';
}

abstract class AppRouter {
  static final _root  = GlobalKey<NavigatorState>();
  static final _shell = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _root,
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(path: AppRoutes.splash,   builder: (_, __) => const SplashPage()),
      GoRoute(path: AppRoutes.login,    builder: (_, __) => const LoginPage()),
      GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterPage()),

      ShellRoute(
        navigatorKey: _shell,
        builder: (_, __, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: AppRoutes.home,       pageBuilder: (_, s) => _fade(const HomePage(), s.pageKey)),
          GoRoute(path: AppRoutes.search,     pageBuilder: (_, s) => _fade(const SearchPage(), s.pageKey)),
          GoRoute(path: AppRoutes.wishlist,   pageBuilder: (_, s) => _fade(const WishlistPage(), s.pageKey)),
          GoRoute(path: AppRoutes.tourHunter, pageBuilder: (_, s) => _fade(const TourHunterPage(), s.pageKey)),
          GoRoute(path: AppRoutes.profile,    pageBuilder: (_, s) => _fade(const ProfilePage(), s.pageKey)),
        ],
      ),

      // ── Tours ──────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.tourList,
        builder: (_, s) => TourListPage(filters: s.extra as Map<String, dynamic>?),
      ),
      GoRoute(
        path: AppRoutes.tourDetail,
        builder: (_, s) {
          final extra = s.extra as Map<String, dynamic>?;
          return TourDetailPage(
            tourId: s.pathParameters['id']!,
            departureCity: extra?['departureCity'] as String? ?? 'Алматы',
            tourists: extra?['tourists'] as String? ?? '2 взрослых',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.tourBooking,
        builder: (_, s) {
          final e = s.extra as Map<String, dynamic>;
          return TourBookingPage(
            tour: e['tour'] as Tour,
            adults: e['adults'] as int,
            children: e['children'] as int,
            finalPrice: e['finalPrice'] as double,
            bonusDiscount: e['bonusDiscount'] as int,
            departureCity: e['departureCity'] as String? ?? 'Алматы',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.tourBookingSuccess,
        builder: (_, s) {
          final e = s.extra as Map<String, dynamic>;
          return TourBookingSuccessPage(
            earnedBonuses: e['earnedBonuses'] as int,
            tourTitle: e['tourTitle'] as String,
            departureDate: e['departureDate'] as String,
            nights: e['nights'] as int,
          );
        },
      ),

      // ── Hotels ─────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.hotelList,
        builder: (_, s) => HotelListPage(filters: s.extra as Map<String, dynamic>?),
      ),
      GoRoute(
        path: AppRoutes.hotelDetail,
        builder: (_, s) {
          final extra = s.extra as Map<String, dynamic>?;
          return HotelDetailPage(
            hotelId: s.pathParameters['id']!,
            dates: extra?['dates'] as String?,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.hotelBooking,
        builder: (_, s) {
          final e = s.extra as Map<String, dynamic>;
          return HotelBookingPage(
            variant: e['variant'] as HotelRoomVariant,
            hotel: e['hotel'] as Map<String, dynamic>,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.hotelBookingSuccess,
        builder: (_, s) {
          final e = s.extra as Map<String, dynamic>;
          return HotelBookingSuccessPage(
            earnedBonuses: e['earnedBonuses'] as int,
            hotelName: e['hotelName'] as String,
            checkIn: e['checkIn'] as String,
            checkOut: e['checkOut'] as String,
          );
        },
      ),

      // ── Charters ───────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.charterList,
        builder: (_, s) {
          final e = s.extra as Map<String, dynamic>?;
          return CharterListPage(
            from: e?['from'] ?? 'Алматы',
            to: e?['to'] ?? 'Анталья',
            date: e?['date'] ?? '29 апр',
            passengers: e?['passengers'] ?? '2 взр',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.charterDetail,
        builder: (_, s) => CharterDetailPage(flight: s.extra as Flight),
      ),
      GoRoute(
        path: AppRoutes.charterBooking,
        builder: (_, s) {
          final e = s.extra as Map<String, dynamic>;
          return CharterBookingPage(
            flight: e['flight'] as Flight,
            passengers: e['passengers'] as int? ?? 2,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.charterBookingSuccess,
        builder: (_, s) {
          final e = s.extra as Map<String, dynamic>;
          return CharterBookingSuccessPage(
            earnedBonuses: e['earnedBonuses'] as int,
            fromCity: e['fromCity'] as String,
            toCity: e['toCity'] as String,
            date: e['date'] as String,
            flightNumber: e['flightNumber'] as String,
          );
        },
      ),

      // ── Profile / Other ────────────────────────────────────────
      GoRoute(path: AppRoutes.editProfile,  builder: (_, __) => const EditProfilePage()),
      GoRoute(path: AppRoutes.myBookings,   builder: (_, __) => const MyBookingsPage()),
      GoRoute(path: AppRoutes.aiAssistant,  builder: (_, __) => const AiAssistantPage()),
      GoRoute(path: AppRoutes.onboarding,   builder: (_, __) => const OnboardingPage()),
      GoRoute(path: AppRoutes.support,      builder: (_, __) => const SupportChatPage()),
    ],
  );

  static CustomTransitionPage<void> _fade(Widget child, LocalKey key) =>
      CustomTransitionPage<void>(
        key: key,
        child: child,
        transitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        ),
      );
}