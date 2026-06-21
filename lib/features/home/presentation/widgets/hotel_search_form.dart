import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import 'form_widgets.dart';

class HotelSearchForm extends StatefulWidget {
  const HotelSearchForm({super.key});

  @override
  State<HotelSearchForm> createState() => _HotelSearchFormState();
}

class _HotelSearchFormState extends State<HotelSearchForm> {
  String _country = '';
  late String _dates;
  String _tourists = '2 взрослых';
  String _stars = 'Все отели';
  String _meal = 'Любое';

  static const _starOptions = ['Все отели', '5 звёзд', '4 звезды', '3 звезды'];
  static const _mealOptions = ['Любое', 'All Inclusive', 'Завтраки', 'Полупансион', 'Без питания'];

  static String _fmt(DateTime d) =>
      '${d.day}.${d.month.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final start = now.add(const Duration(days: 3));
    final end = start.add(const Duration(days: 5));
    _dates = '${_fmt(start)} — ${_fmt(end)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        HomeFormField(
          label: 'Страна, курорт, отель',
          value: _country,
          hint: 'Страна, курорт, отель',
          onTap: () => _showOptions(context, 'Направление',
              ['Турция', 'Египет', 'Таиланд', 'ОАЭ', 'Мальдивы'],
              (v) => setState(() => _country = v)),
        ),
        const Divider(height: 1, indent: 16),
        HomeFormField(
          label: 'Дата заезда — отъезда',
          value: _dates,
          onTap: () => _showDateSheet(context),
        ),
        const Divider(height: 1, indent: 16),
        HomeFormField(
          label: 'Кто летит',
          value: _tourists,
          onTap: () => _showOptions(context, 'Туристы',
              ['1 взрослый', '2 взрослых', '3 взрослых', '2 взр + 1 ребёнок'],
              (v) => setState(() => _tourists = v)),
        ),
        const Divider(height: 1, indent: 16),
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: HomeFormField(
                  label: 'Класс отеля',
                  value: _stars,
                  onTap: () => _showOptions(context, 'Класс отеля',
                      _starOptions, (v) => setState(() => _stars = v)),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: HomeFormField(
                  label: 'Тип питания',
                  value: _meal,
                  onTap: () => _showOptions(context, 'Тип питания',
                      _mealOptions, (v) => setState(() => _meal = v)),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => context.push(
                AppRoutes.hotelList,
                extra: {
                  'country': _country.isEmpty ? null : _country,
                  'dates': _dates,
                  'tourists': _tourists,
                  'stars': _stars == 'Все отели' ? null : _stars,
                  'meal': _meal == 'Любое' ? null : _meal,
                },
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Найти отели',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ],
    );
  }

  void _showDateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _DatePickerSheet(
        onConfirm: (dates) {
          setState(() => _dates = dates);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showOptions(BuildContext context, String title,
      List<String> options, ValueChanged<String> onChange) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Text(title, style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          ...options.map((o) => ListTile(
                title: Text(o, style: AppTextStyles.bodyLarge),
                onTap: () {
                  Navigator.pop(context);
                  onChange(o);
                },
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Date Picker ───────────────────────────────────────────────────

class _DatePickerSheet extends StatefulWidget {
  final void Function(String) onConfirm;
  const _DatePickerSheet({required this.onConfirm});

  @override
  State<_DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<_DatePickerSheet> {
  DateTime? _start;
  DateTime? _end;

  static String _fmt(DateTime d) =>
      '${d.day}.${d.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      builder: (_, ctrl) => Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Заезд',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.grey500)),
                        Text(
                          _start != null ? _fmt(_start!) : '—',
                          style: AppTextStyles.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward,
                      color: AppColors.grey400, size: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Выезд',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.grey500)),
                        Text(
                          _end != null ? _fmt(_end!) : '—',
                          style: AppTextStyles.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: ctrl,
              child: Column(
                children: List.generate(3, (mi) {
                  final now = DateTime.now();
                  final month = DateTime(now.year, now.month + mi);
                  return _MonthCalendar(
                    month: month,
                    start: _start,
                    end: _end,
                    onDayTap: (day) {
                      setState(() {
                        if (_start == null ||
                            (_start != null && _end != null)) {
                          _start = day;
                          _end = null;
                        } else {
                          if (day.isBefore(_start!)) _start = day;
                          else _end = day;
                        }
                      });
                    },
                  );
                }),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
            child: ElevatedButton(
              onPressed: _start != null && _end != null
                  ? () => widget.onConfirm('${_fmt(_start!)} — ${_fmt(_end!)}')
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
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

class _MonthCalendar extends StatelessWidget {
  final DateTime month;
  final DateTime? start;
  final DateTime? end;
  final void Function(DateTime) onDayTap;

  const _MonthCalendar({
    required this.month,
    required this.start,
    required this.end,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    const names = [
      '', 'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
    ];
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startWeekday = DateTime(month.year, month.month, 1).weekday - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${names[month.month]} ${month.year}',
              style: AppTextStyles.titleLarge),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7, childAspectRatio: 1),
            itemCount: startWeekday + daysInMonth,
            itemBuilder: (_, i) {
              if (i < startWeekday) return const SizedBox();
              final day =
                  DateTime(month.year, month.month, i - startWeekday + 1);
              final isStart = start != null &&
                  day.year == start!.year &&
                  day.month == start!.month &&
                  day.day == start!.day;
              final isEnd = end != null &&
                  day.year == end!.year &&
                  day.month == end!.month &&
                  day.day == end!.day;
              final inRange = start != null &&
                  end != null &&
                  day.isAfter(start!) &&
                  day.isBefore(end!);
              final isPast = day
                  .isBefore(DateTime.now().subtract(const Duration(days: 1)));
              return GestureDetector(
                onTap: isPast ? null : () => onDayTap(day),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isStart || isEnd
                        ? AppColors.primary
                        : inRange
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('${day.day}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isStart || isEnd
                              ? Colors.white
                              : isPast
                                  ? AppColors.grey300
                                  : AppColors.grey800,
                          fontWeight: isStart || isEnd
                              ? FontWeight.w700
                              : FontWeight.w400,
                        )),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}