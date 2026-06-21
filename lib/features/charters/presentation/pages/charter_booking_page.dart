// ═══════════════════════════════════════════════════════════════════
// charter_booking_page.dart
// ═══════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/flight_model.dart';
import '../../../../data/services/bonus_service.dart';

class CharterBookingPage extends StatefulWidget {
  final Flight flight;
  final int passengers;

  const CharterBookingPage({
    super.key,
    required this.flight,
    this.passengers = 2,
  });

  @override
  State<CharterBookingPage> createState() => _CharterBookingPageState();
}

class _CharterBookingPageState extends State<CharterBookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _surnameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();

  bool _useBonuses = false;
  bool _isLoading = false;
  int _availableBonuses = 0;

  final _bonusService = BonusService();

  @override
  void initState() {
    super.initState();
    _prefill();
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
        _surnameCtrl.text = data['surname'] as String? ?? ''; // ← добавить
        _phoneCtrl.text = data['phone'] as String? ?? '';
        _emailCtrl.text = user.email ?? '';
      }
    } catch (_) {}
  }

  Future<void> _loadBonuses() async {
    final b = await _bonusService.getBalance();
    if (mounted) setState(() => _availableBonuses = b);
  }

  double get _basePrice => widget.flight.price.toDouble();
  int get _bonusDiscount =>
      _useBonuses ? _availableBonuses.clamp(0, (_basePrice * 0.3).toInt()) : 0;
  double get _finalPrice => _basePrice - _bonusDiscount;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final f = widget.flight;

      await FirebaseFirestore.instance.collection('bookings').add({
        'userId': user?.uid,
        'type': 'charter',
        'flightId': f.id,
        'airline': f.airline,
        'flightNumber': f.flightNumber,
        'fromCity': f.fromCity,
        'toCity': f.toCity,
        'departureTime': f.departureTime,
        'arrivalTime': f.arrivalTime,
        'date': f.date,
        'classType': f.classType,
        'baggage': f.baggage,
        'passengers': widget.passengers,
        'price': _finalPrice,
        'originalPrice': _basePrice,
        'usedBonuses': _bonusDiscount,
        'touristName': '${_nameCtrl.text} ${_surnameCtrl.text}'.trim(),
        'phone': _phoneCtrl.text,
        'email': _emailCtrl.text,
        'comment': _commentCtrl.text,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (_bonusDiscount > 0) await _bonusService.useBonus(_bonusDiscount);
      final earned = await _bonusService.addBonus(_finalPrice);

      if (mounted) {
        context.pushReplacement('/charter-booking-success', extra: {
          'earnedBonuses': earned,
          'fromCity': f.fromCity,
          'toCity': f.toCity,
          'date': f.date,
          'flightNumber': f.flightNumber,
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

  String _fmt(double p) => p.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

  @override
  Widget build(BuildContext context) {
    final f = widget.flight;
    final cashback = (_finalPrice * 0.05).round();

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7B1FA2),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Оформление чартера',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            // ── Flight summary ────────────────────────────────────
            _Card(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${f.fromCity} — ${f.toCity}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  Text(f.date,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.grey500)),
                  const Divider(height: 16),
                  _SummaryRow(label: 'Авиакомпания', value: f.airline),
                  const SizedBox(height: 6),
                  _SummaryRow(label: 'Рейс', value: f.flightNumber),
                  const SizedBox(height: 6),
                  _SummaryRow(
                    label: 'Время',
                    value: '${f.departureTime} — ${f.arrivalTime}',
                  ),
                  const SizedBox(height: 6),
                  _SummaryRow(label: 'Класс', value: f.classType),
                  const SizedBox(height: 6),
                  _SummaryRow(label: 'Багаж', value: f.baggage),
                  const SizedBox(height: 6),
                  _SummaryRow(
                      label: 'Пассажиры', value: '${widget.passengers} взр'),
                  if (!f.isRefundable) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_outlined,
                              size: 14, color: Colors.orange),
                          SizedBox(width: 4),
                          Text('Невозвратный билет',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Passenger data ────────────────────────────────────
            _SectionTitle(title: 'Данные пассажира'),
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

            // ── Bonuses ───────────────────────────────────────────
            if (_availableBonuses > 0) ...[
              _SectionTitle(title: 'Бонусный счёт'),
              _Card(
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [
                          Color(0xFF7B1FA2), Color(0xFF1A6FE8)
                        ]),
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
                                fontSize: 16, fontWeight: FontWeight.w800,
                              )),
                          Text('доступно бонусов',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.grey500)),
                          if (_useBonuses)
                            Text('-${_fmt(_bonusDiscount.toDouble())} ₸ спишется',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF7B1FA2),
                                  fontWeight: FontWeight.w600,
                                )),
                        ],
                      ),
                    ),
                    Switch(
                      value: _useBonuses,
                      onChanged: (v) => setState(() => _useBonuses = v),
                      activeThumbColor: const Color(0xFF7B1FA2),
                    ),
                  ],
                ),
              ),
            ],

            // ── Comment ───────────────────────────────────────────
            _SectionTitle(title: 'Комментарий (необязательно)'),
            _Card(
              child: TextFormField(
                controller: _commentCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Особые пожелания по месту, питанию...',
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
                    value: '${_fmt(_basePrice)} ₸',
                  ),
                  if (_useBonuses && _bonusDiscount > 0) ...[
                    const SizedBox(height: 6),
                    _SummaryRow(
                      label: 'Бонусы',
                      value: '-${_fmt(_bonusDiscount.toDouble())} ₸',
                      valueColor: const Color(0xFF7B1FA2),
                    ),
                  ],
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Text('К оплате',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Text('${_fmt(_finalPrice)} ₸',
                          style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800,
                            color: AppColors.grey900,
                          )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.stars_rounded,
                          color: Color(0xFF7B1FA2), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '+${_fmt(cashback.toDouble())} ₸ кешбэк на бонусный счёт',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7B1FA2),
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
              blurRadius: 16, offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B1FA2),
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
                    'Подтвердить бронирование  •  ${_fmt(_finalPrice)} ₸',
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
// Charter Booking Success Page
// ═══════════════════════════════════════════════════════════════════
class CharterBookingSuccessPage extends StatelessWidget {
  final int earnedBonuses;
  final String fromCity;
  final String toCity;
  final String date;
  final String flightNumber;

