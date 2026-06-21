import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../home/cubit/home_cubit.dart';
import '../widgets/charter_search_form.dart';
import '../widgets/form_widgets.dart';
import '../widgets/hotel_search_form.dart';
import '../widgets/hot_tours_block.dart';
import '../widgets/popular_countries.dart';
import '../widgets/tour_search_form.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<HomeCubit>()..load(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView>
    with SingleTickerProviderStateMixin {
  int _tab = 0;
  late AnimationController _colorCtrl;
  late Animation<Color?> _bgColor;

  static const _tabColors = [
    Color(0xFF1A6FE8),
    Color(0xFF00897B),
    Color(0xFF7B1FA2),
    Color(0xFFE85D20),
  ];

  static const _tabLabels = ['Туры', 'Отели', 'Чартеры', '🔥 Горящие'];

  @override
  void initState() {
    super.initState();
    _colorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bgColor = ColorTween(
      begin: _tabColors[0],
      end: _tabColors[0],
    ).animate(CurvedAnimation(parent: _colorCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _colorCtrl.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    if (index == 3) {
      context.push(AppRoutes.tourList, extra: {'hotOnly': true});
      return;
    }
    if (_tab == index) return;
    final from = _tabColors[_tab];
    final to = _tabColors[index];
    setState(() => _tab = index);
    _bgColor = ColorTween(begin: from, end: to).animate(
      CurvedAnimation(parent: _colorCtrl, curve: Curves.easeInOut),
    );
    _colorCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorCtrl,
      builder: (context, _) {
        final bgColor = _bgColor.value ?? _tabColors[_tab];
        return BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            return Scaffold(
              backgroundColor: AppColors.bgLight,
              body: CustomScrollView(
                slivers: [
                  // ── AppBar ───────────────────────────────────────
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: bgColor,
                    surfaceTintColor: Colors.transparent,
                    title: Row(
                      children: [
                        const Text(
                          'TravelKZ',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),

                        // ── AI Подбор ──────────────────────────────
                        GestureDetector(
                          onTap: () => context.push(AppRoutes.aiAssistant),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.auto_awesome,
                                    color: Colors.white, size: 16),
                                SizedBox(width: 6),
                                Text('AI Подбор',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // ── Чат поддержки ──────────────────────────
                        GestureDetector(
                          onTap: () => context.push(AppRoutes.support),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.chat_bubble_outline,
                                    color: Colors.white, size: 16),
                                SizedBox(width: 6),
                                Text('Чат',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Tabs + Form ──────────────────────────────────
                  SliverToBoxAdapter(
                    child: Container(
                      color: bgColor,
                      child: Column(
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: Row(
                              children: List.generate(
                                _tabLabels.length,
                                (i) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: HomeTab(
                                    label: _tabLabels[i],
                                    selected: _tab == i,
                                    onTap: () => _switchTab(i),
                                    badge: i == 2 ? 'new' : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: _tab == 1
                                  ? const HotelSearchForm(key: ValueKey('hotel'))
                                  : _tab == 2
                                      ? const CharterSearchForm(key: ValueKey('charter'))
                                      : const TourSearchForm(key: ValueKey('tour')),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Content ──────────────────────────────────────
                  if (state is HomeLoaded) ...[
                    SliverToBoxAdapter(
                      child: HotToursBlock(tours: state.hotTours),
                    ),
                    SliverToBoxAdapter(
                      child: PopularCountries(destinations: state.destinations),
                    ),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}