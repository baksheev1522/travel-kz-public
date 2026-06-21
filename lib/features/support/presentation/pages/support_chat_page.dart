import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

/// Путь: lib/features/support/presentation/pages/support_chat_page.dart
class SupportChatPage extends StatefulWidget {
  const SupportChatPage({super.key});

  @override
  State<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends State<SupportChatPage> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_Message> _messages = [];
  bool _isTyping = false;

  static const _quickReplies = [
    _QR(label: '📋 Мои бронирования', text: 'Где посмотреть мои бронирования?'),
    _QR(label: '💳 Оплата',           text: 'Как оплатить тур?'),
    _QR(label: '❌ Отмена',            text: 'Как отменить бронирование?'),
    _QR(label: '🎁 Бонусы',            text: 'Как работают бонусы?'),
    _QR(label: '✈️ Документы',         text: 'Какие документы нужны для тура?'),
    _QR(label: '📞 Оператор',          text: 'Хочу поговорить с оператором'),
  ];

  static const _rules = <_Rule>[
    _Rule(
      keywords: ['бронирован', 'заказ', 'мои туры', 'посмотреть'],
      answer: '📋 *Мои бронирования*\n\n'
          'Все заказы находятся в разделе:\n'
          '👤 Профиль → «Мои бронирования»\n\n'
          'Там вы найдёте:\n'
          '• Статус каждого тура\n'
          '• Детали и даты поездки\n'
          '• Контакты менеджера\n\n'
          'Есть конкретный вопрос?',
    ),
    _Rule(
      keywords: ['оплат', 'платить', 'картой', 'kaspi', 'каспи', 'способ'],
      answer: '💳 *Способы оплаты*\n\n'
          'Мы принимаем:\n'
          '• Банковские карты Visa / Mastercard\n'
          '• Kaspi Pay и Kaspi QR\n'
          '• Перевод на расчётный счёт\n\n'
          'Доступна рассрочка 0% до 12 месяцев.\n\n'
          'Оплата при оформлении в приложении 📱',
    ),
    _Rule(
      keywords: ['отмен', 'возврат', 'вернуть', 'деньги', 'отказ'],
      answer: '❌ *Отмена и возврат*\n\n'
          'Условия по срокам до вылета:\n\n'
          '• За 30+ дней — возврат 100%\n'
          '• За 14–29 дней — возврат 70%\n'
          '• За 7–13 дней — возврат 50%\n'
          '• Менее 7 дней — возврат 20%\n\n'
          '📧 support@travelkz.kz\n'
          '📞 +7 (727) 123-45-67',
    ),
    _Rule(
      keywords: ['бонус', 'баллы', 'накопить', 'потратить', 'кешбэк'],
      answer: '🎁 *Бонусная программа*\n\n'
          'Начисляем за каждое бронирование:\n'
          '• Туры — 2% от суммы\n'
          '• Отели — 1.5% от суммы\n'
          '• Чартеры — 1% от суммы\n\n'
          'Бонусами можно оплатить до 20%\n'
          'от стоимости следующего тура.\n\n'
          'Баланс бонусов — в разделе Профиль 👤',
    ),
    _Rule(
      keywords: ['документ', 'паспорт', 'виза', 'нужно', 'загран'],
      answer: '✈️ *Необходимые документы*\n\n'
          'Обязательно:\n'
          '• Загранпаспорт (действует 6+ мес)\n'
          '• Детский паспорт для детей\n\n'
          'Виза по направлениям:\n'
          '• Турция, ОАЭ, Таиланд — без визы\n'
          '• Египет — виза по прилёту (25\$)\n'
          '• Мальдивы — бесплатно по прилёту\n\n'
          'Полный список придёт на email\n'
          'после оформления бронирования 📧',
    ),
    _Rule(
      keywords: ['оператор', 'менеджер', 'человек', 'позвон', 'связь'],
      answer: '📞 *Связь с оператором*\n\n'
          'График работы:\n'
          'Пн–Пт: 09:00 – 20:00\n'
          'Сб–Вс: 10:00 – 18:00\n\n'
          '📱 +7 (727) 123-45-67\n'
          '📧 support@travelkz.kz\n'
          '💬 WhatsApp: +7 700 123-45-67\n\n'
          'Среднее время ответа — 5 минут ⚡',
    ),
    _Rule(
      keywords: ['рассрочк', 'кредит'],
      answer: '💳 *Рассрочка и кредит*\n\n'
          'Доступна рассрочка 0% через:\n'
          '• Kaspi Gold — до 24 месяцев\n'
          '• Home Credit Bank — до 36 месяцев\n\n'
          'Оформление с помощью вашего менеджера.',
    ),
    _Rule(
      keywords: ['привет', 'здравствуй', 'добрый', 'хай'],
      answer: '👋 Привет!\n\n'
          'Рад вас видеть в TravelKZ!\n'
          'Чем могу помочь сегодня?\n\n'
          'Выберите тему ниже или напишите\n'
          'свой вопрос 😊',
    ),
    _Rule(
      keywords: ['спасибо', 'благодарю', 'супер', 'отлично', 'классно'],
      answer: '😊 Пожалуйста!\n\n'
          'Если появятся ещё вопросы —\n'
          'всегда готов помочь.\n\n'
          'Желаем незабываемого отдыха! 🌴✈️',
    ),
  ];

