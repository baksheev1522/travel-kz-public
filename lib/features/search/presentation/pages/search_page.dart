import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/repositories/tour_repository.dart';
import '../../../../data/services/wishlist_service.dart';
import '../../../../domain/entities/entities.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _repo = TourRepository();
  final _ctrl = TextEditingController();
  List<Tour> _allTours = [];
  bool _loading = true;
  String _query = '';
  String? _selectedCountry;
  int? _selectedStars;
  bool _hotOnly = false;

  static const _countries = [
    'Турция', 'Египет', 'Таиланд', 'ОАЭ', 'Мальдивы',
  ];

  @override
  void initState() {
    super.initState();
    _loadTours();
  }

  Future<void> _loadTours() async {
    setState(() => _loading = true);
    try {
      final tours = await _repo.getTours();
      if (mounted) setState(() { _allTours = tours; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<Tour> get _filtered {
    var list = List<Tour>.from(_allTours);
    if (_query.isNotEmpty) {
      list = list.where((t) =>
        t.country.toLowerCase().contains(_query.toLowerCase()) ||
        t.city.toLowerCase().contains(_query.toLowerCase()) ||
        t.hotelName.toLowerCase().contains(_query.toLowerCase()),
      ).toList();
    }
    if (_selectedCountry != null) {
      list = list.where((t) => t.country == _selectedCountry).toList();
    }
    if (_selectedStars != null) {
      list = list.where((t) => t.stars >= _selectedStars!).toList();
    }
    if (_hotOnly) {
      list = list.where((t) => t.isHot).toList();
    }
    return list;
  }

  void _resetFilters() {
    setState(() {
      _selectedCountry = null;
      _selectedStars = null;
      _hotOnly = false;
      _query = '';
      _ctrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final tours = _filtered;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Поиск туров',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _ctrl,
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Турция, Египет, отель...',
                hintStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () => setState(() {
                          _query = '';
                          _ctrl.clear();
                        }),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.2),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Фильтры
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: '🔥 Горящие',
                    selected: _hotOnly,
                    onTap: () => setState(() => _hotOnly = !_hotOnly),
                  ),
                  const SizedBox(width: 8),
                  ..._countries.map((c) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: c,
                      selected: _selectedCountry == c,
                      onTap: () => setState(() =>
                          _selectedCountry = _selectedCountry == c ? null : c),
                    ),
                  )),
                  _FilterChip(
                    label: '5★',
                    selected: _selectedStars == 5,
                    onTap: () => setState(() =>
                        _selectedStars = _selectedStars == 5 ? null : 5),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '4★+',
                    selected: _selectedStars == 4,
                    onTap: () => setState(() =>
                        _selectedStars = _selectedStars == 4 ? null : 4),
                  ),
                ],
              ),
            ),
          ),

          // Счётчик
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Найдено: ${tours.length} туров',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
                ),
                const Spacer(),
                if (_selectedCountry != null || _selectedStars != null ||
                    _hotOnly || _query.isNotEmpty)
                  GestureDetector(
                    onTap: _resetFilters,
                    child: const Text(
                      'Сбросить',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: tours.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: tours.length,
                    itemBuilder: (_, i) => _TourCard(tour: tours[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded, size: 72, color: AppColors.grey300),
          const SizedBox(height: 16),
          const Text('Ничего не найдено', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Попробуйте изменить фильтры',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _resetFilters,
            child: const Text('Сбросить фильтры'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Tour Card
// ═══════════════════════════════════════════════════════════════════
class _TourCard extends StatefulWidget {
  final Tour tour;
  const _TourCard({required this.tour});

  @override
  State<_TourCard> createState() => _TourCardState();
}

class _TourCardState extends State<_TourCard> {
  bool _inWishlist = false;
  final _wishlistService = WishlistService();
  StreamSubscription<bool>? _wishlistSub;

  @override
  void initState() {
    super.initState();
    _wishlistSub = _wishlistService
        .streamContains(widget.tour.id)
        .listen((v) {
          if (mounted) setState(() => _inWishlist = v);
        });
  }

  @override
  void dispose() {
    _wishlistSub?.cancel();
    super.dispose();
  }

  void _toggleWishlist() {
    _wishlistService.toggle(
      tourId: widget.tour.id,
      hotelName: widget.tour.hotelName,
      country: widget.tour.country,
      city: widget.tour.city,
      imageUrl: widget.tour.imageUrl,
      stars: widget.tour.stars,
      nights: widget.tour.nights,
      mealType: widget.tour.mealType,
      price: widget.tour.price,
      originalPrice: widget.tour.originalPrice,
      isHot: widget.tour.isHot,
    );
    // Стрим сам обновит _inWishlist — setState не нужен
  }

  String _fmt(double p) => p.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

  @override
  Widget build(BuildContext context) {
    final tour = widget.tour;

    return GestureDetector(
      onTap: () => context.push('/tours/${tour.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(18)),
                  child: CachedNetworkImage(
                    imageUrl: tour.imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(height: 180, color: AppColors.grey200),
                    errorWidget: (_, __, ___) =>
                        Container(height: 180, color: AppColors.grey100),
                  ),
                ),
                // Badges
                Positioned(
                  top: 12, left: 12,
                  child: Row(
                    children: [
                      if (tour.isHot)
                        _Badge(label: '🔥 Горящий', color: AppColors.secondary),
                      if (tour.hasDiscount) ...[
                        const SizedBox(width: 6),
                        _Badge(
                            label: '-${tour.discountPercent}%',
                            color: AppColors.error),
                      ],
                    ],
                  ),
                ),
                // Wishlist button
                Positioned(
                  top: 10, right: 10,
                  child: GestureDetector(
                    onTap: _toggleWishlist,
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        _inWishlist ? Icons.favorite : Icons.favorite_outline,
                        color: _inWishlist ? AppColors.error : AppColors.grey400,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                // Rating
                Positioned(
                  bottom: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star,
                            color: AppColors.warning, size: 13),
                        const SizedBox(width: 3),
                        Text('${tour.rating}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tour.hotelName, style: AppTextStyles.titleLarge),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.grey500),
                      const SizedBox(width: 2),
                      Text(
                        '${tour.country}, ${tour.city}',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.grey500),
                      ),
                      const SizedBox(width: 6),
                      ...List.generate(
                        tour.stars,
                        (_) => const Icon(Icons.star,
                            size: 12, color: AppColors.warning),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      _InfoChip('${tour.nights} ночей'),
                      _InfoChip(tour.mealType),
                      _InfoChip('из ${tour.departureCity}'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (tour.hasDiscount)
                            Text(
                              '${_fmt(tour.originalPrice)} ₸',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.grey400,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          Text(
                            '${_fmt(tour.price)} ₸',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () => context.push('/tours/${tour.id}'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Подробнее'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Helpers
// ═══════════════════════════════════════════════════════════════════
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.grey100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.grey700,
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: AppColors.grey100, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey700)),
    );
  }
}