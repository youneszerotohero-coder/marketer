import 'package:flutter/material.dart';

enum OrderStatus { pending, delivered, cancelled }

class StatusBadge extends StatelessWidget {
  final OrderStatus status;
  final String text;

  const StatusBadge({
    super.key,
    required this.status,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case OrderStatus.pending:
        backgroundColor = theme.colorScheme.primaryContainer.withValues(alpha: 0.3);
        textColor = theme.colorScheme.primary;
        break;
      case OrderStatus.delivered:
        backgroundColor = theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3);
        textColor = theme.colorScheme.tertiary;
        break;
      case OrderStatus.cancelled:
        backgroundColor = theme.colorScheme.surfaceContainerHighest;
        textColor = theme.colorScheme.onSurfaceVariant;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
