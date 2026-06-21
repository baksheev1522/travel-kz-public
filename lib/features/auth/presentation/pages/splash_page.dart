import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/router/app_router.dart';
import '../../bloc/auth_bloc.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _globeCtrl;
  late AnimationController _fadeCtrl;
  late AnimationController _dotsCtrl;

  @override
  void initState() {
    super.initState();
    _globeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _globeCtrl.dispose();
    _fadeCtrl.dispose();
    _dotsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is AuthAuthenticatedState ||
            state is AuthUnauthenticatedState) {
          await Future.delayed(const Duration(milliseconds: 800));
          if (!mounted) return;

          if (state is AuthAuthenticatedState) {
            context.go(AppRoutes.home);
          } else {
            final prefs = await SharedPreferences.getInstance();
            final onboardingDone = prefs.getBool('onboarding_done') ?? false;
            if (!mounted) return;
            if (onboardingDone) {
              context.go(AppRoutes.login);
            } else {
              context.go(AppRoutes.onboarding);
            }
          }
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0A1628),
                Color(0xFF1A3A6B),
                Color(0xFF1A6FE8),
              ],
            ),
          ),
          child: FadeTransition(
            opacity: _fadeCtrl,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Globe
                AnimatedBuilder(
                  animation: _globeCtrl,
                  builder: (_, __) => CustomPaint(
                    size: const Size(260, 260),
                    painter: _GlobePainter(
                      rotation: _globeCtrl.value * 2 * pi,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Logo
                ShaderMask(
                  shaderCallback: (bounds) =>
                      const LinearGradient(
                    colors: [
                      Color(0xFF90CAF9),
                      Colors.white,
                      Color(0xFF90CAF9),
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    'TravelKZ',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Твои лучшие путешествия',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.6),
                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 48),

                // Loading dots
                AnimatedBuilder(
                  animation: _dotsCtrl,
                  builder: (_, __) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final phase =
                          (_dotsCtrl.value - i * 0.25).clamp(0.0, 1.0);
                      final alpha = sin(phase * pi).clamp(0.0, 1.0);
                      return Container(
                        margin:
                            const EdgeInsets.symmetric(horizontal: 5),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(
                            alpha: 0.2 + alpha * 0.8,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlobePainter extends CustomPainter {
  final double rotation;

  const _GlobePainter({required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final R = size.width / 2 - 8;

    // Glow
    canvas.drawCircle(
      Offset(cx, cy),
      R * 1.2,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF1A6FE8).withValues(alpha: 0.0),
            const Color(0xFF1A6FE8).withValues(alpha: 0.3),
          ],
          stops: const [0.6, 1.0],
        ).createShader(
            Rect.fromCircle(center: Offset(cx, cy), radius: R * 1.2)),
    );

    // Ocean
    canvas.drawCircle(
      Offset(cx, cy),
      R,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: const [
            Color(0xFF2563C7),
            Color(0xFF1A4FA0),
            Color(0xFF0D2F6B),
          ],
        ).createShader(
            Rect.fromCircle(center: Offset(cx, cy), radius: R)),
    );

    // Border
    canvas.drawCircle(
      Offset(cx, cy),
      R,
      Paint()
        ..color = const Color(0xFF64B5F6).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Grid
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (int lat = -60; lat <= 60; lat += 30) {
      final path = Path();
      bool started = false;
      for (int lon = -180; lon <= 180; lon += 4) {
        final p = _project(lon.toDouble(), lat.toDouble(), cx, cy, R);
        if (p.z > -0.1) {
          if (!started) {
            path.moveTo(p.dx, p.dy);
            started = true;
          } else {
            path.lineTo(p.dx, p.dy);
          }
        } else {
          started = false;
        }
      }
      canvas.drawPath(path, gridPaint);
    }

    for (int lon = -150; lon <= 180; lon += 30) {
      final path = Path();
      bool started = false;
      for (int lat = -80; lat <= 80; lat += 4) {
        final p = _project(lon.toDouble(), lat.toDouble(), cx, cy, R);
        if (p.z > -0.1) {
          if (!started) {
            path.moveTo(p.dx, p.dy);
            started = true;
          } else {
            path.lineTo(p.dx, p.dy);
          }
        } else {
          started = false;
        }
      }
      canvas.drawPath(path, gridPaint);
    }


    // Atmosphere
    canvas.drawCircle(
      Offset(cx, cy),
      R * 1.03,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF90CAF9).withValues(alpha: 0.0),
            const Color(0xFF90CAF9).withValues(alpha: 0.2),
          ],
          stops: const [0.8, 1.0],
        ).createShader(Rect.fromCircle(
            center: Offset(cx, cy), radius: R * 1.03)),
    );

    // Highlight
    canvas.drawCircle(
      Offset(cx, cy),
      R,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.5, -0.5),
          colors: [
            Colors.white.withValues(alpha: 0.18),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(
            Rect.fromCircle(center: Offset(cx, cy), radius: R)),
    );
  }

  _Point _project(double lon, double lat, double cx, double cy, double R) {
    final lam = (lon * pi / 180) + rotation;
    final phi = lat * pi / 180;
    final x = cos(phi) * sin(lam);
    final y = sin(phi);
    final z = cos(phi) * cos(lam);
    return _Point(cx + R * x, cy - R * y, z);
  }

  @override
  bool shouldRepaint(covariant _GlobePainter old) =>
      old.rotation != rotation;
}

class _Point {
  final double dx, dy, z;
  const _Point(this.dx, this.dy, this.z);
}