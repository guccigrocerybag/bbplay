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
  bool get notificationsEnabled => _notificationsEnabled;

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
      final themeIndex = prefs.getInt('theme_mode') ?? 2;
      _themeMode = ThemeModeOption.values[themeIndex.clamp(0, 2)];
      _language = prefs.getString('language') ?? 'Русский';
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

  // ============================================================
  // ПОЛНАЯ СИСТЕМА ЛОКАЛИЗАЦИИ (Русский / English)
  // ============================================================
  final Map<String, Map<String, String>> _localizedValues = {
    'Русский': {
      // ─── Навигация ─────────────────────────────────────────
      'news': 'Новости',
      'clubs': 'Клубы',
      'booking': 'Бронирование',
      'chat': 'Чат-бот',
      'profile': 'Профиль',
      'settings': 'Настройки',

      // ─── Профиль ───────────────────────────────────────────
      'gamer_profile': 'Профиль игрока',
      'rank_progress': 'ПРОГРЕСС РАНГА',
      'available_balance': 'ДОСТУПНЫЙ БАЛАНС',
      'top_up_balance': 'ПОПОЛНИТЬ БАЛАНС',
      'booking_history': 'История бронирований',
      'invite_friends': 'Пригласить друзей',
      'log_out': 'Выйти',
      'deposit_funds': 'Пополнение счета',
      'top_up': 'ПОПОЛНИТЬ',
      'cancel': 'Отмена',
      'enter_amount': 'Введите сумму больше 0',
      'demo_topup': 'Демо-пополнение выполнено!',
      'invite_title': 'Пригласить друзей',
      'invite_text': 'Поделись своим реферальным кодом с друзьями и получай бонусы!',
      'logout_title': 'Выход',
      'logout_confirm': 'Вы уверены, что хотите выйти?',
      'logout_btn': 'ВЫЙТИ',
      'change_avatar': 'Сменить аватар',
      'avatar_camera': 'Сделать фото',
      'avatar_gallery': 'Выбрать из галереи',
      'avatar_remove': 'Удалить аватар',

      // ─── Баланс ────────────────────────────────────────────
      'balance': 'БАЛАНС',
      'session_hub': 'ВАШИ СЕССИИ',
      'pay': 'Оплатить',

      // ─── Бронирование ──────────────────────────────────────
      'select_date': 'ВЫБЕРИТЕ ДАТУ',
      'duration': 'ДЛИТЕЛЬНОСТЬ',
      'select_pc': 'ВЫБЕРИТЕ ПК',
      'book_now': 'Забронировать',
      'book_success': 'Бронь подтверждена!',
      'book_error': 'Ошибка бронирования',
      'pc_occupied': 'ПК занят',
      'pc_free': 'Свободен',
      'pc_selected': 'Выбран',
      'loading_pcs': 'Загрузка ПК...',
      'no_pcs': 'Нет свободных ПК',
      'select_time': 'Выберите время',

      // ─── История ───────────────────────────────────────────
      'history_title': 'История сессий',
      'history_all': 'Все',
      'history_active': 'Активные',
      'history_completed': 'Завершённые',
      'no_history': 'У вас пока нет сессий',
      'no_history_sub': 'Забронируйте ПК и начните игру!',
      'session_cancelled': 'Отменена',
      'session_completed': 'Завершена',
      'session_active': 'Активна',
      'cancel_booking': 'Отменить бронь',
      'cancel_confirm': 'Вы уверены?',
      'cancel_yes': 'Да, отменить',
      'cancel_no': 'Нет',

      // ─── Авторизация ───────────────────────────────────────
      'login_label': 'Логин',
      'pass_label': 'Пароль',
      'phone_label': 'Телефон',
      'login_btn': 'ВОЙТИ',
      'register_btn': 'РЕГИСТРАЦИЯ',
      'no_account': 'Нет аккаунта? Создать',
      'have_account': 'Есть аккаунт? Войти',
      'auth_error': 'Ошибка входа',
      'reg_error': 'Ошибка регистрации',
      'enter_credentials': 'Введите логин и пароль',
      'sms_confirm_title': 'Подтверждение',
      'sms_confirm_body': 'Мы отправили код на ваш номер. Введите его ниже:',
      'sms_confirm_btn': 'ПОДТВЕРДИТЬ',
      'sms_cancel_btn': 'ОТМЕНА',
      'auth_title': 'Вход в аккаунт',
      'reg_title': 'Создание аккаунта',
      'phone_hint': 'Телефон (Например, 79991234567)',
      'password_requirements': 'Пароль должен содержать минимум 8 символов, хотя бы одну ЗАГЛАВНУЮ букву, одну строчную и одну цифру.',
      'login_btn_text': 'ВОЙТИ',
      'register_btn_text': 'ЗАРЕГИСТРИРОВАТЬСЯ',
      'password_too_simple': 'Пароль слишком простой! Проверьте требования.',

      // ─── Чат-бот ───────────────────────────────────────────
      'chat_title': 'AI Поддержка',
      'chat_hint': 'Ваш вопрос...',
      'chat_typing': 'Бот печатает...',
      // Ответы бота
      'bot_greeting': 'Привет! 👋\n\nЯ помощник компьютерного клуба BBplay. Могу рассказать про:\n💰 Цены и тарифы\n📍 Адреса клубов\n🖥️ Наше железо\n📋 Правила клуба\n🕐 Время работы\n\nЧто тебя интересует?',
      'bot_prices': '💰 Наши тарифы:\n\n🎮 GameZone — 100 ₽/час\n🚀 BootCamp — 150 ₽/час\n👑 VIP — 200 ₽/час\n\n💡 Пакеты выгоднее! Например, 5 часов VIP за 222 ₽.\n\nЗабронировать ПК можно на экране "Бронирование" в приложении.',
      'bot_address': '📍 Точные адреса всех клубов смотри на экране "Наши клубы" в приложении.\n\nТам же можно построить маршрут через Яндекс.Карты!',
      'bot_hardware': '🖥️ Наше железо:\n\n🎮 Видеокарты: RTX 4060 / RTX 3060\n🖥️ Мониторы: 240Hz / 165Hz\n🖱️ Мышки: Logitech G Pro\n⌨️ Клавиатуры: Dark Project (механика)\n\nВсё топовое для максимального FPS! 🔥',
      'bot_rules': '📋 Правила клуба BBplay:\n\n✅ Можно:\n- Приносить свою периферию\n- Заказывать еду\n\n❌ Нельзя:\n- Приносить алкоголь\n- Курить (в т.ч. вейпы)\n\n🔞 Ночью (после 22:00) вход строго 18+ и по паспорту.',
      'bot_hours': '🕐 Мы работаем 24/7 без выходных!\n\nПриходи в любое время — всегда рады гостям 🎮',
      'bot_booking': '🎮 Забронировать ПК можно прямо в приложении!\n\nПерейди на экран "Бронирование" и выбери свободное место.',
      'bot_fallback': 'Извини, я не совсем понял вопрос 😅\n\nЯ могу рассказать про:\n💰 Цены и тарифы\n📍 Адреса клубов\n🖥️ Наше железо\n📋 Правила клуба\n🕐 Время работы\n\nИли просто напиши по-другому!',
      'bot_welcome': 'Привет! Я виртуальный помощник BBplay 🐻\n\nМогу рассказать про наши цены, адреса клубов, мощное железо или правила. Просто напиши свой вопрос!',

      // ─── Настройки ─────────────────────────────────────────
      'appearance': 'Внешний вид',
      'theme_title': 'Тема приложения',
      'lang_title': 'Язык',
      'notif_title': 'Push-уведомления',
      'notif_sub': 'Оповещения о бронировании',
      'theme_system': 'Системная',
      'theme_light': 'Светлая',
      'theme_dark': 'Тёмная',

      // ─── Онбординг ─────────────────────────────────────────
      'onb_1_title': 'Добро пожаловать в BBplay!',
      'onb_1_sub': 'Сеть компьютерных клубов для настоящих геймеров',
      'onb_2_title': 'Бронируй ПК',
      'onb_2_sub': 'Выбирай свободное место и бронируй в один клик',
      'onb_3_title': 'Следи за балансом',
      'onb_3_sub': 'Пополняй счет и следи за историей сессий',
      'onb_start': 'НАЧАТЬ',
      'onb_next': 'ДАЛЕЕ',
      'onb_skip': 'ПРОПУСТИТЬ',

      // ─── Сплэш ─────────────────────────────────────────────
      'splash_loading': 'Загрузка...',

      // ─── Клубы ─────────────────────────────────────────────
      'clubs_title': 'Наши клубы',
      'clubs_loading': 'Загрузка клубов...',
      'clubs_error': 'Не удалось загрузить клубы',
      'clubs_empty': 'Клубы не найдены',
      'route': 'Маршрут',
      'telegram': 'Telegram',
      'map_error': 'Не удалось открыть карту',
      'call_error': 'Не удалось совершить звонок',
      'telegram_error': 'Не удалось открыть Telegram',

      // ─── Бронирование (дополнительные) ─────────────────────
      'all_sessions': 'Все сессии →',
      'upcoming': 'UPCOMING',
      'active_status': 'ACTIVE',
      'expired': 'EXPIRED',
      'unknown_status': 'UNKNOWN',
      'insufficient_balance': 'Недостаточно средств!',
      'booking_created': 'Бронирование успешно создано!',
      'booking_cancelled': 'Бронирование отменено',
      'cancel_title': 'Отмена бронирования',
      'cancel_confirm_text': 'Вы уверены, что хотите отменить бронь на ПК',
      'cancel_yes_btn': 'ОТМЕНИТЬ',
      'cancel_no_btn': 'НЕТ',
      'check_history': 'Проверьте историю бронирований для подтверждения',
      'error_prefix': 'Ошибка:',
      'booking_error_prefix': 'Ошибка бронирования:',
      'booking_success_animation': 'Бронирование успешно!',
      'booking_success': 'Бронирование успешно!',
      'booking_error': 'Ошибка бронирования:',
      'unknown_error': 'Неизвестная ошибка',
      'no': 'НЕТ',
      'cancel_btn': 'ОТМЕНИТЬ',

      // ─── Новости ───────────────────────────────────────────
      'news_title': 'НОВОСТИ',
      'news_loading': 'Загрузка новостей...',
      'news_error': 'Не удалось загрузить новости',
      'news_empty': 'Новостей пока нет',
      'watch_video': 'СМОТРЕТЬ ВИДЕО',
      'read_more': 'ЧИТАТЬ ДАЛЕЕ',

      // ─── Профиль (дополнительные) ──────────────────────────
      'photo_error': 'Ошибка выбора фото:',
      'ok': 'OK',
      'rub_100': '100 ₽',
      'rub_500': '500 ₽',
      'rub_1000': '1000 ₽',

      // ─── Турниры ──────────────────────────────────────────
      'tournaments': 'Турниры',
      'tournaments_title': 'ТУРНИРЫ',
      'tournaments_prize': 'Призовой фонд',
      'tournaments_date': 'Дата',
      'tournaments_game': 'Игра',
      'tournaments_format': 'Формат',
      'tournaments_register': 'ЗАПИСАТЬСЯ',
      'tournaments_registered': 'Вы записаны на турнир!',
      'tournaments_all': 'Все',
      'tournaments_upcoming': 'Предстоящие',
      'tournaments_past': 'Завершённые',
      'tournaments_status': 'Статус',
      'tournaments_status_upcoming': 'Предстоящий',
      'tournaments_status_ongoing': 'Идёт',
      'tournaments_status_completed': 'Завершён',
      'tournaments_club': 'Клуб',
      'tournaments_no_tournaments': 'Турниров пока нет',

      // ─── Доставка еды ─────────────────────────────────────
      'order_food': '🍕 Заказать еду',
      'food_menu': 'Меню доставки',
      'food_order': 'ЗАКАЗАТЬ',
      'food_ordered': '✅ Заказ доставят к вашему ПК через 15 минут!',
      'food_quantity': 'Кол-во',
      'food_total': 'Итого',
      'food_close': 'Закрыть',
      'food_pizza': 'Пицца "Маргарита"',
      'food_cola': 'Cola 0.5L',
      'food_fries': 'Картошка фри',
      'food_hotdog': 'Хот-дог',
      'food_snacks': 'Снеки (чипсы)',
      'food_pizza_price': '350 ₽',
      'food_cola_price': '100 ₽',
      'food_fries_price': '150 ₽',
      'food_hotdog_price': '200 ₽',
      'food_snacks_price': '120 ₽',

      // ─── Оффлайн ──────────────────────────────────────────
      'offline_mode': 'Нет подключения к интернету. Показываются кешированные данные.',
    },

    'English': {
      // ─── Navigation ────────────────────────────────────────
      'news': 'News',
      'clubs': 'Clubs',
      'booking': 'Booking',
      'chat': 'AI Chat',
      'profile': 'Profile',
      'settings': 'Settings',

      // ─── Profile ───────────────────────────────────────────
      'gamer_profile': 'Gamer Profile',
      'rank_progress': 'RANK PROGRESS',
      'available_balance': 'AVAILABLE BALANCE',
      'top_up_balance': 'TOP UP BALANCE',
      'booking_history': 'Booking History',
      'invite_friends': 'Invite Friends',
      'log_out': 'Log Out',
      'deposit_funds': 'Deposit Funds',
      'top_up': 'TOP UP',
      'cancel': 'Cancel',
      'enter_amount': 'Enter an amount greater than 0',
      'demo_topup': 'Demo top-up successful!',
      'invite_title': 'Invite Friends',
      'invite_text': 'Share your referral code with friends and get bonuses!',
      'logout_title': 'Log Out',
      'logout_confirm': 'Are you sure you want to log out?',
      'logout_btn': 'LOGOUT',
      'change_avatar': 'Change Avatar',
      'avatar_camera': 'Take Photo',
      'avatar_gallery': 'Choose from Gallery',
      'avatar_remove': 'Remove Avatar',

      // ─── Balance ───────────────────────────────────────────
      'balance': 'BALANCE',
      'session_hub': 'YOUR SESSIONS',
      'pay': 'Pay',

      // ─── Booking ───────────────────────────────────────────
      'select_date': 'SELECT DATE',
      'duration': 'DURATION',
      'select_pc': 'SELECT PC',
      'book_now': 'BOOK NOW',
      'book_success': 'Booking confirmed!',
      'book_error': 'Booking error',
      'pc_occupied': 'Occupied',
      'pc_free': 'Free',
      'pc_selected': 'Selected',
      'loading_pcs': 'Loading PCs...',
      'no_pcs': 'No free PCs',
      'select_time': 'Select time',

      // ─── History ───────────────────────────────────────────
      'history_title': 'Session History',
      'history_all': 'All',
      'history_active': 'Active',
      'history_completed': 'Completed',
      'no_history': 'No sessions yet',
      'no_history_sub': 'Book a PC and start playing!',
      'session_cancelled': 'Cancelled',
      'session_completed': 'Completed',
      'session_active': 'Active',
      'cancel_booking': 'Cancel Booking',
      'cancel_confirm': 'Are you sure?',
      'cancel_yes': 'Yes, cancel',
      'cancel_no': 'No',

      // ─── Auth ──────────────────────────────────────────────
      'login_label': 'Login',
      'pass_label': 'Password',
      'phone_label': 'Phone',
      'login_btn': 'LOGIN',
      'register_btn': 'REGISTER',
      'no_account': 'No account? Sign up',
      'have_account': 'Have account? Login',
      'auth_error': 'Login error',
      'reg_error': 'Registration error',
      'enter_credentials': 'Enter login and password',
      'sms_confirm_title': 'Confirmation',
      'sms_confirm_body': 'We sent a code to your number. Enter it below:',
      'sms_confirm_btn': 'CONFIRM',
      'sms_cancel_btn': 'CANCEL',
      'auth_title': 'Login',
      'reg_title': 'Create Account',
      'phone_hint': 'Phone (e.g., 79991234567)',
      'password_requirements': 'Password must be at least 8 characters, with at least one uppercase letter, one lowercase letter, and one digit.',
      'login_btn_text': 'LOGIN',
      'register_btn_text': 'REGISTER',
      'password_too_simple': 'Password is too simple! Check the requirements.',

      // ─── Chat bot ──────────────────────────────────────────
      'chat_title': 'AI Support',
      'chat_hint': 'Your question...',
      'chat_typing': 'Bot is typing...',
      // Bot responses
      'bot_greeting': 'Hi! 👋\n\nI am the BBplay computer club assistant. I can tell you about:\n💰 Prices and rates\n📍 Club addresses\n🖥️ Our hardware\n📋 Club rules\n🕐 Working hours\n\nWhat are you interested in?',
      'bot_prices': '💰 Our rates:\n\n🎮 GameZone — 100 ₽/hour\n🚀 BootCamp — 150 ₽/hour\n👑 VIP — 200 ₽/hour\n\n💡 Packages are cheaper! For example, 5 hours VIP for 222 ₽.\n\nBook a PC on the "Booking" screen in the app.',
      'bot_address': '📍 Check exact addresses of all clubs on the "Clubs" screen in the app.\n\nYou can also build a route via Yandex Maps!',
      'bot_hardware': '🖥️ Our hardware:\n\n🎮 GPUs: RTX 4060 / RTX 3060\n🖥️ Monitors: 240Hz / 165Hz\n🖱️ Mice: Logitech G Pro\n⌨️ Keyboards: Dark Project (mechanical)\n\nAll top-tier for maximum FPS! 🔥',
      'bot_rules': '📋 BBplay club rules:\n\n✅ You can:\n- Bring your own peripherals\n- Order food\n\n❌ You cannot:\n- Bring alcohol\n- Smoke (including vapes)\n\n🔞 At night (after 10 PM) entry is strictly 18+ with ID.',
      'bot_hours': '🕐 We are open 24/7!\n\nCome anytime — we are always happy to see you 🎮',
      'bot_booking': '🎮 You can book a PC right in the app!\n\nGo to the "Booking" screen and choose a free spot.',
      'bot_fallback': 'Sorry, I didn\'t quite understand your question 😅\n\nI can tell you about:\n💰 Prices and rates\n📍 Club addresses\n🖥️ Our hardware\n📋 Club rules\n🕐 Working hours\n\nOr just ask in a different way!',
      'bot_welcome': 'Hi! I am the BBplay virtual assistant 🐻\n\nI can tell you about our prices, club addresses, powerful hardware, or rules. Just ask your question!',

      // ─── Settings ──────────────────────────────────────────
      'appearance': 'Appearance',
      'theme_title': 'App Theme',
      'lang_title': 'Language',
      'notif_title': 'Push Notifications',
      'notif_sub': 'Alerts for sessions',
      'theme_system': 'System',
      'theme_light': 'Light',
      'theme_dark': 'Dark',

      // ─── Onboarding ────────────────────────────────────────
      'onb_1_title': 'Welcome to BBplay!',
      'onb_1_sub': 'A network of computer clubs for real gamers',
      'onb_2_title': 'Book a PC',
      'onb_2_sub': 'Choose a free spot and book in one click',
      'onb_3_title': 'Track your balance',
      'onb_3_sub': 'Top up your account and track session history',
      'onb_start': 'START',
      'onb_next': 'NEXT',
      'onb_skip': 'SKIP',

      // ─── Splash ────────────────────────────────────────────
      'splash_loading': 'Loading...',

      // ─── Clubs ─────────────────────────────────────────────
      'clubs_title': 'Our Clubs',
      'clubs_loading': 'Loading clubs...',
      'clubs_error': 'Failed to load clubs',
      'clubs_empty': 'No clubs found',
      'route': 'Route',
      'telegram': 'Telegram',
      'map_error': 'Failed to open map',
      'call_error': 'Failed to make a call',
      'telegram_error': 'Failed to open Telegram',

      // ─── Booking (additional) ──────────────────────────────
      'all_sessions': 'All sessions →',
      'upcoming': 'UPCOMING',
      'active_status': 'ACTIVE',
      'expired': 'EXPIRED',
      'unknown_status': 'UNKNOWN',
      'insufficient_balance': 'Insufficient balance!',
      'booking_created': 'Booking created successfully!',
      'booking_cancelled': 'Booking cancelled',
      'cancel_title': 'Cancel Booking',
      'cancel_confirm_text': 'Are you sure you want to cancel booking for PC',
      'cancel_yes_btn': 'CANCEL',
      'cancel_no_btn': 'NO',
      'check_history': 'Check booking history for confirmation',
      'error_prefix': 'Error:',
      'booking_error_prefix': 'Booking error:',
      'booking_success_animation': 'Booking successful!',

      // ─── Profile (additional) ──────────────────────────────
      'photo_error': 'Photo selection error:',
      'ok': 'OK',
      'rub_100': '100 ₽',
      'rub_500': '500 ₽',
      'rub_1000': '1000 ₽',

      // ─── News ──────────────────────────────────────────────
      'news_title': 'NEWS',
      'news_loading': 'Loading news...',
      'news_error': 'Failed to load news',
      'news_empty': 'No news yet',
      'watch_video': 'WATCH VIDEO',
      'read_more': 'READ MORE',

      // ─── Booking (additional English) ──────────────────────
      'booking_success': 'Booking successful!',
      'booking_error': 'Booking error:',
      'unknown_error': 'Unknown error',
      'no': 'NO',
      'cancel_btn': 'CANCEL',

      // ─── Tournaments ──────────────────────────────────────
      'tournaments': 'Tournaments',
      'tournaments_title': 'TOURNAMENTS',
      'tournaments_prize': 'Prize Pool',
      'tournaments_date': 'Date',
      'tournaments_game': 'Game',
      'tournaments_format': 'Format',
      'tournaments_register': 'REGISTER',
      'tournaments_registered': 'You are registered for the tournament!',
      'tournaments_all': 'All',
      'tournaments_upcoming': 'Upcoming',
      'tournaments_past': 'Past',
      'tournaments_status': 'Status',
      'tournaments_status_upcoming': 'Upcoming',
      'tournaments_status_ongoing': 'Ongoing',
      'tournaments_status_completed': 'Completed',
      'tournaments_club': 'Club',
      'tournaments_no_tournaments': 'No tournaments yet',

      // ─── Food Delivery ────────────────────────────────────
      'order_food': '🍕 Order Food',
      'food_menu': 'Food Menu',
      'food_order': 'ORDER',
      'food_ordered': '✅ Your order will be delivered to your PC in 15 minutes!',
      'food_quantity': 'Qty',
      'food_total': 'Total',
      'food_close': 'Close',
      'food_pizza': 'Pizza "Margherita"',
      'food_cola': 'Cola 0.5L',
      'food_fries': 'French Fries',
      'food_hotdog': 'Hot Dog',
      'food_snacks': 'Snacks (Chips)',
      'food_pizza_price': '350 ₽',
      'food_cola_price': '100 ₽',
      'food_fries_price': '150 ₽',
      'food_hotdog_price': '200 ₽',
      'food_snacks_price': '120 ₽',

      // ─── Offline ──────────────────────────────────────────
      'offline_mode': 'No internet connection. Showing cached data.',
    }
  };

  String getText(String key) {
    return _localizedValues[_language]?[key] ?? key;
  }
}
