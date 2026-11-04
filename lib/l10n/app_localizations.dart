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

  /// Nom de marque affiché sous le badge de `login_screen.dart` — identique dans les deux fichiers .arb (nom propre, jamais traduit).
  ///
  /// In fr, this message translates to:
  /// **'NEXUS JDR'**
  String get authLoginBrandTitle;

  /// Accroche sous le nom de marque, écran de connexion.
  ///
  /// In fr, this message translates to:
  /// **'Le registre des aventuriers'**
  String get authLoginTagline;

  /// Mention sous la carte de connexion, rappelant le compte partagé avec l'app web "Histoires".
  ///
  /// In fr, this message translates to:
  /// **'Même compte que l\'app Histoires'**
  String get authLoginSharedAccountNotice;

  /// Titre de la carte en mode inscription (`_AuthCard`).
  ///
  /// In fr, this message translates to:
  /// **'CRÉER UN COMPTE'**
  String get authLoginCardTitleSignUp;

  /// Titre de la carte en mode connexion (`_AuthCard`).
  ///
  /// In fr, this message translates to:
  /// **'ENTRER DANS LA TAVERNE'**
  String get authLoginCardTitleLogin;

  /// Libellé du champ e-mail du formulaire de connexion/inscription.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail'**
  String get authLoginEmailLabel;

  /// Placeholder du champ e-mail du formulaire de connexion/inscription.
  ///
  /// In fr, this message translates to:
  /// **'nom@exemple.com'**
  String get authLoginEmailHint;

  /// Libellé du champ mot de passe du formulaire de connexion/inscription.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get authLoginPasswordLabel;

  /// Placeholder (points masqués) du champ mot de passe.
  ///
  /// In fr, this message translates to:
  /// **'••••••••'**
  String get authLoginPasswordHint;

  /// Lien sous le champ mot de passe en mode connexion, ouvre `forgot_password_dialog.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get authLoginForgotPasswordLink;

  /// Libellé du champ de confirmation de mot de passe, mode inscription uniquement.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get authLoginConfirmPasswordLabel;

  /// Libellé du champ pseudo (optionnel), mode inscription uniquement.
  ///
  /// In fr, this message translates to:
  /// **'Pseudo'**
  String get authLoginPseudoLabel;

  /// Placeholder du champ pseudo, mode inscription uniquement.
  ///
  /// In fr, this message translates to:
  /// **'Comment veux-tu qu\'on t\'appelle ?'**
  String get authLoginPseudoHint;

  /// Texte d'aide sous le champ pseudo, mode inscription uniquement.
  ///
  /// In fr, this message translates to:
  /// **'Facultatif — tu pourras le changer plus tard dans ton profil.'**
  String get authLoginPseudoHelper;

  /// Libellé du `PrimaryButton` de soumission en mode inscription.
  ///
  /// In fr, this message translates to:
  /// **'Créer le compte'**
  String get authLoginSubmitSignUp;

  /// Libellé du `PrimaryButton` de soumission en mode connexion.
  ///
  /// In fr, this message translates to:
  /// **'Entrer'**
  String get authLoginSubmitLogin;

  /// Séparateur entre le formulaire e-mail/mot de passe et les boutons de connexion sociale.
  ///
  /// In fr, this message translates to:
  /// **'OU'**
  String get authLoginOrDivider;

  /// Libellé du bouton de connexion Apple (iOS/macOS uniquement, voir `appleSignInSupportedProvider`).
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Apple'**
  String get authLoginContinueWithApple;

  /// Libellé du bouton de connexion Google.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Google'**
  String get authLoginContinueWithGoogle;

  /// Texte précédant le lien de bascule, affiché en mode inscription (espace final volontaire avant le lien).
  ///
  /// In fr, this message translates to:
  /// **'Déjà un compte ? '**
  String get authLoginSwitchModePromptLogin;

  /// Texte précédant le lien de bascule, affiché en mode connexion (espace final volontaire avant le lien).
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ? '**
  String get authLoginSwitchModePromptSignUp;

  /// Lien de bascule vers le mode connexion, affiché en mode inscription.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get authLoginSwitchModeActionLogin;

  /// Lien de bascule vers le mode inscription, affiché en mode connexion.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get authLoginSwitchModeActionSignUp;

  /// Titre de l'état "vérifiez vos e-mails" après une inscription nécessitant une confirmation par e-mail.
  ///
  /// In fr, this message translates to:
  /// **'VÉRIFIEZ VOS E-MAILS'**
  String get authLoginSignUpConfirmationTitle;

  /// Corps de l'état "vérifiez vos e-mails", avec l'adresse saisie à l'inscription.
  ///
  /// In fr, this message translates to:
  /// **'Un e-mail de confirmation vient d\'être envoyé à {email}. Cliquez sur le lien qu\'il contient pour activer votre compte.'**
  String authLoginSignUpConfirmationBody(String email);

  /// Bouton de retour au formulaire depuis l'état "vérifiez vos e-mails".
  ///
  /// In fr, this message translates to:
  /// **'Retour à la connexion'**
  String get authLoginBackToLogin;

  /// Titre de la boîte de dialogue `forgot_password_dialog.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get authForgotPasswordTitle;

  /// Texte d'explication de la boîte de dialogue "Mot de passe oublié ?".
  ///
  /// In fr, this message translates to:
  /// **'Saisissez votre adresse e-mail : nous vous enverrons un lien pour définir un nouveau mot de passe.'**
  String get authForgotPasswordDescription;

  /// Placeholder du champ e-mail de la boîte de dialogue "Mot de passe oublié ?".
  ///
  /// In fr, this message translates to:
  /// **'nom@exemple.com'**
  String get authForgotPasswordEmailHint;

  /// Bouton d'annulation de la boîte de dialogue "Mot de passe oublié ?".
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get authForgotPasswordCancel;

  /// Bouton de soumission de la boîte de dialogue "Mot de passe oublié ?".
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le lien'**
  String get authForgotPasswordSubmit;

  /// SnackBar affiché après toute tentative d'envoi (succès ou échec confondus) — message volontairement neutre, voir la doc de classe de `showForgotPasswordDialog`.
  ///
  /// In fr, this message translates to:
  /// **'Si un compte existe avec cet email, un lien de réinitialisation vient d\'être envoyé.'**
  String get authForgotPasswordNeutralMessage;

  /// Message résolu depuis `AuthErrorCode.invalidCredentials` (`auth_error_mapper.dart`), affiché par `login_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail ou mot de passe incorrect.'**
  String get authErrorInvalidCredentials;

  /// Message résolu depuis `AuthErrorCode.emailAlreadyExists`.
  ///
  /// In fr, this message translates to:
  /// **'Un compte existe déjà avec cette adresse e-mail.'**
  String get authErrorEmailAlreadyExists;

  /// Message résolu depuis `AuthErrorCode.weakPassword` (erreur renvoyée par Supabase, distincte de la validation locale `authValidationPasswordTooShort`).
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins {minLength} caractères.'**
  String authErrorWeakPassword(int minLength);

  /// Message résolu depuis `AuthErrorCode.emailNotConfirmed`.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez votre adresse e-mail avant de vous connecter (vérifiez votre boîte de réception).'**
  String get authErrorEmailNotConfirmed;

  /// Message résolu depuis `AuthErrorCode.invalidEmail` (erreur renvoyée par Supabase, distincte de la validation locale `authValidationEmailInvalid`).
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail invalide.'**
  String get authErrorInvalidEmail;

  /// Message résolu depuis `AuthErrorCode.tooManyRequests`.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives. Réessayez dans quelques instants.'**
  String get authErrorTooManyRequests;

  /// Message résolu depuis `AuthErrorCode.network` (absence de réseau, voir `mapUnknownError`).
  ///
  /// In fr, this message translates to:
  /// **'Impossible de contacter le serveur. Vérifiez votre connexion internet et réessayez.'**
  String get authErrorNetwork;

  /// Message résolu depuis `AuthErrorCode.browserLaunchFailed` (`url_launcher` n'a pas pu ouvrir le navigateur système pour le flux OAuth Google, voir `SupabaseAuthRepository.signInWithGoogle`).
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir le navigateur pour continuer avec Google. Réessayez.'**
  String get authErrorBrowserLaunchFailed;

  /// Repli défensif affiché par `login_screen.dart` pour toute exception qui n'est pas une `AuthFailure`.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur inattendue est survenue. Réessayez.'**
  String get authErrorUnexpected;

  /// Erreur de validation locale, champ e-mail vide (`AuthValidators.email`).
  ///
  /// In fr, this message translates to:
  /// **'Saisissez votre adresse e-mail.'**
  String get authValidationEmailRequired;

  /// Erreur de validation locale, format d'e-mail invalide (`AuthValidators.email`).
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail invalide.'**
  String get authValidationEmailInvalid;

  /// Erreur de validation locale, champ mot de passe vide (`AuthValidators.password`).
  ///
  /// In fr, this message translates to:
  /// **'Saisissez votre mot de passe.'**
  String get authValidationPasswordRequired;

  /// Erreur de validation locale, mot de passe trop court (`AuthValidators.password`).
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins {minLength} caractères.'**
  String authValidationPasswordTooShort(int minLength);

  /// Erreur de validation locale, champ de confirmation vide (`AuthValidators.passwordConfirmation`).
  ///
  /// In fr, this message translates to:
  /// **'Confirmez votre mot de passe.'**
  String get authValidationPasswordConfirmationRequired;

  /// Erreur de validation locale, confirmation différente du mot de passe (`AuthValidators.passwordConfirmation`).
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas.'**
  String get authValidationPasswordConfirmationMismatch;
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
