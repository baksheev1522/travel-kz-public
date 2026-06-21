import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/hotel_model.dart';
import '../../../../data/services/hotel_service.dart';
import '../../../../data/services/bonus_service.dart';
import '../../../../core/utils/share_utils.dart';
import '../../../../core/widgets/info_bottom_sheet.dart';

class HotelDetailPage extends StatefulWidget {
  final String hotelId;
  final String? dates;
  const HotelDetailPage({super.key, required this.hotelId, this.dates});

  @override
  State<HotelDetailPage> createState() => _HotelDetailPageState();
}

class _HotelDetailPageState extends State<HotelDetailPage> {
  Map<String, dynamic>? _hotel;
  bool _loading = true;
  int _currentImage = 0;
  bool _inWishlist = false;
  bool _likesSelected = true;
  int _selectedCategory = 0;

  final _hotelService = HotelService();

  static const _categories = ['Отель', 'Номер', 'Бассейн', 'Ресторан'];

  static const _likes = [
    ('сервис', 120), ('питание', 99), ('номер', 84),
    ('красивый вид', 69), ('пляж', 68), ('расположение', 55),
  ];

  static const _dislikes = [
    ('шумно', 32), ('очереди', 25), ('wi-fi', 18),
    ('трансфер', 15),
  ];

  static const _coords = {
    'Турция': (36.8841, 31.0456),
    'Египет': (27.2574, 33.8129),
    'Таиланд': (7.8804, 98.2963),
    'ОАЭ': (25.2048, 55.2708),
    'Мальдивы': (3.2028, 73.2207),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final hotel = await _hotelService.getHotelById(widget.hotelId);
    if (mounted) setState(() { _hotel = hotel; _loading = false; });
  }

