import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../domain/entities/entities.dart';
import '../../../../data/services/bonus_service.dart';

class TourBookingPage extends StatefulWidget {
  final Tour tour;
  final int adults;
  final int children;
  final double finalPrice;
  final int bonusDiscount;
  final String departureCity; // ← новый параметр

  const TourBookingPage({
    super.key,
    required this.tour,
    required this.adults,
    required this.children,
    required this.finalPrice,
    required this.bonusDiscount,
    this.departureCity = 'Алматы',
  });

  @override
  State<TourBookingPage> createState() => _TourBookingPageState();
}

class _TourBookingPageState extends State<TourBookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _surnameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  bool _isLoading = false;

  final _bonusService = BonusService();

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _surnameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _prefill() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      if (data != null && mounted) {
        _nameCtrl.text = data['name'] as String? ?? '';
        _surnameCtrl.text = data['surname'] as String? ?? '';
        _phoneCtrl.text = data['phone'] as String? ?? '';
        _emailCtrl.text = user.email ?? '';
      }
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final tour = widget.tour;

      await FirebaseFirestore.instance.collection('bookings').add({
        'userId': user?.uid,
        'type': 'tour',
        'tourId': tour.id,
        'tourTitle': tour.title,
        'hotelName': tour.hotelName,
        'country': tour.country,
        'city': tour.city,
        'imageUrl': tour.imageUrl,
        'departureCity': widget.departureCity,
        'departureDate': tour.departureDate.toIso8601String(),
        'nights': tour.nights,
        'mealType': tour.mealType,
        'flightInfo': _flightInfo,
        'adults': widget.adults,
        'children': widget.children,
        'price': widget.finalPrice,
        'originalPrice': tour.price,
        'usedBonuses': widget.bonusDiscount,
        'touristName': '${_nameCtrl.text} ${_surnameCtrl.text}'.trim(),
        'phone': _phoneCtrl.text,
        'email': _emailCtrl.text,
        'comment': _commentCtrl.text,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (widget.bonusDiscount > 0) {
        await _bonusService.useBonus(widget.bonusDiscount);
      }
      final earned = await _bonusService.addBonus(widget.finalPrice);

      if (mounted) {
        context.pushReplacement('/tour-booking-success', extra: {
          'earnedBonuses': earned,
          'tourTitle': tour.title,
          'departureDate': tour.departureDate.toIso8601String(),
          'nights': tour.nights,
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ошибка оформления. Попробуйте ещё раз.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ← Формируем строку перелёта с городом юзера
  String get _flightInfo {
    final tour = widget.tour;
    // Берём оригинальный flightInfo и заменяем город вылета
    // Формат: "Прямой рейс Алматы — Анталья, 5 часов"
    // Заменяем часть до " — " на выбранный город
    final original = tour.flightInfo;
    final dashIndex = original.indexOf(' — ');
    if (dashIndex != -1) {
      // Находим начало города (после "рейс " или "рейс с пересадкой ")
      final prefix = original.substring(0, dashIndex);
      final suffix = original.substring(dashIndex); // " — Анталья, 5 часов"
      final spaceIndex = prefix.lastIndexOf(' ');
      if (spaceIndex != -1) {
        final beforeCity = prefix.substring(0, spaceIndex + 1);
        return '$beforeCity${widget.departureCity}$suffix';
      }
    }
    return original;
  }

  String _fmt(double p) => p.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

  @override
  Widget build(BuildContext context) {
    final tour = widget.tour;
    final cashback = (widget.finalPrice * 0.05).round();
    final dep = tour.departureDate;
    final depStr =
        '${dep.day.toString().padLeft(2, '0')}.${dep.month.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Оформление тура',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => context.push('/ai-assistant'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            // ── Tour summary ─────────────────────────────────────
            _Card(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(tour.stars,
                        (_) => const Icon(Icons.star,
                            color: AppColors.warning, size: 14)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${tour.hotelName.toUpperCase()} ${tour.stars}*',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  Text('${tour.country}, ${tour.city}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.grey500)),
                  const Divider(height: 16),
                  _SummaryRow(label: 'Вылет', value: depStr),
                  const SizedBox(height: 6),
                  _SummaryRow(label: 'Ночей', value: '${tour.nights}'),
                  const SizedBox(height: 6),
                  _SummaryRow(
                    label: 'Туристы',
                    value: widget.children > 0
                        ? '${widget.adults} взр, ${widget.children} дет'
                        : '${widget.adults} взрослых',
                  ),
                  const SizedBox(height: 6),
                  _SummaryRow(label: 'Питание', value: tour.mealType),
                  const SizedBox(height: 6),
                  // ← Показываем перелёт с городом юзера
                  _SummaryRow(label: 'Перелёт', value: _flightInfo),
                ],
              ),
            ),

            // ── Tourist data ──────────────────────────────────────
            _SectionTitle(title: 'Данные туриста'),
            _Card(
              child: Column(
                children: [
                  _Field(
                    controller: _nameCtrl,
                    label: 'Имя',
                    hint: 'Как в паспорте',
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Введите имя' : null,
                  ),
                  const SizedBox(height: 12),
                  _Field(
                    controller: _surnameCtrl,
                    label: 'Фамилия',
                    hint: 'Как в паспорте',
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Введите фамилию'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _Field(
                    controller: _phoneCtrl,
                    label: 'Телефон',
                    hint: '+7 (___) ___-__-__',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9+\s\-\(\)]')),
                    ],
                    validator: (v) =>
                        v == null || v.trim().length < 10
                            ? 'Введите телефон'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  _Field(
                    controller: _emailCtrl,
                    label: 'Email',
                    hint: 'example@mail.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        v == null || !v.contains('@') ? 'Введите email' : null,
                  ),
                ],
              ),
            ),

            // ── Comment ───────────────────────────────────────────
            _SectionTitle(title: 'Комментарий (необязательно)'),
            _Card(
              child: TextFormField(
                controller: _commentCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Особые пожелания, предпочтения по месту...',
                  hintStyle: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.grey400),
                  border: InputBorder.none,
                ),
              ),
            ),

            // ── Price summary ─────────────────────────────────────
            _SectionTitle(title: 'Итого'),
            _Card(
              child: Column(
                children: [
                  _SummaryRow(
                    label: 'Стоимость',
                    value: '${_fmt(tour.price * widget.adults)} ₸',
                  ),
                  if (widget.bonusDiscount > 0) ...[
                    const SizedBox(height: 6),
                    _SummaryRow(
                      label: 'Бонусы',
                      value: '-${_fmt(widget.bonusDiscount.toDouble())} ₸',
                      valueColor: AppColors.success,
                    ),
                  ],
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Text('К оплате',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Text('${_fmt(widget.finalPrice)} ₸',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.grey900,
                          )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.stars_rounded,
                          color: AppColors.primary, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '+${_fmt(cashback.toDouble())} ₸ кешбэк на бонусный счёт',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.grey300,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text(
                    'Подтвердить бронирование  •  ${_fmt(widget.finalPrice)} ₸',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Tour Booking Success Page
// ═══════════════════════════════════════════════════════════════════
class TourBookingSuccessPage extends StatelessWidget {
  final int earnedBonuses;
  final String tourTitle;
  final String departureDate;
  final int nights;

  const TourBookingSuccessPage({
    super.key,
    required this.earnedBonuses,
    required this.tourTitle,
    required this.departureDate,
    required this.nights,
  });

  String _fmt(double p) => p.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

  @override
  Widget build(BuildContext context) {
    final dep = DateTime.parse(departureDate);
    final depStr =
        '${dep.day.toString().padLeft(2, '0')}.${dep.month.toString().padLeft(2, '0')}.${dep.year}';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF26C6DA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 30, spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 60),
              ),
              const SizedBox(height: 32),
              const Text(
                'Бронирование\nоформлено!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.grey900,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Менеджер свяжется с вами\nв течение 30 минут',
                textAlign: TextAlign.center,
                style:
                    AppTextStyles.bodyLarge.copyWith(color: AppColors.grey600),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _SummaryRow(label: 'Тур', value: tourTitle),
                    const SizedBox(height: 8),
                    _SummaryRow(label: 'Вылет', value: depStr),
                    const SizedBox(height: 8),
                    _SummaryRow(label: 'Ночей', value: '$nights'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF1A6FE8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars_rounded,
                        color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Бонусы начислены!',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            )),
                        Text(
                          '+${_fmt(earnedBonuses.toDouble())} ₸ на следующий отдых',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: () => context.go('/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('На главную',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  context.go('/home');
                  context.push('/profile/bookings');
                },
                child: const Text('Мои бронирования',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Shared helpers
// ═══════════════════════════════════════════════════════════════════
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(title, style: AppTextStyles.headlineMedium),
      );
}

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  const _Card({required this.child, this.margin});

  @override
  Widget build(BuildContext context) => Container(
        margin: margin ?? const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: child,
      );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: AppColors.grey500, fontSize: 13),
          hintStyle: const TextStyle(color: AppColors.grey400, fontSize: 13),
          filled: true,
          fillColor: AppColors.grey100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error, width: 1),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      );
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _SummaryRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(label,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500)),
          const Spacer(),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.grey800,
                )),
          ),
        ],
      );
}