import 'package:flutter/material.dart';

/// Full-bleed empty/error placeholder for customer screens (Requests,
/// subcategory grids, etc.) — mirrors [TabStatePlaceholder] used on the
/// provider dashboard so both sides read as one consistent design system.
class EmptyStatePlaceholder extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? message;
  final String? retryLabel;
  final VoidCallback? onRetry;

  const EmptyStatePlaceholder({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.message,
    this.retryLabel,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: Icon(icon, size: 34, color: color),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A2233)),
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        message!,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13.5, color: Colors.grey[600], height: 1.4),
                      ),
                    ],
                    if (onRetry != null) ...[
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(retryLabel ?? 'Retry'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: color,
                          side: BorderSide(color: color.withValues(alpha: 0.4)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
