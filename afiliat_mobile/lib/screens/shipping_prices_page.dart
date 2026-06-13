import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_translations.dart';
import '../services/api_service.dart';

class ShippingPricesPage extends StatefulWidget {
  const ShippingPricesPage({super.key});

  @override
  State<ShippingPricesPage> createState() => _ShippingPricesPageState();
}

class _ShippingPricesPageState extends State<ShippingPricesPage> {
  bool _loading = true;
  String _error = '';
  List<Map<String, dynamic>> _shippingRates = [];
  String? _pdfUrl;

  @override
  void initState() {
    super.initState();
    _loadShippingRates();
    _loadPdfUrl();
  }

  Future<void> _loadPdfUrl() async {
    try {
      final data = await ApiService.instance.get('/app/settings');
      if (mounted) {
        setState(() {
          _pdfUrl = data['pdf_document_url']?.toString();
        });
      }
    } catch (_) {}
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _loadShippingRates() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final data = await ApiService.instance.get('/delivery/rates');
      final items = List<Map<String, dynamic>>.from(
        (data['data'] ?? data).map((item) => Map<String, dynamic>.from(item)),
      );

      if (mounted) {
        setState(() {
          _shippingRates = items.map(_normalizeRate).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Map<String, dynamic> _normalizeRate(Map<String, dynamic> rate) {
    return {
      'id': (rate['code'] ?? rate['wilaya_code'] ?? rate['id'] ?? '')
          .toString(),
      'name': (rate['wilaya'] ?? rate['name'] ?? rate['territory'] ?? '—')
          .toString(),
      'home':
          rate['home'] ??
          rate['home_price'] ??
          rate['to_home'] ??
          rate['price'] ??
          0,
      'desk':
          rate['desk'] ??
          rate['desk_price'] ??
          rate['stop_desk'] ??
          rate['office'] ??
          0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Shipping Prices'.tr,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_pdfUrl != null && _pdfUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                onPressed: () => _launchUrl(_pdfUrl!),
                icon: const Icon(Icons.picture_as_pdf, size: 14, color: Colors.white),
                label: const Text(
                  'أرقام المكاتب',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: theme.colorScheme.surface,
              child: Row(
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Delivery rates vary by state. Choose between Home Delivery or Stop Desk pickup.'
                          .tr,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : _error.isNotEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _error,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _shippingRates.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final state = _shippingRates[index];
                        return Container(
                          decoration: BoxDecoration(
                            color:
                                theme.cardTheme.color ??
                                theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: theme.shadowColor.withOpacity(isDark ? 0.2 : 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      state['id'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    state['name'],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildPriceRow(
                                context,
                                theme,
                                icon: Icons.home_outlined,
                                title: 'Home Delivery'.tr,
                                price: '${state['home']} DZD',
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Divider(height: 1),
                              ),
                              _buildPriceRow(
                                context,
                                theme,
                                icon: Icons.storefront_outlined,
                                title: 'Desk Delivery'.tr,
                                price: '${state['desk']} DZD',
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String price,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          price,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
