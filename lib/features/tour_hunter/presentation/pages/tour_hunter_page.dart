import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/tour_model.dart';
import '../../../../data/services/price_alert_service.dart';
import '../../../../domain/entities/entities.dart';

class TourHunterPage extends StatefulWidget {
  const TourHunterPage({super.key});

  @override
  State<TourHunterPage> createState() => _TourHunterPageState();
}

class _TourHunterPageState extends State<TourHunterPage> {
  final _service = PriceAlertService();
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _initAndCheck();
  }

  // Сначала инициализируем уведомления, потом проверяем цены
  Future<void> _initAndCheck() async {
    await PriceAlertService.initNotifications();
    await _checkPrices();
  }

  Future<void> _checkPrices() async {
    if (_checking) return;
    setState(() => _checking = true);
    await _service.checkPrices();
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Охотник за турами',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: _checking
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, color: Colors.white),
            onPressed: _checking ? null : _checkPrices,
            tooltip: 'Проверить цены',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () => _showHelp(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _service.stream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final alerts = snap.data ?? [];
          final activeCount =
              alerts.where((a) => a['isActive'] == true).length;
          final triggeredTotal =
              alerts.where((a) => a['isTriggered'] == true).length;

          return Column(
            children: [
              // ── Info banner ──────────────────────────────────────
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_active_outlined,
                        color: Colors.white, size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Мы следим за ценами',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _checking
                                ? 'Проверяем актуальные цены...'
                                : 'Цены обновляются каждый день',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Stats ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _StatCard(
                        label: 'Активных',
                        value: '$activeCount',
                        color: AppColors.primary),
                    const SizedBox(width: 12),
                    _StatCard(
                        label: 'Всего',
                        value: '${alerts.length}',
                        color: AppColors.grey600),
                    const SizedBox(width: 12),
                    _StatCard(
                        label: 'Снижений',
                        value: '$triggeredTotal',
                        color: AppColors.success),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── List ─────────────────────────────────────────────
              Expanded(
                child: alerts.isEmpty
                    ? _buildEmpty(context)
                    : ListView.builder(
                        padding: const EdgeInsets.only(
                            bottom: 100, left: 16, right: 16),
                        itemCount: alerts.length,
                        itemBuilder: (_, i) {
                          final alert = alerts[i];
                          return _AlertCard(
                            data: alert,
                            onToggle: (v) => _service.toggle(
                                alert['alertId'] as String, v),
                            onDelete: () => _service
                                .delete(alert['alertId'] as String),
                            onBook: () => context
                                .push('/tours/${alert['tourId']}'),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAlert(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Добавить',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_off_outlined,
                size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text('Нет активных оповещений',
              style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Добавьте тур и установите целевую цену\n— мы пришлём уведомление при снижении',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.grey500),
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

  void _showHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Как работает охотник?',
                style: AppTextStyles.headlineMedium),
            SizedBox(height: 16),
            _HelpRow(step: '1',
                text: 'Выберите тур и установите целевую цену'),
            _HelpRow(step: '2',
                text: 'Цены на туры меняются каждый день'),
            _HelpRow(step: '3',
                text:
                    'Получите push-уведомление при снижении цены до цели'),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAddAlert(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddAlertSheet(
        onAdd: (tour, price) async {
          Navigator.pop(context);
          await _service.add(
            tourId: tour.id,
            hotelName: tour.hotelName,
            country: tour.country,
            imageUrl: tour.imageUrl,
            nights: tour.nights,
            targetPrice: price,
            currentPrice: tour.price,
          );
          // Сразу проверяем — вдруг цена уже ниже цели
          await _checkPrices();
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Alert Card
// ═══════════════════════════════════════════════════════════════════
class _AlertCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  final VoidCallback onBook;

  const _AlertCard({
    required this.data,
    required this.onToggle,
    required this.onDelete,
    required this.onBook,
  });

  String _fmt(double p) => p.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

  @override
  Widget build(BuildContext context) {
    final hotelName = data['hotelName'] as String? ?? '—';
    final country = data['country'] as String? ?? '';
    final imageUrl = data['imageUrl'] as String? ?? '';
    final nights = (data['nights'] as num?)?.toInt() ?? 0;
    final targetPrice = (data['targetPrice'] as num?)?.toDouble() ?? 0;
    final currentPrice = (data['currentPrice'] as num?)?.toDouble() ?? 0;
    final isActive = data['isActive'] as bool? ?? true;
    final isTriggered = data['isTriggered'] as bool? ?? false;
    final alertId = data['alertId'] as String;

    final isPriceDrop = currentPrice <= targetPrice;
    final diff = (targetPrice - currentPrice).abs();
    final diffPct = targetPrice > 0
        ? ((targetPrice - currentPrice) / targetPrice * 100).round()
        : 0;

    return Dismissible(
      key: Key(alertId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline,
            color: Colors.white, size: 28),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isTriggered
              ? Border.all(color: AppColors.success, width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 100, height: 120,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                        width: 100, height: 120,
                        color: AppColors.grey200),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hotelName,
                            style: AppTextStyles.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('$country • $nights ночей',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.grey500)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.flag_outlined,
                                          size: 13,
                                          color: AppColors.success),
                                      const SizedBox(width: 4),
                                      Text('${_fmt(targetPrice)} ₸',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.success,
                                          )),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(
                                        isPriceDrop
                                            ? Icons.arrow_downward
                                            : Icons.arrow_upward,
                                        size: 13,
                                        color: isPriceDrop
                                            ? AppColors.success
                                            : AppColors.grey500,
                                      ),
                                      const SizedBox(width: 4),
                                      Text('${_fmt(currentPrice)} ₸',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isPriceDrop
                                                ? AppColors.success
                                                : AppColors.grey600,
                                          )),
                                    ],
                                  ),
                                  if (!isPriceDrop) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'осталось ${_fmt(diff)} ₸',
                                      style: AppTextStyles.bodySmall
                                          .copyWith(
                                              color: AppColors.grey400),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Switch(
                              value: isActive,
                              activeThumbColor: AppColors.primary,
                              onChanged: onToggle,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Status bar
            if (isTriggered)
              GestureDetector(
                onTap: onBook,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: AppColors.success, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Цена снизилась на $diffPct%! Забронировать →',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isActive
                          ? Icons.visibility_outlined
                          : Icons.pause_circle_outline,
                      size: 14,
                      color: AppColors.grey500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isActive ? 'Отслеживается' : 'Приостановлено',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.grey500),
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
// Add Alert Sheet
// ═══════════════════════════════════════════════════════════════════
class _AddAlertSheet extends StatefulWidget {
  final void Function(Tour, double) onAdd;
  const _AddAlertSheet({required this.onAdd});

  @override
  State<_AddAlertSheet> createState() => _AddAlertSheetState();
}

class _AddAlertSheetState extends State<_AddAlertSheet> {
  Tour? _selectedTour;
  double _targetPrice = 300000;

  String _fmtPrice(double p) => p.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20, 20, 20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Добавить оповещение',
              style: AppTextStyles.headlineMedium),
          const SizedBox(height: 16),

          const Text('Выберите тур', style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: TourModel.mockList.length,
              itemBuilder: (_, i) {
                final tour = TourModel.mockList[i];
                final selected = _selectedTour?.id == tour.id;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedTour = tour;
                    _targetPrice = (tour.price * 0.9).roundToDouble();
                  }),
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: tour.imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                Container(color: AppColors.grey200),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.6),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 6, left: 6, right: 6,
                            child: Text(tour.country,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                )),
                          ),
                          if (selected)
                            Positioned(
                              top: 6, right: 6,
                              child: Container(
                                width: 20, height: 20,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check,
                                    color: Colors.white, size: 13),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (_selectedTour != null) ...[
            const SizedBox(height: 8),
            Text(
              'Текущая цена: ${_fmtPrice(_selectedTour!.price)} ₸',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.grey500),
            ),
          ],

          const SizedBox(height: 16),
          const Text('Целевая цена', style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          Text(
            '${_fmtPrice(_targetPrice)} ₸',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          Slider(
            value: _targetPrice.clamp(100000, 1500000),
            min: 100000,
            max: 1500000,
            divisions: 28,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _targetPrice = v),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('100 000 ₸',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.grey500)),
              Text('1 500 000 ₸',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.grey500)),
            ],
          ),

          if (_selectedTour != null &&
              _targetPrice >= _selectedTour!.price) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: AppColors.warning),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Цель выше текущей цены — уведомление придёт сразу',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _selectedTour != null
                  ? () => widget.onAdd(_selectedTour!, _targetPrice)
                  : null,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Добавить оповещение',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Helpers
// ═══════════════════════════════════════════════════════════════════
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: color)),
            Text(label,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.grey500)),
          ],
        ),
      ),
    );
  }
}

class _HelpRow extends StatelessWidget {
  final String step;
  final String text;

  const _HelpRow({required this.step, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: const BoxDecoration(
                color: AppColors.primary, shape: BoxShape.circle),
            child: Center(
              child: Text(step,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}