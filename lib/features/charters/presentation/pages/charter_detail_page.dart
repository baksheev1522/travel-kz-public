import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/flight_model.dart';
import '../../../../core/utils/share_utils.dart';
import '../../../../core/widgets/info_bottom_sheet.dart';

class CharterDetailPage extends StatefulWidget {
  final Flight flight;
  const CharterDetailPage({super.key, required this.flight});

  @override
  State<CharterDetailPage> createState() => _CharterDetailPageState();
}

class _CharterDetailPageState extends State<CharterDetailPage>
    with SingleTickerProviderStateMixin {
  bool _isChecking = false;
  bool _priceConfirmed = false;

  late AnimationController _fillController;
  late Animation<double> _fillAnimation;

  @override
  void initState() {
    super.initState();
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

  void _startPriceCheck() {
    if (_isChecking) return;
    setState(() => _isChecking = true);
    _fillController.forward();
  }

  void _showBenefits() {
    final cashback = widget.flight.cashback;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BenefitsSheet(
        cashback: cashback,
        onContinue: () {
          Navigator.pop(context);
          context.push('/charter-booking', extra: {
            'flight': widget.flight,
            'passengers': 2,
          });
        },
        onContactManager: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.flight;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7B1FA2),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${f.fromCity} — ${f.toCity}',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            Text('${f.date}, 2 взр',
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            onPressed: () => context.push('/ai-assistant'),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () => ShareUtils.shareCharter(
              context: context,
              fromCity: f.fromCity,
              toCity: f.toCity,
              date: f.date,
              price: f.formattedPrice,
              flightNumber: f.flightNumber,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16, 16, 16,
              MediaQuery.of(context).padding.bottom + 80,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header card ───────────────────────────────────
                _InfoCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${f.fromCity} — ${f.toCity}',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w800)),
                            Text(f.date,
                                style: AppTextStyles.bodyMedium
                                    .copyWith(color: AppColors.grey500)),
                          ],
                        ),
                      ),
                      if (!f.isRefundable)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_outlined,
                                  size: 14, color: Colors.orange),
                              SizedBox(width: 4),
                              Text('Невозвратный',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Flight detail card ────────────────────────────
                _InfoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Airline row
                      Row(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF7B1FA2).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(f.airlineCode,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF7B1FA2))),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(f.airline,
                                    style: const TextStyle(
                                        fontSize: 15, fontWeight: FontWeight.w700)),
                                Text('${f.classType} | ${f.duration}',
                                    style: AppTextStyles.bodySmall
                                        .copyWith(color: AppColors.grey500)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.grey100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Рейс: ${f.flightNumber}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.grey700)),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Timeline
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 10, height: 10,
                                decoration: const BoxDecoration(
                                    color: Color(0xFF7B1FA2),
                                    shape: BoxShape.circle),
                              ),
                              Container(
                                width: 2, height: 70,
                                color: AppColors.grey300,
                                margin:
                                    const EdgeInsets.symmetric(vertical: 4),
                              ),
                              Container(
                                width: 10, height: 10,
                                decoration: const BoxDecoration(
                                    color: Color(0xFF7B1FA2),
                                    shape: BoxShape.circle),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(f.departureTime,
                                    style: const TextStyle(
                                        fontSize: 20, fontWeight: FontWeight.w800)),
                                Text(f.date,
                                    style: AppTextStyles.bodySmall
                                        .copyWith(color: AppColors.grey500)),
                                Text(f.fromCity,
                                    style: const TextStyle(
                                        fontSize: 15, fontWeight: FontWeight.w600)),
                                Text(f.fromFull,
                                    style: AppTextStyles.bodySmall
                                        .copyWith(color: AppColors.grey500)),
                                Text(f.from,
                                    style: AppTextStyles.bodySmall
                                        .copyWith(color: AppColors.grey400)),
                                const SizedBox(height: 16),
                                Text(f.arrivalTime,
                                    style: const TextStyle(
                                        fontSize: 20, fontWeight: FontWeight.w800)),
                                Text(f.date,
                                    style: AppTextStyles.bodySmall
                                        .copyWith(color: AppColors.grey500)),
                                Text(f.toCity,
                                    style: const TextStyle(
                                        fontSize: 15, fontWeight: FontWeight.w600)),
                                Text(f.toFull,
                                    style: AppTextStyles.bodySmall
                                        .copyWith(color: AppColors.grey500)),
                                Text(f.to,
                                    style: AppTextStyles.bodySmall
                                        .copyWith(color: AppColors.grey400)),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          const Icon(Icons.luggage_outlined,
                              size: 18, color: AppColors.grey500),
                          const SizedBox(width: 8),
                          Text(f.baggage, style: AppTextStyles.bodyMedium),
                          const SizedBox(width: 16),
                          const Icon(Icons.flight,
                              size: 18, color: AppColors.grey500),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('Самолёт: ${f.aircraft}',
                                style: AppTextStyles.bodyMedium),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Cashback banner ───────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Кешбэк ${f.formattedCashback} ₸',
                                style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                )),
                            const Text('Столько вы получите\nс этого путешествия',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                const Text('Может быть полезно',
                    style: AppTextStyles.headlineMedium),
                const SizedBox(height: 12),
                _LinkRow(
                  label: 'Правила въезда',
                  onTap: () => InfoBottomSheet.showEntryRules(context),
                ),
                const SizedBox(height: 8),
                _LinkRow(
                  label: 'Часто задаваемые вопросы',
                  onTap: () => InfoBottomSheet.showFaq(context),
                ),
                const SizedBox(height: 16),

                // ── Price card ────────────────────────────────────
                _InfoCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Цена',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      Text('${f.formattedPrice} ₸',
                          style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800,
                            color: AppColors.grey900,
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Animated bottom button ────────────────────────────────
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
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16, offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: _AnimatedCheckButton(
                fillAnimation: _fillAnimation,
                isChecking: _isChecking,
                priceConfirmed: _priceConfirmed,
                accentColor: const Color(0xFF7B1FA2),
                onTap: _startPriceCheck,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Animated Check Button
// ═══════════════════════════════════════════════════════════════════
class _AnimatedCheckButton extends StatelessWidget {
  final Animation<double> fillAnimation;
  final bool isChecking;
  final bool priceConfirmed;
  final VoidCallback onTap;
  final Color accentColor;

  const _AnimatedCheckButton({
    required this.fillAnimation,
    required this.isChecking,
    required this.priceConfirmed,
    required this.onTap,
    required this.accentColor,
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
                    color: accentColor,
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
                                  fontSize: 16, fontWeight: FontWeight.w700,
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
                                      fontSize: 16, fontWeight: FontWeight.w700,
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
                                fontSize: 16, fontWeight: FontWeight.w700,
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

// ═══════════════════════════════════════════════════════════════════
// Benefits Sheet
// ═══════════════════════════════════════════════════════════════════
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
                'При бронировании чартера в приложении вам назначат личного менеджера. Отдел бронирования работает без выходных.',
          ),
          const SizedBox(height: 16),
          const _BenefitItem(
            icon: Icons.support_agent_rounded,
            title: 'Персональный менеджер',
            description:
                'Бронируйте чартеры и получайте возврат на ваш бонусный счёт.',
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
                backgroundColor: const Color(0xFF7B1FA2),
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
                  color: Color(0xFF7B1FA2),
                  fontSize: 14, fontWeight: FontWeight.w600,
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
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: AppColors.grey900)),
              const SizedBox(height: 3),
              Text(description,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.grey600)),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Helpers
// ═══════════════════════════════════════════════════════════════════
class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05), blurRadius: 8,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _LinkRow extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _LinkRow({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.grey200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(label,
                style: const TextStyle(
                  color: AppColors.primary, fontSize: 14,
                  fontWeight: FontWeight.w500,
                )),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}