  Future<void> _openMap() async {
    if (_hotel == null) return;
    final coords = _coords[_hotel!['country']] ?? (51.1694, 71.4491);
    final query = Uri.encodeComponent('${_hotel!['name']} ${_hotel!['city']}');
    final url = Uri.parse(
      'https://maps.google.com/?q=$query&ll=${coords.$1},${coords.$2}&z=15',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_hotel == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: const Color(0xFF00897B)),
        body: const Center(child: Text('Отель не найден')),
      );
    }

    final hotel = _hotel!;
    final images = List<String>.from(hotel['imageUrls'] ?? [hotel['imageUrl']]);
    final rating = (hotel['rating'] as num).toDouble();
    final stars = hotel['stars'] as int;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: const Color(0xFF00897B),
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: GestureDetector(
                      onTap: () => setState(() => _inWishlist = !_inWishlist),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          _inWishlist ? Icons.favorite : Icons.favorite_outline,
                          color: _inWishlist ? AppColors.error : Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      PageView.builder(
                        itemCount: images.length,
                        onPageChanged: (i) => setState(() => _currentImage = i),
                        itemBuilder: (_, i) => CachedNetworkImage(
                          imageUrl: images[i],
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: AppColors.grey200),
                          errorWidget: (_, __, ___) => Container(color: AppColors.grey200),
                        ),
                      ),
                      Positioned(
                        bottom: 12, left: 0, right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(images.length, (i) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _currentImage == i ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _currentImage == i ? Colors.white : Colors.white54,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          )),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category circles
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: List.generate(_categories.length, (i) => Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedCategory = i),
                            child: Column(
                              children: [
                                Container(
                                  width: 60, height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _selectedCategory == i
                                          ? const Color(0xFF00897B)
                                          : AppColors.grey300,
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: images[i % images.length],
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) =>
                                          Container(color: AppColors.grey200),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _categories[i],
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _selectedCategory == i
                                        ? const Color(0xFF00897B)
                                        : AppColors.grey600,
                                    fontWeight: _selectedCategory == i
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                      ),
                    ),

                    const Divider(height: 1),

                    // Stars
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: Row(
                        children: [
                          Row(
                            children: List.generate(stars, (_) =>
                              const Icon(Icons.star, color: AppColors.warning, size: 18)),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => setState(() => _inWishlist = !_inWishlist),
                            child: Icon(
                              _inWishlist ? Icons.favorite : Icons.favorite_outline,
                              color: _inWishlist ? AppColors.error : AppColors.grey400,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () => ShareUtils.shareHotel(
                              context: context,
                              name: hotel['name'] as String,
                              country: hotel['country'] as String,
                              city: hotel['city'] as String,
                              stars: hotel['stars'] as int,
                              rating: (hotel['rating'] as num).toDouble(),
                            ),
                            child: const Icon(Icons.share_outlined,
                                color: AppColors.grey400, size: 24),
                          ),
                        ],
                      ),
                    ),

                    // Name
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Text(
                        '${(hotel['name'] as String).toUpperCase()} $stars*',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.grey900,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Location + Rating
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${hotel['country']}, ${hotel['city']}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.grey800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: _openMap,
                                  child: const Row(
                                    children: [
                                      Icon(Icons.location_on_outlined,
                                          color: Color(0xFF00897B), size: 18),
                                      SizedBox(width: 4),
                                      Text('На карте',
                                          style: TextStyle(
                                            color: Color(0xFF00897B),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          )),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF003580),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text('Booking.com',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF003580),
                                    fontWeight: FontWeight.w700,
                                  )),
                              Text(
                                '${hotel['reviewsCount']} отзывов',
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.grey500),
                              ),
                              const SizedBox(height: 4),
                              const Text('Все отзывы',
                                  style: TextStyle(
                                    color: Color(0xFF00897B),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  )),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 24),

                    // Likes / Dislikes
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Туристам', style: AppTextStyles.headlineMedium),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _likesSelected = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _likesSelected ? AppColors.grey100 : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('Нравится',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _likesSelected ? AppColors.grey900 : AppColors.grey500,
                                    )),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _likesSelected = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: !_likesSelected ? AppColors.grey100 : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('Не нравится',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: !_likesSelected ? AppColors.grey900 : AppColors.grey500,
                                    )),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 8, runSpacing: 8,
                        children: (_likesSelected ? _likes : _dislikes)
                            .map((item) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFF00897B)),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(item.$1,
                                      style: const TextStyle(
                                        color: Color(0xFF00897B),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      )),
                                  const SizedBox(width: 6),
                                  Text('${item.$2}',
                                      style: const TextStyle(
                                        color: AppColors.grey400,
                                        fontSize: 11,
                                      )),
                                ],
                              ),
                            ))
                            .toList(),
                      ),
                    ),

                    const Divider(height: 24),

                    // TravelKZ recommends
                    if ((hotel['isRecommended'] as bool?) == true)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.grey200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 48, height: 48,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00897B),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.thumb_up_outlined,
                                    color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('TravelKZ рекомендует',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.grey900,
                                        )),
                                    Text(
                                      '${((hotel['reviewsCount'] as int) * 4.2).round()} туров куплено',
                                      style: AppTextStyles.bodySmall
                                          .copyWith(color: AppColors.grey500),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      hotel['description'] as String,
                                      style: AppTextStyles.bodyMedium
                                          .copyWith(color: AppColors.grey700),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Amenities
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Удобства', style: AppTextStyles.headlineMedium),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 8, runSpacing: 8,
                        children: (List<String>.from(hotel['amenities'] as List))
                            .map((a) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00897B).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_outline,
                                      size: 14, color: Color(0xFF00897B)),
                                  const SizedBox(width: 5),
                                  Text(a,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF00897B),
                                        fontWeight: FontWeight.w500,
                                      )),
                                ],
                              ),
                            ))
                            .toList(),
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),

          // Bottom bar
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                16, 12, 16,
                MediaQuery.of(context).padding.bottom + 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () => _showVariants(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  backgroundColor: const Color(0xFF00897B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Показать варианты',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showVariants(BuildContext context) {
    final variants = ((_hotel!['variants'] as List?) ?? [])
        .map((v) => HotelRoomVariant.fromMap(Map<String, dynamic>.from(v)))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _VariantsSheet(
      hotel: _hotel!,
      variants: variants,
      dates: widget.dates,
    ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Variants Sheet
// ═══════════════════════════════════════════════════════════════════
class _VariantsSheet extends StatefulWidget {
  final Map<String, dynamic> hotel;
  final List<HotelRoomVariant> variants;
  final String? dates;
  const _VariantsSheet({required this.hotel, required this.variants, this.dates});

  @override
  State<_VariantsSheet> createState() => _VariantsSheetState();
}

class _VariantsSheetState extends State<_VariantsSheet> {
  int _adults = 2;

  static String _fmtDate(DateTime d) =>
      '${d.day}.${d.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final hotel = widget.hotel;
    final variants = widget.variants;
    String checkIn;
    String checkOut;
    if (widget.dates != null && widget.dates!.contains('—')) {
      final parts = widget.dates!.split('—');
      checkIn = parts[0].trim();
      checkOut = parts[1].trim();
    } else {
      final now = DateTime.now();
      checkIn = _fmtDate(now.add(const Duration(days: 3)));
      checkOut = _fmtDate(now.add(const Duration(days: 8)));
    }
    final nights = hotel['nights'] ?? 5;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      builder: (_, ctrl) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: AppColors.grey700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${(hotel['name'] as String).toUpperCase()} ${hotel['stars']}*',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey900,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.grey300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$checkIn - $checkOut',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                      builder: (_) => _GuestsSheet(
                        adults: _adults,
                        onConfirm: (v) => setState(() => _adults = v),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.grey300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$_adults взрослых',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          const Icon(Icons.edit_outlined,
                              size: 16, color: AppColors.grey500),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              controller: ctrl,
              padding: const EdgeInsets.all(16),
              itemCount: variants.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _VariantCard(
                variant: variants[i],
                checkIn: checkIn,
                checkOut: checkOut,
                nights: nights,
                hotel: hotel,
                adults: _adults,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Variant Card
// ═══════════════════════════════════════════════════════════════════
class _VariantCard extends StatelessWidget {
  final HotelRoomVariant variant;
  final String checkIn;
  final String checkOut;
  final int nights;
  final Map<String, dynamic> hotel;
  final int adults;

  const _VariantCard({
    required this.variant,
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.hotel,
    required this.adults,
  });

  String _fmt(double p) => p.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => _VariantDetailSheet(
          variant: variant,
          hotel: hotel,
          adults: adults,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: variant.isBestPrice ? const Color(0xFF00897B) : AppColors.grey200,
            width: variant.isBestPrice ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (variant.isBestPrice)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4081),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Выгодная цена',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            Row(children: [
              const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.grey500),
              const SizedBox(width: 8),
              Text('$checkIn - $checkOut, $nights ночей', style: AppTextStyles.bodyMedium),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.restaurant_outlined, size: 16, color: AppColors.grey500),
              const SizedBox(width: 8),
              Text(variant.mealType, style: AppTextStyles.bodyMedium),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.bed_outlined, size: 16, color: AppColors.grey500),
              const SizedBox(width: 8),
              Text('Номер: ${variant.roomType} (${variant.roomSize})',
                  style: AppTextStyles.bodyMedium),
            ]),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('${_fmt(variant.price)} ₸',
                    style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.grey900,
                    )),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('От ${_fmt(variant.pricePerMonth)} ₸ х мес',
                      style: const TextStyle(
                        fontSize: 11, color: Color(0xFF856404), fontWeight: FontWeight.w600,
                      )),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.grey400),
              ],
            ),
            const SizedBox(height: 4),
            const Text('✓ С учётом налогов',
                style: TextStyle(fontSize: 11, color: AppColors.grey500)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Variant Detail Sheet
// ═══════════════════════════════════════════════════════════════════
class _VariantDetailSheet extends StatefulWidget {
  final HotelRoomVariant variant;
  final Map<String, dynamic> hotel;
  final int adults;

  const _VariantDetailSheet({
    required this.variant,
    required this.hotel,
    required this.adults,
  });

  @override
  State<_VariantDetailSheet> createState() => _VariantDetailSheetState();
}

class _VariantDetailSheetState extends State<_VariantDetailSheet>
    with SingleTickerProviderStateMixin {
  bool _isChecking = false;
  bool _priceConfirmed = false;
  bool _submitted = false;

  late AnimationController _fillController;
  late Animation<double> _fillAnimation;
  int _earnedBonuses = 0;
  final _bonusService = BonusService();

  @override
  void initState() {
    super.initState();
    _fillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _fillAnimation = CurvedAnimation(
      parent: _fillController,
      curve: Curves.easeInOut,
    );
    _fillController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _priceConfirmed = true);
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) _showBenefits();
        });
      }
    });
  }

  @override
  void dispose() {
    _fillController.dispose();
    super.dispose();
  }

  void _startPriceCheck() {
    if (_isChecking) return;
    setState(() => _isChecking = true);
    _fillController.forward();
  }

  void _showBenefits() {
    final cashback = (widget.variant.price * 0.02).round();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BenefitsSheet(
        cashback: cashback,
        onContinue: () {
          Navigator.pop(context);
          Navigator.pop(context);
          context.push('/hotel-booking', extra: {
            'variant': widget.variant,
            'hotel': widget.hotel,
            'adults': widget.adults,
          });
        },
        onContactManager: () => Navigator.pop(context),
      ),
    );
  }

  String _fmt(double p) => p.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

  void _showManagerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, MediaQuery.of(context).padding.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2)),
              )),
              const SizedBox(height: 20),
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.support_agent_rounded,
                    color: AppColors.primary, size: 30),
              ),
              const SizedBox(height: 16),
              const Text('Персональный менеджер',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              const Text(
                'После бронирования вам будет назначен персональный менеджер, '
                'который будет с вами на связи 24/7 в WhatsApp и Telegram.\n\n'
                'Менеджер поможет с любыми вопросами — документы, '
                'изменения в бронировании, советы по курорту.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.grey600, height: 1.6),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.grey200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.access_time_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text('Менеджер ответит в течение 5 минут',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.grey900)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Понятно',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _SuccessView(earnedBonuses: _earnedBonuses);

    final hotel = widget.hotel;
    final variant = widget.variant;
    final cashback = (variant.price * 0.02).round();

    return Stack(
      children: [
        DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          builder: (_, ctrl) => SingleChildScrollView(
            controller: ctrl,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  0, 0, 0, MediaQuery.of(context).padding.bottom + 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Center(child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.grey300,
                        borderRadius: BorderRadius.circular(2)),
                  )),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: Text('Детали тура',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.grey900)),
                    ),
                  ),
                  const Divider(height: 20),

                  // Hotel info row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: hotel['imageUrl'] as String,
                            width: 64, height: 64, fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                                width: 64, height: 64, color: AppColors.grey200),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Row(
                                    children: List.generate(hotel['stars'] as int,
                                        (_) => const Icon(Icons.star,
                                            color: AppColors.warning, size: 14)),
                                  ),
                                  const SizedBox(width: 6),
                                  Text('#${hotel['reviewsCount']}',
                                      style: AppTextStyles.bodySmall
                                          .copyWith(color: AppColors.grey500)),
                                ],
                              ),
                              Text(
                                '${(hotel['name'] as String).toUpperCase()} ${hotel['stars']}*',
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                              Text('${hotel['country']}, ${hotel['city']}',
                                  style: AppTextStyles.bodySmall
                                      .copyWith(color: AppColors.grey500)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.grey300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('Без перелёта',
                                    style: TextStyle(
                                        fontSize: 11, color: AppColors.grey600)),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => ShareUtils.shareHotel(
                            context: context,
                            name: hotel['name'] as String,
                            country: hotel['country'] as String,
                            city: hotel['city'] as String,
                            stars: hotel['stars'] as int,
                            rating: (hotel['rating'] as num).toDouble(),
                          ),
                          child: const Icon(Icons.share_outlined,
                              color: AppColors.grey400),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Guests info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 18, color: AppColors.grey600),
                        const SizedBox(width: 8),
                        Text('${widget.adults} взрослых',
                            style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Price block
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.grey200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${_fmt(variant.price)} ₸',
                              style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.grey900)),
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3CD),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('От ${_fmt(variant.pricePerMonth)} ₸ х мес',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF856404),
                                      fontWeight: FontWeight.w600)),
                            ),
                          ]),
                          const SizedBox(height: 4),
                          const Text('✓ С учётом налогов',
                              style: TextStyle(fontSize: 11, color: AppColors.grey500)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Cashback banners
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF6B35), Color(0xFFE84040)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('10 000 ₸',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16)),
                                Text('на первую покупку',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.grey200),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('+${_fmt(cashback.toDouble())} ₸',
                                    style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14)),
                                const Text('кешбэком на бонусный счёт',
                                    style: TextStyle(
                                        color: AppColors.grey500, fontSize: 10)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('В стоимость проживания входит',
                        style: AppTextStyles.headlineMedium),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    height: 220,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _RoomIncludedCard(variant: variant, isSelected: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Info rows
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.grey200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _InfoRow(
                            icon: Icons.restaurant_outlined,
                            title: 'Питание',
                            subtitle: variant.mealType,
                          ),
                          const Divider(height: 1, indent: 56),
                          _InfoRow(
                            icon: Icons.receipt_outlined,
                            title: 'Налоги и сборы',
                            subtitle: 'Включены',
                          ),
                          const Divider(height: 1, indent: 56),
                          _InfoRow(
                            icon: Icons.headset_mic_outlined,
                            title: 'Сопровождение менеджера',
                            subtitle: 'Круглосуточная помощь в мессенджерах',
                            hasLink: true,
                            onLinkTap: _showManagerSheet,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // FAQ links
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _LinkRow(
                          label: 'Правила въезда и оплаты тура',
                          onTap: () => InfoBottomSheet.showPaymentRules(context),
                        ),
                        const SizedBox(height: 8),
                        _LinkRow(
                          label: 'Часто задаваемые вопросы',
                          onTap: () => InfoBottomSheet.showFaq(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Bottom button
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16, offset: const Offset(0, -4),
                ),
              ],
            ),
            child: _AnimatedCheckButton(
              fillAnimation: _fillAnimation,
              isChecking: _isChecking,
              priceConfirmed: _priceConfirmed,
              onTap: _startPriceCheck,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Animated Check Price Button
// ═══════════════════════════════════════════════════════════════════
class _AnimatedCheckButton extends StatelessWidget {
  final Animation<double> fillAnimation;
  final bool isChecking;
  final bool priceConfirmed;
  final VoidCallback onTap;

  const _AnimatedCheckButton({
    required this.fillAnimation,
    required this.isChecking,
    required this.priceConfirmed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isChecking || priceConfirmed ? null : onTap,
      child: AnimatedBuilder(
        animation: fillAnimation,
        builder: (_, __) => Container(
          height: 52,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14), color: AppColors.grey200),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: fillAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: const Color(0xFF00897B),
                  ),
                ),
              ),
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: priceConfirmed
                      ? const Row(
                          key: ValueKey('confirmed'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded,
                                color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text('Цена актуальна 😉',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ],
                        )
                      : isChecking
                          ? Row(
                              key: const ValueKey('checking'),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Уточняем цену',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: fillAnimation.value > 0.5
                                          ? Colors.white
                                          : AppColors.grey700,
                                    )),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      fillAnimation.value > 0.5
                                          ? Colors.white
                                          : AppColors.grey600,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              key: ValueKey('idle'),
                              'Уточнить цену',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.grey800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Benefits Sheet
// ═══════════════════════════════════════════════════════════════════
class _BenefitsSheet extends StatelessWidget {
  final int cashback;
  final VoidCallback onContinue;
  final VoidCallback onContactManager;

  const _BenefitsSheet({
    required this.cashback,
    required this.onContinue,
    required this.onContactManager,
  });

  String _fmt(double p) => p.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: AppColors.grey300, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          const Text('Преимущества заказа\nв приложении',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.grey900)),
          const SizedBox(height: 24),
          _BenefitItem(
            icon: Icons.percent_rounded,
            title: 'Кешбэк ${_fmt(cashback.toDouble())} ₸',
            description: 'При бронировании проживания в приложении Вам будет назначен личный менеджер. Отдел бронирования работает без выходных.',
          ),
          const SizedBox(height: 16),
          const _BenefitItem(
            icon: Icons.support_agent_rounded,
            title: 'Персональный менеджер',
            description: 'Бронируйте проживание и получайте возврат на ваш бонусный счёт. Используйте бонусы при следующем оформлении.',
          ),
          const SizedBox(height: 16),
          const _BenefitItem(
            icon: Icons.credit_card_rounded,
            title: 'Рассрочка и кредит',
            description: 'Ваш менеджер поможет с оформлением рассрочки или кредита через Home Credit Bank и Kaspi.',
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                border: Border.all(color: AppColors.grey200),
                borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Цена актуальна 😉',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.grey900)),
                      Text('Успейте забронировать по этой цене',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.grey500)),
                    ],
                  ),
                ),
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 22),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Продолжить',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onContactManager,
            child: const Text('Связаться с менеджером',
                style: TextStyle(
                    color: Color(0xFF00897B),
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFFC107).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFFFFC107), size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.grey900)),
              const SizedBox(height: 3),
              Text(description,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600)),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Success View
