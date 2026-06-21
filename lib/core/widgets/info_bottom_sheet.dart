import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Путь: lib/core/widgets/info_bottom_sheet.dart
///
/// Универсальный bottom sheet для FAQ и правил.
/// Использование:
///   InfoBottomSheet.showEntryRules(context);
///   InfoBottomSheet.showFaq(context);
///   InfoBottomSheet.showPaymentRules(context);
abstract class InfoBottomSheet {
  static void showEntryRules(BuildContext context) {
    _show(
      context,
      title: 'Правила въезда',
      sections: const [
        _Section(
          title: '🛂 Паспорт и документы',
          body: 'Для въезда необходим загранпаспорт со сроком действия не менее 6 месяцев с момента окончания поездки. Детям до 18 лет необходим детский паспорт или вписка в паспорт родителя.',
        ),
        _Section(
          title: '🇹🇷 Турция',
          body: 'Виза не требуется. Граждане Казахстана могут находиться в стране до 30 дней без визы. Рекомендуется иметь обратный билет и подтверждение брони отеля.',
        ),
        _Section(
          title: '🇪🇬 Египет',
          body: 'Виза оформляется по прилёту в аэропорту. Стоимость — 25 USD. Необходимо иметь наличные доллары. Срок пребывания — до 30 дней.',
        ),
        _Section(
          title: '🇹🇭 Таиланд',
          body: 'Виза не требуется для пребывания до 30 дней. При прилёте необходимо показать обратный билет и иметь при себе не менее 10 000 THB или эквивалент.',
        ),
        _Section(
          title: '🇦🇪 ОАЭ',
          body: 'Виза не требуется. Граждане Казахстана въезжают по безвизовому режиму на срок до 30 дней. Требуется обратный билет и бронь отеля.',
        ),
        _Section(
          title: '🇲🇻 Мальдивы',
          body: 'Туристическая виза выдаётся бесплатно по прилёту на 30 дней. Необходимо подтверждение брони проживания и обратный билет.',
        ),
        _Section(
          title: '💉 Медицинские требования',
          body: 'Прививки не обязательны для большинства направлений. Рекомендуется оформить страховку с покрытием не менее 30 000 USD. Страховка входит в стоимость тура.',
        ),
        _Section(
          title: '🚫 Ограничения',
          body: 'Запрещён ввоз наркотических веществ, оружия, а также продуктов животного происхождения без соответствующих сертификатов. Ограничение на ввоз алкоголя — 1 литр на человека.',
        ),
      ],
    );
  }

  static void showFaq(BuildContext context) {
    _show(
      context,
      title: 'Часто задаваемые вопросы',
      sections: const [
        _Section(
          title: '❓ Что входит в стоимость тура?',
          body: 'В стоимость включены: авиаперелёт туда и обратно, трансфер аэропорт—отель—аэропорт, проживание в номере выбранной категории, питание согласно выбранному типу, страховка. Экскурсии и личные расходы оплачиваются отдельно.',
        ),
        _Section(
          title: '❓ Когда я получу документы на тур?',
          body: 'Электронные билеты, ваучер на отель и страховой полис будут отправлены на вашу электронную почту за 3–5 дней до вылета. Менеджер также продублирует их в мессенджер.',
        ),
        _Section(
          title: '❓ Можно ли изменить даты после бронирования?',
          body: 'Изменение дат возможно при наличии мест на другие рейсы. Перенос более чем за 14 дней — бесплатно. Менее чем за 14 дней — штраф от 5 000 ₸. Свяжитесь с менеджером для уточнения.',
        ),
        _Section(
          title: '❓ Что делать если потерял багаж?',
          body: 'Немедленно обратитесь на стойку Lost & Found в аэропорту прилёта. Составьте акт PIR. Сообщите менеджеру TravelKZ — мы поможем с поиском и возмещением через страховую.',
        ),
        _Section(
          title: '❓ Как работает программа бонусов?',
          body: 'За каждое бронирование начисляются бонусы: туры — 2%, отели — 1.5%, чартеры — 1% от суммы. Бонусы можно списать при следующем бронировании (до 20% от стоимости). Бонусы не имеют срока действия.',
        ),
        _Section(
          title: '❓ Что такое рассрочка 0%?',
          body: 'При оформлении тура вы можете разбить сумму на 12 или 24 месяца без переплат через Kaspi Gold или Home Credit Bank. Оформление занимает 10 минут. Ваш менеджер поможет со всеми документами.',
        ),
        _Section(
          title: '❓ Как связаться с менеджером во время поездки?',
          body: 'Ваш персональный менеджер доступен 24/7 в WhatsApp и Telegram. Контакт будет передан за 3 дня до вылета. Также доступна горячая линия: +7 (727) 123-45-67.',
        ),
        _Section(
          title: '❓ Есть ли скидки для детей?',
          body: 'Дети до 2 лет (без отдельного места) — бесплатно. Дети 2–12 лет — скидка 30% от стоимости тура. Дети старше 12 лет — тариф взрослого. Укажите возраст детей при бронировании.',
        ),
      ],
    );
  }

