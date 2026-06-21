import 'package:flutter/widgets.dart';

/// i18n léger FR/EN pour le socle (Sprint 1).
/// Migration vers ARB + flutter gen-l10n prévue quand le volume de chaînes
/// augmentera (Sprint 4+).
class Strings {
  Strings(this.locale);
  final Locale locale;

  static Strings of(BuildContext context) =>
      Localizations.of<Strings>(context, Strings)!;

  static const supportedLocales = [Locale('fr'), Locale('en')];

  static const _values = <String, Map<String, String>>{
    'appName': {'fr': 'TM Pharma', 'en': 'TM Pharma'},
    'tagline': {
      'fr': 'Gestion de pharmacie, même hors-ligne',
      'en': 'Pharmacy management, even offline',
    },
    'welcome': {'fr': 'Socle technique prêt', 'en': 'Technical core ready'},
    'sprint1': {
      'fr': 'Sprint 1 — Socle & sécurité',
      'en': 'Sprint 1 — Core & security',
    },
    'language': {'fr': 'Langue', 'en': 'Language'},
    'theme': {'fr': 'Thème', 'en': 'Theme'},
  };

  String _t(String key) =>
      _values[key]?[locale.languageCode] ?? _values[key]?['fr'] ?? key;

  String get appName => _t('appName');
  String get tagline => _t('tagline');
  String get welcome => _t('welcome');
  String get sprint1 => _t('sprint1');
  String get language => _t('language');
  String get theme => _t('theme');
}

class StringsDelegate extends LocalizationsDelegate<Strings> {
  const StringsDelegate();

  @override
  bool isSupported(Locale locale) => Strings.supportedLocales.any(
    (l) => l.languageCode == locale.languageCode,
  );

  @override
  Future<Strings> load(Locale locale) async => Strings(locale);

  @override
  bool shouldReload(StringsDelegate old) => false;
}
