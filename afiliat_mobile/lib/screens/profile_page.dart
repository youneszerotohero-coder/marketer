import 'package:flutter/material.dart';
import '../main.dart';
import 'login_page.dart';
import '../l10n/app_translations.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(context, primaryColor),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildSectionTitle('ANALYTICS OVERVIEW'.tr, theme),
                  const SizedBox(height: 16),
                  _buildAnalyticsGrid(theme),
                  const SizedBox(height: 12),
                  _buildCommissionCard(theme, primaryColor),
                  const SizedBox(height: 32),
                  _buildSectionTitle('ACCOUNT SETTINGS'.tr, theme),
                  const SizedBox(height: 16),
                  _buildSettingsCard(context, theme),
                  const SizedBox(height: 32),
                  _buildLogoutButton(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, Color primaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
            child: const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 50, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'John Doe',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'john.doe@example.com',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Pro Affiliate'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
      ),
    );
  }

  Widget _buildAnalyticsGrid(ThemeData theme) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _buildAnalyticsCard(theme, 'Total Sales'.tr, '142', '+8%', true),
        _buildAnalyticsCard(theme, 'Pending Orders'.tr, '12', 'In Progress'.tr, null),
        _buildAnalyticsCard(theme, 'Delivered'.tr, '98', '82% Rate'.replaceAll('Rate', 'Rate'.tr), true, color: const Color(0xFF006D36)),
        _buildAnalyticsCard(theme, 'Failed'.tr, '05', '-2%', false, color: const Color(0xFFBA1A1A)),
      ],
    );
  }

  Widget _buildAnalyticsCard(ThemeData theme, String title, String value, String trendText, bool? isPositive, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color ?? const Color(0xFFF97316)),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isPositive != null)
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    size: 14,
                    color: isPositive ? const Color(0xFF006D36) : const Color(0xFFBA1A1A),
                  ),
                const SizedBox(width: 4),
                Text(
                  trendText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isPositive == null 
                        ? theme.colorScheme.onSurfaceVariant
                        : (isPositive ? const Color(0xFF006D36) : const Color(0xFFBA1A1A)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionCard(ThemeData theme, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Commission Earned'.tr, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('DZD 45,800', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.monetization_on_outlined, color: primaryColor, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildProfileMenuItem(context, theme, Icons.person_outline, 'Personal Information'.tr, true),
          _buildDivider(theme),
          _buildProfileMenuItem(context, theme, Icons.account_balance_outlined, 'Bank Details'.tr, true),
          _buildDivider(theme),
          _buildThemeToggleMenuItem(context, theme),
          _buildDivider(theme),
          _buildProfileMenuItem(context, theme, Icons.security_outlined, 'Security'.tr, true),
          _buildDivider(theme),
          _buildProfileMenuItem(context, theme, Icons.help_outline, 'Help & Support'.tr, false),
        ],
      ),
    );
  }

  Widget _buildThemeToggleMenuItem(BuildContext context, ThemeData theme) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentThemeMode, _) {
        final isDark = currentThemeMode == ThemeMode.dark || 
            (currentThemeMode == ThemeMode.system && 
             MediaQuery.of(context).platformBrightness == Brightness.dark);

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined, 
              color: theme.colorScheme.onSurface, 
              size: 20
            ),
          ),
          title: Text(
            'Dark Mode'.tr, 
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: theme.colorScheme.onSurface)
          ),
          trailing: Switch(
            value: isDark,
            activeColor: theme.colorScheme.primary,
            onChanged: (value) {
              themeModeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
            },
          ),
        );
      },
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(height: 1, thickness: 1, color: theme.colorScheme.surfaceContainerHighest, indent: 60, endIndent: 20);
  }

  Widget _buildProfileMenuItem(BuildContext context, ThemeData theme, IconData icon, String title, bool hasBorder) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: theme.colorScheme.onSurface, size: 20),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: theme.colorScheme.onSurface)),
      trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
      onTap: () {},
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFBA1A1A),
          side: const BorderSide(color: Color(0xFFBA1A1A), width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, size: 20),
            const SizedBox(width: 8),
            Text(
              'Log Out'.tr,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
