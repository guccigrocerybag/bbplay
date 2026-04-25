# BBplay - Инструкция по запуску и тестированию

## 🚀 Быстрый старт (решение проблемы "client failed to fetch")

### Вариант 1: Запуск с прокси-сервером (рекомендуется)
1. **Откройте новое окно терминала**
2. **Перейдите в папку web:**
   ```bash
   cd c:\Users\zxc5k\bbplay\web
   ```
3. **Запустите dev сервер:**
   ```bash
   start_dev_server.bat
   ```
   Или вручную:
   ```bash
   node dev_server.js
   ```

4. **Откройте браузер:**
   - Перейдите по адресу: http://localhost:3000
   - Теперь CORS проблема решена!

### Вариант 2: Просмотр как на телефоне (Chrome DevTools)
1. Запустите приложение по инструкции выше
2. В Chrome нажмите **F12**
3. Нажмите иконку телефона/планшета (Toggle Device Toolbar) или **Ctrl+Shift+M**
4. Выберите нужный размер экрана (например, iPhone 12)
5. Тестируйте интерфейс как на мобильном устройстве!

## 🔧 Что было сделано для решения проблемы:

### 1. **Настроен прокси-сервер**
- Создан `web/dev_server.js` - сервер на Node.js
- Все API запросы перенаправляются на `https://vibe.blackbearsplay.ru`
- Решена проблема CORS для локальной разработки

### 2. **Обновлен ApiClient**
- Добавлена поддержка относительных путей для веб-версии
- При запуске в браузере используется `''` вместо полного URL
- Прокси сервер добавляет правильный домен

### 3. **Созданы удобные скрипты**
- `web/start_dev_server.bat` - запуск сервера одним кликом
- `web/package.json` - зависимости для сервера

## 📱 Как тестировать авторизацию:

1. **Запустите dev сервер** (см. выше)
2. **Откройте http://localhost:3000**
3. **Попробуйте войти:**
   - Логин: ваш тестовый логин
   - Пароль: ваш пароль
4. **Ошибка "client failed to fetch" должна исчезнуть!**

## 🛠 Дополнительные настройки:

### Для разработки в Chrome без прокси (альтернатива):
1. Установите расширение "CORS Unblock"
2. Или запустите Chrome с отключенной безопасностью:
   ```bash
   chrome.exe --disable-web-security --user-data-dir="C:/temp"
   ```

### Для тестирования на Android эмуляторе:
1. Установите Android Studio
2. Создайте виртуальное устройство (AVD)
3. Запустите:
   ```bash
   flutter run -d emulator-5554
   ```

## 🤖 Чат-бот с поддержкой ИИ

В приложении реализован умный чат-бот для поддержки гостей.

**Текущий режим:** Rule-based — бот отвечает на вопросы по базе знаний клуба:
- 💰 Цены и тарифы (GameZone, BootCamp, VIP)
- 📍 Адреса клубов
- 🖥️ Железо (RTX 4060/3060, 240Hz и т.д.)
- 📋 Правила клуба
- 🕐 Время работы (24/7)
- 🎮 Бронирование ПК

**Режим нейросети (YandexGPT):** Для подключения нейросети вставьте API-ключ YandexGPT в файл `lib/core/config.dart`:
```dart
static const String yandexGptApiKey = 'ваш_ключ';
static const String yandexGptFolderId = 'ваш_folder_id';
```
После этого бот будет отвечать с помощью ИИ, понимая любые вопросы.

## 📱 iOS сборка и установка на iPhone

### Что нужно заранее

- **Mac** (любой — MacBook, Mac mini, iMac)
- **iPhone** (для тестирования)
- **USB-кабель** для подключения iPhone к Mac
- **Apple ID** (бесплатный, не нужна платная подписка $99)

### Шаг 1: Установить Xcode

1. Открой **App Store** на Mac
2. Найди **Xcode** и нажми "Установить" (~15 ГБ)
3. После установки **открой Xcode** один раз, чтобы принял лицензию
4. Установи Command Line Tools:
   ```bash
   xcode-select --install
   ```

### Шаг 2: Установить Flutter на Mac

1. Скачай Flutter SDK:
   ```bash
   cd ~/Downloads
   curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.29.0-stable.zip
   unzip flutter_macos_arm64_3.29.0-stable.zip
   mv flutter ~/
   ```
   > Или скачай вручную: https://docs.flutter.dev/get-started/install/macos

