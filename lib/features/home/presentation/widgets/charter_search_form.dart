import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import 'form_widgets.dart';

class CharterSearchForm extends StatefulWidget {
  const CharterSearchForm({super.key});

  @override
  State<CharterSearchForm> createState() => _CharterSearchFormState();
}

class _CharterSearchFormState extends State<CharterSearchForm> {
  String _from = 'Алматы';
  String _to = '';
  late String _date;
  String _tourists = '2 взрослых';

  static const _fromCities = [
    'Алматы', 'Астана', 'Шымкент', 'Актобе', 'Актау', 'Атырау',
  ];

  static const _toCities = [
    'Анталья', 'Хургада', 'Дубай', 'Бангкок', 'Пхукет',
    'Шарм-эль-Шейх', 'Мале', 'Дананг',
  ];

  static String _fmt(DateTime d) =>
      '${d.day}.${d.month.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final start = now.add(const Duration(days: 3));
    final end = start.add(const Duration(days: 14));
    _date = '${_fmt(start)} — ${_fmt(end)}';
  }

  void _pickCity(String title, List<String> cities, ValueChanged<String> onPick) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.9,
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
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                controller: ctrl,
                itemCount: cities.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
                itemBuilder: (_, i) => ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  title: Text(cities[i], style: AppTextStyles.bodyLarge),
                  onTap: () {
                    Navigator.pop(context);
                    onPick(cities[i]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
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
          setState(() => _date = dates);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showPassengersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PassengersSheet(
        current: _tourists,
        onConfirm: (v) {
          setState(() => _tourists = v);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        HomeFormField(
          label: 'Откуда',
          value: _from,
          onTap: () => _pickCity('Откуда', _fromCities,
              (v) => setState(() => _from = v)),
        ),
        const Divider(height: 1, indent: 16),
        HomeFormField(
          label: 'Куда',
          value: _to,
          hint: 'Город назначения',
          onTap: () => _pickCity('Куда', _toCities,
              (v) => setState(() => _to = v)),
        ),
        const Divider(height: 1, indent: 16),
        HomeFormField(
          label: 'Даты вылета',
          value: _date,
          onTap: () => _showDateSheet(context),
        ),
        const Divider(height: 1, indent: 16),
        HomeFormField(
          label: 'Пассажиры',
          value: _tourists,
          onTap: () => _showPassengersSheet(context),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => context.push(
                AppRoutes.charterList,
                extra: {
                  'from': _from,
                  'to': _to.isEmpty ? 'Анталья' : _to,
                  'date': _date,
                  'passengers': _tourists,
                },
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Найти чартеры',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ],
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
                  border: Border.all(color: const Color(0xFF7B1FA2)),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Вылет',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.grey500)),
                        Text(_start != null ? _fmt(_start!) : '—',
                            style: AppTextStyles.titleMedium),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward,
                      color: AppColors.grey400, size: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Крайняя дата',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.grey500)),
                        Text(_end != null ? _fmt(_end!) : '—',
                            style: AppTextStyles.titleMedium),
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
                    accentColor: const Color(0xFF7B1FA2),
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
                backgroundColor: const Color(0xFF7B1FA2),
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
  final Color accentColor;
  final void Function(DateTime) onDayTap;

  const _MonthCalendar({
    required this.month,
    required this.start,
    required this.end,
    required this.onDayTap,
    this.accentColor = AppColors.primary,
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
              final isPast = day.isBefore(
                  DateTime.now().subtract(const Duration(days: 1)));
              return GestureDetector(
                onTap: isPast ? null : () => onDayTap(day),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isStart || isEnd
                        ? accentColor
                        : inRange
                            ? accentColor.withValues(alpha: 0.1)
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

// ── Passengers Sheet ──────────────────────────────────────────────

class _PassengersSheet extends StatefulWidget {
  final String current;
  final void Function(String) onConfirm;
  const _PassengersSheet({required this.current, required this.onConfirm});

  @override
  State<_PassengersSheet> createState() => _PassengersSheetState();
}

class _PassengersSheetState extends State<_PassengersSheet> {
  int _adults = 2;

  @override
  void initState() {
    super.initState();
    _adults = int.tryParse(widget.current.split(' ').first) ?? 2;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Пассажиры', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RoundBtn(
                icon: Icons.remove,
                onTap: _adults > 1 ? () => setState(() => _adults--) : null,
                color: const Color(0xFF7B1FA2),
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
                onTap: _adults < 9 ? () => setState(() => _adults++) : null,
                color: const Color(0xFF7B1FA2),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () =>
                  widget.onConfirm('$_adults взрослых'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B1FA2),
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

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  const _RoundBtn({required this.icon, this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: onTap != null ? color : AppColors.grey200,
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            color: onTap != null ? Colors.white : AppColors.grey400, size: 20),
      ),
    );
  }
}