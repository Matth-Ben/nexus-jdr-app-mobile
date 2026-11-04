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

  @override
  String get authLoginBrandTitle => 'NEXUS JDR';

  @override
  String get authLoginTagline => 'Le registre des aventuriers';

  @override
  String get authLoginSharedAccountNotice => 'Même compte que l\'app Histoires';

  @override
  String get authLoginCardTitleSignUp => 'CRÉER UN COMPTE';

  @override
  String get authLoginCardTitleLogin => 'ENTRER DANS LA TAVERNE';

  @override
  String get authLoginEmailLabel => 'Adresse e-mail';

  @override
  String get authLoginEmailHint => 'nom@exemple.com';

  @override
  String get authLoginPasswordLabel => 'Mot de passe';

  @override
  String get authLoginPasswordHint => '••••••••';

  @override
  String get authLoginForgotPasswordLink => 'Mot de passe oublié ?';

  @override
  String get authLoginConfirmPasswordLabel => 'Confirmer le mot de passe';

  @override
  String get authLoginPseudoLabel => 'Pseudo';

  @override
  String get authLoginPseudoHint => 'Comment veux-tu qu\'on t\'appelle ?';

  @override
  String get authLoginPseudoHelper =>
      'Facultatif — tu pourras le changer plus tard dans ton profil.';

  @override
  String get authLoginSubmitSignUp => 'Créer le compte';

  @override
  String get authLoginSubmitLogin => 'Entrer';

  @override
  String get authLoginOrDivider => 'OU';

  @override
  String get authLoginContinueWithApple => 'Continuer avec Apple';

  @override
  String get authLoginContinueWithGoogle => 'Continuer avec Google';

  @override
  String get authLoginSwitchModePromptLogin => 'Déjà un compte ? ';

  @override
  String get authLoginSwitchModePromptSignUp => 'Pas encore de compte ? ';

  @override
  String get authLoginSwitchModeActionLogin => 'Se connecter';

  @override
  String get authLoginSwitchModeActionSignUp => 'Créer un compte';

  @override
  String get authLoginSignUpConfirmationTitle => 'VÉRIFIEZ VOS E-MAILS';

  @override
  String authLoginSignUpConfirmationBody(String email) {
    return 'Un e-mail de confirmation vient d\'être envoyé à $email. Cliquez sur le lien qu\'il contient pour activer votre compte.';
  }

  @override
  String get authLoginBackToLogin => 'Retour à la connexion';

  @override
  String get authForgotPasswordTitle => 'Mot de passe oublié ?';

  @override
  String get authForgotPasswordDescription =>
      'Saisissez votre adresse e-mail : nous vous enverrons un lien pour définir un nouveau mot de passe.';

  @override
  String get authForgotPasswordEmailHint => 'nom@exemple.com';

  @override
  String get authForgotPasswordCancel => 'Annuler';

  @override
  String get authForgotPasswordSubmit => 'Envoyer le lien';

  @override
  String get authForgotPasswordNeutralMessage =>
      'Si un compte existe avec cet email, un lien de réinitialisation vient d\'être envoyé.';

  @override
  String get authErrorInvalidCredentials =>
      'Adresse e-mail ou mot de passe incorrect.';

  @override
  String get authErrorEmailAlreadyExists =>
      'Un compte existe déjà avec cette adresse e-mail.';

  @override
  String authErrorWeakPassword(int minLength) {
    return 'Le mot de passe doit contenir au moins $minLength caractères.';
  }

  @override
  String get authErrorEmailNotConfirmed =>
      'Confirmez votre adresse e-mail avant de vous connecter (vérifiez votre boîte de réception).';

  @override
  String get authErrorInvalidEmail => 'Adresse e-mail invalide.';

  @override
  String get authErrorTooManyRequests =>
      'Trop de tentatives. Réessayez dans quelques instants.';

  @override
  String get authErrorNetwork =>
      'Impossible de contacter le serveur. Vérifiez votre connexion internet et réessayez.';

  @override
  String get authErrorUnexpected =>
      'Une erreur inattendue est survenue. Réessayez.';

  @override
  String get authValidationEmailRequired => 'Saisissez votre adresse e-mail.';

  @override
  String get authValidationEmailInvalid => 'Adresse e-mail invalide.';

  @override
  String get authValidationPasswordRequired => 'Saisissez votre mot de passe.';

  @override
  String authValidationPasswordTooShort(int minLength) {
    return 'Le mot de passe doit contenir au moins $minLength caractères.';
  }

  @override
  String get authValidationPasswordConfirmationRequired =>
      'Confirmez votre mot de passe.';

  @override
  String get authValidationPasswordConfirmationMismatch =>
      'Les mots de passe ne correspondent pas.';
}