  const CharterBookingSuccessPage({
    super.key,
    required this.earnedBonuses,
    required this.fromCity,
    required this.toCity,
    required this.date,
    required this.flightNumber,
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
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B1FA2), Color(0xFF1A6FE8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7B1FA2).withValues(alpha: 0.3),
                      blurRadius: 30, spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.flight_takeoff_rounded,
                    color: Colors.white, size: 56),
              ),
              const SizedBox(height: 32),
              const Text(
                'Чартер\nзабронирован!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w800,
                  color: AppColors.grey900, height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Менеджер свяжется с вами\nв течение 30 минут',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.grey600),
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
                    _SummaryRow(
                        label: 'Маршрут', value: '$fromCity — $toCity'),
                    const SizedBox(height: 8),
                    _SummaryRow(label: 'Дата', value: date),
                    const SizedBox(height: 8),
                    _SummaryRow(label: 'Рейс', value: flightNumber),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B1FA2), Color(0xFF1A6FE8)],
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
                          '+${_fmt(earnedBonuses.toDouble())} ₸ на следующее путешествие',
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
                    backgroundColor: const Color(0xFF7B1FA2),
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
                      color: Color(0xFF7B1FA2),
                      fontSize: 14, fontWeight: FontWeight.w600,
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
// Helpers (дублируются здесь, после рефакторинга вынести в shared)
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
              color: Colors.black.withValues(alpha: 0.05), blurRadius: 10,
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
            borderSide: const BorderSide(
                color: Color(0xFF7B1FA2), width: 1.5),
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