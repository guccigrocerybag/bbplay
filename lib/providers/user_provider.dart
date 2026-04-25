import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalBooking {
  final DateTime startTime;
  final DateTime endTime;
  LocalBooking(this.startTime, this.endTime);
}

class UserProvider extends ChangeNotifier {
  Map<String, dynamic>? _userData;
  final Map<String, List<LocalBooking>> _localBookings = {};

  // Список ПК, для которых мы ждем подтверждения отмены от сервера
  final List<String> _pendingSyncPcs = [];

  // ─── АВАТАРКА ─────────────────────────────────────────────
  String? _avatarPath; // null = нет аватарки, иначе путь к файлу

  Map<String, dynamic>? get userData => _userData;
  List<String> get pendingSyncPcs => _pendingSyncPcs;
  String? get avatarPath => _avatarPath;

  String get memberId => _userData?['member_id']?.toString() ?? "";
  String get account => _userData?['member_account'] ?? "Гость";
  String get balance => _userData?['member_balance']?.toString() ?? "0.00";

  UserProvider() {
    _loadAvatar();
  }

  /// Загружаем путь к аватару из SharedPreferences
  Future<void> _loadAvatar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _avatarPath = prefs.getString('avatar_path');
      notifyListeners();
    } catch (_) {}
  }

  /// Устанавливаем новый аватар (путь к файлу)
  Future<void> setAvatar(String? path) async {
    _avatarPath = path;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (path != null) {
        await prefs.setString('avatar_path', path);
      } else {
        await prefs.remove('avatar_path');
      }
    } catch (_) {}
    notifyListeners();
  }

  void setUser(Map<String, dynamic> data) {
    _userData = data;
    notifyListeners();
  }

  void updateBalance(double addedAmount) {
    if (_userData != null) {
      double currentBalance = double.tryParse(_userData!['member_balance'].toString()) ?? 0.0;
      _userData!['member_balance'] = (currentBalance + addedAmount).toStringAsFixed(2);
      notifyListeners(); 
    }
  }

  void addLocalBooking(String pcName, DateTime start, int durationMins) {
    _pendingSyncPcs.remove(pcName); // Если забронировали - удаляем из ожидания
    final end = start.add(Duration(minutes: durationMins));
    if (!_localBookings.containsKey(pcName)) _localBookings[pcName] = [];
    _localBookings[pcName]!.add(LocalBooking(start, end));
    notifyListeners();
  }

  // Когда мы отменили бронь в Истории:
  void cancelLocalBooking(String pcName) {
    _localBookings.remove(pcName);
    // Добавляем в список "ждем, пока сервер освободит"
    if (!_pendingSyncPcs.contains(pcName)) {
      _pendingSyncPcs.add(pcName);
    }
    notifyListeners();
  }

  // Метод вызывается, когда сервер НАКОНЕЦ-ТО прислал, что ПК свободен
  void confirmServerFreed(String pcName) {
    if (_pendingSyncPcs.contains(pcName)) {
      _pendingSyncPcs.remove(pcName);
      notifyListeners();
    }
  }

  bool isPcBookedLocally(String pcName, DateTime reqStart, int reqMins) {
    final reqEnd = reqStart.add(Duration(minutes: reqMins));
    final bookings = _localBookings[pcName] ?? [];
    for (var b in bookings) {
      if (reqStart.isBefore(b.endTime) && reqEnd.isAfter(b.startTime)) return true; 
    }
    return false; 
  }

  void logout() {
    _userData = null;
    _localBookings.clear();
    _pendingSyncPcs.clear();
    _avatarPath = null;
    notifyListeners();
  }
}
