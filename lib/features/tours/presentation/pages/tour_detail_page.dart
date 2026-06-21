import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/repositories/tour_repository.dart';
import '../../../../data/services/review_service.dart';
import '../../../../domain/entities/entities.dart';
import '../../../../data/services/bonus_service.dart';
import '../../../../data/services/wishlist_service.dart';
import '../../../../core/utils/share_utils.dart';
import '../../../../core/widgets/story_viewer.dart';

class TourDetailPage extends StatefulWidget {
  final String tourId;
  final String departureCity;
  final String tourists;
  const TourDetailPage({
  super.key,
  required this.tourId,
  this.departureCity = 'Алматы',
  this.tourists = '2 взрослых', // ← добавь
});

  @override
  State<TourDetailPage> createState() => _TourDetailPageState();
}

class _TourDetailPageState extends State<TourDetailPage>
    with SingleTickerProviderStateMixin {
  Tour? _tour;
  List<Review> _reviews = [];
  bool _loading = true;
  bool _inWishlist = false;
  int _currentImage = 0;
  late TabController _tabCtrl;
  bool _likesSelected = true;

  final _repo = TourRepository();
  final _reviewService = ReviewService();
  final _wishlistService = WishlistService();

  static const _categories = ['Отель', 'Территория', 'Номер'];
  int _selectedCategory = 0;

  static const _likes = [
    ('питание', 296), ('сервис', 216), ('для детей', 143),
    ('номер', 113), ('пляж', 101), ('расположение', 89),
    ('бассейн', 76),
  ];

  static const _dislikes = [
    ('шумно', 45), ('очереди', 38), ('wi-fi', 22),
    ('трансфер', 19), ('цены в баре', 15),
  ];

  static const _roomTypes = [
    _RoomType('Стандартный номер', '28 м²', 'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=300'),
    _RoomType('Делюкс с видом на море', '38 м²', 'https://images.unsplash.com/photo-1618773928121-c32242e63f39?w=300'),
    _RoomType('Семейный номер', '55 м²', 'https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=300'),
    _RoomType('Люкс', '75 м²', 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=300'),
  ];

  // Координаты по стране
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
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadData();
    _wishlistService.contains(widget.tourId).then((v) {
      if (mounted) setState(() => _inWishlist = v);
    });
  }

  Future<void> _loadData() async {
    try {
      final tour = await _repo.getTourById(widget.tourId);
      final reviews = await _reviewService.getReviewsForTour(widget.tourId);
      if (mounted) {
        setState(() {
          _tour = tour;
          _reviews = reviews;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openMap() async {
    if (_tour == null) return;
    final coords = _coords[_tour!.country] ?? (51.1694, 71.4491);
    final query = Uri.encodeComponent('${_tour!.hotelName} ${_tour!.city}');
    final url = Uri.parse(
      'https://maps.google.com/?q=$query&ll=${coords.$1},${coords.$2}&z=15',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_tour == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: AppColors.primary),
        body: const Center(child: Text('Тур не найден')),
      );
    }

    final tour = _tour!;
    final ratingNum = (tour.rating * 10).round() / 10;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Photo AppBar ──────────────────────────────────────
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppColors.primary,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18,
                      ),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: GestureDetector(
                    onTap: () {
                      _wishlistService.toggle(
                        tourId: _tour!.id,
                        hotelName: _tour!.hotelName,
                        country: _tour!.country,
                        city: _tour!.city,
                        imageUrl: _tour!.imageUrl,
                        stars: _tour!.stars,
                        nights: _tour!.nights,
                        mealType: _tour!.mealType,
                        price: _tour!.price,
                        originalPrice: _tour!.originalPrice,
                        isHot: _tour!.isHot,
                      ).then((added) {
                        if (mounted) setState(() => _inWishlist = added);
                      });
                    },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          _inWishlist
                              ? Icons.favorite
                              : Icons.favorite_outline,
                          color: _inWishlist
                              ? AppColors.error
                              : Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                    child: GestureDetector(
                      onTap: () => ShareUtils.shareTour(
                        context: context,
                        title: tour.title,
                        country: tour.country,
                        city: tour.city,
                        price: tour.price,
                        nights: tour.nights,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      PageView.builder(
                        itemCount: tour.imageUrls.isEmpty
                            ? 1
                            : tour.imageUrls.length,
                        onPageChanged: (i) =>
                            setState(() => _currentImage = i),
                        itemBuilder: (_, i) => CachedNetworkImage(
                          imageUrl: tour.imageUrls.isEmpty
                              ? tour.imageUrl
                              : tour.imageUrls[i],
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: AppColors.grey200),
                          errorWidget: (_, __, ___) =>
                              Container(color: AppColors.grey200),
                        ),
                      ),
                      // Dot indicators
                      Positioned(
                        bottom: 12,
                        left: 0, right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            tour.imageUrls.isEmpty
                                ? 1
                                : tour.imageUrls.length,
                            (i) => Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 3),
                              width: _currentImage == i ? 20 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _currentImage == i
                                    ? Colors.white
                                    : Colors.white54,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Photo count
                      Positioned(
                        bottom: 12, right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_currentImage + 1}/${tour.imageUrls.isEmpty ? 1 : tour.imageUrls.length}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
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
                    // ── Category circles ──────────────────────────
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: List.generate(
                          _categories.length,
                          (i) => Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _selectedCategory = i);
                                StoryViewer.show(
                                  context: context,
                                  images: tour.imageUrls.isNotEmpty ? tour.imageUrls : [tour.imageUrl],
                                  initialIndex: i.clamp(0, (tour.imageUrls.isNotEmpty ? tour.imageUrls.length : 1) - 1),
                                  labels: _categories,
                                );
                              },
                              child: Column(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _selectedCategory == i
                                            ? AppColors.primary
                                            : AppColors.grey300,
                                        width: 2,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: CachedNetworkImage(
                                        imageUrl: tour.imageUrls.isNotEmpty
                                            ? tour.imageUrls[
                                                i % tour.imageUrls.length]
                                            : tour.imageUrl,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) =>
                                            Container(
                                          color: AppColors.grey200,
                                          child: const Icon(
                                              Icons.image_outlined,
                                              color: AppColors.grey400),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _categories[i],
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _selectedCategory == i
                                          ? AppColors.primary
                                          : AppColors.grey600,
                                      fontWeight: _selectedCategory == i
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const Divider(height: 1),

                    // ── Stars + wishlist ──────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: Row(
                        children: [
                          Row(
                            children: List.generate(
                              tour.stars,
                              (_) => const Icon(Icons.star,
                                  color: AppColors.warning, size: 18),
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                                onTap: () {
                                  _wishlistService.toggle(
                                    tourId: _tour!.id,
                                    hotelName: _tour!.hotelName,
                                    country: _tour!.country,
                                    city: _tour!.city,
                                    imageUrl: _tour!.imageUrl,
                                    stars: _tour!.stars,
                                    nights: _tour!.nights,
                                    mealType: _tour!.mealType,
                                    price: _tour!.price,
                                    originalPrice: _tour!.originalPrice,
                                    isHot: _tour!.isHot,
                                  ).then((added) {
                                    if (mounted) setState(() => _inWishlist = added);
                                  });
                                },
                            child: Icon(
                              _inWishlist
                                  ? Icons.favorite
                                  : Icons.favorite_outline,
                              color: _inWishlist
                                  ? AppColors.error
                                  : AppColors.grey400,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 16),
                            GestureDetector(
                              onTap: () => ShareUtils.shareTour(
                                context: context,
                                title: tour.title,
                                country: tour.country,
                                city: tour.city,
                                price: tour.price,
                                nights: tour.nights,
                              ),
                              child: const Icon(Icons.share_outlined,
                                  color: AppColors.grey400, size: 24),
                            ),
                        ],
                      ),
                    ),

                    // ── Hotel name ────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Text(
                        '${tour.hotelName.toUpperCase()} ${tour.stars}*',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.grey900,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Location + Rating ─────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Location
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${tour.country}, ${tour.city}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.grey800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: _openMap,
                                  child: Row(
                                    children: [
                                      const Icon(
                                          Icons.location_on_outlined,
                                          color: AppColors.primary,
                                          size: 18),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'На карте',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Booking rating
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
                                  ratingNum.toString(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Booking.com',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF003580),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${tour.reviewsCount} отзывов',
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.grey500),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () => _showAllReviews(context),
                                child: const Text(
                                  'Все отзывы',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 24),

                    // ── Нравится / Не нравится ────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Text('Туристам',
                          style: AppTextStyles.headlineMedium),
                    ),
                    const SizedBox(height: 12),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _likesSelected = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
                                decoration: BoxDecoration(
                                  color: _likesSelected
                                      ? AppColors.grey100
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Нравится',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _likesSelected
                                        ? AppColors.grey900
                                        : AppColors.grey500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _likesSelected = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
                                decoration: BoxDecoration(
                                  color: !_likesSelected
                                      ? AppColors.grey100
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Не нравится',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: !_likesSelected
                                        ? AppColors.grey900
                                        : AppColors.grey500,
                                  ),
                                ),
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
                        spacing: 8,
                        runSpacing: 8,
                        children: (_likesSelected ? _likes : _dislikes)
                            .map((item) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: AppColors.primary),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        item.$1,
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${item.$2}',
                                        style: const TextStyle(
                                          color: AppColors.grey400,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ),

                    const Divider(height: 24),

                    // ── TravelKZ рекомендует ──────────────────────
                    if (tour.rating >= 4.5)
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
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.thumb_up_outlined,
                                    color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'TravelKZ рекомендует',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.grey900,
                                      ),
                                    ),
                                    Text(
                                      '${(tour.reviewsCount * 4.2).round()} туров куплено',
                                      style: AppTextStyles.bodySmall
                                          .copyWith(color: AppColors.grey500),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      tour.description,
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

                    // ── Типы номеров ──────────────────────────────
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Типы номеров',
                          style: AppTextStyles.headlineMedium),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 135,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _roomTypes.length,
                        itemBuilder: (_, i) {
                          final room = _roomTypes[i];
                          return Container(
                                  width: 200,
                                  margin: const EdgeInsets.only(right: 12),
                                  clipBehavior: Clip.hardEdge,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.grey200),
                                  ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    bottomLeft: Radius.circular(12),
                                  ),
                                  child: CachedNetworkImage(
                                    imageUrl: room.imageUrl,
                                    width: 80,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Container(
                                      width: 80,
                                      color: AppColors.grey200,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.crop_square,
                                            size: 14,
                                            color: AppColors.grey400),
                                        Text(
                                          room.size,
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                  color: AppColors.grey500),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          room.name,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.grey900,
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        const Icon(
                                            Icons.open_in_new,
                                            size: 14,
                                            color: AppColors.primary),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // ── Включено / Не включено ────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Включено в стоимость',
                              style: AppTextStyles.headlineMedium),
                          const SizedBox(height: 10),
                          ...tour.included.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: AppColors.success, size: 18),
                                const SizedBox(width: 10),
                                Text(item, style: AppTextStyles.bodyMedium),
                              ],
                            ),
                          )),
                          const SizedBox(height: 12),
                          const Text('Не включено',
                              style: AppTextStyles.titleLarge),
                          const SizedBox(height: 10),
                          ...tour.notIncluded.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.cancel_outlined,
                                    color: AppColors.grey400, size: 18),
                                const SizedBox(width: 10),
                                Text(item, style: AppTextStyles.bodyMedium),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // ── Отзывы ────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Text('Отзывы',
                              style: AppTextStyles.headlineMedium),
                          const Spacer(),
                          if (_reviews.isNotEmpty)
                            GestureDetector(
                              onTap: () => _showAllReviews(context),
                              child: const Text(
                                'Все отзывы',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_reviews.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Пока нет отзывов',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.grey500),
                        ),
                      )
                    else
                      ..._reviews.take(3).map((r) => _ReviewCard(review: r)),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),

          // ── Bottom bar ────────────────────────────────────────
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
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_tour!.hasDiscount)
                        Text(
                          '${_fmt(_tour!.originalPrice)} ₸',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.grey400,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      Text(
                        '${_fmt(_tour!.price)} ₸',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.grey900,
                        ),
                      ),
                      const Text(
                        'за 2 взрослых · перелёт включён',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.grey500),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showBookingSheet(context),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Забронировать',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAllReviews(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ReviewsSheet(
        reviews: _reviews,
        tour: _tour!,
      ),
    );
  }

  void _showBookingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _BookingSheet(
        tour: _tour!,
        departureCity: widget.departureCity,
        tourists: widget.tourists,
      ),
    );
  }

  String _fmt(double p) => p.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
}

