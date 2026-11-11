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
  /// **'Sur aidedd.org, ouvre la fiche de ton personnage puis utilise son export XML (bouton d\'export du site). Dans Nexus JDR, va dans la liste des Personnages et appuie sur « Importer XML », en bas de l\'écran à côté de « + Créer », puis sélectionne ce fichier .xml. L\'app pré-remplit automatiquement la fiche (caractéristiques, classe, race, sorts, inventaire...) et te montre un écran de vérification avant de l\'enregistrer, avec un badge sur les champs qu\'elle n\'a pas reconnus pour que tu les complètes toi-même.'**
  String get profileFaqAnswer1;

  /// Question 2 de `profile_faq_screen.dart` (`_faqItems`, id 2).
  ///
  /// In fr, this message translates to:
  /// **'Comment rejoindre l\'histoire de mon MJ ?'**
  String get profileFaqQuestion2;

  /// Réponse 2 de `profile_faq_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'Ton MJ t\'envoie un lien d\'invitation depuis l\'app « Histoires ». Sur Android, ouvre ce lien sur ton téléphone : Nexus JDR s\'ouvre sur l\'invitation et tu choisis le personnage à rattacher. Il n\'y a pas encore de saisie manuelle du code dans l\'app, et l\'ouverture du lien dans l\'app n\'est pas encore disponible sur iPhone/iPad.'**
  String get profileFaqAnswer2;

  /// Question 3 de `profile_faq_screen.dart` (`_faqItems`, id 3).
  ///
  /// In fr, this message translates to:
  /// **'Mes personnages sont-ils sauvegardés hors ligne ?'**
  String get profileFaqQuestion3;

  /// Réponse 3 de `profile_faq_screen.dart`.
  ///
  /// In fr, this message translates to:
  /// **'En grande partie. Sans connexion, tu peux consulter ta liste et les fiches déjà ouvertes, et modifier points de vie (et PV temporaires), XP, emplacements de sorts, sorts innés, aptitudes, conditions, repos, sorts préparés, objets équipés ou harmonisés, inspiration, bonus de CA, monnaies, journal et inventaire (objet personnalisé, retrait, usage, butin). Ces changements sont mis en attente sur ton appareil, puis envoyés automatiquement au retour du réseau. Un seul repos est mis en attente à la fois par personnage : tant qu\'il n\'est pas envoyé, un second repos est refusé ; attends le retour du réseau. Pour ajouter un objet du catalogue hors ligne, ouvre le catalogue au moins une fois en ligne ; l\'objet personnalisé marche toujours. La bannière en haut de l\'écran indique l\'état : « Hors ligne », « N modifications en attente » ou « Synchronisé ». Si la même fiche a été modifiée sur un autre appareil, une alerte te l\'indique ; ta modification hors ligne est appliquée par-dessus. Demandent toujours une connexion : création de personnage, montée de niveau, marquer mort ou ressusciter, archiver ou supprimer un personnage, histoire du personnage, arme de pacte, portrait, partage, groupes, import et export XML, suppression de compte et signalement de bug.'**
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

  /// SnackBar de `_applyRest` (D187) : `WriteOutcome.restAlreadyPending` — la file hors-ligne ne garde qu'un repos par personnage, ce second repos n'est ni écrit ni mis en file.
  ///
  /// In fr, this message translates to:
  /// **'Un repos est déjà en attente de synchronisation pour ce personnage. Attendez le retour de la connexion avant d\'en faire un autre.'**
  String get characterDetailRestAlreadyPendingMessage;

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

  /// Libellé d'état affiché sous la jauge PV quand les PV actuels valent exactement 0.
  ///
  /// In fr, this message translates to:
  /// **'À 0 PV'**
  String get characterVitalsCardZeroHpLabel;

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

  /// Valeur de la tuile "Vitesse" quand `speed` est résolu — unité métrique (mètres) volontairement gardée telle quelle en anglais aussi (même unité conservée dans app_en.arb, qui ne porte pas sa propre description de clé : ce fichier app_fr.arb est le template) : `speed` est reçu DÉJÀ converti en mètres (`SpeedConverter.feetToMetres`, la base `races.speed` reste en pieds), formaté selon la locale (7,5 en français, 7.5 en anglais).
  ///
  /// In fr, this message translates to:
  /// **'{speed} m'**
  String characterStatPillsSpeedValue(double speed);

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

  /// Bouton primaire de `hp_adjustment_sheet.dart` en mode Dégâts (le libellé suit le mode actif pour éviter d'appliquer des dégâts alors qu'on voulait soigner).
  ///
  /// In fr, this message translates to:
  /// **'Infliger'**
  String get hpAdjustmentSheetDamageApplyButton;

  /// Bouton primaire de `hp_adjustment_sheet.dart` en mode Soins.
  ///
  /// In fr, this message translates to:
  /// **'Soigner'**
  String get hpAdjustmentSheetHealApplyButton;

  /// Bouton primaire de `hp_adjustment_sheet.dart` en mode PV temporaires.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get hpAdjustmentSheetTemporaryApplyButton;

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

  /// Message de la sheet "Depuis le catalogue" quand le catalogue n'a jamais été chargé et que l'appareil est hors ligne (F20) : propose l'objet personnalisé, disponible hors ligne.
  ///
  /// In fr, this message translates to:
  /// **'Le catalogue d\'objets n\'est pas encore disponible : il n\'a jamais été chargé sur cet appareil et la connexion est indisponible. Vous pouvez ajouter un objet personnalisé dès maintenant, ou réessayer une fois reconnecté.'**
  String get addItemFlowCatalogOfflineMessage;

  /// Bouton de l'état « catalogue indisponible hors ligne » de la sheet "Depuis le catalogue" : ouvre la saisie d'un objet personnalisé.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un objet personnalisé'**
  String get addItemFlowCatalogOfflineCustomButton;

  /// Bouton de l'état « catalogue indisponible hors ligne » de la sheet "Depuis le catalogue" : relance le chargement du catalogue.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get addItemFlowCatalogOfflineRetryButton;

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

  /// Bouton secondaire de la sheet d'ajustement de monnaie qui ouvre la conversion entre pièces.
  ///
  /// In fr, this message translates to:
  /// **'Changer'**
  String get currencyAdjustmentSheetConvertButton;

  /// Libellé d'accessibilité du bouton moins du champ de montant (PV, monnaies).
  ///
  /// In fr, this message translates to:
  /// **'Diminuer'**
  String get numericAmountDecreaseLabel;

  /// Libellé d'accessibilité du bouton plus du champ de montant (PV, monnaies).
  ///
  /// In fr, this message translates to:
  /// **'Augmenter'**
  String get numericAmountIncreaseLabel;

  /// Libellé d'accessibilité du champ de montant de la feuille d'ajustement des PV.
  ///
  /// In fr, this message translates to:
  /// **'Montant de PV'**
  String get hpAdjustmentSheetAmountFieldLabel;

  /// Libellé d'accessibilité du champ de montant de la feuille d'ajustement de monnaie.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get currencyAdjustmentSheetAmountFieldLabel;

  /// Aide sous le champ de montant : borne maximale saisissable.
  ///
  /// In fr, this message translates to:
  /// **'Max {max}'**
  String numericAmountMaxHint(int max);

  /// Aide sous le champ de montant en mode Retirer : solde de la monnaie, borne du retrait.
  ///
  /// In fr, this message translates to:
  /// **'Solde : {balance}'**
  String currencyAdjustmentSheetBalanceHint(int balance);

  /// Titre de la sheet de conversion de pièces.
  ///
  /// In fr, this message translates to:
  /// **'Changer des pièces'**
  String get currencyConversionSheetTitle;

  /// Intitulé du choix de la pièce source.
  ///
  /// In fr, this message translates to:
  /// **'PIÈCE À CHANGER'**
  String get currencyConversionSheetFromLabel;

  /// Intitulé du choix de la pièce cible.
  ///
  /// In fr, this message translates to:
  /// **'CONTRE'**
  String get currencyConversionSheetToLabel;

  /// Intitulé du champ de montant de la conversion.
  ///
  /// In fr, this message translates to:
  /// **'MONTANT À CHANGER'**
  String get currencyConversionSheetAmountLabel;

  /// Aperçu du résultat de la conversion avant validation.
  ///
  /// In fr, this message translates to:
  /// **'{spent} {fromUnit} contre {obtained} {toUnit}'**
  String currencyConversionSheetPreview(
    int spent,
    String fromUnit,
    int obtained,
    String toUnit,
  );

  /// Précise la part du montant qui n'est pas convertie (jamais perdue).
  ///
  /// In fr, this message translates to:
  /// **'{unconverted} {fromUnit} non converties restent dans votre bourse.'**
  String currencyConversionSheetRemainder(int unconverted, String fromUnit);

  /// Erreur : le montant est trop faible pour une seule pièce cible.
  ///
  /// In fr, this message translates to:
  /// **'Ce montant ne suffit pas pour obtenir une pièce entière.'**
  String get currencyConversionSheetTooSmall;

  /// Message quand tous les soldes sont à zéro.
  ///
  /// In fr, this message translates to:
  /// **'Aucune pièce à changer.'**
  String get currencyConversionSheetNothingToConvert;

  /// Bouton secondaire d'annulation de la sheet de conversion.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get currencyConversionSheetCancelButton;

  /// Bouton primaire de validation de la conversion.
  ///
  /// In fr, this message translates to:
  /// **'Changer'**
  String get currencyConversionSheetApplyButton;

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

  /// `Semantics.label` d'une ligne d'emplacements d'un niveau (carte des emplacements, compteur du titre de groupe de sorts).
  ///
  /// In fr, this message translates to:
  /// **'Niveau {level} : {remaining} sur {total} emplacements disponibles'**
  String characterSpellsSectionSlotLevelSemanticLabel(
    int level,
    int remaining,
    int total,
  );

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

  /// Message de `_NonCasterEmptyState` (classe sans emplacements de sorts).
  ///
  /// In fr, this message translates to:
  /// **'Ce personnage ne lance pas de sorts.'**
  String get characterSpellsTabBodyNonCasterMessage;

  /// Titre de la carte des aptitudes à usage limité quand le personnage ne lance pas de sorts.
  ///
  /// In fr, this message translates to:
  /// **'RESSOURCES'**
  String get characterSpellsTabBodyResourcesTitle;

  /// Titre de la carte listant les emplacements de sorts de chaque niveau disponible.
  ///
  /// In fr, this message translates to:
  /// **'EMPLACEMENTS DE SORTS'**
  String get characterSpellsTabBodySlotsCardTitle;

  /// Libellé d'une ligne de pastilles de la carte des emplacements de sorts.
  ///
  /// In fr, this message translates to:
  /// **'Niveau {level}'**
  String characterSpellsTabBodySlotsLevelLabel(int level);

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

  /// Libellé de la condition D&D 5e « blinded » (clé serveur `blinded`).
  ///
  /// In fr, this message translates to:
  /// **'Aveuglé'**
  String get conditionBlindedLabel;

  /// Règle résumée de la condition « blinded » (D&D 5e, édition 2014), ≤ 90 caractères, purement informative.
  ///
  /// In fr, this message translates to:
  /// **'Ne voit pas ; ses attaques ont le désavantage, celles contre lui l\'avantage.'**
  String get conditionBlindedRule;

  /// Libellé de la condition D&D 5e « charmed » (clé serveur `charmed`).
  ///
  /// In fr, this message translates to:
  /// **'Charmé'**
  String get conditionCharmedLabel;

  /// Règle résumée de la condition « charmed » (D&D 5e, édition 2014), ≤ 90 caractères, purement informative.
  ///
  /// In fr, this message translates to:
  /// **'Ne peut cibler le charmeur de façon nuisible ; celui-ci a l\'avantage social.'**
  String get conditionCharmedRule;

  /// Libellé de la condition D&D 5e « deafened » (clé serveur `deafened`).
  ///
  /// In fr, this message translates to:
  /// **'Assourdi'**
  String get conditionDeafenedLabel;

  /// Règle résumée de la condition « deafened » (D&D 5e, édition 2014), ≤ 90 caractères, purement informative.
  ///
  /// In fr, this message translates to:
  /// **'N\'entend rien et rate automatiquement les tests d\'ouïe.'**
  String get conditionDeafenedRule;

  /// Libellé de la condition D&D 5e « frightened » (clé serveur `frightened`).
  ///
  /// In fr, this message translates to:
  /// **'Effrayé'**
  String get conditionFrightenedLabel;

  /// Règle résumée de la condition « frightened » (D&D 5e, édition 2014), ≤ 90 caractères, purement informative.
  ///
  /// In fr, this message translates to:
  /// **'Désavantage aux tests et attaques tant que la source est en vue ; ne s\'en approche pas.'**
  String get conditionFrightenedRule;

  /// Libellé de la condition D&D 5e « grappled » (clé serveur `grappled`).
  ///
  /// In fr, this message translates to:
  /// **'Agrippé'**
  String get conditionGrappledLabel;

  /// Règle résumée de la condition « grappled » (D&D 5e, édition 2014), ≤ 90 caractères, purement informative.
  ///
  /// In fr, this message translates to:
  /// **'Vitesse 0, sans bonus de vitesse ; fin si l\'agrippeur est neutralisé.'**
  String get conditionGrappledRule;

  /// Libellé de la condition D&D 5e « incapacitated » (clé serveur `incapacitated`).
  ///
  /// In fr, this message translates to:
  /// **'Neutralisé'**
  String get conditionIncapacitatedLabel;

  /// Règle résumée de la condition « incapacitated » (D&D 5e, édition 2014), ≤ 90 caractères, purement informative.
  ///
  /// In fr, this message translates to:
  /// **'Ne peut effectuer ni action ni réaction.'**
  String get conditionIncapacitatedRule;

  /// Libellé de la condition D&D 5e « invisible » (clé serveur `invisible`).
  ///
  /// In fr, this message translates to:
  /// **'Invisible'**
  String get conditionInvisibleLabel;

  /// Règle résumée de la condition « invisible » (D&D 5e, édition 2014), ≤ 90 caractères, purement informative.
  ///
  /// In fr, this message translates to:
  /// **'Attaques avantagées, celles contre lui désavantagées (sauf magie ou sens spécial).'**
  String get conditionInvisibleRule;

  /// Libellé de la condition D&D 5e « paralyzed » (clé serveur `paralyzed`).
  ///
  /// In fr, this message translates to:
  /// **'Paralysé'**
  String get conditionParalyzedLabel;

  /// Règle résumée de la condition « paralyzed » (D&D 5e, édition 2014), ≤ 90 caractères, purement informative.
  ///
  /// In fr, this message translates to:
  /// **'Neutralisé, immobile ; rate For/Dex ; attaques contre lui avantagées, critique ≤ 1,50 m.'**
  String get conditionParalyzedRule;

  /// Libellé de la condition D&D 5e « petrified » (clé serveur `petrified`).
  ///
  /// In fr, this message translates to:
  /// **'Pétrifié'**
  String get conditionPetrifiedLabel;

  /// Règle résumée de la condition « petrified » (D&D 5e, édition 2014), ≤ 90 caractères, purement informative.
  ///
  /// In fr, this message translates to:
  /// **'Pierre : neutralisé, avantage contre lui, rate For/Dex, résiste à tout, immunisé poison.'**
  String get conditionPetrifiedRule;

  /// Libellé de la condition D&D 5e « poisoned » (clé serveur `poisoned`).
  ///
  /// In fr, this message translates to:
  /// **'Empoisonné'**
  String get conditionPoisonedLabel;

  /// Règle résumée de la condition « poisoned » (D&D 5e, édition 2014), ≤ 90 caractères, purement informative.
  ///
  /// In fr, this message translates to:
  /// **'Désavantage aux jets d\'attaque et aux tests de caractéristique.'**
  String get conditionPoisonedRule;

  /// Libellé de la condition D&D 5e « prone » (clé serveur `prone`).
  ///
  /// In fr, this message translates to:
  /// **'À terre'**
  String get conditionProneLabel;

  /// Règle résumée de la condition « prone » (D&D 5e, édition 2014), ≤ 90 caractères, purement informative.
  ///
  /// In fr, this message translates to:
  /// **'Rampe ; désavantage à ses attaques ; contre lui : avantage ≤ 1,50 m, sinon désavantage.'**
  String get conditionProneRule;

  /// Libellé de la condition D&D 5e « restrained » (clé serveur `restrained`).
  ///
  /// In fr, this message translates to:
  /// **'Entravé'**
  String get conditionRestrainedLabel;

  /// Règle résumée de la condition « restrained » (D&D 5e, édition 2014), ≤ 90 caractères, purement informative.
  ///
  /// In fr, this message translates to:
  /// **'Vitesse 0 ; attaques contre lui avantagées, les siennes et ses JS Dex désavantagés.'**
  String get conditionRestrainedRule;

  /// Libellé de la condition D&D 5e « stunned » (clé serveur `stunned`).
  ///
  /// In fr, this message translates to:
  /// **'Étourdi'**
  String get conditionStunnedLabel;

  /// Règle résumée de la condition « stunned » (D&D 5e, édition 2014), ≤ 90 caractères, purement informative.
  ///
  /// In fr, this message translates to:
  /// **'Neutralisé, immobile, parle à peine ; rate For/Dex ; attaques contre lui avantagées.'**
  String get conditionStunnedRule;

  /// Libellé de la condition D&D 5e « unconscious » (clé serveur `unconscious`).
  ///
  /// In fr, this message translates to:
  /// **'Inconscient'**
  String get conditionUnconsciousLabel;

  /// Règle résumée de la condition « unconscious » (D&D 5e, édition 2014), ≤ 90 caractères, purement informative.
  ///
  /// In fr, this message translates to:
  /// **'Neutralisé, lâche tout, à terre ; rate For/Dex ; contre lui : avantage, critique ≤ 1,50 m.'**
  String get conditionUnconsciousRule;

  /// Libellé du bouton discret d'ajout de la zone d'état (précédé d'une icône +).
  ///
  /// In fr, this message translates to:
  /// **'État'**
  String get conditionsAddButtonLabel;

  /// Libellé d'accessibilité du bouton d'ajout d'un état (aucune condition active).
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un état'**
  String get conditionsAddSemanticsLabel;

  /// Libellé d'accessibilité du bouton d'édition des états (au moins une condition active).
  ///
  /// In fr, this message translates to:
  /// **'Modifier les états'**
  String get conditionsEditSemanticsLabel;

  /// Libellé d'accessibilité de la zone d'état : liste des conditions actives.
  ///
  /// In fr, this message translates to:
  /// **'États actifs : {names}'**
  String conditionsZoneSemanticsLabel(String names);

  /// Pastille de dépassement (« +N ») quand toutes les conditions ne tiennent pas.
  ///
  /// In fr, this message translates to:
  /// **'+{count}'**
  String conditionsMoreChipLabel(int count);

  /// Libellé d'accessibilité de la pastille « +N » : liste des conditions masquées.
  ///
  /// In fr, this message translates to:
  /// **'{count} autres états : {names}'**
  String conditionsMoreChipSemanticsLabel(int count, String names);

  /// Libellé d'accessibilité d'une pastille : nom puis règle de la condition.
  ///
  /// In fr, this message translates to:
  /// **'{label} : {rule}'**
  String conditionChipSemanticsLabel(String label, String rule);

  /// Titre de la feuille de sélection des conditions (palier display).
  ///
  /// In fr, this message translates to:
  /// **'ÉTATS'**
  String get conditionsSheetTitle;

  /// Sous-titre rappelant que les états sont informatifs.
  ///
  /// In fr, this message translates to:
  /// **'Informatif : n\'a aucun effet sur les calculs.'**
  String get conditionsSheetSubtitle;

  /// Bouton d'enregistrement de la feuille des conditions.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get conditionsSheetSaveButton;

  /// Bouton d'annulation de la feuille des conditions.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get conditionsSheetCancelButton;

  /// Lien qui décoche toutes les conditions (visible si au moins une est cochée).
  ///
  /// In fr, this message translates to:
  /// **'Tout décocher'**
  String get conditionsSheetClearAllButton;

  /// Erreur générique à l'enregistrement des conditions.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'enregistrer les états. Réessayez.'**
  String get conditionsSheetGenericError;

  /// Annonce d'accessibilité après enregistrement.
  ///
  /// In fr, this message translates to:
  /// **'États mis à jour : {names}'**
  String conditionsUpdatedAnnouncement(String names);

  /// Annonce d'accessibilité quand plus aucune condition n'est active.
  ///
  /// In fr, this message translates to:
  /// **'Aucun état actif'**
  String get conditionsNoneAnnouncement;

  /// Refus d'accès (RLS) à l'enregistrement des conditions d'un personnage (singulier).
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez pas accès à ce personnage.'**
  String get conditionsAccessDeniedMessage;

  /// Bandeau de synchro (`SyncStatusBanner`) : synchronisation en cours, visible après 1 s.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation…'**
  String get syncBannerSyncing;

  /// Bandeau de synchro : hors ligne, aucune modification en attente (fiche seulement).
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne. Tes modifications seront envoyées au retour du réseau.'**
  String get syncBannerOfflineEmpty;

  /// Bandeau de synchro : hors ligne avec des modifications en attente.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Hors ligne · 1 modification en attente} other{Hors ligne · {count} modifications en attente}}'**
  String syncBannerOfflinePending(int count);

  /// Bandeau de synchro : en ligne, des modifications attendent depuis plus de 3 s.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 modification en attente d\'envoi} other{{count} modifications en attente d\'envoi}}'**
  String syncBannerPendingOnline(int count);

  /// Bandeau de synchro : confirmation transitoire (2 s) après un état hors ligne/en attente.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisé'**
  String get syncBannerSynced;

  /// Libellé d'accessibilité fixe (sans compteur, pour ne pas être ré-annoncé à chaque changement) de la région live du bandeau hors ligne.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne'**
  String get syncBannerOfflineSemantics;

  /// Info-bulle/libellé d'accessibilité du bouton de fermeture d'une alerte de synchro.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get syncBannerDismissTooltip;

  /// Repli du nom de personnage dans une alerte de synchro quand le nom n'a pas pu être retrouvé.
  ///
  /// In fr, this message translates to:
  /// **'ce personnage'**
  String get syncAlertUnknownCharacter;

  /// Alerte d'abandon d'une écriture de PV.
  ///
  /// In fr, this message translates to:
  /// **'Modification non enregistrée : la dernière valeur connue des PV de {name} est {value}/{max}.'**
  String syncAlertAbandonHp(String name, int value, int max);

  /// Alerte d'abandon d'une écriture d'emplacement de sort.
  ///
  /// In fr, this message translates to:
  /// **'Modification non enregistrée : la dernière valeur connue des emplacements de niveau {level} de {name} est {value}/{max}.'**
  String syncAlertAbandonSlot(String name, int level, int value, int max);

  /// Alerte d'abandon d'une écriture d'XP.
  ///
  /// In fr, this message translates to:
  /// **'Modification non enregistrée : la dernière valeur connue de l\'XP de {name} est {value}.'**
  String syncAlertAbandonXp(String name, int value);

  /// Alerte d'abandon de repli (aptitude, sort inné, repos, valeur serveur inconnue).
  ///
  /// In fr, this message translates to:
  /// **'Une modification de {name} n\'a pas pu être enregistrée. La fiche affiche la valeur du serveur.'**
  String syncAlertAbandonFallback(String name);

  /// Alerte de conflit F19 (même compte, deux appareils) sur les PV. `server`/`queued` sont déjà formatés (ex. « 12/30 + 3 temp. », ou « 12 » si le maximum est inconnu). `server` = valeur AVANT l'envoi, `queued` = valeur appliquée.
  ///
  /// In fr, this message translates to:
  /// **'{name} : les PV ont été modifiés sur un autre appareil (serveur : {server}). Ta modification hors ligne ({queued}) les a remplacés.'**
  String syncAlertConflictHp(String name, String server, String queued);

  /// Alerte de conflit F19 quand seuls les PV temporaires diffèrent.
  ///
  /// In fr, this message translates to:
  /// **'{name} : les PV temporaires ont été modifiés sur un autre appareil (serveur : {server}). Ta modification hors ligne ({queued}) les a remplacés.'**
  String syncAlertConflictTempHp(String name, int server, int queued);

  /// Suffixe d'une valeur de PV citée dans une alerte quand les PV temporaires sont > 0.
  ///
  /// In fr, this message translates to:
  /// **' + {temp} temp.'**
  String syncAlertTempHpSuffix(int temp);

  /// Alerte de conflit F19 sur les monnaies. `server`/`queued` sont des listes déjà formatées (« 120 PO, 4 PA »), mêmes monnaies, même ordre.
  ///
  /// In fr, this message translates to:
  /// **'{name} : tes pièces ont été modifiées sur un autre appareil (serveur : {server}). Ta modification hors ligne ({queued}) les a remplacées.'**
  String syncAlertConflictCurrency(String name, String server, String queued);

  /// Unité courte cuivre dans une alerte de synchro.
  ///
  /// In fr, this message translates to:
  /// **'PC'**
  String get syncAlertCurrencyUnitCp;

  /// Unité courte argent dans une alerte de synchro.
  ///
  /// In fr, this message translates to:
  /// **'PA'**
  String get syncAlertCurrencyUnitSp;

  /// Unité courte électrum dans une alerte de synchro.
  ///
  /// In fr, this message translates to:
  /// **'PE'**
  String get syncAlertCurrencyUnitEp;

  /// Unité courte or dans une alerte de synchro.
  ///
  /// In fr, this message translates to:
  /// **'PO'**
  String get syncAlertCurrencyUnitGp;

  /// Unité courte platine dans une alerte de synchro.
  ///
  /// In fr, this message translates to:
  /// **'PP'**
  String get syncAlertCurrencyUnitPp;

  /// Alerte de conflit F19 sur la quantité d'un objet (un seul objet).
  ///
  /// In fr, this message translates to:
  /// **'{name} : la quantité de « {item} » a été modifiée sur un autre appareil (serveur : {server}). Ta modification hors ligne ({queued}) l\'a remplacée.'**
  String syncAlertConflictItem(
    String name,
    String item,
    int server,
    int queued,
  );

  /// Alerte de conflit F19 agrégée : plusieurs objets d'un même personnage dans une passe de rejeu. Au plus deux noms cités, `more` = nombre d'objets restants.
  ///
  /// In fr, this message translates to:
  /// **'{name} : les quantités de « {first} » et « {second} » ont été modifiées sur un autre appareil{more, plural, =0{} =1{ (+1 autre)} other{ (+{more} autres)}}. Tes modifications hors ligne les ont remplacées.'**
  String syncAlertConflictItems(
    String name,
    String first,
    String second,
    int more,
  );

  /// Alerte de conflit F19 sur l'XP.
  ///
  /// In fr, this message translates to:
  /// **'{name} : l\'XP a été modifiée sur un autre appareil (serveur : {server} XP). Ta modification hors ligne ({queued} XP) l\'a remplacée.'**
  String syncAlertConflictXp(String name, int server, int queued);

  /// Alerte de conflit de repli (valeur serveur inconnue).
  ///
  /// In fr, this message translates to:
  /// **'{name} a été modifié sur un autre appareil. Ta modification hors ligne a été appliquée par-dessus.'**
  String syncAlertConflictFallback(String name);

  /// Suffixe ajouté à une alerte de synchro quand d'autres alertes attendent derrière elle.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{ (+1 autre)} other{ (+{count} autres)}}'**
  String syncAlertMoreSuffix(int count);

  /// Titre du dialogue du retour Android depuis la liste racine quand des écritures sont en attente.
  ///
  /// In fr, this message translates to:
  /// **'Quitter l\'app ?'**
  String get syncExitDialogTitle;

  /// Corps du dialogue de sortie Android.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 modification en attente d\'envoi. Elle reste enregistrée sur l\'appareil et partira à la prochaine ouverture avec du réseau.} other{{count} modifications en attente d\'envoi. Elles restent enregistrées sur l\'appareil et partiront à la prochaine ouverture avec du réseau.}}'**
  String syncExitDialogBody(int count);

  /// Bouton primaire du dialogue de sortie : ferme le dialogue.
  ///
  /// In fr, this message translates to:
  /// **'Rester'**
  String get syncExitDialogStay;

  /// Bouton secondaire du dialogue de sortie : quitte l'app.
  ///
  /// In fr, this message translates to:
  /// **'Quitter quand même'**
  String get syncExitDialogLeave;

  /// Ligne du pied de page du Profil. {when} : durée relative ou date absolue.
  ///
  /// In fr, this message translates to:
  /// **'Dernière synchronisation : {when}'**
  String profileLastSync(String when);

  /// Pied de page du Profil : aucune synchro réussie connue pour ce compte.
  ///
  /// In fr, this message translates to:
  /// **'Dernière synchronisation : jamais'**
  String get profileLastSyncNever;

  /// Durée relative < 1 min.
  ///
  /// In fr, this message translates to:
  /// **'à l\'instant'**
  String get profileLastSyncJustNow;

  /// Durée relative < 60 min.
  ///
  /// In fr, this message translates to:
  /// **'il y a {count} min'**
  String profileLastSyncMinutes(int count);

  /// Durée relative < 24 h.
  ///
  /// In fr, this message translates to:
  /// **'il y a {count} h'**
  String profileLastSyncHours(int count);

  /// Date absolue locale (au-delà de 24 h). date/time déjà formatés par intl.
  ///
  /// In fr, this message translates to:
  /// **'{date} à {time}'**
  String profileLastSyncAbsolute(String date, String time);

  /// Suffixe de la ligne de dernière synchro quand des modifications attendent.
  ///
  /// In fr, this message translates to:
  /// **' · {count} en attente'**
  String profileLastSyncPendingSuffix(int count);
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
