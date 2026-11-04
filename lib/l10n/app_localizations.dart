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
