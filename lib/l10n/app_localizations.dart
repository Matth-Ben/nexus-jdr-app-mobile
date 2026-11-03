import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// Libellé de la tuile de menu "Langue" de l'écran Profil (`profile_screen.dart`), qui pousse vers `/profile/language`.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get profileLanguageMenuEntry;

  /// Titre du bandeau bois (`WoodBackHeader`) de l'écran `profile_language_screen.dart`, déjà en majuscules (`font.display` ne transforme pas la casse).
  ///
  /// In fr, this message translates to:
  /// **'LANGUE'**
  String get profileLanguageScreenTitle;

  /// Titre de la 1ère `SelectableOptionTile` de l'écran "Langue" — préférence par défaut (aucune langue forcée, `LocalePreferenceController` à `null`).
  ///
  /// In fr, this message translates to:
  /// **'Langue du téléphone'**
  String get profileLanguagePhoneOption;

  /// Sous-titre fixe de la 1ère `SelectableOptionTile`, toujours dans l'AUTRE langue que `profileLanguagePhoneOption` (indice bilingue volontaire pour un utilisateur qui ne lirait pas la langue active).
  ///
  /// In fr, this message translates to:
  /// **'Phone language'**
  String get profileLanguagePhoneOptionSubtitle;

  /// `selectedDetail` affiché uniquement quand la 1ère tuile est sélectionnée — texte fixe bilingue (identique dans les deux fichiers .arb), spec direction-artistique explicite : pas de logique runtime pour choisir l'ordre FR/EN.
  ///
  /// In fr, this message translates to:
  /// **'Suit la langue de l\'appareil (FR/EN) ; repli sur le français si l\'appareil utilise une autre langue. / Follows the device\'s language (FR/EN); falls back to French otherwise.'**
  String get profileLanguagePhoneOptionDetail;

  /// Titre de la 2e `SelectableOptionTile` — nom de la langue dans sa propre langue, identique dans les deux fichiers .arb (convention habituelle d'un sélecteur de langue).
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get profileLanguageFrenchOption;

  /// Titre de la 3e `SelectableOptionTile` — nom de la langue dans sa propre langue, identique dans les deux fichiers .arb (convention habituelle d'un sélecteur de langue).
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get profileLanguageEnglishOption;

  /// SnackBar d'erreur générique si l'écriture SharedPreferences échoue au tap sur une option — même ton que les autres écrans Profil.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'enregistrer ce réglage. Réessaie.'**
  String get profileLanguageSaveError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
