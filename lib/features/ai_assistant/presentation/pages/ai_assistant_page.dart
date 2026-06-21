import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../../../core/theme/app_theme.dart';

class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({super.key});

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_Message> _messages = [];
  bool _loading = false;

  static const _apiKey = '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';

  static const _systemPrompt = '''
Ты — AI ассистент туристического приложения TravelKZ.
Помогаешь пользователям подобрать идеальный тур.
Отвечай на русском языке, дружелюбно и кратко.

Доступные туры:
1. Турция — Белек, Rixos Premium Belek 5*, 7 ночей, All Inclusive, 450 000 ₸, горящий
2. Турция — Бодрум, Kempinski Barbaros Bay 5*, 7 ночей, Завтраки, 380 000 ₸, горящий
3. Египет — Хургада, Steigenberger Al Dau 4*, 10 ночей, All Inclusive, 320 000 ₸
4. Египет — Шарм-эль-Шейх, Four Seasons Resort 5*, 8 ночей, All Inclusive, 560 000 ₸, горящий
5. Таиланд — Пхукет, Trisara Resort 5*, 14 ночей, Завтраки, 680 000 ₸, горящий
6. Таиланд — Паттайя, Amari Pattaya 4*, 10 ночей, All Inclusive, 420 000 ₸
7. Таиланд — Самуи, Centara Grand Beach 5*, 12 ночей, Полупансион, 590 000 ₸, горящий
8. ОАЭ — Дубай, Burj Al Arab 5*, 5 ночей, Завтраки, 510 000 ₸
9. ОАЭ — Дубай, Atlantis The Palm 5*, 7 ночей, Завтраки, 750 000 ₸
10. Мальдивы — Атолл Южный Ари, Conrad Maldives 5*, 10 ночей, Полупансион, 1 200 000 ₸, горящий

Когда пользователь описывает желаемый отдых — подбери 1-2 подходящих тура.
Объясни почему именно этот тур подходит.
Если бюджет не указан — уточни.

ВАЖНО — формат ответа:
- Всегда используй эмодзи в начале каждого пункта
- Название тура выделяй на отдельной строке
- Цену пиши отдельной строкой
- Делай отступы между блоками
- Отвечай структурировано, не сплошным текстом
- Максимум 3-4 предложения на тур
- В конце задай один вопрос пользователю
''';

  @override
  void initState() {
    super.initState();
    _messages.add(const _Message(
      text: 'Привет! 👋 Я AI ассистент TravelKZ.\n\nОпишите какой отдых вы хотите — я подберу идеальный тур!\n\nНапример: "хочу тёплое море, бюджет 500к, лечу из Алматы на 7 ночей"',
      isAi: true,
    ));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _loading) return;

    setState(() {
      _messages.add(_Message(text: text, isAi: false));
      _loading = true;
    });
    _ctrl.clear();
    _scrollToBottom();

    try {
      final msgs = <Map<String, dynamic>>[
        {'role': 'system', 'content': _systemPrompt},
      ];
      for (int i = 1; i < _messages.length; i++) {
        msgs.add({
          'role': _messages[i].isAi ? 'assistant' : 'user',
          'content': _messages[i].text,
        });
      }

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': msgs,
          'max_tokens': 1024,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final aiText = data['choices'][0]['message']['content'] as String;
        setState(() {
          _messages.add(_Message(text: aiText, isAi: true));
          _loading = false;
        });
      } else {
        print('STATUS: ${response.statusCode}');
        print('BODY: ${response.body}');
        _showError();
      }
    } catch (e) {
      print('ERROR: $e');
      _showError();
    }
    _scrollToBottom();
  }

  void _showError() {
    setState(() {
      _messages.add(const _Message(
        text: 'Извините, произошла ошибка. Попробуйте снова.',
        isAi: true,
      ));
      _loading = false;
    });
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Icon(Icons.auto_awesome,
                  color: AppColors.primary, size: 18),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Ассистент',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Подберу тур для вас',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
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
            padding: const EdgeInsets.symmetric(
                vertical: 10, horizontal: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _QuickPrompt(
                    label: '🏖 Море до 400к',
                    onTap: () {
                      _ctrl.text = 'Хочу на море, бюджет до 400 000 ₸';
                      _send();
                    },
                  ),
                  const SizedBox(width: 8),
                  _QuickPrompt(
                    label: '🔥 Горящие туры',
                    onTap: () {
                      _ctrl.text = 'Покажи горящие туры';
                      _send();
                    },
                  ),
                  const SizedBox(width: 8),
                  _QuickPrompt(
                    label: '👨‍👩‍👧 С детьми',
                    onTap: () {
                      _ctrl.text = 'Хочу тур с детьми, что посоветуешь?';
                      _send();
                    },
                  ),
                  const SizedBox(width: 8),
                  _QuickPrompt(
                    label: '💎 Люкс отдых',
                    onTap: () {
                      _ctrl.text = 'Хочу роскошный отдых, бюджет не ограничен';
                      _send();
                    },
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _messages.length) return const _TypingIndicator();
                return _MessageBubble(message: _messages[i]);
              },
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              12, 10, 12,
              MediaQuery.of(context).padding.bottom + 10,
            ),
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
                      hintText: 'Опишите желаемый отдых...',
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
                  onTap: _send,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
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

class _Message {
  final String text;
  final bool isAi;
  const _Message({required this.text, required this.isAi});
}

class _MessageBubble extends StatelessWidget {
  final _Message message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: message.isAi
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (message.isAi) ...[
            Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isAi ? Colors.white : AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(message.isAi ? 4 : 18),
                  bottomRight: Radius.circular(message.isAi ? 18 : 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 14,
                  color: message.isAi ? AppColors.grey900 : Colors.white,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (!message.isAi) const SizedBox(width: 8),
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
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.auto_awesome,
              color: Colors.white, size: 16),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: List.generate(3, (i) {
              return AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                      alpha: i == 0
                          ? _ctrl.value
                          : i == 1
                              ? (_ctrl.value + 0.3).clamp(0, 1)
                              : (_ctrl.value + 0.6).clamp(0, 1),
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _QuickPrompt extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickPrompt({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}