import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/services/wishlist_service.dart';

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = WishlistService();

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Избранное',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: service.stream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snap.data ?? [];

          if (items.isEmpty) return _EmptyState();

          return Column(
            children: [
              // Счётчик + очистить
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Text(
                      '${items.length} ${_plural(items.length)}',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.grey600),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _confirmClear(context, service, items),
                      child: Text(
                        'Очистить всё',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: items.length,
                  itemBuilder: (_, i) => _WishCard(
                    data: items[i],
                    onRemove: () => service.remove(items[i]['tourId'] as String),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _plural(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'тур';
    if (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)) {
      return 'тура';
    }
    return 'туров';
  }

  void _confirmClear(
    BuildContext context,
    WishlistService service,
    List<Map<String, dynamic>> items,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
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
            const Text('Очистить избранное?',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Все ${items.length} ${_plural(items.length)} будут удалены из списка',
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      for (final item in items) {
                        await service.remove(item['tourId'] as String);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error),
                    child: const Text('Удалить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _plural2(int n) => _plural(n); // avoid lint
}

// ═══════════════════════════════════════════════════════════════════
// Wish Card
// ═══════════════════════════════════════════════════════════════════
class _WishCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onRemove;

  const _WishCard({required this.data, required this.onRemove});

  String _fmt(double p) => p.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

  @override
  Widget build(BuildContext context) {
    final tourId = data['tourId'] as String? ?? '';
    final imageUrl = data['imageUrl'] as String? ?? '';
    final hotelName = data['hotelName'] as String? ?? '—';
    final country = data['country'] as String? ?? '';
    final city = data['city'] as String? ?? '';
    final stars = (data['stars'] as num?)?.toInt() ?? 0;
    final nights = (data['nights'] as num?)?.toInt() ?? 0;
    final mealType = data['mealType'] as String? ?? '';
    final price = (data['price'] as num?)?.toDouble() ?? 0;
    final originalPrice = (data['originalPrice'] as num?)?.toDouble() ?? 0;
    final isHot = data['isHot'] as bool? ?? false;
    final hasDiscount = originalPrice > price && originalPrice > 0;
    final discountPct = hasDiscount
        ? ((originalPrice - price) / originalPrice * 100).round()
        : 0;

    return GestureDetector(
      onTap: () => context.push('/tours/$tourId'),
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
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        Container(height: 160, color: AppColors.grey200),
                  ),
                ),
                // Badges
                Positioned(
                  top: 10, left: 10,
                  child: Row(
                    children: [
                      if (isHot)
                        _Badge(label: '🔥 Горящий', color: AppColors.secondary),
                      if (hasDiscount) ...[
                        const SizedBox(width: 6),
                        _Badge(label: '-$discountPct%', color: AppColors.error),
                      ],
                    ],
                  ),
                ),
                // Remove
                Positioned(
                  top: 10, right: 10,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      width: 34, height: 34,
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
                      child: const Icon(Icons.favorite,
                          color: AppColors.error, size: 18),
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
                  Text(hotelName, style: AppTextStyles.titleLarge),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.grey500),
                      const SizedBox(width: 2),
                      Text('$country, $city',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.grey500)),
                      const SizedBox(width: 8),
                      ...List.generate(
                        stars,
                        (_) => const Icon(Icons.star,
                            size: 12, color: AppColors.warning),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _Chip('$nights ночей'),
                      const SizedBox(width: 6),
                      _Chip(mealType),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasDiscount)
                            Text(
                              '${_fmt(originalPrice)} ₸',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.grey400,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          Text(
                            '${_fmt(price)} ₸',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () => context.push('/tours/$tourId'),
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
// Empty State
// ═══════════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_outline,
                size: 40, color: AppColors.error),
          ),
          const SizedBox(height: 16),
          const Text('Список избранного пуст',
              style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Добавляйте туры нажав на ♡\nна карточке тура',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/search'),
            icon: const Icon(Icons.search),
            label: const Text('Найти туры'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Helpers
// ═══════════════════════════════════════════════════════════════════
class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
      );
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.grey100, borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey700)),
      );
}