import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../core/utils/api_client.dart';
import '../providers/booking_provider.dart';

class ClubsScreen extends StatefulWidget {
  const ClubsScreen({super.key});

  @override
  State<ClubsScreen> createState() => _ClubsScreenState();
}

class _ClubsScreenState extends State<ClubsScreen> {
  Future<List<dynamic>> _fetchCafes() async {
    final response = await ApiClient.get('/cafes');
    return response['data']; 
  }

  // Открываем навигатор (Яндекс или Google Maps)
  Future<void> _openMap(String address) async {
    final Uri url = Uri.parse('https://yandex.ru/maps/?text=${Uri.encodeComponent(address)}');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось открыть карту')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Наши клубы', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true, 
        backgroundColor: colorScheme.surface, 
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _fetchCafes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: colorScheme.primary));
          if (snapshot.hasError) return Center(child: Text('Ошибка: ${snapshot.error}', style: TextStyle(color: colorScheme.error)));

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
                          // Кнопки действий
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _openMap(address),
                                  icon: const Icon(FontAwesomeIcons.map, size: 16),
                                  label: const Text('Маршрут'),
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
                                  label: const Text('Забронировать'),
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