import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../providers/user_provider.dart';
import '../providers/settings_provider.dart';
import '../core/utils/api_client.dart';
import 'auth_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  
  // --- ВЫБОР АВАТАРКИ ---
  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (image != null) {
        if (!mounted) return;
        await context.read<UserProvider>().setAvatar(image.path);
      }
    } catch (e) {
      if (!mounted) return;
      final s = context.read<SettingsProvider>();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${s.getText('photo_error')} $e')),
      );
    }
  }

  void _showAvatarPicker() {
    final settings = context.read<SettingsProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                settings.getText('change_avatar'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(FontAwesomeIcons.camera),
                title: Text(settings.getText('avatar_camera')),
                onTap: () {
                  Navigator.pop(context);
                  _pickAvatar(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(FontAwesomeIcons.image),
                title: Text(settings.getText('avatar_gallery')),
                onTap: () {
                  Navigator.pop(context);
                  _pickAvatar(ImageSource.gallery);
                },
              ),
              if (context.read<UserProvider>().avatarPath != null)
                ListTile(
                  leading: Icon(FontAwesomeIcons.trashCan,
                      color: Theme.of(context).colorScheme.error),
                  title: Text(
                    settings.getText('avatar_remove'),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    context.read<UserProvider>().setAvatar(null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- ЛОГИКА ПОПОЛНЕНИЯ БАЛАНСА ---
  Future<void> _showTopUpDialog() async {
    final user = Provider.of<UserProvider>(context, listen: false);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = context.read<SettingsProvider>();
    
    final TextEditingController amountController = TextEditingController();
    double? finalAmount;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              settings.getText('deposit_funds'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: TextStyle(color: colorScheme.primary, fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0', 
                suffixText: '₽',
                suffixStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                filled: true, 
                fillColor: colorScheme.surfaceContainerHighest, 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => amountController.text = '100',
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      foregroundColor: colorScheme.onSurfaceVariant,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(settings.getText('rub_100')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => amountController.text = '500',
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      foregroundColor: colorScheme.onSurfaceVariant,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(settings.getText('rub_500')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => amountController.text = '1000',
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      foregroundColor: colorScheme.onSurfaceVariant,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(settings.getText('rub_1000')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text) ?? 0.0;
                if (amount > 0) {
                  finalAmount = amount;
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(settings.getText('enter_amount')),
                    backgroundColor: colorScheme.error,
                  ));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                settings.getText('top_up'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                settings.getText('cancel'),
                style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
              ),
            ),
          ],
        ),
      ),
    );

    if (finalAmount != null && finalAmount! > 0) {
      try {
        final cafeId = user.userData?['member_icafe_id']?.toString() ?? "87375";
        await ApiClient.topUpBalance(cafeId: cafeId, memberId: user.memberId, account: user.account, amount: finalAmount!);
        if (!mounted) return;
        user.updateBalance(finalAmount!);
      } catch (e) {
        user.updateBalance(finalAmount!);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(settings.getText('demo_topup')),
          backgroundColor: colorScheme.primary,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = Provider.of<SettingsProvider>(context);
    
    // Ранг на основе баллов (member_points) с сервера
    double pts = double.tryParse(user.points) ?? 0.0;
    String rank;
    double nextRankPoints;
    double progress;
    if (pts >= 5000) {
      rank = "GOLD";
      nextRankPoints = 5000;
      progress = 1.0;
    } else if (pts >= 1000) {
      rank = "SILVER";
      nextRankPoints = 5000;
      progress = (pts - 1000) / (5000 - 1000);
    } else {
      rank = "BRONZE";
      nextRankPoints = 1000;
      progress = pts / 1000;
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          settings.getText('gamer_profile'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- HEADER: AVATAR & RANK ---
            GestureDetector(
              onTap: _showAvatarPicker,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, 
                      gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.primary])
                    ),
                    child: CircleAvatar(
                      radius: 50, 
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      backgroundImage: user.avatarPath != null
                          ? FileImage(File(user.avatarPath!))
                          : null,
                      child: user.avatarPath == null
                          ? Icon(FontAwesomeIcons.userAstronaut, size: 45, color: colorScheme.onSurfaceVariant)
                          : null,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.edit, size: 16, color: colorScheme.onPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.account,
              style: TextStyle(color: colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
              ),
              child: Text(
                rank,
                style: TextStyle(color: colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        settings.getText('rank_progress'),
                        style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      Text('${(progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(color: colorScheme.primary, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- POINTS CARD ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: colorScheme.surface,
                border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(FontAwesomeIcons.star, size: 20, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settings.getText('loyalty_points'),
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${user.points}',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    rank == "GOLD" ? 'MAX' : '→ ${nextRankPoints.toInt()}',
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.4),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- BALANCE CARD (PREMIUM LOOK) ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: [colorScheme.surface, colorScheme.surface.withOpacity(0.8)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight
                ),
                border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
                boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.05), blurRadius: 20, spreadRadius: 5)],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(FontAwesomeIcons.wallet, size: 14, color: colorScheme.onSurface.withOpacity(0.6)),
                      const SizedBox(width: 8),
                      Text(
                        settings.getText('available_balance'),
                        style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FittedBox(
                    child: Text(
                      '${user.balance} ₽',
                      style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: colorScheme.onSurface),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _showTopUpDialog,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(FontAwesomeIcons.plus, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          settings.getText('top_up_balance'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- ACTIONS GRID ---
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildActionCard(
                  icon: FontAwesomeIcons.clockRotateLeft,
                  title: settings.getText('booking_history'),
                  color: colorScheme.primary,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen())),
                ),
                _buildActionCard(
                  icon: FontAwesomeIcons.gear,
                  title: settings.getText('settings'),
                  color: colorScheme.primary,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
                ),
                _buildActionCard(
                  icon: FontAwesomeIcons.share,
                  title: settings.getText('invite_friends'),
                  color: colorScheme.primary,
                  onTap: () => _showInviteDialog(context, colorScheme, settings),
                ),
                _buildActionCard(
                  icon: FontAwesomeIcons.rightFromBracket,
                  title: settings.getText('log_out'),
                  color: colorScheme.error,
                  onTap: () => _logout(context, settings),
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteDialog(BuildContext context, ColorScheme colorScheme, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(settings.getText('invite_title'), style: TextStyle(color: colorScheme.onSurface)),
        content: Text(
          settings.getText('invite_text'),
          style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(settings.getText('ok'), style: TextStyle(color: colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(settings.getText('logout_title'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Text(
          settings.getText('logout_confirm'),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(settings.getText('cancel'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
          ),
          TextButton(
            onPressed: () {
              Provider.of<UserProvider>(context, listen: false).logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const AuthScreen()),
                (route) => false,
              );
            },
            child: Text(settings.getText('logout_btn'), style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}
