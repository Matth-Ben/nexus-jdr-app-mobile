// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get profileLanguageMenuEntry => 'Langue';

  @override
  String get profileLanguageScreenTitle => 'LANGUE';

  @override
  String get profileLanguagePhoneOption => 'Langue du téléphone';

  @override
  String get profileLanguagePhoneOptionSubtitle => 'Phone language';

  @override
  String get profileLanguagePhoneOptionDetail =>
      'Suit la langue de l\'appareil (FR/EN) ; repli sur le français si l\'appareil utilise une autre langue. / Follows the device\'s language (FR/EN); falls back to French otherwise.';

  @override
  String get profileLanguageFrenchOption => 'Français';

  @override
  String get profileLanguageEnglishOption => 'English';

  @override
  String get profileLanguageSaveError =>
      'Impossible d\'enregistrer ce réglage. Réessaie.';
}
