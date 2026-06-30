import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? description;
  final bool isGamified;

  const EmptyStateWidget({
    super.key,
    this.icon,
    required this.title,
    this.description,
    this.isGamified = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final quotes = [
      "Hôm nay trống lịch. Tắt app đi ngủ đi sếp.",
      "Không có lịch học. Xách xe ra làm bát phở thôi!",
      "Trống tiết! Tâm bất biến giữa dòng đời vạn biến.",
      "Thư giãn đi, nay không ai điểm danh đâu.",
      "Chẳng có lịch gì sất. Đi làm ván game giải trí nào!"
    ];
    final randomQuote = quotes[DateTime.now().millisecondsSinceEpoch % quotes.length];

    final displayTitle = isGamified ? "Trống lịch rồi!" : title;
    final displayDesc = isGamified ? randomQuote : description;
    final displayIcon = isGamified ? FLucideIcons.coffee : (icon ?? FLucideIcons.inbox);

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIconPlaceholder(theme, displayIcon),
              const SizedBox(height: 20),
              Text(
                displayTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              if (displayDesc != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    displayDesc,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconPlaceholder(ThemeData theme, IconData displayIcon) {
    return Container(
      padding: const EdgeInsets.all(20), // Reduced from 24
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      child: Icon(
        displayIcon,
        size: 48, // Reduced from 56 for better small screen fit
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
