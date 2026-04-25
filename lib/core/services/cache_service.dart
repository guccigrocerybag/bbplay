import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// Сервис кеширования данных для оффлайн-режима.
///
/// Использует Hive для хранения JSON-данных с временем жизни (TTL).
/// Позволяет приложению работать без интернета, показывая последние
/// загруженные данные.
class CacheService {
  static const String _boxName = 'app_cache';
  static Box? _box;

  /// Инициализация Hive. Вызвать один раз при старте приложения.
  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  /// Сохранить данные в кеш с указанным временем жизни.
  ///
  /// [key] — уникальный ключ (например, 'cafes' или 'history_user123')
  /// [data] — любые JSON-сериализуемые данные
  /// [ttl] — время жизни кеша (по умолчанию 1 час)
  static Future<void> set(
    String key,
    dynamic data, {
    Duration ttl = const Duration(hours: 1),
  }) async {
    final box = _box ?? await Hive.openBox(_boxName);
    await box.put(
      key,
      json.encode({
        'data': data,
        'expires': DateTime.now().add(ttl).toIso8601String(),
      }),
    );
  }

  /// Загрузить данные из кеша.
  ///
  /// Возвращает `null`, если данных нет или они просрочены.
  static Future<dynamic> get(String key) async {
    final box = _box ?? await Hive.openBox(_boxName);
    final raw = box.get(key);
    if (raw == null) return null;

    try {
      final cached = json.decode(raw);
      final expires = DateTime.parse(cached['expires']);

      if (DateTime.now().isAfter(expires)) {
        // Данные просрочены — удаляем
        await box.delete(key);
        return null;
      }

      return cached['data'];
    } catch (_) {
      // Если данные повреждены — удаляем
      await box.delete(key);
      return null;
    }
  }

  /// Загрузить данные из кеша, даже если они просрочены.
  /// Используется как fallback, когда нет интернета.
  static Future<dynamic> getStale(String key) async {
    final box = _box ?? await Hive.openBox(_boxName);
    final raw = box.get(key);
    if (raw == null) return null;

    try {
      final cached = json.decode(raw);
      return cached['data'];
    } catch (_) {
      return null;
    }
  }

  /// Удалить конкретный ключ из кеша.
  static Future<void> remove(String key) async {
    final box = _box ?? await Hive.openBox(_boxName);
    await box.delete(key);
  }

  /// Очистить весь кеш.
  static Future<void> clear() async {
    final box = _box ?? await Hive.openBox(_boxName);
    await box.clear();
  }
}
