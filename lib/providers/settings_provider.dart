import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeModeOption { system, light, dark }

class SettingsProvider extends ChangeNotifier {
  ThemeModeOption _themeMode = ThemeModeOption.dark;
  String _language = 'Русский';
  bool _notificationsEnabled = true;
  
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  
  SettingsProvider() {
    _loadSettings();
  }

  ThemeModeOption get themeMode => _themeMode;
  String get language => _language;
  bool get notificationsEnabled => _notificationsEnabled; // <--- ГЕТТЕР

  ThemeMode get flutterThemeMode {
    switch (_themeMode) {
      case ThemeModeOption.light: return ThemeMode.light;
      case ThemeModeOption.dark: return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }

  void setThemeMode(ThemeModeOption mode) {
    _themeMode = mode;
    _saveThemeMode(mode);
    notifyListeners();
  }

  void setLanguage(String lang) {
    _language = lang;
    _saveLanguage(lang);
    notifyListeners();
  }

  void toggleNotifications(bool value) {
    _notificationsEnabled = value;
    _saveBool('notifications_enabled', value);
    notifyListeners();
  }

  // --- ЗАГРУЗКА И СОХРАНЕНИЕ НАСТРОЕК ---
  
  Future<void> _loadSettings() async {
    try {
      final prefs = await _prefs;
      
      // Загрузка темы
      final themeIndex = prefs.getInt('theme_mode') ?? 2; // По умолчанию dark (2)
      _themeMode = ThemeModeOption.values[themeIndex.clamp(0, 2)];
      
      // Загрузка языка
      _language = prefs.getString('language') ?? 'Русский';
      
      // Загрузка настроек уведомлений
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      
      notifyListeners();
    } catch (e) {
      print('Ошибка загрузки настроек: $e');
    }
  }
  
  Future<void> _saveThemeMode(ThemeModeOption mode) async {
    try {
      final prefs = await _prefs;
      await prefs.setInt('theme_mode', mode.index);
    } catch (e) {
      print('Ошибка сохранения темы: $e');
    }
  }
  
  Future<void> _saveLanguage(String lang) async {
    try {
      final prefs = await _prefs;
      await prefs.setString('language', lang);
    } catch (e) {
      print('Ошибка сохранения языка: $e');
    }
  }
  
  Future<void> _saveBool(String key, bool value) async {
    try {
      final prefs = await _prefs;
      await prefs.setBool(key, value);
    } catch (e) {
      print('Ошибка сохранения $key: $e');
    }
  }

  // --- СИСТЕМА ПЕРЕВОДА (ЛОКАЛИЗАЦИЯ) ---
  final Map<String, Map<String, String>> _localizedValues = {
    'Русский': {
      'news': 'Новости',
      'clubs': 'Клубы',
      'booking': 'Бронирование',
      'chat': 'Чат-бот',
      'profile': 'Профиль',
      'settings': 'Настройки',
      'balance': 'БАЛАНС',
      'top_up': 'ПОПОЛНИТЬ',
      'history': 'История сессий',
      'logout': 'ВЫЙТИ',
      'session_hub': 'ВАШИ СЕССИИ',
      'pay': 'Оплатить',
      'select_date': 'ВЫБЕРИТЕ ДАТУ',
      'duration': 'ДЛИТЕЛЬНОСТЬ',
      'login_label': 'Логин',
      'pass_label': 'Пароль',
      'phone_label': 'Телефон',
      'login_btn': 'ВОЙТИ',
      'register_btn': 'РЕГИСТРАЦИЯ',
      'no_account': 'Нет аккаунта? Создать',
      'have_account': 'Есть аккаунт? Войти',
      'appearance': 'Внешний вид',
      'theme_title': 'Тема приложения',
      'lang_title': 'Язык',
      'notif_title': 'Push-уведомления',
      'notif_sub': 'Оповещения о бронировании',
    },
    'English': {
      'news': 'News',
      'clubs': 'Clubs',
      'booking': 'Booking',
      'chat': 'AI Chat',
      'profile': 'Profile',
      'settings': 'Settings',
      'balance': 'BALANCE',
      'top_up': 'TOP UP',
      'history': 'Sessions',
      'logout': 'LOGOUT',
      'session_hub': 'YOUR SESSIONS',
      'pay': 'Pay',
      'select_date': 'SELECT DATE',
      'duration': 'DURATION',
      'login_label': 'Login',
      'pass_label': 'Password',
      'phone_label': 'Phone',
      'login_btn': 'LOGIN',
      'register_btn': 'REGISTER',
      'no_account': 'No account? Sign up',
      'have_account': 'Have account? Login',
      'appearance': 'Appearance',
      'theme_title': 'App Theme',
      'lang_title': 'Language',
      'notif_title': 'Push Notifications',
      'notif_sub': 'Alerts for sessions',
    }
  };

  String getText(String key) {
    return _localizedValues[_language]?[key] ?? key;
  }
}