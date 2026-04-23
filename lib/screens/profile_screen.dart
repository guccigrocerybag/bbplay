import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/user_provider.dart';
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
  
  // --- ЛОГИКА ПОПОЛНЕНИЯ БАЛАНСА ---
  Future<void> _showTopUpDialog() async {
    final user = Provider.of<UserProvider>(context, listen: false);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
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
            Text('Deposit Funds', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
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
                fillColor: colorScheme.surfaceVariant, 
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
                      backgroundColor: colorScheme.surfaceVariant,
                      foregroundColor: colorScheme.onSurfaceVariant,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('100 ₽'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => amountController.text = '500',
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.surfaceVariant,
                      foregroundColor: colorScheme.onSurfaceVariant,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('500 ₽'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => amountController.text = '1000',
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.surfaceVariant,
                      foregroundColor: colorScheme.onSurfaceVariant,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('1000 ₽'),
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
                    content: const Text('Введите сумму больше 0'),
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
              child: const Text('TOP UP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6))),
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
        user.updateBalance(finalAmount!); // Fallback для демо-режима
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Demo top-up successful!'),
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
    final isDark = theme.brightness == Brightness.dark;
    
    // Динамический расчет ранга для красоты
    double bal = double.tryParse(user.balance) ?? 0.0;
    String rank = bal > 50000 ? "GOLD" : (bal > 10000 ? "SILVER" : "BRONZE");
    double progress = (bal % 1000) / 1000;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('GAMER PROFILE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 16)),
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
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, 
                    gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.secondary])
                  ),
                  child: CircleAvatar(
                    radius: 50, 
                    backgroundColor: colorScheme.surfaceVariant, 
                    child: Icon(FontAwesomeIcons.userAstronaut, size: 45, color: colorScheme.onSurfaceVariant)
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
                  child: Icon(Icons.verified, size: 18, color: colorScheme.onPrimary),
                ),
              ],
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
                      Text('RANK PROGRESS', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.bold)),
                      Text('${(progress * 100).toStringAsFixed(0)}%', style: TextStyle(color: colorScheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: colorScheme.surfaceVariant,
                      color: colorScheme.primary,
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
                      Text('AVAILABLE BALANCE', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(FontAwesomeIcons.plus, size: 16),
                        SizedBox(width: 8),
                        Text('TOP UP BALANCE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                  icon: FontAwesomeIcons.history,
                  title: 'Booking History',
                  color: colorScheme.primary,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen())),
                ),
                _buildActionCard(
                  icon: FontAwesomeIcons.gear,
                  title: 'Settings',
                  color: colorScheme.secondary,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
                ),
                _buildActionCard(
                  icon: FontAwesomeIcons.share,
                  title: 'Invite Friends',
                  color: const Color(0xFF00C853),
                  onTap: () => _showInviteDialog(context, colorScheme),
                ),
                _buildActionCard(
                  icon: FontAwesomeIcons.rightFromBracket,
                  title: 'Log Out',
                  color: colorScheme.error,
                  onTap: () => _logout(context),
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

  void _showInviteDialog(BuildContext context, ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text('Invite Friends', style: TextStyle(color: colorScheme.onSurface)),
        content: Text(
          'Share your referral code with friends and get bonuses!',
          style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('Log Out', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
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
            child: Text('Log Out', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}