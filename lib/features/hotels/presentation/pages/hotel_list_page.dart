import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/services/hotel_service.dart';

class HotelListPage extends StatefulWidget {
  final Map<String, dynamic>? filters;
  const HotelListPage({super.key, this.filters});

  @override
  State<HotelListPage> createState() => _HotelListPageState();
}

class _HotelListPageState extends State<HotelListPage> {
  final _hotelService = HotelService();
  List<Map<String, dynamic>> _hotels = [];
  bool _loading = true;
  String _sort = 'Рекомендуемые';
  int? _selectedStars;
  bool _recommendedOnly = false;
  String _searchQuery = '';

  String? _countryFilter;
  String? _mealFilter;

  static const _sorts = [
    'Рекомендуемые', 'Сначала дешёвые',
    'Сначала дорогие', 'По рейтингу',
  ];

  @override
  void initState() {
    super.initState();
    _countryFilter = widget.filters?['country'] as String?;
    _mealFilter = widget.filters?['meal'] as String?;
    final starsStr = widget.filters?['stars'] as String?;
    if (starsStr != null) {
      _selectedStars = int.tryParse(starsStr.replaceAll(RegExp(r'[^0-9]'), ''));
    }
    _loadHotels();
  }

  Future<void> _loadHotels() async {
    setState(() => _loading = true);
    try {
      final hotels = await _hotelService.getHotels();
      if (mounted) setState(() { _hotels = hotels; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    var list = List<Map<String, dynamic>>.from(_hotels);

    // Поиск
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((h) =>
        (h['name'] as String).toLowerCase().contains(q) ||
        (h['city'] as String).toLowerCase().contains(q) ||
        (h['country'] as String).toLowerCase().contains(q)
      ).toList();
    }

    // Фильтр по стране из формы
    if (_countryFilter != null && _countryFilter!.isNotEmpty) {
      list = list.where((h) =>
        (h['country'] as String?)
            ?.toLowerCase()
            .contains(_countryFilter!.toLowerCase()) == true
      ).toList();
    }

    // Фильтр по питанию из формы
    if (_mealFilter != null && _mealFilter!.isNotEmpty) {
      list = list.where((h) =>
        (h['mealType'] as String?) == _mealFilter
      ).toList();
    }

    // Звёзды
    if (_selectedStars != null) {
      list = list.where((h) => (h['stars'] as int) >= _selectedStars!).toList();
    }

    // Только рекомендованные
    if (_recommendedOnly) {
      list = list.where((h) => (h['isRecommended'] as bool?) == true).toList();
    }

    // Сортировка
    switch (_sort) {
      case 'Сначала дешёвые':
        list.sort((a, b) => (a['price'] as num? ?? 0).compareTo(b['price'] as num? ?? 0));
      case 'Сначала дорогие':
        list.sort((a, b) => (b['price'] as num? ?? 0).compareTo(a['price'] as num? ?? 0));
      case 'По рейтингу':
        list.sort((a, b) => (b['rating'] as num).compareTo(a['rating'] as num));
    }

    return list;
  }

  String get _subtitle {
    final dates = widget.filters?['dates'] as String?;
    if (dates != null && dates.isNotEmpty) return dates;
    return '';
  }

  String get _title {
    if (_countryFilter != null && _countryFilter!.isNotEmpty) {
      return 'Отели — $_countryFilter';
    }
    return 'Отели';
  }

  @override
  Widget build(BuildContext context) {
    final hotels = _filtered;
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00897B),
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
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Поиск ─────────────────────────────────────────
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

                // ── Фильтры ───────────────────────────────────────
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
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: '👍 Рекомендуем',
                          selected: _recommendedOnly,
                          onTap: () => setState(() => _recommendedOnly = !_recommendedOnly),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Счётчик ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(children: [
                    Text('Найдено: ${hotels.length} отелей',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600)),
                  ]),
                ),
                const Divider(height: 1),

                // ── Список ────────────────────────────────────────
                Expanded(
                  child: hotels.isEmpty
                      ? const Center(
                          child: Text('Отели не найдены',
                              style: AppTextStyles.headlineMedium))
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: hotels.length,
                          itemBuilder: (_, i) => _HotelMapCard(
  hotel: hotels[i],
  dates: widget.filters?['dates'] as String?,
),
                        ),
                ),
              ],
            ),
    );
  }
}

// ── Hotel Card ────────────────────────────────────────────────────

class _HotelMapCard extends StatefulWidget {
  final Map<String, dynamic> hotel;
  final String? dates;
  const _HotelMapCard({required this.hotel, this.dates});

  @override
  State<_HotelMapCard> createState() => _HotelMapCardState();
}

class _HotelMapCardState extends State<_HotelMapCard> {
  bool _inWishlist = false;

  @override
  Widget build(BuildContext context) {
    final hotel = widget.hotel;
    final images = List<String>.from(hotel['imageUrls'] ?? [hotel['imageUrl']]);
    final stars = hotel['stars'] as int;
    final rating = (hotel['rating'] as num).toDouble();

    return GestureDetector(
      onTap: () => context.push(
        '/hotels/${hotel['id']}',
        extra: {'dates': widget.dates},
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
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
                    imageUrl: images.first,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
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
                          count: images.length + 10),
                    ],
                  ),
                ),
                if ((hotel['isRecommended'] as bool?) == true)
                  Positioned(
                    bottom: 10, left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00897B),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.thumb_up_outlined, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('TravelKZ рекомендует',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  top: 10, right: 10,
                  child: GestureDetector(
                    onTap: () => setState(() => _inWishlist = !_inWishlist),
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8),
                        ],
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
                      Row(
                        children: List.generate(stars,
                            (_) => const Icon(Icons.star, color: AppColors.warning, size: 16)),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF003580),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(rating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Booking.com',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF003580),
                                  fontWeight: FontWeight.w600)),
                          Text('${hotel['reviewsCount']} отзывов',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.grey500)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('${hotel['name']} $stars*',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.grey900)),
                  const SizedBox(height: 2),
                  Text('${hotel['country']}, ${hotel['city']}',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.beach_access_outlined, size: 14, color: AppColors.grey500),
                      const SizedBox(width: 4),
                      Text(hotel['beachType'] as String? ?? 'Пляж',
                          style: const TextStyle(fontSize: 12, color: AppColors.grey600)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Цена за ${hotel['nights']} ночей, 2 взрослых',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500)),
                      const Text('перелёт не включён',
                          style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF00897B),
                              fontWeight: FontWeight.w500)),
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

// ── Helpers ───────────────────────────────────────────────────────

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
              style: const TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF00897B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? const Color(0xFF00897B) : AppColors.grey300),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.grey700)),
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
                      ? const Icon(Icons.check, color: Color(0xFF00897B))
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    onChange(o);
                  },
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
            Text('Сортировка',
                style: TextStyle(fontSize: 13, color: AppColors.grey700)),
          ],
        ),
      ),
    );
  }
}