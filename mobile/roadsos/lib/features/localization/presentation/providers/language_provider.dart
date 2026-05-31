import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../domain/app_localizations.dart';

final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('en') {
    _loadLanguage();
  }

  late final Box _box;

  void _loadLanguage() {
    _box = Hive.box('offline_settings_box');
    final saved = _box.get('current_language') as String?;
    if (saved != null) {
      state = saved;
    }
  }

  Future<void> setLanguage(String langCode) async {
    if (['en', 'te', 'hi', 'ta'].contains(langCode)) {
      state = langCode;
      await _box.put('current_language', langCode);
    }
  }
}

// Global provider for translations helper function
final translationProvider = Provider<String Function(String)>((ref) {
  final lang = ref.watch(languageProvider);
  return (String key) {
    return AppLocalizations.translate(lang, key);
  };
});