  static void showPaymentRules(BuildContext context) {
    _show(
      context,
      title: 'Правила въезда и оплаты',
      sections: const [
        _Section(
          title: '💳 Способы оплаты',
          body: 'Принимаем оплату через: банковские карты Visa и Mastercard, Kaspi Pay, Kaspi QR, банковский перевод на расчётный счёт. Оплата производится в тенге по курсу на день оплаты.',
        ),
        _Section(
          title: '📋 Порядок оплаты',
          body: '1. Бронирование и подтверждение тура\n2. Внесение предоплаты 30% в течение 24 часов\n3. Оплата оставшейся суммы за 14 дней до вылета\n\nПри оплате полной суммы сразу — скидка 2%.',
        ),
        _Section(
          title: '🔄 Рассрочка и кредит',
          body: 'Доступна рассрочка 0% через Kaspi Gold на 3, 6, 12 или 24 месяца. Также возможно оформление кредита через Home Credit Bank до 36 месяцев. Решение по заявке — в течение 15 минут.',
        ),
        _Section(
          title: '❌ Условия отмены',
          body: 'За 30+ дней до вылета — возврат 100%\nЗа 14–29 дней — возврат 70%\nЗа 7–13 дней — возврат 50%\nМенее 7 дней — возврат 20%\n\nВозврат производится в течение 10 рабочих дней.',
        ),
        _Section(
          title: '🛂 Правила въезда',
          body: 'Для большинства направлений (Турция, ОАЭ, Таиланд) виза не требуется. Египет — виза по прилёту 25 USD. Мальдивы — бесплатная виза по прилёту. Необходим действующий загранпаспорт (срок действия 6+ месяцев).',
        ),
        _Section(
          title: '📄 Документы для оформления',
          body: 'Для бронирования потребуются: копия загранпаспорта (все участники тура), контактный номер телефона, email для получения документов. Документы передаются менеджеру в мессенджере.',
        ),
        _Section(
          title: '⚖️ Ответственность сторон',
          body: 'TravelKZ несёт ответственность за качество предоставленных услуг согласно договору. Туроператор не несёт ответственности за форс-мажорные обстоятельства (закрытие границ, стихийные бедствия и т.д.).',
        ),
      ],
    );
  }

  // ── Internal ────────────────────────────────────────────────────

  static void _show(
    BuildContext context, {
    required String title,
    required List<_Section> sections,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InfoSheet(title: title, sections: sections),
    );
  }
}

// ── Sheet widget ────────────────────────────────────────────────────

class _InfoSheet extends StatelessWidget {
  final String title;
  final List<_Section> sections;

  const _InfoSheet({required this.title, required this.sections});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.grey900,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),

            // Content
            Expanded(
              child: ListView.separated(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                itemCount: sections.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (_, i) => _SectionCard(section: sections[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatefulWidget {
  final _Section section;
  const _SectionCard({required this.section});

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _expanded
              ? AppColors.primary.withValues(alpha: 0.04)
              : AppColors.grey50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _expanded ? AppColors.primary.withValues(alpha: 0.3) : AppColors.grey200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.section.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _expanded ? AppColors.primary : AppColors.grey900,
                    ),
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: _expanded ? AppColors.primary : AppColors.grey400,
                  size: 22,
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 10),
              Text(
                widget.section.body,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.grey700,
                  height: 1.6,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Section {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});
}