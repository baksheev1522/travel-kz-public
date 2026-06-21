import 'dart:math';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../domain/entities/entities.dart';

// ═══════════════════════════════════════════════════════════════════
// PriceCalendarSheet — календарь цен (даты × количество ночей)
// ═══════════════════════════════════════════════════════════════════

/// Результат выбора в календаре цен.
class PriceCalendarResult {
  final DateTime departureDate;
  final int nights;
  final double price;
  const PriceCalendarResult({
    required this.departureDate,
    required this.nights,
    required this.price,
  });
}

/// Детерминированный генератор демо-цен.
/// Цена зависит от базовой цены тура, даты и количества ночей —
/// одинаковые входные данные всегда дают одинаковую цену (не "плавает"
/// при перестроении виджета), но выглядит правдоподобно разнообразно.
/// Часть ячеек специально помечается "нет мест" (null), как на ht.kz.
class _DemoPriceGenerator {
  final double basePrice;
  final int baseNights;

  _DemoPriceGenerator({required this.basePrice, required this.baseNights});

  /// Возвращает цену за тур на конкретную дату и количество ночей,
  /// либо null, если "мест нет".
  double? priceFor(DateTime date, int nights) {
    final seed = date.year * 10000 +
        date.month * 100 +
        date.day +
        nights * 7;
    final rnd = Random(seed);

    // ~30% ячеек — "нет мест" (для реалистичности, как на ht.kz)
    if (rnd.nextDouble() < 0.3) return null;

    final pricePerNight = basePrice / baseNights;

    final weekendBoost = (date.weekday == DateTime.friday ||
            date.weekday == DateTime.saturday)
        ? 1.12
        : 1.0;
    final randomFactor = 0.85 + rnd.nextDouble() * 0.3; // 0.85..1.15

    final total = pricePerNight * nights * weekendBoost * randomFactor;

    return (total / 1000).round() * 1000;
  }
}

class PriceCalendarSheet extends StatefulWidget {
  final Tour tour;
  final DateTime initialDate;
  final int initialNights;

  const PriceCalendarSheet({
    super.key,
    required this.tour,
    required this.initialDate,
    required this.initialNights,
  });

  @override
  State<PriceCalendarSheet> createState() => _PriceCalendarSheetState();
}

class _PriceCalendarSheetState extends State<PriceCalendarSheet> {
  late DateTime _weekStart;
  late int _selectedNights;
  late DateTime _selectedDate;
  late _DemoPriceGenerator _gen;

  static const _nightsRange = [5, 6, 7, 8, 9, 10, 11];
  static const _weekdayShort = [
    'пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс',
  ];
  static const _monthShort = [
    'янв', 'фев', 'мар', 'апр', 'май', 'июн',
    'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _selectedNights = widget.initialNights;
    final weekday = _selectedDate.weekday; // 1=пн .. 7=вс
    _weekStart = _selectedDate.subtract(Duration(days: weekday - 1));
    _gen = _DemoPriceGenerator(
      basePrice: widget.tour.price,
      baseNights: widget.tour.nights,
    );
  }

  void _shiftWeek(int deltaDays) {
    setState(() {
      _weekStart = _weekStart.add(Duration(days: deltaDays));
    });
  }

  String _fmtPrice(double p) => p.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

  String _fmtRangeLabel() {
    final start = _weekStart;
    final end = _weekStart.add(const Duration(days: 6));
    return '${start.day} ${_monthShort[start.month - 1]} — '
        '${end.day} ${_monthShort[end.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final days = List.generate(7, (i) => _weekStart.add(Duration(days: i)));
    final selectedPrice = _gen.priceFor(_selectedDate, _selectedNights);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Цены на туры',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.grey900,
                ),
              ),
              const SizedBox(height: 16),

              // ── Переключение недели ─────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left,
                            color: AppColors.primary),
                        onPressed: () => _shiftWeek(-7),
                      ),
                      Expanded(
                        child: Text(
                          _fmtRangeLabel(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.grey900,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right,
                            color: AppColors.primary),
                        onPressed: () => _shiftWeek(7),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Таблица ───────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Table(
                      defaultColumnWidth: const FixedColumnWidth(96),
                      border: TableBorder.all(
                        color: AppColors.grey200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      children: [
                        // ── Шапка с датами ───────────────────────
                        TableRow(
                          decoration:
                              const BoxDecoration(color: AppColors.grey100),
                          children: [
                            _HeaderCell('Ночей'),
                            ...days.map((d) {
                              final isSelected = _isSameDay(d, _selectedDate);
                              return _HeaderCell(
                                '${d.day} ${_monthShort[d.month - 1]}.'
                                ' ${_weekdayShort[d.weekday - 1]}',
                                highlighted: isSelected,
                              );
                            }),
                          ],
                        ),
                        // ── Строки по количеству ночей ───────────
                        ..._nightsRange.map((nights) {
                          final isNightsSelected =
                              nights == _selectedNights;
                          return TableRow(
                            decoration: BoxDecoration(
                              color: isNightsSelected
                                  ? AppColors.primary.withValues(alpha: 0.06)
                                  : null,
                            ),
                            children: [
                              _HeaderCell(
                                '$nights',
                                highlighted: isNightsSelected,
                                isRowHeader: true,
                              ),
                              ...days.map((d) {
                                final price = _gen.priceFor(d, nights);
                                final isCellSelected = isNightsSelected &&
                                    _isSameDay(d, _selectedDate);
                                return _PriceCell(
                                  price: price,
                                  fmt: _fmtPrice,
                                  selected: isCellSelected,
                                  onTap: price == null
                                      ? null
                                      : () => setState(() {
                                            _selectedDate = d;
                                            _selectedNights = nights;
                                          }),
                                );
                              }),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Кнопка подтверждения ─────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(
                    16, 12, 16, MediaQuery.of(context).padding.bottom + 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: selectedPrice == null
                        ? null
                        : () => Navigator.pop(
                              context,
                              PriceCalendarResult(
                                departureDate: _selectedDate,
                                nights: _selectedNights,
                                price: selectedPrice,
                              ),
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.grey300,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Показать туры',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final bool highlighted;
  final bool isRowHeader;
  const _HeaderCell(this.text,
      {this.highlighted = false, this.isRowHeader = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isRowHeader ? 48 : 56,
      alignment: Alignment.center,
      color: highlighted
          ? AppColors.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: highlighted ? AppColors.primary : AppColors.grey700,
        ),
      ),
    );
  }
}

class _PriceCell extends StatelessWidget {
  final double? price;
  final String Function(double) fmt;
  final bool selected;
  final VoidCallback? onTap;

  const _PriceCell({
    required this.price,
    required this.fmt,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFE8F5E9)
              : Colors.transparent,
          border: selected
              ? Border.all(color: const Color(0xFF4CAF50), width: 2)
              : null,
        ),
        child: price == null
            ? const Text('-',
                style: TextStyle(color: AppColors.grey400, fontSize: 14))
            : Text(
                '${fmt(price!)} ₸',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? const Color(0xFF2E7D32)
                      : AppColors.grey900,
                ),
              ),
      ),
    );
  }
}
