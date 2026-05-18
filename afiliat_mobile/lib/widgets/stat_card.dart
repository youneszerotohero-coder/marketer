import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String trendText;
  final bool isPositive;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.trendText,
    this.isPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title.toUpperCase(),
              style: theme.textTheme.labelSmall,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.displayLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: isPositive ? colorScheme.tertiary : colorScheme.error,
                ),
                const SizedBox(width: 4),
                Text(
                  trendText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isPositive ? colorScheme.tertiary : colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
