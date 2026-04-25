import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

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

  // Стартовое сообщение — будет установлено в initState
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    // Добавляем приветствие после того, как SettingsProvider доступен
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsProvider>();
      if (_messages.isEmpty) {
        setState(() {
          _messages.add(ChatMessage(
            text: settings.getText('bot_welcome'),
            isUser: false,
          ));
        });
      }
    });
  }

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

  /// Rule-based ответы на частые вопросы (с поддержкой языка)
  String _getBotResponse(String message) {
    final settings = context.read<SettingsProvider>();
    final msg = message.toLowerCase().trim();

    // Приветствие
    if (msg.contains('привет') || msg.contains('здравствуй') || msg.contains('хай') || msg == 'здравствуйте' ||
        msg.contains('hello') || msg.contains('hi') || msg.contains('hey')) {
      return settings.getText('bot_greeting');
    }

    // Цены / тарифы
    if (msg.contains('цен') || msg.contains('тариф') || msg.contains('стоит') || msg.contains('прайс') || msg.contains('сколько') ||
        msg.contains('price') || msg.contains('rate') || msg.contains('cost') || msg.contains('how much')) {
      return settings.getText('bot_prices');
    }

    // Адреса
    if (msg.contains('адрес') || msg.contains('где') || msg.contains('находит') || 
        msg.contains('address') || msg.contains('where') || msg.contains('location')) {
      return settings.getText('bot_address');
    }

    // Железо / компьютеры
    if (msg.contains('желез') || msg.contains('компьютер') || msg.contains('видеокарт') || msg.contains('rtx') || 
        msg.contains('монитор') || msg.contains('мышк') || msg.contains('клавиатур') ||
        msg.contains('hardware') || msg.contains('gpu') || msg.contains('monitor') || msg.contains('mouse') || msg.contains('keyboard')) {
      return settings.getText('bot_hardware');
    }

    // Правила
    if (msg.contains('правил') || msg.contains('можно') || msg.contains('нельзя') || msg.contains('18') || msg.contains('паспорт') ||
        msg.contains('rule') || msg.contains('allowed') || msg.contains('not allowed') || msg.contains('age')) {
      return settings.getText('bot_rules');
    }

    // Время работы
    if (msg.contains('работ') || msg.contains('открыт') || msg.contains('закрыт') || msg.contains('24') || msg.contains('круглосуточ') ||
        msg.contains('hour') || msg.contains('open') || msg.contains('closed') || msg.contains('24/7')) {
      return settings.getText('bot_hours');
    }

    // Бронирование
    if (msg.contains('бронь') || msg.contains('бронирован') || msg.contains('забронир') || msg.contains('записат') ||
        msg.contains('book') || msg.contains('reserve') || msg.contains('booking')) {
      return settings.getText('bot_booking');
    }

    // Если ничего не подошло
    return settings.getText('bot_fallback');
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

    // Имитируем задержку ответа (как будто бот "думает")
    await Future.delayed(const Duration(milliseconds: 600));

    final reply = _getBotResponse(text);

    setState(() {
      _messages.add(ChatMessage(text: reply, isUser: false));
      _isTyping = false;
    });

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(FontAwesomeIcons.robot, color: colorScheme.primary, size: 20),
            const SizedBox(width: 12),
            Text(
              settings.getText('chat_title'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
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
                  return _buildTypingIndicator(colorScheme, settings);
                }
                return _buildMessageBubble(_messages[index], colorScheme);
              },
            ),
          ),
          _buildInputArea(colorScheme, settings),
        ],
      ),
    );
  }

  Widget _buildInputArea(ColorScheme colorScheme, SettingsProvider settings) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
            top: BorderSide(color: colorScheme.outline.withOpacity(0.2), width: 1)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: settings.getText('chat_hint'),
                  hintStyle:
                      TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                child: Icon(FontAwesomeIcons.paperPlane,
                    color: colorScheme.onPrimary, size: 16),
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
          color: message.isUser ? colorScheme.primary : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: message.isUser
                ? const Radius.circular(16)
                : const Radius.circular(4),
            bottomRight: message.isUser
                ? const Radius.circular(4)
                : const Radius.circular(16),
          ),
        ),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(ColorScheme colorScheme, SettingsProvider settings) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          settings.getText('chat_typing'),
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
