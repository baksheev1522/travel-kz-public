import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _current = 0;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const _pages = [
    _PageData(
      gradient: [Color(0xFF1A6FE8), Color(0xFF0A3D8F)],
      icon: '✈️',
      iconBg: Color(0xFF2979FF),
      title: 'Лучшие туры\nКазахстана',
      subtitle:
          'Тысячи туров от надёжных туроператоров.\nТурция, Египет, Мальдивы и многое другое.',
      features: ['Более 30 туроператоров', 'Реальные цены', 'Мгновенное бронирование'],
    ),
    _PageData(
      gradient: [Color(0xFFE85D20), Color(0xFFB03010)],
      icon: '🔥',
      iconBg: Color(0xFFFF6D00),
      title: 'Горящие туры\nсо скидками до 50%',
      subtitle:
          'Охотник за ценами сообщит когда\nцена на тур снизится до нужной.',
      features: ['Уведомления о снижении цен', 'Горящие предложения', 'Эксклюзивные скидки'],
    ),
    _PageData(
      gradient: [Color(0xFF00897B), Color(0xFF00574B)],
      icon: '🤖',
      iconBg: Color(0xFF00BFA5),
      title: 'AI Ассистент\nподберёт тур за вас',
      subtitle:
          'Просто опишите мечту об отдыхе —\nAI найдёт идеальный вариант.',
      features: ['Персональные рекомендации', 'Умный подбор', 'Мгновенный ответ'],
    ),
    _PageData(
      gradient: [Color(0xFF6A1B9A), Color(0xFF38006B)],
      icon: '🏝',
      iconBg: Color(0xFF9C27B0),
      title: 'Начните\nпутешествовать!',
      subtitle:
          'Бронируйте туры прямо со смартфона.\nВсе документы в одном месте.',
      features: ['Оплата онлайн', 'Документы в приложении', 'Поддержка 24/7'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
        parent: _animCtrl, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) context.go(AppRoutes.login);
  }

  void _next() {
    if (_current < _pages.length - 1) {
      _animCtrl.reset();
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      _animCtrl.forward();
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Pages
          PageView.builder(
            controller: _pageCtrl,
            onPageChanged: (i) {
              setState(() => _current = i);
              _animCtrl.reset();
              _animCtrl.forward();
            },
            itemCount: _pages.length,
            itemBuilder: (_, i) => _OnboardingScreen(
              data: _pages[i],
              fadeAnim: _fadeAnim,
              slideAnim: _slideAnim,
            ),
          ),

          // Skip
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 20,
            child: GestureDetector(
              onTap: _finish,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'Пропустить',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 32,
            left: 24,
            right: 24,
            child: Column(
              children: [
                // Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _current == i ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _current == i
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // Button
                GestureDetector(
                  onTap: _next,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _current < _pages.length - 1
                            ? 'Далее →'
                            : 'Начать →',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _pages[_current].gradient[0],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Single Onboarding Screen ─────────────────────────────────────
class _OnboardingScreen extends StatelessWidget {
  final _PageData data;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;

  const _OnboardingScreen({
    required this.data,
    required this.fadeAnim,
    required this.slideAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: data.gradient,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: FadeTransition(
            opacity: fadeAnim,
            child: SlideTransition(
              position: slideAnim,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),

                  // Icon block
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        data.icon,
                        style: const TextStyle(fontSize: 48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Title
                  Text(
                    data.title,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Subtitle
                  Text(
                    data.subtitle,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.75),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Features
                  ...data.features.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white
                                  .withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            f,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Data ─────────────────────────────────────────────────────────
class _PageData {
  final List<Color> gradient;
  final String icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final List<String> features;

  const _PageData({
    required this.gradient,
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.features,
  });
}