  static const _fallback =
      '🤔 Не совсем понял вопрос.\n\n'
      'Попробуйте выбрать тему из меню\n'
      'или свяжитесь с нами напрямую:\n\n'
      '📞 +7 (727) 123-45-67\n'
      '📧 support@travelkz.kz\n\n'
      'Пн–Пт 09:00–20:00 · Сб–Вс 10:00–18:00';

  @override
  void initState() {
    super.initState();
    _messages.add(const _Message(
      text: 'Здравствуйте! 👋\n\n'
          'Я виртуальный помощник TravelKZ.\n'
          'Отвечаю на частые вопросы 24/7.\n\n'
          'Выберите тему или напишите свой вопрос:',
      isSupport: true,
    ));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _ctrl.text).trim();
    if (text.isEmpty || _isTyping) return;
    _ctrl.clear();

    setState(() {
      _messages.add(_Message(text: text, isSupport: false));
      _isTyping = true;
    });
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    setState(() {
      _messages.add(_Message(text: _findAnswer(text), isSupport: true));
      _isTyping = false;
    });
    _scrollToBottom();
  }

  String _findAnswer(String input) {
    final lower = input.toLowerCase();
    for (final rule in _rules) {
      if (rule.keywords.any(lower.contains)) return rule.answer;
    }
    return _fallback;
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Icon(Icons.support_agent_rounded,
                  color: AppColors.primary, size: 18),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Поддержка TravelKZ',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                Row(
                  children: [
                    CircleAvatar(radius: 4, backgroundColor: Color(0xFF4CAF50)),
                    SizedBox(width: 5),
                    Text('Онлайн · ответим за 5 мин',
                        style: TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickReplies
                    .map((q) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _Chip(label: q.label, onTap: () => _send(q.text)),
                        ))
                    .toList(),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _messages.length) return const _TypingIndicator();
                return _Bubble(message: _messages[i]);
              },
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
                12, 10, 12, MediaQuery.of(context).padding.bottom + 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    maxLines: 3,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Напишите вопрос...',
                      filled: true,
                      fillColor: AppColors.grey100,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _send(),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                        color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
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

// ── Models ───────────────────────────────────────────────────────

class _Message {
  final String text;
  final bool isSupport;
  const _Message({required this.text, required this.isSupport});
}

class _Rule {
  final List<String> keywords;
  final String answer;
  const _Rule({required this.keywords, required this.answer});
}

class _QR {
  final String label;
  final String text;
  const _QR({required this.label, required this.text});
}

// ── Widgets ──────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w500)),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final _Message message;
  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            message.isSupport ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (message.isSupport) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.support_agent_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isSupport ? Colors.white : AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(message.isSupport ? 4 : 18),
                  bottomRight: Radius.circular(message.isSupport ? 18 : 4),
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 14,
                  color: message.isSupport ? AppColors.grey900 : Colors.white,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (!message.isSupport) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
                color: AppColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.support_agent_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
              ],
            ),
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => Row(
                children: List.generate(3, (i) {
                  final opacity = (((_ctrl.value + i * 0.3) % 1.0)).clamp(0.2, 1.0);
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: opacity),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}