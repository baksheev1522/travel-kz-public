import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/tour_repository.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'firebase_options.dart';
import 'data/services/dynamic_pricing_service.dart';
import 'data/services/review_service.dart';
import 'data/services/hotel_service.dart';
import 'data/services/background_service.dart';
import 'data/services/price_alert_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await configureDependencies();

try {
  await TourRepository().seedToursIfEmpty();
  await HotelService().seedHotelsIfEmpty();
  await ReviewService().seedReviewsIfEmpty();
  await DynamicPricingService().updateDailyPrices();
} catch (_) {}

  await PriceAlertService.initNotifications();

  await BackgroundService.init();
  await BackgroundService.registerPriceCheck();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const TravelApp());
}

class TravelApp extends StatelessWidget {
  const TravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => getIt<AuthBloc>()..add(AuthCheckStatusEvent()),
        ),
      ],
      child: MaterialApp.router(
        title: 'TravelKZ',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
        builder: (context, child) => BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthUnauthenticatedState) {
              AppRouter.router.go(AppRoutes.login);
            }
          },
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}