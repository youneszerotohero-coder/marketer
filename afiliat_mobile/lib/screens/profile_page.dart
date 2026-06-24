import 'package:flutter/material.dart';
import '../main.dart';
import 'login_page.dart';
import '../l10n/app_translations.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _user;
  bool _loading = true;
  bool _saving = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bankController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedWilaya;
  final List<String> _wilayas = [
    '01 - Adrar', '02 - Chlef', '03 - Laghouat', '04 - Oum El Bouaghi', '05 - Batna', '06 - Béjaïa', '07 - Biskra', '08 - Béchar', '09 - Blida', '10 - Bouira',
    '11 - Tamanrasset', '12 - Tébessa', '13 - Tlemcen', '14 - Tiaret', '15 - Tizi Ouzou', '16 - Alger', '17 - Djelfa', '18 - Jijel', '19 - Sétif', '20 - Saïda',
    '21 - Skikda', '22 - Sidi Bel Abbès', '23 - Annaba', '24 - Guelma', '25 - Constantine', '26 - Médéa', '27 - Mostaganem', '28 - M\'Sila', '29 - Mascara', '30 - Ouargla',
    '31 - Oran', '32 - El Bayadh', '33 - Illizi', '34 - Bordj Bou Arréridj', '35 - Boumerdès', '36 - El Tarf', '37 - Tindouf', '38 - Tissemsilt', '39 - El Oued', '40 - Khenchela',
    '41 - Souk Ahras', '42 - Tipaza', '43 - Mila', '44 - Aïn Defla', '45 - Naâma', '46 - Aïn Témouchent', '47 - Ghardaïa', '48 - Relizane',
    '49 - Timimoun', '50 - Bordj Badji Mokhtar', '51 - Ouled Djellal', '52 - Béni Abbès', '53 - In Salah', '54 - In Guezzam', '55 - Touggourt', '56 - Djanet', '57 - El M\'Ghair', '58 - El Meniaa'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bankController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // 1. Try loading from cache first
    try {
      final cached = await AuthService.instance.cachedUser();
      if (cached != null && mounted) {
        setState(() {
          _user = cached;
          _nameController.text = (_user?['name'] ?? '').toString();
          _phoneController.text = (_user?['phone'] ?? '').toString();

          final profile = _user?['profile'];
          _bankController.text =
              (profile is Map ? profile['bank_number'] : null)?.toString() ??
              '';
          String? w = (profile is Map ? profile['wilaya'] : null)?.toString();
          if (_wilayas.contains(w)) _selectedWilaya = w;
          _loading = false;
        });
      }
    } catch (_) {}

    // 2. Fetch fresh details in the background
    try {
      final user = await ApiService.instance.get('/me');
      final userMap = user as Map<String, dynamic>;
      await AuthService.instance.cacheUser(userMap);
      if (mounted) {
        setState(() {
          _user = userMap;
          _nameController.text = (_user?['name'] ?? '').toString();
          _phoneController.text = (_user?['phone'] ?? '').toString();

          final profile = _user?['profile'];
          _bankController.text =
              (profile is Map ? profile['bank_number'] : null)?.toString() ??
              '';
          String? w = (profile is Map ? profile['wilaya'] : null)?.toString();
          if (_wilayas.contains(w)) _selectedWilaya = w;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted && _user == null) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final bankNumber = _bankController.text.trim();
    final password = _passwordController.text.trim();
    final wilaya = _selectedWilaya;

    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Name is required.'.tr)));
      return;
    }
    if (password.isNotEmpty && password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password must be at least 8 characters.'.tr)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final updatedUser = await ApiService.instance.put(
        '/me',
        body: {
          'name': name,
          'phone': phone.isEmpty ? null : phone,
          'bank_number': bankNumber.isEmpty ? null : bankNumber,
          'wilaya': wilaya,
          if (password.isNotEmpty) 'password': password,
        },
      );

      if (mounted) {
        final user = Map<String, dynamic>.from(updatedUser as Map);
        await AuthService.instance.cacheUser(user);
        if (!mounted) return;
        setState(() {
          _user = user;
          _nameController.text = (_user?['name'] ?? '').toString();
          _phoneController.text = (_user?['phone'] ?? '').toString();
          final profile = _user?['profile'];
          _bankController.text =
              (profile is Map ? profile['bank_number'] : null)?.toString() ??
              '';
          String? w = (profile is Map ? profile['wilaya'] : null)?.toString();
          if (_wilayas.contains(w)) _selectedWilaya = w;
          _passwordController.clear();
          _saving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully!'.tr),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile.'.tr),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService.instance.logout();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
                  _buildSectionTitle('PERSONAL INFORMATION'.tr, theme),
                  const SizedBox(height: 16),
                  _buildPersonalInfoForm(theme, primaryColor),
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
                ),
              ],
            ),
            child: const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 50, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            (_user?['name'] ?? '—').toString(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            (_user?['email'] ?? '').toString(),
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
              (_user?['tier'] ?? 'Marketer').toString(),
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

  Widget _buildPersonalInfoForm(ThemeData theme, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            theme.cardTheme.color ?? theme.colorScheme.surfaceContainerLowest,
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
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Name'.tr,
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number'.tr,
              prefixIcon: const Icon(Icons.phone_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedWilaya,
            items: _wilayas.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
            onChanged: (val) => setState(() => _selectedWilaya = val),
            decoration: InputDecoration(
              labelText: 'Wilaya'.tr,
              prefixIcon: const Icon(Icons.map_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _bankController,
            decoration: InputDecoration(
              labelText: 'Bank Account Number'.tr,
              prefixIcon: const Icon(Icons.account_balance_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'New Password (Optional)'.tr,
              prefixIcon: const Icon(Icons.lock_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              helperText: 'Leave blank to keep current password'.tr,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Save Changes'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color:
            theme.cardTheme.color ?? theme.colorScheme.surfaceContainerLowest,
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
          _buildThemeToggleMenuItem(context, theme),
          _buildDivider(theme),
          _buildLanguageToggleMenuItem(context, theme),
        ],
      ),
    );
  }

  Widget _buildThemeToggleMenuItem(BuildContext context, ThemeData theme) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentThemeMode, _) {
        final isDark =
            currentThemeMode == ThemeMode.dark ||
            (currentThemeMode == ThemeMode.system &&
                MediaQuery.of(context).platformBrightness == Brightness.dark);

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 4,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              color: theme.colorScheme.onSurface,
              size: 20,
            ),
          ),
          title: Text(
            'Dark Mode'.tr,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: theme.colorScheme.onSurface,
            ),
          ),
          trailing: Switch(
            value: isDark,
            activeThumbColor: theme.colorScheme.primary,
            onChanged: (value) {
              themeModeNotifier.value = value
                  ? ThemeMode.dark
                  : ThemeMode.light;
            },
          ),
        );
      },
    );
  }

  Widget _buildLanguageToggleMenuItem(BuildContext context, ThemeData theme) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, currentLocale, _) {
        final isArabic = currentLocale.languageCode == 'ar';

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 4,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.language,
              color: theme.colorScheme.onSurface,
              size: 20,
            ),
          ),
          title: Text(
            'العربية'.tr,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: theme.colorScheme.onSurface,
            ),
          ),
          trailing: Switch(
            value: isArabic,
            activeThumbColor: theme.colorScheme.primary,
            onChanged: (value) {
              localeNotifier.value = value
                  ? const Locale('ar')
                  : const Locale('fr');
            },
          ),
        );
      },
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(
      height: 1,
      thickness: 1,
      color: theme.colorScheme.surfaceContainerHighest,
      indent: 60,
      endIndent: 20,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => _logout(context),
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