2. Добавь Flutter в PATH (открой Terminal и выполни):
   ```bash
   echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.zshrc
   source ~/.zshrc
   ```

3. Проверь установку:
   ```bash
   flutter doctor
   ```
   Должно быть зелёные галочки напротив Flutter, Xcode, iOS.

### Шаг 3: Клонировать проект

```bash
cd ~/Desktop
git clone https://github.com/guccigrocerybag/bbplay.git
cd bbplay
```

### Шаг 4: Установить зависимости

```bash
flutter pub get
cd ios
pod install
cd ..
```

### Шаг 5: Настроить Bundle Identifier (обязательно!)

1. Открой Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. В Xcode слева выбери **Runner** (самый верхний)

3. Справа выбери вкладку **Signing & Capabilities**

4. В поле **Bundle Identifier** напиши уникальный идентификатор, например:
   ```
   com.tvoёимя.bbplay
   ```
   (замени "твоёимя" на что-то своё, например `com.petrov.bbplay`)

5. В поле **Team** выбери свой Apple ID:
   - Если нет — нажми **Add Account** → войди со своим Apple ID
   - После добавления выбери его в выпадающем списке

### Шаг 6: Собрать и установить на iPhone

**Вариант A — через Xcode (проще):**

1. Подключи iPhone к Mac через USB-кабель
2. В Xcode сверху выбери свой iPhone вместо симулятора (рядом с кнопкой Play ▶)
3. Нажми кнопку **Play ▶** (или Cmd+R)
4. Xcode соберёт приложение и установит на iPhone
5. На iPhone появится уведомление: **"Ненадёжный разработчик"**
6. На iPhone зайди: **Настройки → Основные → VPN и управление устройством**
7. Нажми на свой Apple ID → **Доверять**

Готово! Приложение появится на рабочем столе iPhone.

**Вариант B — через Terminal (если не хочешь открывать Xcode):**

```bash
flutter run -d ios
```

### ⚠️ Важные моменты

1. **Приложение работает 7 дней** — бесплатный Apple ID позволяет устанавливать приложения на 7 дней. После этого нужно переустановить (нажать Play в Xcode снова).

2. **Чтобы убрать ограничение 7 дней** — нужна подписка Apple Developer Program ($99/год).

3. **Если Xcode ругается на подписи** — в Xcode: Product → Clean Build Folder, потом попробуй снова.

4. **Если ошибка "Failed to register bundle identifier"** — придумай другой Bundle Identifier в Xcode (шаг 5).

5. **Если ошибка с CocoaPods** — выполни:
   ```bash
   sudo gem install cocoapods
   cd ios && pod deintegrate && pod install && cd ..
   ```

### 📦 Сборка IPA (для отправки другим)

Если хочешь отправить приложение друзьям или жюри:

1. **Через Xcode:**
   - Product → Archive
   - В открывшемся окне нажми **Distribute App**
   - Выбери **Development** → твой iPhone
   - Получишь .ipa файл

2. **Через Terminal:**
   ```bash
   flutter build ios --release
   ```
   IPA появится в `build/ios/ipa/bbplay.ipa`

### 🔄 Обновление приложения

Когда вносишь изменения в код на Windows:
1. Закоммить и запушь на GitHub
2. На Mac выполни:
   ```bash
   cd ~/Desktop/bbplay
   git pull
   flutter pub get
   cd ios && pod install && cd ..
   flutter run -d ios
   ```

## 📊 Статус проекта:

✅ **Решено:**
- Проблема CORS в веб-версии
- Настройка темизации (темная/светлая тема)
- Сохранение настроек темы через shared_preferences
- Чат-бот с rule-based логикой (работает без API-ключей)
- Интеграция с YandexGPT (требуется API-ключ)
- iOS сборка (Info.plist настроен, разрешения добавлены)

⚠️ **Требует внимания:**
- Проблемы со сборкой Windows (отсутствующие C++ файлы)

## 🆘 Если что-то не работает:

1. **Проверьте, запущен ли dev сервер:**
   ```bash
   netstat -an | find "3000"
   ```

2. **Проверьте логи сервера** (в окне где запущен start_dev_server.bat)

3. **Очистите кэш браузера** или откройте в режиме инкогнито

4. **Проверьте интернет-соединение** - сервер API должен быть доступен

## 📞 Поддержка:
Если проблемы остались, проверьте:
- Файл `web/dev_server.js` запущен и слушает порт 3000
- В консоли браузера нет других ошибок
- API сервер `https://vibe.blackbearsplay.ru` доступен