// ═══════════════════════════════════════════════════════════════════
class _SuccessView extends StatelessWidget {
  final int earnedBonuses;
  const _SuccessView({required this.earnedBonuses});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 32, 24, MediaQuery.of(context).padding.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF00897B).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline,
                size: 40, color: Color(0xFF00897B)),
          ),
          const SizedBox(height: 16),
          const Text('Заявка отправлена!', style: AppTextStyles.headlineLarge),
          const SizedBox(height: 8),
          Text(
            'Менеджер свяжется с вами\nв течение 30 минут',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.grey600),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00897B), Color(0xFF1A6FE8)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Начислены бонусы!',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    Text('+$earnedBonuses ₸ на следующий отдых',
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00897B)),
            child: const Text('Отлично!'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Room Included Card
// ═══════════════════════════════════════════════════════════════════
class _RoomIncludedCard extends StatelessWidget {
  final HotelRoomVariant variant;
  final bool isSelected;

  const _RoomIncludedCard({required this.variant, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF00897B) : AppColors.grey200,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(variant.roomType,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      Text('${variant.roomSize} на 2 взр',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.grey500)),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00897B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Выбранный номер',
                        style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF00897B),
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: CachedNetworkImage(
                imageUrl: variant.imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(color: AppColors.grey200),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Info Row
// ═══════════════════════════════════════════════════════════════════
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool hasLink;
  final VoidCallback? onLinkTap;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.hasLink = false,
    this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.grey500),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey900)),
                Text(subtitle,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500)),
                if (hasLink)
                  GestureDetector(
                    onTap: onLinkTap,
                    child: const Text('Подробнее',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Link Row
// ═══════════════════════════════════════════════════════════════════
class _LinkRow extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _LinkRow({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.grey200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Guests Sheet
// ═══════════════════════════════════════════════════════════════════
class _GuestsSheet extends StatefulWidget {
  final int adults;
  final void Function(int) onConfirm;
  const _GuestsSheet({required this.adults, required this.onConfirm});

  @override
  State<_GuestsSheet> createState() => _GuestsSheetState();
}

class _GuestsSheetState extends State<_GuestsSheet> {
  late int _adults;

  @override
  void initState() {
    super.initState();
    _adults = widget.adults;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: AppColors.grey300, borderRadius: BorderRadius.circular(2)),
          )),
          const SizedBox(height: 20),
          const Text('Гости', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RoundBtn(
                icon: Icons.remove,
                onTap: _adults > 1 ? () => setState(() => _adults--) : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text('$_adults', style: AppTextStyles.headlineLarge),
                    Text('взрослых',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.grey500)),
                  ],
                ),
              ),
              _RoundBtn(
                icon: Icons.add,
                onTap: _adults < 8 ? () => setState(() => _adults++) : null,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: () {
                widget.onConfirm(_adults);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Выбрать',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _RoundBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: onTap != null ? const Color(0xFF00897B) : AppColors.grey200,
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            color: onTap != null ? Colors.white : AppColors.grey400, size: 20),
      ),
    );
  }
}