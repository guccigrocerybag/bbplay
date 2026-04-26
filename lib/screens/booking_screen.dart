import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../core/utils/api_client.dart';
import '../core/services/notification_service.dart';
import '../providers/user_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/app_animations.dart';
import 'history_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  String? _selectedCafeId;
  List<dynamic> _cafesList = [];

  DateTime _selectedDate = DateTime.now();
  DateTime _focusedWeekStart = DateTime.now(); 
  TimeOfDay _selectedTime = TimeOfDay.now();
  final List<int> _durations = [30, 60, 120, 180, 240, 300];
  int _selectedMins = 60; 

  List<Map<String, dynamic>> _v2Packages = [];
  Map<String, dynamic>? _roomsData;
  Map<String, dynamic>? _availabilityData;
  bool _isLoading = true;
  Map<String, dynamic>? _selectedPc;
  final List<String> _locallyCanceledIds = [];

  /// Кешированные данные сессий для _buildSessionHub
  List<dynamic>? _cachedSessions;
  DateTime? _lastSessionFetch;

  @override
  void initState() {
    super.initState();
    _focusedWeekStart = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    // Округляем время до ближайших 10 минут
    int minutes = (_selectedTime.minute / 10).ceil() * 10;
    if (minutes >= 60) {
      _selectedTime = TimeOfDay(hour: (_selectedTime.hour + 1) % 24, minute: 0);
    } else {
      _selectedTime = TimeOfDay(hour: _selectedTime.hour, minute: minutes);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _initScreen());
  }

  // --- ЛОГИКА ЗАГРУЗКИ ---

  Future<void> _initScreen() async {
    setState(() => _isLoading = true);
    try {
      final cafesRes = await ApiClient.get('/cafes');
      _cafesList = cafesRes['data'];
      final bProv = Provider.of<BookingProvider>(context, listen: false);
      _selectedCafeId = bProv.selectedCafeId ?? (_cafesList.isNotEmpty ? _cafesList.first['icafe_id'].toString() : null);
      if (_selectedCafeId != null) await _fetchData();
    } catch (e) { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _fetchData() async {
    if (!mounted || _selectedCafeId == null) return;
    final user = Provider.of<UserProvider>(context, listen: false);
    setState(() { _isLoading = true; _selectedPc = null; });
    try {
      final dateStr = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
      final timeStr = "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}";

      final results = await Future.wait([
        ApiClient.get('/struct-rooms-icafe', params: {'cafeId': _selectedCafeId!}),
        ApiClient.getAvailablePcs(cafeId: _selectedCafeId!, date: dateStr, time: timeStr, mins: _selectedMins),
        ApiClient.getAllPrices(cafeId: _selectedCafeId!, memberId: user.memberId, date: dateStr),
      ]);
      
      if (mounted) {
        // Парсим цены из all-prices-icafe (results[2])
        final pricesData = results[2]['data']['prices'] as List? ?? [];
        List<Map<String, dynamic>> parsedPrices = [];
        for (var p in pricesData) {
          parsedPrices.add({
            'group': p['group_name'] ?? 'Default',
            'price': p['total_price'] ?? p['price_price1'],
            'duration': p['duration'],
            'price_per_half_hour': p['price_price1'], // цена за 30 мин (базовая)
          });
        }
        _v2Packages = parsedPrices;
        _roomsData = results[0]['data'];
        _availabilityData = results[1]['data'];
        _isLoading = false;
        
        final availPcs = results[1]['data']['pc_list'] as List? ?? [];
        for (var pc in availPcs) { if (pc['is_using'] == false) user.confirmServerFreed(pc['pc_name']); }
        setState(() {});
      }
    } catch (e) { if (mounted) setState(() => _isLoading = false); }
  }

  // --- ЛОГИКА БИЗНЕСА ---

  bool _isPcBusy(String pcName, UserProvider user) {
    if (user.pendingSyncPcs.contains(pcName)) return true;
    DateTime start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute);
    if (user.isPcBookedLocally(pcName, start, _selectedMins)) return true;
    if (_availabilityData == null) return false;
    final List pcs = _availabilityData!['pc_list'] as List? ?? [];
    for (var pc in pcs) {
      if (pc['pc_name'] == pcName) return pc['is_using'] == true;
    }
    return false;
  }

  /// Рассчитывает цену на основе данных с сервера (all-prices-icafe).
  /// Сервер сам применяет скидки по рангу пользователя (memberId).
  /// Если цена для данной зоны и длительности не найдена — использует хардкод как fallback.
  Map<String, int> _calculateSmartPrice(Map<String, dynamic> pc) {
    final zone = (pc['pc_group_name'] ?? pc['pc_area_name'] ?? 'Default').toString().toLowerCase();
    
    // Пытаемся найти цену с сервера для этой зоны и длительности
    try {
      final pkg = _v2Packages.firstWhere(
        (p) => p['duration'] == _selectedMins && p['group'].toString().toLowerCase().contains(zone),
      );
      final serverPrice = double.parse(pkg['price'].toString()).toInt();
      // base = цена почасовой оплаты (price_per_half_hour * кол-во получасов)
      final halfHourPrice = double.parse(pkg['price_per_half_hour'].toString());
      int base = (halfHourPrice * (_selectedMins / 30)).round();
      return {'base': base, 'final': serverPrice};
    } catch (_) {
      // Fallback: хардкод, если сервер не вернул цену
      int hr = zone.contains('bootcamp') ? 150 : (zone.contains('vip') ? 200 : 100);
      int base = (hr * (_selectedMins / 60)).round();
      return {'base': base, 'final': base};
    }
  }

  // --- ЗАГРУЗКА СЕССИЙ ДЛЯ HUB ---

  /// Загружает сессии для SessionHub (только активные/будущие, для текущего клуба)
  Future<List<dynamic>> _getActiveSessions(UserProvider user) async {
    // Кеш на 30 секунд
    if (_cachedSessions != null && _lastSessionFetch != null &&
        DateTime.now().difference(_lastSessionFetch!).inSeconds < 30) {
      return _cachedSessions!;
    }
    
    try {
      final response = await ApiClient.getBookingHistory(user.account);
      final raw = response['data'];
      List<dynamic> allSessions = [];
      if (raw is Map) {
        raw.forEach((cafeId, bookings) {
          if (bookings is List) {
            for (final booking in bookings) {
              if (booking is Map) {
                allSessions.add({
                  ...booking,
                  'cafe_id': cafeId.toString(),
                });
              }
            }
          }
        });
      } else if (raw is List) {
        allSessions.addAll(raw);
      }
      
      // Фильтруем: только для текущего клуба и не завершённые
      final now = DateTime.now();
      allSessions.removeWhere((s) {
        // Удаляем локально отменённые
        if (_locallyCanceledIds.contains(s['product_id'].toString())) return true;
        
        // Удаляем завершённые (end < now)
        final toStr = s['product_available_date_local_to']?.toString() ?? '';
        if (toStr.isNotEmpty) {
          try {
            final end = DateTime.parse(toStr.replaceAll(' ', 'T'));
            if (end.isBefore(now)) return true;
          } catch (_) {}
        }
        
        // Фильтруем по текущему клубу
        final cafeId = s['cafe_id']?.toString() ?? '';
        if (cafeId.isNotEmpty && cafeId != _selectedCafeId) return true;
        
        return false;
      });
      
      // Сортируем: сначала ближайшие
      allSessions.sort((a, b) {
        final aFrom = a['product_available_date_local_from']?.toString() ?? '';
        final bFrom = b['product_available_date_local_from']?.toString() ?? '';
        return aFrom.compareTo(bFrom);
      });
      
      // Берём максимум 5
      final limited = allSessions.take(5).toList();
      
      _cachedSessions = limited;
      _lastSessionFetch = DateTime.now();
      return limited;
    } catch (e) {
      return _cachedSessions ?? [];
    }
  }

  // --- UI КОМПОНЕНТЫ ---

  Widget _buildClubSelector() {
    if (_cafesList.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).colorScheme.outline)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCafeId, dropdownColor: Theme.of(context).colorScheme.surfaceVariant, isExpanded: true,
          items: _cafesList.map((cafe) => DropdownMenuItem<String>(value: cafe['icafe_id'].toString(), child: Text(cafe['address'], style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold, fontSize: 13)))).toList(),
          onChanged: (val) { if (val != null) { setState(() { _selectedCafeId = val; _selectedPc = null; _cachedSessions = null; }); _fetchData(); } },
        ),
      ),
    );
  }

  Widget _buildSessionHub(UserProvider user, SettingsProvider s) {
    return FutureBuilder<List<dynamic>>(
      future: _getActiveSessions(user),
      builder: (context, snapshot) {
        final sessions = snapshot.data ?? [];
        if (sessions.isEmpty) return const SizedBox.shrink();

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  s.getText('session_hub'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HistoryScreen(),
                      ),
                    );
                  },
                  child: Text(
                    s.getText('all_sessions'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final sess = sessions[index];
                
                // Определяем статус
                final fromStr = sess['product_available_date_local_from']?.toString() ?? '';
                final toStr = sess['product_available_date_local_to']?.toString() ?? '';
                final now = DateTime.now();
                
                String statusText;
                Color statusColor;
                bool canCancel;
                
                try {
                  final from = DateTime.parse(fromStr.replaceAll(' ', 'T'));
                  final to = DateTime.parse(toStr.replaceAll(' ', 'T'));
                  
                  if (now.isBefore(from)) {
                    statusText = s.getText('upcoming');
                    statusColor = Colors.green;
                    canCancel = true;
                  } else if (now.isAfter(to)) {
                    statusText = s.getText('expired');
                    statusColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.4);
                    canCancel = false;
                  } else {
                    statusText = s.getText('active_status');
                    statusColor = Colors.orange;
                    canCancel = false;
                  }
                } catch (_) {
                  statusText = s.getText('unknown_status');
                  statusColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.4);
                  canCancel = false;
                }
                
                // Форматируем дату
                String datePart = '';
                String timeStart = '';
                String timeEnd = '';
                try {
                  datePart = fromStr.split(' ')[0].substring(5); // MM-DD
                  timeStart = fromStr.split(' ')[1].substring(0, 5);
                  timeEnd = toStr.split(' ')[1].substring(0, 5);
                } catch (_) {}
                
                // Продолжительность
                String duration = '';
                final mins = sess['product_mins'];
                if (mins != null) {
                  final m = int.tryParse(mins.toString()) ?? 0;
                  if (m >= 60) {
                    duration = '${m ~/ 60}ч ${m % 60}мин';
                  } else {
                    duration = '${m}мин';
                  }
                }

                return Container(
                  width: 200,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: canCancel
                        ? Theme.of(context).colorScheme.surfaceVariant
                        : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: canCancel
                          ? Theme.of(context).colorScheme.outline
                          : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Верхняя строка: ПК + кнопка отмены
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'PC ${sess['product_pc_name']}',
                            style: TextStyle(
                              color: canCancel
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (canCancel)
                            GestureDetector(
                              onTap: () => _showCancelConfirmationDialog(
                                sess['product_id'].toString(),
                                sess['product_pc_name'],
                                sess['member_offer_id'].toString(),
                                user,
                              ),
                              child: const Icon(Icons.cancel, color: Colors.redAccent, size: 20),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Продолжительность
                      if (duration.isNotEmpty)
                        Text(
                          duration,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      const Spacer(),
                      // Статус
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Дата и время
                      Text(
                        '$datePart | $timeStart - $timeEnd',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ]);
      },
    );
  }

  Widget _buildCalendarRow(SettingsProvider s) {
    List<DateTime> weekDays = List.generate(7, (i) => _focusedWeekStart.add(Duration(days: i)));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(s.getText('select_date'), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold)),
        IconButton(icon: Icon(Icons.calendar_month, color: Theme.of(context).colorScheme.primary, size: 20), onPressed: () async {
          DateTime? d = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now(), lastDate: DateTime(2027));
          if (d != null) { setState(() { _selectedDate = d; _focusedWeekStart = d; }); _fetchData(); }
        })
      ])),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Row(children: [
        IconButton(icon: Icon(Icons.chevron_left, color: Theme.of(context).colorScheme.onSurface, size: 20), onPressed: () => setState(() => _focusedWeekStart = _focusedWeekStart.subtract(const Duration(days: 7)))),
        for (var d in weekDays) Expanded(child: GestureDetector(
          onTap: () { setState(() => _selectedDate = d); _fetchData(); },
          child: Container(height: 60, margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(color: (_selectedDate.day == d.day && _selectedDate.month == d.month) ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(10)),
            child: Center(child: FittedBox(child: Text(d.day.toString(), style: TextStyle(color: (_selectedDate.day == d.day) ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18)))),),
        )),
        IconButton(icon: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface, size: 20), onPressed: () => setState(() => _focusedWeekStart = _focusedWeekStart.add(const Duration(days: 7)))),
      ]))
    ]);
  }

  Widget _buildTimeAndDuration(SettingsProvider s) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(s.getText('duration'), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Row(children: [
        GestureDetector(onTap: _showCustomTimePicker, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).colorScheme.outline)), child: Text(_selectedTime.format(context), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)))),
        const SizedBox(width: 8),
        for (var m in _durations) Expanded(child: GestureDetector(
          onTap: () { setState(() => _selectedMins = m); _fetchData(); },
          child: Container(height: 50, margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(color: _selectedMins == m ? Theme.of(context).colorScheme.primary.withOpacity(0.2) : Colors.transparent, border: Border.all(color: _selectedMins == m ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline), borderRadius: BorderRadius.circular(10)),
            child: Center(child: FittedBox(child: Text('${m < 60 ? m : m ~/ 60}${m < 60 ? 'm' : 'h'}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)))),),
        )),
      ]),
    ]));
  }

  Widget _buildStaticMap(List rooms, UserProvider user) {
    return LayoutBuilder(builder: (context, constraints) {
      double pcSize = constraints.maxWidth / 11;
      if (pcSize > 42) pcSize = 42; if (pcSize < 34) pcSize = 34;
      return Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: rooms.map((room) {
        String name = room['area_name'].toString(); bool isGZ = name.toLowerCase().contains('gamezone');
        Color c = isGZ ? Colors.green : (name.toLowerCase().contains('bootcamp') ? Colors.pinkAccent : Colors.purpleAccent);
        return Expanded(flex: isGZ ? 2 : 1, child: Column(children: [
          FittedBox(child: Text(name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.bold))),
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.all(6), margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(border: Border.all(color: c, width: 2), borderRadius: BorderRadius.circular(12)),
            child: Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: (room['pcs_list'] as List).map((pc) {
              bool busy = _isPcBusy(pc['pc_name'], user); bool sel = _selectedPc?['pc_name'] == pc['pc_name'];
              return GestureDetector(onTap: busy ? null : () => setState(() => _selectedPc = sel ? null : pc),
                child: Container(width: pcSize, height: pcSize, decoration: BoxDecoration(color: sel ? Theme.of(context).colorScheme.primary : (busy ? Theme.of(context).colorScheme.surfaceVariant : Theme.of(context).colorScheme.outline), borderRadius: BorderRadius.circular(8)),
                  child: Center(child: FittedBox(child: Padding(padding: const EdgeInsets.all(4.0), child: Text(pc['pc_name'].toString().replaceAll('PC', ''), style: TextStyle(color: sel ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold))))),
                ),
              );
            }).toList()),
          ),
        ]));
      }).toList()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);
    final s = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(s.getText('booking'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(Icons.fastfood, color: Theme.of(context).colorScheme.primary),
            onPressed: () => _showFoodMenu(s),
          ),
          IconButton(
            icon: Icon(Icons.sync, color: Theme.of(context).colorScheme.primary),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: Column(children: [
        _buildClubSelector(),
        Expanded(child: SingleChildScrollView(physics: const BouncingScrollPhysics(), child: Column(children: [
          _buildSessionHub(user, s),
          _buildCalendarRow(s),
          const SizedBox(height: 16),
          _buildTimeAndDuration(s),
          const SizedBox(height: 32),
          if (_isLoading)
            const Center(
              child: GamingSpinner(size: 80),
            )
          else if (_roomsData != null) _buildStaticMap(_roomsData!['rooms'], user),
          const SizedBox(height: 40),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [ _legendItem(Theme.of(context).colorScheme.outline, s.getText('pc_free')), _legendItem(Theme.of(context).colorScheme.surfaceVariant, s.getText('pc_occupied')), _legendItem(Theme.of(context).colorScheme.primary, s.getText('pc_selected')) ]),
          const SizedBox(height: 40),
        ]))),
      ]),
      bottomNavigationBar: _selectedPc != null ? _buildBottomBar(s) : null,
    );
  }

  Widget _buildBottomBar(SettingsProvider s) {
    final p = _calculateSmartPrice(_selectedPc!);
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: SafeArea(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 16)),
        onPressed: _handleBooking, child: Text('${s.getText('pay')} ${p['final']}.00 rub', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
      )),
    );
  }

  Future<void> _handleBooking() async {
    final user = Provider.of<UserProvider>(context, listen: false);
    final s = Provider.of<SettingsProvider>(context, listen: false);
    final p = _calculateSmartPrice(_selectedPc!);
    
    print('🎯 [BOOKING] Начало бронирования:');
    print('🎯 [BOOKING] ПК: ${_selectedPc!['pc_name']}');
    print('🎯 [BOOKING] Аккаунт: ${user.account}');
    print('🎯 [BOOKING] Member ID: ${user.memberId}');
    print('🎯 [BOOKING] Баланс: ${user.balance}, цена: ${p['final']}');
    
    if (double.parse(user.balance) < p['final']!) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.getText('insufficient_balance'))));
      return;
    }
    
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: GamingSpinner(size: 100),
        ),
      );
      
      final bookingData = {
        "icafe_id": _selectedCafeId!,
        "pc_name": _selectedPc!['pc_name'],
        "member_account": user.account,
        "member_id": user.memberId,
        "start_date": "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}",
        "start_time": "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}",
        "mins": _selectedMins.toString(),
        ...ApiClient.generateBookingKeys(_selectedCafeId!, _selectedPc!['pc_name'], user.memberId),
      };
      
      print('🎯 [BOOKING] Данные для бронирования: $bookingData');
      
      final response = await ApiClient.post('/booking', bookingData);
      print('✅ [BOOKING] Ответ сервера на бронирование: $response');
      
      // Проверяем ответ сервера
      // Приоритет 1: iCafe_response — если там "success", это 100% успех
      final iCafeMsg = response['iCafe_response']?['message']?.toString().toLowerCase() ?? '';
      if (iCafeMsg.contains('success')) {
        print('✅ [BOOKING] Успешное бронирование (iCafe_response)!');
        Navigator.pop(context);
        
        // Обновляем локальное состояние
        user.addLocalBooking(_selectedPc!['pc_name'], DateTime.now(), _selectedMins);
        user.updateBalance(-(p['final']!.toDouble()));
        
        // Планируем уведомления о сессии
        final startTime = DateTime(
          _selectedDate.year, _selectedDate.month, _selectedDate.day,
          _selectedTime.hour, _selectedTime.minute,
        );
        final endTime = startTime.add(Duration(minutes: _selectedMins));
        final bookingId = '${_selectedCafeId}_${_selectedPc!['pc_name']}_${startTime.millisecondsSinceEpoch}';
        NotificationService().scheduleSessionNotifications(
          bookingId: bookingId,
          pcName: _selectedPc!['pc_name'],
          startTime: startTime,
          endTime: endTime,
        );
        
        // Показываем анимацию успеха
        _showSuccessAnimation();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.getText('booking_success')),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // Приоритет 2: проверяем code и message
        final code = response['code'];
        final codeOk = code == 0 || code == '0' || code == 200 || code == '200';
        final message = response['message']?.toString().toLowerCase() ?? '';
        
        // Успех: code ок И сообщение содержит "success" (не "fail"!)
        final isSuccess = codeOk && (message.contains('success') || message.contains('succes'));
        // Явная ошибка: сообщение содержит слова-маркеры ошибки
        final isExplicitError = message.contains('incorrect') || 
                                message.contains('error') || 
                                message.contains('ошибк') ||
                                message.contains('not allowed') ||
                                message.contains('failed') ||  // только "failed", не "fail"
                                message.contains('denied') ||
                                message.contains('occupied');
        
        if (isSuccess && !isExplicitError) {
          print('✅ [BOOKING] Успешное бронирование!');
          Navigator.pop(context);
          
          // Обновляем локальное состояние
          user.addLocalBooking(_selectedPc!['pc_name'], DateTime.now(), _selectedMins);
          user.updateBalance(-(p['final']!.toDouble()));
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(s.getText('booking_success')),
              backgroundColor: Theme.of(context).colorScheme.primary,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          // Сервер вернул ошибку
          Navigator.pop(context);
          final errorMsg = response['message'] ?? s.getText('unknown_error');
          print('❌ [BOOKING] Ошибка бронирования от сервера: $errorMsg');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${s.getText('booking_error')} $errorMsg'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 5),
            ),
          );
          return;
        }
      }
      
      // Сбрасываем выбранный ПК
      setState(() {
        _selectedPc = null;
      });
      
      // Обновляем данные (доступность ПК)
      _fetchData();
      
      // Ждем немного и показываем сообщение о проверке истории
      await Future.delayed(const Duration(seconds: 2));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.getText('check_history')),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          duration: const Duration(seconds: 4),
        ),
      );
      
    } catch (e) {
      if (mounted) Navigator.pop(context);
      print('❌ [BOOKING] Ошибка бронирования: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${s.getText('error_prefix')} ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// Показывает диалог подтверждения отмены бронирования
  void _showCancelConfirmationDialog(
    String bookingId,
    String pcName,
    String offerId,
    UserProvider user,
  ) {
    final s = Provider.of<SettingsProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(s.getText('cancel_booking')),
        content: Text('${s.getText('cancel_confirm')} $pcName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.getText('no')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiClient.cancelBooking(
                  _selectedCafeId!,
                  bookingId,
                  pcName,
                  offerId,
                );
                // Отменяем запланированные уведомления
                NotificationService().cancelSessionNotifications(bookingId);
                setState(() {
                  _locallyCanceledIds.add(bookingId);
                  _cachedSessions = null;
                });
                user.cancelLocalBooking(pcName);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(s.getText('booking_cancelled')),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${s.getText('error_prefix')} $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(s.getText('cancel_btn')),
          ),
        ],
      ),
    );
  }

  Future<void> _showCustomTimePicker() async {
    final now = DateTime.now();
    bool isToday = _selectedDate.day == now.day && _selectedDate.month == now.month && _selectedDate.year == now.year;
    List<TimeOfDay> tms = [];
    for (int h = 0; h < 24; h++) { for (int m = 0; m < 60; m += 10) {
      if (isToday && (h < now.hour || (h == now.hour && m < now.minute))) continue;
      tms.add(TimeOfDay(hour: h, minute: m));
    }}
    int si = 0;
    await showModalBottomSheet(context: context, backgroundColor: Theme.of(context).colorScheme.surfaceVariant, builder: (c) => SizedBox(height: 250, child: CupertinoPicker(itemExtent: 40, onSelectedItemChanged: (i) => si = i, children: tms.map((t) => Center(child: Text(t.format(context), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)))).toList())));
    setState(() => _selectedTime = tms[si]); _fetchData();
  }

  Widget _legendItem(Color c, String t) => Row(children: [Container(width: 8, height: 8, color: c, margin: const EdgeInsets.only(right: 4)), Text(t, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11))]);

  /// Показывает BottomSheet с меню доставки еды
  void _showFoodMenu(SettingsProvider s) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Демо-меню
    final foodItems = [
      {'name': s.getText('food_pizza'), 'price': 350, 'emoji': '🍕'},
      {'name': s.getText('food_cola'), 'price': 100, 'emoji': '🥤'},
      {'name': s.getText('food_fries'), 'price': 150, 'emoji': '🍟'},
      {'name': s.getText('food_hotdog'), 'price': 200, 'emoji': '🌭'},
      {'name': s.getText('food_snacks'), 'price': 120, 'emoji': '🥜'},
    ];
    
    Map<int, int> quantities = {for (int i = 0; i < foodItems.length; i++) i: 0};
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            int total = 0;
            for (int i = 0; i < foodItems.length; i++) {
              final price = foodItems[i]['price'] as int;
              total += price * quantities[i]!;
            }
            
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s.getText('food_menu'),
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Список товаров
                  ...List.generate(foodItems.length, (i) {
                    final item = foodItems[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Text(item['emoji'] as String, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'] as String,
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${item['price']} ₽',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Счётчик количества
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (quantities[i]! > 0) {
                                    setSheetState(() => quantities[i] = quantities[i]! - 1);
                                  }
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: colorScheme.outline),
                                  ),
                                  child: Center(
                                    child: Icon(Icons.remove, size: 16, color: colorScheme.onSurface),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 36,
                                child: Center(
                                  child: Text(
                                    '${quantities[i]}',
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setSheetState(() => quantities[i] = quantities[i]! + 1),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Icon(Icons.add, size: 16, color: colorScheme.onPrimary),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  // Итого и кнопка заказа
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${s.getText('food_total')}: $total ₽',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: total > 0 ? colorScheme.primary : colorScheme.surface,
                          foregroundColor: total > 0 ? colorScheme.onPrimary : colorScheme.onSurface.withValues(alpha: 0.5),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: total > 0
                            ? () {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(s.getText('food_ordered')),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            : null,
                        child: Text(
                          s.getText('food_order'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Показывает анимацию успешного бронирования
  void _showSuccessAnimation() {
    final s = Provider.of<SettingsProvider>(context, listen: false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        Future.delayed(const Duration(seconds: 3), () {
          if (ctx.mounted) Navigator.pop(ctx);
        });
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          content: SuccessAnimation(
            size: 150,
            message: s.getText('booking_success'),
          ),
        );
      },
    );
  }
}
