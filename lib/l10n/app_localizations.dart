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

  /// Titre du bandeau bois (`WoodBackHeader`) de `profile_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'PROFIL'**
  String get profileMenuTitle;

  /// Libellé de la tuile de menu "Modifier le profil" de `profile_screen.dart`, pousse vers `/profile/edit`.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le profil'**
  String get profileMenuEditProfile;

  /// Libellé de la tuile de menu "Notifications" de `profile_screen.dart`, pousse vers `/profile/notifications`.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get profileMenuNotifications;

  /// Libellé de la tuile de menu "Confidentialité et données" de `profile_screen.dart`, pousse vers `/profile/privacy`.
  ///
  /// In fr, this message translates to:
  /// **'Confidentialité et données'**
  String get profileMenuPrivacy;

  /// Libellé de la tuile de menu "Aide et support" de `profile_screen.dart`, pousse vers `/profile/help`.
  ///
  /// In fr, this message translates to:
  /// **'Aide et support'**
  String get profileMenuHelp;

  /// Libellé du `DestructiveButton` "Se déconnecter" de `profile_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get profileMenuSignOut;

  /// Titre du bandeau bois de `profile_credits_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'CRÉDITS & LICENCES'**
  String get profileCreditsScreenTitle;

  /// Titre de la section "Contenu de jeu" de `profile_credits_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Contenu de jeu'**
  String get profileCreditsGameContentTitle;

  /// 1er paragraphe de la section "Contenu de jeu" de `profile_credits_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Le contenu de règles Donjons & Dragons 5e (races, classes, historiques, sorts, objets, monstres...) provient d\'Open5e et du System Reference Document (SRD 5.1/5.2) de Wizards of the Coast, sous licence Creative Commons Attribution 4.0 International (CC-BY 4.0).'**
  String get profileCreditsGameContentPara1;

  /// 2e paragraphe de la section "Contenu de jeu" de `profile_credits_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Donjons & Dragons, D&D et leurs logos sont des marques de Wizards of the Coast LLC. Wizards of the Coast n\'a ni produit, ni approuvé, ni autorisé cette application.'**
  String get profileCreditsGameContentPara2;

  /// Texte du bloc encadré `_LicenseNoticeBox` de `profile_credits_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Ce produit inclut des éléments du System Reference Document 5.1 et 5.2, disponibles sur dndbeyond.com/srd et open5e.com, sous licence Creative Commons Attribution 4.0 International (creativecommons.org/licenses/by/4.0/legalcode).'**
  String get profileCreditsLicenseNotice;

  /// Titre de la section "Polices" de `profile_credits_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Polices'**
  String get profileCreditsFontsTitle;

  /// Paragraphe de la section "Polices" de `profile_credits_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Press Start 2P (The Press Start 2P Project Authors) et Work Sans (The Work Sans Project Authors) sont distribuées sous licence SIL Open Font License, version 1.1 (scripts.sil.org/OFL), et embarquées telles quelles dans l\'application depuis le dépôt officiel Google Fonts (github.com/google/fonts).'**
  String get profileCreditsFontsPara1;

  /// Titre de la section "Bibliothèques open source" de `profile_credits_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Bibliothèques open source'**
  String get profileCreditsOpenSourceTitle;

  /// 1er paragraphe (liste énumérée) de la section "Bibliothèques open source" — noms de bibliothèques, jamais traduits.
  ///
  /// In fr, this message translates to:
  /// **'Flutter · Riverpod · Supabase Flutter · Drift · Freezed · go_router · image_picker · file_picker · connectivity_plus · package_info_plus · share_plus · app_settings · url_launcher · Firebase (Core, Messaging) · shared_preferences'**
  String get profileCreditsOpenSourcePara1;

  /// 2e paragraphe (clôture) de la section "Bibliothèques open source".
  ///
  /// In fr, this message translates to:
  /// **'Ainsi que les autres bibliothèques listées dans le fichier pubspec.yaml du projet, chacune sous sa licence open source d\'origine.'**
  String get profileCreditsOpenSourcePara2;

  /// Date de dernière mise à jour en pied de `profile_credits_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Dernière mise à jour : 14 octobre 2026'**
  String get profileCreditsLastUpdated;

  /// Titre du bandeau bois de `profile_delete_account_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'SUPPRIMER LE COMPTE'**
  String get profileDeleteAccountScreenTitle;

  /// Bandeau d'erreur hors-ligne de `profile_delete_account_screen.dart`, vérifié avant chaque appel réseau.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne : cette action n\'a pas pu être enregistrée. Réessayez une fois reconnecté.'**
  String get profileDeleteAccountOfflineMessage;

  /// Erreur générique de `profile_delete_account_screen.dart` (toute erreur autre qu'un mot de passe incorrect).
  ///
  /// In fr, this message translates to:
  /// **'Impossible de supprimer le compte. Réessayez.'**
  String get profileDeleteAccountGenericError;

  /// Erreur affichée sous le champ mot de passe de `profile_delete_account_screen.dart` quand `signInWithPassword` échoue.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe incorrect.'**
  String get profileDeleteAccountWrongPassword;

  /// Titre du bandeau d'avertissement de `profile_delete_account_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'ACTION IRRÉVERSIBLE'**
  String get profileDeleteAccountWarningTitle;

  /// Corps du bandeau d'avertissement "ACTION IRRÉVERSIBLE" de `profile_delete_account_screen.dart` — texte à ne pas modifier sans revalider auprès du chef de projet. Justification de son ampleur : le compte Supabase est unique et partagé avec l'app web "Histoires" ; supprimer le compte (`auth.admin.deleteUser`) cascade en base non seulement vers les personnages de cette app, mais aussi vers les histoires que ce compte a créées en tant que MJ côté web (`stories.user_id`) et ses entrées codex (`codex_entries.user_id`), toutes deux référençant `auth.users` en cascade — vérifié par le chantier backend qui a construit l'edge function `delete-account` (dépôt web `markdown-editor`). Ce texte doit refléter cette ampleur réelle, pas seulement les données propres à l'app mobile.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est irréversible. Elle supprimera définitivement :\n• Tous tes personnages et leurs portraits\n• Tes rattachements aux histoires que tu as rejointes\n• Toutes les histoires que tu as créées en tant que MJ sur l\'app Histoires (et l\'accès de tes joueurs à ces histoires)\n\nCette action ne peut pas être annulée.'**
  String get profileDeleteAccountWarningMessage;

  /// Libellé de la case à cocher de confirmation de `profile_delete_account_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Je comprends que cette action est définitive et que mes données ne pourront pas être récupérées.'**
  String get profileDeleteAccountConfirmationCheckboxLabel;

  /// Titre de la carte "CE QUI SERA SUPPRIMÉ" de `profile_delete_account_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'CE QUI SERA SUPPRIMÉ'**
  String get profileDeleteAccountWhatWillBeDeletedTitle;

  /// 1ère ligne de la carte "CE QUI SERA SUPPRIMÉ".
  ///
  /// In fr, this message translates to:
  /// **'Tous tes personnages et leurs fiches'**
  String get profileDeleteAccountChecklistCharacters;

  /// 2e ligne de la carte "CE QUI SERA SUPPRIMÉ".
  ///
  /// In fr, this message translates to:
  /// **'Ton accès aux histoires partagées'**
  String get profileDeleteAccountChecklistStories;

  /// 3e ligne de la carte "CE QUI SERA SUPPRIMÉ".
  ///
  /// In fr, this message translates to:
  /// **'Ton profil et tes préférences'**
  String get profileDeleteAccountChecklistProfile;

  /// Titre de section au-dessus du champ mot de passe de `profile_delete_account_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'SAISIS TON MOT DE PASSE POUR CONFIRMER'**
  String get profileDeleteAccountPasswordSectionTitle;

  /// Placeholder (points masqués) du champ mot de passe de `profile_delete_account_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'••••••••'**
  String get profileDeleteAccountPasswordHint;

  /// Libellé du bouton de suppression de `profile_delete_account_screen.dart` pendant l'appel réseau.
  ///
  /// In fr, this message translates to:
  /// **'Suppression en cours…'**
  String get profileDeleteAccountSubmitInProgress;

  /// Libellé du bouton de suppression de `profile_delete_account_screen.dart` au repos.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer définitivement'**
  String get profileDeleteAccountSubmitLabel;

  /// Libellé du bouton d'annulation de `profile_delete_account_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get profileDeleteAccountCancel;

  /// Titre du bandeau bois de `profile_edit_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'MODIFIER LE PROFIL'**
  String get profileEditScreenTitle;

  /// Libellé du champ pseudo de `profile_edit_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Pseudo'**
  String get profileEditPseudoLabel;

  /// Placeholder du champ pseudo de `profile_edit_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Comment veux-tu qu\'on t\'appelle ?'**
  String get profileEditPseudoHint;

  /// Libellé du champ e-mail (désactivé) de `profile_edit_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'E-mail'**
  String get profileEditEmailLabel;

  /// Texte d'aide sous le champ e-mail de `profile_edit_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'e-mail envoie un lien de confirmation à la nouvelle adresse.'**
  String get profileEditEmailChangeNotice;

  /// Libellé de la tuile "Changer le mot de passe" de `profile_edit_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Changer le mot de passe'**
  String get profileEditChangePassword;

  /// Libellé du bouton de soumission de `profile_edit_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get profileEditSaveButton;

  /// SnackBar de confirmation après sauvegarde du pseudo sur `profile_edit_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Pseudo mis à jour.'**
  String get profileEditSavedSnackbar;

  /// Bandeau d'erreur hors-ligne de `profile_edit_screen.dart`, vérifié avant l'appel réseau.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne : cette action n\'a pas pu être enregistrée. Réessayez une fois reconnecté.'**
  String get profileEditOfflineMessage;

  /// Erreur générique de `profile_edit_screen.dart` pour toute exception qui n'est pas une `AuthFailure`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'enregistrer les modifications. Réessayez.'**
  String get profileEditGenericError;

  /// Lien sous l'avatar de `profile_edit_screen.dart`, ouvre `showAvatarEditSheet`.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get profileEditTakePhoto;

  /// Lien sous l'avatar de `profile_edit_screen.dart`, ouvre `showAvatarEditSheet`.
  ///
  /// In fr, this message translates to:
  /// **'Choisir dans la galerie'**
  String get profileEditChoosePhoto;

  /// Titre du bandeau bois de `profile_faq_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'QUESTIONS FRÉQUENTES'**
  String get profileFaqScreenTitle;

  /// Question 1 de `profile_faq_screen.dart` (`_faqItems`, id 1).
  ///
  /// In fr, this message translates to:
  /// **'Comment importer un personnage depuis aidedd.org ?'**
  String get profileFaqQuestion1;

  /// Réponse 1 de `profile_faq_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Sur aidedd.org, ouvre la fiche de ton personnage puis utilise son export XML (bouton d\'export du site). Dans Nexus JDR, va dans Personnages > « + » > Importer un fichier XML, puis sélectionne ce fichier. L\'app pré-remplit automatiquement la fiche (caractéristiques, classe, race, sorts, inventaire...) et te montre un écran de vérification avant de l\'enregistrer, avec les champs qu\'elle n\'a pas reconnus signalés d\'une pastille pour que tu les complètes toi-même.'**
  String get profileFaqAnswer1;

  /// Question 2 de `profile_faq_screen.dart` (`_faqItems`, id 2).
  ///
  /// In fr, this message translates to:
  /// **'Comment rejoindre l\'histoire de mon MJ ?'**
  String get profileFaqQuestion2;

  /// Réponse 2 de `profile_faq_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Ton MJ te partage un code d\'invitation ou un lien depuis l\'app « Histoires ». Dans Nexus JDR, ouvre ce lien ou saisis le code dans l\'écran « Rejoindre une histoire », puis choisis le personnage à rattacher (un existant ou un nouveau). Le personnage reste ensuite synchronisé avec cette histoire tant que le MJ ne retire pas l\'accès.'**
  String get profileFaqAnswer2;

  /// Question 3 de `profile_faq_screen.dart` (`_faqItems`, id 3).
  ///
  /// In fr, this message translates to:
  /// **'Mes personnages sont-ils sauvegardés hors ligne ?'**
  String get profileFaqQuestion3;

  /// Réponse 3 de `profile_faq_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Oui. Tous tes personnages restent consultables et modifiables sans connexion : les changements (points de vie, XP, inventaire...) sont mis en file d\'attente sur ton appareil puis synchronisés automatiquement avec le serveur dès que la connexion revient. Aucune donnée n\'est perdue en cas de coupure réseau.'**
  String get profileFaqAnswer3;

  /// Question 4 de `profile_faq_screen.dart` (`_faqItems`, id 4).
  ///
  /// In fr, this message translates to:
  /// **'Comment fonctionne la montée de niveau ?'**
  String get profileFaqQuestion4;

  /// Réponse 4 de `profile_faq_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Depuis la fiche de personnage, l\'écran « Monter de niveau » te guide pas à pas : nouveaux points de vie, capacités de classe débloquées, nouveaux emplacements de sorts si ta classe en lance, et augmentation de caractéristique si le niveau l\'autorise. Rien n\'est appliqué avant que tu valides l\'écran récapitulatif.'**
  String get profileFaqAnswer4;

  /// Question 5 de `profile_faq_screen.dart` (`_faqItems`, id 5).
  ///
  /// In fr, this message translates to:
  /// **'Comment changer le portrait de mon personnage ?'**
  String get profileFaqQuestion5;

  /// Réponse 5 de `profile_faq_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Ouvre la fiche du personnage, appuie sur son portrait puis choisis « Prendre une photo » ou « Choisir dans la galerie ». Tu peux ensuite recadrer l\'image avant de l\'enregistrer — elle est stockée de façon sécurisée et associée uniquement à ce personnage.'**
  String get profileFaqAnswer5;

  /// Question 6 de `profile_faq_screen.dart` (`_faqItems`, id 6).
  ///
  /// In fr, this message translates to:
  /// **'Comment supprimer mon compte ?'**
  String get profileFaqQuestion6;

  /// Réponse 6 de `profile_faq_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Depuis Profil > Confidentialité et données > Supprimer mon compte, en bas de l\'écran (zone dangereuse). Cette action est irréversible : elle supprime définitivement tes personnages, leurs portraits et tous les rattachements à des histoires. Tu peux exporter tes données avant de confirmer.'**
  String get profileFaqAnswer6;

  /// Titre du bandeau bois de `profile_help_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'AIDE ET SUPPORT'**
  String get profileHelpScreenTitle;

  /// Titre de la 1ère section de `profile_help_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'QUESTIONS FRÉQUENTES'**
  String get profileHelpSectionFaq;

  /// Libellé de la 1ère tuile FAQ de `profile_help_screen.dart` (pousse `?question=1`) — texte distinct de `profileFaqQuestion1`, propre à cette tuile raccourcie.
  ///
  /// In fr, this message translates to:
  /// **'Comment importer un personnage aidedd.org ?'**
  String get profileHelpFaqQuestion1;

  /// Libellé de la 2e tuile FAQ de `profile_help_screen.dart` (pousse `?question=2`).
  ///
  /// In fr, this message translates to:
  /// **'Comment rejoindre l\'histoire de mon MJ ?'**
  String get profileHelpFaqQuestion2;

  /// Libellé de la 3e tuile FAQ de `profile_help_screen.dart` (pousse `?question=3`).
  ///
  /// In fr, this message translates to:
  /// **'Mes personnages sont-ils sauvegardés hors ligne ?'**
  String get profileHelpFaqQuestion3;

  /// Libellé de la 4e tuile FAQ de `profile_help_screen.dart` (pousse `/profile/help/faq` sans pré-ouverture).
  ///
  /// In fr, this message translates to:
  /// **'Voir toutes les questions'**
  String get profileHelpFaqSeeAll;

  /// Titre de la 2e section de `profile_help_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'NOUS CONTACTER'**
  String get profileHelpSectionContact;

  /// Libellé de la tuile "Contacter le support" de `profile_help_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Contacter le support'**
  String get profileHelpContactSupport;

  /// Libellé de la tuile "Signaler un bug" de `profile_help_screen.dart`, ouvre `showReportBugSheet`.
  ///
  /// In fr, this message translates to:
  /// **'Signaler un bug'**
  String get profileHelpReportBug;

  /// Note sous la section "NOUS CONTACTER" de `profile_help_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Réponse sous 48h en semaine. Un aperçu des infos techniques de l\'appareil est joint automatiquement.'**
  String get profileHelpContactFooterNote;

  /// Titre de la 3e section de `profile_help_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'À PROPOS'**
  String get profileHelpSectionAbout;

  /// Libellé de la tuile "Revoir la présentation de l'app" de `profile_help_screen.dart`, pousse `/onboarding`.
  ///
  /// In fr, this message translates to:
  /// **'Revoir la présentation de l\'app'**
  String get profileHelpReplayOnboarding;

  /// Libellé de la tuile "Mentions légales / CGU" de `profile_help_screen.dart`, pousse `/profile/help/legal`.
  ///
  /// In fr, this message translates to:
  /// **'Mentions légales / CGU'**
  String get profileHelpLegalMentions;

  /// Libellé de la tuile "Crédits & licences" de `profile_help_screen.dart`, pousse `/profile/help/credits`.
  ///
  /// In fr, this message translates to:
  /// **'Crédits & licences'**
  String get profileHelpCredits;

  /// Note sous la section "À PROPOS" de `profile_help_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Contenu D&D 5e sous licence Open5e / SRD. Voir les crédits complets pour le détail des sources.'**
  String get profileHelpAboutFooterNote;

  /// Pied de page de `profile_help_screen.dart` une fois `packageInfoProvider` résolu.
  ///
  /// In fr, this message translates to:
  /// **'Nexus JDR — Personnages · v{version}'**
  String profileHelpFooterVersionWithNumber(String version);

  /// Pied de page de `profile_help_screen.dart` pendant que `packageInfoProvider` résout (ou en cas d'échec).
  ///
  /// In fr, this message translates to:
  /// **'Nexus JDR — Personnages'**
  String get profileHelpFooterVersionWithoutNumber;

  /// SnackBar affiché par `profile_help_screen.dart` quand `canLaunchUrl` échoue pour "Contacter le support".
  ///
  /// In fr, this message translates to:
  /// **'Aucune application e-mail n\'est configurée sur cet appareil.'**
  String get profileHelpNoMailApp;

  /// SnackBar générique affiché par `profile_help_screen.dart` pour toute exception plateforme pendant l'ouverture du client e-mail.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir l\'application e-mail. Réessayez.'**
  String get profileHelpGenericMailError;

  /// Titre du bandeau bois de `profile_legal_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'MENTIONS LÉGALES / CGU'**
  String get profileLegalScreenTitle;

  /// Titre de la section "Éditeur" de `profile_legal_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Éditeur'**
  String get profileLegalEditorTitle;

  /// 1er paragraphe de la section "Éditeur".
  ///
  /// In fr, this message translates to:
  /// **'Matthias Benoit'**
  String get profileLegalEditorPara1;

  /// 2e paragraphe de la section "Éditeur".
  ///
  /// In fr, this message translates to:
  /// **'Contact : support@nexus-jdr.app'**
  String get profileLegalEditorPara2;

  /// Titre de la section "Hébergement" de `profile_legal_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Hébergement'**
  String get profileLegalHostingTitle;

  /// Paragraphe de la section "Hébergement".
  ///
  /// In fr, this message translates to:
  /// **'L\'application et ses données sont hébergées par Supabase (base de données, authentification, stockage des fichiers).'**
  String get profileLegalHostingPara1;

  /// Titre de la section "Objet de l'application" de `profile_legal_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Objet de l\'application'**
  String get profileLegalPurposeTitle;

  /// Paragraphe de la section "Objet de l'application".
  ///
  /// In fr, this message translates to:
  /// **'Nexus JDR — Personnages permet de créer, importer et gérer des personnages de Donjons & Dragons 5e, seul ou synchronisé avec l\'app « Histoires » utilisée par ton Maître du Jeu.'**
  String get profileLegalPurposePara1;

  /// Titre de la section "Conditions d'utilisation" de `profile_legal_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d\'utilisation'**
  String get profileLegalTermsTitle;

  /// Paragraphe de la section "Conditions d'utilisation".
  ///
  /// In fr, this message translates to:
  /// **'L\'usage de l\'application nécessite un compte. Tu es responsable de l\'exactitude des informations que tu y renseignes et de la confidentialité de tes identifiants. L\'éditeur se réserve le droit de suspendre un compte en cas d\'usage abusif.'**
  String get profileLegalTermsPara1;

  /// Titre de la section "Propriété intellectuelle" de `profile_legal_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Propriété intellectuelle'**
  String get profileLegalIntellectualPropertyTitle;

  /// Paragraphe de la section "Propriété intellectuelle".
  ///
  /// In fr, this message translates to:
  /// **'Le contenu de règles Donjons & Dragons 5e (races, classes, sorts, objets...) provient d\'Open5e et du System Reference Document (SRD), sous licence Creative Commons Attribution 4.0 (CC-BY 4.0) — voir « Crédits & licences » pour le détail. Le reste de l\'application (code, design, marque « Nexus JDR ») appartient à son éditeur.'**
  String get profileLegalIntellectualPropertyPara1;

  /// Titre de la section "Résiliation" de `profile_legal_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Résiliation'**
  String get profileLegalTerminationTitle;

  /// Paragraphe de la section "Résiliation".
  ///
  /// In fr, this message translates to:
  /// **'Tu peux supprimer ton compte à tout moment depuis Profil > Confidentialité et données > Supprimer mon compte.'**
  String get profileLegalTerminationPara1;

  /// Titre de la section "Droit applicable" de `profile_legal_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Droit applicable'**
  String get profileLegalGoverningLawTitle;

  /// Paragraphe de la section "Droit applicable".
  ///
  /// In fr, this message translates to:
  /// **'Ces mentions sont soumises au droit français.'**
  String get profileLegalGoverningLawPara1;

  /// Date de dernière mise à jour en pied de `profile_legal_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Dernière mise à jour : 25 septembre 2026'**
  String get profileLegalLastUpdated;

  /// Titre du bandeau bois de `profile_notifications_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'NOTIFICATIONS'**
  String get profileNotificationsScreenTitle;

  /// `AlertBanner` affiché quand la permission OS de notification est refusée.
  ///
  /// In fr, this message translates to:
  /// **'Les notifications sont désactivées au niveau du téléphone. Active-les dans les réglages de l\'appareil pour les recevoir.'**
  String get profileNotificationsOsPermissionDenied;

  /// Titre de la rangée bascule principale de `profile_notifications_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Notifications push'**
  String get profileNotificationsPushToggle;

  /// Titre de section "DÉCLENCHEURS" de `profile_notifications_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'DÉCLENCHEURS'**
  String get profileNotificationsSectionTriggers;

  /// Titre de la 1ère rangée "DÉCLENCHEURS".
  ///
  /// In fr, this message translates to:
  /// **'Repos long non pris depuis longtemps'**
  String get profileNotificationsRestReminder;

  /// Titre de la 2e rangée "DÉCLENCHEURS".
  ///
  /// In fr, this message translates to:
  /// **'Accès retiré ou modifié par le MJ'**
  String get profileNotificationsAccessRevoked;

  /// Titre de la 3e rangée "DÉCLENCHEURS".
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle mise à jour disponible'**
  String get profileNotificationsNewVersion;

  /// Titre de section "E-MAIL" de `profile_notifications_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'E-MAIL'**
  String get profileNotificationsSectionEmail;

  /// Titre de la rangée "E-MAIL" de `profile_notifications_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir un résumé par e-mail'**
  String get profileNotificationsEmailDigest;

  /// Sous-titre de la rangée "E-MAIL" de `profile_notifications_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Résumé hebdomadaire des personnages qui ont progressé.'**
  String get profileNotificationsEmailDigestSubtitle;

  /// Note en pied de `profile_notifications_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Les autorisations système (notifications) se gèrent aussi depuis les réglages du téléphone.'**
  String get profileNotificationsSystemNote;

  /// SnackBar générique d'échec d'écriture de `profile_notifications_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'enregistrer ce réglage. Réessaie.'**
  String get profileNotificationsGenericError;

  /// Message de l'état d'erreur de chargement de `profile_notifications_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger tes préférences de notifications. Réessaie.'**
  String get profileNotificationsLoadError;

  /// Libellé du bouton "Réessayer" de l'état d'erreur de `profile_notifications_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get profileNotificationsRetry;

  /// Titre du bandeau bois de `profile_privacy_policy_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'POLITIQUE DE CONFIDENTIALITÉ'**
  String get profilePrivacyPolicyScreenTitle;

  /// Titre de la section "Introduction" de `profile_privacy_policy_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Introduction'**
  String get profilePrivacyPolicyIntroductionTitle;

  /// Paragraphe de la section "Introduction".
  ///
  /// In fr, this message translates to:
  /// **'Cette politique explique quelles données Nexus JDR collecte, pourquoi, avec qui elles sont partagées, et comment tu peux y accéder, les exporter ou les supprimer.'**
  String get profilePrivacyPolicyIntroductionPara1;

  /// Titre de la section 1 de `profile_privacy_policy_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'1. Qui est responsable de tes données'**
  String get profilePrivacyPolicySection1Title;

  /// 1er paragraphe de la section 1.
  ///
  /// In fr, this message translates to:
  /// **'Cette politique s\'applique à l\'application mobile Nexus JDR — Personnages (Android) et à l\'application web Nexus JDR « Histoires » (nexus-jdr.app), qui partagent le même compte.'**
  String get profilePrivacyPolicySection1Para1;

  /// 2e paragraphe de la section 1.
  ///
  /// In fr, this message translates to:
  /// **'Responsable du traitement : Matthias Benoit, éditeur de Nexus JDR. Contact : support@nexus-jdr.app.'**
  String get profilePrivacyPolicySection1Para2;

  /// Titre de la section 2 de `profile_privacy_policy_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'2. Données collectées'**
  String get profilePrivacyPolicySection2Title;

  /// 1er paragraphe (liste à puces) de la section 2.
  ///
  /// In fr, this message translates to:
  /// **'• Compte : adresse e-mail et mot de passe (le mot de passe est stocké chiffré par notre service d\'authentification, nous ne le voyons jamais), pseudo affiché et avatar facultatif.'**
  String get profilePrivacyPolicySection2Para1;

  /// 2e paragraphe (liste à puces) de la section 2.
  ///
  /// In fr, this message translates to:
  /// **'• Contenu de jeu : tout ce que tu crées — personnages (caractéristiques, compétences, sorts, inventaire, apparence, histoire), journal, notes de groupe, groupes et histoires rejoints, fichiers de personnage que tu importes.'**
  String get profilePrivacyPolicySection2Para2;

  /// 3e paragraphe (liste à puces) de la section 2.
  ///
  /// In fr, this message translates to:
  /// **'• Photos : portrait de personnage, galerie et avatar, uniquement les images que tu choisis de prendre avec l\'appareil photo, d\'importer depuis ta galerie ou depuis une adresse web.'**
  String get profilePrivacyPolicySection2Para3;

  /// 4e paragraphe (liste à puces) de la section 2.
  ///
  /// In fr, this message translates to:
  /// **'• Dictée vocale (notes de groupe, facultative) : le micro n\'est utilisé que pendant que tu dictes. La reconnaissance vocale est assurée par le service de ton téléphone (par exemple Google sur Android) ; nous ne recevons que le texte obtenu, jamais l\'enregistrement audio.'**
  String get profilePrivacyPolicySection2Para4;

  /// 5e paragraphe (liste à puces) de la section 2.
  ///
  /// In fr, this message translates to:
  /// **'• Notifications : un identifiant technique de ton appareil (jeton de notification) et tes préférences de notification, pour t\'envoyer les rappels et nouvelles de tes groupes.'**
  String get profilePrivacyPolicySection2Para5;

  /// 6e paragraphe (liste à puces) de la section 2.
  ///
  /// In fr, this message translates to:
  /// **'• Statistiques d\'utilisation : écrans consultés et actions réalisées dans l\'app, accompagnés d\'informations techniques (modèle d\'appareil, système, version de l\'app) et d\'un identifiant pseudonyme généré par l\'outil de mesure. Ces statistiques ne sont pas rattachées à ton compte ni à ton adresse e-mail.'**
  String get profilePrivacyPolicySection2Para6;

  /// 7e paragraphe (liste à puces) de la section 2.
  ///
  /// In fr, this message translates to:
  /// **'• Signalements de bug : titre, description et gravité que tu saisis, version de l\'app, plateforme et, si tu le choisis, le personnage concerné.'**
  String get profilePrivacyPolicySection2Para7;

  /// Titre de la section 3 de `profile_privacy_policy_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'3. Ce que nous ne collectons pas'**
  String get profilePrivacyPolicySection3Title;

  /// Paragraphe de la section 3.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée de localisation, aucun contact, aucune donnée de paiement. Aucune publicité n\'est affichée et aucune donnée n\'est vendue.'**
  String get profilePrivacyPolicySection3Para1;

  /// Titre de la section 4 de `profile_privacy_policy_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'4. Pourquoi nous utilisons ces données'**
  String get profilePrivacyPolicySection4Title;

  /// 1er paragraphe (liste à puces) de la section 4.
  ///
  /// In fr, this message translates to:
  /// **'• Fournir le service (compte, fiches, groupes, synchronisation avec ton MJ, photos, notifications que tu actives) : c’est nécessaire à l\'exécution du service que tu utilises.'**
  String get profilePrivacyPolicySection4Para1;

  /// 2e paragraphe (liste à puces) de la section 4.
  ///
  /// In fr, this message translates to:
  /// **'• Améliorer l\'app (statistiques d\'utilisation) : intérêt légitime à comprendre quelles fonctionnalités sont utilisées. Tu peux t\'y opposer à tout moment dans Profil > Confidentialité et données > Partager mes données d\'usage.'**
  String get profilePrivacyPolicySection4Para2;

  /// 3e paragraphe (liste à puces) de la section 4.
  ///
  /// In fr, this message translates to:
  /// **'• Corriger les bugs que tu nous signales.'**
  String get profilePrivacyPolicySection4Para3;

  /// Titre de la section 5 de `profile_privacy_policy_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'5. Avec qui tes données sont partagées'**
  String get profilePrivacyPolicySection5Title;

  /// 1er paragraphe de la section 5.
  ///
  /// In fr, this message translates to:
  /// **'Avec d\'autres utilisateurs, uniquement à ton initiative : le MJ et les membres des histoires ou groupes que tu rejoins voient les personnages que tu y rattaches ; si tu crées un lien de partage de fiche, toute personne disposant de ce lien peut consulter la fiche en lecture seule, jusqu\'à ce que tu le désactives.'**
  String get profilePrivacyPolicySection5Para1;

  /// 2e paragraphe de la section 5.
  ///
  /// In fr, this message translates to:
  /// **'Avec nos prestataires techniques, qui traitent les données pour notre compte :'**
  String get profilePrivacyPolicySection5Para2;

  /// 3e paragraphe (liste à puces) de la section 5.
  ///
  /// In fr, this message translates to:
  /// **'• Supabase — hébergement de la base de données, de l\'authentification et des photos.'**
  String get profilePrivacyPolicySection5Para3;

  /// 4e paragraphe (liste à puces) de la section 5.
  ///
  /// In fr, this message translates to:
  /// **'• Google Firebase — envoi des notifications (Firebase Cloud Messaging) et statistiques d\'utilisation (Firebase Analytics).'**
  String get profilePrivacyPolicySection5Para4;

  /// 5e paragraphe (liste à puces) de la section 5.
  ///
  /// In fr, this message translates to:
  /// **'• Google Firebase Crashlytics — rapports de plantage (traces techniques de l\'erreur et informations sur ton appareil), collectés systématiquement pour maintenir la stabilité de l\'app. Contrairement aux statistiques d\'utilisation (Firebase Analytics/PostHog, voir ci-dessus), ce recueil ne peut pas être désactivé depuis l\'app : notre intérêt légitime à diagnostiquer et corriger les plantages de l\'app prévaut ici.'**
  String get profilePrivacyPolicySection5Para5;

  /// 6e paragraphe (liste à puces) de la section 5.
  ///
  /// In fr, this message translates to:
  /// **'• PostHog (hébergement dans l\'Union européenne) — statistiques d\'utilisation.'**
  String get profilePrivacyPolicySection5Para6;

  /// 7e paragraphe (liste à puces) de la section 5.
  ///
  /// In fr, this message translates to:
  /// **'• GitHub — suivi des bugs signalés : le contenu d\'un signalement (titre, description, gravité, version, plateforme) est publié comme ticket dans un dépôt public, sans ton adresse e-mail ni ton nom. N\'y indique donc aucune information personnelle.'**
  String get profilePrivacyPolicySection5Para7;

  /// 8e paragraphe (liste à puces) de la section 5.
  ///
  /// In fr, this message translates to:
  /// **'• Resend — envoi des e-mails transactionnels (confirmation de compte, réinitialisation de mot de passe).'**
  String get profilePrivacyPolicySection5Para8;

  /// 9e paragraphe (liste à puces) de la section 5.
  ///
  /// In fr, this message translates to:
  /// **'• Vercel — hébergement du site nexus-jdr.app.'**
  String get profilePrivacyPolicySection5Para9;

  /// 10e paragraphe (clôture) de la section 5.
  ///
  /// In fr, this message translates to:
  /// **'Certains de ces prestataires peuvent traiter des données hors de l\'Union européenne ; ces transferts sont encadrés par les garanties prévues par le RGPD (clauses contractuelles types de la Commission européenne ou cadre de protection des données UE–États-Unis).'**
  String get profilePrivacyPolicySection5Para10;

  /// Titre de la section 6 de `profile_privacy_policy_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'6. Durée de conservation'**
  String get profilePrivacyPolicySection6Title;

  /// 1er paragraphe (liste à puces) de la section 6.
  ///
  /// In fr, this message translates to:
  /// **'• Compte, contenu de jeu et photos : tant que ton compte existe. Ils sont supprimés définitivement dès que tu supprimes ton compte.'**
  String get profilePrivacyPolicySection6Para1;

  /// 2e paragraphe (liste à puces) de la section 6.
  ///
  /// In fr, this message translates to:
  /// **'• Statistiques d\'utilisation : conservées sous forme pseudonyme, sans lien avec ton compte, pendant la durée de conservation paramétrée dans les outils de mesure.'**
  String get profilePrivacyPolicySection6Para2;

  /// 3e paragraphe (liste à puces) de la section 6.
  ///
  /// In fr, this message translates to:
  /// **'• Signalements de bug : le temps nécessaire à leur traitement.'**
  String get profilePrivacyPolicySection6Para3;

  /// Titre de la section 7 de `profile_privacy_policy_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'7. Tes droits'**
  String get profilePrivacyPolicySection7Title;

  /// 1er paragraphe de la section 7.
  ///
  /// In fr, this message translates to:
  /// **'Conformément au RGPD, tu disposes d\'un droit d\'accès, de rectification, d\'effacement, de portabilité, d\'opposition et de limitation du traitement. Directement depuis l\'app :'**
  String get profilePrivacyPolicySection7Para1;

  /// 2e paragraphe (liste à puces) de la section 7.
  ///
  /// In fr, this message translates to:
  /// **'• Exporter tes données : Profil > Confidentialité et données > Exporter mes données.'**
  String get profilePrivacyPolicySection7Para2;

  /// 3e paragraphe (liste à puces) de la section 7.
  ///
  /// In fr, this message translates to:
  /// **'• Supprimer ton compte et toutes tes données : Profil > Confidentialité et données > Supprimer mon compte.'**
  String get profilePrivacyPolicySection7Para3;

  /// 4e paragraphe (liste à puces) de la section 7.
  ///
  /// In fr, this message translates to:
  /// **'• Désactiver les statistiques d\'utilisation : Profil > Confidentialité et données.'**
  String get profilePrivacyPolicySection7Para4;

  /// 5e paragraphe (liste à puces) de la section 7.
  ///
  /// In fr, this message translates to:
  /// **'• Désactiver les notifications : dans les réglages de notification de l\'app ou de ton téléphone.'**
  String get profilePrivacyPolicySection7Para5;

  /// 6e paragraphe (clôture) de la section 7.
  ///
  /// In fr, this message translates to:
  /// **'Pour toute autre demande, écris à support@nexus-jdr.app. Tu peux aussi introduire une réclamation auprès de la CNIL (www.cnil.fr).'**
  String get profilePrivacyPolicySection7Para6;

  /// Titre de la section 8 de `profile_privacy_policy_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'8. Sécurité'**
  String get profilePrivacyPolicySection8Title;

  /// Paragraphe de la section 8.
  ///
  /// In fr, this message translates to:
  /// **'Les échanges avec nos serveurs sont chiffrés (HTTPS). L’accès à tes données est protégé par l\'authentification de ton compte et par des règles d\'accès qui empêchent tout autre utilisateur de lire ou modifier ce que tu ne partages pas.'**
  String get profilePrivacyPolicySection8Para1;

  /// Titre de la section 9 de `profile_privacy_policy_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'9. Modifications de cette politique'**
  String get profilePrivacyPolicySection9Title;

  /// Paragraphe de la section 9.
  ///
  /// In fr, this message translates to:
  /// **'Cette politique peut évoluer avec l\'application. La date de dernière mise à jour figure en bas de cet écran ; en cas de changement important, tu en seras informé dans l\'app.'**
  String get profilePrivacyPolicySection9Para1;

  /// Date de dernière mise à jour en pied de `profile_privacy_policy_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Dernière mise à jour : 1er novembre 2026'**
  String get profilePrivacyPolicyLastUpdated;

  /// Titre du bandeau bois de `profile_privacy_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'CONFIDENTIALITÉ'**
  String get profilePrivacyScreenTitle;

  /// Titre de section "MES DONNÉES" de `profile_privacy_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'MES DONNÉES'**
  String get profilePrivacyDataSectionTitle;

  /// Libellé de la tuile "Exporter mes données" de `profile_privacy_screen.dart`, ouvre `showExportDataSheet`.
  ///
  /// In fr, this message translates to:
  /// **'Exporter mes données'**
  String get profilePrivacyExportData;

  /// Libellé de la tuile "Politique de confidentialité" de `profile_privacy_screen.dart`, pousse `/profile/privacy/policy`.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get profilePrivacyPolicyLink;

  /// Libellé de la tuile "Autorisations de l'appareil" de `profile_privacy_screen.dart`, ouvre `showDevicePermissionsSheet`.
  ///
  /// In fr, this message translates to:
  /// **'Autorisations de l\'appareil'**
  String get profilePrivacyDevicePermissions;

  /// Note sous la carte "MES DONNÉES" de `profile_privacy_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'L\'export contient ton profil, tes personnages (leur inventaire, leurs sorts et leur historique), tes groupes et tes notes de groupe (JSON, proposé au partage depuis ton appareil).'**
  String get profilePrivacyExportNote;

  /// Titre de la rangée bascule "Partager mes données d'usage" de `profile_privacy_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Partager mes données d\'usage'**
  String get profilePrivacyShareUsageData;

  /// Sous-titre de la rangée bascule "Partager mes données d'usage".
  ///
  /// In fr, this message translates to:
  /// **'Statistiques d\'utilisation anonymes (Firebase Analytics, PostHog), pour améliorer l\'app. Désactivable à tout moment — les rapports de plantage restent toujours actifs pour la stabilité de l\'app (voir Politique de confidentialité).'**
  String get profilePrivacyShareUsageDataSubtitle;

  /// Titre de section "ZONE DANGEREUSE" de `profile_privacy_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'ZONE DANGEREUSE'**
  String get profilePrivacyDangerZoneTitle;

  /// Libellé de la tuile destructrice "Supprimer mon compte" de `profile_privacy_screen.dart`, pousse `/profile/privacy/delete-account`.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon compte'**
  String get profilePrivacyDeleteAccount;

  /// Titre du bandeau bois de `widgets/avatar_crop_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'RECADRAGE'**
  String get profileAvatarCropScreenTitle;

  /// Texte d'aide sous le cadre de recadrage de `widgets/avatar_crop_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Pincez pour zoomer, glissez pour cadrer.'**
  String get profileAvatarCropInstructions;

  /// Libellé du bouton d'annulation de `widgets/avatar_crop_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get profileAvatarCropCancel;

  /// Libellé du bouton de validation de `widgets/avatar_crop_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get profileAvatarCropConfirm;

  /// Bandeau d'erreur hors-ligne de `widgets/avatar_crop_screen.dart`, vérifié avant l'appel réseau.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne : cette action n\'a pas pu être enregistrée. Réessayez une fois reconnecté.'**
  String get profileAvatarCropOfflineMessage;

  /// Erreur générique de `widgets/avatar_crop_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de mettre à jour l\'avatar. Réessayez.'**
  String get profileAvatarCropGenericError;

  /// Message de l'`AuthFailure` levée quand `RenderRepaintBoundary.toImage().toByteData()` renvoie `null` dans `widgets/avatar_crop_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de préparer l\'image. Réessayez.'**
  String get profileAvatarCropPrepareImageError;

  /// Libellé de la ligne "Prendre une photo" de la sheet `widgets/avatar_edit_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get profileAvatarEditTakePhoto;

  /// Libellé de la ligne "Choisir dans la galerie" de la sheet `widgets/avatar_edit_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Choisir dans la galerie'**
  String get profileAvatarEditChooseGallery;

  /// Libellé de la ligne "Retirer la photo" de la sheet `widgets/avatar_edit_sheet.dart` (affichée seulement si un avatar existe déjà).
  ///
  /// In fr, this message translates to:
  /// **'Retirer la photo'**
  String get profileAvatarEditRemovePhoto;

  /// SnackBar de confirmation après suppression de l'avatar dans `widgets/avatar_edit_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Photo retirée.'**
  String get profileAvatarEditRemovedSnackbar;

  /// SnackBar d'erreur générique de `widgets/avatar_edit_sheet.dart` pour toute exception qui n'est pas une `AuthFailure`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de mettre à jour l\'avatar. Réessayez.'**
  String get profileAvatarEditGenericError;

  /// Titre du dialogue de confirmation `showRemoveAvatarConfirmationDialog` de `widgets/avatar_edit_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la photo ?'**
  String get profileAvatarEditRemoveConfirmTitle;

  /// Bouton d'annulation du dialogue de confirmation `showRemoveAvatarConfirmationDialog`.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get profileAvatarEditRemoveConfirmCancel;

  /// Bouton de confirmation du dialogue `showRemoveAvatarConfirmationDialog`.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get profileAvatarEditRemoveConfirmAction;

  /// Titre de la sheet `widgets/change_email_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'ADRESSE EMAIL'**
  String get profileChangeEmailTitle;

  /// `InfoBanner` permanent de la sheet `widgets/change_email_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Un email de confirmation sera envoyé à cette adresse. Le changement ne sera effectif qu\'après confirmation.'**
  String get profileChangeEmailInfoBanner;

  /// Libellé du champ de la sheet `widgets/change_email_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'NOUVELLE ADRESSE EMAIL'**
  String get profileChangeEmailFieldLabel;

  /// Placeholder du champ e-mail de la sheet `widgets/change_email_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'nom@exemple.com'**
  String get profileChangeEmailHint;

  /// Rappel de l'adresse e-mail actuelle sous le champ de la sheet `widgets/change_email_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Adresse actuelle : {email}'**
  String profileChangeEmailCurrentAddress(String email);

  /// Bouton d'annulation de la sheet `widgets/change_email_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get profileChangeEmailCancel;

  /// Bouton de soumission de la sheet `widgets/change_email_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get profileChangeEmailSave;

  /// SnackBar affiché une fois la sheet `widgets/change_email_sheet.dart` refermée avec succès.
  ///
  /// In fr, this message translates to:
  /// **'Email de confirmation envoyé. Vérifie ta boîte de réception pour finaliser le changement.'**
  String get profileChangeEmailConfirmationSnackbar;

  /// Bandeau d'erreur hors-ligne de la sheet `widgets/change_email_sheet.dart`, vérifié avant l'appel réseau.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne : cette action n\'a pas pu être enregistrée. Réessayez une fois reconnecté.'**
  String get profileChangeEmailOfflineMessage;

  /// Erreur générique de la sheet `widgets/change_email_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'envoyer le nouvel email. Réessayez.'**
  String get profileChangeEmailGenericError;

  /// Titre de la sheet `widgets/change_password_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'MOT DE PASSE'**
  String get profileChangePasswordTitle;

  /// Libellé du champ "nouveau mot de passe" de `widgets/change_password_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'NOUVEAU MOT DE PASSE'**
  String get profileChangePasswordNewLabel;

  /// Placeholder (points masqués) des champs mot de passe de `widgets/change_password_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'••••••••'**
  String get profileChangePasswordHint;

  /// Libellé du champ de confirmation de `widgets/change_password_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'CONFIRMER LE MOT DE PASSE'**
  String get profileChangePasswordConfirmLabel;

  /// Bouton d'annulation de la sheet `widgets/change_password_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get profileChangePasswordCancel;

  /// Bouton de soumission de la sheet `widgets/change_password_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get profileChangePasswordSave;

  /// SnackBar affiché une fois la sheet `widgets/change_password_sheet.dart` refermée avec succès.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe mis à jour.'**
  String get profileChangePasswordUpdatedSnackbar;

  /// Bandeau d'erreur hors-ligne de la sheet `widgets/change_password_sheet.dart`, vérifié avant l'appel réseau.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne : cette action n\'a pas pu être enregistrée. Réessayez une fois reconnecté.'**
  String get profileChangePasswordOfflineMessage;

  /// Erreur générique de la sheet `widgets/change_password_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de mettre à jour le mot de passe. Réessayez.'**
  String get profileChangePasswordGenericError;

  /// Titre de la sheet `widgets/device_permissions_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'GESTION DES AUTORISATIONS APPAREIL'**
  String get profileDevicePermissionsTitle;

  /// Corps de texte statique de la sheet `widgets/device_permissions_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Nexus JDR utilise l\'appareil photo et la galerie uniquement pour définir le portrait de ton personnage ou ton avatar. Pour modifier ces autorisations, ouvre les réglages de ton téléphone.'**
  String get profileDevicePermissionsBody;

  /// Libellé du bouton de la sheet `widgets/device_permissions_sheet.dart` (`AppSettings.openAppSettings`).
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir les réglages'**
  String get profileDevicePermissionsOpenSettings;

  /// Titre de la sheet `widgets/edit_display_name_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'PSEUDO'**
  String get profileEditDisplayNameTitle;

  /// Libellé du champ de la sheet `widgets/edit_display_name_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'NOM D\'AFFICHAGE'**
  String get profileEditDisplayNameFieldLabel;

  /// Placeholder du champ de la sheet `widgets/edit_display_name_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Comment veux-tu qu\'on t\'appelle ?'**
  String get profileEditDisplayNameHint;

  /// Bouton d'annulation de la sheet `widgets/edit_display_name_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get profileEditDisplayNameCancel;

  /// Bouton de soumission de la sheet `widgets/edit_display_name_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get profileEditDisplayNameSave;

  /// SnackBar affiché une fois la sheet `widgets/edit_display_name_sheet.dart` refermée avec succès.
  ///
  /// In fr, this message translates to:
  /// **'Pseudo mis à jour.'**
  String get profileEditDisplayNameUpdatedSnackbar;

  /// Bandeau d'erreur hors-ligne de la sheet `widgets/edit_display_name_sheet.dart`, vérifié avant l'appel réseau.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne : cette action n\'a pas pu être enregistrée. Réessayez une fois reconnecté.'**
  String get profileEditDisplayNameOfflineMessage;

  /// Erreur générique de la sheet `widgets/edit_display_name_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'enregistrer les modifications. Réessayez.'**
  String get profileEditDisplayNameGenericError;

  /// Titre de la sheet `widgets/export_data_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'EXPORT DE MES DONNÉES'**
  String get profileExportDataTitle;

  /// Texte d'explication de la sheet `widgets/export_data_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Génère un fichier JSON contenant ton profil, tous tes personnages et leurs données associées (inventaire, sorts, historique), ainsi que tes groupes et tes notes de groupe. Le fichier te sera proposé au partage/enregistrement depuis ton appareil.'**
  String get profileExportDataDescription;

  /// Bouton d'annulation de la sheet `widgets/export_data_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get profileExportDataCancel;

  /// Bouton de génération de la sheet `widgets/export_data_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Générer l\'export'**
  String get profileExportDataGenerate;

  /// SnackBar affiché une fois l'export partagé depuis `widgets/export_data_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Export généré.'**
  String get profileExportDataGeneratedSnackbar;

  /// Bandeau d'erreur hors-ligne de la sheet `widgets/export_data_sheet.dart`, vérifié avant la génération.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne : cette action n\'a pas pu être enregistrée. Réessayez une fois reconnecté.'**
  String get profileExportDataOfflineMessage;

  /// Erreur générique de la sheet `widgets/export_data_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de générer l\'export. Réessayez.'**
  String get profileExportDataGenericError;

  /// SnackBar affiché une fois la sheet `widgets/report_bug_sheet.dart` refermée avec succès.
  ///
  /// In fr, this message translates to:
  /// **'Merci, ton signalement a bien été envoyé !'**
  String get profileReportBugSentSnackbar;

  /// Titre de la 1ère option de sévérité de `widgets/report_bug_sheet.dart` (valeur technique `mineur`).
  ///
  /// In fr, this message translates to:
  /// **'Gênant'**
  String get profileReportBugSeverityMinorTitle;

  /// Sous-titre de la 1ère option de sévérité de `widgets/report_bug_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Un désagrément, mais tu peux continuer à jouer'**
  String get profileReportBugSeverityMinorSubtitle;

  /// Titre de la 2e option de sévérité de `widgets/report_bug_sheet.dart` (valeur technique `majeur`).
  ///
  /// In fr, this message translates to:
  /// **'Problématique'**
  String get profileReportBugSeverityMajorTitle;

  /// Sous-titre de la 2e option de sévérité de `widgets/report_bug_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Ça complique les choses, mais il y a moyen de contourner'**
  String get profileReportBugSeverityMajorSubtitle;

  /// Titre de la 3e option de sévérité de `widgets/report_bug_sheet.dart` (valeur technique `bloquant`).
  ///
  /// In fr, this message translates to:
  /// **'Ça bloque tout'**
  String get profileReportBugSeverityBlockingTitle;

  /// Sous-titre de la 3e option de sévérité de `widgets/report_bug_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de continuer sans ça'**
  String get profileReportBugSeverityBlockingSubtitle;

  /// Titre de la 4e option de sévérité de `widgets/report_bug_sheet.dart` (valeur technique `contenu`).
  ///
  /// In fr, this message translates to:
  /// **'Contenu à corriger'**
  String get profileReportBugSeverityContentTitle;

  /// Sous-titre de la 4e option de sévérité de `widgets/report_bug_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Erreur ou oubli dans un sort, un objet, une règle ou une traduction'**
  String get profileReportBugSeverityContentSubtitle;

  /// Bandeau d'erreur hors-ligne de `widgets/report_bug_sheet.dart`, vérifié avant l'appel réseau.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne : cette action n\'a pas pu être enregistrée. Réessayez une fois reconnecté.'**
  String get profileReportBugOfflineMessage;

  /// Erreur générique de `widgets/report_bug_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'envoyer le signalement. Réessayez.'**
  String get profileReportBugGenericError;

  /// Erreur affichée quand `BugReportFailureKind.screenshotUpload` est levée par `widgets/report_bug_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'envoyer la capture. Réessayez, ou retirez-la pour envoyer le signalement sans.'**
  String get profileReportBugScreenshotUploadError;

  /// Erreur de choix d'image, `BugReportScreenshotFailureKind.tooLarge`.
  ///
  /// In fr, this message translates to:
  /// **'Cette image est trop lourde (plus de 5 Mo), même compressée. Choisissez-en une autre.'**
  String get profileReportBugCaptureTooLarge;

  /// Erreur de choix d'image, `BugReportScreenshotFailureKind.unsupportedFormat` (et repli sur exception inattendue).
  ///
  /// In fr, this message translates to:
  /// **'Ce format d\'image n\'est pas pris en charge. Choisissez une autre image.'**
  String get profileReportBugCaptureUnsupportedFormat;

  /// Erreur de choix d'image, `BugReportScreenshotFailureKind.accessDenied`.
  ///
  /// In fr, this message translates to:
  /// **'L\'accès à vos photos ou à l\'appareil photo est refusé. Autorisez-le dans les réglages du téléphone.'**
  String get profileReportBugCaptureAccessDenied;

  /// Mention de confidentialité du bloc "CAPTURE D'ÉCRAN" de `widgets/report_bug_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Facultatif, une seule image. Elle reste privée : seule l\'équipe de développement la voit, elle n\'est jamais publiée avec ton signalement et elle est supprimée avec ton compte. Évite quand même d\'y laisser des infos personnelles.'**
  String get profileReportBugCapturePrivacyNotice;

  /// Libellé d'accessibilité (`Semantics.label`) de la tuile vide d'ajout de capture.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une capture d\'écran (facultatif)'**
  String get profileReportBugAddCaptureSemanticLabel;

  /// Libellé visible du `DashedAddTile` d'ajout de capture de `widgets/report_bug_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une capture'**
  String get profileReportBugAddCapture;

  /// Titre du bloc "CAPTURE D'ÉCRAN" de `widgets/report_bug_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'CAPTURE D\'ÉCRAN'**
  String get profileReportBugCaptureSectionTitle;

  /// Titre de la sheet `widgets/report_bug_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'SIGNALER UN BUG'**
  String get profileReportBugTitle;

  /// Libellé du champ "titre" de `widgets/report_bug_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'TITRE'**
  String get profileReportBugFieldTitleLabel;

  /// Placeholder du champ "titre" de `widgets/report_bug_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Résumé en une phrase (ex. « Le bouton PV ne répond pas »)'**
  String get profileReportBugFieldTitleHint;

  /// Libellé du champ "description" de `widgets/report_bug_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'DESCRIPTION'**
  String get profileReportBugFieldDescriptionLabel;

  /// Placeholder du champ "description" de `widgets/report_bug_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Que s\'est-il passé ? Que faisais-tu au moment du bug ?'**
  String get profileReportBugFieldDescriptionHint;

  /// Titre du sélecteur de sévérité de `widgets/report_bug_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'QUEL GENRE DE SOUCI ?'**
  String get profileReportBugSeveritySectionTitle;

  /// Bouton d'annulation de la sheet `widgets/report_bug_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get profileReportBugCancel;

  /// Bouton de soumission de la sheet `widgets/report_bug_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get profileReportBugSend;

  /// Libellé de la ligne "Choisir dans la galerie" de la sheet de source de capture de `widgets/report_bug_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Choisir dans la galerie'**
  String get profileReportBugChooseGallery;

  /// Libellé de la ligne "Prendre une photo" de la sheet de source de capture de `widgets/report_bug_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get profileReportBugTakePhoto;

  /// Texte visible du cadre "Préparation de l'image…" de `widgets/report_bug_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Préparation de l\'image…'**
  String get profileReportBugPreparingImage;

  /// Libellé d'accessibilité (`Semantics.label`) du cadre "Préparation de l'image…".
  ///
  /// In fr, this message translates to:
  /// **'Préparation de l\'image en cours'**
  String get profileReportBugPreparingImageSemanticLabel;

  /// Libellé de la carte de capture jointe de `widgets/report_bug_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Capture jointe'**
  String get profileReportBugAttachedLabel;

  /// Libellé visible du bouton "Remplacer" de la carte de capture jointe.
  ///
  /// In fr, this message translates to:
  /// **'Remplacer'**
  String get profileReportBugReplace;

  /// Libellé visible du bouton "Retirer" de la carte de capture jointe.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get profileReportBugRemove;

  /// Libellé d'accessibilité (`Semantics.label`) du bouton "Remplacer".
  ///
  /// In fr, this message translates to:
  /// **'Remplacer la capture d\'écran'**
  String get profileReportBugReplaceSemanticLabel;

  /// Libellé d'accessibilité (`Semantics.label`) du bouton "Retirer".
  ///
  /// In fr, this message translates to:
  /// **'Retirer la capture d\'écran'**
  String get profileReportBugRemoveSemanticLabel;

  /// Libellé d'accessibilité (`Semantics.label`) de la vignette de capture jointe.
  ///
  /// In fr, this message translates to:
  /// **'Capture d\'écran jointe'**
  String get profileReportBugAttachedImageSemanticLabel;

  /// Segment "Niv. X" du résumé "Race · Classe · Niv. X" d'un personnage — partagé entre `character_card.dart::_summaryLine` et `character_card_action_sheet.dart::_CardActionSheetContent._summaryLine` (copie intentionnellement dupliquée entre ces deux fichiers, voir leur doc respective, mais la clé `.arb` elle-même est réutilisée).
  ///
  /// In fr, this message translates to:
  /// **'Niv. {level}'**
  String characterLevelAbbreviation(int level);

  /// Anciennement `presentation/widgets/character_write_feedback.dart::offlineNotPersistedMessage` (dette technique D88) — ce fichier et sa constante ont été retirés au lot "Characters — fiche (identité/statistiques)" une fois `character_detail_screen.dart` (son dernier appelant restant, D141) migré vers cette clé, comme `character_list_screen.dart`/`character_card_action_sheet.dart` avant lui.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne : cette action n\'a pas pu être enregistrée. Réessayez une fois reconnecté.'**
  String get characterOfflineNotPersistedMessage;

  /// `CharacterErrorCode.accessDenied` (`domain/character_failure.dart`) — texte à garder identique à `data/character_error_mapper.dart::mapCharacterError`, encore utilisé tel quel par les appelants pas encore migrés (D141).
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez pas accès à ces personnages.'**
  String get characterAccessDeniedErrorMessage;

  /// `CharacterErrorCode.network` (`domain/character_failure.dart`) — texte à garder identique à `data/character_error_mapper.dart::mapUnknownCharacterError` (D141).
  ///
  /// In fr, this message translates to:
  /// **'Impossible de contacter le serveur. Vérifiez votre connexion internet et réessayez.'**
  String get characterNetworkErrorMessage;

  /// Titre de l'en-tête de `character_list_screen.dart` (écran d'accueil), déjà en majuscules (`font.display` ne transforme pas la casse).
  ///
  /// In fr, this message translates to:
  /// **'TES AVENTURIERS'**
  String get characterListHeaderTitle;

  /// `hintText` du champ de recherche de la barre `_SearchRow`.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un personnage'**
  String get characterListSearchHint;

  /// `tooltip` du bouton "×" qui vide le champ de recherche.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get characterListSearchClearTooltip;

  /// Libellé d'accessibilité (`Semantics.label`) du bouton entonnoir de `_SearchRow`.
  ///
  /// In fr, this message translates to:
  /// **'Filtrer les personnages'**
  String get characterListFilterButtonLabel;

  /// Valeur sémantique (`Semantics.value`) du bouton entonnoir quand au moins un filtre est actif.
  ///
  /// In fr, this message translates to:
  /// **'Filtre actif'**
  String get characterListFilterButtonActiveValue;

  /// Libellé d'accessibilité (`Semantics.label`) du bouton d'entrée en mode sélection multiple.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner plusieurs personnages'**
  String get characterListSelectionModeButtonLabel;

  /// Libellé du bouton primaire "+ Créer" en pied d'écran (hors mode sélection).
  ///
  /// In fr, this message translates to:
  /// **'+ Créer'**
  String get characterListCreateButton;

  /// Libellé du bouton secondaire "Importer XML" en pied d'écran (hors mode sélection).
  ///
  /// In fr, this message translates to:
  /// **'Importer XML'**
  String get characterListImportXmlButton;

  /// SnackBar affiché si la lecture du fichier sélectionné par `file_picker` échoue (`_startXmlImport`).
  ///
  /// In fr, this message translates to:
  /// **'Impossible de lire ce fichier. Vérifiez qu\'il s\'agit bien d\'un export XML aidedd.org.'**
  String get characterListImportErrorMessage;

  /// Titre de `_SearchEmptyState` quand un filtre de classe/statut (sans recherche textuelle) ne laisse aucun résultat, déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'AUCUN RÉSULTAT'**
  String get characterListSearchEmptyTitleNoQuery;

  /// Titre de `_SearchEmptyState` quand la recherche textuelle ne donne aucun résultat — {query} est déjà mis en majuscules par l'appelant (`query.toUpperCase()`), déjà en majuscules pour le reste du texte.
  ///
  /// In fr, this message translates to:
  /// **'AUCUN RÉSULTAT POUR « {query} »'**
  String characterListSearchEmptyTitleWithQuery(String query);

  /// Corps de `_SearchEmptyState` quand seul un filtre de classe/statut est actif (pas de copie dédiée au cahier des charges pour ce sous-cas).
  ///
  /// In fr, this message translates to:
  /// **'Aucun personnage ne correspond à ce filtre. Réinitialise pour retrouver tous tes personnages.'**
  String get characterListSearchEmptyBodyNoQuery;

  /// Corps de `_SearchEmptyState` quand une recherche textuelle est active — copie exacte de `docs/cahier-des-charges/16-textes-a-rediger.md` section 5.
  ///
  /// In fr, this message translates to:
  /// **'Vérifie l\'orthographe, ou réinitialise la recherche pour retrouver tous tes personnages.'**
  String get characterListSearchEmptyBodyWithQuery;

  /// Libellé du bouton secondaire "Réinitialiser" de `_SearchEmptyState`.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get characterListSearchEmptyResetButton;

  /// Titre de `_EmptyState` (aucun personnage côté serveur), déjà en majuscules — voir la maquette "État vide — Liste de personnages".
  ///
  /// In fr, this message translates to:
  /// **'AUCUN AVENTURIER POUR L\'INSTANT'**
  String get characterListEmptyTitle;

  /// Corps de `_EmptyState` — "ou rejoins l'histoire d'un ami" volontairement omis, voir la doc de classe de `_EmptyState`.
  ///
  /// In fr, this message translates to:
  /// **'Crée ton premier personnage, ou importe-le depuis aidedd.org, pour commencer l\'aventure.'**
  String get characterListEmptyBody;

  /// SnackBar affiché quand une suppression groupée échoue entièrement pour une raison autre qu'une absence de réseau (`_deleteSelectedCharacters`).
  ///
  /// In fr, this message translates to:
  /// **'Impossible de supprimer les personnages sélectionnés. Réessayez.'**
  String get characterListDeleteSelectionGenericError;

  /// Premier segment du SnackBar récapitulatif d'une suppression groupée partiellement réussie (`_partialDeleteMessage`), concaténé avec `characterListDeleteSelectionFailedLabel`.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 personnage supprimé} other{{count} personnages supprimés}}'**
  String characterListDeleteSelectionSucceededLabel(int count);

  /// Second segment du SnackBar récapitulatif d'une suppression groupée partiellement réussie (`_partialDeleteMessage`), concaténé après `characterListDeleteSelectionSucceededLabel`.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 personnage n\'a pas pu être supprimé} other{{count} personnages n\'ont pas pu être supprimés}}'**
  String characterListDeleteSelectionFailedLabel(int count);

  /// Titre de la sheet "Filtrer" (`SheetHeaderBar`, `character_list_filter_sheet.dart`), déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'FILTRER'**
  String get characterListFilterSheetTitle;

  /// Libellé de la section "STATUT" de la sheet "Filtrer", déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'STATUT'**
  String get characterListFilterSheetStatusSection;

  /// Libellé de la section "CLASSE" de la sheet "Filtrer", déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'CLASSE'**
  String get characterListFilterSheetClassSection;

  /// Libellé du bouton secondaire "Réinitialiser" de la sheet "Filtrer".
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get characterListFilterSheetResetButton;

  /// Libellé du bouton primaire "Appliquer" de la sheet "Filtrer".
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get characterListFilterSheetApplyButton;

  /// Libellé de l'option de statut `CharacterStatusFilter.alive` (`domain/character_status_filter.dart`).
  ///
  /// In fr, this message translates to:
  /// **'Vivants'**
  String get characterListFilterSheetStatusAlive;

  /// Libellé de l'option de statut `CharacterStatusFilter.archived`.
  ///
  /// In fr, this message translates to:
  /// **'Archivé'**
  String get characterListFilterSheetStatusArchived;

  /// Libellé de l'option de statut `CharacterStatusFilter.dead`.
  ///
  /// In fr, this message translates to:
  /// **'Mort'**
  String get characterListFilterSheetStatusDead;

  /// Badge pill "ARCHIVÉ" de `character_card.dart::_StatusBadge.archived`, déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'ARCHIVÉ'**
  String get characterCardArchivedBadge;

  /// Badge pill "MORT" de `character_card.dart::_StatusBadge.dead`, déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'MORT'**
  String get characterCardDeadBadge;

  /// Libellé "XP" à droite de la jauge `character_card.dart::_XpGauge` — identique dans les deux fichiers .arb (abréviation déjà internationale).
  ///
  /// In fr, this message translates to:
  /// **'XP'**
  String get characterCardXpLabel;

  /// Libellé de l'action "Modifier" de la sheet "Actions de personnage" (`character_card_action_sheet.dart`).
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get characterCardActionSheetEdit;

  /// Libellé de l'action "Partager".
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get characterCardActionSheetShare;

  /// Libellé de l'action "Archiver" pour un personnage actif (non archivé).
  ///
  /// In fr, this message translates to:
  /// **'Archiver ce personnage'**
  String get characterCardActionSheetArchive;

  /// Libellé de l'action "Archiver" pour un personnage déjà archivé.
  ///
  /// In fr, this message translates to:
  /// **'Désarchiver'**
  String get characterCardActionSheetUnarchive;

  /// Libellé de l'action "Marquer comme mort" pour un personnage vivant.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme mort'**
  String get characterCardActionSheetMarkDead;

  /// Libellé de l'action "Marquer comme mort" pour un personnage déjà mort.
  ///
  /// In fr, this message translates to:
  /// **'Ressusciter'**
  String get characterCardActionSheetRevive;

  /// Libellé de l'action "Supprimer" (en rouge, `accentBrick`).
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le personnage'**
  String get characterCardActionSheetDelete;

  /// SnackBar affiché quand `setArchived`/`setDead` échouent avec une erreur générique (pas une `CharacterFailure`).
  ///
  /// In fr, this message translates to:
  /// **'Impossible de mettre à jour le statut. Réessayez.'**
  String get characterCardActionSheetUpdateStatusGenericError;

  /// SnackBar affiché quand `deleteCharacter` échoue avec une erreur générique (pas une `CharacterFailure`).
  ///
  /// In fr, this message translates to:
  /// **'Impossible de supprimer le personnage. Réessayez.'**
  String get characterCardActionSheetDeleteGenericError;

  /// Titre du dialogue `showDeleteCharacterConfirmationDialog` (suppression d'un unique personnage).
  ///
  /// In fr, this message translates to:
  /// **'Supprimer {characterName} ?'**
  String characterDeleteConfirmationSingleTitle(String characterName);

  /// Corps du dialogue `showDeleteCharacterConfirmationDialog` (suppression d'un unique personnage).
  ///
  /// In fr, this message translates to:
  /// **'Cette action est définitive : le personnage et toutes ses données (sorts, inventaire, historique...) seront irrémédiablement supprimés.'**
  String get characterDeleteConfirmationBody;

  /// Titre du dialogue `showDeleteCharactersConfirmationDialog` (suppression groupée, n > 1 toujours — voir sa doc de classe).
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ces {count} personnages ?'**
  String characterDeleteConfirmationMultipleTitle(int count);

  /// Corps du dialogue `showDeleteCharactersConfirmationDialog` (suppression groupée).
  ///
  /// In fr, this message translates to:
  /// **'Cette action est définitive : les personnages et toutes leurs données (sorts, inventaire, historique...) seront irrémédiablement supprimés.'**
  String get characterDeleteConfirmationMultipleBody;

  /// Libellé du bouton secondaire "Annuler", partagé par les deux dialogues de `character_delete_confirmation.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get characterDeleteConfirmationCancelButton;

  /// Libellé du bouton destructif de confirmation du dialogue singulier.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get characterDeleteConfirmationConfirmButton;

  /// Libellé du bouton destructif de confirmation du dialogue pluriel, avec le compte entre parenthèses.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ({count})'**
  String characterDeleteConfirmationMultipleConfirmButton(int count);

  /// Libellé central de `CharacterSelectionActionBar` (nombre de personnages cochés en mode sélection multiple).
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun personnage sélectionné} =1{1 personnage sélectionné} other{{count} personnages sélectionnés}}'**
  String characterSelectionActionBarSelectedCount(int count);

  /// Libellé du lien "Annuler" de `CharacterSelectionActionBar`.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get characterSelectionActionBarCancelButton;

  /// Libellé du bouton destructif "Supprimer" de `CharacterSelectionActionBar`.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get characterSelectionActionBarDeleteButton;

  /// Libellé d'accessibilité (`Semantics.label`) de `CharacterNameTagChip` quand `onTap` est fourni.
  ///
  /// In fr, this message translates to:
  /// **'{name}, voir le détail'**
  String characterNameTagChipSemanticLabel(String name);

  /// Libellé (pied de fiche, `CharacterDetailTabBar`) de l'onglet "Personnage" — déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'PERSO'**
  String get characterDetailTabCharacterLabel;

  /// Titre affiché dans `WoodBackHeader` (bandeau bois) quand l'onglet "Personnage" est actif — déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'FICHE'**
  String get characterDetailTabCharacterTitle;

  /// Libellé (pied de fiche) de l'onglet "Aptitudes" — déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'APT.'**
  String get characterDetailTabSkillsLabel;

  /// Titre affiché dans `WoodBackHeader` quand l'onglet "Aptitudes" est actif — déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'APTITUDES'**
  String get characterDetailTabSkillsTitle;

  /// Libellé (pied de fiche) de l'onglet "Sorts" — déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'SORTS'**
  String get characterDetailTabSpellsLabel;

  /// Titre affiché dans `WoodBackHeader` quand l'onglet "Sorts" est actif — déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'SORTS'**
  String get characterDetailTabSpellsTitle;

  /// Libellé (pied de fiche) de l'onglet "Inventaire" — déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'SAC'**
  String get characterDetailTabInventoryLabel;

  /// Titre affiché dans `WoodBackHeader` quand l'onglet "Inventaire" est actif — déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'INVENTAIRE'**
  String get characterDetailTabInventoryTitle;

  /// Libellé (pied de fiche) de l'onglet "Histoire" — déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'HIST.'**
  String get characterDetailTabStoryLabel;

  /// Titre affiché dans `WoodBackHeader` quand l'onglet "Histoire" est actif — déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'HISTOIRE'**
  String get characterDetailTabStoryTitle;

  /// `tooltip` de l'icône "?" du bandeau bois, onglet "Personnage" uniquement — ouvre `showStepHelpSheet`.
  ///
  /// In fr, this message translates to:
  /// **'Aide'**
  String get characterDetailHelpTooltip;

  /// `tooltip` de l'icône "⋮" du bandeau bois (menu "Modifier"/"Exporter en XML"/"Archiver"/"Marquer comme mort"/"Supprimer"), onglet "Personnage" uniquement.
  ///
  /// In fr, this message translates to:
  /// **'Plus d\'options'**
  String get characterDetailMoreOptionsTooltip;

  /// `tooltip` de l'icône loupe du bandeau bois, partagée par les onglets "Aptitudes" et "Sorts" (focus le champ de recherche de l'onglet actif).
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get characterDetailSearchTooltip;

  /// `tooltip` de l'icône entonnoir du bandeau bois, onglet "Inventaire" uniquement (fait défiler jusqu'à la bascule de filtre par catégorie).
  ///
  /// In fr, this message translates to:
  /// **'Filtrer'**
  String get characterDetailFilterTooltip;

  /// Item "Exporter en XML" du menu "⋮" du bandeau bois.
  ///
  /// In fr, this message translates to:
  /// **'Exporter en XML'**
  String get characterDetailMenuExportXml;

  /// Message de repli de `_ErrorState` quand `characterDetailProvider` échoue avec une erreur qui n'est pas une `CharacterFailure` (sinon `CharacterFailure.message` est affiché tel quel).
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger ce personnage. Réessayez.'**
  String get characterDetailLoadErrorMessage;

  /// `label` passé à `showDiceRollSheet` au tap sur la tuile "INIT." de `CharacterStatPillsRow` (titre de la feuille de lancer de dé).
  ///
  /// In fr, this message translates to:
  /// **'Initiative'**
  String get characterDetailInitiativeLabel;

  /// SnackBar d'échec générique de `_applyHpState` (ajustement PV depuis la feuille détaillée).
  ///
  /// In fr, this message translates to:
  /// **'Impossible de mettre à jour les PV. Réessayez.'**
  String get characterDetailHpUpdateErrorMessage;

  /// SnackBar d'échec de `_reassertCurrentHpState` (réaffirmation PV après un repos, voir sa documentation).
  ///
  /// In fr, this message translates to:
  /// **'Impossible de synchroniser les PV. Réessayez.'**
  String get characterDetailHpSyncErrorMessage;

  /// SnackBar de succès de `_useClassFeature` (onglet "Aptitudes", utilisation d'une aptitude de classe à usage limité).
  ///
  /// In fr, this message translates to:
  /// **'{featureName} utilisée.'**
  String characterDetailFeatureUseSuccessMessage(String featureName);

  /// SnackBar d'échec de `_useClassFeature`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'utiliser cette aptitude. Réessayez.'**
  String get characterDetailFeatureUseErrorMessage;

  /// SnackBar d'échec de `_reassertFeatureUsesState` (réaffirmation après un repos).
  ///
  /// In fr, this message translates to:
  /// **'Impossible de synchroniser les aptitudes de classe. Réessayez.'**
  String get characterDetailFeatureSyncErrorMessage;

  /// SnackBar d'échec de `_addXp`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ajouter l\'XP. Réessayez.'**
  String get characterDetailXpAddErrorMessage;

  /// Voir `_CharacterDetailScreenState._offlineQueuedMessage` — écriture réellement mise en file (`PendingCharacterWriteQueue`) : promet une synchronisation future réelle, contrairement à `characterOfflineNotPersistedMessage`.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne : sera synchronisé dès que la connexion revient.'**
  String get characterDetailOfflineQueuedMessage;

  /// SnackBar d'échec de `_adjustArmorClassBonus` (sheet "Ajustement de CA").
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ajuster la Classe d\'Armure. Réessayez.'**
  String get characterDetailArmorClassAdjustErrorMessage;

  /// Libellé du bouton unique "Repos" de `CharacterVitalsCard` (ouvre `RestSheet`).
  ///
  /// In fr, this message translates to:
  /// **'Repos'**
  String get characterVitalsCardRestButton;

  /// Libellé du bandeau PV, déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'POINTS DE VIE'**
  String get characterVitalsCardHpLabel;

  /// Puce affichée sous la jauge PV quand `temporaryHp > 0`.
  ///
  /// In fr, this message translates to:
  /// **'+{amount} PV temp.'**
  String characterVitalsCardTemporaryHpChip(int amount);

  /// Libellé du bandeau XP, déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'EXPÉRIENCE'**
  String get characterVitalsCardXpLabel;

  /// Libellé du `PrimaryButton` pleine largeur sous la jauge XP (ouvre `AddXpSheet`).
  ///
  /// In fr, this message translates to:
  /// **'+ XP'**
  String get characterVitalsCardAddXpButton;

  /// Bandeau affiché sous la jauge XP une fois le seuil du niveau suivant franchi, déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'NIVEAU {targetLevel} DISPONIBLE'**
  String characterVitalsCardLevelUpBanner(int targetLevel);

  /// Libellé de la tuile "Vitesse" de `CharacterStatPillsRow`, déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'VIT.'**
  String get characterStatPillsSpeedLabel;

  /// Libellé de la tuile "Classe d'Armure" de `CharacterStatPillsRow`, déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'CA'**
  String get characterStatPillsArmorClassLabel;

  /// Libellé de la tuile "Initiative" de `CharacterStatPillsRow`, déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'INIT.'**
  String get characterStatPillsInitiativeLabel;

  /// Libellé de la tuile "Inspiration" de `CharacterStatPillsRow`, déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'INSP.'**
  String get characterStatPillsInspirationLabel;

  /// Valeur de la tuile "Vitesse" quand `speed` est résolu — unité métrique (mètres) volontairement gardée telle quelle en anglais aussi (même unité conservée dans app_en.arb, qui ne porte pas sa propre description de clé : ce fichier app_fr.arb est le template) : les données de vitesse de ce dépôt sont stockées en mètres, jamais converties en pieds.
  ///
  /// In fr, this message translates to:
  /// **'{speed} m'**
  String characterStatPillsSpeedValue(int speed);

  /// Abréviation de la caractéristique Force, partagée par `character_saving_throws_card.dart` et `character_skills_card.dart` (chacun garde sa propre table de correspondance `Dart`, intentionnellement dupliquée — voir leur doc de classe respective — mais réutilise ces mêmes clés `.arb`, même principe que `characterLevelAbbreviation`).
  ///
  /// In fr, this message translates to:
  /// **'For'**
  String get characterAbilityAbbreviationStr;

  /// Abréviation de la caractéristique Dextérité — voir `characterAbilityAbbreviationStr`.
  ///
  /// In fr, this message translates to:
  /// **'Dex'**
  String get characterAbilityAbbreviationDex;

  /// Abréviation de la caractéristique Constitution — voir `characterAbilityAbbreviationStr`.
  ///
  /// In fr, this message translates to:
  /// **'Con'**
  String get characterAbilityAbbreviationCon;

  /// Abréviation de la caractéristique Intelligence — voir `characterAbilityAbbreviationStr`.
  ///
  /// In fr, this message translates to:
  /// **'Int'**
  String get characterAbilityAbbreviationInt;

  /// Abréviation de la caractéristique Sagesse — voir `characterAbilityAbbreviationStr`.
  ///
  /// In fr, this message translates to:
  /// **'Sag'**
  String get characterAbilityAbbreviationWis;

  /// Abréviation de la caractéristique Charisme — voir `characterAbilityAbbreviationStr`.
  ///
  /// In fr, this message translates to:
  /// **'Cha'**
  String get characterAbilityAbbreviationCha;

  /// Titre de `CharacterSavingThrowsCard`, déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'JETS DE SAUVEGARDE'**
  String get characterSavingThrowsCardTitle;

  /// Titre de `CharacterSkillsCard`, déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'LES 18 COMPÉTENCES'**
  String get characterSkillsCardTitle;

  /// Légende "● maîtrisée" en tête de `CharacterSkillsCard`.
  ///
  /// In fr, this message translates to:
  /// **'maîtrisée'**
  String get characterSkillsCardMasteredLegend;

  /// Texte de la puce "D20" en bout de ligne de compétence — notation de dé, identique dans les deux langues.
  ///
  /// In fr, this message translates to:
  /// **'D20'**
  String get characterSkillsCardD20Chip;

  /// Titre de `CharacterAppearanceCard`, déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'APPARENCE PHYSIQUE'**
  String get characterAppearanceCardTitle;

  /// Libellé du champ "Sexe" de `CharacterAppearanceCard`.
  ///
  /// In fr, this message translates to:
  /// **'Sexe'**
  String get characterAppearanceCardSexeLabel;

  /// Libellé du champ "Âge" de `CharacterAppearanceCard`.
  ///
  /// In fr, this message translates to:
  /// **'Âge'**
  String get characterAppearanceCardAgeLabel;

  /// Libellé du champ "Taille" de `CharacterAppearanceCard`.
  ///
  /// In fr, this message translates to:
  /// **'Taille'**
  String get characterAppearanceCardHeightLabel;

  /// Libellé du champ "Poids" de `CharacterAppearanceCard`.
  ///
  /// In fr, this message translates to:
  /// **'Poids'**
  String get characterAppearanceCardWeightLabel;

  /// Libellé du champ "Yeux" de `CharacterAppearanceCard`.
  ///
  /// In fr, this message translates to:
  /// **'Yeux'**
  String get characterAppearanceCardEyesLabel;

  /// Libellé du champ "Peau" de `CharacterAppearanceCard`.
  ///
  /// In fr, this message translates to:
  /// **'Peau'**
  String get characterAppearanceCardSkinLabel;

  /// Libellé du champ "Cheveux" de `CharacterAppearanceCard`.
  ///
  /// In fr, this message translates to:
  /// **'Cheveux'**
  String get characterAppearanceCardHairLabel;

  /// `hintText` du champ de recherche "LES 18 COMPÉTENCES" de l'onglet "Aptitudes" (`_SkillSearchField`).
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une compétence'**
  String get characterSkillsTabBodySearchHint;

  /// Message de `_NoSkillMatchState` quand la recherche ne donne aucun résultat.
  ///
  /// In fr, this message translates to:
  /// **'Aucune compétence pour « {query} ».'**
  String characterSkillsTabBodyNoMatchMessage(String query);

  /// Titre du bandeau bois de `ConnectionErrorState._Banner`, déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'CONNEXION'**
  String get connectionErrorStateBannerTitle;

  /// Titre de l'écran "Connexion impossible" — copie exacte de `docs/cahier-des-charges/16-textes-a-rediger.md` section 4.
  ///
  /// In fr, this message translates to:
  /// **'Connexion impossible'**
  String get connectionErrorStateTitle;

  /// Corps de l'écran "Connexion impossible" — copie exacte de `docs/cahier-des-charges/16-textes-a-rediger.md` section 4.
  ///
  /// In fr, this message translates to:
  /// **'Vérifie ta connexion internet et réessaie. Tes personnages restent disponibles hors ligne — les modifications se synchroniseront automatiquement dès le retour du réseau.'**
  String get connectionErrorStateBody;

  /// Libellé du bouton primaire "Réessayer".
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get connectionErrorStateRetryButton;

  /// Libellé du lien visuellement neutre "Continuer hors ligne" — voir la doc de classe de `_ContinueOfflineLink` pour le rationale de sa désactivation.
  ///
  /// In fr, this message translates to:
  /// **'Continuer hors ligne'**
  String get connectionErrorStateContinueOfflineLabel;

  /// `Tooltip.message` du lien "Continuer hors ligne".
  ///
  /// In fr, this message translates to:
  /// **'Bientôt disponible : la lecture hors ligne de tes personnages arrive avec une prochaine mise à jour. Pour l\'instant, une connexion est nécessaire pour charger tes personnages.'**
  String get connectionErrorStateContinueOfflineTooltip;

  /// Titre de `hp_adjustment_sheet.dart` (bouton crayon du bandeau PV).
  ///
  /// In fr, this message translates to:
  /// **'Ajuster les PV'**
  String get hpAdjustmentSheetTitle;

  /// Segment "Dégâts" du `SegmentedToggle` de `hp_adjustment_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Dégâts'**
  String get hpAdjustmentSheetDamageOption;

  /// Segment "Soins" du `SegmentedToggle` de `hp_adjustment_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Soins'**
  String get hpAdjustmentSheetHealOption;

  /// Segment "PV temp." du `SegmentedToggle` de `hp_adjustment_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'PV temp.'**
  String get hpAdjustmentSheetTemporaryOption;

  /// Bouton secondaire "Annuler" de `hp_adjustment_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get hpAdjustmentSheetCancelButton;

  /// Bouton primaire "Appliquer" de `hp_adjustment_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get hpAdjustmentSheetApplyButton;

  /// Titre de `add_xp_sheet.dart` (bouton "+" du bandeau XP).
  ///
  /// In fr, this message translates to:
  /// **'Ajouter de l\'XP'**
  String get addXpSheetTitle;

  /// Ligne "XP actuelle : X / Y" de `add_xp_sheet.dart` — `threshold` retombe sur `currentXp` au niveau maximum (voir `_AddXpSheetContent.build`).
  ///
  /// In fr, this message translates to:
  /// **'XP actuelle : {currentXp} / {threshold}'**
  String addXpSheetCurrentXpLabel(int currentXp, int threshold);

  /// Libellé du champ de saisie du montant d'XP de `add_xp_sheet.dart`, déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'XP GAGNÉE'**
  String get addXpSheetGainedLabel;

  /// `hintText` du champ de saisie du montant d'XP de `add_xp_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Ex. 250'**
  String get addXpSheetAmountHint;

  /// Texte d'aide sous le champ de saisie du montant d'XP de `add_xp_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Montant remis par le MJ en fin de séance, par exemple.'**
  String get addXpSheetAmountHelper;

  /// Ligne "Nouveau total" de `add_xp_sheet.dart`, affichée dès qu'un montant valide est saisi.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau total : {total} XP'**
  String addXpSheetNewTotalLabel(int total);

  /// Bouton secondaire "Annuler" de `add_xp_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get addXpSheetCancelButton;

  /// Bouton primaire "Ajouter" de `add_xp_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get addXpSheetApplyButton;

  /// Lien "Monter de niveau manuellement" de `add_xp_sheet.dart`, affiché tant que le seuil du niveau suivant n'est pas déjà franchi.
  ///
  /// In fr, this message translates to:
  /// **'Monter de niveau manuellement'**
  String get addXpSheetManualLevelUpLink;

  /// Titre (`SheetHeaderBar`) de `add_reward_sheet.dart`, déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'AJOUTER UNE RÉCOMPENSE'**
  String get addRewardSheetTitle;

  /// Titre de la section "MONNAIE" de `add_reward_sheet.dart`, déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'MONNAIE'**
  String get addRewardSheetCurrencyLabel;

  /// Titre de la section "OBJETS" de `add_reward_sheet.dart`, déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'OBJETS'**
  String get addRewardSheetItemsLabel;

  /// Libellé de la `DashedAddTile` "Ajouter un objet" de `add_reward_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un objet'**
  String get addRewardSheetAddItemLabel;

  /// Bouton secondaire "Annuler" de `add_reward_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get addRewardSheetCancelButton;

  /// Bouton primaire "Ajouter la récompense" de `add_reward_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter la récompense'**
  String get addRewardSheetApplyButton;

  /// Ligne d'objet composé localement de `add_reward_sheet.dart::_RewardItemRow` — `name` est déjà le nom d'affichage résolu (catalogue ou objet personnalisé).
  ///
  /// In fr, this message translates to:
  /// **'{name} × {quantity}'**
  String addRewardSheetItemQuantityLabel(String name, int quantity);

  /// Titre de `rest_sheet.dart` (lien "Prendre un repos").
  ///
  /// In fr, this message translates to:
  /// **'Repos'**
  String get restSheetTitle;

  /// Ligne "PV actuels" de `rest_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'PV actuels : {currentHp} / {maxHp}'**
  String restSheetCurrentHpLabel(int currentHp, int maxHp);

  /// Segment "Repos court" du `SegmentedToggle` de `rest_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Repos court'**
  String get restSheetShortOption;

  /// Segment "Repos long" du `SegmentedToggle` de `rest_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Repos long'**
  String get restSheetLongOption;

  /// Bouton secondaire "Annuler" de `rest_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get restSheetCancelButton;

  /// Bouton primaire "Appliquer" de `rest_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get restSheetApplyButton;

  /// Titre de la section "Sorts préparés" du repos long de `rest_sheet.dart::_PreparedSpellsChoice`, déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'SORTS PRÉPARÉS'**
  String get restSheetPreparedSpellsTitle;

  /// Segment "Garder ma liste" du `SegmentedToggle` de `rest_sheet.dart::_PreparedSpellsChoice`.
  ///
  /// In fr, this message translates to:
  /// **'Garder ma liste'**
  String get restSheetKeepListOption;

  /// Segment "Changer mes sorts" du `SegmentedToggle` de `rest_sheet.dart::_PreparedSpellsChoice`.
  ///
  /// In fr, this message translates to:
  /// **'Changer mes sorts'**
  String get restSheetChangeSpellsOption;

  /// Texte d'aide affiché quand "Changer mes sorts" est sélectionné dans `rest_sheet.dart::_PreparedSpellsChoice`.
  ///
  /// In fr, this message translates to:
  /// **'Après le repos, la liste de vos sorts s\'ouvre pour choisir ceux à préparer.'**
  String get restSheetChangeSpellsHelper;

  /// Texte d'aide affiché quand "Garder ma liste" est sélectionné dans `rest_sheet.dart::_PreparedSpellsChoice`.
  ///
  /// In fr, this message translates to:
  /// **'Vos sorts préparés restent les mêmes après le repos.'**
  String get restSheetKeepListHelper;

  /// Texte d'aide du repos long dans `rest_sheet.dart::_RestHelpBlock`.
  ///
  /// In fr, this message translates to:
  /// **'Restaure les PV au maximum, réinitialise les emplacements de sorts et recharge toutes les aptitudes rechargeables (repos court comme repos long).'**
  String get restSheetLongHelpText;

  /// Ligne "PV après repos" du repos long dans `rest_sheet.dart::_RestHelpBlock` — `maxHp` répété volontairement (le repos long restaure toujours au maximum).
  ///
  /// In fr, this message translates to:
  /// **'PV après repos : {maxHp} / {maxHp}'**
  String restSheetAfterRestHpLabel(int maxHp);

  /// Ligne d'état des dés de vie du repos court mono-classe dans `rest_sheet.dart::_ShortRestHitDiceBlock`.
  ///
  /// In fr, this message translates to:
  /// **'Dés de vie disponibles : {remaining}/{total} (d{hitDie})'**
  String restSheetHitDiceAvailableLabel(int remaining, int total, int hitDie);

  /// Libellé "Dés à dépenser" du stepper de `rest_sheet.dart` (mono-classe et multiclasse).
  ///
  /// In fr, this message translates to:
  /// **'Dés à dépenser'**
  String get restSheetDiceToSpendLabel;

  /// Message affiché quand aucun dé de vie n'est disponible, dans `rest_sheet.dart::_ShortRestHitDiceBlock`.
  ///
  /// In fr, this message translates to:
  /// **'Aucun dé de vie disponible. Le repos court reste gratuit — aucune action supplémentaire requise.'**
  String get restSheetNoHitDiceAvailable;

  /// Segment "Lancer les dés" du `SegmentedToggle` de méthode de jet de `rest_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Lancer les dés'**
  String get restSheetRollMethodOption;

  /// Segment "Valeur moyenne" du `SegmentedToggle` de méthode de jet de `rest_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Valeur moyenne'**
  String get restSheetAverageMethodOption;

  /// Lien "Relancer les dés" de `rest_sheet.dart`, affiché en méthode "Lancer les dés".
  ///
  /// In fr, this message translates to:
  /// **'Relancer les dés'**
  String get restSheetRerollLink;

  /// Rappel de la formule de valeur moyenne, affiché en méthode "Valeur moyenne" dans `rest_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'(moitié du dé arrondie au supérieur, +1, par dé)'**
  String get restSheetAverageFormulaHint;

  /// `InfoBanner` affichée quand les PV sont déjà au maximum lors d'un repos court, dans `rest_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'PV déjà au maximum : ce repos ne restaurera aucun PV supplémentaire.'**
  String get restSheetAlreadyMaxHpMessage;

  /// Titre de la `GainRow` "PV restaurés" du repos court dans `rest_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'PV restaurés'**
  String get restSheetHpRestoredTitle;

  /// Sous-titre de la `GainRow` "PV restaurés" du repos court dans `rest_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'{currentHp} → {newHp} (+{gain})'**
  String restSheetHpRestoredSubtitle(int currentHp, int newHp, int gain);

  /// En-tête du bloc de jet par classe, repos court multiclassé, dans `rest_sheet.dart::_MulticlassShortRestHitDiceBlock`.
  ///
  /// In fr, this message translates to:
  /// **'{className} (d{hitDie})'**
  String restSheetPoolRolledLabel(String className, int hitDie);

  /// Ligne d'état des dés de vie d'UN pool, repos court multiclassé, dans `rest_sheet.dart::_PoolSpendRow`.
  ///
  /// In fr, this message translates to:
  /// **'{className} — dés de vie disponibles : {available}/{total} (d{hitDie})'**
  String restSheetPoolStatusLabel(
    String className,
    int available,
    int total,
    int hitDie,
  );

  /// Titre de la répartition des dés de vie récupérés, repos long multiclassé, dans `rest_sheet.dart::_LongRestRecoveryChoice`.
  ///
  /// In fr, this message translates to:
  /// **'Dés de vie récupérés : {count} — répartissez-les entre vos classes'**
  String restSheetRecoveredAllocationTitle(int count);

  /// Ligne d'UN pool de la répartition des dés de vie récupérés, dans `rest_sheet.dart::_LongRestRecoveryChoice`.
  ///
  /// In fr, this message translates to:
  /// **'{className} (d{hitDie}) — {spent} dépensé(s)'**
  String restSheetRecoveredPoolLabel(String className, int hitDie, int spent);

  /// Ligne "Reste à répartir" de `rest_sheet.dart::_LongRestRecoveryChoice`.
  ///
  /// In fr, this message translates to:
  /// **'Reste à répartir : {remaining}'**
  String restSheetRemainingToAllocateLabel(int remaining);

  /// Formule du résultat de `dice_roll_sheet.dart` — `modifier` est déjà formaté avec son signe (`SignedModifierFormatter`).
  ///
  /// In fr, this message translates to:
  /// **'d20 ({roll}) {modifier} = {total}'**
  String diceRollSheetFormula(int roll, String modifier, int total);

  /// Mention affichée sur un 20 naturel dans `dice_roll_sheet.dart`, déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'RÉUSSITE CRITIQUE'**
  String get diceRollSheetCriticalSuccess;

  /// Mention affichée sur un 1 naturel dans `dice_roll_sheet.dart`, déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'ÉCHEC CRITIQUE'**
  String get diceRollSheetCriticalFailure;

  /// Bouton "Relancer" de `dice_roll_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Relancer'**
  String get diceRollSheetRerollButton;

  /// Titre de `armor_class_bonus_sheet.dart` (tap sur la tuile "CA").
  ///
  /// In fr, this message translates to:
  /// **'Ajustement de CA'**
  String get armorClassBonusSheetTitle;

  /// Segment "Bonus" du `SegmentedToggle` de `armor_class_bonus_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Bonus'**
  String get armorClassBonusSheetBonusOption;

  /// Segment "Malus" du `SegmentedToggle` de `armor_class_bonus_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Malus'**
  String get armorClassBonusSheetMalusOption;

  /// Bouton secondaire "Effacer" de `armor_class_bonus_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get armorClassBonusSheetClearButton;

  /// Bouton primaire "Valider" de `armor_class_bonus_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get armorClassBonusSheetValidateButton;

  /// Eyebrow commun à tout le flux "Montée de niveau" (`LevelUpHeader.eyebrow`), déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'MONTÉE DE NIVEAU'**
  String get levelUpScreenEyebrow;

  /// Eyebrow de l'écran de blocage quand un ou plusieurs niveaux du chaînage ont déjà été validés cette session (`_buildBlocked`), déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'NIVEAU ATTEINT'**
  String get levelUpScreenLevelReachedEyebrow;

  /// `LevelUpHeader.levelLabel`, déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'NIVEAU {level}'**
  String levelUpScreenLevelLabel(int level);

  /// `LevelUpHeader.remainingLevelsLabel`, affiché en cas de chaînage multi-niveaux.
  ///
  /// In fr, this message translates to:
  /// **'{remaining, plural, =1{Encore 1 niveau à valider ensuite} other{Encore {remaining} niveaux à valider ensuite}}'**
  String levelUpScreenRemainingLevelsLabel(int remaining);

  /// `SnackBar` du lien "Voir l'historique des niveaux" (aucun écran dédié n'existe encore).
  ///
  /// In fr, this message translates to:
  /// **'Bientôt disponible'**
  String get levelUpScreenComingSoonSnackBar;

  /// `_applyError` générique du récapitulatif, erreur non `CharacterFailure` interceptée par `_continueFromSummary`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'enregistrer la montée de niveau. Réessayez.'**
  String get levelUpScreenGenericApplyError;

  /// Message de repli de `_ErrorState` quand l'erreur de chargement n'est pas une `CharacterFailure`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les données de montée de niveau. Réessayez.'**
  String get levelUpScreenGenericLoadError;

  /// Instruction de l'étape `classDecision` (multiclassage/choix de la classe continuée).
  ///
  /// In fr, this message translates to:
  /// **'Choisissez comment ce niveau s\'applique.'**
  String get levelUpScreenClassDecisionInstruction;

  /// Titre d'une tuile "Continuer en {classe}" de l'étape `classDecision`.
  ///
  /// In fr, this message translates to:
  /// **'Continuer en {className}'**
  String levelUpScreenContinueClassOptionTitle(String className);

  /// Sous-titre de la tuile "Continuer" primaire quand ce niveau est bloqué — réutilisé aussi comme corps de l'écran de blocage (`_buildBlocked`), texte identique dans les deux cas.
  ///
  /// In fr, this message translates to:
  /// **'Ce niveau nécessite un choix pas encore disponible dans l\'app.'**
  String get levelUpScreenContinueClassBlockedSubtitle;

  /// Sous-titre par défaut (non bloqué) d'une tuile "Continuer en {classe}".
  ///
  /// In fr, this message translates to:
  /// **'Vous progressez dans votre voie actuelle (niveau {currentLevel} → {nextLevel}).'**
  String levelUpScreenContinueClassSubtitle(int currentLevel, int nextLevel);

  /// Titre d'une tuile "Se multiclasser en {classe}" de l'étape `classDecision`.
  ///
  /// In fr, this message translates to:
  /// **'Se multiclasser en {className}'**
  String levelUpScreenMulticlassOptionTitle(String className);

  /// Sous-titre d'une tuile "Se multiclasser en {classe}" — `abilities` est déjà la liste jointe des caractéristiques qui satisfont le prérequis.
  ///
  /// In fr, this message translates to:
  /// **'Vous débutez au niveau 1 dans cette classe. Prérequis rempli : {abilities}.'**
  String levelUpScreenMulticlassOptionSubtitle(String abilities);

  /// `InfoBanner` de contexte affichée en tête de toute étape concernant la nouvelle classe tant que le multiclassage est en cours.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle classe : {className} (niveau 1)'**
  String levelUpScreenMulticlassInfoBanner(String className);

  /// Titre du bloc teaser de l'annonce de niveau (`_buildAnnouncement`).
  ///
  /// In fr, this message translates to:
  /// **'À venir dans les prochaines étapes'**
  String get levelUpScreenUpcomingStepsTitle;

  /// Ligne teaser "Choix à faire" de l'annonce de niveau — `choiceLabel` est déjà résolu (voir `_choiceStepLabel`).
  ///
  /// In fr, this message translates to:
  /// **'Un choix de {choiceLabel} vous attendra'**
  String levelUpScreenUpcomingChoiceStep(String choiceLabel);

  /// Ligne teaser "Sorts" de l'annonce de niveau.
  ///
  /// In fr, this message translates to:
  /// **'Vos emplacements de sorts vont évoluer'**
  String get levelUpScreenUpcomingSpellsStep;

  /// Ligne teaser "Invocations" de l'annonce de niveau.
  ///
  /// In fr, this message translates to:
  /// **'De nouvelles invocations vous attendront'**
  String get levelUpScreenUpcomingInvocationsStep;

  /// Ligne teaser "Disciplines élémentaires" de l'annonce de niveau.
  ///
  /// In fr, this message translates to:
  /// **'De nouvelles disciplines élémentaires vous attendront'**
  String get levelUpScreenUpcomingElementalDisciplinesStep;

  /// Ligne teaser "Manœuvres" de l'annonce de niveau.
  ///
  /// In fr, this message translates to:
  /// **'De nouvelles manœuvres vous attendront'**
  String get levelUpScreenUpcomingManeuversStep;

  /// Ligne teaser "Tirs arcaniques" de l'annonce de niveau.
  ///
  /// In fr, this message translates to:
  /// **'De nouveaux tirs arcaniques vous attendront'**
  String get levelUpScreenUpcomingArcaneShotsStep;

  /// Ligne teaser "Runes" de l'annonce de niveau.
  ///
  /// In fr, this message translates to:
  /// **'De nouvelles runes vous attendront'**
  String get levelUpScreenUpcomingRunesStep;

  /// Ligne teaser "Infusions" de l'annonce de niveau.
  ///
  /// In fr, this message translates to:
  /// **'Vos infusions vont évoluer'**
  String get levelUpScreenUpcomingInfusionsStep;

  /// Bouton primaire "Continuer" partagé par l'annonce, le récapitulatif et `_StepFooter` (étapes 1 à 3 et dédiées).
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get levelUpScreenContinueButton;

  /// Bouton secondaire "Retour" de `_StepFooter`.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get levelUpScreenBackButton;

  /// Titre de `GainRow` "Nouvelle aptitude" — annonce, étape "Aptitudes" et récapitulatif.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle aptitude'**
  String get levelUpScreenNewFeatureTitle;

  /// Titre de `GainRow` "Nouvelle maîtrise" du bloc "Maîtrises de multiclassage" de l'étape "Aptitudes".
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle maîtrise'**
  String get levelUpScreenNewProficiencyTitle;

  /// `stepLabel` de l'étape "Points de vie" (toujours étape 1).
  ///
  /// In fr, this message translates to:
  /// **'Étape 1 sur {totalSteps} · Points de vie'**
  String levelUpScreenHpStepLabel(int totalSteps);

  /// Titre "Points de vie maximum" — étape "Points de vie" et récapitulatif.
  ///
  /// In fr, this message translates to:
  /// **'Points de vie maximum'**
  String get levelUpScreenMaxHpTitle;

  /// Formule de delta des PV maximum (étape "Points de vie" et récapitulatif).
  ///
  /// In fr, this message translates to:
  /// **'{oldHp} → {newHp} (+{gain})'**
  String levelUpScreenMaxHpDelta(int oldHp, int newHp, int gain);

  /// Libellé du dé de vie, branche multiclassage, étape "Points de vie".
  ///
  /// In fr, this message translates to:
  /// **'Dé de vie de {className} (niveau 1) : d{hitDie}'**
  String levelUpScreenHitDieMulticlassLabel(String className, int hitDie);

  /// Libellé du dé de vie, branche classe continuée, étape "Points de vie".
  ///
  /// In fr, this message translates to:
  /// **'Dé de vie de la classe : d{hitDie}'**
  String levelUpScreenHitDieClassLabel(int hitDie);

  /// Segment "Lancer le dé" du `SegmentedToggle` de méthode PV de l'étape "Points de vie".
  ///
  /// In fr, this message translates to:
  /// **'Lancer le dé (d{hitDie})'**
  String levelUpScreenRollHitDieOption(int hitDie);

  /// Segment "Valeur moyenne" du `SegmentedToggle` de méthode PV de l'étape "Points de vie".
  ///
  /// In fr, this message translates to:
  /// **'Valeur moyenne ({average})'**
  String levelUpScreenAverageHitDieOption(int average);

  /// Ligne "{modificateur} modificateur de Constitution" de l'étape "Points de vie" — `modifier` est déjà formaté avec son signe (`SignedModifierFormatter`).
  ///
  /// In fr, this message translates to:
  /// **'{modifier} modificateur de Constitution'**
  String levelUpScreenConstitutionModifierLabel(String modifier);

  /// Lien "Relancer le dé" de l'étape "Points de vie" (méthode "Lancer le dé").
  ///
  /// In fr, this message translates to:
  /// **'Relancer le dé'**
  String get levelUpScreenRerollDieLink;

  /// Rappel de la formule de valeur moyenne de l'étape "Points de vie" (méthode "Valeur moyenne").
  ///
  /// In fr, this message translates to:
  /// **'(moitié du dé arrondie au supérieur, +1)'**
  String get levelUpScreenAverageDieFormulaHint;

  /// Lien sous le bouton "Continuer" de l'étape "Points de vie" (aucun écran dédié n'existe encore, voir `_showLevelHistoryComingSoon`).
  ///
  /// In fr, this message translates to:
  /// **'Voir l\'historique des niveaux'**
  String get levelUpScreenLevelHistoryLink;

  /// `stepLabel` de l'étape "Aptitudes" sans maîtrises de multiclassage.
  ///
  /// In fr, this message translates to:
  /// **'Étape 2 sur {totalSteps} · Aptitudes de classe'**
  String levelUpScreenAbilitiesStepLabel(int totalSteps);

  /// `stepLabel` de l'étape "Aptitudes" avec maîtrises de multiclassage.
  ///
  /// In fr, this message translates to:
  /// **'Étape 2 sur {totalSteps} · Aptitudes & maîtrises'**
  String levelUpScreenAbilitiesStepLabelWithProficiencies(int totalSteps);

  /// Titre du bloc d'aptitudes automatiques de l'étape "Aptitudes".
  ///
  /// In fr, this message translates to:
  /// **'Vous obtenez automatiquement :'**
  String get levelUpScreenAutomaticFeaturesLabel;

  /// Titre du bloc "Maîtrises de multiclassage" de l'étape "Aptitudes".
  ///
  /// In fr, this message translates to:
  /// **'Maîtrises de multiclassage :'**
  String get levelUpScreenMulticlassProficienciesLabel;

  /// `stepLabel` de l'étape "Choix à faire" — `choiceLabel` est déjà résolu (voir `_choiceStepLabel`).
  ///
  /// In fr, this message translates to:
  /// **'Étape 3 sur {totalSteps} · {choiceLabel}'**
  String levelUpScreenChoiceStepLabel(int totalSteps, String choiceLabel);

  /// Libellé court de `LevelUpChoiceKind.abilityScoreImprovement` pour le `stepLabel`/récapitulatif.
  ///
  /// In fr, this message translates to:
  /// **'Amélioration ou don'**
  String get levelUpScreenChoiceKindAbilityScoreImprovement;

  /// Libellé court de `LevelUpChoiceKind.subclass`.
  ///
  /// In fr, this message translates to:
  /// **'Sous-classe'**
  String get levelUpScreenChoiceKindSubclass;

  /// Libellé court de `LevelUpChoiceKind.fightingStyle`.
  ///
  /// In fr, this message translates to:
  /// **'Style de combat'**
  String get levelUpScreenChoiceKindFightingStyle;

  /// Libellé court de `LevelUpChoiceKind.favoredEnemy`.
  ///
  /// In fr, this message translates to:
  /// **'Ennemi juré'**
  String get levelUpScreenChoiceKindFavoredEnemy;

  /// Libellé court de `LevelUpChoiceKind.pact`.
  ///
  /// In fr, this message translates to:
  /// **'Faveur de pacte'**
  String get levelUpScreenChoiceKindPact;

  /// Instruction de la variante liste "Sous-classe" de l'étape "Choix à faire".
  ///
  /// In fr, this message translates to:
  /// **'Choisissez une sous-classe.'**
  String get levelUpScreenChooseSubclassInstruction;

  /// Instruction de la variante liste "Style de combat" de l'étape "Choix à faire".
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un style de combat.'**
  String get levelUpScreenChooseFightingStyleInstruction;

  /// Instruction de la variante liste "Ennemi juré" de l'étape "Choix à faire".
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un ennemi juré.'**
  String get levelUpScreenChooseFavoredEnemyInstruction;

  /// Instruction de la variante liste "Faveur de pacte" de l'étape "Choix à faire".
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre Faveur de pacte.'**
  String get levelUpScreenChoosePactInstruction;

  /// Instruction du sous-état ASI-ou-don de l'étape "Choix à faire".
  ///
  /// In fr, this message translates to:
  /// **'Choisissez comment progresser.'**
  String get levelUpScreenChooseProgressionInstruction;

  /// Segment "Répartir +2" du `SegmentedToggle` ASI-ou-don de l'étape "Choix à faire".
  ///
  /// In fr, this message translates to:
  /// **'Répartir +2'**
  String get levelUpScreenAllocateAbilityOption;

  /// Segment "Choisir un don" du `SegmentedToggle` ASI-ou-don de l'étape "Choix à faire".
  ///
  /// In fr, this message translates to:
  /// **'Choisir un don'**
  String get levelUpScreenChooseFeatOption;

  /// Instruction de la variante liste "Don" de l'étape "Choix à faire".
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un don.'**
  String get levelUpScreenChooseFeatInstruction;

  /// Titre du sélecteur de caractéristique d'un demi-don à plusieurs choix, étape "Choix à faire".
  ///
  /// In fr, this message translates to:
  /// **'Caractéristique augmentée par {featName} (+1) :'**
  String levelUpScreenFeatAbilityIncreaseLabel(String featName);

  /// Instruction de la variante allocation ASI de l'étape "Choix à faire".
  ///
  /// In fr, this message translates to:
  /// **'Répartissez {budget} points entre vos caractéristiques.'**
  String levelUpScreenAllocateBudgetInstruction(int budget);

  /// Ligne "Points restants" de la variante allocation ASI de l'étape "Choix à faire".
  ///
  /// In fr, this message translates to:
  /// **'Points restants : {remaining}/{budget}'**
  String levelUpScreenPointsRemainingLabel(int remaining, int budget);

  /// Ligne affichée une fois le budget ASI entièrement réparti.
  ///
  /// In fr, this message translates to:
  /// **'Tous les points sont répartis.'**
  String get levelUpScreenAllPointsAllocatedLabel;

  /// Formule de delta de caractéristique de `_AllocationRow` (variante allocation ASI).
  ///
  /// In fr, this message translates to:
  /// **'{oldScore} → {newScore} (+{alloc})'**
  String levelUpScreenAbilityScoreDelta(int oldScore, int newScore, int alloc);

  /// `stepLabel` de l'étape "Sorts" quand seul un recalcul automatique d'emplacements est proposé (pas de sélection de sorts connus).
  ///
  /// In fr, this message translates to:
  /// **'Étape {stepNumber} sur {totalSteps} · Emplacements de sorts'**
  String levelUpScreenSpellSlotsStepLabel(int stepNumber, int totalSteps);

  /// Titre du bloc de recalcul des emplacements de sorts de l'étape "Sorts" (les deux variantes).
  ///
  /// In fr, this message translates to:
  /// **'Vos emplacements de sorts sont recalculés :'**
  String get levelUpScreenSpellSlotsRecalculatedLabel;

  /// Message affiché quand aucun changement d'emplacement de sorts n'est calculé pour ce niveau, étape "Sorts" (variante sélection de sorts connus).
  ///
  /// In fr, this message translates to:
  /// **'Aucun emplacement de sorts à ce niveau.'**
  String get levelUpScreenNoSpellSlotsAtThisLevel;

  /// `stepLabel` de l'étape "Sorts" quand une sélection de nouveaux sorts/cantrips connus est proposée.
  ///
  /// In fr, this message translates to:
  /// **'Étape {stepNumber} sur {totalSteps} · Sorts'**
  String levelUpScreenSpellsStepLabel(int stepNumber, int totalSteps);

  /// Onglet "Mineurs" (sorts mineurs) du sélecteur de l'étape "Sorts".
  ///
  /// In fr, this message translates to:
  /// **'Mineurs'**
  String get levelUpScreenCantripTab;

  /// Onglet "Sorts" (niveau 1+) du sélecteur de l'étape "Sorts".
  ///
  /// In fr, this message translates to:
  /// **'Sorts'**
  String get levelUpScreenSpellsTab;

  /// Onglet "Grimoire" (Livre des ombres, Pacte du grimoire) du sélecteur de l'étape "Sorts".
  ///
  /// In fr, this message translates to:
  /// **'Grimoire'**
  String get levelUpScreenPactTab;

  /// Titre de section de l'onglet "Mineurs" de l'étape "Sorts", déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'SORTS MINEURS CONNUS'**
  String get levelUpScreenKnownCantripsTitle;

  /// Titre de section de l'onglet "Grimoire" de l'étape "Sorts", déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'LIVRE DES OMBRES'**
  String get levelUpScreenShadowBookTitle;

  /// Titre de section de l'onglet "Sorts" de l'étape "Sorts", déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'NOUVEAUX SORTS CONNUS'**
  String get levelUpScreenKnownSpellsTitle;

  /// Badge "X / Y" de `_QuotaBadge`, partagé par toutes les étapes à quota (Sorts, Invocations, Disciplines élémentaires, Manœuvres, Tirs arcaniques, Runes, Infusions, Métamagie, Expertise).
  ///
  /// In fr, this message translates to:
  /// **'{selected} / {quota}'**
  String levelUpScreenQuotaBadge(int selected, int quota);

  /// Sous-titre d'une tuile de sort candidat de la section "NOUVEAUX SORTS CONNUS" — `metaLine` est déjà résolu (`SpellOption.metaLine`).
  ///
  /// In fr, this message translates to:
  /// **'{metaLine} (niveau {level})'**
  String levelUpScreenSpellMetaLineWithLevel(String metaLine, int level);

  /// Sous-titre d'un sort de la liste étendue du patron (Occultiste) — `baseSubtitle` est déjà résolu.
  ///
  /// In fr, this message translates to:
  /// **'{baseSubtitle} · Patron'**
  String levelUpScreenPatronSpellSubtitle(String baseSubtitle);

  /// `stepLabel` de l'étape "Invocations" (Occultiste).
  ///
  /// In fr, this message translates to:
  /// **'Étape {stepNumber} sur {totalSteps} · Invocations'**
  String levelUpScreenInvocationsStepLabel(int stepNumber, int totalSteps);

  /// Titre de section de l'étape "Invocations", déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'INVOCATIONS CONNUES'**
  String get levelUpScreenKnownInvocationsTitle;

  /// Message d'état vide de l'étape "Invocations" (cas attendu, pas seulement défensif).
  ///
  /// In fr, this message translates to:
  /// **'Vous connaissez déjà toutes les invocations occultistes disponibles.'**
  String get levelUpScreenNoMoreInvocationsMessage;

  /// `stepLabel` de l'étape "Disciplines élémentaires" (Moine, Voie des quatre éléments).
  ///
  /// In fr, this message translates to:
  /// **'Étape {stepNumber} sur {totalSteps} · Disciplines élémentaires'**
  String levelUpScreenElementalDisciplinesStepLabel(
    int stepNumber,
    int totalSteps,
  );

  /// Titre de section de l'étape "Disciplines élémentaires", déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'DISCIPLINES ÉLÉMENTAIRES CONNUES'**
  String get levelUpScreenKnownElementalDisciplinesTitle;

  /// Message d'état vide de l'étape "Disciplines élémentaires".
  ///
  /// In fr, this message translates to:
  /// **'Vous connaissez déjà toutes les disciplines élémentaires disponibles à ce niveau.'**
  String get levelUpScreenNoMoreElementalDisciplinesMessage;

  /// `stepLabel` de l'étape "Manœuvres" (Guerrier, Maître de guerre).
  ///
  /// In fr, this message translates to:
  /// **'Étape {stepNumber} sur {totalSteps} · Manœuvres'**
  String levelUpScreenManeuversStepLabel(int stepNumber, int totalSteps);

  /// Titre de section de l'étape "Manœuvres", déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'MANŒUVRES CONNUES'**
  String get levelUpScreenKnownManeuversTitle;

  /// Message d'état vide de l'étape "Manœuvres".
  ///
  /// In fr, this message translates to:
  /// **'Vous connaissez déjà toutes les manœuvres disponibles.'**
  String get levelUpScreenNoMoreManeuversMessage;

  /// `stepLabel` de l'étape "Tirs arcaniques" (Guerrier, Archer arcanique).
  ///
  /// In fr, this message translates to:
  /// **'Étape {stepNumber} sur {totalSteps} · Tirs arcaniques'**
  String levelUpScreenArcaneShotsStepLabel(int stepNumber, int totalSteps);

  /// Titre de section de l'étape "Tirs arcaniques", déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'TIRS ARCANIQUES CONNUS'**
  String get levelUpScreenKnownArcaneShotsTitle;

  /// Message d'état vide de l'étape "Tirs arcaniques".
  ///
  /// In fr, this message translates to:
  /// **'Vous connaissez déjà tous les tirs arcaniques disponibles.'**
  String get levelUpScreenNoMoreArcaneShotsMessage;

  /// `stepLabel` de l'étape "Runes" (Guerrier, Chevalier runique).
  ///
  /// In fr, this message translates to:
  /// **'Étape {stepNumber} sur {totalSteps} · Runes'**
  String levelUpScreenRunesStepLabel(int stepNumber, int totalSteps);

  /// Titre de section de l'étape "Runes", déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'RUNES CONNUES'**
  String get levelUpScreenKnownRunesTitle;

  /// Message d'état vide de l'étape "Runes".
  ///
  /// In fr, this message translates to:
  /// **'Vous connaissez déjà toutes les runes disponibles.'**
  String get levelUpScreenNoMoreRunesMessage;

  /// `stepLabel` de l'étape "Infusions" (Artificier).
  ///
  /// In fr, this message translates to:
  /// **'Étape {stepNumber} sur {totalSteps} · Infusions'**
  String levelUpScreenInfusionsStepLabel(int stepNumber, int totalSteps);

  /// Titre de section "Nouvelles infusions" de l'étape "Infusions", déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'NOUVELLES INFUSIONS'**
  String get levelUpScreenNewInfusionsTitle;

  /// Message d'état vide de la section "Nouvelles infusions" de l'étape "Infusions".
  ///
  /// In fr, this message translates to:
  /// **'Vous connaissez déjà toutes les infusions disponibles.'**
  String get levelUpScreenNoMoreInfusionsMessage;

  /// Titre de section "Remplacer une infusion" de l'étape "Infusions", déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'REMPLACER UNE INFUSION (OPTIONNEL)'**
  String get levelUpScreenReplaceInfusionOptionalTitle;

  /// Titre "REMPLACÉE PAR" de la sous-section échange, étapes "Infusions" et "Métamagie", déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'REMPLACÉE PAR'**
  String get levelUpScreenReplacedByLabel;

  /// `stepLabel` de l'étape "Métamagie" (Ensorceleur).
  ///
  /// In fr, this message translates to:
  /// **'Étape {stepNumber} sur {totalSteps} · Métamagie'**
  String levelUpScreenMetamagicStepLabel(int stepNumber, int totalSteps);

  /// Titre de section "Nouvelles options" de l'étape "Métamagie", déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'NOUVELLES OPTIONS DE MÉTAMAGIE'**
  String get levelUpScreenNewMetamagicOptionsTitle;

  /// Message d'état vide de la section "Nouvelles options" de l'étape "Métamagie".
  ///
  /// In fr, this message translates to:
  /// **'Vous connaissez déjà toutes les options de Métamagie disponibles.'**
  String get levelUpScreenNoMoreMetamagicMessage;

  /// Titre de section "Remplacer une option" de l'étape "Métamagie", déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'REMPLACER UNE OPTION (OPTIONNEL)'**
  String get levelUpScreenReplaceMetamagicOptionalTitle;

  /// `stepLabel` de l'étape "Expertise" (Barde/Roublard).
  ///
  /// In fr, this message translates to:
  /// **'Étape {stepNumber} sur {totalSteps} · Expertise'**
  String levelUpScreenExpertiseStepLabel(int stepNumber, int totalSteps);

  /// Titre de section de l'étape "Expertise", déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'COMPÉTENCES EN EXPERTISE'**
  String get levelUpScreenExpertiseSkillsTitle;

  /// Libellé "Outils de voleur" — tuile de substitution de l'étape "Expertise" et récapitulatif (Roublard, édition 2014).
  ///
  /// In fr, this message translates to:
  /// **'Outils de voleur'**
  String get levelUpScreenThievesToolsLabel;

  /// Sous-titre de la tuile de substitution "Outils de voleur" de l'étape "Expertise".
  ///
  /// In fr, this message translates to:
  /// **'Substitue une des places d\'Expertise à la maîtrise des outils de voleur.'**
  String get levelUpScreenThievesToolsSubstitutionHint;

  /// Message d'état vide de l'étape "Expertise" (aucune compétence candidate).
  ///
  /// In fr, this message translates to:
  /// **'Aucune compétence déjà maîtrisée à faire passer en Expertise.'**
  String get levelUpScreenNoExpertiseCandidatesMessage;

  /// `stepLabel` de l'étape "Ascendance draconique" (Ensorceleur, Lignage draconique, niveau 1 de sous-classe).
  ///
  /// In fr, this message translates to:
  /// **'Étape {stepNumber} sur {totalSteps} · Ascendance draconique'**
  String levelUpScreenDraconicAncestryStepLabel(int stepNumber, int totalSteps);

  /// Titre de section de l'étape "Ascendance draconique", déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'TYPE DE DÉGÂTS'**
  String get levelUpScreenDamageTypeTitle;

  /// Titre de `GainRow` "Nouveaux emplacements de sorts" (déblocage net d'un palier) — étape "Sorts" et récapitulatif.
  ///
  /// In fr, this message translates to:
  /// **'Nouveaux emplacements de sorts'**
  String get levelUpScreenNewSpellSlotsTitle;

  /// Titre de `GainRow` "Emplacements de sorts renforcés" (renfort d'un palier déjà actif) — étape "Sorts" et récapitulatif.
  ///
  /// In fr, this message translates to:
  /// **'Emplacements de sorts renforcés'**
  String get levelUpScreenReinforcedSpellSlotsTitle;

  /// Sous-titre de `GainRow` d'un palier d'emplacements nouvellement débloqué.
  ///
  /// In fr, this message translates to:
  /// **'Niveau {spellLevel} débloqué'**
  String levelUpScreenSpellSlotUnlockedSubtitle(int spellLevel);

  /// Sous-titre de `GainRow` d'un palier d'emplacements renforcé.
  ///
  /// In fr, this message translates to:
  /// **'Niveau {spellLevel} : {oldTotal} → {newTotal} (+{delta})'**
  String levelUpScreenSpellSlotReinforcedSubtitle(
    int spellLevel,
    int oldTotal,
    int newTotal,
    int delta,
  );

  /// Titre de `GainRow` de magie de pacte (Occultiste), premier dip.
  ///
  /// In fr, this message translates to:
  /// **'Magie de pacte débloquée'**
  String get levelUpScreenPactMagicUnlockedTitle;

  /// Sous-titre de `GainRow` de magie de pacte, premier dip.
  ///
  /// In fr, this message translates to:
  /// **'Niveau {slotLevel} · {charges} charge(s)'**
  String levelUpScreenPactMagicUnlockedSubtitle(int slotLevel, int charges);

  /// Titre de `GainRow` de magie de pacte, charges renforcées (niveau de charge inchangé, ou les deux changent).
  ///
  /// In fr, this message translates to:
  /// **'Charges de pacte renforcées'**
  String get levelUpScreenPactChargesReinforcedTitle;

  /// Sous-titre de `GainRow` de magie de pacte, charges renforcées à niveau de charge inchangé.
  ///
  /// In fr, this message translates to:
  /// **'{oldCharges} → {newCharges} charges (niveau {slotLevel})'**
  String levelUpScreenPactChargesReinforcedSubtitle(
    int oldCharges,
    int newCharges,
    int slotLevel,
  );

  /// Titre de `GainRow` de magie de pacte, niveau de charge amélioré à charges inchangées.
  ///
  /// In fr, this message translates to:
  /// **'Charges de pacte améliorées'**
  String get levelUpScreenPactChargesImprovedTitle;

  /// Sous-titre de `GainRow` de magie de pacte, niveau de charge amélioré à charges inchangées.
  ///
  /// In fr, this message translates to:
  /// **'Niveau {oldSlotLevel} → {newSlotLevel} ({newCharges} charges)'**
  String levelUpScreenPactChargesImprovedSubtitle(
    int oldSlotLevel,
    int newSlotLevel,
    int newCharges,
  );

  /// Sous-titre de `GainRow` de magie de pacte, charges ET niveau de charge changent à la fois.
  ///
  /// In fr, this message translates to:
  /// **'{oldCharges} → {newCharges} charges, niveau {oldSlotLevel} → {newSlotLevel}'**
  String levelUpScreenPactChargesBothSubtitle(
    int oldCharges,
    int newCharges,
    int oldSlotLevel,
    int newSlotLevel,
  );

  /// Titre de `GainRow` du récapitulatif, étape "Choix à faire" en mode don (ASI).
  ///
  /// In fr, this message translates to:
  /// **'Don'**
  String get levelUpScreenFeatSummaryTitle;

  /// Sous-titre de `GainRow` du récapitulatif, don avec augmentation de caractéristique choisie.
  ///
  /// In fr, this message translates to:
  /// **'{featName} ({abilityLabel} +1)'**
  String levelUpScreenFeatAbilityBonusSubtitle(
    String featName,
    String abilityLabel,
  );

  /// Un élément de la liste jointe du sous-titre de `GainRow` du récapitulatif, mode allocation ASI.
  ///
  /// In fr, this message translates to:
  /// **'{label} +{amount}'**
  String levelUpScreenAbilityAllocationSummaryItem(String label, int amount);

  /// Titre de `GainRow` du récapitulatif, étape "Choix à faire" en mode allocation ASI.
  ///
  /// In fr, this message translates to:
  /// **'Amélioration de caractéristique'**
  String get levelUpScreenAbilityScoreImprovementTitle;

  /// Titre de `GainRow` du récapitulatif, bloc "Sorts appris" (sorts mineurs).
  ///
  /// In fr, this message translates to:
  /// **'Nouveaux sorts mineurs'**
  String get levelUpScreenNewCantripsTitle;

  /// Titre de `GainRow` du récapitulatif, bloc "Sorts appris" (niveau 1+).
  ///
  /// In fr, this message translates to:
  /// **'Nouveaux sorts appris'**
  String get levelUpScreenNewSpellsLearnedTitle;

  /// Titre de `GainRow` du récapitulatif, bloc "Sorts appris" (Livre des ombres).
  ///
  /// In fr, this message translates to:
  /// **'Livre des ombres'**
  String get levelUpScreenShadowBookGainTitle;

  /// Titre de `GainRow` du récapitulatif, ajout du sort "Appel de familier" (Pacte de la chaîne).
  ///
  /// In fr, this message translates to:
  /// **'Appel de familier ajouté'**
  String get levelUpScreenFamiliarAddedTitle;

  /// Sous-titre de `GainRow` "Appel de familier ajouté".
  ///
  /// In fr, this message translates to:
  /// **'Pacte de la chaîne'**
  String get levelUpScreenChainPactSubtitle;

  /// Titre de `GainRow` du récapitulatif, un sort inné racial nouvellement accordé.
  ///
  /// In fr, this message translates to:
  /// **'Sort inné racial'**
  String get levelUpScreenRacialInnateSpellTitle;

  /// Titre de `GainRow` du récapitulatif, bloc "Invocation(s)".
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Nouvelle invocation occultiste} other{Nouvelles invocations occultistes}}'**
  String levelUpScreenNewInvocationsSummaryTitle(int count);

  /// Titre de `GainRow` du récapitulatif, bloc "Discipline(s) élémentaire(s)".
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Nouvelle discipline élémentaire} other{Nouvelles disciplines élémentaires}}'**
  String levelUpScreenNewElementalDisciplinesSummaryTitle(int count);

  /// Titre de `GainRow` du récapitulatif, bloc "Manœuvre(s)".
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Nouvelle manœuvre} other{Nouvelles manœuvres}}'**
  String levelUpScreenNewManeuversSummaryTitle(int count);

  /// Titre de `GainRow` du récapitulatif, bloc "Tir(s) arcanique(s)".
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Nouveau tir arcanique} other{Nouveaux tirs arcaniques}}'**
  String levelUpScreenNewArcaneShotsSummaryTitle(int count);

  /// Titre de `GainRow` du récapitulatif, bloc "Rune(s)".
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Nouvelle rune} other{Nouvelles runes}}'**
  String levelUpScreenNewRunesSummaryTitle(int count);

  /// Titre de `GainRow` du récapitulatif, bloc "Infusion(s)".
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Nouvelle infusion} other{Nouvelles infusions}}'**
  String levelUpScreenNewInfusionsSummaryTitle(int count);

  /// Titre de `GainRow` du récapitulatif, échange d'infusion.
  ///
  /// In fr, this message translates to:
  /// **'Infusion remplacée'**
  String get levelUpScreenInfusionSwapTitle;

  /// Sous-titre de `GainRow` du récapitulatif, échange d'infusion ou de Métamagie.
  ///
  /// In fr, this message translates to:
  /// **'{removedName} → {addedName}'**
  String levelUpScreenSwapSubtitle(String removedName, String addedName);

  /// Titre de `GainRow` du récapitulatif, bloc "Métamagie".
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Nouvelle option de Métamagie} other{Nouvelles options de Métamagie}}'**
  String levelUpScreenNewMetamagicOptionsSummaryTitle(int count);

  /// Titre de `GainRow` du récapitulatif, échange de Métamagie.
  ///
  /// In fr, this message translates to:
  /// **'Métamagie remplacée'**
  String get levelUpScreenMetamagicSwapTitle;

  /// Titre de `GainRow` du récapitulatif, bloc "Expertise".
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Expertise} other{Expertises}}'**
  String levelUpScreenExpertiseSummaryTitle(int count);

  /// Titre de `GainRow` du récapitulatif, bloc "Ascendance draconique".
  ///
  /// In fr, this message translates to:
  /// **'Ascendance draconique'**
  String get levelUpScreenDraconicAncestryTitle;

  /// Message de `_EmptyFeaturesState` (état vide de l'étape "Aptitudes").
  ///
  /// In fr, this message translates to:
  /// **'Aucune nouvelle aptitude de classe à ce niveau.'**
  String get levelUpScreenNoNewFeaturesMessage;

  /// Message générique de repli de `_EmptyChoiceState` (étape "Choix à faire", cas défensif).
  ///
  /// In fr, this message translates to:
  /// **'Aucune option disponible pour ce choix.'**
  String get levelUpScreenNoOptionAvailableMessage;

  /// Titre de l'écran de blocage (`_buildBlocked`) — `level` est le niveau DANS la classe concernée, jamais le niveau total.
  ///
  /// In fr, this message translates to:
  /// **'Niveau {level} : choix requis'**
  String levelUpScreenBlockedLevelTitle(int level);

  /// Bouton primaire de l'écran de blocage (`_buildBlocked`).
  ///
  /// In fr, this message translates to:
  /// **'Retour à la fiche'**
  String get levelUpScreenBackToSheetButton;

  /// Bouton secondaire "Réessayer" de `_ErrorState`.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get levelUpScreenRetryButton;

  /// Titre de `CharacterClassChoicesCard`, onglet "Compétences".
  ///
  /// In fr, this message translates to:
  /// **'CHOIX DE CLASSE'**
  String get characterClassChoicesCardTitle;

  /// Libellé d'une entrée "Sous-classe" quand une seule classe du personnage a une sous-classe choisie (cas le plus courant).
  ///
  /// In fr, this message translates to:
  /// **'Sous-classe'**
  String get characterClassChoicesCardSubclassLabel;

  /// Libellé d'une entrée "Sous-classe" désambiguïsé par nom de classe, quand plus d'une classe du personnage a une sous-classe choisie (multiclassage).
  ///
  /// In fr, this message translates to:
  /// **'Sous-classe ({className})'**
  String characterClassChoicesCardSubclassLabelWithClass(String className);

  /// Titre par défaut de `CharacterClassFeaturesCard` (surchargeable via son paramètre `title`, voir `character_spells_tab_body.dart`).
  ///
  /// In fr, this message translates to:
  /// **'APTITUDES DE CLASSE'**
  String get characterClassFeaturesCardTitle;

  /// Libellé affiché à droite d'une aptitude de classe passive (sans compteur d'usage), carte `CharacterClassFeaturesCard`.
  ///
  /// In fr, this message translates to:
  /// **'Passive'**
  String get characterClassFeaturesCardPassiveLabel;

  /// Titre de `CharacterFeatsCard`, onglet "Aptitudes".
  ///
  /// In fr, this message translates to:
  /// **'DONS'**
  String get characterFeatsCardTitle;

  /// Titre de `CharacterRacialTraitsCard`, onglet "Aptitudes".
  ///
  /// In fr, this message translates to:
  /// **'TRAITS RACIAUX'**
  String get characterRacialTraitsCardTitle;

  /// Libellé affiché à droite de chaque trait racial, toujours "Passive" (décision tranchée, voir la doc de classe de `CharacterRacialTraitsCard`).
  ///
  /// In fr, this message translates to:
  /// **'Passive'**
  String get characterRacialTraitsCardPassiveLabel;

  /// Titre de `CharacterRaceChoicesCard`, onglet "Compétences".
  ///
  /// In fr, this message translates to:
  /// **'CHOIX DE RACE'**
  String get characterRaceChoicesCardTitle;

  /// Libellé d'une entrée de compétence de race à choix, carte `CharacterRaceChoicesCard`.
  ///
  /// In fr, this message translates to:
  /// **'Compétence'**
  String get characterRaceChoicesCardSkillLabel;

  /// Libellé d'une entrée d'outil de race à choix, carte `CharacterRaceChoicesCard`.
  ///
  /// In fr, this message translates to:
  /// **'Outil'**
  String get characterRaceChoicesCardToolLabel;

  /// Titre de `CharacterArmorProficienciesCard`, onglet "Compétences".
  ///
  /// In fr, this message translates to:
  /// **'MAÎTRISES D\'ARMURES'**
  String get characterArmorProficienciesCardTitle;

  /// Titre de `CharacterWeaponProficienciesCard`, onglet "Compétences".
  ///
  /// In fr, this message translates to:
  /// **'MAÎTRISES D\'ARMES'**
  String get characterWeaponProficienciesCardTitle;

  /// Titre de `CharacterToolProficienciesCard`, onglet "Compétences".
  ///
  /// In fr, this message translates to:
  /// **'MAÎTRISES D\'OUTILS'**
  String get characterToolProficienciesCardTitle;

  /// Titre de `CharacterLanguagesCard`, onglet "Compétences".
  ///
  /// In fr, this message translates to:
  /// **'LANGUES CONNUES'**
  String get characterLanguagesCardTitle;

  /// Titre de `CharacterInvocationsCard`, onglet "Compétences".
  ///
  /// In fr, this message translates to:
  /// **'INVOCATIONS CONNUES'**
  String get characterInvocationsCardTitle;

  /// Titre de `CharacterPactWeaponCard`, onglet "Personnage" (Occultiste, Pacte de la lame).
  ///
  /// In fr, this message translates to:
  /// **'ARME DE PACTE'**
  String get characterPactWeaponCardTitle;

  /// Ligne d'information affichée quand la sous-classe du personnage est Lame maudite, carte `CharacterPactWeaponCard`.
  ///
  /// In fr, this message translates to:
  /// **'Lame maudite : vous pouvez utiliser le Charisme à la place de la Force ou de la Dextérité pour l\'attaque et les dégâts.'**
  String get characterPactWeaponCardCursedBladeText;

  /// Rappel de règle toujours affiché en pied de `CharacterPactWeaponCard`.
  ///
  /// In fr, this message translates to:
  /// **'Invoquée par une action. Disparaît si elle reste à plus de 1,50 m de vous pendant 1 minute, ou si vous l\'invoquez à nouveau.'**
  String get characterPactWeaponCardReminderText;

  /// Chip "Arme magique" de `CharacterPactWeaponCard` quand une forme est choisie.
  ///
  /// In fr, this message translates to:
  /// **'Arme magique'**
  String get characterPactWeaponCardMagicWeaponChip;

  /// Chip "Maîtrisée" de `CharacterPactWeaponCard` quand une forme est choisie.
  ///
  /// In fr, this message translates to:
  /// **'Maîtrisée'**
  String get characterPactWeaponCardProficientChip;

  /// Titre de l'état vide de `CharacterPactWeaponCard` (aucune forme choisie encore).
  ///
  /// In fr, this message translates to:
  /// **'Aucune forme choisie'**
  String get characterPactWeaponCardEmptyTitle;

  /// Description de l'état vide de `CharacterPactWeaponCard`.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez la forme que prend votre arme lorsque vous l\'invoquez.'**
  String get characterPactWeaponCardEmptyDescription;

  /// Libellé du bouton de `CharacterPactWeaponCard` quand aucune forme n'est encore choisie.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une forme'**
  String get characterPactWeaponCardChooseFormButton;

  /// Libellé du bouton de `CharacterPactWeaponCard` quand une forme est déjà choisie.
  ///
  /// In fr, this message translates to:
  /// **'Changer de forme'**
  String get characterPactWeaponCardChangeFormButton;

  /// Libellé d'accessibilité (`Semantics.label`) de la forme choisie quand aucun dé de dégâts n'est connu, `CharacterPactWeaponCard`.
  ///
  /// In fr, this message translates to:
  /// **'Arme de pacte : {name}'**
  String characterPactWeaponCardSemanticLabel(String name);

  /// Libellé d'accessibilité (`Semantics.label`) de la forme choisie quand un dé de dégâts est connu, `CharacterPactWeaponCard`.
  ///
  /// In fr, this message translates to:
  /// **'Arme de pacte : {name}, {damage}'**
  String characterPactWeaponCardSemanticLabelWithDamage(
    String name,
    String damage,
  );

  /// Libellé de l'action "Infos" de `showClassFeatureActionSheet`.
  ///
  /// In fr, this message translates to:
  /// **'Infos'**
  String get classFeatureActionSheetInfoLabel;

  /// Libellé de l'action "Utiliser" de `showClassFeatureActionSheet`.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser'**
  String get classFeatureActionSheetUseLabel;

  /// Texte de fin de ligne de l'action "Utiliser" quand l'aptitude n'a plus d'utilisation restante, `showClassFeatureActionSheet`.
  ///
  /// In fr, this message translates to:
  /// **'Épuisée'**
  String get classFeatureActionSheetExhaustedLabel;

  /// Ligne "niveau d'obtention" du panneau "Infos" d'une aptitude de classe, `showClassFeatureInfoPanel`.
  ///
  /// In fr, this message translates to:
  /// **'Obtenue au niveau {level}.'**
  String classFeatureInfoPanelObtainedAtLevel(int level);

  /// Libellé de la ligne "Utilisations" du panneau "Infos" d'une aptitude de classe, `showClassFeatureInfoPanel`.
  ///
  /// In fr, this message translates to:
  /// **'Utilisations'**
  String get classFeatureInfoPanelUsesLabel;

  /// Valeur de la ligne "Utilisations" quand l'aptitude est passive, `showClassFeatureInfoPanel`.
  ///
  /// In fr, this message translates to:
  /// **'Passive'**
  String get classFeatureInfoPanelPassiveLabel;

  /// Titre de section "DESCRIPTION" du panneau "Infos" d'une aptitude de classe, `showClassFeatureInfoPanel`.
  ///
  /// In fr, this message translates to:
  /// **'DESCRIPTION'**
  String get classFeatureInfoPanelDescriptionLabel;

  /// Repli affiché quand la description de l'aptitude est vide, `showClassFeatureInfoPanel`.
  ///
  /// In fr, this message translates to:
  /// **'Description indisponible.'**
  String get classFeatureInfoPanelDescriptionUnavailable;

  /// Bouton primaire de pied du panneau "Infos" d'une aptitude de classe à usage limité, `showClassFeatureInfoPanel`.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser'**
  String get classFeatureInfoPanelUseButton;

  /// Ligne "Prérequis" du panneau "Infos" d'un don, `showFeatInfoPanel`, quand renseigné.
  ///
  /// In fr, this message translates to:
  /// **'Prérequis : {prerequisite}'**
  String featInfoPanelPrerequisiteLabel(String prerequisite);

  /// Titre de section "DESCRIPTION" du panneau "Infos" d'un don, `showFeatInfoPanel`.
  ///
  /// In fr, this message translates to:
  /// **'DESCRIPTION'**
  String get featInfoPanelDescriptionLabel;

  /// Titre de section "DESCRIPTION" du panneau "Infos" d'un trait racial, `showRacialTraitInfoPanel`.
  ///
  /// In fr, this message translates to:
  /// **'DESCRIPTION'**
  String get racialTraitInfoPanelDescriptionLabel;

  /// Repli affiché quand la description du trait racial est vide, `showRacialTraitInfoPanel`.
  ///
  /// In fr, this message translates to:
  /// **'Description indisponible.'**
  String get racialTraitInfoPanelDescriptionUnavailable;

  /// Message d'erreur de chargement du catalogue, `showProficiencyDetailPanel`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger le catalogue. Réessayez.'**
  String get proficiencyDetailPanelLoadErrorMessage;

  /// Message d'état vide dédié au token 'boucliers (non métalliques)', toujours vide dans ce catalogue — voir `DruidNonMetallicEquipment`.
  ///
  /// In fr, this message translates to:
  /// **'Aucun bouclier non métallique disponible dans le catalogue actuel.'**
  String get proficiencyDetailPanelNoNonMetallicShieldMessage;

  /// Message d'état vide générique de repli (cas défensif, non couvert par la spec direction-artistique), `showProficiencyDetailPanel`.
  ///
  /// In fr, this message translates to:
  /// **'Aucun objet correspondant disponible dans le catalogue actuel.'**
  String get proficiencyDetailPanelNoMatchingItemMessage;

  /// Préfixe de la ligne "Propriétés" d'une arme, `showProficiencyDetailPanel`.
  ///
  /// In fr, this message translates to:
  /// **'Propriétés : '**
  String get proficiencyDetailPanelPropertiesLabel;

  /// Libellé de la ligne "CA" du gabarit réduit d'un bouclier, `showProficiencyDetailPanel`.
  ///
  /// In fr, this message translates to:
  /// **'CA'**
  String get proficiencyDetailPanelAcLabel;

  /// Libellé de la ligne "CA de base" du gabarit complet d'une armure, `showProficiencyDetailPanel`.
  ///
  /// In fr, this message translates to:
  /// **'CA de base'**
  String get proficiencyDetailPanelAcBaseLabel;

  /// Libellé de la ligne "Bonus Dex" du gabarit complet d'une armure, `showProficiencyDetailPanel`.
  ///
  /// In fr, this message translates to:
  /// **'Bonus Dex'**
  String get proficiencyDetailPanelDexBonusLabel;

  /// Libellé de la ligne "Force requise" du gabarit complet d'une armure, quand renseignée, `showProficiencyDetailPanel`.
  ///
  /// In fr, this message translates to:
  /// **'Force requise'**
  String get proficiencyDetailPanelStrengthRequirementLabel;

  /// Libellé de la ligne "Désavantage discrétion" du gabarit complet d'une armure, quand vrai, `showProficiencyDetailPanel`.
  ///
  /// In fr, this message translates to:
  /// **'Désavantage discrétion'**
  String get proficiencyDetailPanelStealthDisadvantageLabel;

  /// Valeur de la ligne "Désavantage discrétion" quand vrai, `showProficiencyDetailPanel`.
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get proficiencyDetailPanelYesLabel;

  /// Titre de la feuille `showPactWeaponPickerSheet`.
  ///
  /// In fr, this message translates to:
  /// **'FORME DE L\'ARME'**
  String get pactWeaponPickerSheetTitle;

  /// Texte d'indice du champ de recherche de `showPactWeaponPickerSheet`.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une arme...'**
  String get pactWeaponPickerSheetSearchHint;

  /// Message d'erreur de chargement des armes éligibles, `showPactWeaponPickerSheet`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les armes. Réessayez.'**
  String get pactWeaponPickerSheetLoadErrorMessage;

  /// Message d'état vide (catalogue sans arme éligible), `showPactWeaponPickerSheet`.
  ///
  /// In fr, this message translates to:
  /// **'Aucune arme disponible.'**
  String get pactWeaponPickerSheetEmptyMessage;

  /// Message affiché quand la recherche ne trouve aucune arme, `showPactWeaponPickerSheet`.
  ///
  /// In fr, this message translates to:
  /// **'Aucune arme trouvée.'**
  String get pactWeaponPickerSheetNoResultsMessage;

  /// Titre de la feuille `showWeaponSlotPickerSheet`.
  ///
  /// In fr, this message translates to:
  /// **'CHOISIR UN SET'**
  String get weaponSlotPickerSheetTitle;

  /// Texte affiché en fin de ligne pour un set sans arme équipée, `showWeaponSlotPickerSheet`.
  ///
  /// In fr, this message translates to:
  /// **'Vide'**
  String get weaponSlotPickerSheetEmptyLabel;

  /// Libellé du bouton "Filtre" en tête de liste de l'onglet "Inventaire" (`CompactActionButton`) — `filterLabel` reste `InventoryCategoryFilter.label`, non traduit (classe domain sans `BuildContext`, hors périmètre de ce lot, voir le registre de dette technique).
  ///
  /// In fr, this message translates to:
  /// **'Filtre : {filterLabel}'**
  String characterInventoryTabBodyFilterButtonLabel(String filterLabel);

  /// Libellé de la tuile pointillée "+ Objet" en pied de l'onglet "Inventaire" (`DashedAddTile`).
  ///
  /// In fr, this message translates to:
  /// **'Objet'**
  String get characterInventoryTabBodyAddItemButtonLabel;

  /// Libellé du bouton "Récompense" en pied de l'onglet "Inventaire" (`_RewardButton`).
  ///
  /// In fr, this message translates to:
  /// **'RÉCOMPENSE'**
  String get characterInventoryTabBodyRewardButtonLabel;

  /// Message affiché quand au moins un objet existe dans l'inventaire mais qu'aucun ne correspond au filtre de catégorie actif (`_NoFilterMatchState`).
  ///
  /// In fr, this message translates to:
  /// **'Aucun objet dans cette catégorie.'**
  String get characterInventoryTabBodyNoFilterMatchMessage;

  /// Titre de l'état vide de l'onglet "Inventaire" (`_EmptyInventoryState`), aucun objet du tout dans l'inventaire.
  ///
  /// In fr, this message translates to:
  /// **'INVENTAIRE VIDE'**
  String get characterInventoryTabBodyEmptyTitle;

  /// Sous-titre de l'état vide de l'onglet "Inventaire" (`_EmptyInventoryState`).
  ///
  /// In fr, this message translates to:
  /// **'Aucun objet dans cet inventaire pour l\'instant.'**
  String get characterInventoryTabBodyEmptyMessage;

  /// Sous-titre d'une carte d'objet de l'onglet "Inventaire" (`CharacterInventoryItemCard`) — `category` reste `InventoryCategoryRules.labelFor`, non traduit (classe domain sans `BuildContext`, hors périmètre de ce lot, voir le registre de dette technique).
  ///
  /// In fr, this message translates to:
  /// **'{category} · x{quantity}'**
  String characterInventoryItemCardSubtitle(String category, int quantity);

  /// Badge affiché à droite d'un objet équipé, à la place de son poids (`_EquippedBadge`).
  ///
  /// In fr, this message translates to:
  /// **'ÉQUIPÉ'**
  String get characterInventoryItemCardEquippedBadge;

  /// Poids affiché à droite d'un objet non équipé (`_Trailing`) — unité métrique volontairement gardée telle quelle en anglais aussi, même rationale que `characterStatPillsSpeedValue`.
  ///
  /// In fr, this message translates to:
  /// **'{weight} kg'**
  String characterInventoryItemCardWeightValue(String weight);

  /// Titre de la jauge "CHARGE" de l'onglet "Inventaire" (`CharacterInventoryCapacityGauge`).
  ///
  /// In fr, this message translates to:
  /// **'CHARGE'**
  String get characterInventoryCapacityGaugeTitle;

  /// Valeur "poids porté / capacité" affichée à droite du titre de la jauge "CHARGE" — unité métrique volontairement gardée telle quelle en anglais aussi, même rationale que `characterStatPillsSpeedValue`.
  ///
  /// In fr, this message translates to:
  /// **'{weight} / {capacity} kg'**
  String characterInventoryCapacityGaugeValueLabel(
    String weight,
    String capacity,
  );

  /// Message d'alerte affiché sous la jauge "CHARGE" quand le poids porté dépasse la capacité de transport.
  ///
  /// In fr, this message translates to:
  /// **'Surchargé — poids supérieur à la capacité de transport.'**
  String get characterInventoryCapacityGaugeOverloadedWarning;

  /// Libellé d'accessibilité de la jauge "CHARGE", cas non surchargé.
  ///
  /// In fr, this message translates to:
  /// **'Charge : {weight} kilogrammes sur {capacity} kilogrammes'**
  String characterInventoryCapacityGaugeSemanticsLabel(
    String weight,
    String capacity,
  );

  /// Libellé d'accessibilité de la jauge "CHARGE", cas surchargé.
  ///
  /// In fr, this message translates to:
  /// **'Charge : {weight} kilogrammes sur {capacity} kilogrammes, surchargé'**
  String characterInventoryCapacityGaugeSemanticsLabelOverloaded(
    String weight,
    String capacity,
  );

  /// Titre de la carte « ARMES ÉQUIPÉES » de l'onglet « Personnage » (`CharacterEquippedWeaponsCard`).
  ///
  /// In fr, this message translates to:
  /// **'ARMES ÉQUIPÉES'**
  String get characterEquippedWeaponsCardTitle;

  /// Titre de la sous-section "Set principal" de `CharacterEquippedWeaponsCard`.
  ///
  /// In fr, this message translates to:
  /// **'SET PRINCIPAL'**
  String get characterEquippedWeaponsCardPrimarySetTitle;

  /// Titre de la sous-section "Set secondaire" de `CharacterEquippedWeaponsCard`.
  ///
  /// In fr, this message translates to:
  /// **'SET SECONDAIRE'**
  String get characterEquippedWeaponsCardSecondarySetTitle;

  /// Message affiché par une sous-section de set sans arme équipée (`_WeaponSlotSection`).
  ///
  /// In fr, this message translates to:
  /// **'Aucune arme dans ce set.'**
  String get characterEquippedWeaponsCardEmptySetMessage;

  /// Libellé de la ligne "Attaque" d'une arme équipée (`_Weapon`).
  ///
  /// In fr, this message translates to:
  /// **'Attaque'**
  String get characterEquippedWeaponsCardAttackLabel;

  /// Titre de l'état vide de `CharacterEquippedWeaponsCard` (`_EmptyWeapons`), aucune arme équipée.
  ///
  /// In fr, this message translates to:
  /// **'Aucune arme équipée'**
  String get characterEquippedWeaponsCardEmptyTitle;

  /// Sous-titre de l'état vide de `CharacterEquippedWeaponsCard` (`_EmptyWeapons`).
  ///
  /// In fr, this message translates to:
  /// **'Équipez une arme depuis l\'onglet Inventaire pour qu\'elle apparaisse ici.'**
  String get characterEquippedWeaponsCardEmptyDescription;

  /// Début du libellé d'accessibilité d'une arme équipée (`_Weapon`) — `name` reste `item.name`, donnée de contenu D&D.
  ///
  /// In fr, this message translates to:
  /// **'Arme équipée : {name}'**
  String characterEquippedWeaponsCardSemanticsLabel(String name);

  /// Segment "Attaque" ajouté au libellé d'accessibilité d'une arme équipée quand un bonus d'attaque est connu.
  ///
  /// In fr, this message translates to:
  /// **', Attaque : {attackBonus}'**
  String characterEquippedWeaponsCardSemanticsAttackSuffix(String attackBonus);

  /// Segment "Portée" ajouté au libellé d'accessibilité d'une arme équipée à portée (arme à distance).
  ///
  /// In fr, this message translates to:
  /// **', Portée : {range}'**
  String characterEquippedWeaponsCardSemanticsRangeSuffix(String range);

  /// Portée d'une arme équipée sans portée maximale distincte — unité métrique volontairement gardée telle quelle en anglais aussi, même rationale que `characterStatPillsSpeedValue`.
  ///
  /// In fr, this message translates to:
  /// **'{rangeNormal} m'**
  String characterEquippedWeaponsCardRangeValue(String rangeNormal);

  /// Portée d'une arme équipée avec portée maximale distincte.
  ///
  /// In fr, this message translates to:
  /// **'{rangeNormal} m (max {rangeMax} m)'**
  String characterEquippedWeaponsCardRangeValueWithMax(
    String rangeNormal,
    String rangeMax,
  );

  /// Première option de la sheet d'entrée "+ Ajouter un objet" (`_AddItemEntrySheetContent`).
  ///
  /// In fr, this message translates to:
  /// **'Depuis le catalogue'**
  String get addItemFlowCatalogEntryLabel;

  /// Seconde option de la sheet d'entrée "+ Ajouter un objet" (`_AddItemEntrySheetContent`).
  ///
  /// In fr, this message translates to:
  /// **'Objet personnalisé'**
  String get addItemFlowCustomEntryLabel;

  /// Titre de la sheet "Depuis le catalogue" en sélection simple (`_ItemCatalogPickerContent`, `multiSelect: false`).
  ///
  /// In fr, this message translates to:
  /// **'AJOUTER UN OBJET'**
  String get addItemFlowCatalogTitleSingle;

  /// Titre de la sheet "Depuis le catalogue" en sélection multiple (`_ItemCatalogPickerContent`, `multiSelect: true`).
  ///
  /// In fr, this message translates to:
  /// **'AJOUTER DES OBJETS'**
  String get addItemFlowCatalogTitleMulti;

  /// Texte d'indice du champ de recherche de la sheet "Depuis le catalogue".
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un objet...'**
  String get addItemFlowSearchHint;

  /// Message d'erreur de repli affiché quand le chargement du catalogue échoue sans `CharacterFailure` exploitable.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger le catalogue d\'objets. Réessayez.'**
  String get addItemFlowCatalogLoadErrorMessage;

  /// Libellé du bouton "Ajouter" de la sheet "Depuis le catalogue" en sélection multiple, aucun objet coché.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get addItemFlowAddButtonLabel;

  /// Libellé du bouton "Ajouter" de la sheet "Depuis le catalogue" en sélection multiple, avec le compte d'objets cochés entre parenthèses — même recette que `characterDeleteConfirmationMultipleConfirmButton`.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter ({count})'**
  String addItemFlowAddButtonLabelWithCount(int count);

  /// Message affiché quand la recherche de la sheet "Depuis le catalogue" ne trouve aucun objet.
  ///
  /// In fr, this message translates to:
  /// **'Aucun objet trouvé.'**
  String get addItemFlowNoResultsMessage;

  /// Sous-titre d'une ligne du catalogue avec un poids connu (`_CatalogItemRow`) — unités "po"/"kg" volontairement gardées telles quelles en anglais aussi, même rationale que `characterStatPillsSpeedValue`.
  ///
  /// In fr, this message translates to:
  /// **'{cost} po · {weight} kg'**
  String addItemFlowCatalogItemSubtitleWithWeight(String cost, String weight);

  /// Sous-titre d'une ligne du catalogue sans poids connu (`_CatalogItemRow`).
  ///
  /// In fr, this message translates to:
  /// **'{cost} po'**
  String addItemFlowCatalogItemSubtitleNoWeight(String cost);

  /// Titre de la sheet légère de quantité ouverte au tap sur une ligne du catalogue (`_ItemQuantitySheetContent`) — `itemName` reste le nom de l'objet, donnée de contenu D&D.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter {itemName}'**
  String addItemFlowQuantitySheetTitle(String itemName);

  /// Bouton "Ajouter" de la sheet légère de quantité (`_ItemQuantitySheetContent`).
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get addItemFlowQuantitySheetAddButton;

  /// Titre de la sheet "Objet personnalisé" (`_CustomItemPickerContent`).
  ///
  /// In fr, this message translates to:
  /// **'OBJET PERSONNALISÉ'**
  String get addItemFlowCustomSheetTitle;

  /// Libellé de section "Nom de l'objet" de la sheet "Objet personnalisé".
  ///
  /// In fr, this message translates to:
  /// **'NOM DE L\'OBJET'**
  String get addItemFlowCustomNameSectionLabel;

  /// Texte d'indice du champ "Nom de l'objet" de la sheet "Objet personnalisé".
  ///
  /// In fr, this message translates to:
  /// **'Ex. Amulette de famille'**
  String get addItemFlowCustomNameHint;

  /// Libellé de section "Description" de la sheet "Objet personnalisé".
  ///
  /// In fr, this message translates to:
  /// **'DESCRIPTION'**
  String get addItemFlowCustomDescriptionSectionLabel;

  /// Texte d'indice du champ "Description" de la sheet "Objet personnalisé".
  ///
  /// In fr, this message translates to:
  /// **'Ex. Un médaillon gravé aux armes de votre famille.'**
  String get addItemFlowCustomDescriptionHint;

  /// Libellé de section "Type d'objet" de la sheet "Objet personnalisé".
  ///
  /// In fr, this message translates to:
  /// **'TYPE D\'OBJET'**
  String get addItemFlowCustomTypeSectionLabel;

  /// Option "Objet simple" du `SegmentedToggle` "Type d'objet" de la sheet "Objet personnalisé".
  ///
  /// In fr, this message translates to:
  /// **'Objet simple'**
  String get addItemFlowCustomTypeSimpleOption;

  /// Option "Arme" du `SegmentedToggle` "Type d'objet" de la sheet "Objet personnalisé".
  ///
  /// In fr, this message translates to:
  /// **'Arme'**
  String get addItemFlowCustomTypeWeaponOption;

  /// Libellé de section "Dé de dégâts" de la sheet "Objet personnalisé" (visible seulement pour le type "Arme").
  ///
  /// In fr, this message translates to:
  /// **'DÉ DE DÉGÂTS'**
  String get addItemFlowCustomDiceSectionLabel;

  /// Lettre "d" affichée entre le nombre de dés et le nombre de faces du dé de dégâts (notation D&D "NdM", ex. "1d8") — gardée telle quelle en anglais aussi, notation de dés internationale.
  ///
  /// In fr, this message translates to:
  /// **'d'**
  String get addItemFlowCustomDiceNotationSeparator;

  /// Libellé de section "Type de dégâts" de la sheet "Objet personnalisé" (visible seulement pour le type "Arme").
  ///
  /// In fr, this message translates to:
  /// **'TYPE DE DÉGÂTS'**
  String get addItemFlowCustomDamageTypeSectionLabel;

  /// Texte d'indice du menu déroulant "Type de dégâts" de la sheet "Objet personnalisé", aucune valeur choisie.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner'**
  String get addItemFlowCustomDamageTypeHint;

  /// Libellé affiché pour le type de dégâts "tranchant" dans le menu déroulant de la sheet "Objet personnalisé" (valeur stockée inchangée).
  ///
  /// In fr, this message translates to:
  /// **'Tranchant'**
  String get addItemFlowDamageTypeSlashingLabel;

  /// Libellé affiché pour le type de dégâts "perforant" dans le menu déroulant de la sheet "Objet personnalisé" (valeur stockée inchangée).
  ///
  /// In fr, this message translates to:
  /// **'Perforant'**
  String get addItemFlowDamageTypePiercingLabel;

  /// Libellé affiché pour le type de dégâts "contondant" dans le menu déroulant de la sheet "Objet personnalisé" (valeur stockée inchangée).
  ///
  /// In fr, this message translates to:
  /// **'Contondant'**
  String get addItemFlowDamageTypeBludgeoningLabel;

  /// Libellé de section "Propriétés" de la sheet "Objet personnalisé" (visible seulement pour le type "Arme").
  ///
  /// In fr, this message translates to:
  /// **'PROPRIÉTÉS'**
  String get addItemFlowCustomPropertiesSectionLabel;

  /// Texte d'indice du champ "Propriétés" de la sheet "Objet personnalisé".
  ///
  /// In fr, this message translates to:
  /// **'Ex. légère, finesse'**
  String get addItemFlowCustomPropertiesHint;

  /// Légende sous le champ "Propriétés" de la sheet "Objet personnalisé".
  ///
  /// In fr, this message translates to:
  /// **'Séparez plusieurs propriétés par une virgule.'**
  String get addItemFlowCustomPropertiesCaption;

  /// Libellé de section "Quantité" de la sheet "Objet personnalisé".
  ///
  /// In fr, this message translates to:
  /// **'QUANTITÉ'**
  String get addItemFlowCustomQuantitySectionLabel;

  /// Bouton secondaire "Annuler" de la sheet "Objet personnalisé".
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get addItemFlowCustomCancelButton;

  /// Bouton primaire "Ajouter" de la sheet "Objet personnalisé".
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get addItemFlowCustomAddButton;

  /// Action "Infos" de la sheet d'actions d'objet (`_ItemActionSheetContent`), toujours affichée.
  ///
  /// In fr, this message translates to:
  /// **'Infos'**
  String get itemActionSheetInfoLabel;

  /// Action "Utiliser" de la sheet d'actions d'objet, affichée pour un objet consommable.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser'**
  String get itemActionSheetUseLabel;

  /// Action "Équiper" de la sheet d'actions d'objet (arme non équipée, ou armure/bouclier non équipé).
  ///
  /// In fr, this message translates to:
  /// **'Équiper'**
  String get itemActionSheetEquipLabel;

  /// Action "Changer de set" de la sheet d'actions d'objet, pour une arme déjà équipée.
  ///
  /// In fr, this message translates to:
  /// **'Changer de set'**
  String get itemActionSheetChangeSetLabel;

  /// Action "Déséquiper" de la sheet d'actions d'objet (arme, armure ou bouclier déjà équipé).
  ///
  /// In fr, this message translates to:
  /// **'Déséquiper'**
  String get itemActionSheetUnequipLabel;

  /// Action "Harmoniser cet objet" de la sheet d'actions d'objet, objet pas encore harmonisé.
  ///
  /// In fr, this message translates to:
  /// **'Harmoniser cet objet'**
  String get itemActionSheetAttuneLabel;

  /// Action "Ne plus harmoniser" de la sheet d'actions d'objet, objet déjà harmonisé.
  ///
  /// In fr, this message translates to:
  /// **'Ne plus harmoniser'**
  String get itemActionSheetStopAttuneLabel;

  /// Texte de fin de ligne de l'action d'harmonisation quand le plafond `CharacterDetail.attunementCap` est atteint pour un objet pas encore harmonisé.
  ///
  /// In fr, this message translates to:
  /// **'Limite ({cap}) atteinte'**
  String itemActionSheetAttunementCapReachedLabel(int cap);

  /// Action "Retirer" de la sheet d'actions d'objet, toujours affichée.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get itemActionSheetRemoveLabel;

  /// Sous-titre de l'objet en tête de la sheet d'actions d'objet — `category` reste `InventoryCategoryRules.labelFor`, non traduit (classe domain sans `BuildContext`, hors périmètre de ce lot, voir le registre de dette technique).
  ///
  /// In fr, this message translates to:
  /// **'{category} · x{quantity}'**
  String itemActionSheetSubtitle(String category, int quantity);

  /// Titre du dialogue de confirmation "Retirer {nom} ?" — `itemName` reste le nom de l'objet, donnée de contenu D&D.
  ///
  /// In fr, this message translates to:
  /// **'Retirer {itemName} ?'**
  String itemActionSheetRemoveConfirmationTitle(String itemName);

  /// Corps du dialogue de confirmation "Retirer {nom} ?".
  ///
  /// In fr, this message translates to:
  /// **'Cette action est définitive.'**
  String get itemActionSheetRemoveConfirmationBody;

  /// Bouton secondaire "Annuler" du dialogue de confirmation "Retirer {nom} ?".
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get itemActionSheetRemoveConfirmationCancelButton;

  /// Bouton destructif de confirmation du dialogue "Retirer {nom} ?".
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get itemActionSheetRemoveConfirmationConfirmButton;

  /// Libellé de la ligne "Poids unitaire" du panneau "Infos" d'un objet.
  ///
  /// In fr, this message translates to:
  /// **'Poids unitaire'**
  String get itemInfoPanelWeightLabel;

  /// Valeur de la ligne "Poids unitaire" du panneau "Infos" d'un objet — unité métrique volontairement gardée telle quelle en anglais aussi, même rationale que `characterStatPillsSpeedValue`.
  ///
  /// In fr, this message translates to:
  /// **'{weight} kg'**
  String itemInfoPanelWeightValue(String weight);

  /// Libellé de la ligne "Coût" du panneau "Infos" d'un objet.
  ///
  /// In fr, this message translates to:
  /// **'Coût'**
  String get itemInfoPanelCostLabel;

  /// Valeur de la ligne "Coût" du panneau "Infos" d'un objet — unité "po" volontairement gardée telle quelle en anglais aussi, même rationale que `characterStatPillsSpeedValue`.
  ///
  /// In fr, this message translates to:
  /// **'{cost} po'**
  String itemInfoPanelCostValue(String cost);

  /// Libellé de la ligne "Set" du panneau "Infos" d'une arme équipée dont le set est connu — la valeur affichée reste `WeaponSlot.label`, non traduite (classe domain sans `BuildContext`, hors périmètre de ce lot, voir le registre de dette technique).
  ///
  /// In fr, this message translates to:
  /// **'Set'**
  String get itemInfoPanelSetLabel;

  /// Libellé de la ligne "Attaque" du panneau "Infos" d'une arme.
  ///
  /// In fr, this message translates to:
  /// **'Attaque'**
  String get itemInfoPanelAttackLabel;

  /// Libellé de la ligne "Dégâts" du panneau "Infos" d'une arme.
  ///
  /// In fr, this message translates to:
  /// **'Dégâts'**
  String get itemInfoPanelDamageLabel;

  /// Libellé de la ligne "Propriétés" du panneau "Infos" d'une arme.
  ///
  /// In fr, this message translates to:
  /// **'Propriétés'**
  String get itemInfoPanelPropertiesLabel;

  /// Libellé de la ligne "Portée" du panneau "Infos" d'une arme à distance.
  ///
  /// In fr, this message translates to:
  /// **'Portée'**
  String get itemInfoPanelRangeLabel;

  /// Valeur de la ligne "Portée" sans portée maximale distincte — unité métrique volontairement gardée telle quelle en anglais aussi, même rationale que `characterStatPillsSpeedValue`.
  ///
  /// In fr, this message translates to:
  /// **'{rangeNormal} m'**
  String itemInfoPanelRangeValue(String rangeNormal);

  /// Valeur de la ligne "Portée" avec portée maximale distincte.
  ///
  /// In fr, this message translates to:
  /// **'{rangeNormal} m (max {rangeMax} m)'**
  String itemInfoPanelRangeValueWithMax(String rangeNormal, String rangeMax);

  /// Libellé de la ligne "CA de base" du panneau "Infos" d'une armure/bouclier.
  ///
  /// In fr, this message translates to:
  /// **'CA de base'**
  String get itemInfoPanelArmorClassLabel;

  /// Libellé de la ligne "Bonus Dex" du panneau "Infos" d'une armure/bouclier — la valeur affichée reste `InventoryArmorDexBonusFormatter.format`, non traduite (classe domain sans `BuildContext`, hors périmètre de ce lot, voir le registre de dette technique).
  ///
  /// In fr, this message translates to:
  /// **'Bonus Dex'**
  String get itemInfoPanelDexBonusLabel;

  /// Libellé de la ligne "Force requise" du panneau "Infos" d'une armure, affichée seulement si renseignée.
  ///
  /// In fr, this message translates to:
  /// **'Force requise'**
  String get itemInfoPanelStrengthRequirementLabel;

  /// Libellé de la ligne "Désavantage discrétion" du panneau "Infos" d'une armure/bouclier.
  ///
  /// In fr, this message translates to:
  /// **'Désavantage discrétion'**
  String get itemInfoPanelStealthDisadvantageLabel;

  /// Valeur "Oui" de la ligne "Désavantage discrétion" du panneau "Infos" d'une armure/bouclier.
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get itemInfoPanelYesLabel;

  /// Valeur "Non" de la ligne "Désavantage discrétion" du panneau "Infos" d'une armure/bouclier.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get itemInfoPanelNoLabel;

  /// Libellé de la ligne "Rareté" du panneau "Infos" d'un objet, affichée seulement si renseignée.
  ///
  /// In fr, this message translates to:
  /// **'Rareté'**
  String get itemInfoPanelRarityLabel;

  /// Titre de la section "Description" du panneau "Infos" d'un objet.
  ///
  /// In fr, this message translates to:
  /// **'DESCRIPTION'**
  String get itemInfoPanelDescriptionSectionLabel;

  /// Texte de repli de la section "Description" du panneau "Infos", objet sans description renseignée.
  ///
  /// In fr, this message translates to:
  /// **'Aucune description disponible.'**
  String get itemInfoPanelDescriptionUnavailable;

  /// Bouton de pied "Utiliser" du panneau "Infos", objet consommable.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser'**
  String get itemInfoPanelUseButton;

  /// Bouton de pied "Équiper" du panneau "Infos" (armure/bouclier non équipé).
  ///
  /// In fr, this message translates to:
  /// **'Équiper'**
  String get itemInfoPanelEquipButton;

  /// Bouton de pied "Déséquiper" du panneau "Infos" (armure/bouclier équipé).
  ///
  /// In fr, this message translates to:
  /// **'Déséquiper'**
  String get itemInfoPanelUnequipButton;

  /// Lien "Harmoniser cet objet" du panneau "Infos" (`_ToggleAttunedLink`), objet pas encore harmonisé.
  ///
  /// In fr, this message translates to:
  /// **'Harmoniser cet objet'**
  String get itemInfoPanelAttuneLabel;

  /// Lien "Ne plus harmoniser" du panneau "Infos" (`_ToggleAttunedLink`), objet déjà harmonisé.
  ///
  /// In fr, this message translates to:
  /// **'Ne plus harmoniser'**
  String get itemInfoPanelStopAttuneLabel;

  /// Légende affichée sous le lien d'harmonisation du panneau "Infos" quand le plafond `CharacterDetail.attunementCap` est atteint pour un objet pas encore harmonisé.
  ///
  /// In fr, this message translates to:
  /// **'{cap, plural, =1{Limite de 1 objet harmonisé atteinte.} other{Limite de {cap} objets harmonisés atteinte.}}'**
  String itemInfoPanelAttunementCapReachedCaption(int cap);

  /// Titre de la sheet d'ajustement de monnaie — `currencyLabel` reste `CurrencyKind.fullLabel`, non traduit (classe domain sans `BuildContext`, hors périmètre de ce lot, voir le registre de dette technique).
  ///
  /// In fr, this message translates to:
  /// **'Ajuster les {currencyLabel}'**
  String currencyAdjustmentSheetTitle(String currencyLabel);

  /// Option "Ajouter" du `SegmentedToggle` de la sheet d'ajustement de monnaie.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get currencyAdjustmentSheetAddOption;

  /// Option "Retirer" du `SegmentedToggle` de la sheet d'ajustement de monnaie.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get currencyAdjustmentSheetRemoveOption;

  /// Bouton secondaire "Annuler" de la sheet d'ajustement de monnaie.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get currencyAdjustmentSheetCancelButton;

  /// Bouton primaire "Appliquer" de la sheet d'ajustement de monnaie.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get currencyAdjustmentSheetApplyButton;

  /// Titre de la sheet "Filtrer par catégorie" de l'onglet "Inventaire".
  ///
  /// In fr, this message translates to:
  /// **'FILTRER PAR CATÉGORIE'**
  String get inventoryCategoryFilterSheetTitle;

  /// Titre "SORTS" affiché au-dessus du bloc "Magie de pacte" dans `CharacterSpellsSection` (uniquement visible si le personnage a de la magie de pacte, voir `hasPact`).
  ///
  /// In fr, this message translates to:
  /// **'SORTS'**
  String get characterSpellsSectionTitle;

  /// Libellé de `_PactSlotBanner`, à côté de l'icône de flamme.
  ///
  /// In fr, this message translates to:
  /// **'Magie de pacte — Niveau {level}'**
  String characterSpellsSectionPactLabel(int level);

  /// `Semantics.label` de `SpellSlotDots` pour un emplacement de pacte (`slot.isPact`).
  ///
  /// In fr, this message translates to:
  /// **'Emplacements de pacte : {remaining} restants sur {total} (niveau {level})'**
  String characterSpellsSectionPactSlotsSemanticLabel(
    int remaining,
    int total,
    int level,
  );

  /// `Semantics.label` de `SpellSlotDots` pour un emplacement classique.
  ///
  /// In fr, this message translates to:
  /// **'Emplacements de sorts : {remaining} restants sur {total}'**
  String characterSpellsSectionSlotsSemanticLabel(int remaining, int total);

  /// `Semantics.label` de `_GrantBadge` — `sourceLabel` reste `SpellGrantSource.label` (domain, non traduit, voir le registre de dette technique).
  ///
  /// In fr, this message translates to:
  /// **'Toujours préparé, accordé par : {sourceLabel}'**
  String characterSpellsSectionGrantBadgeSemanticLabel(String sourceLabel);

  /// Libellé de la pastille `_RowBadge` d'un sort inné (`_InnateUsage`).
  ///
  /// In fr, this message translates to:
  /// **'INNÉ'**
  String get characterSpellsSectionInnateBadgeLabel;

  /// Texte affiché à la place de la pastille pleine quand l'usage inné est épuisé (`_InnateUsage`).
  ///
  /// In fr, this message translates to:
  /// **'Épuisé'**
  String get characterSpellsSectionInnateExhaustedLabel;

  /// `Semantics.label` de `_InnateUsage` quand il reste au moins un usage.
  ///
  /// In fr, this message translates to:
  /// **'Sort inné, sans emplacement, {remaining, plural, =1{1 utilisation restante} other{{remaining} utilisations restantes}} sur {max}, repos long'**
  String characterSpellsSectionInnateAvailableSemanticLabel(
    int remaining,
    int max,
  );

  /// `Semantics.label` de `_InnateUsage` une fois l'usage épuisé.
  ///
  /// In fr, this message translates to:
  /// **'Sort inné, épuisé, disponible après un repos long'**
  String get characterSpellsSectionInnateExhaustedSemanticLabel;

  /// Titre de `CharacterClassFeaturesCard` en pied de cet onglet (D142, registre de dette technique : point du titre littéral refermé par ce lot).
  ///
  /// In fr, this message translates to:
  /// **'INVOCATIONS & APTITUDES À USAGE LIMITÉ'**
  String get characterSpellsTabBodyLimitedUseFeaturesCardTitle;

  /// `hintText` du champ de recherche de l'onglet "Sorts".
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un sort'**
  String get characterSpellsTabBodySearchHint;

  /// Tooltip du bouton d'effacement du champ de recherche de l'onglet "Sorts".
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get characterSpellsTabBodySearchClearTooltip;

  /// Libellé "kind" de `_NoMatchState` pour le filtre `SpellPreparationFilter.all`.
  ///
  /// In fr, this message translates to:
  /// **'Aucun sort'**
  String get characterSpellsTabBodyNoMatchAllLabel;

  /// Libellé "kind" de `_NoMatchState` pour le filtre `SpellPreparationFilter.prepared`.
  ///
  /// In fr, this message translates to:
  /// **'Aucun sort préparé'**
  String get characterSpellsTabBodyNoMatchPreparedLabel;

  /// Libellé "kind" de `_NoMatchState` pour le filtre `SpellPreparationFilter.unprepared`.
  ///
  /// In fr, this message translates to:
  /// **'Aucun sort non préparé'**
  String get characterSpellsTabBodyNoMatchUnpreparedLabel;

  /// Message de `_NoMatchState` quand la recherche est vide (`kind` déjà localisé, ex. `characterSpellsTabBodyNoMatchAllLabel`).
  ///
  /// In fr, this message translates to:
  /// **'{kind}.'**
  String characterSpellsTabBodyNoMatchMessageEmpty(String kind);

  /// Message de `_NoMatchState` quand la recherche en cours ne donne aucun résultat.
  ///
  /// In fr, this message translates to:
  /// **'{kind} pour « {query} ».'**
  String characterSpellsTabBodyNoMatchMessageQuery(String kind, String query);

  /// Titre de `_EmptySpellsState` (aucun sort du tout sur la fiche).
  ///
  /// In fr, this message translates to:
  /// **'AUCUN SORT'**
  String get characterSpellsTabBodyEmptyStateTitle;

  /// Sous-titre de `_EmptySpellsState`.
  ///
  /// In fr, this message translates to:
  /// **'Aucun sort sur cette fiche pour l\'instant. Pour les classes qui lancent des sorts, ils se choisissent depuis l\'assistant de création ou à la montée de niveau.'**
  String get characterSpellsTabBodyEmptyStateBody;

  /// Titre de `_NonCasterEmptyState` (classe structurellement non lanceuse de sorts).
  ///
  /// In fr, this message translates to:
  /// **'Cette classe ne lance pas de sorts'**
  String get characterSpellsTabBodyNonCasterTitle;

  /// Repli de `className` quand le personnage n'a aucune classe (`detail.primaryClass?.className`), transmis à `characterSpellsTabBodyNonCasterBody`.
  ///
  /// In fr, this message translates to:
  /// **'cette classe'**
  String get characterSpellsTabBodyNonCasterDefaultClassName;

  /// Sous-titre de `_NonCasterEmptyState`.
  ///
  /// In fr, this message translates to:
  /// **'{characterName} est {className} — hors archétype dédié (ex. Chevalier occulte), cette classe ne dispose pas d\'emplacements de sorts. Cet onglet reste accessible par cohérence de navigation, mais restera vide pour ce personnage.'**
  String characterSpellsTabBodyNonCasterBody(
    String characterName,
    String className,
  );

  /// Titre de la sheet de choix d'emplacement (`_SpellSlotChoiceSheetContent`), `castSpellFlow`.
  ///
  /// In fr, this message translates to:
  /// **'Lancer {spellName}'**
  String spellActionSheetTitle(String spellName);

  /// Sous-titre de la sheet de choix d'emplacement.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez le niveau d\'emplacement à utiliser.'**
  String get spellActionSheetSubtitle;

  /// Bouton secondaire "Annuler" de la sheet de choix d'emplacement.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get spellActionSheetCancelButton;

  /// Bouton primaire "Lancer" de la sheet de choix d'emplacement.
  ///
  /// In fr, this message translates to:
  /// **'Lancer'**
  String get spellActionSheetCastButton;

  /// Libellé `leading` de `_SpellSlotOptionRow` pour un emplacement épuisé.
  ///
  /// In fr, this message translates to:
  /// **'Épuisé'**
  String get spellActionSheetSlotExhaustedLabel;

  /// Libellé `leading` de `_SpellSlotOptionRow` quand `slot.total <= 0` (repli sans pastilles).
  ///
  /// In fr, this message translates to:
  /// **'{remaining}/{total} restants'**
  String spellActionSheetSlotRemainingLabel(int remaining, int total);

  /// Titre de `_SpellSlotOptionRow` pour un emplacement de pacte.
  ///
  /// In fr, this message translates to:
  /// **'Niveau {level} (pacte)'**
  String spellActionSheetPactSlotLevelLabel(int level);

  /// Titre de `_SpellSlotOptionRow` pour un emplacement classique.
  ///
  /// In fr, this message translates to:
  /// **'Niveau {level}'**
  String spellActionSheetSlotLevelLabel(int level);

  /// Libellé de la ligne "Utilisations" du panneau "Infos" (sort inné à charge).
  ///
  /// In fr, this message translates to:
  /// **'Utilisations'**
  String get spellInfoPanelUsagesLabel;

  /// Libellé de la ligne "Temps d'incantation" du panneau "Infos".
  ///
  /// In fr, this message translates to:
  /// **'Temps d\'incantation'**
  String get spellInfoPanelCastingTimeLabel;

  /// Libellé de la ligne "Portée" du panneau "Infos".
  ///
  /// In fr, this message translates to:
  /// **'Portée'**
  String get spellInfoPanelRangeLabel;

  /// Libellé de la ligne "Durée" du panneau "Infos".
  ///
  /// In fr, this message translates to:
  /// **'Durée'**
  String get spellInfoPanelDurationLabel;

  /// Libellé de la ligne "Concentration" du panneau "Infos".
  ///
  /// In fr, this message translates to:
  /// **'Concentration'**
  String get spellInfoPanelConcentrationLabel;

  /// Valeur de la ligne "Concentration" quand `spell.concentration` est vrai.
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get spellInfoPanelConcentrationYes;

  /// Valeur de la ligne "Concentration" quand `spell.concentration` est faux.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get spellInfoPanelConcentrationNo;

  /// Note affichée pour un sort accordé par une sous-classe — `sourceLabel` reste `SpellGrantSource.label.toLowerCase()` (domain, non traduit, voir le registre de dette technique).
  ///
  /// In fr, this message translates to:
  /// **'Toujours préparé — sort de {sourceLabel} (ne compte pas dans la limite de sorts préparés)'**
  String spellInfoPanelGrantSourceNote(String sourceLabel);

  /// Note affichée pour un sort inné à charge limitée.
  ///
  /// In fr, this message translates to:
  /// **'Sort inné — se lance sans emplacement, {usesPerLongRest} fois par repos long'**
  String spellInfoPanelInnateNote(int usesPerLongRest);

  /// Titre de section "DESCRIPTION" du panneau "Infos" (texte de description lui-même non traduit, contenu D&D).
  ///
  /// In fr, this message translates to:
  /// **'DESCRIPTION'**
  String get spellInfoPanelDescriptionTitle;

  /// Bouton primaire "Lancer" en pied du panneau "Infos" (route ordinaire).
  ///
  /// In fr, this message translates to:
  /// **'Lancer'**
  String get spellInfoPanelCastButton;

  /// Second bouton "Lancer (sort inné)" d'un sort à double route (D43).
  ///
  /// In fr, this message translates to:
  /// **'Lancer (sort inné)'**
  String get spellInfoPanelCastInnateButton;

  /// Lien `_TogglePreparedLink` quand le sort est déjà préparé.
  ///
  /// In fr, this message translates to:
  /// **'Ne plus préparer'**
  String get spellInfoPanelUnprepareLink;

  /// Lien `_TogglePreparedLink` quand le sort n'est pas encore préparé.
  ///
  /// In fr, this message translates to:
  /// **'Préparer ce sort'**
  String get spellInfoPanelPrepareLink;

  /// Libellé de la ligne "Composantes" du panneau "Infos" (`_SpellComponentsInfoRow`).
  ///
  /// In fr, this message translates to:
  /// **'Composantes'**
  String get spellInfoPanelComponentsLabel;

  /// Titre de `SpellPreparationCard`, réutilisé tel quel pour le titre de `showSpellPreparationInfoSheet` (même texte).
  ///
  /// In fr, this message translates to:
  /// **'PRÉPARATION DES SORTS'**
  String get spellPreparationCardTitle;

  /// Tooltip de l'icône ⓘ de `SpellPreparationCard`.
  ///
  /// In fr, this message translates to:
  /// **'Comment fonctionne la préparation des sorts ?'**
  String get spellPreparationCardInfoTooltip;

  /// Libellé de `PreparedSpellsCounter` pour une classe donnée, quand le personnage a plusieurs classes qui préparent — `className` déjà mis en majuscules par l'appelant.
  ///
  /// In fr, this message translates to:
  /// **'SORTS PRÉPARÉS — {className}'**
  String spellPreparationCardClassLabel(String className);

  /// Libellé par défaut de `PreparedSpellsCounter` (rendu mono-classe historique).
  ///
  /// In fr, this message translates to:
  /// **'SORTS PRÉPARÉS'**
  String get spellPreparationCardDefaultLabel;

  /// Phrase d'état de `PreparedSpellsCounter` quand `count > limit`.
  ///
  /// In fr, this message translates to:
  /// **'Limite dépassée de {overBy}'**
  String spellPreparationCardOverLimitStatus(int overBy);

  /// Phrase d'état de `PreparedSpellsCounter` quand `count == limit`.
  ///
  /// In fr, this message translates to:
  /// **'Limite atteinte'**
  String get spellPreparationCardLimitReachedStatus;

  /// Phrase d'état de `PreparedSpellsCounter` quand `count < limit`.
  ///
  /// In fr, this message translates to:
  /// **'{remaining, plural, =1{Encore 1 sort à préparer} other{Encore {remaining} sorts à préparer}}'**
  String spellPreparationCardRemainingToPrepareStatus(int remaining);

  /// Base du `Semantics.label` de `PreparedSpellsCounter` — complété par `spellPreparationCardCounterOverLimitSuffix` si la limite est dépassée.
  ///
  /// In fr, this message translates to:
  /// **'{label} : {count} sur {limit}'**
  String spellPreparationCardCounterSemanticLabel(
    String label,
    int count,
    int limit,
  );

  /// Suffixe du `Semantics.label` de `PreparedSpellsCounter` quand la limite est dépassée.
  ///
  /// In fr, this message translates to:
  /// **', limite dépassée'**
  String get spellPreparationCardCounterOverLimitSuffix;

  /// Titre de la première entrée de `showSpellPreparationInfoSheet`.
  ///
  /// In fr, this message translates to:
  /// **'Préparer pour lancer'**
  String get spellPreparationCardInfoEntryPrepareTitle;

  /// Corps de la première entrée de `showSpellPreparationInfoSheet`.
  ///
  /// In fr, this message translates to:
  /// **'Seuls les sorts préparés peuvent être lancés. Les sorts non préparés restent dans la liste, grisés, après les sorts préparés. Touchez un sort puis « Préparer ce sort » ou « Ne plus préparer ».'**
  String get spellPreparationCardInfoEntryPrepareBody;

  /// Titre de la deuxième entrée de `showSpellPreparationInfoSheet`.
  ///
  /// In fr, this message translates to:
  /// **'Combien de sorts ?'**
  String get spellPreparationCardInfoEntryHowManyTitle;

  /// Corps de la deuxième entrée de `showSpellPreparationInfoSheet` — `limitsSentence` reste `spellPreparationCardSingleLimitSentence`/`spellPreparationCardMultipleLimitsSentence` (ou chaîne vide si `classLimits` est vide).
  ///
  /// In fr, this message translates to:
  /// **'Clerc, Druide et Magicien : modificateur de caractéristique d\'incantation + niveau de classe. Paladin et Artificier (demi-lanceurs) : modificateur + moitié du niveau. Minimum 1. Multiclassé avec plusieurs classes qui préparent : chaque classe a sa propre limite, jamais un total commun.{limitsSentence} Une fois la limite atteinte, impossible de préparer un nouveau sort de cette classe sans en dé-préparer un autre d\'abord.'**
  String spellPreparationCardInfoEntryHowManyBody(String limitsSentence);

  /// `limitsSentence` quand `classLimits` compte exactement un élément.
  ///
  /// In fr, this message translates to:
  /// **' Votre limite actuelle : {limit}.'**
  String spellPreparationCardSingleLimitSentence(int limit);

  /// `limitsSentence` quand `classLimits` compte plusieurs éléments — `limitsList` reste une concaténation "{className} {limit}" (noms de classe déjà traduits), non recomposée via `.arb`.
  ///
  /// In fr, this message translates to:
  /// **' Vos limites actuelles : {limitsList}.'**
  String spellPreparationCardMultipleLimitsSentence(String limitsList);

  /// Titre de la troisième entrée de `showSpellPreparationInfoSheet`.
  ///
  /// In fr, this message translates to:
  /// **'Sans préparation'**
  String get spellPreparationCardInfoEntryNoPreparationTitle;

  /// Corps de la troisième entrée de `showSpellPreparationInfoSheet`.
  ///
  /// In fr, this message translates to:
  /// **'Les sorts mineurs, les sorts innés et les sorts de domaine ou de serment n\'ont jamais à être préparés et ne comptent pas dans la limite. Un sort inné de niveau 1 ou plus se lance sans emplacement, une fois par repos long.'**
  String get spellPreparationCardInfoEntryNoPreparationBody;

  /// Titre de la quatrième entrée de `showSpellPreparationInfoSheet`.
  ///
  /// In fr, this message translates to:
  /// **'Lancer ne dé-prépare pas'**
  String get spellPreparationCardInfoEntryCastDoesNotUnprepareTitle;

  /// Corps de la quatrième entrée de `showSpellPreparationInfoSheet`.
  ///
  /// In fr, this message translates to:
  /// **'Lancer un sort consomme un emplacement, mais le sort reste préparé : vous pouvez le relancer tant qu\'il vous reste des emplacements.'**
  String get spellPreparationCardInfoEntryCastDoesNotUnprepareBody;

  /// Titre de la cinquième entrée (dernière) de `showSpellPreparationInfoSheet`.
  ///
  /// In fr, this message translates to:
  /// **'Changer sa liste'**
  String get spellPreparationCardInfoEntryChangeListTitle;

  /// Corps de la cinquième entrée (dernière) de `showSpellPreparationInfoSheet`.
  ///
  /// In fr, this message translates to:
  /// **'La liste de sorts préparés se change après un repos long : le repos long vous propose de garder votre liste ou de la modifier.'**
  String get spellPreparationCardInfoEntryChangeListBody;

  /// Titre de `showPrepareSpellsSheet` (`SheetHeaderBar`).
  ///
  /// In fr, this message translates to:
  /// **'PRÉPARER MES SORTS'**
  String get prepareSpellsSheetTitle;

  /// Libellé de `PreparedSpellsCounter` pour une classe donnée dans `showPrepareSpellsSheet`, quand le personnage a plusieurs classes qui préparent — `className` déjà mis en majuscules par l'appelant.
  ///
  /// In fr, this message translates to:
  /// **'SORTS PRÉPARÉS — {className}'**
  String prepareSpellsSheetClassLabel(String className);

  /// `hintText` du champ de recherche de `showPrepareSpellsSheet`.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un sort'**
  String get prepareSpellsSheetSearchHint;

  /// Tooltip du bouton d'effacement du champ de recherche de `showPrepareSpellsSheet`.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get prepareSpellsSheetSearchClearTooltip;

  /// Message de `_NoMatchState` de `showPrepareSpellsSheet` quand la recherche est vide.
  ///
  /// In fr, this message translates to:
  /// **'Aucun sort disponible.'**
  String get prepareSpellsSheetNoMatchEmptyMessage;

  /// Message de `_NoMatchState` de `showPrepareSpellsSheet` quand la recherche en cours ne donne aucun résultat.
  ///
  /// In fr, this message translates to:
  /// **'Aucun sort pour « {query} ».'**
  String prepareSpellsSheetNoMatchQueryMessage(String query);

  /// Tooltip du bouton ⓘ de `_SpellCheckRow`.
  ///
  /// In fr, this message translates to:
  /// **'Description de {spellName}'**
  String prepareSpellsSheetInfoTooltip(String spellName);

  /// Titre de `showCastInnateSpellConfirmationDialog`.
  ///
  /// In fr, this message translates to:
  /// **'Lancer {spellName} ?'**
  String castInnateSpellConfirmationDialogTitle(String spellName);

  /// Message de `showCastInnateSpellConfirmationDialog`.
  ///
  /// In fr, this message translates to:
  /// **'Cette action consomme un usage de ce sort inné, récupéré seulement au prochain repos long.'**
  String get castInnateSpellConfirmationDialogMessage;

  /// Bouton secondaire "Annuler" de `showCastInnateSpellConfirmationDialog`.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get castInnateSpellConfirmationDialogCancelButton;

  /// Bouton primaire "Lancer" de `showCastInnateSpellConfirmationDialog`.
  ///
  /// In fr, this message translates to:
  /// **'Lancer'**
  String get castInnateSpellConfirmationDialogCastButton;

  /// SnackBar de succès de `_castSpell` pour un sort de niveau 0 (rien à persister).
  ///
  /// In fr, this message translates to:
  /// **'{spellName} lancé.'**
  String characterDetailCastSpellSuccessMessage(String spellName);

  /// SnackBar de succès de `_castSpell` pour un emplacement classique.
  ///
  /// In fr, this message translates to:
  /// **'{spellName} lancé (emplacement niveau {slotLevel}).'**
  String characterDetailCastSpellWithSlotSuccessMessage(
    String spellName,
    int slotLevel,
  );

  /// SnackBar d'échec générique de `_castSpell`/`_castPactSpell`/`_castInnateSpell`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de lancer ce sort. Réessayez.'**
  String get characterDetailCastSpellErrorMessage;

  /// SnackBar de succès de `_castPactSpell`.
  ///
  /// In fr, this message translates to:
  /// **'{spellName} lancé (emplacement de pacte niveau {pactLevel}).'**
  String characterDetailCastPactSpellSuccessMessage(
    String spellName,
    int pactLevel,
  );

  /// SnackBar de succès de `_castInnateSpell`.
  ///
  /// In fr, this message translates to:
  /// **'{spellName} lancé (sort inné).'**
  String characterDetailCastInnateSpellSuccessMessage(String spellName);

  /// SnackBar d'échec de `_reassertInnateUsesState`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de synchroniser les sorts innés. Réessayez.'**
  String get characterDetailInnateSpellSyncErrorMessage;

  /// Titre de `_EmptyStoryState` (les 9 champs de texte libre sont tous vides).
  ///
  /// In fr, this message translates to:
  /// **'AUCUNE HISTOIRE RENSEIGNÉE'**
  String get characterStoryTabBodyEmptyStateTitle;

  /// Sous-titre de `_EmptyStoryState`, absent en lecture seule (`actionsDisabled`).
  ///
  /// In fr, this message translates to:
  /// **'Apparence, traits, idéaux... raconte l\'histoire de ton personnage quand tu veux.'**
  String get characterStoryTabBodyEmptyStateSubtitle;

  /// `PrimaryButton` de `_EmptyStoryState` (met son libellé en majuscules à l'affichage), absent en lecture seule.
  ///
  /// In fr, this message translates to:
  /// **'Renseigner mon histoire'**
  String get characterStoryTabBodyEmptyStateButtonLabel;

  /// Titre du `SheetHeaderBar` de la sheet "Modifier l'histoire".
  ///
  /// In fr, this message translates to:
  /// **'MODIFIER L\'HISTOIRE'**
  String get characterStoryEditSheetTitle;

  /// `SecondaryButton` "Annuler" (met son libellé en majuscules à l'affichage).
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get characterStoryEditSheetCancelButton;

  /// `PrimaryButton` "Enregistrer" (met son libellé en majuscules à l'affichage).
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get characterStoryEditSheetSaveButton;

  /// Libellé du 1er des 9 champs (`appearanceText`).
  ///
  /// In fr, this message translates to:
  /// **'APPARENCE PHYSIQUE'**
  String get characterStoryEditSheetAppearanceLabel;

  /// Placeholder du 1er des 9 champs (`appearanceText`).
  ///
  /// In fr, this message translates to:
  /// **'Décris l\'apparence physique de ton personnage…'**
  String get characterStoryEditSheetAppearanceHint;

  /// Libellé du 2e des 9 champs (`traitsText`).
  ///
  /// In fr, this message translates to:
  /// **'TRAITS DE PERSONNALITÉ'**
  String get characterStoryEditSheetTraitsLabel;

  /// Placeholder du 2e des 9 champs (`traitsText`).
  ///
  /// In fr, this message translates to:
  /// **'Décris les traits de personnalité de ton personnage…'**
  String get characterStoryEditSheetTraitsHint;

  /// Libellé du 3e des 9 champs (`idealsText`).
  ///
  /// In fr, this message translates to:
  /// **'IDÉAUX'**
  String get characterStoryEditSheetIdealsLabel;

  /// Placeholder du 3e des 9 champs (`idealsText`).
  ///
  /// In fr, this message translates to:
  /// **'Quels idéaux guident ton personnage ?'**
  String get characterStoryEditSheetIdealsHint;

  /// Libellé du 4e des 9 champs (`bondsText`).
  ///
  /// In fr, this message translates to:
  /// **'LIENS'**
  String get characterStoryEditSheetBondsLabel;

  /// Placeholder du 4e des 9 champs (`bondsText`).
  ///
  /// In fr, this message translates to:
  /// **'Quels liens unissent ton personnage à d\'autres ?'**
  String get characterStoryEditSheetBondsHint;

  /// Libellé du 5e des 9 champs (`flawsText`).
  ///
  /// In fr, this message translates to:
  /// **'DÉFAUTS'**
  String get characterStoryEditSheetFlawsLabel;

  /// Placeholder du 5e des 9 champs (`flawsText`).
  ///
  /// In fr, this message translates to:
  /// **'Quels défauts ou faiblesses a ton personnage ?'**
  String get characterStoryEditSheetFlawsHint;

  /// Libellé du 6e des 9 champs (`backstoryText`).
  ///
  /// In fr, this message translates to:
  /// **'HISTOIRE PERSONNELLE'**
  String get characterStoryEditSheetBackstoryLabel;

  /// Placeholder du 6e des 9 champs (`backstoryText`).
  ///
  /// In fr, this message translates to:
  /// **'Raconte l\'histoire personnelle de ton personnage…'**
  String get characterStoryEditSheetBackstoryHint;

  /// Libellé du 7e des 9 champs (`alliesText`).
  ///
  /// In fr, this message translates to:
  /// **'ALLIÉS'**
  String get characterStoryEditSheetAlliesLabel;

  /// Placeholder du 7e des 9 champs (`alliesText`).
  ///
  /// In fr, this message translates to:
  /// **'Quels alliés ou organisations soutiennent ton personnage ?'**
  String get characterStoryEditSheetAlliesHint;

  /// Libellé du 8e des 9 champs (`featuresText`).
  ///
  /// In fr, this message translates to:
  /// **'PARTICULARITÉS'**
  String get characterStoryEditSheetFeaturesLabel;

  /// Placeholder du 8e des 9 champs (`featuresText`).
  ///
  /// In fr, this message translates to:
  /// **'Décris les particularités de ton personnage…'**
  String get characterStoryEditSheetFeaturesHint;

  /// Libellé du 9e des 9 champs (`treasureText`).
  ///
  /// In fr, this message translates to:
  /// **'TRÉSOR'**
  String get characterStoryEditSheetTreasureLabel;

  /// Placeholder du 9e des 9 champs (`treasureText`).
  ///
  /// In fr, this message translates to:
  /// **'Quels trésors ou objets précieux possède ton personnage ?'**
  String get characterStoryEditSheetTreasureHint;

  /// Bandeau d'alerte inline sur échec inattendu (pas une `CharacterFailure`) de `_submit`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'enregistrer les modifications. Réessayez.'**
  String get characterStoryEditSheetGenericErrorMessage;

  /// SnackBar de confirmation affiché par `showCharacterStoryEditSheet` une fois la sheet refermée avec succès.
  ///
  /// In fr, this message translates to:
  /// **'Histoire mise à jour.'**
  String get characterStoryEditSheetUpdatedMessage;

  /// Titre de la carte "Journal de campagne" de l'onglet "Histoire".
  ///
  /// In fr, this message translates to:
  /// **'JOURNAL DE CAMPAGNE'**
  String get characterJournalCardTitle;

  /// `DashedAddTile` de `CharacterJournalCard`, absente en lecture seule (`actionsDisabled`).
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une note'**
  String get characterJournalCardAddButtonLabel;

  /// Ligne "Modifier" de la sheet d'actions ouverte au tap sur une entrée de journal.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get characterJournalCardEditAction;

  /// Ligne "Supprimer" de la sheet d'actions ouverte au tap sur une entrée de journal.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get characterJournalCardRemoveAction;

  /// Titre de `showRemoveJournalEntryConfirmationDialog`.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette note ?'**
  String get characterJournalCardRemoveConfirmationTitle;

  /// Sous-titre de `showRemoveJournalEntryConfirmationDialog`.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est définitive.'**
  String get characterJournalCardRemoveConfirmationMessage;

  /// `SecondaryButton` "Annuler" de `showRemoveJournalEntryConfirmationDialog`.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get characterJournalCardRemoveConfirmationCancelButton;

  /// `DestructiveButton` "Supprimer" de `showRemoveJournalEntryConfirmationDialog`.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get characterJournalCardRemoveConfirmationConfirmButton;

  /// SnackBar de confirmation de `_confirmAndRemove`.
  ///
  /// In fr, this message translates to:
  /// **'Note supprimée.'**
  String get characterJournalCardRemovedMessage;

  /// SnackBar d'échec inattendu de `_confirmAndRemove`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de supprimer cette note. Réessayez.'**
  String get characterJournalCardRemoveGenericErrorMessage;

  /// Titre du `SheetHeaderBar` en mode ajout (`entry` null).
  ///
  /// In fr, this message translates to:
  /// **'AJOUTER UNE NOTE'**
  String get characterJournalEntryEditSheetAddTitle;

  /// Titre du `SheetHeaderBar` en mode édition (`entry` non null).
  ///
  /// In fr, this message translates to:
  /// **'MODIFIER LA NOTE'**
  String get characterJournalEntryEditSheetEditTitle;

  /// Placeholder du champ de texte de la note.
  ///
  /// In fr, this message translates to:
  /// **'Note de séance, événement marquant…'**
  String get characterJournalEntryEditSheetHint;

  /// `SecondaryButton` "Annuler".
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get characterJournalEntryEditSheetCancelButton;

  /// `PrimaryButton` "Enregistrer".
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get characterJournalEntryEditSheetSaveButton;

  /// Bandeau d'alerte inline sur échec inattendu (pas une `CharacterFailure`) de `_submit`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'enregistrer cette note. Réessayez.'**
  String get characterJournalEntryEditSheetGenericErrorMessage;

  /// SnackBar de confirmation affiché par `showJournalEntryEditSheet` en mode ajout.
  ///
  /// In fr, this message translates to:
  /// **'Note ajoutée.'**
  String get characterJournalEntryEditSheetAddedMessage;

  /// SnackBar de confirmation affiché par `showJournalEntryEditSheet` en mode édition.
  ///
  /// In fr, this message translates to:
  /// **'Note modifiée.'**
  String get characterJournalEntryEditSheetUpdatedMessage;

  /// Titre de la carte "Galerie" de l'onglet "Histoire".
  ///
  /// In fr, this message translates to:
  /// **'GALERIE'**
  String get characterGalleryCardTitle;

  /// Ligne "Prendre une photo" du bottom sheet "Ajouter une photo".
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get galleryPhotoUploadSheetCameraAction;

  /// Ligne "Choisir dans la galerie" du bottom sheet "Ajouter une photo".
  ///
  /// In fr, this message translates to:
  /// **'Choisir dans la galerie'**
  String get galleryPhotoUploadSheetGalleryAction;

  /// Ligne "Utiliser une URL" du bottom sheet "Ajouter une photo".
  ///
  /// In fr, this message translates to:
  /// **'Utiliser une URL'**
  String get galleryPhotoUploadSheetUrlAction;

  /// SnackBar de confirmation de `showAddGalleryPhotoSheet`.
  ///
  /// In fr, this message translates to:
  /// **'Photo ajoutée.'**
  String get galleryPhotoUploadSheetAddedMessage;

  /// SnackBar d'échec de `showAddGalleryPhotoSheet`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ajouter cette photo. Réessayez.'**
  String get galleryPhotoUploadSheetGenericErrorMessage;

  /// Titre du dialogue "Utiliser une URL".
  ///
  /// In fr, this message translates to:
  /// **'URL de la photo'**
  String get galleryPhotoUploadSheetUrlDialogTitle;

  /// Placeholder du champ URL — identique quelle que soit la langue (syntaxe d'URL, pas du texte naturel).
  ///
  /// In fr, this message translates to:
  /// **'https://...'**
  String get galleryPhotoUploadSheetUrlDialogHint;

  /// Repli affiché quand l'échec n'est pas une `PortraitUrlFetchFailure` (message déjà localisé par l'appelant) — voir D147 du registre de dette technique pour `PortraitUrlFetchFailure.message` elle-même, qui reste figée en français.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger cette image.'**
  String get galleryPhotoUploadSheetUrlDialogGenericError;

  /// `SecondaryButton` "Annuler" du dialogue "Utiliser une URL".
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get galleryPhotoUploadSheetUrlDialogCancelButton;

  /// `PrimaryButton` "Suivant" du dialogue "Utiliser une URL".
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get galleryPhotoUploadSheetUrlDialogNextButton;

  /// `DestructiveButton` de la visionneuse plein écran, absent en lecture seule (`actionsDisabled`).
  ///
  /// In fr, this message translates to:
  /// **'Retirer cette photo'**
  String get galleryPhotoViewerScreenRemoveButtonLabel;

  /// SnackBar de confirmation de `_confirmAndRemove`.
  ///
  /// In fr, this message translates to:
  /// **'Photo retirée.'**
  String get galleryPhotoViewerScreenRemovedMessage;

  /// SnackBar d'échec de `_confirmAndRemove`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de retirer cette photo. Réessayez.'**
  String get galleryPhotoViewerScreenRemoveGenericErrorMessage;

  /// Titre de `showRemoveGalleryPhotoConfirmationDialog`.
  ///
  /// In fr, this message translates to:
  /// **'Retirer cette photo ?'**
  String get galleryPhotoViewerScreenRemoveConfirmationTitle;

  /// `SecondaryButton` "Annuler" de `showRemoveGalleryPhotoConfirmationDialog`.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get galleryPhotoViewerScreenRemoveConfirmationCancelButton;

  /// `DestructiveButton` "Retirer" de `showRemoveGalleryPhotoConfirmationDialog`.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get galleryPhotoViewerScreenRemoveConfirmationConfirmButton;

  /// Ligne "Prendre une photo" du bottom sheet "changer le portrait".
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get portraitUploadSheetCameraAction;

  /// Ligne "Choisir dans la galerie" du bottom sheet "changer le portrait".
  ///
  /// In fr, this message translates to:
  /// **'Choisir dans la galerie'**
  String get portraitUploadSheetGalleryAction;

  /// Ligne "Utiliser une URL" du bottom sheet "changer le portrait".
  ///
  /// In fr, this message translates to:
  /// **'Utiliser une URL'**
  String get portraitUploadSheetUrlAction;

  /// Ligne "Retirer le portrait" du bottom sheet "changer le portrait", proposée seulement si `hasPortrait`.
  ///
  /// In fr, this message translates to:
  /// **'Retirer le portrait'**
  String get portraitUploadSheetRemoveAction;

  /// SnackBar de confirmation de `_confirmAndRemove`.
  ///
  /// In fr, this message translates to:
  /// **'Portrait retiré.'**
  String get portraitUploadSheetRemovedMessage;

  /// SnackBar d'échec de `_confirmAndRemove`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de retirer le portrait. Réessayez.'**
  String get portraitUploadSheetRemoveGenericErrorMessage;

  /// Titre du dialogue "Utiliser une URL" de `showPortraitUrlDialog`.
  ///
  /// In fr, this message translates to:
  /// **'URL du portrait'**
  String get portraitUploadSheetUrlDialogTitle;

  /// Placeholder du champ URL — identique quelle que soit la langue (syntaxe d'URL, pas du texte naturel).
  ///
  /// In fr, this message translates to:
  /// **'https://...'**
  String get portraitUploadSheetUrlDialogHint;

  /// Repli affiché quand l'échec n'est pas une `PortraitUrlFetchFailure` (message déjà localisé par l'appelant) — voir D147 du registre de dette technique.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger cette image.'**
  String get portraitUploadSheetUrlDialogGenericError;

  /// `SecondaryButton` "Annuler" du dialogue "Utiliser une URL".
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get portraitUploadSheetUrlDialogCancelButton;

  /// `PrimaryButton` "Suivant" du dialogue "Utiliser une URL".
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get portraitUploadSheetUrlDialogNextButton;

  /// Titre de `showRemovePortraitConfirmationDialog`.
  ///
  /// In fr, this message translates to:
  /// **'Retirer le portrait ?'**
  String get portraitUploadSheetRemoveConfirmationTitle;

  /// `SecondaryButton` "Annuler" de `showRemovePortraitConfirmationDialog`.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get portraitUploadSheetRemoveConfirmationCancelButton;

  /// `DestructiveButton` "Retirer" de `showRemovePortraitConfirmationDialog`.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get portraitUploadSheetRemoveConfirmationConfirmButton;

  /// Titre du `WoodBackHeader` de l'écran de recadrage.
  ///
  /// In fr, this message translates to:
  /// **'RECADRAGE'**
  String get portraitCropScreenTitle;

  /// Texte d'aide sous le cadre de recadrage.
  ///
  /// In fr, this message translates to:
  /// **'Pincez pour zoomer, glissez pour cadrer.'**
  String get portraitCropScreenInstructions;

  /// `SecondaryButton` "Annuler".
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get portraitCropScreenCancelButton;

  /// `PrimaryButton` "Valider".
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get portraitCropScreenSaveButton;

  /// Bandeau d'alerte inline quand la capture du cadre recadré échoue (`byteData == null`) — géré directement, sans passer par une `CharacterFailure` (évite d'embarquer un message figé en français dans une exception du domaine).
  ///
  /// In fr, this message translates to:
  /// **'Impossible de préparer l\'image. Réessayez.'**
  String get portraitCropScreenPrepareImageErrorMessage;

  /// Bandeau d'alerte inline sur échec inattendu (pas une `CharacterFailure`) de `_submit`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'envoyer le portrait. Réessayez.'**
  String get portraitCropScreenGenericErrorMessage;

  /// Titre de la carte "Aventures" de l'onglet "Personnage".
  ///
  /// In fr, this message translates to:
  /// **'AVENTURES'**
  String get characterAdventuresCardTitle;

  /// Sous-titre de `_AdventureRow` affiché quand `gmDisplayName` est renseigné (`gmName` est une donnée joueur, jamais traduite).
  ///
  /// In fr, this message translates to:
  /// **'MJ : {gmName}'**
  String characterAdventuresCardGmLabel(String gmName);

  /// Tooltip de l'`IconButton` "Quitter" (`Icons.logout`) de `_AdventureRow`.
  ///
  /// In fr, this message translates to:
  /// **'Quitter l\'histoire'**
  String get characterAdventuresCardLeaveTooltip;

  /// SnackBar de confirmation de `_confirmAndLeave` (`storyTitle` est une donnée joueur, jamais traduite).
  ///
  /// In fr, this message translates to:
  /// **'Tu as quitté {storyTitle}.'**
  String characterAdventuresCardLeftMessage(String storyTitle);

  /// SnackBar d'échec de `_confirmAndLeave`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de quitter cette histoire. Réessayez.'**
  String get characterAdventuresCardLeaveGenericErrorMessage;

  /// Titre de `showLeaveAdventureConfirmationDialog` (`storyTitle` est une donnée joueur, jamais traduite).
  ///
  /// In fr, this message translates to:
  /// **'Quitter « {storyTitle} » ?'**
  String characterAdventuresCardLeaveConfirmationTitle(String storyTitle);

  /// Sous-titre de `showLeaveAdventureConfirmationDialog`.
  ///
  /// In fr, this message translates to:
  /// **'Ton personnage garde toutes ses données. Seul le lien avec cette histoire disparaît.'**
  String get characterAdventuresCardLeaveConfirmationMessage;

  /// `SecondaryButton` "Annuler" de `showLeaveAdventureConfirmationDialog`.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get characterAdventuresCardLeaveConfirmationCancelButton;

  /// `DestructiveButton` "Quitter" de `showLeaveAdventureConfirmationDialog`.
  ///
  /// In fr, this message translates to:
  /// **'Quitter'**
  String get characterAdventuresCardLeaveConfirmationConfirmButton;

  /// Tooltip de l'icône "?" du bandeau bois (`_Header`), ouvre l'aide contextuelle de l'étape.
  ///
  /// In fr, this message translates to:
  /// **'Aide'**
  String get editionStepScreenHelpTooltip;

  /// Titre d'étape du bandeau bois (`_Header`).
  ///
  /// In fr, this message translates to:
  /// **'1. Édition'**
  String get editionStepScreenHeaderTitle;

  /// Compteur d'étape du bandeau bois (`_Header`).
  ///
  /// In fr, this message translates to:
  /// **'Étape {currentStep} / {totalSteps}'**
  String editionStepScreenStepCounter(int currentStep, int totalSteps);

  /// Phrase d'intro affichée au-dessus des deux options d'édition.
  ///
  /// In fr, this message translates to:
  /// **'Choisis l\'édition des règles D&D 5e pour ce personnage. Ce choix est définitif.'**
  String get editionStepScreenIntroText;

  /// Titre de la tuile d'option "2014".
  ///
  /// In fr, this message translates to:
  /// **'2014 — Manuel des Joueurs'**
  String get editionStepScreenOption2014Title;

  /// Sous-titre de la tuile d'option "2014".
  ///
  /// In fr, this message translates to:
  /// **'L\'édition originale des règles D&D 5e, publiée en 2014.'**
  String get editionStepScreenOption2014Subtitle;

  /// Titre de la tuile d'option "2024".
  ///
  /// In fr, this message translates to:
  /// **'2024 — Manuel des Joueurs revu'**
  String get editionStepScreenOption2024Title;

  /// Sous-titre de la tuile d'option "2024".
  ///
  /// In fr, this message translates to:
  /// **'L\'édition révisée des règles D&D 5e, publiée en 2024, avec certains ajustements de règles.'**
  String get editionStepScreenOption2024Subtitle;

  /// `SecondaryButton` "Retour" (met son libellé en majuscules à l'affichage).
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get editionStepScreenBackButton;

  /// `PrimaryButton` "Suivant" (met son libellé en majuscules à l'affichage).
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get editionStepScreenNextButton;

  /// Tooltip de l'icône "?" du bandeau bois (`_Header`/`_MinimalHeader`), ouvre l'aide contextuelle de l'étape.
  ///
  /// In fr, this message translates to:
  /// **'Aide'**
  String get raceStepScreenHelpTooltip;

  /// Titre d'étape du bandeau bois (`_Header`).
  ///
  /// In fr, this message translates to:
  /// **'2. Race'**
  String get raceStepScreenHeaderTitle;

  /// Compteur d'étape du bandeau bois (`_Header`).
  ///
  /// In fr, this message translates to:
  /// **'Étape {currentStep} / {totalSteps}'**
  String raceStepScreenStepCounter(int currentStep, int totalSteps);

  /// Message de repli de `_ErrorState` quand l'erreur n'est pas une `CharacterCreationFailure`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les races disponibles. Réessayez.'**
  String get raceStepScreenGenericErrorMessage;

  /// `SecondaryButton` "Réessayer" de `_ErrorState` (met son libellé en majuscules à l'affichage).
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get raceStepScreenRetryButton;

  /// Phrase d'intro affichée au-dessus de la liste des races.
  ///
  /// In fr, this message translates to:
  /// **'Choisis l\'ascendance de ton personnage.'**
  String get raceStepScreenIntroText;

  /// Placeholder du champ de recherche, masqué en mode modification (race verrouillée).
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une race...'**
  String get raceStepScreenSearchHint;

  /// `InfoBanner` affiché en mode modification (race verrouillée).
  ///
  /// In fr, this message translates to:
  /// **'La race ne peut pas être modifiée après la création du personnage : elle est liée aux sorts innés déjà acquis.'**
  String get raceStepScreenLockedBannerMessage;

  /// En-tête de section (`_SectionHeader`) des races du Manuel des Joueurs.
  ///
  /// In fr, this message translates to:
  /// **'RACES DE BASE'**
  String get raceStepScreenCoreRacesSectionTitle;

  /// En-tête de section (`_SectionHeader`) des races hors Manuel des Joueurs.
  ///
  /// In fr, this message translates to:
  /// **'RACES D\'EXTENSION'**
  String get raceStepScreenExtensionRacesSectionTitle;

  /// Titre de la tuile "Race personnalisée", toujours affichée en dernier.
  ///
  /// In fr, this message translates to:
  /// **'Race personnalisée'**
  String get raceStepScreenCustomRaceTileTitle;

  /// Placeholder du `TextField` de saisie libre de la race personnalisée.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la race personnalisée'**
  String get raceStepScreenCustomRaceHint;

  /// `SecondaryButton` "Retour" (met son libellé en majuscules à l'affichage).
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get raceStepScreenBackButton;

  /// `PrimaryButton` "Suivant" (met son libellé en majuscules à l'affichage).
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get raceStepScreenNextButton;

  /// Message de `_EmptySearchState`, affiché quand la recherche ne trouve aucune race.
  ///
  /// In fr, this message translates to:
  /// **'Aucune race trouvée.'**
  String get raceStepScreenEmptySearchMessage;

  /// Libellé de sémantique (`Semantics.label`) d'un `_SuggestionChip` sous "Race personnalisée" (`raceName` est le nom d'une race indisponible dans l'édition courante, donnée du jeu jamais traduite ici).
  ///
  /// In fr, this message translates to:
  /// **'Utiliser \"{raceName}\" comme race personnalisée'**
  String raceStepScreenSuggestionChipSemanticsLabel(String raceName);

  /// Tooltip de l'icône "?" du bandeau bois (`_Header`/`_MinimalHeader`), ouvre l'aide contextuelle de l'étape.
  ///
  /// In fr, this message translates to:
  /// **'Aide'**
  String get subraceStepScreenHelpTooltip;

  /// Titre d'étape du bandeau bois (`_Header`).
  ///
  /// In fr, this message translates to:
  /// **'2. Sous-race'**
  String get subraceStepScreenHeaderTitle;

  /// Compteur d'étape du bandeau bois (`_Header`).
  ///
  /// In fr, this message translates to:
  /// **'Étape {currentStep} / {totalSteps}'**
  String subraceStepScreenStepCounter(int currentStep, int totalSteps);

  /// Message de repli de `_ErrorState` quand l'erreur n'est pas une `CharacterCreationFailure`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les races disponibles. Réessayez.'**
  String get subraceStepScreenGenericErrorMessage;

  /// `SecondaryButton` "Réessayer" de `_ErrorState` (met son libellé en majuscules à l'affichage).
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get subraceStepScreenRetryButton;

  /// Phrase d'intro affichée au-dessus de la liste des sous-races (`raceName` est le nom de la race choisie à l'étape précédente, donnée du jeu jamais traduite ici — ou le repli `subraceStepScreenFallbackRaceName`).
  ///
  /// In fr, this message translates to:
  /// **'Choisis une sous-race pour {raceName}.'**
  String subraceStepScreenIntroText(String raceName);

  /// `SecondaryButton` "Retour" (met son libellé en majuscules à l'affichage).
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get subraceStepScreenBackButton;

  /// `PrimaryButton` "Suivant" (met son libellé en majuscules à l'affichage).
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get subraceStepScreenNextButton;

  /// Repli de `_buildContent` quand `raceId` ne correspond à aucune race du catalogue (ne devrait pas arriver, race supprimée entre deux sessions) — injecté dans `subraceStepScreenIntroText`.
  ///
  /// In fr, this message translates to:
  /// **'cette race'**
  String get subraceStepScreenFallbackRaceName;

  /// Tooltip de l'icône "?" du bandeau bois (`_Header`/`_MinimalHeader`), ouvre l'aide contextuelle de l'étape.
  ///
  /// In fr, this message translates to:
  /// **'Aide'**
  String get lineageStepScreenHelpTooltip;

  /// Message de repli de `_ErrorState` quand l'erreur n'est pas une `CharacterCreationFailure`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les ascendances/lignées disponibles. Réessayez.'**
  String get lineageStepScreenGenericErrorMessage;

  /// `SecondaryButton` "Réessayer" de `_ErrorState` (met son libellé en majuscules à l'affichage).
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get lineageStepScreenRetryButton;

  /// `SecondaryButton` "Retour" (met son libellé en majuscules à l'affichage).
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get lineageStepScreenBackButton;

  /// `PrimaryButton` "Suivant" (met son libellé en majuscules à l'affichage).
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get lineageStepScreenNextButton;

  /// Compteur d'étape du bandeau bois (`_Header`).
  ///
  /// In fr, this message translates to:
  /// **'Étape {currentStep} / {totalSteps}'**
  String lineageStepScreenStepCounter(int currentStep, int totalSteps);

  /// Titre de bandeau de `_LineageStepCopy.forRaceId` pour le Tieffelin.
  ///
  /// In fr, this message translates to:
  /// **'2. Lignée'**
  String get lineageStepScreenTieffelinBannerTitle;

  /// Phrase d'intro de `_LineageStepCopy.forRaceId` pour le Tieffelin.
  ///
  /// In fr, this message translates to:
  /// **'Choisis ta lignée fiélonne.'**
  String get lineageStepScreenTieffelinIntroText;

  /// Titre de bandeau de `_LineageStepCopy.forRaceId` pour le Goliath.
  ///
  /// In fr, this message translates to:
  /// **'2. Ascendance'**
  String get lineageStepScreenGoliathBannerTitle;

  /// Phrase d'intro de `_LineageStepCopy.forRaceId` pour le Goliath.
  ///
  /// In fr, this message translates to:
  /// **'Choisis ton ascendance géante.'**
  String get lineageStepScreenGoliathIntroText;

  /// Titre de bandeau de `_LineageStepCopy.forRaceId` pour le Drakéide (valeur identique au Goliath, voir la doc de classe de `_LineageStepCopy`).
  ///
  /// In fr, this message translates to:
  /// **'2. Ascendance'**
  String get lineageStepScreenDrakeideBannerTitle;

  /// Phrase d'intro de `_LineageStepCopy.forRaceId` pour le Drakéide (repli par défaut du `switch`).
  ///
  /// In fr, this message translates to:
  /// **'Choisis ton ascendance draconique.'**
  String get lineageStepScreenDrakeideIntroText;

  /// Tooltip de l'icône "?" du bandeau bois (`_Header`/`_MinimalHeader`), ouvre l'aide contextuelle de l'étape.
  ///
  /// In fr, this message translates to:
  /// **'Aide'**
  String get backgroundStepScreenHelpTooltip;

  /// Titre d'étape du bandeau bois (`_Header`).
  ///
  /// In fr, this message translates to:
  /// **'4. Historique'**
  String get backgroundStepScreenHeaderTitle;

  /// Compteur d'étape du bandeau bois (`_Header`).
  ///
  /// In fr, this message translates to:
  /// **'Étape {currentStep} / {totalSteps}'**
  String backgroundStepScreenStepCounter(int currentStep, int totalSteps);

  /// Message de repli de `_ErrorState` quand l'erreur n'est pas une `CharacterCreationFailure`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les historiques disponibles. Réessayez.'**
  String get backgroundStepScreenGenericErrorMessage;

  /// `SecondaryButton` "Réessayer" de `_ErrorState` (met son libellé en majuscules à l'affichage).
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get backgroundStepScreenRetryButton;

  /// Phrase d'intro affichée au-dessus de la liste des historiques.
  ///
  /// In fr, this message translates to:
  /// **'D\'où vient ton personnage avant l\'aventure ?'**
  String get backgroundStepScreenIntroText;

  /// `SecondaryButton` "Retour" (met son libellé en majuscules à l'affichage).
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get backgroundStepScreenBackButton;

  /// `PrimaryButton` "Suivant" (met son libellé en majuscules à l'affichage).
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get backgroundStepScreenNextButton;

  /// Tooltip de l'icône "?" du bandeau bois (`_Header`/`_MinimalHeader`), ouvre l'aide contextuelle de l'étape.
  ///
  /// In fr, this message translates to:
  /// **'Aide'**
  String get classStepScreenHelpTooltip;

  /// Titre d'étape du bandeau bois (`_Header`).
  ///
  /// In fr, this message translates to:
  /// **'3. Classe'**
  String get classStepScreenHeaderTitle;

  /// Compteur d'étape du bandeau bois (`_Header`).
  ///
  /// In fr, this message translates to:
  /// **'Étape {currentStep} / {totalSteps}'**
  String classStepScreenStepCounter(int currentStep, int totalSteps);

  /// Phrase d'intro affichée au-dessus de la liste des classes.
  ///
  /// In fr, this message translates to:
  /// **'Choisis la voie que ton personnage empruntera.'**
  String get classStepScreenIntroText;

  /// Message de `InfoBanner` affiché en mode modification quand la classe est verrouillée (niveau > 1).
  ///
  /// In fr, this message translates to:
  /// **'La classe et la sous-classe ne peuvent être modifiées qu\'au niveau 1.'**
  String get classStepScreenLockedBannerMessage;

  /// `SecondaryButton` "Retour" (met son libellé en majuscules à l'affichage).
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get classStepScreenBackButton;

  /// `PrimaryButton` "Suivant" (met son libellé en majuscules à l'affichage).
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get classStepScreenNextButton;

  /// Message de repli de `_ErrorState` quand l'erreur n'est pas une `CharacterCreationFailure`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les classes disponibles. Réessayez.'**
  String get classStepScreenGenericErrorMessage;

  /// `SecondaryButton` "Réessayer" de `_ErrorState` (met son libellé en majuscules à l'affichage).
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get classStepScreenRetryButton;

  /// Tooltip de l'icône "?" du bandeau bois (`_Header`), ouvre l'aide contextuelle de l'étape (style de combat/ennemi juré/expertise).
  ///
  /// In fr, this message translates to:
  /// **'Aide'**
  String get classChoiceStepScreenHelpTooltip;

  /// Titre d'étape du bandeau bois (`_Header`), {title} vient de `ClassChoiceRules.titleFor` (domaine, reste en français — D149 de docs/dette-technique.md).
  ///
  /// In fr, this message translates to:
  /// **'3. {title}'**
  String classChoiceStepScreenHeaderTitle(String title);

  /// Compteur d'étape du bandeau bois (`_Header`).
  ///
  /// In fr, this message translates to:
  /// **'Étape {currentStep} / {totalSteps}'**
  String classChoiceStepScreenStepCounter(int currentStep, int totalSteps);

  /// Phrase d'intro affichée au-dessus des options, {className} vient des données (`ClassOption.name`, non traduit).
  ///
  /// In fr, this message translates to:
  /// **'Ce choix se fait dès le niveau 1 pour {className}.'**
  String classChoiceStepScreenIntroText(String className);

  /// Indication affichée en rouge tant qu'aucune option n'est sélectionnée (`_NamedChoiceBody`).
  ///
  /// In fr, this message translates to:
  /// **'Choisis une option pour continuer.'**
  String get classChoiceStepScreenChooseOptionHint;

  /// Libellé de repli si l'id de classe du brouillon est absent du catalogue chargé (`_NamedChoiceBody`, cas défensif), même principe que `subraceStepScreenFallbackRaceName`.
  ///
  /// In fr, this message translates to:
  /// **'cette classe'**
  String get classChoiceStepScreenFallbackClassName;

  /// `SecondaryButton` "Retour" (met son libellé en majuscules à l'affichage).
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get classChoiceStepScreenBackButton;

  /// `PrimaryButton` "Suivant" (met son libellé en majuscules à l'affichage).
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get classChoiceStepScreenNextButton;

  /// Message de repli de `_ErrorState` (`_NamedChoiceBody`) quand l'erreur n'est pas une `CharacterCreationFailure`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les classes disponibles. Réessayez.'**
  String get classChoiceStepScreenGenericErrorMessage;

  /// `SecondaryButton` "Réessayer" de `_ErrorState` (met son libellé en majuscules à l'affichage).
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get classChoiceStepScreenRetryButton;

  /// Titre de section au-dessus des compétences candidates à l'Expertise (`_ExpertiseBody`/`_SectionHeader`).
  ///
  /// In fr, this message translates to:
  /// **'COMPÉTENCES MAÎTRISÉES'**
  String get classChoiceStepScreenSkillsSectionTitle;

  /// Badge de quota de `_SectionHeader` (`_ExpertiseBody`), ex. "0 / 2 choisies".
  ///
  /// In fr, this message translates to:
  /// **'{selectedCount} / {effectiveQuota} choisies'**
  String classChoiceStepScreenQuotaBadge(int selectedCount, int effectiveQuota);

  /// Message défensif affiché quand `effectiveQuota <= 0` (`_ExpertiseBody`).
  ///
  /// In fr, this message translates to:
  /// **'Aucune option n\'est disponible pour ce choix. Tu peux continuer sans en faire.'**
  String get classChoiceStepScreenNoOptionsAvailableMessage;

  /// Message de repli de `_ErrorState` (`_ExpertiseBody`) quand l'erreur n'est pas une `CharacterCreationFailure`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les compétences disponibles. Réessayez.'**
  String get classChoiceStepScreenSkillsErrorMessage;

  /// Tooltip de l'icône "?" du bandeau bois (`_Header`/`_MinimalHeader`), ouvre l'aide contextuelle de l'étape.
  ///
  /// In fr, this message translates to:
  /// **'Aide'**
  String get subclassStepScreenHelpTooltip;

  /// Titre d'étape du bandeau bois (`_Header`).
  ///
  /// In fr, this message translates to:
  /// **'3. Sous-classe'**
  String get subclassStepScreenHeaderTitle;

  /// Compteur d'étape du bandeau bois (`_Header`).
  ///
  /// In fr, this message translates to:
  /// **'Étape {currentStep} / {totalSteps}'**
  String subclassStepScreenStepCounter(int currentStep, int totalSteps);

  /// Phrase d'intro affichée au-dessus du bloc de choix de sous-classe, {className} vient des données (`ClassOption.name`, non traduit).
  ///
  /// In fr, this message translates to:
  /// **'Ce choix se fait dès le niveau 1 pour {className}.'**
  String subclassStepScreenIntroText(String className);

  /// Libellé de repli si l'id de classe du brouillon est absent du catalogue chargé (cas défensif), même principe que `subraceStepScreenFallbackRaceName`.
  ///
  /// In fr, this message translates to:
  /// **'cette classe'**
  String get subclassStepScreenFallbackClassName;

  /// `SecondaryButton` "Retour" (met son libellé en majuscules à l'affichage).
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get subclassStepScreenBackButton;

  /// `PrimaryButton` "Suivant" (met son libellé en majuscules à l'affichage).
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get subclassStepScreenNextButton;

  /// Message de repli de `_ErrorState` quand l'erreur n'est pas une `CharacterCreationFailure`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les classes disponibles. Réessayez.'**
  String get subclassStepScreenGenericErrorMessage;

  /// `SecondaryButton` "Réessayer" de `_ErrorState` (met son libellé en majuscules à l'affichage).
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get subclassStepScreenRetryButton;

  /// Label de `Semantics` quand au moins une option est disponible, {title} vient de `SubclassChoiceRules.titleFor` (domaine, reste en français — D149 de docs/dette-technique.md).
  ///
  /// In fr, this message translates to:
  /// **'{title}, choix obligatoire'**
  String subclassChoiceBlockRequiredSemanticsLabel(String title);

  /// Phrase affichée au-dessus de la liste d'options de sous-classe.
  ///
  /// In fr, this message translates to:
  /// **'Ce choix se fait dès le niveau 1 pour cette classe.'**
  String get subclassChoiceBlockIntroText;

  /// Indication affichée en rouge tant qu'aucune sous-classe n'est sélectionnée.
  ///
  /// In fr, this message translates to:
  /// **'Choisis une option pour continuer.'**
  String get subclassChoiceBlockChooseOptionHint;

  /// Message défensif affiché quand le catalogue ne propose aucune option pour cette classe.
  ///
  /// In fr, this message translates to:
  /// **'Aucune sous-classe n\'est disponible pour cette classe. Tu peux continuer sans en choisir.'**
  String get subclassChoiceBlockEmptyMessage;

  /// Message d'erreur affiché en cas d'échec de chargement du catalogue de sous-classes.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les sous-classes disponibles. Réessaie.'**
  String get subclassChoiceBlockErrorMessage;

  /// `SecondaryButton` "Réessayer" affiché sous le message d'erreur (met son libellé en majuscules à l'affichage).
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get subclassChoiceBlockRetryButton;

  /// Titre de repli affiché avant que le choix (`SubclassFeatureChoice`) n'ait fini de se charger.
  ///
  /// In fr, this message translates to:
  /// **'Choix de sous-classe'**
  String get subclassFeatureChoiceBlockFallbackTitle;

  /// Label de `Semantics` quand au moins une option est disponible, {title} vient de `SubclassFeatureChoice.featureName` (donnée, non traduite).
  ///
  /// In fr, this message translates to:
  /// **'{title}, choix obligatoire'**
  String subclassFeatureChoiceBlockRequiredSemanticsLabel(String title);

  /// Texte annoncé aux lecteurs d'écran quand les options apparaissent, {featureName} vient de `SubclassFeatureChoice.featureName` (déjà passé en minuscules par l'appelant, donnée non traduite).
  ///
  /// In fr, this message translates to:
  /// **'Choisis le choix de {featureName}.'**
  String subclassFeatureChoiceBlockAnnouncement(String featureName);

  /// Phrase affichée au-dessus de la liste d'options du second choix de sous-classe.
  ///
  /// In fr, this message translates to:
  /// **'Ce choix se fait dès le niveau 1 de ta sous-classe.'**
  String get subclassFeatureChoiceBlockIntroText;

  /// Indication affichée en rouge tant qu'aucune option n'est sélectionnée.
  ///
  /// In fr, this message translates to:
  /// **'Choisis une option pour continuer.'**
  String get subclassFeatureChoiceBlockChooseOptionHint;

  /// Message défensif affiché quand `options` est vide (ex. D95, class_options pas encore peuplées).
  ///
  /// In fr, this message translates to:
  /// **'Aucune option n\'est disponible pour ce choix. Tu peux continuer sans en faire.'**
  String get subclassFeatureChoiceBlockNoOptionsMessage;

  /// Message d'erreur affiché en cas d'échec de chargement du second choix de niveau 1.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger ce choix de sous-classe. Réessaie.'**
  String get subclassFeatureChoiceBlockErrorMessage;

  /// `SecondaryButton` "Réessayer" affiché sous le message d'erreur (met son libellé en majuscules à l'affichage).
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get subclassFeatureChoiceBlockRetryButton;

  /// Tooltip de l'icône "?" du bandeau, ouvrant l'aide contextuelle de l'étape.
  ///
  /// In fr, this message translates to:
  /// **'Aide'**
  String get abilityScoreStepScreenHelpTooltip;

  /// Titre d'étape affiché sur le bandeau bois.
  ///
  /// In fr, this message translates to:
  /// **'5. Caractéristiques'**
  String get abilityScoreStepScreenHeaderTitle;

  /// Compteur d'étape affiché sur le bandeau bois.
  ///
  /// In fr, this message translates to:
  /// **'Étape {currentStep} / {totalSteps}'**
  String abilityScoreStepScreenStepCounter(int currentStep, int totalSteps);

  /// Message de repli de `_ErrorState` quand l'erreur n'est pas une `CharacterCreationFailure`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les bonus raciaux. Réessayez.'**
  String get abilityScoreStepScreenGenericErrorMessage;

  /// `SecondaryButton` "Réessayer" de `_ErrorState` (met son libellé en majuscules à l'affichage).
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get abilityScoreStepScreenRetryButton;

  /// Libellé du segment "Tableau standard" de la bascule de méthode (`SegmentedToggle`, met son libellé en majuscules à l'affichage).
  ///
  /// In fr, this message translates to:
  /// **'Tableau'**
  String get abilityScoreStepScreenMethodStandardLabel;

  /// Libellé du segment "Achat par points" de la bascule de méthode (`SegmentedToggle`, met son libellé en majuscules à l'affichage).
  ///
  /// In fr, this message translates to:
  /// **'Points'**
  String get abilityScoreStepScreenMethodPointBuyLabel;

  /// Libellé du segment "Dés" de la bascule de méthode (`SegmentedToggle`, met son libellé en majuscules à l'affichage).
  ///
  /// In fr, this message translates to:
  /// **'Dés'**
  String get abilityScoreStepScreenMethodDiceRollLabel;

  /// Points restants affichés pour la méthode "Achat par points" — pas de forme plurielle : "Points" reste invariable quel que soit le nombre restant (0 à 27), même convention que `classChoiceStepScreenQuotaBadge`.
  ///
  /// In fr, this message translates to:
  /// **'Points restants : {remaining}/{budget}'**
  String abilityScoreStepScreenPointsRemainingLabel(int remaining, int budget);

  /// Bouton texte affiché pour la méthode "Dés", relance les 6 dés.
  ///
  /// In fr, this message translates to:
  /// **'Relancer les dés'**
  String get abilityScoreStepScreenRerollDiceButton;

  /// `SecondaryButton` "Retour" (met son libellé en majuscules à l'affichage).
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get abilityScoreStepScreenBackButton;

  /// `PrimaryButton` "Suivant" (met son libellé en majuscules à l'affichage).
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get abilityScoreStepScreenNextButton;

  /// Modificateur affiché sous le nom de chaque caractéristique (`_AbilityRow`), {modifier} déjà formaté avec son signe (ex. "+2", "-1") par l'écran.
  ///
  /// In fr, this message translates to:
  /// **'Modificateur {modifier}'**
  String abilityScoreStepScreenModifierLabel(String modifier);

  /// Message de `InfoBanner` affiché en mode modification (saisie directe des 6 scores finaux).
  ///
  /// In fr, this message translates to:
  /// **'Scores finaux : bonus de race et améliorations déjà inclus. Ajuste-les librement (1 à 30).'**
  String get abilityScoreStepScreenEditIntroMessage;

  /// Rappel affiché en mode modification quand la race a changé depuis l'original, {before}/{after} viennent de `_racialBonusesLabel` (bonus de race/sous-race formatés par `RaceSummaryFormatter.formatAbilityBonuses`, domaine, non traduit — D157 de docs/dette-technique.md).
  ///
  /// In fr, this message translates to:
  /// **'Race modifiée — reporte toi-même la différence de bonus :\navant : {before}\nmaintenant : {after}'**
  String abilityScoreStepScreenRaceChangedMessage(String before, String after);

  /// Valeur de repli de `_racialBonusesLabel` quand la race/sous-race ne porte aucun bonus de caractéristique fixe (ex. race 2024).
  ///
  /// In fr, this message translates to:
  /// **'aucun'**
  String get abilityScoreStepScreenNoRacialBonusLabel;

  /// Tooltip de l'icône "?" du bandeau, ouvrant l'aide contextuelle de l'étape.
  ///
  /// In fr, this message translates to:
  /// **'Aide'**
  String get skillsAndToolsStepScreenHelpTooltip;

  /// Titre d'étape affiché sur le bandeau bois.
  ///
  /// In fr, this message translates to:
  /// **'6. Compétences'**
  String get skillsAndToolsStepScreenHeaderTitle;

  /// Compteur d'étape affiché sur le bandeau bois.
  ///
  /// In fr, this message translates to:
  /// **'Étape {currentStep} / {totalSteps}'**
  String skillsAndToolsStepScreenStepCounter(int currentStep, int totalSteps);

  /// Message de repli de `_ErrorState` quand l'erreur n'est pas une `CharacterCreationFailure`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les compétences et outils disponibles. Réessayez.'**
  String get skillsAndToolsStepScreenGenericErrorMessage;

  /// `SecondaryButton` "Réessayer" de `_ErrorState` (met son libellé en majuscules à l'affichage).
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get skillsAndToolsStepScreenRetryButton;

  /// `SecondaryButton` "Retour" (met son libellé en majuscules à l'affichage).
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get skillsAndToolsStepScreenBackButton;

  /// `PrimaryButton` "Suivant" (met son libellé en majuscules à l'affichage).
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get skillsAndToolsStepScreenNextButton;

  /// Titre de la section 1 (toujours affichée), déjà en majuscules dans le code (pas de transformation automatique).
  ///
  /// In fr, this message translates to:
  /// **'COMPÉTENCES DE CLASSE'**
  String get skillsAndToolsStepScreenClassSkillsSectionTitle;

  /// Titre de la section 2, affichée si la classe propose un choix ou un octroi automatique d'outils, déjà en majuscules dans le code.
  ///
  /// In fr, this message translates to:
  /// **'OUTILS (CLASSE)'**
  String get skillsAndToolsStepScreenClassToolsSectionTitle;

  /// Titre de la section 3 (jamais interactive, octroi automatique), déjà en majuscules dans le code.
  ///
  /// In fr, this message translates to:
  /// **'OUTILS (HISTORIQUE)'**
  String get skillsAndToolsStepScreenBackgroundToolsSectionTitle;

  /// Titre de la section 4, affichée si l'historique propose un choix de langues, déjà en majuscules dans le code.
  ///
  /// In fr, this message translates to:
  /// **'LANGUES (HISTORIQUE)'**
  String get skillsAndToolsStepScreenLanguagesSectionTitle;

  /// Titre de la section 5, affichée si la race propose un choix et/ou un octroi automatique de compétences, déjà en majuscules dans le code.
  ///
  /// In fr, this message translates to:
  /// **'COMPÉTENCES (RACE)'**
  String get skillsAndToolsStepScreenRaceSkillsSectionTitle;

  /// Titre de la section 6, affichée si la race propose un choix d'outils, déjà en majuscules dans le code.
  ///
  /// In fr, this message translates to:
  /// **'OUTILS (RACE)'**
  String get skillsAndToolsStepScreenRaceToolsSectionTitle;

  /// Badge de quota partagé par les 5 sections à choix interactif (compétences de classe, outils de classe, langues, compétences de race, outils de race) — pas de forme plurielle : "choisies" reste invariable quel que soit le quota (accord implicite avec "compétences"/"outils"/"langues", jamais énoncé littéralement), même convention que `classChoiceStepScreenQuotaBadge`.
  ///
  /// In fr, this message translates to:
  /// **'{selectedCount} / {quota} choisies'**
  String skillsAndToolsStepScreenQuotaBadge(int selectedCount, int quota);

  /// Infobulle de l'icône "?" du bandeau de l'étape 6/9 "Sorts".
  ///
  /// In fr, this message translates to:
  /// **'Aide'**
  String get spellsStepScreenHelpTooltip;

  /// Titre d'étape affiché sur le bandeau bois, en-tête de `SpellsStepScreen`.
  ///
  /// In fr, this message translates to:
  /// **'7. Sorts'**
  String get spellsStepScreenHeaderTitle;

  /// Compteur d'étape affiché à droite du titre sur le bandeau bois.
  ///
  /// In fr, this message translates to:
  /// **'Étape {currentStep} / {totalSteps}'**
  String spellsStepScreenStepCounter(int currentStep, int totalSteps);

  /// Message de repli affiché quand l'erreur n'est pas une `CharacterCreationFailure` (dont le message, lui, reste en français — D148, hors périmètre de ce lot).
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les sorts disponibles. Réessayez.'**
  String get spellsStepScreenGenericErrorMessage;

  /// Bouton de l'état d'erreur, relance les deux providers feuilles (classe + catalogue de sorts).
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get spellsStepScreenRetryButton;

  /// Bouton de retour vers l'étape 5/9 "Compétences et outils".
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get spellsStepScreenBackButton;

  /// Bouton de validation vers l'étape suivante.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get spellsStepScreenNextButton;

  /// Libellé de l'onglet des sorts mineurs ("cantrips", niveau 0) sur le sélecteur de pilules du bandeau — n'apparaît que si les deux onglets sont visibles (voir `SpellsStepScreen._Header`).
  ///
  /// In fr, this message translates to:
  /// **'Mineurs'**
  String get spellsStepScreenCantripTabLabel;

  /// Libellé de l'onglet des sorts de niveau 1 sur le sélecteur de pilules du bandeau.
  ///
  /// In fr, this message translates to:
  /// **'Niveau 1'**
  String get spellsStepScreenLevelOneTabLabel;

  /// Titre de section de l'onglet "Mineurs", déjà en majuscules dans le code.
  ///
  /// In fr, this message translates to:
  /// **'SORTS MINEURS CONNUS'**
  String get spellsStepScreenCantripSectionTitle;

  /// Titre de section de l'onglet "Niveau 1", déjà en majuscules dans le code.
  ///
  /// In fr, this message translates to:
  /// **'SORTS DE NIVEAU 1 CONNUS'**
  String get spellsStepScreenLevelOneSectionTitle;

  /// Badge de quota à droite du titre de section ("3 / 4") — purement numérique, sans aucun mot à accorder (contrairement à `skillsAndToolsStepScreenQuotaBadge`, qui porte le suffixe "choisies") : aucune forme plurielle à distinguer, `selectedCount`/`quota` ne sont jamais mis en mots.
  ///
  /// In fr, this message translates to:
  /// **'{selectedCount} / {quota}'**
  String spellsStepScreenQuotaBadge(int selectedCount, int quota);

  /// Infobulle du bouton ⓘ affiché à droite de chaque sort, ouvre `SpellOptionInfoSheet` (widget partagé avec `level_up_screen.dart`, hors périmètre de ce lot, voir le rapport).
  ///
  /// In fr, this message translates to:
  /// **'Description de {spellName}'**
  String spellsStepScreenSpellInfoTooltip(String spellName);

  /// Infobulle de l'icône "?" du bandeau de l'étape 7/9 "Équipement de départ".
  ///
  /// In fr, this message translates to:
  /// **'Aide'**
  String get equipmentStepScreenHelpTooltip;

  /// Titre d'étape affiché sur le bandeau bois, en-tête de `EquipmentStepScreen`.
  ///
  /// In fr, this message translates to:
  /// **'8. Équipement'**
  String get equipmentStepScreenHeaderTitle;

  /// Compteur d'étape affiché à droite du titre sur le bandeau bois.
  ///
  /// In fr, this message translates to:
  /// **'Étape {currentStep} / {totalSteps}'**
  String equipmentStepScreenStepCounter(int currentStep, int totalSteps);

  /// Message de repli affiché quand l'erreur n'est pas une `CharacterCreationFailure` (dont le message, lui, reste en français — D148, hors périmètre de ce lot).
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger l\'équipement de départ. Réessayez.'**
  String get equipmentStepScreenGenericErrorMessage;

  /// Bouton de l'état d'erreur, relance les trois providers feuilles (historiques, objets, classes).
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get equipmentStepScreenRetryButton;

  /// Bouton de retour vers l'étape précédente (5/9 ou 6/9 selon la classe).
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get equipmentStepScreenBackButton;

  /// Bouton de validation vers l'étape suivante.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get equipmentStepScreenNextButton;

  /// Libellé du premier onglet du `SegmentedToggle` (équipement automatiquement accordé par l'historique).
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get equipmentStepScreenBackgroundTabLabel;

  /// Libellé du second onglet du `SegmentedToggle`, avec le budget d'achat de l'historique entre parenthèses — unité "po" volontairement gardée telle quelle en anglais aussi, même rationale que `itemInfoPanelCostValue`/D145. `amount` est déjà formaté par `GoldAmountFormatter.format` (virgule française assumée, D144, hors périmètre de ce lot).
  ///
  /// In fr, this message translates to:
  /// **'Acheter ({amount} po)'**
  String equipmentStepScreenPurchaseTabLabel(String amount);

  /// Titre de la section optionnelle "Équipement de classe" (options A/B/C, affichée au-dessus des deux onglets), déjà en majuscules dans le code.
  ///
  /// In fr, this message translates to:
  /// **'ÉQUIPEMENT DE CLASSE'**
  String get equipmentStepScreenClassEquipmentSectionTitle;

  /// Titre d'une tuile d'option d'équipement de classe — `label` est la lettre brute de `classes.starting_equipment` ("A"/"B"/"C"), jamais traduite.
  ///
  /// In fr, this message translates to:
  /// **'Option {label}'**
  String equipmentStepScreenClassOptionTitle(String label);

  /// Titre de section de l'onglet "Historique", déjà en majuscules dans le code.
  ///
  /// In fr, this message translates to:
  /// **'ÉQUIPEMENT DE L\'HISTORIQUE'**
  String get equipmentStepScreenHistoryEquipmentSectionTitle;

  /// État vide de l'onglet "Historique" (ne devrait normalement jamais arriver pour le contenu peuplé).
  ///
  /// In fr, this message translates to:
  /// **'Aucun équipement pour cet historique.'**
  String get equipmentStepScreenEmptyHistoryMessage;

  /// État vide de l'onglet "Acheter" (catalogue d'objets vide, distinct de l'état d'erreur).
  ///
  /// In fr, this message translates to:
  /// **'Aucun objet disponible à l\'achat.'**
  String get equipmentStepScreenEmptyShopMessage;

  /// Bandeau d'alerte affiché à la place du bandeau "OR RESTANT" quand le panier dépasse le budget — même rationale "po" que `equipmentStepScreenPurchaseTabLabel`. `amount` est déjà formaté par `GoldAmountFormatter.format`.
  ///
  /// In fr, this message translates to:
  /// **'Budget dépassé de {amount} po'**
  String equipmentStepScreenOverBudgetMessage(String amount);

  /// Libellé du bandeau doré sur l'onglet "Historique" (équipement automatiquement accordé, pas de budget à gérer), déjà en majuscules dans le code.
  ///
  /// In fr, this message translates to:
  /// **'OR DE DÉPART'**
  String get equipmentStepScreenStartingGoldLabel;

  /// Libellé du bandeau doré sur l'onglet "Acheter" tant que le budget n'est pas dépassé, déjà en majuscules dans le code.
  ///
  /// In fr, this message translates to:
  /// **'OR RESTANT'**
  String get equipmentStepScreenRemainingGoldLabel;

  /// Montant affiché par le bandeau doré ("OR DE DÉPART"/"OR RESTANT") — même rationale "po" que `equipmentStepScreenPurchaseTabLabel`. `amount` est déjà formaté par `GoldAmountFormatter.format`.
  ///
  /// In fr, this message translates to:
  /// **'{amount} po'**
  String equipmentStepScreenGoldAmount(String amount);

  /// Sous-titre d'une tuile du catalogue d'achat ("Arme · 2 po") — `category` vient de `EquipmentCategoryRules.labelFor` (texte français en dur, D151, hors périmètre de ce lot) ; même rationale "po" que `equipmentStepScreenPurchaseTabLabel`. `cost` est déjà formaté par `GoldAmountFormatter.format`.
  ///
  /// In fr, this message translates to:
  /// **'{category} · {cost} po'**
  String equipmentStepScreenShopItemSubtitle(String category, String cost);

  /// Infobulle de l'icône "?" du bandeau de l'étape 9/10 "Histoire".
  ///
  /// In fr, this message translates to:
  /// **'Aide'**
  String get appearanceAndBackstoryStepScreenHelpTooltip;

  /// Titre d'étape affiché sur le bandeau bois, en-tête de `AppearanceAndBackstoryStepScreen`.
  ///
  /// In fr, this message translates to:
  /// **'9. Histoire'**
  String get appearanceAndBackstoryStepScreenHeaderTitle;

  /// Compteur d'étape affiché à droite du titre sur le bandeau bois.
  ///
  /// In fr, this message translates to:
  /// **'Étape {currentStep} / {totalSteps}'**
  String appearanceAndBackstoryStepScreenStepCounter(
    int currentStep,
    int totalSteps,
  );

  /// Bouton de retour vers l'étape précédente (8/10 "Équipement").
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get appearanceAndBackstoryStepScreenBackButton;

  /// Bouton de validation vers l'étape suivante — toujours actif (aucun champ requis à cette étape).
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get appearanceAndBackstoryStepScreenNextButton;

  /// Titre de la tuile "Portrait" en tête du corps de l'écran.
  ///
  /// In fr, this message translates to:
  /// **'Portrait'**
  String get appearanceAndBackstoryStepScreenPortraitTitle;

  /// Sous-titre de la tuile "Portrait" une fois un portrait déjà choisi (brouillon ou personnage existant en mode modification).
  ///
  /// In fr, this message translates to:
  /// **'Touchez pour changer ou retirer'**
  String get appearanceAndBackstoryStepScreenPortraitHasPhotoSubtitle;

  /// Sous-titre de la tuile "Portrait" tant qu'aucun portrait n'est choisi.
  ///
  /// In fr, this message translates to:
  /// **'Optionnel — touchez pour en ajouter un'**
  String get appearanceAndBackstoryStepScreenPortraitEmptySubtitle;

  /// Libellé du champ "Alignement" (`_AlignmentField`), déjà en majuscules dans le code.
  ///
  /// In fr, this message translates to:
  /// **'ALIGNEMENT'**
  String get appearanceAndBackstoryStepScreenAlignmentLabel;

  /// Option de repli du menu déroulant "Alignement" (aucun alignement choisi, valeur par défaut).
  ///
  /// In fr, this message translates to:
  /// **'Aucun'**
  String get appearanceAndBackstoryStepScreenAlignmentNoneOption;

  /// Message affiché à la place du menu déroulant "Alignement" si `alignmentCatalogProvider` échoue.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les alignements.'**
  String get appearanceAndBackstoryStepScreenAlignmentErrorMessage;

  /// Bouton texte qui relance `alignmentCatalogProvider` après un échec de chargement.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get appearanceAndBackstoryStepScreenAlignmentRetryButton;

  /// Libellé du champ court d'identité "Sexe" (`characters.sexe`), déjà en majuscules dans le code.
  ///
  /// In fr, this message translates to:
  /// **'SEXE'**
  String get appearanceAndBackstoryStepScreenSexeLabel;

  /// Placeholder du champ "Sexe".
  ///
  /// In fr, this message translates to:
  /// **'Ex. femme'**
  String get appearanceAndBackstoryStepScreenSexeHint;

  /// Libellé du champ court d'identité "Âge" (`characters.age`), déjà en majuscules dans le code.
  ///
  /// In fr, this message translates to:
  /// **'ÂGE'**
  String get appearanceAndBackstoryStepScreenAgeLabel;

  /// Placeholder du champ "Âge".
  ///
  /// In fr, this message translates to:
  /// **'Ex. 27 ans'**
  String get appearanceAndBackstoryStepScreenAgeHint;

  /// Libellé du champ court d'identité "Taille" (`characters.height`), déjà en majuscules dans le code.
  ///
  /// In fr, this message translates to:
  /// **'TAILLE'**
  String get appearanceAndBackstoryStepScreenHeightLabel;

  /// Placeholder du champ "Taille" — unité "m" volontairement gardée telle quelle en anglais aussi, même rationale que `equipmentStepScreenPurchaseTabLabel`/D145 pour "po".
  ///
  /// In fr, this message translates to:
  /// **'Ex. 1,75 m'**
  String get appearanceAndBackstoryStepScreenHeightHint;

  /// Libellé du champ court d'identité "Poids" (`characters.weight`), déjà en majuscules dans le code.
  ///
  /// In fr, this message translates to:
  /// **'POIDS'**
  String get appearanceAndBackstoryStepScreenWeightLabel;

  /// Placeholder du champ "Poids" — unité "kg" volontairement gardée telle quelle en anglais aussi, même rationale que `equipmentStepScreenPurchaseTabLabel`/D145 pour "po".
  ///
  /// In fr, this message translates to:
  /// **'Ex. 70 kg'**
  String get appearanceAndBackstoryStepScreenWeightHint;

  /// Libellé du champ court d'identité "Yeux" (`characters.eyes`), déjà en majuscules dans le code.
  ///
  /// In fr, this message translates to:
  /// **'YEUX'**
  String get appearanceAndBackstoryStepScreenEyesLabel;

  /// Placeholder du champ "Yeux".
  ///
  /// In fr, this message translates to:
  /// **'Ex. verts'**
  String get appearanceAndBackstoryStepScreenEyesHint;

  /// Libellé du champ court d'identité "Peau" (`characters.skin`), déjà en majuscules dans le code.
  ///
  /// In fr, this message translates to:
  /// **'PEAU'**
  String get appearanceAndBackstoryStepScreenSkinLabel;

  /// Placeholder du champ "Peau".
  ///
  /// In fr, this message translates to:
  /// **'Ex. hâlée'**
  String get appearanceAndBackstoryStepScreenSkinHint;

  /// Libellé du champ court d'identité "Cheveux" (`characters.hair`), déjà en majuscules dans le code.
  ///
  /// In fr, this message translates to:
  /// **'CHEVEUX'**
  String get appearanceAndBackstoryStepScreenHairLabel;

  /// Placeholder du champ "Cheveux".
  ///
  /// In fr, this message translates to:
  /// **'Ex. bruns, courts'**
  String get appearanceAndBackstoryStepScreenHairHint;

  /// Libellé du 1er des 9 champs texte libre — même texte que `characterStoryEditSheetAppearanceLabel` (duplication assumée, voir le commentaire de classe de `_fieldSpecsFor`), déjà en majuscules dans le code.
  ///
  /// In fr, this message translates to:
  /// **'APPARENCE PHYSIQUE'**
  String get appearanceAndBackstoryStepScreenAppearanceLabel;

  /// Placeholder du champ "Apparence physique" — même texte que `characterStoryEditSheetAppearanceHint`.
  ///
  /// In fr, this message translates to:
  /// **'Décris l\'apparence physique de ton personnage…'**
  String get appearanceAndBackstoryStepScreenAppearanceHint;

  /// Libellé du champ "Traits de personnalité" — même texte que `characterStoryEditSheetTraitsLabel`, déjà en majuscules dans le code.
  ///
  /// In fr, this message translates to:
  /// **'TRAITS DE PERSONNALITÉ'**
  String get appearanceAndBackstoryStepScreenTraitsLabel;

  /// Placeholder du champ "Traits de personnalité" — même texte que `characterStoryEditSheetTraitsHint`.
  ///
  /// In fr, this message translates to:
  /// **'Décris les traits de personnalité de ton personnage…'**
  String get appearanceAndBackstoryStepScreenTraitsHint;

  /// Libellé du champ "Idéaux" — même texte que `characterStoryEditSheetIdealsLabel`, déjà en majuscules dans le code.
  ///
  /// In fr, this message translates to:
  /// **'IDÉAUX'**
  String get appearanceAndBackstoryStepScreenIdealsLabel;

  /// Placeholder du champ "Idéaux" — même texte que `characterStoryEditSheetIdealsHint`.
  ///
  /// In fr, this message translates to:
  /// **'Quels idéaux guident ton personnage ?'**
  String get appearanceAndBackstoryStepScreenIdealsHint;

  /// Libellé du champ "Liens" — même texte que `characterStoryEditSheetBondsLabel`, déjà en majuscules dans le code.
  ///
  /// In fr, this message translates to:
  /// **'LIENS'**
  String get appearanceAndBackstoryStepScreenBondsLabel;

  /// Placeholder du champ "Liens" — même texte que `characterStoryEditSheetBondsHint`.
  ///
  /// In fr, this message translates to:
  /// **'Quels liens unissent ton personnage à d\'autres ?'**
  String get appearanceAndBackstoryStepScreenBondsHint;

  /// Libellé du champ "Défauts" — même texte que `characterStoryEditSheetFlawsLabel`, déjà en majuscules dans le code.
  ///
  /// In fr, this message translates to:
  /// **'DÉFAUTS'**
  String get appearanceAndBackstoryStepScreenFlawsLabel;

  /// Placeholder du champ "Défauts" — même texte que `characterStoryEditSheetFlawsHint`.
  ///
  /// In fr, this message translates to:
  /// **'Quels défauts ou faiblesses a ton personnage ?'**
  String get appearanceAndBackstoryStepScreenFlawsHint;

  /// Libellé du champ "Histoire personnelle" — même texte que `characterStoryEditSheetBackstoryLabel`, déjà en majuscules dans le code.
  ///
  /// In fr, this message translates to:
  /// **'HISTOIRE PERSONNELLE'**
  String get appearanceAndBackstoryStepScreenBackstoryLabel;

  /// Placeholder du champ "Histoire personnelle" — même texte que `characterStoryEditSheetBackstoryHint`.
  ///
  /// In fr, this message translates to:
  /// **'Raconte l\'histoire personnelle de ton personnage…'**
  String get appearanceAndBackstoryStepScreenBackstoryHint;

  /// Libellé du champ "Alliés" — même texte que `characterStoryEditSheetAlliesLabel`, déjà en majuscules dans le code.
  ///
  /// In fr, this message translates to:
  /// **'ALLIÉS'**
  String get appearanceAndBackstoryStepScreenAlliesLabel;

  /// Placeholder du champ "Alliés" — même texte que `characterStoryEditSheetAlliesHint`.
  ///
  /// In fr, this message translates to:
  /// **'Quels alliés ou organisations soutiennent ton personnage ?'**
  String get appearanceAndBackstoryStepScreenAlliesHint;

  /// Libellé du champ "Particularités" — même texte que `characterStoryEditSheetFeaturesLabel`, déjà en majuscules dans le code.
  ///
  /// In fr, this message translates to:
  /// **'PARTICULARITÉS'**
  String get appearanceAndBackstoryStepScreenFeaturesLabel;

  /// Placeholder du champ "Particularités" — même texte que `characterStoryEditSheetFeaturesHint`.
  ///
  /// In fr, this message translates to:
  /// **'Décris les particularités de ton personnage…'**
  String get appearanceAndBackstoryStepScreenFeaturesHint;

  /// Libellé du champ "Trésor" — même texte que `characterStoryEditSheetTreasureLabel`, déjà en majuscules dans le code.
  ///
  /// In fr, this message translates to:
  /// **'TRÉSOR'**
  String get appearanceAndBackstoryStepScreenTreasureLabel;

  /// Placeholder du champ "Trésor" — même texte que `characterStoryEditSheetTreasureHint`.
  ///
  /// In fr, this message translates to:
  /// **'Quels trésors ou objets précieux possède ton personnage ?'**
  String get appearanceAndBackstoryStepScreenTreasureHint;

  /// Infobulle de l'icône "?" du bandeau de l'étape 10/10 "Récapitulatif".
  ///
  /// In fr, this message translates to:
  /// **'Aide'**
  String get summaryStepScreenHelpTooltip;

  /// Titre d'étape affiché sur le bandeau bois, en-tête de `SummaryStepScreen`.
  ///
  /// In fr, this message translates to:
  /// **'10. Récapitulatif'**
  String get summaryStepScreenHeaderTitle;

  /// Compteur d'étape affiché à droite du titre sur le bandeau bois.
  ///
  /// In fr, this message translates to:
  /// **'Étape {currentStep} / {totalSteps}'**
  String summaryStepScreenStepCounter(int currentStep, int totalSteps);

  /// Message de repli affiché quand l'erreur n'est pas une `CharacterCreationFailure` (dont le message, lui, reste en français — D148, hors périmètre de ce lot).
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger le récapitulatif. Réessayez.'**
  String get summaryStepScreenGenericErrorMessage;

  /// Bouton de l'état d'erreur, relance tous les providers feuilles consommés par cette étape.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get summaryStepScreenRetryButton;

  /// `SnackBar` affiché après une création réussie dont l'envoi du portrait (best-effort, voir `_submit`) a échoué.
  ///
  /// In fr, this message translates to:
  /// **'Personnage créé, mais le portrait n\'a pas pu être envoyé. Ajoutez-le depuis la fiche.'**
  String get summaryStepScreenPortraitUploadFailedMessage;

  /// Message de repli affiché quand l'échec de `createCharacter`/`CharacterEditRepository.save` n'est pas une `CharacterCreationFailure` (dont le message, lui, reste en français — D148, hors périmètre de ce lot) — même clé réutilisée pour `_submit` et `_saveEdit`.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Réessayez.'**
  String get summaryStepScreenGenericSubmitErrorMessage;

  /// `SnackBar` affiché après l'enregistrement réussi d'une modification (mode édition, `_saveEdit`).
  ///
  /// In fr, this message translates to:
  /// **'Modifications enregistrées.'**
  String get summaryStepScreenEditSavedMessage;

  /// Dernier segment du sous-titre de la carte d'en-tête ("{Race} · {Classe} · Niveau 1") — toujours "Niveau 1", l'assistant de création ne produisant que des personnages de niveau 1.
  ///
  /// In fr, this message translates to:
  /// **'Niveau 1'**
  String get summaryStepScreenLevelOneSegment;

  /// Titre de la ligne de résumé "Caractéristiques", renvoie à l'étape 5/10.
  ///
  /// In fr, this message translates to:
  /// **'Caractéristiques'**
  String get summaryStepScreenAbilityScoresRowTitle;

  /// Titre de la ligne de résumé "Compétences", renvoie à l'étape 6/10.
  ///
  /// In fr, this message translates to:
  /// **'Compétences'**
  String get summaryStepScreenSkillsRowTitle;

  /// Titre de la ligne de résumé "Outils" (masquée si aucun outil choisi), renvoie à l'étape 6/10.
  ///
  /// In fr, this message translates to:
  /// **'Outils'**
  String get summaryStepScreenToolsRowTitle;

  /// Titre de la ligne de résumé "Langues" (masquée si aucune langue d'historique choisie), renvoie à l'étape 6/10.
  ///
  /// In fr, this message translates to:
  /// **'Langues'**
  String get summaryStepScreenLanguagesRowTitle;

  /// Titre de la ligne de résumé "Sorts mineurs" (classe lanceuse de sorts uniquement), renvoie à l'étape 7/10.
  ///
  /// In fr, this message translates to:
  /// **'Sorts mineurs'**
  String get summaryStepScreenCantripsRowTitle;

  /// Titre de la ligne de résumé "Sorts niveau 1" (classe lanceuse de sorts uniquement), renvoie à l'étape 7/10.
  ///
  /// In fr, this message translates to:
  /// **'Sorts niveau 1'**
  String get summaryStepScreenLevelOneSpellsRowTitle;

  /// Valeur des lignes "Sorts mineurs"/"Sorts niveau 1" — ancien texte "{N} sélectionné(s)" (jamais accordé, qu'il y ait 0, 1 ou plusieurs sorts choisis) remplacé par un pluriel ICU à cette occasion.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun sélectionné} =1{1 sélectionné} other{{count} sélectionnés}}'**
  String summaryStepScreenSpellSelectionCount(int count);

  /// Titre de la ligne de résumé "Équipement" (absente en mode modification, l'inventaire se gérant depuis l'onglet Sac), renvoie à l'étape 8/10.
  ///
  /// In fr, this message translates to:
  /// **'Équipement'**
  String get summaryStepScreenEquipmentRowTitle;

  /// Valeur de la ligne "Équipement" quand l'onglet "Historique" de l'étape 8/10 est actif.
  ///
  /// In fr, this message translates to:
  /// **'Historique : {backgroundName}'**
  String summaryStepScreenEquipmentBackgroundSummary(String backgroundName);

  /// Valeur de la ligne "Équipement" quand l'onglet "Acheter" de l'étape 8/10 est actif — ancien texte "Achat ({N} objets)" (jamais accordé, y compris pour 1 objet) remplacé par un pluriel ICU à cette occasion.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Achat (0 objet)} =1{Achat (1 objet)} other{Achat ({count} objets)}}'**
  String summaryStepScreenEquipmentPurchaseSummary(int count);

  /// Préfixe ajouté devant `summaryStepScreenEquipmentBackgroundSummary`/`summaryStepScreenEquipmentPurchaseSummary` (`base`) quand la classe a une option d'équipement de départ choisie (règles 2024) — `label` est la lettre brute ("A"/"B"), jamais traduite.
  ///
  /// In fr, this message translates to:
  /// **'Classe : option {label} · {base}'**
  String summaryStepScreenEquipmentClassOptionPrefix(String label, String base);

  /// Titre de la ligne de résumé "Histoire & portrait", renvoie à l'étape 9/10.
  ///
  /// In fr, this message translates to:
  /// **'Histoire & portrait'**
  String get summaryStepScreenAppearanceAndBackstoryRowTitle;

  /// Valeur de la ligne "Histoire & portrait" si au moins un des 9 champs texte de l'étape 9/10 est renseigné.
  ///
  /// In fr, this message translates to:
  /// **'Renseignés'**
  String get summaryStepScreenAppearanceFilledValue;

  /// Valeur de la ligne "Histoire & portrait" si les 9 champs texte de l'étape 9/10 sont tous vides.
  ///
  /// In fr, this message translates to:
  /// **'Non renseignés'**
  String get summaryStepScreenAppearanceEmptyValue;

  /// Libellé du champ "Nom du personnage", déjà en majuscules dans le code.
  ///
  /// In fr, this message translates to:
  /// **'NOM DU PERSONNAGE'**
  String get summaryStepScreenNameFieldLabel;

  /// Placeholder du champ "Nom du personnage".
  ///
  /// In fr, this message translates to:
  /// **'Ex. Halltesse Ambrelune'**
  String get summaryStepScreenNameFieldHint;

  /// Texte d'aide discret sous le champ "Nom du personnage" (jamais un style d'erreur, voir la documentation de classe de `SummaryStepScreen`).
  ///
  /// In fr, this message translates to:
  /// **'Requis pour retrouver facilement ton personnage'**
  String get summaryStepScreenNameFieldHelperText;

  /// Repli affiché par la carte d'en-tête tant qu'aucun nom n'est saisi.
  ///
  /// In fr, this message translates to:
  /// **'Personnage sans nom'**
  String get summaryStepScreenUnnamedCharacterFallback;

  /// Lien "Retour" sous la liste de résumé (style lien souligné, pas un `SecondaryButton`).
  ///
  /// In fr, this message translates to:
  /// **'‹ Retour'**
  String get summaryStepScreenBackLink;

  /// Libellé du bouton primaire en mode modification.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les modifications'**
  String get summaryStepScreenSaveEditButton;

  /// Libellé du bouton primaire en mode création — désactivé tant que le nom (trim) est vide.
  ///
  /// In fr, this message translates to:
  /// **'Créer le personnage'**
  String get summaryStepScreenCreateButton;

  /// Libellé du bandeau bois de chaque étape de l'assistant hors mode modification (`CreationModeTitle`).
  ///
  /// In fr, this message translates to:
  /// **'CRÉATION'**
  String get creationModeTitleCreationLabel;

  /// Libellé du bandeau bois de chaque étape de l'assistant quand une `CharacterEditSession` est ouverte (`CreationModeTitle`).
  ///
  /// In fr, this message translates to:
  /// **'MODIFICATION'**
  String get creationModeTitleModificationLabel;

  /// Préfixe du pied de page des étapes 1 à 9, hors mode modification (`DraftAutosaveFooter`).
  ///
  /// In fr, this message translates to:
  /// **'↻ Brouillon sauvegardé automatiquement · '**
  String get draftAutosaveFooterAutosavedPrefix;

  /// Préfixe du pied de page des étapes 1 à 9, en mode modification (`DraftAutosaveFooter`).
  ///
  /// In fr, this message translates to:
  /// **'Modification en cours · '**
  String get draftAutosaveFooterModifyingPrefix;

  /// Lien tapable du pied de page hors mode modification, ouvre `showAbandonCreationConfirmationDialog` (`DraftAutosaveFooter`).
  ///
  /// In fr, this message translates to:
  /// **'Abandonner'**
  String get draftAutosaveFooterAbandonLink;

  /// Lien tapable du pied de page en mode modification, ouvre `showAbandonCreationConfirmationDialog` (`DraftAutosaveFooter`).
  ///
  /// In fr, this message translates to:
  /// **'Annuler les modifications'**
  String get draftAutosaveFooterCancelModificationsLink;

  /// Titre du dialogue de confirmation hors mode modification (`showAbandonCreationConfirmationDialog`).
  ///
  /// In fr, this message translates to:
  /// **'Abandonner la création ?'**
  String get abandonCreationFlowAbandonDialogTitle;

  /// Titre du dialogue de confirmation en mode modification (`showAbandonCreationConfirmationDialog`).
  ///
  /// In fr, this message translates to:
  /// **'Annuler les modifications ?'**
  String get abandonCreationFlowCancelEditDialogTitle;

  /// Corps du dialogue de confirmation hors mode modification (`showAbandonCreationConfirmationDialog`).
  ///
  /// In fr, this message translates to:
  /// **'Les choix déjà faits dans ce brouillon seront perdus. Cette action est définitive.'**
  String get abandonCreationFlowAbandonDialogMessage;

  /// Corps du dialogue de confirmation en mode modification (`showAbandonCreationConfirmationDialog`).
  ///
  /// In fr, this message translates to:
  /// **'Le personnage reste tel qu\'il était : rien de ce qui a été changé dans cet assistant ne sera enregistré.'**
  String get abandonCreationFlowCancelEditDialogMessage;

  /// Bouton secondaire du dialogue de confirmation (referme sans rien faire), même libellé dans les deux modes.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get abandonCreationFlowContinueButton;

  /// Bouton destructif du dialogue de confirmation hors mode modification.
  ///
  /// In fr, this message translates to:
  /// **'Abandonner'**
  String get abandonCreationFlowAbandonButton;

  /// Bouton destructif du dialogue de confirmation en mode modification.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get abandonCreationFlowCancelEditButton;

  /// Titre de la carte de répartition des bonus raciaux au choix (`RacialBonusChoiceCard`).
  ///
  /// In fr, this message translates to:
  /// **'Bonus racial au choix'**
  String get racialBonusChoiceCardTitle;

  /// Sous-titre de la carte tant que la répartition n'est pas complète — `ruleLabel` vient de `RacialBonusChoiceSpec.ruleLabel` (texte en dur en français, hors périmètre de ce lot, voir D154).
  ///
  /// In fr, this message translates to:
  /// **'{ruleLabel} — à répartir'**
  String racialBonusChoiceCardRuleIncomplete(String ruleLabel);

  /// Option du `SegmentedToggle` du motif de bonus flexible (+2 à une caractéristique, +1 à une autre).
  ///
  /// In fr, this message translates to:
  /// **'+2 / +1'**
  String get racialBonusChoiceCardTwoOnePatternLabel;

  /// Option du `SegmentedToggle` du motif de bonus flexible (+1 à trois caractéristiques).
  ///
  /// In fr, this message translates to:
  /// **'+1 / +1 / +1'**
  String get racialBonusChoiceCardOneOneOnePatternLabel;

  /// Titre du bandeau de `group_list_screen.dart` (`_Header`), déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'GROUPES'**
  String get groupListScreenTitle;

  /// Bouton primaire en pied d'écran, navigue vers `/groups/new`.
  ///
  /// In fr, this message translates to:
  /// **'Créer un groupe'**
  String get groupListScreenCreateButtonLabel;

  /// Bouton secondaire en pied d'écran, navigue vers `/groups/join`.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre un groupe'**
  String get groupListScreenJoinButtonLabel;

  /// Message de repli de `_ErrorState` quand l'erreur de `myGroupsProvider` n'est pas une `GroupFailure` (voir `groupAccessDeniedErrorMessage`/`groupNetworkErrorMessage` sinon).
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger vos groupes. Réessayez.'**
  String get groupListScreenLoadErrorMessage;

  /// Titre de `_EmptyState` (aucun groupe rejoint), déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'AUCUN GROUPE POUR L\'INSTANT'**
  String get groupListScreenEmptyTitle;

  /// Corps de `_EmptyState`.
  ///
  /// In fr, this message translates to:
  /// **'Crée un groupe pour ton équipe, ou rejoins celui de tes coéquipiers avec un code d\'invitation.'**
  String get groupListScreenEmptyBody;

  /// Nombre de membres affiché sous le nom d'un groupe (`_GroupRow`) — ancien texte en dur toujours au pluriel ("1 membres"), corrigé en ICU plural par cette migration.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 membre} other{{count} membres}}'**
  String groupListScreenMemberCountLabel(int count);

  /// Badge affiché à côté du nom d'un groupe fondé par le joueur connecté (`_FounderBadge`), déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'TOI'**
  String get groupListScreenFounderBadgeLabel;

  /// `SecondaryButton` "Réessayer" de `_ErrorState` (met son libellé en majuscules à l'affichage).
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get groupListScreenRetryButtonLabel;

  /// Résolution de `GroupFailure.code == GroupErrorCode.accessDenied` — même rationale que `characterAccessDeniedErrorMessage` (clé partagée par tous les écrans qui consomment `GroupFailure`, pas propre à un seul écran).
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez pas accès à ce groupe.'**
  String get groupAccessDeniedErrorMessage;

  /// Résolution de `GroupFailure.code == GroupErrorCode.network` — même rationale que `characterNetworkErrorMessage`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de contacter le serveur. Vérifiez votre connexion internet et réessayez.'**
  String get groupNetworkErrorMessage;

  /// `SheetHeaderBar.title` de la sheet de sélection de rôle ouverte par `_RoleSelectorTile`, déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'CHOISIR TON RÔLE'**
  String get groupCreateScreenRolePickerTitle;

  /// Message de repli de l'état d'erreur de la sheet de rôle quand l'erreur de `charactersProvider` n'est pas une `CharacterFailure`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger vos personnages. Réessayez.'**
  String get groupCreateScreenCharactersLoadErrorMessage;

  /// Titre du `WoodBackHeader` de `group_create_screen.dart`, déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'CRÉER UN GROUPE'**
  String get groupCreateScreenTitle;

  /// Texte d'intro affiché en tête du corps parchemin.
  ///
  /// In fr, this message translates to:
  /// **'Un groupe permet de suivre les PV de ton équipe en direct et de gérer un butin commun, indépendamment des histoires du MJ.'**
  String get groupCreateScreenIntro;

  /// Libellé au-dessus du `TextFormField` du nom du groupe.
  ///
  /// In fr, this message translates to:
  /// **'Nom du groupe'**
  String get groupCreateScreenNameLabel;

  /// `hintText` du `TextFormField` du nom du groupe.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Les Lames de l\'Aube'**
  String get groupCreateScreenNameHint;

  /// Libellé au-dessus de `_RoleSelectorTile`.
  ///
  /// In fr, this message translates to:
  /// **'Qui te représente dans ce groupe ?'**
  String get groupCreateScreenRoleQuestionLabel;

  /// Sous-texte sous `groupCreateScreenRoleQuestionLabel`.
  ///
  /// In fr, this message translates to:
  /// **'Ce personnage représentera ta présence dans le tableau de bord du groupe.'**
  String get groupCreateScreenRoleQuestionHint;

  /// Bouton primaire en pied d'écran, soumet `createGroup`.
  ///
  /// In fr, this message translates to:
  /// **'Créer le groupe'**
  String get groupCreateScreenSubmitButtonLabel;

  /// `SnackBar` affiché après la création réussie, juste avant de naviguer vers `/groups/:id`.
  ///
  /// In fr, this message translates to:
  /// **'Groupe créé !'**
  String get groupCreateScreenSuccessSnackbar;

  /// Message de repli de `_errorMessage` quand l'erreur de `createGroup` n'est pas une `GroupFailure` (voir `groupAccessDeniedErrorMessage`/`groupNetworkErrorMessage` sinon).
  ///
  /// In fr, this message translates to:
  /// **'Impossible de créer le groupe. Réessayez.'**
  String get groupCreateScreenGenericErrorMessage;

  /// Libellé du rôle "MJ sans personnage", affiché par `_GmOptionRow` (sheet) et `_RoleSelectorTile` (tuile) une fois ce rôle choisi.
  ///
  /// In fr, this message translates to:
  /// **'MJ — sans personnage'**
  String get groupCreateScreenGameMasterRoleLabel;

  /// Texte de `_CreatingGroupOverlay`, affiché pendant `createGroup`.
  ///
  /// In fr, this message translates to:
  /// **'Création du groupe...'**
  String get groupCreateScreenCreatingOverlayMessage;

  /// Note de `_NoCharacterNote`, affichée sous la ligne MJ de la sheet quand `charactersProvider` résout une liste vide.
  ///
  /// In fr, this message translates to:
  /// **'Tu n\'as pas encore de personnage à inscrire dans ce groupe.'**
  String get groupCreateScreenNoCharacterNote;

  /// Note de `_InviteCodeNote`, affichée sous `_RoleSelectorTile`.
  ///
  /// In fr, this message translates to:
  /// **'Un code d\'invitation sera généré automatiquement à la création.'**
  String get groupCreateScreenInviteCodeNote;

  /// Texte de `_RoleSelectorTile` tant qu'aucun personnage/rôle n'est choisi.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un personnage ou un rôle'**
  String get groupCreateScreenRoleSelectorPlaceholder;

  /// `SecondaryButton` "Réessayer" de l'état d'erreur de la sheet de rôle (surface parchemin).
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get groupCreateScreenCharactersRetryButtonLabel;

  /// Bandeau générique (`AlertBanner`) affiché pour `GroupInviteFailureKind.generic` et toute erreur inattendue de `previewGroupInvite`/`joinGroup`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de rejoindre ce groupe. Réessayez.'**
  String get groupJoinScreenGenericErrorMessage;

  /// `SheetHeaderBar.title` de la sheet de sélection de rôle ouverte par `_RoleSelectorTile`, déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'CHOISIR TON RÔLE'**
  String get groupJoinScreenRolePickerTitle;

  /// Message de repli de `_CharacterTileError` quand l'erreur de `charactersProvider` n'est pas une `CharacterFailure`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger vos personnages. Réessayez.'**
  String get groupJoinScreenCharactersLoadErrorMessage;

  /// Titre du `WoodBackHeader` de `group_join_screen.dart`, déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'REJOINDRE UN GROUPE'**
  String get groupJoinScreenTitle;

  /// `SnackBar` affiché après le rattachement réussi, juste avant de naviguer vers `/groups/:id`.
  ///
  /// In fr, this message translates to:
  /// **'Groupe rejoint !'**
  String get groupJoinScreenSuccessSnackbar;

  /// Texte d'aide discret sous le champ code (`_CodeErrorHint`), pour `GroupInviteFailureKind.invalidCode` (aperçu ou rattachement).
  ///
  /// In fr, this message translates to:
  /// **'Ce code d\'invitation n\'est pas valide.'**
  String get groupJoinScreenInvalidCodeErrorMessage;

  /// Bandeau (`AlertBanner`) pour `GroupInviteFailureKind.alreadyInGroup`.
  ///
  /// In fr, this message translates to:
  /// **'Ce personnage est déjà membre de ce groupe.'**
  String get groupJoinScreenAlreadyInGroupErrorMessage;

  /// Bandeau (`AlertBanner`) pour `GroupInviteFailureKind.mjAlreadyAssigned`.
  ///
  /// In fr, this message translates to:
  /// **'Ce groupe a déjà un MJ sans personnage.'**
  String get groupJoinScreenMjAlreadyAssignedErrorMessage;

  /// Texte d'intro affiché en tête du corps scrollable.
  ///
  /// In fr, this message translates to:
  /// **'Demande le code d\'invitation à un membre du groupe, puis choisis le personnage qui vous rejoindra.'**
  String get groupJoinScreenIntro;

  /// `_SectionLabel` au-dessus du champ code.
  ///
  /// In fr, this message translates to:
  /// **'Code d\'invitation'**
  String get groupJoinScreenCodeFieldLabel;

  /// `hintText` du champ code (`_CodeField`) — exemple de code, alphanumérique, identique dans toutes les langues.
  ///
  /// In fr, this message translates to:
  /// **'AB3F - 7K2M'**
  String get groupJoinScreenCodeFieldHint;

  /// `_SectionLabel` au-dessus de `_RoleSelectorTile`.
  ///
  /// In fr, this message translates to:
  /// **'Qui te représente dans ce groupe ?'**
  String get groupJoinScreenRoleQuestionLabel;

  /// Bouton primaire en pied d'écran, soumet `previewGroupInvite` puis `joinGroup`.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre'**
  String get groupJoinScreenSubmitButtonLabel;

  /// Libellé du rôle "MJ sans personnage", affiché par `_GmOptionRow` (sheet) et `_RoleSelectorTile` (tuile) une fois ce rôle choisi.
  ///
  /// In fr, this message translates to:
  /// **'MJ — sans personnage'**
  String get groupJoinScreenGameMasterRoleLabel;

  /// Sous-titre du rôle "MJ sans personnage", affiché par `_GmOptionRow` et `_RoleSelectorTile`.
  ///
  /// In fr, this message translates to:
  /// **'Suit le groupe sans fiche de personnage.'**
  String get groupJoinScreenGameMasterRoleSubtitle;

  /// Texte partagé par `_RoleSelectorTile` (liste résolue vide, aucune sélection) et `_NoCharacterNote` (sheet, sous la ligne MJ).
  ///
  /// In fr, this message translates to:
  /// **'Tu n\'as pas encore de personnage à rattacher.'**
  String get groupJoinScreenNoCharacterMessage;

  /// Texte de `_RoleSelectorTile` tant que rien n'est encore résolu (ni personnage, ni liste vide confirmée).
  ///
  /// In fr, this message translates to:
  /// **'Choisir un personnage ou un rôle'**
  String get groupJoinScreenRoleSelectorPlaceholder;

  /// `TextButton` "Réessayer" de `_CharacterTileError`.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get groupJoinScreenCharactersRetryButtonLabel;

  /// Texte de `_JoinSavingOverlay`, affiché pendant `previewGroupInvite` ET `joinGroup`.
  ///
  /// In fr, this message translates to:
  /// **'Rattachement au groupe...'**
  String get groupJoinScreenJoiningOverlayMessage;

  /// `SecondaryButton` "Annuler" de `showGroupConfirmationDialog` — le titre/message/libellé de confirmation restent fournis par l'appelant (hors périmètre de ce lot, voir `group_screen.dart`/`group_settings_screen.dart`/`group_character_reassignment_screen.dart`).
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get groupConfirmationDialogCancelButtonLabel;

  /// `Semantics.label` de la pastille de code d'invitation copiable.
  ///
  /// In fr, this message translates to:
  /// **'Copier le code d\'invitation {code}'**
  String groupInviteCodeChipSemanticLabel(String code);

  /// `SnackBar` de confirmation après la copie du code d'invitation.
  ///
  /// In fr, this message translates to:
  /// **'Code {code} copié.'**
  String groupInviteCodeChipCopiedSnackbar(String code);

  /// Libellé de l'onglet `GroupTab.members` de `group_screen.dart` (`SegmentedTabBar`, mis en majuscules à l'affichage par ce composant).
  ///
  /// In fr, this message translates to:
  /// **'Membres'**
  String get groupTabMembersLabel;

  /// Libellé de l'onglet `GroupTab.treasure`.
  ///
  /// In fr, this message translates to:
  /// **'Butin'**
  String get groupTabTreasureLabel;

  /// Libellé de l'onglet `GroupTab.notes` (ajouté le 16/09/2026, hors cahier des charges).
  ///
  /// In fr, this message translates to:
  /// **'Notes'**
  String get groupTabNotesLabel;

  /// Titre de repli du `WoodBackHeader` de `group_screen.dart` tant que `groupDetailProvider` n'a pas résolu de nom de groupe.
  ///
  /// In fr, this message translates to:
  /// **'GROUPE'**
  String get groupScreenDefaultTitle;

  /// Titre de `showGroupConfirmationDialog` déclenché par l'icône déconnexion du header (membre, pas fondateur).
  ///
  /// In fr, this message translates to:
  /// **'Quitter « {name} » ?'**
  String groupScreenLeaveConfirmTitle(String name);

  /// Message de `showGroupConfirmationDialog` pour quitter le groupe, partagé par l'icône du header et le lien en pied de l'onglet Membres.
  ///
  /// In fr, this message translates to:
  /// **'Tu perds l\'accès au butin commun et au suivi de tes coéquipiers. Ton personnage garde toutes ses données.'**
  String get groupScreenLeaveConfirmMessage;

  /// `confirmLabel` du dialogue de confirmation pour quitter le groupe.
  ///
  /// In fr, this message translates to:
  /// **'Quitter'**
  String get groupScreenLeaveConfirmButtonLabel;

  /// `SnackBar` affiché après `leaveGroup` réussi, juste avant de naviguer vers `/`.
  ///
  /// In fr, this message translates to:
  /// **'Tu as quitté le groupe.'**
  String get groupScreenLeftGroupSnackbar;

  /// `SnackBar` de repli quand `leaveGroup` échoue avec une erreur qui n'est pas une `GroupFailure`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de quitter le groupe. Réessayez.'**
  String get groupScreenLeaveGroupGenericErrorMessage;

  /// Titre de `showGroupConfirmationDialog` déclenché par le bouton exclure (owner uniquement) d'une ligne de l'onglet Membres.
  ///
  /// In fr, this message translates to:
  /// **'Exclure {name} du groupe ?'**
  String groupScreenRemoveMemberConfirmTitle(String name);

  /// `confirmLabel` du dialogue de confirmation d'exclusion.
  ///
  /// In fr, this message translates to:
  /// **'Exclure'**
  String get groupScreenRemoveMemberConfirmButtonLabel;

  /// Message de confirmation d'exclusion pour un MJ volontaire sans personnage (`GroupMember.isGameMaster`) — voir `_GroupScreenState._removeMemberMessage`.
  ///
  /// In fr, this message translates to:
  /// **'Il/elle quitte immédiatement le groupe.'**
  String get groupScreenRemoveMemberGameMasterMessage;

  /// Message de confirmation d'exclusion pour un membre orphelin (`GroupMember.isAwaitingCharacter`, personnage supprimé entre-temps) — jamais confondu avec le MJ volontaire malgré `characterId == null` dans les deux cas.
  ///
  /// In fr, this message translates to:
  /// **'Son personnage a déjà été supprimé ; il/elle quitte immédiatement le groupe.'**
  String get groupScreenRemoveMemberOrphanMessage;

  /// Message de confirmation d'exclusion pour un membre avec personnage (cas par défaut).
  ///
  /// In fr, this message translates to:
  /// **'Son personnage garde toutes ses données, mais quitte immédiatement le groupe.'**
  String get groupScreenRemoveMemberDefaultMessage;

  /// `SnackBar` affiché après `removeMember` réussi.
  ///
  /// In fr, this message translates to:
  /// **'{name} a été exclu du groupe.'**
  String groupScreenMemberRemovedSnackbar(String name);

  /// `SnackBar` de repli quand `removeMember` échoue avec une erreur qui n'est pas une `GroupFailure`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'exclure ce membre. Réessayez.'**
  String get groupScreenRemoveMemberGenericErrorMessage;

  /// `SnackBar` affiché après un succès total de `_claimCurrency` (toutes les dénominations saisies récupérées).
  ///
  /// In fr, this message translates to:
  /// **'Monnaie récupérée.'**
  String get groupScreenCurrencyClaimedSnackbar;

  /// `SnackBar` affiché quand `_claimCurrency` échoue sur TOUTES les dénominations saisies (conflit, un autre membre a déjà modifié le butin).
  ///
  /// In fr, this message translates to:
  /// **'Un autre membre vient de modifier le butin. Réessaie.'**
  String get groupScreenTreasureConflictAllFailedSnackbar;

  /// `SnackBar` récapitulatif pour un échec PARTIEL de `_claimCurrency` (certaines dénominations acceptées, d'autres refusées) — `{labels}` est la liste des unités refusées (`CurrencyKind.unitLabel`, non traduites : "PO"/"PA"/etc., abréviations de jeu).
  ///
  /// In fr, this message translates to:
  /// **'Butin modifié entretemps : {labels} non récupérées, le reste a été ajouté à ton inventaire.'**
  String groupScreenTreasureConflictPartialSnackbar(String labels);

  /// `SnackBar` affiché après `claimTreasureItem` réussi.
  ///
  /// In fr, this message translates to:
  /// **'Objet ajouté à ton inventaire.'**
  String get groupScreenItemClaimedSnackbar;

  /// `SnackBar` de repli quand `claimTreasureItem` échoue avec une erreur qui n'est pas une `GroupFailure`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de réclamer cet objet. Réessayez.'**
  String get groupScreenClaimItemGenericErrorMessage;

  /// `SnackBar` affiché après `addToTreasure` réussi.
  ///
  /// In fr, this message translates to:
  /// **'Butin mis à jour.'**
  String get groupScreenTreasureUpdatedSnackbar;

  /// `SnackBar` de repli quand `addToTreasure` échoue avec une erreur qui n'est pas une `GroupFailure`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de mettre à jour le butin. Réessayez.'**
  String get groupScreenUpdateTreasureGenericErrorMessage;

  /// `SnackBar` affiché après `saveGroupNote` réussi.
  ///
  /// In fr, this message translates to:
  /// **'Notes enregistrées.'**
  String get groupScreenNoteSavedSnackbar;

  /// `SnackBar` de repli quand `saveGroupNote` échoue avec une erreur qui n'est pas une `GroupFailure`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'enregistrer tes notes. Réessayez.'**
  String get groupScreenSaveNoteGenericErrorMessage;

  /// Message de repli de `_ErrorState` quand l'erreur de `groupDetailProvider` n'est pas une `GroupFailure`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger ce groupe. Réessayez.'**
  String get groupScreenLoadErrorMessage;

  /// Message de repli de `_ErrorState` quand l'erreur de `groupTreasureProvider` n'est pas une `GroupFailure`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger le butin commun. Réessayez.'**
  String get groupScreenTreasureLoadErrorMessage;

  /// Message de repli de `_ErrorState` quand l'erreur de `groupNoteProvider` n'est pas une `GroupFailure`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger tes notes. Réessayez.'**
  String get groupScreenNoteLoadErrorMessage;

  /// Texte de `_NoNotesForGameMasterState` (onglet Notes désactivé pour un MJ sans personnage).
  ///
  /// In fr, this message translates to:
  /// **'Le carnet de notes est propre à un personnage : en tant que MJ sans personnage, tu n\'en as pas ici.'**
  String get groupScreenNoNotesForGameMasterMessage;

  /// `SecondaryButton` "Réessayer" de `_ErrorState`, partagé par les 3 onglets (Membres/Butin/Notes).
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get groupScreenRetryButtonLabel;

  /// Titre du `WoodBackHeader` de `group_settings_screen.dart`, déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'PARAMÈTRES DU GROUPE'**
  String get groupSettingsScreenTitle;

  /// Message de repli de `_ErrorState` quand l'erreur de `groupDetailProvider` n'est pas une `GroupFailure`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger ce groupe. Réessayez.'**
  String get groupSettingsScreenLoadErrorMessage;

  /// `SnackBar` affiché après `renameGroup` réussi.
  ///
  /// In fr, this message translates to:
  /// **'Groupe renommé.'**
  String get groupSettingsScreenRenamedSnackbar;

  /// Bandeau d'erreur (`AlertBanner`) affiché quand `renameGroup` échoue avec une erreur qui n'est pas une `GroupFailure`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'enregistrer les modifications. Réessayez.'**
  String get groupSettingsScreenGenericRenameErrorMessage;

  /// Titre de `showGroupConfirmationDialog` déclenché par le bouton "Régénérer".
  ///
  /// In fr, this message translates to:
  /// **'Régénérer le code d\'invitation ?'**
  String get groupSettingsScreenRegenerateConfirmTitle;

  /// Message de `showGroupConfirmationDialog` pour la régénération du code d'invitation.
  ///
  /// In fr, this message translates to:
  /// **'L\'ancien code cessera de fonctionner immédiatement. Les membres déjà présents ne sont pas affectés.'**
  String get groupSettingsScreenRegenerateConfirmMessage;

  /// `confirmLabel` (`PrimaryButton`, `destructive: false`) du dialogue de confirmation de régénération.
  ///
  /// In fr, this message translates to:
  /// **'Régénérer'**
  String get groupSettingsScreenRegenerateConfirmButtonLabel;

  /// `SnackBar` affiché après `regenerateInviteCode` réussi.
  ///
  /// In fr, this message translates to:
  /// **'Code régénéré.'**
  String get groupSettingsScreenRegeneratedSnackbar;

  /// `SnackBar` de repli quand `regenerateInviteCode` échoue avec une erreur qui n'est pas une `GroupFailure`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de régénérer le code. Réessayez.'**
  String get groupSettingsScreenRegenerateGenericErrorMessage;

  /// `_SectionLabel` au-dessus du `TextFormField` du nom du groupe.
  ///
  /// In fr, this message translates to:
  /// **'Nom du groupe'**
  String get groupSettingsScreenNameLabel;

  /// `hintText` du `TextFormField` du nom du groupe.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Les Lames de l\'Aube'**
  String get groupSettingsScreenNameHint;

  /// Libellé de section au-dessus de `GroupInviteCodeChip`, déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'CODE D\'INVITATION'**
  String get groupSettingsScreenInviteCodeSectionLabel;

  /// `SecondaryButton` "Régénérer" à côté de `GroupInviteCodeChip` (ouvre le dialogue de confirmation, voir `groupSettingsScreenRegenerateConfirmButtonLabel`).
  ///
  /// In fr, this message translates to:
  /// **'Régénérer'**
  String get groupSettingsScreenRegenerateButtonLabel;

  /// Sous-texte sous la ligne code d'invitation/bouton Régénérer.
  ///
  /// In fr, this message translates to:
  /// **'Régénérer invalide l\'ancien code : les membres déjà rattachés ne sont pas affectés.'**
  String get groupSettingsScreenRegenerateHint;

  /// Libellé de section au-dessus du bouton "Dissoudre le groupe", déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'ZONE DANGEREUSE'**
  String get groupSettingsScreenDangerZoneLabel;

  /// `DestructiveButton` qui ouvre `showGroupDissolveSheet`.
  ///
  /// In fr, this message translates to:
  /// **'Dissoudre le groupe'**
  String get groupSettingsScreenDissolveButtonLabel;

  /// Sous-texte sous le bouton "Dissoudre le groupe".
  ///
  /// In fr, this message translates to:
  /// **'Réservé au créateur du groupe. Retire tous les membres et supprime le butin commun ; les personnages et leurs données restent intacts.'**
  String get groupSettingsScreenDissolveHint;

  /// `PrimaryButton` fixé en pied d'écran, soumet `renameGroup`.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get groupSettingsScreenSaveButtonLabel;

  /// `SecondaryButton` "Réessayer" de `_ErrorState`.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get groupSettingsScreenRetryButtonLabel;

  /// `SheetHeaderBar.title` de `group_dissolve_sheet.dart`, déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'DISSOUDRE LE GROUPE'**
  String get groupDissolveSheetTitle;

  /// `AlertBanner` de l'étape `_DissolveStep.warning`.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est irréversible. Elle supprimera définitivement le groupe, son butin commun et l\'accès de tous ses membres — leurs personnages gardent toutes leurs données.\n\nCette action ne peut pas être annulée.'**
  String get groupDissolveSheetWarningMessage;

  /// `AlertBanner` d'erreur de l'étape `_DissolveStep.confirm` quand `dissolveGroup` échoue.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de dissoudre le groupe. Réessayez.'**
  String get groupDissolveSheetGenericErrorMessage;

  /// `SnackBar` affiché après `dissolveGroup` réussi, juste avant de naviguer vers `/`.
  ///
  /// In fr, this message translates to:
  /// **'Groupe dissous.'**
  String get groupDissolveSheetDissolvedSnackbar;

  /// `SecondaryButton` "Annuler" partagé par les 2 étapes (`warning`/`confirm`) de la sheet.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get groupDissolveSheetCancelButtonLabel;

  /// `DestructiveButton` de l'étape `_DissolveStep.warning`, passe à l'étape de confirmation.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get groupDissolveSheetContinueButtonLabel;

  /// `DestructiveButton` de l'étape `_DissolveStep.confirm` quand `!_isDissolving` (voir `groupDissolveSheetConfirmInProgressLabel` sinon).
  ///
  /// In fr, this message translates to:
  /// **'Dissoudre définitivement'**
  String get groupDissolveSheetConfirmButtonLabel;

  /// Libellé du même `DestructiveButton` pendant l'appel réseau (`_isDissolving`).
  ///
  /// In fr, this message translates to:
  /// **'Dissolution en cours…'**
  String get groupDissolveSheetConfirmInProgressLabel;

  /// Libellé au-dessus du `TextFormField` de retape du nom, déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'RETAPE LE NOM DU GROUPE POUR CONFIRMER'**
  String get groupDissolveSheetConfirmInstructionLabel;

  /// `hintText` du `TextFormField` de retape du nom.
  ///
  /// In fr, this message translates to:
  /// **'Nom du groupe'**
  String get groupDissolveSheetNameFieldHint;

  /// Titre du `WoodBackHeader` de `group_character_reassignment_screen.dart`, déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'CHOISIR UN NOUVEAU PERSONNAGE'**
  String get groupCharacterReassignmentScreenTitle;

  /// Titre de `showGroupConfirmationDialog` déclenché par "Quitter le groupe" (état vide, aucun personnage à rattacher).
  ///
  /// In fr, this message translates to:
  /// **'Quitter ce groupe ?'**
  String get groupCharacterReassignmentScreenLeaveConfirmTitle;

  /// Message de `showGroupConfirmationDialog` pour quitter le groupe depuis cet écran.
  ///
  /// In fr, this message translates to:
  /// **'Tu perds l\'accès au butin commun et au suivi de tes coéquipiers.'**
  String get groupCharacterReassignmentScreenLeaveConfirmMessage;

  /// `confirmLabel` du dialogue de confirmation pour quitter le groupe depuis cet écran.
  ///
  /// In fr, this message translates to:
  /// **'Quitter'**
  String get groupCharacterReassignmentScreenLeaveConfirmButtonLabel;

  /// Bandeau (`AlertBanner`, `_bannerMessage`) de repli quand `leaveGroup` échoue avec une erreur qui n'est pas une `GroupFailure`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de quitter le groupe. Réessayez.'**
  String get groupCharacterReassignmentScreenLeaveGenericErrorMessage;

  /// Bandeau de repli quand `setGroupCharacter` échoue avec une erreur inattendue (pas une `GroupCharacterReassignmentFailure` reconnue), ET résolution de `GroupCharacterReassignmentFailureKind.generic`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de mettre à jour le groupe. Réessayez.'**
  String get groupCharacterReassignmentScreenGenericErrorMessage;

  /// Bandeau pour `GroupCharacterReassignmentFailureKind.characterNotOwned`.
  ///
  /// In fr, this message translates to:
  /// **'Ce personnage ne t\'appartient pas.'**
  String get groupCharacterReassignmentScreenCharacterNotOwnedMessage;

  /// Bandeau pour `GroupCharacterReassignmentFailureKind.notMember`.
  ///
  /// In fr, this message translates to:
  /// **'Tu n\'es plus membre de ce groupe.'**
  String get groupCharacterReassignmentScreenNotMemberMessage;

  /// Bandeau pour `GroupCharacterReassignmentFailureKind.notEligible`.
  ///
  /// In fr, this message translates to:
  /// **'Cette action ne te concerne plus.'**
  String get groupCharacterReassignmentScreenNotEligibleMessage;

  /// Bandeau pour `GroupCharacterReassignmentFailureKind.alreadyInGroup`.
  ///
  /// In fr, this message translates to:
  /// **'Ce personnage est déjà membre de ce groupe.'**
  String get groupCharacterReassignmentScreenAlreadyInGroupMessage;

  /// Texte d'intro affiché en tête du corps scrollable.
  ///
  /// In fr, this message translates to:
  /// **'Ton précédent personnage a été supprimé. Choisis celui qui te représentera désormais dans ce groupe.'**
  String get groupCharacterReassignmentScreenIntro;

  /// `_SectionLabel` au-dessus de la liste de personnages sélectionnables.
  ///
  /// In fr, this message translates to:
  /// **'Qui te représente dans ce groupe ?'**
  String get groupCharacterReassignmentScreenRoleQuestionLabel;

  /// `PrimaryButton` fixé en pied d'écran, soumet `setGroupCharacter`.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get groupCharacterReassignmentScreenConfirmButtonLabel;

  /// `SecondaryButton` affiché dans l'état vide (aucun personnage), lance l'assistant de création.
  ///
  /// In fr, this message translates to:
  /// **'Créer un personnage'**
  String get groupCharacterReassignmentScreenCreateCharacterButtonLabel;

  /// `DestructiveButton` affiché dans l'état vide (aucun personnage).
  ///
  /// In fr, this message translates to:
  /// **'Quitter le groupe'**
  String get groupCharacterReassignmentScreenLeaveGroupButtonLabel;

  /// Message de repli de `_CharacterSectionError` quand l'erreur de `charactersProvider` n'est pas une `CharacterFailure`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger vos personnages. Réessayez.'**
  String get groupCharacterReassignmentScreenCharactersLoadErrorMessage;

  /// Note de `_NoCharacterNote`, affichée dans l'état vide (aucun personnage).
  ///
  /// In fr, this message translates to:
  /// **'Tu n\'as pas encore de personnage à rattacher.'**
  String get groupCharacterReassignmentScreenNoCharacterNote;

  /// `TextButton` "Réessayer" de `_CharacterSectionError`.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get groupCharacterReassignmentScreenRetryButtonLabel;

  /// Texte de `_ReassignmentSavingOverlay`, affiché pendant `setGroupCharacter`.
  ///
  /// In fr, this message translates to:
  /// **'Mise à jour du groupe...'**
  String get groupCharacterReassignmentScreenSavingOverlayMessage;

  /// `InfoBanner` affiché quand le joueur est seul dans le groupe (`showBanner`), au-dessus du `GroupInviteCodeChip`.
  ///
  /// In fr, this message translates to:
  /// **'Partage ce code pour inviter d\'autres joueurs (touche-le pour le copier) :'**
  String get groupMembersTabBodyShareCodeBannerMessage;

  /// `_LiveUpdateIndicator`, en tête de liste — rend visible la mise à jour Realtime silencieuse de cet onglet.
  ///
  /// In fr, this message translates to:
  /// **'Mis à jour en direct'**
  String get groupMembersTabBodyLiveUpdateLabel;

  /// `tooltip` du bouton `_RemoveMemberButton` (icône `person_remove_outlined`) — `memberName` est le nom du membre, dynamique.
  ///
  /// In fr, this message translates to:
  /// **'Exclure {memberName}'**
  String groupMembersTabBodyRemoveMemberTooltip(String memberName);

  /// Préfixe du `TextSpan` "MJ - {nom}" de la carte MJ volontaire (`_MemberCard._buildGameMasterCard`) — le nom qui suit reste dynamique.
  ///
  /// In fr, this message translates to:
  /// **'MJ - '**
  String get groupMembersTabBodyGameMasterPrefix;

  /// Suffixe affiché après le nom du joueur connecté sur sa propre carte (personnage, MJ volontaire ou orpheline) — 3 points d'appel identiques dans `_MemberCard`.
  ///
  /// In fr, this message translates to:
  /// **' (toi)'**
  String get groupMembersTabBodySelfSuffix;

  /// Texte neutre affiché à la place de la ligne PV sur la carte MJ volontaire — ne JAMAIS afficher une valeur factice (0/0 serait lu comme "en train de mourir").
  ///
  /// In fr, this message translates to:
  /// **'Ne suit pas ses PV ici.'**
  String get groupMembersTabBodyGameMasterHpNote;

  /// Nom de repli du membre orphelin (`GroupMember.isAwaitingCharacter`, voir les fixtures de test) ET texte d'état affiché à la place de la ligne PV sur sa carte (`_MemberCard._buildAwaitingCharacterCard`).
  ///
  /// In fr, this message translates to:
  /// **'En attente d\'un personnage'**
  String get groupMembersTabBodyAwaitingCharacterLabel;

  /// `_StatusBadge` pour `CharacterVitalStatus.dead`, déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'MORT'**
  String get groupMembersTabBodyDeadStatusLabel;

  /// `_StatusBadge` pour `CharacterVitalStatus.unconscious`, déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'INCONSCIENT'**
  String get groupMembersTabBodyUnconsciousStatusLabel;

  /// `_ArmorClassLine` — "CA {valeur}", avec ou sans suffixe signé du bonus manuel (ajouté séparément par l'appelant).
  ///
  /// In fr, this message translates to:
  /// **'CA {armorClass}'**
  String groupMembersTabBodyArmorClassLabel(int armorClass);

  /// `_TemporaryHpChip` — même texte que `characterVitalsCardTemporaryHpChip`, dupliqué volontairement (pas de dépendance entre ces deux widgets).
  ///
  /// In fr, this message translates to:
  /// **'+{amount} PV temp.'**
  String groupMembersTabBodyTemporaryHpChipLabel(int amount);

  /// `_PrivacyExplanation`, en pied de liste — rappelle ce que la RLS de groupe autorise déjà à lire côté serveur.
  ///
  /// In fr, this message translates to:
  /// **'Touche un membre pour voir sa fiche complète, en lecture seule. Personne ne peut modifier le personnage d\'un autre.'**
  String get groupMembersTabBodyPrivacyExplanation;

  /// `_LeaveGroupLinkLabel`, affiché en pied d'onglet pour les membres non-fondateurs uniquement.
  ///
  /// In fr, this message translates to:
  /// **'Quitter le groupe'**
  String get groupMembersTabBodyLeaveGroupLinkLabel;

  /// `InfoBanner` affiché quand `canClaim` est faux (MJ sans personnage, voir `group_screen.dart::_buildTreasureTab`).
  ///
  /// In fr, this message translates to:
  /// **'En tant que MJ sans personnage, tu peux gérer le butin commun mais pas t\'attribuer une part — seuls les membres avec un personnage le peuvent.'**
  String get groupTreasureTabBodyGameMasterBannerMessage;

  /// `_SectionLabel`, déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'MONNAIE COMMUNE'**
  String get groupTreasureTabBodyCurrencySectionLabel;

  /// `_SectionLabel`, déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'OBJETS EN ATTENTE'**
  String get groupTreasureTabBodyPendingItemsSectionLabel;

  /// `DashedButton` qui ouvre `claim_group_treasure_currency_sheet.dart` — `PrimaryButton`/`SecondaryButton`/`DashedButton` mettent déjà leur libellé en majuscules à l'affichage, ce texte reste en casse normale.
  ///
  /// In fr, this message translates to:
  /// **'Répartir vers mon inventaire'**
  String get groupTreasureTabBodyClaimCurrencyButtonLabel;

  /// `SecondaryButton` qui ouvre `add_to_group_treasure_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter au butin du groupe'**
  String get groupTreasureTabBodyAddToTreasureButtonLabel;

  /// Sous-titre de `_TreasureItemRow` — `item.displayName` (ligne 1, dynamique) reste séparé de cette quantité (ligne 2).
  ///
  /// In fr, this message translates to:
  /// **'× {quantity}'**
  String groupTreasureTabBodyItemQuantityLabel(int quantity);

  /// Lien texte de `_TreasureItemRow`, ouvre `claim_group_treasure_item_sheet.dart`.
  ///
  /// In fr, this message translates to:
  /// **'S\'attribuer'**
  String get groupTreasureTabBodyClaimItemLinkLabel;

  /// `_EmptyTreasureItemsState`, affiché quand `treasure.items` est vide.
  ///
  /// In fr, this message translates to:
  /// **'Aucun objet en attente.'**
  String get groupTreasureTabBodyEmptyItemsMessage;

  /// `hintText` du `TextField` principal de l'onglet Notes.
  ///
  /// In fr, this message translates to:
  /// **'Prends tes notes pendant la partie : événements, indices, rebondissements…'**
  String get groupNotesTabBodyHintText;

  /// `PrimaryButton` "Enregistrer", actif seulement si le texte a changé (`_isDirty`).
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get groupNotesTabBodySaveButtonLabel;

  /// Transmis à `onDictationError` quand `SpeechToText.initialize` échoue (appareil ou permission).
  ///
  /// In fr, this message translates to:
  /// **'Reconnaissance vocale indisponible sur cet appareil ou accès micro refusé.'**
  String get groupNotesTabBodyDictationUnavailableMessage;

  /// Transmis à `onDictationError` sur `SpeechRecognitionError` — `errorMsg` vient du moteur système (`speech_to_text`), jamais traduit (texte déjà fourni par la plateforme, pas une chaîne du dépôt).
  ///
  /// In fr, this message translates to:
  /// **'Erreur de reconnaissance vocale : {errorMsg}'**
  String groupNotesTabBodyDictationErrorMessage(String errorMsg);

  /// Titre de `SheetHeaderBar`, déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'AJOUTER AU BUTIN DU GROUPE'**
  String get addToGroupTreasureSheetTitle;

  /// Même libellé que `addRewardSheetCurrencyLabel`, dupliqué volontairement (sheet distincte).
  ///
  /// In fr, this message translates to:
  /// **'MONNAIE'**
  String get addToGroupTreasureSheetCurrencySectionLabel;

  /// Même libellé que `addRewardSheetItemsLabel`, dupliqué volontairement (sheet distincte).
  ///
  /// In fr, this message translates to:
  /// **'OBJETS'**
  String get addToGroupTreasureSheetItemsSectionLabel;

  /// `DashedAddTile` — au pluriel, contrairement à `addRewardSheetAddItemLabel` ("Ajouter un objet") : `pickInventoryAdditions` permet une sélection multiple ici.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter des objets'**
  String get addToGroupTreasureSheetAddItemsButtonLabel;

  /// `SecondaryButton` "Annuler", ferme la sheet sans appliquer.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get addToGroupTreasureSheetCancelButtonLabel;

  /// `PrimaryButton`, actif seulement si `_canApply` (au moins une monnaie ou un objet saisi).
  ///
  /// In fr, this message translates to:
  /// **'Ajouter au butin'**
  String get addToGroupTreasureSheetApplyButtonLabel;

  /// `_TreasureDraftItemRow` — même format que `addRewardSheetItemQuantityLabel` (`name` déjà résolu, catalogue ou objet personnalisé).
  ///
  /// In fr, this message translates to:
  /// **'{name} × {quantity}'**
  String addToGroupTreasureSheetItemQuantityLabel(String name, int quantity);

  /// Titre de `SheetHeaderBar`, déjà en majuscules.
  ///
  /// In fr, this message translates to:
  /// **'S\'ATTRIBUER DE LA MONNAIE'**
  String get claimGroupTreasureCurrencySheetTitle;

  /// `SecondaryButton` "Annuler", ferme la sheet sans appliquer.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get claimGroupTreasureCurrencySheetCancelButtonLabel;

  /// `PrimaryButton`, actif seulement si `_canApply` (au moins un montant saisi).
  ///
  /// In fr, this message translates to:
  /// **'S\'attribuer'**
  String get claimGroupTreasureCurrencySheetApplyButtonLabel;

  /// `_ClaimCurrencyField` — solde maximum disponible dans le butin, affiché sous le champ.
  ///
  /// In fr, this message translates to:
  /// **'/ {max}'**
  String claimGroupTreasureCurrencySheetMaxLabel(int max);

  /// Titre de la sheet légère — `itemName` est `GroupTreasureItem.displayName`, dynamique.
  ///
  /// In fr, this message translates to:
  /// **'Réclamer {itemName}'**
  String claimGroupTreasureItemSheetTitle(String itemName);

  /// Sous-titre "{quantité} disponible(s)" — ancien texte en dur toujours au pluriel ("1 disponible(s)"), corrigé en ICU plural par cette migration.
  ///
  /// In fr, this message translates to:
  /// **'{quantity, plural, =1{1 disponible} other{{quantity} disponibles}}'**
  String claimGroupTreasureItemSheetAvailableLabel(int quantity);

  /// `PrimaryButton`, actif seulement si la quantité choisie est non nulle.
  ///
  /// In fr, this message translates to:
  /// **'Réclamer'**
  String get claimGroupTreasureItemSheetSubmitButtonLabel;

  /// Titre du bandeau bois, états "Chargement"/"Vérification"/"Erreur réseau" (`_Header`).
  ///
  /// In fr, this message translates to:
  /// **'VÉRIFICATION IMPORT'**
  String get xmlImportReviewScreenHeaderTitle;

  /// Sous-titre du bandeau bois, états "Vérification"/"Erreur réseau" — `fileName` est le nom du fichier importé (dynamique).
  ///
  /// In fr, this message translates to:
  /// **'{fileName} importé depuis aidedd.org'**
  String xmlImportReviewScreenHeaderSubtitle(String fileName);

  /// Sous-titre du bandeau bois pendant le chargement des catalogues.
  ///
  /// In fr, this message translates to:
  /// **'Analyse de {fileName} en cours...'**
  String xmlImportReviewScreenLoadingSubtitle(String fileName);

  /// Titre du bandeau bois, état "Erreur (XML invalide)" — pas de sous-titre pour cet état, voir `_InvalidFileErrorState`.
  ///
  /// In fr, this message translates to:
  /// **'IMPORT XML'**
  String get xmlImportReviewScreenInvalidFileHeaderTitle;

  /// Message de repli de `_NetworkErrorState` quand l'erreur n'est pas une `CharacterCreationFailure` (celle-ci garde son propre `.message`, voir D161/`docs/dette-technique.md`).
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les données de référence. Réessayez.'**
  String get xmlImportReviewScreenNetworkErrorMessage;

  /// Texte de statut positif affiché quand aucun champ ne nécessite de correction manuelle.
  ///
  /// In fr, this message translates to:
  /// **'Tous les champs ont été reconnus automatiquement.'**
  String get xmlImportReviewScreenAllFieldsResolvedMessage;

  /// Texte de statut négatif, nombre de champs encore non résolus.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 champ nécessite une correction manuelle avant validation} other{{count} champs nécessitent une correction manuelle avant validation}}'**
  String xmlImportReviewScreenUnresolvedFieldsCountMessage(int count);

  /// `PrimaryButton` de bas d'écran.
  ///
  /// In fr, this message translates to:
  /// **'Valider le personnage'**
  String get xmlImportReviewScreenValidateButtonLabel;

  /// Segment de `xmlImportReviewScreenMissingFieldsErrorMessage` quand la race bloque la validation.
  ///
  /// In fr, this message translates to:
  /// **'la race'**
  String get xmlImportReviewScreenMissingRaceField;

  /// Segment de `xmlImportReviewScreenMissingFieldsErrorMessage` quand la classe bloque la validation.
  ///
  /// In fr, this message translates to:
  /// **'la classe'**
  String get xmlImportReviewScreenMissingClassField;

  /// Segment de `xmlImportReviewScreenMissingFieldsErrorMessage` quand les bonus raciaux au choix ne sont pas complets.
  ///
  /// In fr, this message translates to:
  /// **'les bonus raciaux au choix'**
  String get xmlImportReviewScreenMissingRacialChoicesField;

  /// Mot de liaison entre les segments de `xmlImportReviewScreenMissingFieldsErrorMessage` (jusqu'à 3 segments, chacun joint par ce mot — pas une virgule d'Oxford, comportement inchangé par rapport à l'ancien texte en dur).
  ///
  /// In fr, this message translates to:
  /// **'et'**
  String get xmlImportReviewScreenFieldConjunction;

  /// Message bloquant (réutilise `AlertBanner`) quand race/classe/bonus raciaux au choix ne sont pas résolus — `missingFields` est la jointure déjà construite des segments ci-dessus.
  ///
  /// In fr, this message translates to:
  /// **'Corrigez d\'abord {missingFields} avant d\'enregistrer ce personnage.'**
  String xmlImportReviewScreenMissingFieldsErrorMessage(String missingFields);

  /// Titre du dialogue de confirmation ouvert quand au moins un champ reste non résolu.
  ///
  /// In fr, this message translates to:
  /// **'CHAMPS NON RÉSOLUS'**
  String get xmlImportReviewScreenUnresolvedDialogTitle;

  /// Corps du dialogue "CHAMPS NON RÉSOLUS".
  ///
  /// In fr, this message translates to:
  /// **'Certains éléments importés n\'ont pas pu être reconnus automatiquement. Ils seront enregistrés comme non catalogués et resteront corrigibles plus tard depuis la fiche du personnage.'**
  String get xmlImportReviewScreenUnresolvedDialogMessage;

  /// `SecondaryButton` du dialogue "CHAMPS NON RÉSOLUS", annule la sauvegarde.
  ///
  /// In fr, this message translates to:
  /// **'Retourner corriger'**
  String get xmlImportReviewScreenUnresolvedDialogBackButtonLabel;

  /// `PrimaryButton` du dialogue "CHAMPS NON RÉSOLUS", poursuit la sauvegarde malgré les champs non résolus.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get xmlImportReviewScreenUnresolvedDialogContinueButtonLabel;

  /// Nom du personnage écrit en base quand le champ `<name>` du fichier source est vide.
  ///
  /// In fr, this message translates to:
  /// **'Personnage importé'**
  String get xmlImportReviewScreenDefaultCharacterName;

  /// Message de repli affiché quand l'échec de sauvegarde n'est pas une `CharacterCreationFailure` (celle-ci garde son propre `.message`, voir D161/`docs/dette-technique.md`).
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Réessayez.'**
  String get xmlImportReviewScreenGenericSaveErrorMessage;

  /// Titre de carte — champ "Nom", toujours une carte de résumé (jamais une alerte).
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get xmlImportReviewScreenNameFieldTitle;

  /// Titre de carte — champ "Race", aussi utilisé (en majuscules) comme titre de la bottom sheet de correction.
  ///
  /// In fr, this message translates to:
  /// **'Race'**
  String get xmlImportReviewScreenRaceFieldTitle;

  /// Titre de carte — champ "Classe".
  ///
  /// In fr, this message translates to:
  /// **'Classe'**
  String get xmlImportReviewScreenClassFieldTitle;

  /// Titre de carte — champ "Sous-classe" (`classPath`), affiché seulement si présent dans le fichier source.
  ///
  /// In fr, this message translates to:
  /// **'Sous-classe'**
  String get xmlImportReviewScreenSubclassFieldTitle;

  /// Titre de carte — champ "Niveau", toujours une carte de résumé.
  ///
  /// In fr, this message translates to:
  /// **'Niveau'**
  String get xmlImportReviewScreenLevelFieldTitle;

  /// Titre de carte — champ "Historique".
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get xmlImportReviewScreenBackgroundFieldTitle;

  /// Titre de carte — champ "Caractéristiques", toujours une carte de résumé.
  ///
  /// In fr, this message translates to:
  /// **'Caractéristiques'**
  String get xmlImportReviewScreenAbilityScoresFieldTitle;

  /// Titre de carte — champ "Points de vie", toujours une carte de résumé.
  ///
  /// In fr, this message translates to:
  /// **'Points de vie'**
  String get xmlImportReviewScreenHitPointsFieldTitle;

  /// Titre de carte — champ "Compétences" (4 groupes consolidés).
  ///
  /// In fr, this message translates to:
  /// **'Compétences'**
  String get xmlImportReviewScreenSkillsFieldTitle;

  /// Titre de carte — champ "Outils" (maîtrises d'outils).
  ///
  /// In fr, this message translates to:
  /// **'Outils'**
  String get xmlImportReviewScreenToolsFieldTitle;

  /// Titre de carte — champ "Langues".
  ///
  /// In fr, this message translates to:
  /// **'Langues'**
  String get xmlImportReviewScreenLanguagesFieldTitle;

  /// Titre de carte — champ "Sorts innés".
  ///
  /// In fr, this message translates to:
  /// **'Sorts innés'**
  String get xmlImportReviewScreenInnateSpellsFieldTitle;

  /// Titre de carte — champ "Sorts connus".
  ///
  /// In fr, this message translates to:
  /// **'Sorts connus'**
  String get xmlImportReviewScreenKnownSpellsFieldTitle;

  /// Titre de carte — champ "Argent", toujours une carte de résumé.
  ///
  /// In fr, this message translates to:
  /// **'Argent'**
  String get xmlImportReviewScreenCurrencyFieldTitle;

  /// Titre de carte — champ "Armure" (codé).
  ///
  /// In fr, this message translates to:
  /// **'Armure'**
  String get xmlImportReviewScreenArmorFieldTitle;

  /// Titre de carte — champ "Bouclier" (codé).
  ///
  /// In fr, this message translates to:
  /// **'Bouclier'**
  String get xmlImportReviewScreenShieldFieldTitle;

  /// Titre de carte — champ "Armes" (quantifié).
  ///
  /// In fr, this message translates to:
  /// **'Armes'**
  String get xmlImportReviewScreenWeaponsFieldTitle;

  /// Titre de carte — champ "Outils physiques" (quantifié, matériel d'outillage, distinct des maîtrises d'outils).
  ///
  /// In fr, this message translates to:
  /// **'Outils physiques'**
  String get xmlImportReviewScreenToolEquipmentFieldTitle;

  /// Titre de carte — champ "Objets" (quantifié).
  ///
  /// In fr, this message translates to:
  /// **'Objets'**
  String get xmlImportReviewScreenItemsFieldTitle;

  /// Titre de carte — objets personnalisés (`itemX`), toujours `custom`, jamais une alerte.
  ///
  /// In fr, this message translates to:
  /// **'Objets personnalisés'**
  String get xmlImportReviewScreenCustomItemsFieldTitle;

  /// Badge discret de la carte "Objets personnalisés".
  ///
  /// In fr, this message translates to:
  /// **'Personnalisé'**
  String get xmlImportReviewScreenCustomItemsBadgeLabel;

  /// Titre de carte — champ "Paquetage de départ" (`pack`), traçabilité uniquement, toujours une carte de résumé.
  ///
  /// In fr, this message translates to:
  /// **'Paquetage de départ'**
  String get xmlImportReviewScreenStartingPackFieldTitle;

  /// Valeur affichée dans la carte de résumé "Paquetage de départ" quand le jeton `pack` du fichier source ne correspond à aucune entrée de `AideddReferenceTables.packs` — toujours une carte lecture seule, jamais une alerte, `rawValue` est le jeton brut (dynamique).
  ///
  /// In fr, this message translates to:
  /// **'Non reconnu (traçabilité uniquement) : {rawValue}'**
  String xmlImportReviewScreenStartingPackUnrecognizedLabel(String rawValue);

  /// Titre de carte — champ "Alignement" (codé).
  ///
  /// In fr, this message translates to:
  /// **'Alignement'**
  String get xmlImportReviewScreenAlignmentFieldTitle;

  /// Titre de carte — champ "Sexe" (codé).
  ///
  /// In fr, this message translates to:
  /// **'Sexe'**
  String get xmlImportReviewScreenSexFieldTitle;

  /// Titre de carte — champ "Apparence", toujours une carte de résumé ("Renseignée"/"Non renseignée").
  ///
  /// In fr, this message translates to:
  /// **'Apparence'**
  String get xmlImportReviewScreenAppearanceFieldTitle;

  /// Titre de carte — champ "Histoire", toujours une carte de résumé ("Renseignée"/"Non renseignée").
  ///
  /// In fr, this message translates to:
  /// **'Histoire'**
  String get xmlImportReviewScreenHistoryFieldTitle;

  /// Titre de carte — champ "Expérience", affiché seulement si `<xp>` est présent dans le fichier source.
  ///
  /// In fr, this message translates to:
  /// **'Expérience'**
  String get xmlImportReviewScreenExperienceFieldTitle;

  /// Valeur affichée par la carte "Nom" quand `<name>` est vide (affichage seulement — `xmlImportReviewScreenDefaultCharacterName` régit le nom réellement enregistré).
  ///
  /// In fr, this message translates to:
  /// **'Sans nom'**
  String get xmlImportReviewScreenNoNameValue;

  /// Valeur des cartes "Apparence"/"Histoire" quand au moins un champ libre correspondant est non vide.
  ///
  /// In fr, this message translates to:
  /// **'Renseignée'**
  String get xmlImportReviewScreenFilledValueLabel;

  /// Valeur des cartes "Apparence"/"Histoire" quand tous les champs libres correspondants sont vides.
  ///
  /// In fr, this message translates to:
  /// **'Non renseignée'**
  String get xmlImportReviewScreenNotFilledValueLabel;

  /// Badge discret affiché sur une carte de résumé dont la valeur reconnue a été créée comme placeholder ("Garder comme élément personnalisé").
  ///
  /// In fr, this message translates to:
  /// **'Donnée incomplète'**
  String get xmlImportReviewScreenIncompleteDataBadgeLabel;

  /// Valeur de la carte "Expérience".
  ///
  /// In fr, this message translates to:
  /// **'{xp} XP'**
  String xmlImportReviewScreenExperienceValue(int xp);

  /// Valeur de la carte "Points de vie".
  ///
  /// In fr, this message translates to:
  /// **'{hp} PV'**
  String xmlImportReviewScreenHitPointsValue(int hp);

  /// Valeur de la carte "Argent" quand les 5 dénominations sont à 0.
  ///
  /// In fr, this message translates to:
  /// **'Aucune'**
  String get xmlImportReviewScreenNoCurrencyValue;

  /// Segment "pièces d'or" de la carte "Argent".
  ///
  /// In fr, this message translates to:
  /// **'{amount} po'**
  String xmlImportReviewScreenGoldAmount(int amount);

  /// Segment "pièces de platine" de la carte "Argent".
  ///
  /// In fr, this message translates to:
  /// **'{amount} pp'**
  String xmlImportReviewScreenPlatinumAmount(int amount);

  /// Segment "pièces d'électrum" de la carte "Argent".
  ///
  /// In fr, this message translates to:
  /// **'{amount} pe'**
  String xmlImportReviewScreenElectrumAmount(int amount);

  /// Segment "pièces d'argent" de la carte "Argent".
  ///
  /// In fr, this message translates to:
  /// **'{amount} pa'**
  String xmlImportReviewScreenSilverAmount(int amount);

  /// Segment "pièces de cuivre" de la carte "Argent".
  ///
  /// In fr, this message translates to:
  /// **'{amount} pc'**
  String xmlImportReviewScreenCopperAmount(int amount);

  /// Message d'une carte d'alerte pour un champ à catalogue unique ou codé non reconnu — `title` est un des titres de champ déjà localisés ci-dessus, `rawValue` est le jeton brut du fichier source (dynamique).
  ///
  /// In fr, this message translates to:
  /// **'{title} non reconnu(e) : \"{rawValue}\"'**
  String xmlImportReviewScreenFieldUnrecognizedMessage(
    String title,
    String rawValue,
  );

  /// Message d'une carte d'alerte consolidée (compétences/outils/langues/armes/outils physiques/objets).
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 élément non catalogué — à corriger manuellement.} other{{count} éléments non catalogués — à corriger manuellement.}}'**
  String xmlImportReviewScreenUncatalogedItemsCountMessage(int count);

  /// Message d'une carte d'alerte consolidée pour les sorts innés/connus.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 sort non catalogué — à corriger manuellement.} other{{count} sorts non catalogués — à corriger manuellement.}}'**
  String xmlImportReviewScreenUncatalogedSpellsCountMessage(int count);

  /// Titre de la bottom sheet de correction (simple ou "mode liste") — `title` est déjà le titre de champ localisé, déjà mis en majuscules par l'appelant.
  ///
  /// In fr, this message translates to:
  /// **'CORRIGER : {title}'**
  String xmlImportReviewScreenCorrectionSheetTitle(String title);

  /// Bouton par ligne de la bottom sheet "mode liste" (champ consolidé).
  ///
  /// In fr, this message translates to:
  /// **'Corriger'**
  String get xmlImportReviewScreenCorrectEntryButtonLabel;

  /// `SecondaryButton` de bas de la bottom sheet "mode liste".
  ///
  /// In fr, this message translates to:
  /// **'Tout garder comme éléments personnalisés'**
  String get xmlImportReviewScreenKeepAllAsCustomButtonLabel;

  /// Texte indicatif du champ de recherche de la bottom sheet de correction simple.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher...'**
  String get xmlImportReviewScreenSearchFieldHint;

  /// Message affiché quand la recherche de la bottom sheet de correction simple ne trouve aucun candidat.
  ///
  /// In fr, this message translates to:
  /// **'Aucune correspondance trouvée.'**
  String get xmlImportReviewScreenNoMatchMessage;

  /// `SecondaryButton` de la bottom sheet de correction simple.
  ///
  /// In fr, this message translates to:
  /// **'Garder comme élément personnalisé'**
  String get xmlImportReviewScreenKeepAsCustomButtonLabel;

  /// `PrimaryButton` de la bottom sheet de correction simple.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get xmlImportReviewScreenConfirmButtonLabel;

  /// `SnackBar` affichée quand "Garder comme élément personnalisé" échoue (réseau, RLS...).
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'enregistrer cet élément. Réessayez.'**
  String get xmlImportReviewScreenPlaceholderSaveErrorMessage;

  /// Message de la carte d'alerte le temps qu'un appel "Garder comme élément personnalisé" soit en vol pour ce champ.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement en cours...'**
  String get xmlImportReviewScreenPlaceholderSavingInProgressMessage;

  /// Texte de `_SavingOverlay`, affiché pendant la sauvegarde finale.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement du personnage...'**
  String get xmlImportReviewScreenSavingOverlayMessage;

  /// Titre de `_InvalidFileErrorState`.
  ///
  /// In fr, this message translates to:
  /// **'Fichier illisible'**
  String get xmlImportReviewScreenInvalidFileTitle;

  /// Sous-titre fixe de `_InvalidFileErrorState`, au-dessus du message détaillé dynamique (`xmlImportReviewScreenParseErrorXxx`).
  ///
  /// In fr, this message translates to:
  /// **'Ce fichier ne semble pas être un export aidedd.org valide.'**
  String get xmlImportReviewScreenInvalidFileSubtitle;

  /// `PrimaryButton` de `_InvalidFileErrorState`.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un autre fichier'**
  String get xmlImportReviewScreenInvalidFilePickAnotherButtonLabel;

  /// Lien texte de `_InvalidFileErrorState`.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get xmlImportReviewScreenInvalidFileCancelButtonLabel;

  /// `SecondaryButton` de `_NetworkErrorState`.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get xmlImportReviewScreenRetryButtonLabel;

  /// Segment de la carte informative neutre (`_buildUnhandledInfoMessage`) quand `styleCombat1`/`styleCombat2` sont présents.
  ///
  /// In fr, this message translates to:
  /// **'Style de combat'**
  String get xmlImportReviewScreenUnhandledStyleCombatFieldLabel;

  /// Segment de la carte informative neutre quand `knownInvocations` est non vide.
  ///
  /// In fr, this message translates to:
  /// **'Invocation connue'**
  String get xmlImportReviewScreenUnhandledKnownInvocationFieldLabel;

  /// Segment de la carte informative neutre quand `favoredEnemy0`/`favoredEnemy6`/`favoredEnemy14` sont présents.
  ///
  /// In fr, this message translates to:
  /// **'Ennemi juré'**
  String get xmlImportReviewScreenUnhandledFavoredEnemyFieldLabel;

  /// Première phrase de la carte informative neutre — `fields` est la jointure (virgule) des segments ci-dessus réellement présents dans le fichier.
  ///
  /// In fr, this message translates to:
  /// **'Non importé automatiquement dans cette version : {fields}.'**
  String xmlImportReviewScreenUnhandledFieldsMessage(String fields);

  /// Seconde phrase (optionnelle) de la carte informative neutre, quand `aug_carac0/1/2` sont présents dans au moins une entrée de niveau.
  ///
  /// In fr, this message translates to:
  /// **'Augmentations de caractéristiques : présentes dans le fichier mais non interprétées automatiquement.'**
  String get xmlImportReviewScreenAbilityIncreasesPresentMessage;

  /// Message détaillé de `_InvalidFileErrorState` pour `XmlImportParseErrorCode.invalidXml`.
  ///
  /// In fr, this message translates to:
  /// **'Ce fichier n\'est pas un XML valide.'**
  String get xmlImportReviewScreenParseErrorInvalidXml;

  /// Message détaillé de `_InvalidFileErrorState` pour `XmlImportParseErrorCode.missingBuilderRoot`.
  ///
  /// In fr, this message translates to:
  /// **'Ce fichier ne semble pas être un export aidedd.org (racine <builder> introuvable).'**
  String get xmlImportReviewScreenParseErrorMissingBuilderRoot;

  /// Message détaillé de `_InvalidFileErrorState` pour `XmlImportParseErrorCode.missingCharacterElement`.
  ///
  /// In fr, this message translates to:
  /// **'Ce fichier ne semble pas être un export aidedd.org (balise <character> introuvable).'**
  String get xmlImportReviewScreenParseErrorMissingCharacterElement;

  /// Message détaillé de `_InvalidFileErrorState` pour `XmlImportParseErrorCode.missingRequiredFields`.
  ///
  /// In fr, this message translates to:
  /// **'Ce fichier ne contient pas les informations minimales d\'un personnage (nom, race, classe, historique).'**
  String get xmlImportReviewScreenParseErrorMissingRequiredFields;

  /// Titre fixe du bandeau bois, affiché par `JoinStepHeader` et `JoinStepMinimalHeader` sur les 3 écrans du flux "Rejoindre une histoire".
  ///
  /// In fr, this message translates to:
  /// **'REJOINDRE'**
  String get joinStepHeaderTitle;

  /// Compteur d'étape du bandeau bois (`JoinStepHeader`) — même patron que `raceStepScreenStepCounter`.
  ///
  /// In fr, this message translates to:
  /// **'Étape {currentStep} / {totalSteps}'**
  String joinStepHeaderStepCounter(int currentStep, int totalSteps);

  /// `stepTitle` transmis à `JoinStepHeader` par l'étape 1/4 (saisie du code).
  ///
  /// In fr, this message translates to:
  /// **'Code'**
  String get joinCodeStepScreenStepTitle;

  /// Titre principal de l'étape 1/4.
  ///
  /// In fr, this message translates to:
  /// **'As-tu un code d\'invitation ?'**
  String get joinCodeStepScreenTitle;

  /// Sous-titre de l'étape 1/4.
  ///
  /// In fr, this message translates to:
  /// **'Ton MJ te l\'a partagé depuis l\'app Histoires pour rejoindre sa campagne.'**
  String get joinCodeStepScreenSubtitle;

  /// Libellé au-dessus du champ de saisie du code.
  ///
  /// In fr, this message translates to:
  /// **'Code d\'invitation'**
  String get joinCodeStepScreenFieldLabel;

  /// `hintText` du champ de saisie du code — exemple illustratif, jamais un vrai code.
  ///
  /// In fr, this message translates to:
  /// **'AB3F7K'**
  String get joinCodeStepScreenFieldHint;

  /// Texte d'aide sous le champ de saisie du code.
  ///
  /// In fr, this message translates to:
  /// **'Code fourni par ton MJ (lettres et chiffres).'**
  String get joinCodeStepScreenFieldHelper;

  /// `PrimaryButton` de l'étape 1/4.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get joinCodeStepScreenNextButton;

  /// `stepTitle` transmis à `JoinStepHeader` par l'étape 2/4 (confirmation).
  ///
  /// In fr, this message translates to:
  /// **'Confirmation'**
  String get joinConfirmationStepScreenStepTitle;

  /// Ligne affichée sous le titre de l'histoire quand `StoryPreview.gmDisplayName` est renseigné — `gmDisplayName` reste dynamique (nom choisi par le MJ, jamais traduit).
  ///
  /// In fr, this message translates to:
  /// **'MJ : {gmDisplayName}'**
  String joinConfirmationStepScreenGmLabel(String gmDisplayName);

  /// Texte d'information sous le nom du MJ, avant le bouton "Rejoindre".
  ///
  /// In fr, this message translates to:
  /// **'En rejoignant, ton personnage sera visible par le MJ (lecture seule). Tu pourras quitter l\'histoire à tout moment depuis sa fiche.'**
  String get joinConfirmationStepScreenDisclaimer;

  /// `PrimaryButton` de l'étape 2/4, pousse l'étape 3/4.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre'**
  String get joinConfirmationStepScreenJoinButton;

  /// Message principal de `_CodeErrorState` pour `StoryInviteFailureKind.invalidCode`.
  ///
  /// In fr, this message translates to:
  /// **'Ce code d\'invitation n\'est pas valide.'**
  String get joinConfirmationStepScreenInvalidCodeMessage;

  /// Message secondaire de `_CodeErrorState` pour `StoryInviteFailureKind.invalidCode`.
  ///
  /// In fr, this message translates to:
  /// **'Vérifie le code transmis par ton MJ et réessaye.'**
  String get joinConfirmationStepScreenInvalidCodeSecondaryMessage;

  /// Message principal de `_CodeErrorState` pour `StoryInviteFailureKind.inviteDisabled`.
  ///
  /// In fr, this message translates to:
  /// **'Cette invitation a été désactivée.'**
  String get joinConfirmationStepScreenInviteDisabledMessage;

  /// Message secondaire de `_CodeErrorState` pour `StoryInviteFailureKind.inviteDisabled`.
  ///
  /// In fr, this message translates to:
  /// **'Demande à ton MJ de générer un nouveau lien.'**
  String get joinConfirmationStepScreenInviteDisabledSecondaryMessage;

  /// `SecondaryButton` de `_CodeErrorState`.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le code'**
  String get joinConfirmationStepScreenEditCodeButton;

  /// Message de `_NetworkErrorState`, pour `StoryInviteFailureKind.characterNotOwned`/`alreadyJoined`/`generic` et toute exception qui n'est pas une `StoryInviteFailure` — même texte que `characters/data/character_error_mapper.dart::_networkErrorMessage`, dupliqué ici (voir la documentation de classe du fichier).
  ///
  /// In fr, this message translates to:
  /// **'Impossible de contacter le serveur. Vérifiez votre connexion internet et réessayez.'**
  String get joinConfirmationStepScreenGenericErrorMessage;

  /// `SecondaryButton` de `_NetworkErrorState`.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get joinConfirmationStepScreenRetryButton;

  /// `stepTitle` transmis à `JoinStepHeader` par l'étape 3/4 (choix du personnage).
  ///
  /// In fr, this message translates to:
  /// **'Choix du personnage'**
  String get joinCharacterStepScreenStepTitle;

  /// `SnackBar` affiché après un rattachement réussi (étape 4/4).
  ///
  /// In fr, this message translates to:
  /// **'Histoire rejointe !'**
  String get joinCharacterStepScreenJoinedSnackbar;

  /// Bandeau d'alerte inline pour `StoryInviteFailureKind.alreadyJoined`.
  ///
  /// In fr, this message translates to:
  /// **'Ce personnage est déjà rattaché à cette histoire.'**
  String get joinCharacterStepScreenAlreadyJoinedErrorMessage;

  /// Bandeau d'alerte inline pour `StoryInviteFailureKind.invalidCode` (cas de course improbable, voir la documentation de `_bannerMessageFor`).
  ///
  /// In fr, this message translates to:
  /// **'Ce code d\'invitation n\'est pas valide.'**
  String get joinCharacterStepScreenInvalidCodeErrorMessage;

  /// Bandeau d'alerte inline pour `StoryInviteFailureKind.inviteDisabled` (cas de course improbable, voir la documentation de `_bannerMessageFor`).
  ///
  /// In fr, this message translates to:
  /// **'Cette invitation a été désactivée.'**
  String get joinCharacterStepScreenInviteDisabledErrorMessage;

  /// Bandeau d'alerte inline pour `StoryInviteFailureKind.characterNotOwned`/`generic` et toute exception qui n'est pas une `StoryInviteFailure`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de rejoindre cette histoire. Réessayez.'**
  String get joinCharacterStepScreenGenericErrorMessage;

  /// Message de repli de `_ErrorState` quand l'erreur de `charactersProvider` n'est pas une `CharacterFailure`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger vos personnages. Réessayez.'**
  String get joinCharacterStepScreenCharactersLoadErrorMessage;

  /// Libellé au-dessus de la liste de personnages, affiché uniquement quand la liste n'est pas vide.
  ///
  /// In fr, this message translates to:
  /// **'Quel personnage rejoint l\'aventure ?'**
  String get joinCharacterStepScreenQuestionLabel;

  /// Message de `_EmptyState`.
  ///
  /// In fr, this message translates to:
  /// **'Tu n\'as pas encore de personnage à rattacher.'**
  String get joinCharacterStepScreenEmptyStateMessage;

  /// `SecondaryButton` lançant l'assistant de création, toujours affiché même dans `_EmptyState`.
  ///
  /// In fr, this message translates to:
  /// **'+ Créer un nouveau personnage'**
  String get joinCharacterStepScreenCreateCharacterButton;

  /// Message de `_JoinSavingOverlay`, pendant l'appel `joinStory`.
  ///
  /// In fr, this message translates to:
  /// **'Rattachement à l\'histoire...'**
  String get joinCharacterStepScreenJoiningOverlayMessage;

  /// `SecondaryButton` de `_ErrorState`.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get joinCharacterStepScreenRetryButton;

  /// Titre du `WoodBackHeader` de `CharacterShareScreen` (route `/characters/:id/share`).
  ///
  /// In fr, this message translates to:
  /// **'PARTAGER LE PERSONNAGE'**
  String get characterShareScreenHeaderTitle;

  /// Paragraphe d'introduction affiché avant la section partage, qu'il soit actif ou non.
  ///
  /// In fr, this message translates to:
  /// **'Génère un lien pour montrer cette fiche en lecture seule à un ami ou à ton MJ, sans qu\'il ait besoin d\'un compte Nexus JDR.'**
  String get characterShareScreenIntroText;

  /// Message de l'`InfoBanner.success` affiché quand `CharacterDetail.shareToken` est renseigné.
  ///
  /// In fr, this message translates to:
  /// **'Partage actif'**
  String get characterShareScreenActiveBanner;

  /// Libellé (déjà en majuscules) au-dessus du champ affichant le lien de partage.
  ///
  /// In fr, this message translates to:
  /// **'LIEN DE PARTAGE'**
  String get characterShareScreenLinkLabel;

  /// Texte d'aide affiché sous le champ de lien.
  ///
  /// In fr, this message translates to:
  /// **'Quiconque possède ce lien peut consulter la fiche tant que le partage reste actif.'**
  String get characterShareScreenLinkHelperText;

  /// `Tooltip` du bouton carré de copie du lien (`_CopyLinkButton`).
  ///
  /// In fr, this message translates to:
  /// **'Copier le lien'**
  String get characterShareScreenCopyLinkTooltip;

  /// Message de `SnackBar` après un appel réussi à `Clipboard.setData` (`_copyLink`).
  ///
  /// In fr, this message translates to:
  /// **'Lien copié.'**
  String get characterShareScreenLinkCopiedMessage;

  /// Libellé du `MenuTile` qui relance `regenerateShareToken` quand le partage est déjà actif.
  ///
  /// In fr, this message translates to:
  /// **'Régénérer le lien'**
  String get characterShareScreenRegenerateMenuLabel;

  /// Message de `SnackBar` après un appel réussi à `regenerateShareToken` (`_regenerate`), partage déjà actif.
  ///
  /// In fr, this message translates to:
  /// **'Lien de partage régénéré.'**
  String get characterShareScreenRegenerateSuccessMessage;

  /// Libellé du `PrimaryButton` affiché quand le partage est désactivé — appelle aussi `regenerateShareToken` (`_regenerate`).
  ///
  /// In fr, this message translates to:
  /// **'Activer le partage'**
  String get characterShareScreenActivateButtonLabel;

  /// Libellé (déjà en majuscules) au-dessus du bouton de désactivation du partage.
  ///
  /// In fr, this message translates to:
  /// **'ZONE DANGEREUSE'**
  String get characterShareScreenDangerZoneLabel;

  /// Libellé du `DestructiveButton` qui ouvre la confirmation de désactivation (`_confirmDisable`).
  ///
  /// In fr, this message translates to:
  /// **'Désactiver le partage'**
  String get characterShareScreenDisableButtonLabel;

  /// Texte affiché sous le bouton de désactivation ET contenu du dialogue de confirmation (`_confirmDisable`) — texte identique dans les deux emplacements, une seule clé.
  ///
  /// In fr, this message translates to:
  /// **'Le lien actuel cessera immédiatement de fonctionner. Tu pourras en générer un nouveau plus tard.'**
  String get characterShareScreenDisableHelperText;

  /// Titre de l'`AlertDialog` de confirmation (`_confirmDisable`).
  ///
  /// In fr, this message translates to:
  /// **'Désactiver le partage ?'**
  String get characterShareScreenDisableDialogTitle;

  /// Bouton d'annulation de l'`AlertDialog` de confirmation.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get characterShareScreenDisableDialogCancel;

  /// Bouton de confirmation de l'`AlertDialog` (plus court que `characterShareScreenDisableButtonLabel`, qui ouvre ce dialogue).
  ///
  /// In fr, this message translates to:
  /// **'Désactiver'**
  String get characterShareScreenDisableDialogConfirm;

  /// Message de `SnackBar` après un appel réussi à `disableShareToken` (`_disable`).
  ///
  /// In fr, this message translates to:
  /// **'Partage désactivé.'**
  String get characterShareScreenDisableSuccessMessage;

  /// Message de `SnackBar` affiché quand `_regenerate`/`_disable` échouent avec une erreur qui n'est pas une `CharacterFailure` — même pattern que `summaryStepScreenGenericSubmitErrorMessage`, réutilisé aux deux points d'appel de cet écran.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Réessayez.'**
  String get characterShareScreenGenericErrorMessage;

  /// Repli de `_ErrorState` quand l'erreur de `characterDetailProvider` n'est pas une `CharacterFailure` — voir `resolveCharacterFailureMessage` (`presentation/character_failure_presenter.dart`) pour le cas `CharacterFailure`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger ce personnage. Réessayez.'**
  String get characterShareScreenLoadErrorMessage;

  /// Bouton de `_ErrorState`.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get characterShareScreenRetryButtonLabel;

  /// Titre du `WoodBackHeader` de `SharedCharacterViewScreen` tant qu'aucune fiche n'est chargée, variante lien de partage (route `/p/:token`) — remplacé par `CharacterDetailTab.headerTitle` une fois la fiche chargée.
  ///
  /// In fr, this message translates to:
  /// **'PERSONNAGE PARTAGÉ'**
  String get sharedCharacterViewScreenHeaderTitle;

  /// Même titre que `sharedCharacterViewScreenHeaderTitle`, variante `SharedCharacterViewScreen.groupMember` (fiche d'un membre de groupe).
  ///
  /// In fr, this message translates to:
  /// **'MEMBRE DU GROUPE'**
  String get sharedCharacterViewScreenGroupMemberHeaderTitle;

  /// Message de l'`InfoBanner` affiché en tête de l'onglet "Personnage".
  ///
  /// In fr, this message translates to:
  /// **'Vue en lecture seule'**
  String get sharedCharacterViewScreenReadOnlyBanner;

  /// Texte explicatif affiché sous la grille de caractéristiques de l'onglet "Personnage".
  ///
  /// In fr, this message translates to:
  /// **'Toutes les sections (Compétences, Sorts, Inventaire, Histoire) sont consultables ci-dessous, en lecture seule.'**
  String get sharedCharacterViewScreenSectionsHintText;

  /// Libellé du bandeau PV de `_SharedVitalsCard` — même texte que `characterVitalsCardHpLabel`, dupliqué volontairement (pas de dépendance entre ces deux widgets, voir la doc de classe de `_SharedVitalsCard`).
  ///
  /// In fr, this message translates to:
  /// **'POINTS DE VIE'**
  String get sharedCharacterViewScreenHpLabel;

  /// Libellé du bandeau XP de `_SharedVitalsCard` — même texte que `characterVitalsCardXpLabel`, dupliqué volontairement (même rationale que `sharedCharacterViewScreenHpLabel`).
  ///
  /// In fr, this message translates to:
  /// **'EXPÉRIENCE'**
  String get sharedCharacterViewScreenXpLabel;

  /// Puce `_TemporaryHpChip` affichée quand `temporaryHp > 0` — même texte que `characterVitalsCardTemporaryHpChip`/`groupMembersTabBodyTemporaryHpChipLabel`, dupliqué volontairement (pas de dépendance entre ces widgets).
  ///
  /// In fr, this message translates to:
  /// **'+{amount} PV temp.'**
  String sharedCharacterViewScreenTemporaryHpChipLabel(int amount);

  /// Titre de `_InvalidLinkState` (résultat RPC `null`), variante lien de partage (`isGroupMember == false`).
  ///
  /// In fr, this message translates to:
  /// **'Ce lien de partage n\'est plus valide'**
  String get sharedCharacterViewScreenInvalidLinkTitle;

  /// Titre de `_InvalidLinkState`, variante `isGroupMember == true`.
  ///
  /// In fr, this message translates to:
  /// **'Cette fiche n\'est plus accessible'**
  String get sharedCharacterViewScreenInvalidLinkGroupMemberTitle;

  /// Corps de `_InvalidLinkState`, variante lien de partage (`isGroupMember == false`).
  ///
  /// In fr, this message translates to:
  /// **'Le partage a peut-être été désactivé, ou le lien a été mal recopié. Demande un nouveau lien à son propriétaire.'**
  String get sharedCharacterViewScreenInvalidLinkBody;

  /// Corps de `_InvalidLinkState`, variante `isGroupMember == true`.
  ///
  /// In fr, this message translates to:
  /// **'Ce personnage a peut-être quitté le groupe.'**
  String get sharedCharacterViewScreenInvalidLinkGroupMemberBody;

  /// Bouton de `_InvalidLinkState` (les deux variantes).
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get sharedCharacterViewScreenInvalidLinkRetryButtonLabel;

  /// Repli de `_ErrorState` quand l'erreur n'est pas une `CharacterFailure` — voir `resolveCharacterFailureMessage` (`presentation/character_failure_presenter.dart`) pour le cas `CharacterFailure`.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger ce personnage. Réessayez.'**
  String get sharedCharacterViewScreenLoadErrorMessage;

  /// Bouton de `_ErrorState`.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get sharedCharacterViewScreenErrorRetryButtonLabel;
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
