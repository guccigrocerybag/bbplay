import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Модель сообщения
class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  
  // Стартовое сообщение
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Привет! Я виртуальный помощник BBplay 🐻\n\nМогу рассказать про наши цены, адреса клубов, мощное железо или правила. Чем помочь?',
      isUser: false,
    ),
  ];

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _controller.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    // Имитация ответа бота
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _messages.add(ChatMessage(text: _generateBotResponse(text), isUser: false));
      _isTyping = false;
    });

    _scrollToBottom();
  }

  String _generateBotResponse(String query) {
    query = query.toLowerCase();

    if (_contains(query, ['привет', 'здравствуй', 'хай', 'hello', 'hi', 'ку', 'салам'])) {
      return 'Привет! Рад тебя видеть! 🐻\n\nЧем могу помочь?';
    }

    if (_contains(query, ['адрес', 'где', 'клуб', 'локация', 'местоположение', 'адреса', 'филиал'])) {
      return 'У нас три клуба в Казани:\n\n'
             '📍 ул. Баумана, 12 (Центр)\n'
             '📍 ул. Профсоюзная, 29 (Юг)\n'
             '📍 ул. Мичуринская, 141а (Север)\n\n'
             'Мы работаем 24/7 без выходных!';
    }

    if (_contains(query, ['желез', 'пк', 'комп', 'характеристики', 'rtx', 'fps', 'фпс', 'видеокарт'])) {
      return 'Наши машины зарядят тебя на победу! 🚀\n\n'
             '• Видеокарты: NVIDIA RTX 4060 и 3060\n'
             '• Мониторы: 240Hz / 165Hz (отклик 1мс)\n'
             '• Девайсы: Мышки Logitech G Pro, Механика Dark Project\n\n'
             'Самое мощное железо ищи в VIP-залах!';
    }

    if (_contains(query, ['цена', 'сколько', 'стоит', 'прайс', 'тариф', 'деньги', 'пакет', 'скидк'])) {
      return 'Наши тарифы:\n'
             '🎮 GameZone — 100 ₽/час\n'
             '🔥 BootCamp — 150 ₽/час\n'
             '👑 VIP — 200 ₽/час\n\n'
             '💡 Выгоднее брать ПАКЕТЫ! Например, 5 часов в VIP стоят всего 222 ₽ вместо 1000 ₽. Проверь во вкладке бронирования!';
    }

    if (_contains(query, ['бронь', 'забронировать', 'занять', 'место', 'резерв'])) {
      return 'Всё просто:\n1. Зайди во вкладку "Clubs".\n2. Выбери клуб и зал.\n3. Выбери свободный ПК и время.\n4. Нажми "Pay".\n\nВажно: на балансе должны быть средства!';
    }

    if (_contains(query, ['правила', 'еда', 'пить', 'курить', 'алкоголь', 'паспорт', 'возраст'])) {
      return 'Напоминаю правила BBplay:\n'
             '✅ Можно: приносить свою периферию и заказывать еду.\n'
             '❌ Нельзя: приносить алкоголь и курить (в т.ч. вейпы).\n'
             '🔞 Ночью (после 22:00) вход строго 18+ и по паспорту.';
    }

    if (_contains(query, ['спасибо', 'спс', 'благодарю', 'круто'])) {
      return 'Всегда пожалуйста! Увидимся в клубе. Тащи катку! 🔥';
    }

    return 'Хмм, сложный вопрос... 🤔\n\nПопробуй спросить про "Цены", "Адреса", "Характеристики ПК" или "Правила клуба". Я обязательно подскажу!';
  }

  bool _contains(String text, List<String> keywords) {
    for (var word in keywords) {
      if (text.contains(word)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(FontAwesomeIcons.robot, color: colorScheme.primary, size: 20),
            const SizedBox(width: 12),
            const Text('Support Bot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator(colorScheme);
                }
                return _buildMessageBubble(_messages[index], colorScheme);
              },
            ),
          ),
          _buildInputArea(colorScheme),
        ],
      ),
    );
  }

  Widget _buildInputArea(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outline.withOpacity(0.2), width: 1)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Ваш вопрос...',
                  hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
                  filled: true,
                  fillColor: colorScheme.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25), 
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(FontAwesomeIcons.paperPlane, color: colorScheme.onPrimary, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, ColorScheme colorScheme) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: message.isUser ? colorScheme.primary : colorScheme.surfaceVariant,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: message.isUser ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: message.isUser ? const Radius.circular(4) : const Radius.circular(16),
          ),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(ColorScheme colorScheme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'Бот печатает...',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant.withOpacity(0.7),
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}