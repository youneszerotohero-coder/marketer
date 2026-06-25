import 'package:flutter/material.dart';
import '../l10n/app_translations.dart';
import '../services/api_service.dart';
import '../widgets/custom_header.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final api = ApiService.instance;
      final stats = await api.get('/marketer/stats');
      if (mounted) {
        setState(() {
          _stats = stats as Map<String, dynamic>;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load dashboard data.'.tr;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 60,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  _error.tr,
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: Text('Retry'.tr),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CustomHeader(),
                const SizedBox(height: 24),
                _buildSectionTitle('FINANCIAL SUMMARY'.tr, theme),
                const SizedBox(height: 16),
                _buildFinancialGrid(theme, primaryColor),
                const SizedBox(height: 28),
                _buildSectionTitle('SALES & ORDERS'.tr, theme),
                const SizedBox(height: 16),
                _buildAnalyticsGrid(theme),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
      ),
    );
  }

  Widget _buildFinancialGrid(ThemeData theme, Color primaryColor) {
    final wallet = _stats?['wallet'] ?? {};
    final earned = wallet['earned']?.toString() ?? '0';
    final available = wallet['available']?.toString() ?? '0';
    final pending = wallet['pending_withdrawals']?.toString() ?? '0';

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF97316), Color(0xFFEA580C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF97316).withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available balance'.tr,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white70,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'DZD $available',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white30, height: 1),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Earned'.tr,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'DZD $earned',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pending'.tr,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'DZD $pending',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsGrid(ThemeData theme) {
    final totalSales = _stats?['total_sales']?.toString() ?? '0';
    final pending = _stats?['pending_orders']?.toString() ?? '0';
    final confirmed = _stats?['confirmed_orders']?.toString() ?? '0';
    final shipped = _stats?['shipped_orders']?.toString() ?? '0';
    final delivered = _stats?['delivered_orders']?.toString() ?? '0';
    final retourFacture = _stats?['retour_facture_orders']?.toString() ?? '0';
    final retourExonere = _stats?['retour_exonere_orders']?.toString() ?? '0';
    final cancelled = _stats?['cancelled_orders']?.toString() ?? '0';
    final rate = '${_stats?['delivery_rate'] ?? 0}%';

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.45,
      children: [
        _buildAnalyticsCard(
          theme,
          'Total Sales'.tr,
          totalSales,
          Icons.shopping_bag_outlined,
          const Color(0xFF3B82F6),
        ),
        _buildAnalyticsCard(
          theme,
          'Pending Orders'.tr,
          pending,
          Icons.hourglass_empty,
          const Color(0xFFF59E0B),
        ),
        _buildAnalyticsCard(
          theme,
          'Confirmed'.tr,
          confirmed,
          Icons.check_circle_outline,
          const Color(0xFF0F766E),
        ),
        _buildAnalyticsCard(
          theme,
          'In Delivery'.tr,
          shipped,
          Icons.local_shipping_outlined,
          const Color(0xFF8B5CF6),
        ),
        _buildAnalyticsCard(
          theme,
          'Delivered'.tr,
          delivered,
          Icons.done_all_outlined,
          const Color(0xFF10B981),
          subText: '${'Delivery Rate'.tr}: $rate',
        ),
        _buildAnalyticsCard(
          theme,
          'Retour Facturé'.tr,
          retourFacture,
          Icons.undo_rounded,
          const Color(0xFFBE123C),
        ),
        _buildAnalyticsCard(
          theme,
          'Retour Exonéré'.tr,
          retourExonere,
          Icons.undo_rounded,
          const Color(0xFFD97706),
        ),
        _buildAnalyticsCard(
          theme,
          'Cancelled'.tr,
          cancelled,
          Icons.cancel_outlined,
          const Color(0xFF6B7280),
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(
    ThemeData theme,
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            theme.cardTheme.color ?? theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (subText != null) ...[
                const SizedBox(height: 4),
                Text(
                  subText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