// ─── Room Type ────────────────────────────────────────────────────
class _RoomType {
  final String name;
  final String size;
  final String imageUrl;
  const _RoomType(this.name, this.size, this.imageUrl);
}

// ─── Review Card ──────────────────────────────────────────────────
class _ReviewCard extends StatelessWidget {
  final Review review;
  const _ReviewCard({required this.review});

  Color get _ratingColor {
    switch (review.ratingLabel) {
      case 'Отлично': return const Color(0xFF4CAF50);
      case 'Хорошо': return const Color(0xFF8BC34A);
      case 'Приемлемо': return const Color(0xFFFFC107);
      case 'Плохо': return const Color(0xFFFF5722);
      default: return AppColors.grey400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  review.userName[0],
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName,
                        style: AppTextStyles.titleMedium),
                    Text(
                      _formatDate(review.date),
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.grey500),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _ratingColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  review.ratingLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (review.pros.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('Плюсы',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey500)),
            const SizedBox(height: 4),
            Text(review.pros, style: AppTextStyles.bodyMedium),
          ],
          if (review.cons.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Минусы',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey500)),
            const SizedBox(height: 4),
            Text(review.cons, style: AppTextStyles.bodyMedium),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      '', 'янв', 'февр', 'март', 'апр', 'май', 'июнь',
      'июль', 'авг', 'сент', 'окт', 'нояб', 'дек',
    ];
    return '${date.day} ${months[date.month]}. ${date.year}';
  }
}

