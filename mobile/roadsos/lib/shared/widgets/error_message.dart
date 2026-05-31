import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class ErrorMessage extends StatelessWidget {
  const ErrorMessage({
    super.key,
    required this.message,
    this.onRetry,
    this.onOpenSettings,
  });

  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.sosRed.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.sosRed, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            if (onRetry != null || onOpenSettings != null) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  if (onRetry != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onRetry,
                        child: const Text('Retry'),
                      ),
                    ),
                  if (onRetry != null && onOpenSettings != null)
                    const SizedBox(width: 12),
                  if (onOpenSettings != null)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onOpenSettings,
                        child: const Text('Settings'),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
