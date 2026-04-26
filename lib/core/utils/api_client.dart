import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../config.dart';
import '../services/cache_service.dart';

class ApiClient {
  static const String baseUrl = 'https://vibe.blackbearsplay.ru';
  
  // Для веб-версии используем относительные пути (прокси будет перенаправлять)
  static String get _effectiveBaseUrl {
    if (kIsWeb) {
      // В веб-версии используем относительные пути
      // Прокси сервер будет перенаправлять запросы
      return '';
    }
    return baseUrl;
  }

  /// Список эндпоинтов, которые можно кешировать для оффлайн-режима
  static const List<String> _cacheableEndpoints = [
    '/cafes',
    '/struct-rooms-icafe',
    '/all-prices-icafe',
  ];

  /// Генерирует ключ кеша на основе endpoint и параметров
  static String _cacheKey(String endpoint, Map<String, String>? params) {
    if (params == null || params.isEmpty) return endpoint;
    final sortedParams = params.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return '$endpoint?${sortedParams.map((e) => '${e.key}=${e.value}').join('&')}';
  }

  static Future<Map<String, dynamic>> get(String endpoint, {Map<String, String>? params}) async {
    final uri = Uri.parse('$_effectiveBaseUrl$endpoint').replace(queryParameters: params);
    final cacheKey = _cacheKey(endpoint, params);
    final bool isCacheable = _cacheableEndpoints.contains(endpoint);
    
    // Добавили таймаут и автоповтор для защиты от падений сервера
    int retryCount = 3;
    while (retryCount > 0) {
      try {
        final response = await http
            .get(uri, headers: {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 10));
        final result = _handleResponse(response);
        
        // Сохраняем в кеш, если эндпоинт кешируемый
        if (isCacheable) {
          try {
            await CacheService.set(cacheKey, result);
          } catch (_) {
            // Игнорируем ошибки кеширования
          }
        }
        
        return result;
      } catch (e) {
        // Если запрос не удался и эндпоинт кешируемый — пробуем кеш
        if (isCacheable && retryCount == 1) {
          final cached = await CacheService.getStale(cacheKey);
          if (cached != null) {
            return cached;
          }
        }
        retryCount--;
        if (retryCount == 0) rethrow;
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    throw Exception('Не удалось связаться с сервером');
  }

  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$_effectiveBaseUrl$endpoint');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(body),
    );
    return _handleResponse(response);
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.body.isEmpty) throw Exception('Пустой ответ от сервера');
    
    final Map<String, dynamic> data = json.decode(response.body);

    final dynamic code = data['code'].toString();
    final String message = (data['message'] ?? "").toString().toLowerCase();

    // 1. ЗАЩИТА ОТ ЛОЖНОГО УСПЕХА
    // Если в сообщении есть слова об ошибке, это ПРОВАЛ, даже если код 0
    bool isFakeSuccess = message.contains('incorrect') || 
                         message.contains('empty') || 
                         message.contains('error') || 
                         message.contains('not allowed') ||
                         message.contains('не удалось') ||
                         message.contains('occupied');

    // 2. ПРОВЕРКА УСПЕХА
    bool isSuccess = (code == '0' || code == '3' || code == '200' || code == '201') || 
                     message.contains('succes');

    if (isSuccess && !isFakeSuccess) {
      return data;
    } else {
      // Если сервер запрятал ошибку глубоко в iCafe_response, достаем её
      String errorMsg = data['message'] ?? 'Ошибка API: $code';
      if (data['iCafe_response'] != null && data['iCafe_response']['message'] != null) {
        errorMsg = data['iCafe_response']['message'];
      }
      throw Exception(errorMsg);
    }
  }

  // --- МЕТОДЫ АВТОРИЗАЦИИ И РЕГИСТРАЦИИ ---
  // --- НОВЫЙ МЕТОД ДЛЯ DELETE ЗАПРОСОВ (Отмена брони) ---
  static Future<Map<String, dynamic>> deleteReq(String endpoint, {Map<String, dynamic>? body}) async {
    final url = Uri.parse('$_effectiveBaseUrl$endpoint');
    
    print('--- ЗАПРОС DELETE НА $endpoint ---');
    if (body != null) print('BODY: ${json.encode(body)}');

    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: body != null ? json.encode(body) : null,
    );
    
    // Для DELETE запросов серверы часто возвращают пустой ответ с кодом 200 или 204
    if (response.body.isEmpty && (response.statusCode == 200 || response.statusCode == 204)) {
      return {'code': 0, 'message': 'Success'};
    }
    
    return _handleResponse(response);
  }

  // --- ИСТИННАЯ ОТМЕНА БРОНИРОВАНИЯ (iCafeCloud API) ---
