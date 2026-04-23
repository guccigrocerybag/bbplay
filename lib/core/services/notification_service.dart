import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Сервис для планирования локальных push-уведомлений о сессиях.
/// Уведомления приходят даже когда приложение закрыто (Android AlarmManager / iOS UNNotification).
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Инициализация плагина. Вызвать один раз при старте приложения.
  Future<void> init() async {
    if (_initialized) return;

    // Инициализация timezone data (нужна для отложенных уведомлений)
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open',
    );
    const windowsSettings = WindowsInitializationSettings(
      appName: 'BBplay',
      appUserModelId: 'BBplay.BBplay.BBplay.1',
      guid: '0E627C33-4A18-4E33-8AE9-C76860F31456',
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      linux: linuxSettings,
      macOS: iosSettings,
      windows: windowsSettings,
    );

    await _plugin.initialize(settings: initSettings);
    _initialized = true;
  }

  /// Запросить разрешение на уведомления (iOS).
  Future<void> requestPermissions() async {
    await _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  /// Планирует 3 уведомления для сессии:
  /// 1. За 15 минут до начала
  /// 2. В момент начала
  /// 3. За 10 минут до конца
  ///
  /// [bookingId] — уникальный ID брони, чтобы можно было отменить уведомления.
  /// [pcName] — имя ПК (например "PC 12").
  /// [startTime] — дата/время начала сессии.
  /// [endTime] — дата/время окончания сессии.
  Future<void> scheduleSessionNotifications({
    required String bookingId,
    required String pcName,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    if (!_initialized) await init();

    // Уведомление 1: за 15 минут до начала
    final remindTime = startTime.subtract(const Duration(minutes: 15));
    if (remindTime.isAfter(DateTime.now())) {
      await _scheduleNotification(
        id: _makeId(bookingId, 1),
        title: '⏰ Скоро сессия!',
        body: 'Ваша сессия на $pcName начнётся через 15 минут',
        scheduledDate: remindTime,
      );
    }

    // Уведомление 2: в момент начала
    if (startTime.isAfter(DateTime.now())) {
      await _scheduleNotification(
        id: _makeId(bookingId, 2),
        title: '🎮 Сессия началась!',
        body: 'Ваша сессия на $pcName началась. Приятной игры!',
        scheduledDate: startTime,
      );
    }

    // Уведомление 3: за 10 минут до конца
    final almostEndTime = endTime.subtract(const Duration(minutes: 10));
    if (almostEndTime.isAfter(DateTime.now())) {
      await _scheduleNotification(
        id: _makeId(bookingId, 3),
        title: '⏳ Сессия скоро закончится',
        body: 'Через 10 минут сессия на $pcName завершится',
        scheduledDate: almostEndTime,
      );
    }
  }

  /// Отменяет все запланированные уведомления для указанной брони.
  Future<void> cancelSessionNotifications(String bookingId) async {
    for (int i = 1; i <= 3; i++) {
      await _plugin.cancel(id: _makeId(bookingId, i));
    }
  }

  /// Отменяет все уведомления (при выходе из аккаунта).
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // --- Вспомогательные методы ---

  int _makeId(String bookingId, int type) {
    // Хэшируем bookingId + type в уникальный int ID
    return (bookingId.hashCode * 10 + type).abs();
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'booking_reminders',
      'Напоминания о бронировании',
      channelDescription: 'Уведомления о начале и окончании сессий',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }
}
