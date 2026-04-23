import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/utils/api_client.dart';
import '../providers/user_provider.dart';

/// Экран истории сессий (бронирований)
/// 
/// Отображает все бронирования пользователя, полученные с сервера.
/// Поддерживает сортировку, фильтрацию по статусу и отмену бронирований.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, String> _cafeNames = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCafeNames();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Загружает названия клубов с сервера для отображения в истории
  Future<void> _loadCafeNames() async {
    try {
      final response = await ApiClient.get('/cafes');
      final data = response['data'];
      
      final names = <String, String>{};
      
      if (data is List) {
        for (final cafe in data) {
          if (cafe is Map) {
            final id = cafe['icafe_id']?.toString() ?? '';
            final name = cafe['name']?.toString() ?? '';
            final displayName = name.isNotEmpty ? name : 'Клуб #$id';
            if (id.isNotEmpty) names[id] = displayName;
          }
        }
      } else if (data is Map) {
        data.forEach((key, value) {
          if (value is Map) {
            final id = key.toString();
            final name = value['name']?.toString() ?? '';
            final displayName = name.isNotEmpty ? name : 'Клуб #$id';
            if (id.isNotEmpty) names[id] = displayName;
          }
        });
      }
      
      if (mounted) {
        setState(() {
          _cafeNames = names;
        });
      }
    } catch (e) {
      // Игнорируем ошибку, используем fallback
    }
  }

  /// Определяет статус сессии на основе дат
  /// - 'upcoming' - будущая (активная)
  /// - 'active' - сейчас идет
  /// - 'completed' - завершена
  static String _getSessionStatus(Map<String, dynamic> session) {
    final fromStr = session['product_available_date_local_from']?.toString() ?? '';
    final toStr = session['product_available_date_local_to']?.toString() ?? '';

    if (fromStr.isEmpty || toStr.isEmpty) return 'unknown';

    try {
      final now = DateTime.now();
      final from = DateTime.parse(fromStr.replaceAll(' ', 'T'));
      final to = DateTime.parse(toStr.replaceAll(' ', 'T'));

      if (now.isBefore(from)) return 'upcoming';
      if (now.isAfter(to)) return 'completed';
      return 'active';
    } catch (e) {
      return 'unknown';
    }
  }

  /// Форматирует дату для отображения
  static String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '—';
    try {
      final dt = DateTime.parse(dateStr.replaceAll(' ', 'T'));
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final hours = dt.hour.toString().padLeft(2, '0');
      final minutes = dt.minute.toString().padLeft(2, '0');
      return '$day.$month $hours:$minutes';
    } catch (e) {
      return dateStr;
    }
  }

  /// Вычисляет продолжительность сессии в минутах
  static int _getDurationMinutes(Map<String, dynamic> session) {
    final mins = session['product_mins'];
    if (mins != null) return int.tryParse(mins.toString()) ?? 0;

    final fromStr =
        session['product_available_date_local_from']?.toString() ?? '';
    final toStr =
        session['product_available_date_local_to']?.toString() ?? '';
    if (fromStr.isEmpty || toStr.isEmpty) return 0;

    try {
      final from = DateTime.parse(fromStr.replaceAll(' ', 'T'));
      final to = DateTime.parse(toStr.replaceAll(' ', 'T'));
      return to.difference(from).inMinutes;
    } catch (e) {
      return 0;
    }
  }

  /// Форматирует продолжительность
  static String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes мин';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '$hours ч';
    return '$hours ч $mins мин';
  }

  /// Получает название клуба по ID
  String _getCafeName(String cafeId) {
    return _cafeNames[cafeId] ?? 'Клуб #$cafeId';
  }

  /// Отмена бронирования
  Future<void> _cancelBooking(
      String bookingId, String pcName, String offerId) async {
    final user = Provider.of<UserProvider>(context, listen: false);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final cafeId = user.userData?['member_icafe_id']?.toString() ?? '87375';

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            Center(child: CircularProgressIndicator(color: colorScheme.primary)),
      );

      await ApiClient.cancelBooking(cafeId, bookingId, pcName, offerId);

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Бронирование успешно отменено'),
          backgroundColor: colorScheme.primary,
        ),
      );

      setState(() {}); // Перезагружаем список
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка отмены: $e'),
          backgroundColor: colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('История сессий',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurface.withOpacity(0.5),
          indicatorColor: colorScheme.primary,
          tabs: const [
            Tab(text: 'Все'),
            Tab(text: 'Активные'),
            Tab(text: 'Завершённые'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: colorScheme.primary),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHistoryList(user, colorScheme, null),
                _buildHistoryList(user, colorScheme, 'upcoming'),
                _buildHistoryList(user, colorScheme, 'completed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(
      UserProvider user, ColorScheme colorScheme, String? filterStatus) {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadCafeNames();
        setState(() {});
      },
      color: colorScheme.primary,
      child: FutureBuilder<Map<String, dynamic>>(
        key: UniqueKey(),
        future: ApiClient.getBookingHistory(user.account),
        builder: (context, snapshot) {
          // Загрузка
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: colorScheme.primary));
          }

          // Ошибка
          if (snapshot.hasError) {
            return _buildErrorView(colorScheme, snapshot.error.toString());
          }

          // Нет данных
          if (!snapshot.hasData || snapshot.data == null) {
            return _buildEmptyState(colorScheme, 'Нет данных от сервера');
          }

          final response = snapshot.data!;
          final rawData = response['data'];
          List<_ParsedSession> allSessions = [];

          if (rawData != null) {
            if (rawData is Map) {
              rawData.forEach((cafeId, bookings) {
                if (bookings is List) {
                  for (final booking in bookings) {
                    if (booking is Map<String, dynamic>) {
                      allSessions.add(_ParsedSession(
                        cafeId: cafeId.toString(),
                        cafeName: _getCafeName(cafeId.toString()),
                        pcName:
                            booking['product_pc_name']?.toString() ?? 'Неизвестный ПК',
                        from: booking['product_available_date_local_from']
                                ?.toString() ??
                            '',
                        to: booking['product_available_date_local_to']
                                ?.toString() ??
                            '',
                        mins: _getDurationMinutes(booking),
                        description:
                            booking['product_description']?.toString() ?? '',
                        bookingId: booking['product_id']?.toString() ?? '',
                        offerId: booking['member_offer_id']?.toString() ?? '',
                        memberAccount:
                            booking['member_account']?.toString() ?? '',
                        status: _getSessionStatus(booking),
                      ));
                    }
                  }
                }
              });
            } else if (rawData is List) {
              for (final booking in rawData) {
                if (booking is Map<String, dynamic>) {
                  allSessions.add(_ParsedSession(
                    cafeId: '',
                    cafeName: 'Неизвестный клуб',
                    pcName:
                        booking['product_pc_name']?.toString() ?? 'Неизвестный ПК',
                    from: booking['product_available_date_local_from']
                            ?.toString() ??
                        '',
                    to: booking['product_available_date_local_to']
                            ?.toString() ??
                        '',
                    mins: _getDurationMinutes(booking),
                    description:
                        booking['product_description']?.toString() ?? '',
                    bookingId: booking['product_id']?.toString() ?? '',
                    offerId: booking['member_offer_id']?.toString() ?? '',
                    memberAccount:
                        booking['member_account']?.toString() ?? '',
                    status: _getSessionStatus(booking),
                  ));
                }
              }
            }
          }

          // Фильтрация по статусу
          if (filterStatus != null) {
            allSessions =
                allSessions.where((s) => s.status == filterStatus).toList();
          }

          // Сортировка: сначала будущие (по возрастанию даты),
          // потом завершенные (по убыванию даты)
          allSessions.sort((a, b) {
            if (a.status == 'upcoming' && b.status != 'upcoming') return -1;
            if (a.status != 'upcoming' && b.status == 'upcoming') return 1;
            if (a.status == 'upcoming' && b.status == 'upcoming') {
              return a.from.compareTo(b.from);
            }
            // Для завершенных и активных - по убыванию даты
            return b.from.compareTo(a.from);
          });

          if (allSessions.isEmpty) {
            final message = filterStatus == 'upcoming'
                ? 'Нет активных бронирований'
                : filterStatus == 'completed'
                    ? 'Нет завершённых сессий'
                    : 'Бронирований пока нет';
            return _buildEmptyState(colorScheme, message);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allSessions.length,
            itemBuilder: (context, index) {
              return _buildSessionCard(allSessions[index], colorScheme);
            },
          );
        },
      ),
    );
  }

  Widget _buildErrorView(ColorScheme colorScheme, String error) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Icon(FontAwesomeIcons.exclamationTriangle,
            size: 50, color: colorScheme.error),
        const SizedBox(height: 16),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Ошибка загрузки истории:\n${error.replaceAll('Exception: ', '')}',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.error, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: ElevatedButton(
            onPressed: () => setState(() {}),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            child: const Text('ПОВТОРИТЬ'),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, String message) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        Icon(FontAwesomeIcons.calendarXmark,
            size: 50, color: colorScheme.onSurface.withOpacity(0.5)),
        const SizedBox(height: 16),
        Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style:
                TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: ElevatedButton(
            onPressed: () => setState(() {}),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            child: const Text('ОБНОВИТЬ'),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionCard(_ParsedSession session, ColorScheme colorScheme) {
    // Определяем цвет и текст статуса
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (session.status) {
      case 'upcoming':
        statusColor = Colors.green;
        statusText = 'АКТИВНО';
        statusIcon = FontAwesomeIcons.checkCircle;
        break;
      case 'active':
        statusColor = Colors.orange;
        statusText = 'ИДЁТ СЕЙЧАС';
        statusIcon = FontAwesomeIcons.play;
        break;
      case 'completed':
        statusColor = colorScheme.onSurface.withOpacity(0.5);
        statusText = 'ЗАВЕРШЕНО';
        statusIcon = FontAwesomeIcons.check;
        break;
      default:
        statusColor = colorScheme.onSurface.withOpacity(0.5);
        statusText = 'НЕИЗВЕСТНО';
        statusIcon = FontAwesomeIcons.question;
    }

    // Определяем, можно ли отменить (только будущие)
    final bool canCancel = session.status == 'upcoming';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Верхняя часть с клубом и статусом
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: canCancel
                  ? colorScheme.primary.withOpacity(0.08)
                  : Colors.transparent,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                // Иконка клуба
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: canCancel
                        ? colorScheme.primary.withOpacity(0.15)
                        : colorScheme.onSurface.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    FontAwesomeIcons.gamepad,
                    size: 18,
                    color: canCancel
                        ? colorScheme.primary
                        : colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(width: 12),
                // Название клуба и ПК
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.cafeName,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ПК ${session.pcName}',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Бейдж статуса
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Детали сессии
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                // Дата и время
                Row(
                  children: [
                    Icon(FontAwesomeIcons.clock,
                        size: 14,
                        color: colorScheme.onSurface.withOpacity(0.6)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_formatDate(session.from)} — ${_formatDate(session.to)}',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.85),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Продолжительность
                Row(
                  children: [
                    Icon(FontAwesomeIcons.hourglassHalf,
                        size: 14,
                        color: colorScheme.onSurface.withOpacity(0.6)),
                    const SizedBox(width: 8),
                    Text(
                      _formatDuration(session.mins),
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.85),
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    // Аккаунт, если не текущий
                    if (session.memberAccount.isNotEmpty &&
                        session.memberAccount !=
                            Provider.of<UserProvider>(context, listen: false)
                                .account)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: colorScheme.onSurface.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          session.memberAccount,
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
                // Кнопка отмены (только для будущих сессий)
                if (canCancel) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showCancelConfirmation(
                          session, colorScheme),
                      icon: const Icon(FontAwesomeIcons.xmark, size: 14),
                      label: const Text('ОТМЕНИТЬ БРОНИРОВАНИЕ',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Показывает диалог подтверждения отмены
  void _showCancelConfirmation(
      _ParsedSession session, ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: const Text('Отмена бронирования'),
        content: Text(
          'Отменить бронь на ПК ${session.pcName}\n${_formatDate(session.from)} — ${_formatDate(session.to)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('НЕТ'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _cancelBooking(
                  session.bookingId, session.pcName, session.offerId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: const Text('ОТМЕНИТЬ'),
          ),
        ],
      ),
    );
  }
}

/// Внутренняя модель для хранения распарсенных данных сессии
class _ParsedSession {
  final String cafeId;
  final String cafeName;
  final String pcName;
  final String from;
  final String to;
  final int mins;
  final String description;
  final String bookingId;
  final String offerId;
  final String memberAccount;
  final String status;

  const _ParsedSession({
    required this.cafeId,
    required this.cafeName,
    required this.pcName,
    required this.from,
    required this.to,
    required this.mins,
    required this.description,
    required this.bookingId,
    required this.offerId,
    required this.memberAccount,
    required this.status,
  });
}
