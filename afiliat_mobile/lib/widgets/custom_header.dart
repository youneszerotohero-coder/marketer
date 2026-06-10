import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/cart_page.dart';
import '../screens/main_shell.dart';
import '../l10n/app_translations.dart';
import '../services/api_service.dart';

class CustomHeader extends StatefulWidget {
  final bool showBackButton;
  const CustomHeader({super.key, this.showBackButton = false});

  @override
  State<CustomHeader> createState() => _CustomHeaderState();
}

class _CustomHeaderState extends State<CustomHeader> {
  String? _pdfUrl;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        if (widget.showBackButton) ...[
          IconButton(
            icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
        ],
        const CircleAvatar(
          radius: 20,
          backgroundColor: Color(0xFFF97316),
          child: Icon(Icons.person, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Text(
          'Marketer Pulse'.tr,
          style: theme.textTheme.titleMedium?.copyWith(
            color: const Color(0xFFF97316),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const Spacer(),
        if (_pdfUrl != null && _pdfUrl!.isNotEmpty) ...[
          GestureDetector(
            onTap: () => _launchUrl(_pdfUrl!),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.picture_as_pdf, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'أرقام المكاتب',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
        IconButton(
          icon: Icon(Icons.shopping_cart_outlined, color: theme.colorScheme.onSurface),
          onPressed: () {
            // Only navigate to cart if we are not already on it
            if (ModalRoute.of(context)?.settings.name != 'CartPage') {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartPage(), settings: const RouteSettings(name: 'CartPage')),
              );
            }
          },
        ),
        IconButton(
          icon: Icon(Icons.notifications_none, color: theme.colorScheme.onSurface),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.menu, color: theme.colorScheme.onSurface),
          onPressed: () {
            mainShellScaffoldKey.currentState?.openEndDrawer();
          },
        ),
      ],
    );
  }
}
