import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

/// Демо-данные турниров
class _Tournament {
  final String name;
  final String game;
  final String format;
  final String prize;
  final String date;
  final String club;
  final String status; // 'upcoming', 'ongoing', 'completed'
  final IconData gameIcon;
  final Color gameColor;

  const _Tournament({
    required this.name,
    required this.game,
    required this.format,
    required this.prize,
    required this.date,
    required this.club,
    required this.status,
    required this.gameIcon,
    required this.gameColor,
  });
}

/// Список демо-турниров
final List<_Tournament> _demoTournaments = [
  _Tournament(
    name: 'CS2 5x5 Cup',
    game: 'CS2',
    format: '5x5',
    prize: '50 000 ₽',
    date: '15.05.2026',
    club: 'Vibe',
    status: 'upcoming',
    gameIcon: Icons.sports_esports,
    gameColor: Color(0xFFFF6B35),
  ),
  _Tournament(
    name: 'Valorant Open',
    game: 'Valorant',
    format: '3x3',
    prize: '30 000 ₽',
    date: '22.05.2026',
    club: 'Black Bears',
    status: 'upcoming',
    gameIcon: Icons.flash_on,
    gameColor: Color(0xFFFD4556),
  ),
  _Tournament(
    name: 'Dota 2 Championship',
    game: 'Dota 2',
    format: '5x5',
    prize: '100 000 ₽',
    date: '01.06.2026',
    club: 'Vibe',
    status: 'upcoming',
    gameIcon: Icons.shield,
    gameColor: Color(0xFFB548C6),
  ),
  _Tournament(
    name: 'Street Fighter 6 Showdown',
    game: 'Street Fighter 6',
    format: '1x1',
    prize: '15 000 ₽',
    date: '08.06.2026',
    club: 'Black Bears',
    status: 'upcoming',
    gameIcon: Icons.sports_kabaddi,
    gameColor: Color(0xFF2196F3),
  ),
  _Tournament(
    name: 'CS2 Night Cup',
    game: 'CS2',
    format: '5x5',
    prize: '25 000 ₽',
    date: '10.04.2026',
    club: 'Vibe',
    status: 'completed',
    gameIcon: Icons.sports_esports,
    gameColor: Color(0xFFFF6B35),
  ),
  _Tournament(
    name: 'Valorant Weekly',
    game: 'Valorant',
    format: '3x3',
    prize: '10 000 ₽',
    date: '05.04.2026',
    club: 'Black Bears',
    status: 'completed',
    gameIcon: Icons.flash_on,
    gameColor: Color(0xFFFD4556),
  ),
];

class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({super.key});

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  String _filter = 'all'; // 'all', 'upcoming', 'past'
  final Set<String> _registeredTournaments = {};

  List<_Tournament> get _filteredTournaments {
    if (_filter == 'all') return _demoTournaments;
    return _demoTournaments.where((t) => t.status == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          settings.getText('tournaments_title'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Фильтры
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('all', settings.getText('tournaments_all'), colorScheme),
                const SizedBox(width: 8),
                _buildFilterChip('upcoming', settings.getText('tournaments_upcoming'), colorScheme),
                const SizedBox(width: 8),
                _buildFilterChip('past', settings.getText('tournaments_past'), colorScheme),
              ],
            ),
          ),
          // Список турниров
          Expanded(
            child: _filteredTournaments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.emoji_events_outlined, size: 64, color: colorScheme.onSurface.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text(
                          settings.getText('tournaments_no_tournaments'),
                          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _filteredTournaments.length,
                    itemBuilder: (context, index) {
                      final t = _filteredTournaments[index];
                      final isRegistered = _registeredTournaments.contains(t.name);
                      return _buildTournamentCard(t, isRegistered, settings, colorScheme);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, ColorScheme colorScheme) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTournamentCard(
    _Tournament t,
    bool isRegistered,
    SettingsProvider settings,
    ColorScheme colorScheme,
  ) {
    // Определяем статус
    String statusText;
    Color statusColor;
    switch (t.status) {
      case 'upcoming':
        statusText = settings.getText('tournaments_status_upcoming');
        statusColor = Colors.green;
        break;
      case 'ongoing':
        statusText = settings.getText('tournaments_status_ongoing');
        statusColor = Colors.orange;
        break;
      default:
        statusText = settings.getText('tournaments_status_completed');
        statusColor = colorScheme.onSurface.withValues(alpha: 0.4);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Верхняя строка: иконка игры + название + статус
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: t.gameColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(t.gameIcon, color: t.gameColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.name,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${t.game} • ${t.format}',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Статус
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Детали: дата, приз, клуб
          Row(
            children: [
              _buildDetailChip(Icons.calendar_today, t.date, colorScheme),
              const SizedBox(width: 8),
              _buildDetailChip(Icons.monetization_on, t.prize, colorScheme),
              const SizedBox(width: 8),
              _buildDetailChip(Icons.location_on, t.club, colorScheme),
            ],
          ),
          const SizedBox(height: 12),
          // Кнопка записи
          if (t.status == 'upcoming')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRegistered ? Colors.green : colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (!isRegistered) {
                    setState(() => _registeredTournaments.add(t.name));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(settings.getText('tournaments_registered')),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: Text(
                  isRegistered
                      ? '✅ ${settings.getText('tournaments_registered')}'
                      : settings.getText('tournaments_register'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colorScheme.onSurface.withValues(alpha: 0.6)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
