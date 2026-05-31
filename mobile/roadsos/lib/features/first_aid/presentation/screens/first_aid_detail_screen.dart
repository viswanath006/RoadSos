import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/first_aid_guide.dart';
import '../providers/first_aid_provider.dart';

class FirstAidDetailScreen extends ConsumerWidget {
  const FirstAidDetailScreen({
    super.key,
    required this.guide,
  });

  final FirstAidGuide guide;

  IconData _getIcon(String id) {
    switch (id) {
      case 'bleeding':
        return Icons.water_drop_outlined;
      case 'fracture':
        return Icons.personal_injury_outlined;
      case 'burns':
        return Icons.local_fire_department_outlined;
      case 'unconscious':
        return Icons.person_outline;
      case 'accident_victim':
        return Icons.car_crash_outlined;
      case 'cpr':
        return Icons.favorite_border_rounded;
      default:
        return Icons.medical_services_outlined;
    }
  }

  List<Color> _getGradientColors(String id) {
    switch (id) {
      case 'bleeding':
        return [const Color(0xFFFF8A80), AppTheme.sosRed];
      case 'fracture':
        return [const Color(0xFFFFD180), Colors.orange.shade700];
      case 'burns':
        return [const Color(0xFFEA80FC), Colors.purple.shade700];
      case 'unconscious':
        return [const Color(0xFF82B1FF), Colors.blue.shade700];
      case 'accident_victim':
        return [const Color(0xFFB9F6CA), Colors.green.shade700];
      case 'cpr':
        return [const Color(0xFFFF80AB), Colors.pink.shade600];
      default:
        return [Colors.teal.shade200, Colors.teal.shade700];
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final isFav = favorites.contains(guide.id);
    final gradient = _getGradientColors(guide.id);
    final icon = _getIcon(guide.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          guide.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFav ? AppTheme.sosRed : AppTheme.textSecondary,
              size: 26,
            ),
            onPressed: () {
              ref.read(favoritesProvider.notifier).toggleFavorite(guide.id);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Illustration Card with dynamic gradient
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradient,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: gradient[1].withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 64,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Title
                    const Text(
                      'What to Do',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Steps List
                    ...guide.steps.asMap().entries.map((entry) {
                      final idx = entry.key + 1;
                      final step = entry.value;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: gradient[1].withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '•',
                                style: TextStyle(
                                  color: gradient[1],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                step,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w500,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Disclaimer Banner at Bottom
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.red.shade50,
              child: Text(
                'Disclaimer: ${guide.disclaimer.isNotEmpty ? guide.disclaimer : "This information is for educational purposes only. Follow official medical protocols."}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red.shade900,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
