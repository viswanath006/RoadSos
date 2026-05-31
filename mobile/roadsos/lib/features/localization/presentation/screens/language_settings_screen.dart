import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/language_provider.dart';

class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(languageProvider);
    final tr = ref.watch(translationProvider);

    final languages = [
      {'code': 'en', 'name': 'English', 'nativeName': 'English'},
      {'code': 'te', 'name': 'Telugu', 'nativeName': 'తెలుగు'},
      {'code': 'hi', 'name': 'Hindi', 'nativeName': 'हिन्दी'},
      {'code': 'ta', 'name': 'Tamil', 'nativeName': 'தமிழ்'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr('language_settings'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: languages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final lang = languages[index];
          final isSelected = currentLang == lang['code'];

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isSelected ? AppTheme.sosRed : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
            ),
            color: isSelected ? AppTheme.sosRed.withOpacity(0.04) : Colors.white,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              onTap: () {
                ref.read(languageProvider.notifier).setLanguage(lang['code']!);
              },
              title: Text(
                lang['nativeName']!,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppTheme.sosRed : AppTheme.textPrimary,
                ),
              ),
              subtitle: Text(
                lang['name']!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              trailing: isSelected
                  ? const Icon(
                      Icons.check_circle,
                      color: AppTheme.sosRed,
                      size: 28,
                    )
                  : Icon(
                      Icons.circle_outlined,
                      color: Colors.grey.shade400,
                      size: 28,
                    ),
            ),
          );
        },
      ),
    );
  }
}