// ─── Reviews Sheet ────────────────────────────────────────────────
class _ReviewsSheet extends StatelessWidget {
  final List<Review> reviews;
  final Tour tour;

  const _ReviewsSheet({required this.reviews, required this.tour});

  @override
  Widget build(BuildContext context) {
    final ratingNum = (tour.rating * 10).round() / 10;

    final counts = {
      'Отлично': reviews.where((r) => r.ratingLabel == 'Отлично').length,
      'Хорошо': reviews.where((r) => r.ratingLabel == 'Хорошо').length,
      'Приемлемо': reviews.where((r) => r.ratingLabel == 'Приемлемо').length,
      'Плохо': reviews.where((r) => r.ratingLabel == 'Плохо').length,
      'Не советую': reviews.where((r) => r.ratingLabel == 'Не советую').length,
    };
    final maxCount = counts.values.fold(0, (a, b) => a > b ? a : b);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: AppColors.grey700),
                const SizedBox(width: 8),
                Text(
                  'Отзывы о ${tour.hotelName} ${tour.stars}*',
                  style: AppTextStyles.titleMedium,
                ),
              ],
            ),
          ),

          // Rating summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        ratingNum.toString(),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('Хорошо',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(
                      'На основании ${tour.reviewsCount} отзывов',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.grey500),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: counts.entries.map((e) {
                      final pct = maxCount > 0
                          ? e.value / maxCount
                          : 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 70,
                              child: Text(e.key,
                                  style: AppTextStyles.bodySmall
                                      .copyWith(color: AppColors.primary)),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: pct.toDouble(),
                                  backgroundColor: AppColors.grey200,
                                  color: AppColors.primary,
                                  minHeight: 8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text('${e.value}',
                                style: AppTextStyles.bodySmall),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 24),

          Expanded(
            child: ListView.builder(
              controller: ctrl,
              itemCount: reviews.length,
              itemBuilder: (_, i) => _ReviewCard(review: reviews[i]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Booking Sheet ────────────────────────────────────────────────
class _BookingSheet extends StatefulWidget {
  final Tour tour;
  final String departureCity;
  final String tourists;
  const _BookingSheet({
  required this.tour,
  required this.departureCity,
  this.tourists = '2 взрослых', // ← добавь
});
 
  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}
 
class _BookingSheetState extends State<_BookingSheet>
    with SingleTickerProviderStateMixin {
  int _adults = 2;
  int _children = 0;
  bool _useBonuses = false;
  bool _loadingBonuses = true;
  int _bonusBalance = 0;
 
  // Анимация кнопки
  bool _isChecking = false;
  bool _priceConfirmed = false;
  late AnimationController _fillController;
  late Animation<double> _fillAnimation;
 
  final _bonusService = BonusService();
 
  @override
  void initState() {
    super.initState();
    final parts = widget.tourists.split('+');
      _adults = int.tryParse(parts[0].trim().split(' ').first) ?? 2;
      if (parts.length > 1) {
        _children = int.tryParse(parts[1].trim().split(' ').first) ?? 0;
      }
    _loadBonuses();
 
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
 
  Future<void> _loadBonuses() async {
    final balance = await _bonusService.getBalance();
    if (mounted) setState(() { _bonusBalance = balance; _loadingBonuses = false; });
  }
 
  double get _total => widget.tour.price * (_adults + _children * 0.7);
  double get _discount =>
      _useBonuses ? _bonusBalance.toDouble().clamp(0, _total * 0.5) : 0;
  double get _finalPrice => (_total - _discount).clamp(0, double.infinity);
 
  void _startPriceCheck() {
    if (_isChecking) return;
    setState(() => _isChecking = true);
    _fillController.forward();
  }
 
  void _showBenefits() {
    final cashback = (_finalPrice * 0.05).round();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BenefitsSheet(
        cashback: cashback,
        onContinue: () {
          Navigator.pop(context); // benefits
          Navigator.pop(context); // booking sheet
          context.push('/tour-booking', extra: {
            'tour': widget.tour,
            'adults': _adults,
            'children': _children,
            'finalPrice': _finalPrice,
            'bonusDiscount': _discount.round(),
            'departureCity': widget.departureCity,
          });
        },
        onContactManager: () => Navigator.pop(context),
      ),
    );
  }
 
  String _fmt(double p) => p.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
 
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20, 20, 20,
        MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text('Бронирование', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 4),
          Text(widget.tour.hotelName,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500)),
          const Divider(height: 24),
 
          // Tourists counter
          _CounterRow(
            label: 'Взрослые',
            value: _adults, min: 1, max: 8,
            onChange: (v) => setState(() => _adults = v),
          ),
          const SizedBox(height: 12),
          _CounterRow(
            label: 'Дети (до 12)',
            value: _children, min: 0, max: 4,
            onChange: (v) => setState(() => _children = v),
          ),
          const Divider(height: 24),
 
          // Bonus toggle
          if (!_loadingBonuses && _bonusBalance > 0) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  const Color(0xFF1A6FE8).withValues(alpha: 0.08),
                  const Color(0xFF00C9A7).withValues(alpha: 0.08),
                ]),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _useBonuses ? AppColors.primary : AppColors.grey200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded,
                      color: Color(0xFF1A6FE8), size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Использовать бонусы',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        Text('Доступно: ${_fmt(_bonusBalance.toDouble())} ₸',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.grey500)),
                        if (_useBonuses)
                          Text('Скидка: -${_fmt(_discount)} ₸',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _useBonuses,
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) => setState(() => _useBonuses = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
 
          // Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Итого:', style: AppTextStyles.titleLarge),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_useBonuses && _discount > 0)
                    Text('${_fmt(_total)} ₸',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.grey400,
                          decoration: TextDecoration.lineThrough,
                        )),
                  Text('${_fmt(_finalPrice)} ₸',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      )),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppColors.grey500),
                const SizedBox(width: 8),
                Text(
                  'Вы получите +${_fmt(_finalPrice * 0.05)} ₸ бонусов',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
                ),
              ],
            ),
          ),
 
          const SizedBox(height: 16),
 
          // Animated button
          _AnimatedCheckButton(
            fillAnimation: _fillAnimation,
            isChecking: _isChecking,
            priceConfirmed: _priceConfirmed,
            onTap: _startPriceCheck,
          ),
        ],
      ),
    );
  }
}

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
            borderRadius: BorderRadius.circular(14),
            color: AppColors.grey200,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: fillAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
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
                                  color: Colors.white,
                                )),
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
                                color: AppColors.grey800,
                              ),
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Преимущества заказа\nв приложении',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: 24),
          _BenefitItem(
            icon: Icons.percent_rounded,
            title: 'Кешбэк ${_fmt(cashback.toDouble())} ₸',
            description:
                'При бронировании тура в приложении вам будет назначен личный менеджер. Отдел бронирования работает без выходных.',
          ),
          const SizedBox(height: 16),
          const _BenefitItem(
            icon: Icons.support_agent_rounded,
            title: 'Персональный менеджер',
            description:
                'Бронируйте туры и получайте возврат на ваш бонусный счёт. Используйте бонусы при следующем оформлении.',
          ),
          const SizedBox(height: 16),
          const _BenefitItem(
            icon: Icons.credit_card_rounded,
            title: 'Рассрочка и кредит',
            description:
                'Ваш менеджер поможет с оформлением рассрочки или кредита через Home Credit Bank и Kaspi.',
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.grey200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Цена актуальна 😉',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 22),
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
                backgroundColor: AppColors.primary,
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
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey900)),
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

class _CounterRow extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChange;

  const _CounterRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: AppTextStyles.bodyLarge),
        const Spacer(),
        _Btn(
            icon: Icons.remove,
            onTap: value > min ? () => onChange(value - 1) : null),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('$value', style: AppTextStyles.headlineMedium),
        ),
        _Btn(
            icon: Icons.add,
            onTap: value < max ? () => onChange(value + 1) : null),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _Btn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.primary : AppColors.grey200,
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            size: 16,
            color: onTap != null ? Colors.white : AppColors.grey400),
      ),
    );
  }
}