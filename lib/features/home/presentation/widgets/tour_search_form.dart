import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import 'form_widgets.dart';

class TourSearchForm extends StatefulWidget {
  const TourSearchForm({super.key});

  @override
  State<TourSearchForm> createState() => _TourSearchFormState();
}

class _TourSearchFormState extends State<TourSearchForm>
    with SingleTickerProviderStateMixin {
  String _city = 'Алматы';
  String _country = '';
  late String _dates;
  String _nights = '4 — 14 ночей';
  String _tourists = '2 взрослых';

  // Фильтры класс/питание
  bool _extraExpanded = false;
  String _stars = 'Все отели';
  String _meal = 'Любое';

  late final AnimationController _animCtrl;
  late final Animation<double> _arrowAnim;

  static const _starOptions = [
    'Все отели',
    '5 звёзд',
    '4 звезды',
    '3 звезды',
    '2 звезды',
  ];

  static const _mealOptions = [
    'Любое',
    'Все включено',
    'Ультра все включено',
    '3-х разовое питание',
    'Завтрак и ужин',
    'Завтрак включен',
    'Завтрак (оплата на месте)',
  ];

  static const _cities = [
    'Алматы',
    'Астана',
    'Шымкент',
    'Актобе',
    'Актау',
    'Атырау',
    'Костанай',
    'Павлодар',
    'Уральск',
    'Усть-Каменогорск',
    'Петропавловск',
  ];

  static const _countries = [
    {
      'name': 'Вьетнам',
      'visa': 'Без визы',
      'resorts': 'Нячанг, Фантхьет, Дананг, Фукуок',
      'url':
          'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=100'
    },
    {
      'name': 'Египет',
      'visa': 'Виза по прилету',
      'resorts': 'Шарм-эль-Шейх, Дахаб, Хургада',
      'url':
          'https://images.unsplash.com/photo-1539768942893-daf53e448371?w=100'
    },
    {
      'name': 'Таиланд',
      'visa': 'Без визы',
      'resorts': 'Пхукет, Паттайя, Краби, Бангкок',
      'url':
          'https://images.unsplash.com/photo-1589394815804-964ed0be2eb5?w=100'
    },
    {
      'name': 'Турция',
      'visa': 'Без визы',
      'resorts': 'Аланья, Кемер, Сиде, Белек, Анталья',
      'url':
          'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?w=100'
    },
    {
      'name': 'Мальдивы',
      'visa': 'Без визы',
      'resorts': 'Мале, Атолл Южный Мале',
      'url':
          'https://images.unsplash.com/photo-1573843981267-be1999ff37cd?w=100'
    },
    {
      'name': 'ОАЭ',
      'visa': 'Без визы',
      'resorts': 'Дубай, Абу-Даби, Шарджа',
      'url':
          'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=100'
    },
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final start = now.add(const Duration(days: 3));
    final end = start.add(const Duration(days: 7));
    _dates =
        '${start.day}.${start.month.toString().padLeft(2, '0')} — ${end.day}.${end.month.toString().padLeft(2, '0')}';
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _arrowAnim = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggleExtra() {
    setState(() => _extraExpanded = !_extraExpanded);
    _extraExpanded ? _animCtrl.forward() : _animCtrl.reverse();
  }

  String get _extraLabel {
    final parts = [
      if (_stars != 'Все отели') _stars,
      if (_meal != 'Любое') _meal,
    ];
    return parts.isEmpty ? 'Класс отеля и питание' : parts.join(' · ');
  }

  bool get _hasExtraFilters => _stars != 'Все отели' || _meal != 'Любое';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),

        HomeFormField(
          label: 'Город вылета',
          value: _city,
          onTap: () => _showCitySheet(context),
        ),
        const Divider(height: 1, indent: 16),

        HomeFormField(
          label: 'Страна, курорт, отель',
          value: _country,
          hint: 'Страна, курорт, отель',
          onTap: () => _showCountrySheet(context),
        ),
        const Divider(height: 1, indent: 16),

        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: HomeFormField(
                  label: 'Дата вылета',
                  value: _dates,
                  onTap: () => _showDateSheet(context),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: HomeFormField(
                  label: 'На сколько',
                  value: _nights,
                  onTap: () => _showNightsSheet(context),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, indent: 16),

        HomeFormField(
          label: 'Кто летит',
          value: _tourists,
          onTap: () => _showTouristsSheet(context),
        ),
        const Divider(height: 1, indent: 16),

        // ── Кнопка раскрытия ──────────────────────────────────────
        GestureDetector(
          onTap: _toggleExtra,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Text(
                  _extraLabel,
                  style: TextStyle(
                    fontSize: 14,
                    color: _hasExtraFilters
                        ? AppColors.grey900
                        : AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                RotationTransition(
                  turns: _arrowAnim,
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Анимированное раскрытие ───────────────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: _extraExpanded
              ? Column(
                  children: [
                    const Divider(height: 1, indent: 16),
                    IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            child: HomeFormField(
                              label: 'Класс отеля',
                              value: _stars,
                              onTap: () => _showStarsSheet(context),
                            ),
                          ),
                          const VerticalDivider(width: 1),
                          Expanded(
                            child: HomeFormField(
                              label: 'Тип питания',
                              value: _meal,
                              onTap: () => _showMealSheet(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                if (_country.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Выберите страну назначения'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                context.push(AppRoutes.tourList, extra: {
                  'country': _country,
                  'departureCity': _city,
                  'stars': _stars == 'Все отели' ? null : _stars,
                  'meal': _meal == 'Любое' ? null : _meal,
                  'dates': _dates,
                  'nights': _nights,
                  'tourists': _tourists,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Найти туры',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Sheets ─────────────────────────────────────────────────────

  void _showStarsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: _sheetShape,
      builder: (_) => _PickerSheet(
        title: 'Класс отеля',
        options: _starOptions,
        selected: _stars,
        onSelect: (v) => setState(() => _stars = v),
      ),
    );
  }

  void _showMealSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: _sheetShape,
      builder: (_) => _PickerSheet(
        title: 'Питание',
        options: _mealOptions,
        selected: _meal,
        onSelect: (v) => setState(() => _meal = v),
      ),
    );
  }

  void _showCitySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: _sheetShape,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, ctrl) => Column(
          children: [
            const SizedBox(height: 12),
            const _Handle(),
            const SizedBox(height: 16),
            const Text('Город вылета', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Казахстан 🇰🇿', style: AppTextStyles.titleMedium),
            ),
            Expanded(
              child: ListView.separated(
                controller: ctrl,
                itemCount: _cities.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 16),
                itemBuilder: (_, i) => RadioListTile<String>(
                  value: _cities[i],
                  groupValue: _city,
                  activeColor: AppColors.primary,
                  title: Text(_cities[i], style: AppTextStyles.bodyLarge),
                  onChanged: (v) {
                    setState(() => _city = v!);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCountrySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: _sheetShape,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        builder: (_, ctrl) => Column(
          children: [
            const SizedBox(height: 12),
            const _Handle(),
            const SizedBox(height: 16),
            const Text('Куда полетим?', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(12)),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Страна, курорт, отель',
                    prefixIcon: Icon(Icons.search, color: AppColors.grey500),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                controller: ctrl,
                itemCount: _countries.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 72),
                itemBuilder: (_, i) {
                  final c = _countries[i];
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: c['url']!,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                            width: 52, height: 52, color: AppColors.grey200),
                      ),
                    ),
                    title: Text(c['name']!, style: AppTextStyles.titleMedium),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c['visa']!,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500)),
                        Text(c['resorts']!,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.grey500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right,
                        color: AppColors.grey400),
                    onTap: () {
                      setState(() => _country = c['name']!);
                      Navigator.pop(context);
                    },
                  );
                },
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
      shape: _sheetShape,
      builder: (_) => _DatePickerSheet(
        onConfirm: (dates) {
          setState(() => _dates = dates);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showNightsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: _sheetShape,
      builder: (_) => _NightsSheet(
        onConfirm: (nights) {
          setState(() => _nights = nights);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showTouristsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: _sheetShape,
      builder: (_) => _TouristsSheet(
        onConfirm: (t) {
          setState(() => _tourists = t);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Picker Sheet — для звёзд и питания
// ═══════════════════════════════════════════════════════════════════
class _PickerSheet extends StatefulWidget {
  final String title;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;

  const _PickerSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  late String _current;

  @override
  void initState() {
    super.initState();
    _current = widget.selected;
  }

  bool _isStarsOption(String opt) =>
      opt != 'Все отели' && RegExp(r'^\d').hasMatch(opt);

  int _starCount(String opt) =>
      int.tryParse(opt.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Handle(),
          const SizedBox(height: 12),
          Text(widget.title, style: AppTextStyles.headlineMedium),
          const SizedBox(height: 12),
          ...widget.options.map((opt) {
            final selected = opt == _current;
            return GestureDetector(
              onTap: () => setState(() => _current = opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.grey200,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    if (_isStarsOption(opt)) ...[
                      ...List.generate(
                        _starCount(opt),
                        (_) => const Icon(Icons.star,
                            color: AppColors.warning, size: 18),
                      ),
                      ...List.generate(
                        5 - _starCount(opt),
                        (_) => const Icon(Icons.star_outline,
                            color: AppColors.warning, size: 18),
                      ),
                    ] else
                      Text(opt, style: AppTextStyles.bodyLarge),
                    const Spacer(),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color:
                              selected ? AppColors.primary : AppColors.grey300,
                        ),
                      ),
                      child: selected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 14)
                          : null,
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                widget.onSelect(_current);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
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

// ─── Date Picker ──────────────────────────────────────────────────
class _DatePickerSheet extends StatefulWidget {
  final void Function(String) onConfirm;
  const _DatePickerSheet({required this.onConfirm});

  @override
  State<_DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<_DatePickerSheet> {
  DateTime? _start;
  DateTime? _end;
  bool _flexible = true;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      builder: (_, ctrl) => Column(
        children: [
          const SizedBox(height: 12),
          const _Handle(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary),
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Дата вылета',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.grey500)),
                        Text(
                          _start != null && _end != null
                              ? '${_start!.day}.${_start!.month.toString().padLeft(2, '0')} — ${_end!.day}.${_end!.month.toString().padLeft(2, '0')}'
                              : '—',
                          style: AppTextStyles.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        border: Border.all(color: AppColors.grey200),
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Кол-во ночей',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.grey500)),
                        const Text('4 — 14', style: AppTextStyles.titleMedium),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('Гибкий вылет ± 2 дня',
                    style: AppTextStyles.bodyMedium),
                const Spacer(),
                Switch(
                  value: _flexible,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _flexible = v),
                ),
              ],
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
                          if (day.isBefore(_start!)) {
                            _start = day;
                          } else {
                            _end = day;
                          }
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
              onPressed: () {
                if (_start != null && _end != null) {
                  widget.onConfirm(
                    '${_start!.day}.${_start!.month.toString().padLeft(2, '0')} — ${_end!.day}.${_end!.month.toString().padLeft(2, '0')}',
                  );
                }
              },
              child: const Text('Выбрать'),
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
    const monthNames = [
      '',
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь',
    ];
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startWeekday = firstDay.weekday - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${monthNames[month.month]} ${month.year}',
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
                    child: Text(
                      '${day.day}',
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
                      ),
                    ),
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

// ─── Nights Sheet ─────────────────────────────────────────────────
class _NightsSheet extends StatefulWidget {
  final void Function(String) onConfirm;
  const _NightsSheet({required this.onConfirm});

  @override
  State<_NightsSheet> createState() => _NightsSheetState();
}

class _NightsSheetState extends State<_NightsSheet> {
  int _from = 4;
  int _to = 14;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Handle(),
          const SizedBox(height: 16),
          const Text('Количество ночей', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 24),

          // ── "От" ──────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('От', style: AppTextStyles.bodyLarge),
              Row(
                children: [
                  CounterButton(
                    icon: Icons.remove,
                    onTap: _from > 1 ? () => setState(() => _from--) : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('$_from', style: AppTextStyles.headlineMedium),
                  ),
                  CounterButton(
                    icon: Icons.add,
                    // Не даём "от" перепрыгнуть "до"
                    onTap: _from < _to ? () => setState(() => _from++) : null,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── "До" ──────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('До', style: AppTextStyles.bodyLarge),
              Row(
                children: [
                  CounterButton(
                    icon: Icons.remove,
                    // Не даём "до" уйти ниже "от"
                    onTap: _to > _from ? () => setState(() => _to--) : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('$_to', style: AppTextStyles.headlineMedium),
                  ),
                  CounterButton(
                    icon: Icons.add,
                    onTap: _to < 30 ? () => setState(() => _to++) : null,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onConfirm('$_from — $_to ночей'),
              child: const Text('Выбрать'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tourists Sheet ───────────────────────────────────────────────
// ЗАМЕНИ ВЕСЬ КЛАСС _TouristsSheet + _TouristsSheetState в tour_search_form.dart

class _TouristsSheet extends StatefulWidget {
  final void Function(String) onConfirm;
  const _TouristsSheet({required this.onConfirm});

  @override
  State<_TouristsSheet> createState() => _TouristsSheetState();
}

class _TouristsSheetState extends State<_TouristsSheet> {
  int _adults = 2;
  final List<int> _children = [];
  bool _showAgePicker = false;
  bool _twoRooms = false;

  static const _ageLabels = [
    'До года',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
  ];

  String _ageLabel(int age) =>
      age == -1 ? 'до года' : '$age ${_yearLabel(age)}';

  String _yearLabel(int age) {
    if (age == 1) return 'год';
    if (age >= 2 && age <= 4) return 'года';
    return 'лет';
  }

  String get _touristsLabel {
    final kids = _children.length;
    return '$_adults взрослых'
        '${kids > 0 ? ' + $kids ${kids == 1 ? 'ребёнок' : kids < 5 ? 'ребёнка' : 'детей'}' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, ctrl) => Column(
        children: [
          // Фиксированная шапка — не скроллится
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              children: [
                const _Handle(),
                const SizedBox(height: 16),
                const Text('Кто летит ?', style: AppTextStyles.headlineMedium),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Скроллируемый контент — растягивается под любое кол-во детей
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              children: [
                // Взрослые
                _PersonRow(
                  label: 'Взрослые',
                  count: _adults,
                  onDecrement:
                      _adults > 1 ? () => setState(() => _adults--) : null,
                  onIncrement:
                      _adults < 8 ? () => setState(() => _adults++) : null,
                ),
                const SizedBox(height: 10),

                // Карточки добавленных детей
                ..._children.asMap().entries.map((e) {
                  final i = e.key;
                  final age = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ChildCard(
                      ageLabel: _ageLabel(age),
                      onRemove: () => setState(() {
                        _children.removeAt(i);
                        if (_children.length < 3) _twoRooms = false;
                      }),
                    ),
                  );
                }),

                // Inline пикер возраста
                if (_showAgePicker) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
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
                            Text(
                              'Укажите возраст ребенка',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.grey500),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _showAgePicker = false),
                              child: const Text(
                                'Отмена',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _ageLabels.map((label) {
                            final isFirst = label == 'До года';
                            return GestureDetector(
                              onTap: () {
                                final age = isFirst ? -1 : int.parse(label);
                                setState(() {
                                  _children.add(age);
                                  _showAgePicker = false;
                                });
                              },
                              child: Container(
                                width: isFirst ? double.infinity : 46,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.primary),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Кнопка "Добавить ребёнка"
                if (!_showAgePicker && _children.length < 4)
                  GestureDetector(
                    onTap: () => setState(() => _showAgePicker = true),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.grey200),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add, color: AppColors.primary, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Добавить ребенка',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Подсказка при 3+ детях
                if (_children.length >= 3) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('👨‍👩‍👧', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Если вы путешествуете большой компанией, то лучше искать два номера.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => setState(() => _twoRooms = !_twoRooms),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: _twoRooms ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _twoRooms
                                  ? AppColors.primary
                                  : AppColors.grey300,
                            ),
                          ),
                          child: _twoRooms
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 14)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Искать туры с двумя номерами',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.grey800,
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
                    onPressed: () => widget.onConfirm(_touristsLabel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Выбрать',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Child Card ───────────────────────────────────────────────────
class _ChildCard extends StatelessWidget {
  final String ageLabel;
  final VoidCallback onRemove;
  const _ChildCard({required this.ageLabel, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ребенок',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              Text(ageLabel,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.grey500)),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.remove, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Person Row ───────────────────────────────────────────────────
class _PersonRow extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  const _PersonRow({
    required this.label,
    required this.count,
    this.onDecrement,
    this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          Text(label, style: AppTextStyles.bodyLarge),
          const Spacer(),
          _RoundBtn(icon: Icons.remove, onTap: onDecrement),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('$count', style: AppTextStyles.headlineMedium),
          ),
          _RoundBtn(icon: Icons.add, onTap: onIncrement),
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
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.primary : AppColors.grey200,
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            color: onTap != null ? Colors.white : AppColors.grey400, size: 18),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────
class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.grey300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}

const _sheetShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
);
