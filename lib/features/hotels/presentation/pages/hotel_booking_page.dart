import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/hotel_model.dart';
import '../../../../data/services/bonus_service.dart';

class HotelBookingPage extends StatefulWidget {
  final HotelRoomVariant variant;
  final Map<String, dynamic> hotel;

  const HotelBookingPage({
    super.key,
    required this.variant,
    required this.hotel,
  });

  @override
  State<HotelBookingPage> createState() => _HotelBookingPageState();
}

class _HotelBookingPageState extends State<HotelBookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _surnameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();

  bool _useBonuses = false;
  bool _agreeTerms = false;
  bool _isLoading = false;
  int _availableBonuses = 0;

  final _bonusService = BonusService();

  @override
  void initState() {
    super.initState();
    _prefillFromAuth();
    _loadBonuses();
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

  Future<void> _prefillFromAuth() async {
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

  Future<void> _loadBonuses() async {
    final bonuses = await _bonusService.getBalance();
    if (mounted) setState(() => _availableBonuses = bonuses);
  }

  double get _finalPrice {
    if (_useBonuses && _availableBonuses > 0) {
      final discount = _availableBonuses.toDouble()
          .clamp(0, widget.variant.price * 0.3);
      return widget.variant.price - discount;
    }
    return widget.variant.price;
  }

  int get _bonusDiscount {
    if (!_useBonuses || _availableBonuses <= 0) return 0;
    return _availableBonuses.clamp(0, (widget.variant.price * 0.3).toInt());
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeTerms) {
      _showSnack('Необходимо принять условия соглашения');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final hotel = widget.hotel;
      final variant = widget.variant;

      // Сохраняем бронирование в Firestore
      await FirebaseFirestore.instance.collection('bookings').add({
        'userId': user?.uid,
        'type': 'hotel',
        'hotelId': hotel['id'],
        'hotelName': hotel['name'],
        'country': hotel['country'],
        'city': hotel['city'],
        'imageUrl': hotel['imageUrl'],
        'roomType': variant.roomType,
        'mealType': variant.mealType,
        'checkIn': hotel['checkIn'],
        'checkOut': hotel['checkOut'],
        'nights': hotel['nights'],
        'tourists': 2,
        'price': _finalPrice,
        'originalPrice': variant.price,
        'usedBonuses': _bonusDiscount,
        'touristName': '${_nameCtrl.text} ${_surnameCtrl.text}'.trim(),
        'phone': _phoneCtrl.text,
        'email': _emailCtrl.text,
        'comment': _commentCtrl.text,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Списываем бонусы если использовали
      if (_useBonuses && _bonusDiscount > 0) {
        await _bonusService.useBonus(_bonusDiscount);
      }

      // Начисляем кешбэк 2%
      await _bonusService.addBonus(_finalPrice);

      if (mounted) {
        context.pushReplacement('/hotel-booking-success', extra: {
          'earnedBonuses': (_finalPrice * 0.02).round(),
          'hotelName': hotel['name'],
          'checkIn': hotel['checkIn'],
          'checkOut': hotel['checkOut'],
        });
      }
    } catch (e) {
      if (mounted) _showSnack('Ошибка оформления. Попробуйте ещё раз.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  String _fmt(double p) => p.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

  @override
  Widget build(BuildContext context) {
    final hotel = widget.hotel;
    final variant = widget.variant;
    final cashback = (_finalPrice * 0.02).round();

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_outlined),
            onPressed: () {}, // TODO: позвонить менеджеру
          ),
        ],
        title: const Text(
          'Оформление отеля',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            // ── Booking summary ──────────────────────────────────
            Container(
              margin: const EdgeInsets.all(16),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Row(
                        children: List.generate(
                          hotel['stars'] as int,
                          (_) => const Icon(Icons.star,
                              color: AppColors.warning, size: 14),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('#${hotel['reviewsCount']}',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.grey500)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(hotel['name'] as String).toUpperCase()} ${hotel['stars']}*',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey900,
                    ),
                  ),
                  Text('${hotel['country']}, ${hotel['city']}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.grey500)),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  _SummaryRow(
                    label: 'Даты',
                    value:
                        '${hotel['checkIn']} — ${hotel['checkOut']}, ${hotel['nights']} ночей',
                  ),
                  const SizedBox(height: 6),
                  _SummaryRow(label: 'Туристы', value: '2 взрослых'),
                  const SizedBox(height: 6),
                  _SummaryRow(label: 'Номер', value: variant.roomType),
                  const SizedBox(height: 6),
                  _SummaryRow(label: 'Питание', value: variant.mealType),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.grey300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Без перелёта',
                        style:
                            TextStyle(fontSize: 11, color: AppColors.grey600)),
                  ),
                ],
              ),
            ),

            // ── Tourist info ─────────────────────────────────────
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
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Введите фамилию' : null,
                  ),
                  const SizedBox(height: 12),
                  _Field(
                    controller: _phoneCtrl,
                    label: 'Телефон',
                    hint: '+7 (___) ___-__-__',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-\(\)]')),
                    ],
                    validator: (v) => v == null || v.trim().length < 10
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

            // ── Bonuses ──────────────────────────────────────────
            if (_availableBonuses > 0) ...[
              _SectionTitle(title: 'Бонусный счёт'),
              _Card(
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00897B), Color(0xFF1A6FE8)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.stars_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${_fmt(_availableBonuses.toDouble())} ₸',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.grey900,
                              )),
                          Text('доступно бонусов',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.grey500)),
                          if (_useBonuses)
                            Text(
                              '-${_fmt(_bonusDiscount.toDouble())} ₸ спишется',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF00897B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _useBonuses,
                      onChanged: (v) => setState(() => _useBonuses = v),
                      activeColor: const Color(0xFF00897B),
                    ),
                  ],
                ),
              ),
            ],

            // ── Comment ──────────────────────────────────────────
            _SectionTitle(title: 'Комментарий (необязательно)'),
            _Card(
              child: TextFormField(
                controller: _commentCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Особые пожелания, поздний заезд...',
                  hintStyle: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.grey400),
                  border: InputBorder.none,
                ),
              ),
            ),

            // ── Price summary ────────────────────────────────────
            _SectionTitle(title: 'Итого'),
            _Card(
              child: Column(
                children: [
                  _SummaryRow(
                    label: 'Стоимость',
                    value: '${_fmt(variant.price)} ₸',
                  ),
                  if (_useBonuses && _bonusDiscount > 0) ...[
                    const SizedBox(height: 6),
                    _SummaryRow(
                      label: 'Бонусы',
                      value: '-${_fmt(_bonusDiscount.toDouble())} ₸',
                      valueColor: const Color(0xFF00897B),
                    ),
                  ],
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Text('К оплате',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.grey900,
                          )),
                      const Spacer(),
                      Text(
                        '${_fmt(_finalPrice)} ₸',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.grey900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.stars_rounded,
                          color: Color(0xFF00897B), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '+${_fmt(cashback.toDouble())} ₸ кешбэк на бонусный счёт',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF00897B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Agreement ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _agreeTerms,
                    onChanged: (v) => setState(() => _agreeTerms = v ?? false),
                    activeColor: const Color(0xFF00897B),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                              fontSize: 12, color: AppColors.grey600),
                          children: [
                            TextSpan(text: 'Продолжая, я соглашаюсь с '),
                            TextSpan(
                              text: 'условиями бронирования',
                              style: TextStyle(
                                color: Color(0xFF00897B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(text: ' и '),
                            TextSpan(
                              text: 'политикой конфиденциальности',
                              style: TextStyle(
                                color: Color(0xFF00897B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // ── Bottom button ────────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          16, 12, 16,
          MediaQuery.of(context).padding.bottom + 12,
        ),
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
              backgroundColor: const Color(0xFF00897B),
              disabledBackgroundColor: AppColors.grey300,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Подтвердить бронирование  •  ${_fmt(_finalPrice)} ₸',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Booking Success Page
// ═══════════════════════════════════════════════════════════════════
class HotelBookingSuccessPage extends StatelessWidget {
  final int earnedBonuses;
  final String hotelName;
  final String checkIn;
  final String checkOut;

  const HotelBookingSuccessPage({
    super.key,
    required this.earnedBonuses,
    required this.hotelName,
    required this.checkIn,
    required this.checkOut,
  });

  String _fmt(double p) => p.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // Success animation container
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00897B), Color(0xFF26C6DA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00897B).withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
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
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.grey600),
              ),

              const SizedBox(height: 32),

              // Hotel card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _SummaryRow(
                      label: 'Отель',
                      value: hotelName,
                    ),
                    const SizedBox(height: 8),
                    _SummaryRow(
                      label: 'Даты',
                      value: '$checkIn — $checkOut',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Bonuses earned
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

              // Actions
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.go('/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
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
                child: const Text(
                  'Мои бронирования',
                  style: TextStyle(
                    color: Color(0xFF00897B),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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

// ═══════════════════════════════════════════════════════════════════
// Helpers
// ═══════════════════════════════════════════════════════════════════
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: AppTextStyles.headlineMedium),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(
            color: AppColors.grey500, fontSize: 13),
        hintStyle: const TextStyle(
            color: AppColors.grey400, fontSize: 13),
        filled: true,
        fillColor: AppColors.grey100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00897B), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.grey800,
            ),
          ),
        ),
      ],
    );
  }
}