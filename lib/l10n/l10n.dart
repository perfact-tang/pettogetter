import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

enum AppLanguage {
  english('en', 'English'),
  japanese('ja', '日本語'),
  chinese('zh', '中文'),
  korean('ko', '한국어');

  const AppLanguage(this.rawValue, this.label);

  final String rawValue;
  final String label;
}

/// Minimal four-language helper, mirroring `L10n.text` in the Swift code.
/// Every call site passes all four strings; this keeps the port readable
/// without a full ARB/flutter_localizations setup.
abstract final class L10n {
  static String text(
    AppLanguage language,
    String english,
    String japanese,
    String chinese,
    String korean,
  ) {
    return switch (language) {
      AppLanguage.english => english,
      AppLanguage.japanese => japanese,
      AppLanguage.chinese => chinese,
      AppLanguage.korean => korean,
    };
  }

  static String categoryTitle(AppLanguage language, CareCategory category) {
    switch (category) {
      case CareCategory.feeding:
        return text(language, 'Feeding', '食事', '喂食', '식사');
      case CareCategory.walking:
        return text(language, 'Walking', '散歩', '散步', '산책');
      case CareCategory.medication:
        return text(language, 'Medication', '薬', '用药', '약');
      case CareCategory.grooming:
        return text(language, 'Grooming', 'グルーミング', '美容', '미용');
      case CareCategory.other:
        return text(language, 'Other', 'その他', '其他', '기타');
    }
  }
}

/// Persists the selected language to `shared_preferences`, like the Swift
/// `AppLanguageStore`.
class AppLanguageStore extends ChangeNotifier {
  AppLanguageStore(this._language);

  static const _key = 'copaw.language';

  AppLanguage _language;
  AppLanguage get language => _language;

  set language(AppLanguage value) {
    if (value == _language) return;
    _language = value;
    notifyListeners();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_key, value.rawValue);
    });
  }

  static Future<AppLanguage> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key) ?? 'en';
    return AppLanguage.values.firstWhere(
      (e) => e.rawValue == raw,
      orElse: () => AppLanguage.english,
    );
  }
}
