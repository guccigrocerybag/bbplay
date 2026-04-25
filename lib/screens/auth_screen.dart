import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/utils/api_client.dart';
import '../providers/user_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/app_animations.dart';
import 'main_layout.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoginMode = true; 
  bool _isLoading = false;

  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final String _defaultCafeId = "87375"; 

  Future<void> _submit() async {
    final settings = context.read<SettingsProvider>();
    final login = _loginController.text.trim();
    final password = _passwordController.text.trim();
    final phone = _phoneController.text.trim();

    if (login.isEmpty || password.isEmpty || (!_isLoginMode && phone.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(settings.getText('enter_credentials')), 
          backgroundColor: Theme.of(context).colorScheme.error,
        )
      );
      return;
    }

    if (!_isLoginMode) {
      final passwordRegex = RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d).{8,}$');
      if (!passwordRegex.hasMatch(password)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
          content: Text(settings.getText('password_too_simple')), 
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          )
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      if (_isLoginMode) {
        final response = await ApiClient.login(login, password);
        _handleSuccessLogin(response);
      } else {
        // Шаг 1: Регистрация
        final regRes = await ApiClient.registerMember(
          cafeId: _defaultCafeId, 
          login: login, 
          phone: phone, 
          password: password
        );
        
        final memberId = regRes['data']['member_id'].toString();

        // Шаг 2: Запрос СМС
        await ApiClient.requestSms(memberId);

        if (!mounted) return;
        setState(() => _isLoading = false);

        // Показываем окно ввода кода
        String? smsCode = await _showSmsDialog(settings);
        if (smsCode == null || smsCode.isEmpty) return;

        setState(() => _isLoading = true);

        // Шаг 3: Верификация
        await ApiClient.verifySms(memberId, smsCode);

        // Входим в аккаунт
        final loginRes = await ApiClient.login(login, password);
        _handleSuccessLogin(loginRes);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${settings.getText('auth_error')}: ${e.toString().replaceAll('Exception: ', '')}'), 
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleSuccessLogin(Map<String, dynamic> response) {
    if (!mounted) return;
    
    print('✅ [AUTH] Успешный логин, полный ответ: $response');
    
    if (response['member'] != null) {
      final memberData = response['member'];
      print('✅ [AUTH] Данные пользователя:');
      print('✅ [AUTH] - member_account: ${memberData['member_account']}');
      print('✅ [AUTH] - member_id: ${memberData['member_id']}');
      print('✅ [AUTH] - member_balance: ${memberData['member_balance']}');
      print('✅ [AUTH] - member_icafe_id: ${memberData['member_icafe_id']}');
      
      Provider.of<UserProvider>(context, listen: false).setUser(memberData);
    } else if (response['data'] != null) {
      print('✅ [AUTH] Данные в response.data: ${response['data']}');
      Provider.of<UserProvider>(context, listen: false).setUser(response['data']);
    } else {
      print('⚠️ [AUTH] Нет данных пользователя в ответе!');
    }
    
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainLayout()));
  }

  Future<String?> _showSmsDialog(SettingsProvider settings) {
    final TextEditingController smsController = TextEditingController();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          settings.getText('sms_confirm_title'), 
          style: TextStyle(color: colorScheme.onSurface)
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children:[
            Text(
              settings.getText('sms_confirm_body'), 
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.7), 
                fontSize: 13
              )
            ),
            const SizedBox(height: 16),
            TextField(
              controller: smsController,
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: colorScheme.onSurface, 
                fontSize: 24, 
                letterSpacing: 10
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                filled: true, 
                fillColor: colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), 
                  borderSide: BorderSide.none
                ),
              ),
            ),
          ],
        ),
        actions:[
          TextButton(
            onPressed: () => Navigator.pop(context, null), 
            child: Text(
              settings.getText('sms_cancel_btn'), 
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7))
            )
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, smsController.text.trim()), 
            child: Text(
              settings.getText('sms_confirm_btn'), 
              style: TextStyle(
                color: colorScheme.primary, 
                fontWeight: FontWeight.bold
              )
            )
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final settings = Provider.of<SettingsProvider>(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children:[
              Text(
                'BBplay', 
                textAlign: TextAlign.center, 
                style: TextStyle(
                  fontSize: 48, 
                  fontWeight: FontWeight.bold, 
                  color: colorScheme.primary, 
                  letterSpacing: 2
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isLoginMode ? settings.getText('auth_title') : settings.getText('reg_title'), 
                textAlign: TextAlign.center, 
                style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7), fontSize: 16)
              ),
              const SizedBox(height: 40),
              
              TextField(
                controller: _loginController,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: settings.getText('login_label'), 
                  labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                  filled: true, 
                  fillColor: colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), 
                    borderSide: BorderSide.none
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (!_isLoginMode) ...[
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: settings.getText('phone_hint'), 
                    labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                    filled: true, 
                    fillColor: colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), 
                      borderSide: BorderSide.none
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              TextField(
                controller: _passwordController,
                obscureText: true,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: settings.getText('pass_label'), 
                  labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                  filled: true, 
                  fillColor: colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), 
                    borderSide: BorderSide.none
                  ),
                ),
              ),
              
              if (!_isLoginMode)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                  child: Text(
                    settings.getText('password_requirements'),
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.6), 
                      fontSize: 11, 
                      height: 1.4
                    ),
                  ),
                ),
                
              const SizedBox(height: 32),

              _isLoading 
                ? const Center(
                    child: GamingSpinner(size: 80),
                  )
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _submit,
                    child: Text(
                      _isLoginMode ? settings.getText('login_btn_text') : settings.getText('register_btn_text'), 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                    ),
                  ),
              const SizedBox(height: 20),
              
              TextButton(
                onPressed: () {
                  _passwordController.clear();
                  setState(() => _isLoginMode = !_isLoginMode);
                },
                child: Text(
                  _isLoginMode ? settings.getText('no_account') : settings.getText('have_account'),
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.7), 
                    decoration: TextDecoration.underline
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}