// --- ИСТИННАЯ ОТМЕНА БРОНИРОВАНИЯ (теперь и с offerId) ---
  static Future<void> cancelBooking(String cafeId, String bookingId, String pcName, String offerId) async {
    await deleteReq('/api/v2/cafe/$cafeId/bookings', body: {
      "booking_ids": [int.tryParse(bookingId) ?? 0],
      "pc_name": pcName,
      "member_offer_id": int.tryParse(offerId) ?? 0, // Добавили то, что он просит сейчас
    });
  }

 static Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await post('/login', {
      'member_name': username,
      'password': password,
    });
    
    // СТРОГАЯ ПРОВЕРКА: Если сервер ответил "Успех", но забыл прислать данные игрока — это обман!
    if (response['member'] == null && response['data'] == null) {
      throw Exception('Неверный логин или пароль');
    }
    
    return response;
  }

  static Future<Map<String, dynamic>> registerMember({
    required String cafeId,
    required String login,
    required String phone,
    required String password,
  }) async {
    return await post('/api/v2/cafe/$cafeId/members', {
      'member_account': login,
      'member_phone': phone,
      'member_password': password, 
      'password': password,        
    });
  }

  static Future<Map<String, dynamic>> requestSms(String memberId) async {
    return await post('/request-sms', {'member_id': memberId});
  }

  static Future<Map<String, dynamic>> verifySms(String memberId, String code) async {
    return await post('/verify', {'member_id': memberId, 'code': code});
  }

  // --- МЕТОДЫ ПРОФИЛЯ ---

  static Future<Map<String, dynamic>> topUpBalance({
    required String cafeId,
    required String memberId,
    required String account,
    required double amount,
  }) async {
    return await post('/api/v2/cafe/$cafeId/members/$memberId/topup', {
      'amount': amount.toString(),
      'member_account': account,
      'pay_method': 'cash',
    });
  }

  // ТОТ САМЫЙ МЕТОД ДЛЯ ИСТОРИИ СЕССИЙ (ИЗ PDF)
  // Исправляем ошибку организаторов в документации: используем /all-books-cafes
  static Future<Map<String, dynamic>> getBookingHistory(String account) async {
    return await get('/all-books-cafes', params: {'member_account': account});
  }

  // --- МЕТОДЫ ДЛЯ ПОЛУЧЕНИЯ ID КЛУБА ---

  /// Возвращает icafe_id для запросов по клиентам.
  static Future<Map<String, dynamic>> getIcafeIdForMember(String memberId) async {
    return await get('/icafe-id-for-member', params: {'memberId': memberId});
  }

  // --- МЕТОДЫ БРОНИРОВАНИЯ ---

  static Future<Map<String, dynamic>> getAvailablePcs({required String cafeId, required String date, required String time, required int mins}) async {
    return await get('/available-pcs-for-booking', params: {'cafeId': cafeId, 'dateStart': date, 'timeStart': time, 'mins': mins.toString(), 'isFindWindow': 'true'});
  }

  static Future<Map<String, dynamic>> getAllPrices({required String cafeId, required String memberId, required String date}) async {
    return await get('/all-prices-icafe', params: {'cafeId': cafeId, 'memberId': memberId, 'bookingDate': date});
  }

  static Map<String, String> generateBookingKeys(String cafeId, String pcName, String memberId) {
    String randKey = (Random().nextInt(900000000) + 1000000000).toString();
    String rawKey = "$cafeId$pcName$memberId$randKey"; 
    String key = md5.convert(utf8.encode(rawKey)).toString();
    return {'rand_key': randKey, 'key': key};
  }

  // --- YANDEX GPT (ЧАТ-БОТ С НЕЙРОСЕТЬЮ) ---

  /// Отправляет сообщение в YandexGPT и возвращает ответ.
  ///
  /// [messages] — история диалога в формате YandexGPT:
  ///   [{ "role": "system"|"user"|"assistant", "text": "..." }]
  static Future<String> chatWithAI(List<Map<String, String>> messages) async {
    final url = Uri.parse(
        'https://llm.api.cloud.yandex.net/foundationModels/v1/completion');

    final body = {
      "modelUri": "gpt://${AppConfig.yandexGptFolderId}/${AppConfig.yandexGptModel}",
      "completionOptions": {
        "stream": false,
        "temperature": 0.6,
        "maxTokens": 1000,
      },
      "messages": messages,
    };

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Api-Key ${AppConfig.yandexGptApiKey}',
            },
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['result'];
        if (result != null &&
            result['alternatives'] != null &&
            result['alternatives'].isNotEmpty) {
          final message = result['alternatives'][0]['message'];
          if (message != null && message['text'] != null) {
            return message['text'].toString();
          }
        }
        return 'Извините, не удалось получить ответ от нейросети.';
      } else {
        final errorData = json.decode(response.body);
        final errorMsg = errorData['error']?['message'] ?? 'Ошибка ${response.statusCode}';
        throw Exception(errorMsg);
      }
    } catch (e) {
      // Если YandexGPT недоступен — выбрасываем исключение
      rethrow;
    }
  }
}
