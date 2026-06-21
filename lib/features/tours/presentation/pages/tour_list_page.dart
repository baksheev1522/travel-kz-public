import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/repositories/tour_repository.dart';
import '../../../../data/services/wishlist_service.dart';
import '../../../../domain/entities/entities.dart';

class TourListPage extends StatefulWidget {
  final Map<String, dynamic>? filters;
  const TourListPage({super.key, this.filters});

  @override
  State<TourListPage> createState() => _TourListPageState();
}

class _TourListPageState extends State<TourListPage> {
  final _repo = TourRepository();
  List<Tour> _tours = [];
  bool _loading = true;
  String _sort = 'Рекомендуемые';
  String _searchQuery = '';
  int? _starsFilter;
  String _mealFilter = 'Любое';

  final _sorts = [
    'Рекомендуемые',
    'Сначала дешёвые',
    'Сначала дорогие',
    'По рейтингу',
  ];

  String get _departureCity =>
      widget.filters?['departureCity'] as String? ?? 'Алматы';

  String get _tourists =>
      widget.filters?['tourists'] as String? ?? '2 взрослых';

  @override
  void initState() {
    super.initState();
    _loadTours();
  }

  Future<void> _loadTours() async {
    setState(() => _loading = true);
    try {
      List<Tour> tours;
      if (widget.filters?['hotOnly'] == true) {
        tours = await _repo.getHotTours();
      } else if (widget.filters?['country'] != null) {
        tours = await _repo.getToursByCountry(widget.filters!['country']);
      } else {
        tours = await _repo.getTours();
      }
      if (mounted) setState(() { _tours = tours; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Tour> get _sorted {
    var list = List<Tour>.from(_tours);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((t) =>
        t.hotelName.toLowerCase().contains(q) ||
        t.city.toLowerCase().contains(q) ||
        t.country.toLowerCase().contains(q)
      ).toList();
    }

    if (_starsFilter != null) {
      list = list.where((t) => t.stars >= _starsFilter!).toList();
    }

    if (_mealFilter != 'Любое') {
      list = list.where((t) => t.mealType == _mealFilter).toList();
    }

    switch (_sort) {
      case 'Сначала дешёвые': list.sort((a, b) => a.price.compareTo(b.price));
      case 'Сначала дорогие': list.sort((a, b) => b.price.compareTo(a.price));
      case 'По рейтингу':     list.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return list;
  }

  String get _title {
    if (widget.filters?['hotOnly'] == true) return '🔥 Горящие туры';
    if (widget.filters?['country'] != null) return widget.filters!['country'];
    return 'Все туры';
  }

  String get _subtitle {
    final dates = widget.filters?['dates'] as String?;
    final nights = widget.filters?['nights'] as String?;
    if (dates != null && nights != null) return '$dates на $nights';
    if (dates != null) return dates;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final tours = _sorted;
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            if (_subtitle.isNotEmpty)
              Text(_subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            onPressed: () => context.push('/ai-assistant'),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: const InputDecoration(
                  hintText: 'Поиск отеля',
                  hintStyle: TextStyle(color: AppColors.grey500, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: AppColors.grey500, size: 18),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),

          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _SortChip(
                    current: _sort,
                    options: _sorts,
                    onChange: (s) => setState(() => _sort = s),
                  ),
                  const SizedBox(width: 8),
                  _DropChip(
                    label: _starsFilter == null ? 'Звёздность' : '$_starsFilter★+',
                    active: _starsFilter != null,
                    onTap: () => showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                      builder: (_) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 16),
                          const Text('Звёздность', style: AppTextStyles.headlineMedium),
                          const SizedBox(height: 8),
                          ...{
                            'Любая': null,
                            '5★': 5,
                            '4★+': 4,
                            '3★+': 3,
                          }.entries.map((e) => ListTile(
                            title: Text(e.key, style: AppTextStyles.bodyLarge),
                            trailing: _starsFilter == e.value
                                ? const Icon(Icons.check, color: AppColors.primary)
                                : null,
                            onTap: () {
                              setState(() => _starsFilter = e.value);
                              Navigator.pop(context);
                            },
                          )),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _DropChip(
                    label: _mealFilter == 'Любое' ? 'Питание' : _mealFilter,
                    active: _mealFilter != 'Любое',
                    onTap: () => showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                      builder: (_) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 16),
                          const Text('Питание', style: AppTextStyles.headlineMedium),
                          const SizedBox(height: 8),
                          ...['Любое', 'All Inclusive', 'Завтраки', 'Полупансион']
                              .map((o) => ListTile(
                            title: Text(o, style: AppTextStyles.bodyLarge),
                            trailing: _mealFilter == o
                                ? const Icon(Icons.check, color: AppColors.primary)
                                : null,
                            onTap: () {
                              setState(() => _mealFilter = o);
                              Navigator.pop(context);
                            },
                          )),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              Text('Найдено: ${tours.length} туров',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600)),
            ]),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: tours.length,
                    itemBuilder: (_, i) => _TourResultCard(
                      tour: tours[i],
                      departureCity: _departureCity,
                      tourists: _tourists,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TourResultCard extends StatefulWidget {
  final Tour tour;
  final String departureCity;
  final String tourists;

  const _TourResultCard({
    required this.tour,
    required this.departureCity,
    required this.tourists,
  });

  @override
  State<_TourResultCard> createState() => _TourResultCardState();
}

class _TourResultCardState extends State<_TourResultCard> {
  bool _inWishlist = false;
  int _currentImage = 0;
  final _wishlistService = WishlistService();
  StreamSubscription<bool>? _wishlistSub;

  @override
  void initState() {
    super.initState();
    _wishlistSub = _wishlistService
        .streamContains(widget.tour.id)
        .listen((v) { if (mounted) setState(() => _inWishlist = v); });
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
  }

  String _fmt(double p) => p.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

  @override
  Widget build(BuildContext context) {
    final tour = widget.tour;
    return GestureDetector(
      onTap: () => context.push('/tours/${tour.id}', extra: {
        'departureCity': widget.departureCity,
        'tourists': widget.tourists,
      }),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: CachedNetworkImage(
                    imageUrl: tour.imageUrls.isNotEmpty
                        ? tour.imageUrls[_currentImage]
                        : tour.imageUrl,
                    height: 200, width: double.infinity, fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        Container(height: 200, color: AppColors.grey200),
                  ),
                ),
                Positioned(
                  top: 10, left: 10,
                  child: Row(
                    children: [
                      _MediaBadge(icon: Icons.videocam_outlined, count: 3),
                      const SizedBox(width: 6),
                      _MediaBadge(
                          icon: Icons.photo_library_outlined,
                          count: tour.imageUrls.length + 12),
                    ],
                  ),
                ),
                if (tour.rating >= 4.7)
                  Positioned(
                    bottom: 10, left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.thumb_up_outlined, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('TravelKZ рекомендует',
                              style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                if (tour.imageUrls.length > 1)
                  Positioned(
                    bottom: 10, left: 0, right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(tour.imageUrls.length, (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: _currentImage == i ? 16 : 6, height: 6,
                        decoration: BoxDecoration(
                          color: _currentImage == i ? Colors.white : Colors.white54,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      )),
                    ),
                  ),
                Positioned(
                  top: 10, right: 10,
                  child: GestureDetector(
                    onTap: _toggleWishlist,
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                      ),
                      child: Icon(
                        _inWishlist ? Icons.favorite : Icons.favorite_outline,
                        color: _inWishlist ? AppColors.error : AppColors.grey500,
                        size: 18,
                      ),
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
                  Row(
                    children: [
                      Row(children: [
                        ...List.generate(tour.stars, (_) =>
                            const Icon(Icons.star, color: AppColors.warning, size: 16)),
                        ...List.generate(5 - tour.stars, (_) =>
                            const Icon(Icons.star_outline, color: AppColors.warning, size: 16)),
                      ]),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF003580),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(tour.rating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Booking.com',
                              style: TextStyle(fontSize: 10, color: Color(0xFF003580), fontWeight: FontWeight.w600)),
                          Text('${tour.reviewsCount} отзывов',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('${tour.hotelName} ${tour.stars}*',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.grey900)),
                  const SizedBox(height: 2),
                  Text('${tour.country}, ${tour.city}',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.beach_access_outlined, size: 16, color: AppColors.grey500),
                      const SizedBox(width: 4),
                      Text('Песчаный пляж',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Цена за ${tour.nights} ночей',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500)),
                          Text(widget.tourists,
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500)),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (tour.hasDiscount)
                            Text('${_fmt(tour.originalPrice)} ₸',
                                style: const TextStyle(fontSize: 12, color: AppColors.grey400,
                                    decoration: TextDecoration.lineThrough)),
                          Text('${_fmt(tour.price)} ₸',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.grey900)),
                          const Text('перелет включён',
                              style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500)),
                        ],
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

class _MediaBadge extends StatelessWidget {
  final IconData icon;
  final int count;
  const _MediaBadge({required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 3),
          Text('$count',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _DropChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _DropChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.primary : AppColors.grey300),
        ),
        child: Row(
          children: [
            Text(label,
                style: TextStyle(fontSize: 13, color: active ? AppColors.primary : AppColors.grey700)),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 16,
                color: active ? AppColors.primary : AppColors.grey500),
          ],
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String current;
  final List<String> options;
  final ValueChanged<String> onChange;

  const _SortChip({required this.current, required this.options, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text('Сортировка', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            ...options.map((o) => ListTile(
                  title: Text(o, style: AppTextStyles.bodyLarge),
                  trailing: o == current
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () { Navigator.pop(context); onChange(o); },
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.grey300),
        ),
        child: const Row(
          children: [
            Icon(Icons.swap_vert, size: 16, color: AppColors.grey700),
            SizedBox(width: 4),
            Text('Сортировка', style: TextStyle(fontSize: 13, color: AppColors.grey700)),
          ],
        ),
      ),
    );
  }
}