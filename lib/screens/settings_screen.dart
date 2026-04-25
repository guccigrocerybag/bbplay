import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(s.getText('settings'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(context, s.getText('appearance')),
          _buildSettingTile(
            context,
            title: s.getText('theme_title'),
            subtitle: s.themeMode.toString().split('.').last.toUpperCase(),
            icon: Icons.palette_outlined,
            onTap: () => _showThemeDialog(context, s),
          ),
          _buildSettingTile(
            context,
            title: s.getText('lang_title'),
            subtitle: s.language,
            icon: Icons.language,
            onTap: () => _showLanguageDialog(context, s),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, s.getText('notif_title')),
          _buildSettingTile(
            context,
            title: s.getText('notif_title'),
            subtitle: s.getText('notif_sub'),
            icon: Icons.notifications_none,
            trailing: Switch(
              activeColor: Theme.of(context).colorScheme.primary,
              value: s.notificationsEnabled,
              onChanged: (val) => s.toggleNotifications(val),
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(settings.getText('theme_title'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        children: [
          _themeOption(context, settings, settings.getText('theme_system'), ThemeModeOption.system),
          _themeOption(context, settings, settings.getText('theme_light'), ThemeModeOption.light),
          _themeOption(context, settings, settings.getText('theme_dark'), ThemeModeOption.dark),
        ],
      ),
    );
  }

  Widget _themeOption(BuildContext context, SettingsProvider settings, String title, ThemeModeOption mode) {
    return RadioListTile<ThemeModeOption>(
      title: Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
      value: mode,
      activeColor: Theme.of(context).colorScheme.primary,
      groupValue: settings.themeMode,
      onChanged: (val) {
        settings.setThemeMode(val!);
        Navigator.pop(context);
      },
    );
  }

  void _showLanguageDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(settings.getText('lang_title'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        children: ['Русский', 'English'].map((lang) => RadioListTile<String>(
          title: Text(lang, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          value: lang,
          activeColor: Theme.of(context).colorScheme.primary,
          groupValue: settings.language,
          onChanged: (val) {
            settings.setLanguage(val!);
            Navigator.pop(context);
          },
        )).toList(),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      child: Text(title.toUpperCase(), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSettingTile(BuildContext context, {required String title, required String subtitle, required IconData icon, VoidCallback? onTap, Widget? trailing}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), 
          fontSize: 12
        )),
        trailing: trailing ?? const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      ),
    );
  }
}