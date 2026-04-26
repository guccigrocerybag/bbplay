import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../core/utils/api_client.dart';
import '../providers/booking_provider.dart';
import '../providers/settings_provider.dart';

class ClubsScreen extends StatefulWidget {
  const ClubsScreen({super.key});

  @override
  State<ClubsScreen> createState() => _ClubsScreenState();
}

class _ClubsScreenState extends State<ClubsScreen> {
  // Статические контакты клуба (сервер их не возвращает)
  static const String _clubPhone = '+7 (999) 123-45-67';
  static const String _clubPhoneRaw = '+79991234567';
  static const String _clubTelegram = 't.me/bbplay_club';

  Future<List<dynamic>> _fetchCafes() async {
    final response = await ApiClient.get('/cafes');
    return response['data']; 
  }

  // Открывает Яндекс.Карты с адресом клуба
  // Яндекс.Карты сами определят геолокацию пользователя и предложат построить маршрут
  Future<void> _openMap(String address) async {
    final Uri url = Uri.parse(
        'https://yandex.ru/maps/?text=${Uri.encodeComponent(address)}&z=17&l=map');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (!mounted) return;
      final s = Provider.of<SettingsProvider>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.getText('map_error'))),
      );
    }
  }

  // Открывает приложение телефона для звонка
  Future<void> _callClub() async {
    final Uri url = Uri.parse('tel:$_clubPhoneRaw');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (!mounted) return;
      final s = Provider.of<SettingsProvider>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.getText('call_error'))),
      );
    }
  }

  // Открывает Telegram-канал клуба
  Future<void> _openTelegram() async {
    final Uri url = Uri.parse('https://$_clubTelegram');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (!mounted) return;
      final s = Provider.of<SettingsProvider>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.getText('telegram_error'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final s = Provider.of<SettingsProvider>(context);
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(s.getText('clubs_title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true, 
        backgroundColor: colorScheme.surface, 
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _fetchCafes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return _buildShimmerLoading(colorScheme);
          if (snapshot.hasError) return Center(child: Text('${s.getText('error_prefix')} ${snapshot.error}', style: TextStyle(color: colorScheme.error)));

          final cafes = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cafes.length,
            itemBuilder: (context, index) {
              final cafe = cafes[index];
              final name = cafe['name'] ?? 'Без названия';
              final address = cafe['address'] ?? 'Адрес не указан';
              final phone = cafe['phone'] ?? 'Телефон не указан';
              final workTime = cafe['work_time'] ?? 'Время работы не указано';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Заголовок клуба
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Row(
                        children: [
                          const Icon(FontAwesomeIcons.locationDot, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Информация о клубе
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(FontAwesomeIcons.mapLocationDot, address, colorScheme),
                          const SizedBox(height: 8),
                          _buildInfoRow(FontAwesomeIcons.phone, phone, colorScheme),
                          const SizedBox(height: 8),
                          _buildInfoRow(FontAwesomeIcons.clock, workTime, colorScheme),
                          const SizedBox(height: 16),
                          // Контакты клуба
                          Row(
                            children: [
                              // Кнопка "Позвонить"
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _callClub,
                                  icon: const Icon(FontAwesomeIcons.phone, size: 14),
                                  label: Text(_clubPhone, style: const TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: colorScheme.primary,
                                    side: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Кнопка "Telegram"
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _openTelegram,
                                  icon: const Icon(FontAwesomeIcons.telegram, size: 14),
                                  label: Text(s.getText('telegram'), style: const TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF0088CC),
                                    side: const BorderSide(color: Color(0xFF0088CC), width: 0.5),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Кнопки действий
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _openMap(address),
                                  icon: const Icon(FontAwesomeIcons.map, size: 16),
                                  label: Text(s.getText('route')),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // Переход на экран бронирования
                                    Provider.of<BookingProvider>(context, listen: false).setTab(2);
                                  },
                                  icon: const Icon(FontAwesomeIcons.desktop, size: 16),
                                  label: Text(
                                    s.getText('book_now'),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.secondary,
                                    foregroundColor: colorScheme.onSecondary,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Скелетон-загрузка с эффектом Shimmer для списка клубов
  Widget _buildShimmerLoading(ColorScheme colorScheme) {
    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceVariant.withOpacity(0.5),
      highlightColor: colorScheme.surfaceVariant.withOpacity(0.8),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                ),
                // Информация
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(height: 14, width: double.infinity, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(height: 14, width: 200, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(height: 14, width: 150, color: Colors.white),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: Container(height: 40, color: Colors.white)),
                          const SizedBox(width: 12),
                          Expanded(child: Container(height: 40, color: Colors.white)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurface.withOpacity(0.7)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}