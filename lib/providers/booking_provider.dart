import 'package:flutter/material.dart';

class BookingProvider extends ChangeNotifier {
  String? _selectedCafeId;
  String? _selectedCafeAddress;
  
  // Механизм для программного переключения вкладок
  int currentTabIndex = 0;

  String? get selectedCafeId => _selectedCafeId;
  String? get selectedCafeAddress => _selectedCafeAddress;

  // Метод, который вызовет кнопка "Забронировать" на вкладке Клубов
  void goToBookingTabWithCafe(String cafeId, String address) {
    _selectedCafeId = cafeId;
    _selectedCafeAddress = address;
    currentTabIndex = 2; // Индекс вкладки "Бронирование"
    notifyListeners();
  }

  // Просто смена вкладки
  void setTab(int index) {
    currentTabIndex = index;
    notifyListeners();
  }
}