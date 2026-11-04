// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get profileLanguageMenuEntry => 'Language';

  @override
  String get profileLanguageScreenTitle => 'LANGUAGE';

  @override
  String get profileLanguagePhoneOption => 'Phone language';

  @override
  String get profileLanguagePhoneOptionSubtitle => 'Langue du téléphone';

  @override
  String get profileLanguagePhoneOptionDetail =>
      'Suit la langue de l\'appareil (FR/EN) ; repli sur le français si l\'appareil utilise une autre langue. / Follows the device\'s language (FR/EN); falls back to French otherwise.';

  @override
  String get profileLanguageFrenchOption => 'Français';

  @override
  String get profileLanguageEnglishOption => 'English';

  @override
  String get profileLanguageSaveError =>
      'Couldn\'t save this setting. Please try again.';

  @override
  String get authLoginBrandTitle => 'NEXUS JDR';

  @override
  String get authLoginTagline => 'The adventurers\' registry';

  @override
  String get authLoginSharedAccountNotice =>
      'Same account as the Histoires app';

  @override
  String get authLoginCardTitleSignUp => 'CREATE AN ACCOUNT';

  @override
  String get authLoginCardTitleLogin => 'ENTER THE TAVERN';

  @override
  String get authLoginEmailLabel => 'Email address';

  @override
  String get authLoginEmailHint => 'name@example.com';

  @override
  String get authLoginPasswordLabel => 'Password';

  @override
  String get authLoginPasswordHint => '••••••••';

  @override
  String get authLoginForgotPasswordLink => 'Forgot password?';

  @override
  String get authLoginConfirmPasswordLabel => 'Confirm password';

  @override
  String get authLoginPseudoLabel => 'Display name';

  @override
  String get authLoginPseudoHint => 'What would you like to be called?';

  @override
  String get authLoginPseudoHelper =>
      'Optional — you can change this later in your profile.';

  @override
  String get authLoginSubmitSignUp => 'Create account';

  @override
  String get authLoginSubmitLogin => 'Enter';

  @override
  String get authLoginOrDivider => 'OR';

  @override
  String get authLoginContinueWithApple => 'Continue with Apple';

  @override
  String get authLoginContinueWithGoogle => 'Continue with Google';

  @override
  String get authLoginSwitchModePromptLogin => 'Already have an account? ';

  @override
  String get authLoginSwitchModePromptSignUp => 'Don\'t have an account? ';

  @override
  String get authLoginSwitchModeActionLogin => 'Log in';

  @override
  String get authLoginSwitchModeActionSignUp => 'Create an account';

  @override
  String get authLoginSignUpConfirmationTitle => 'CHECK YOUR EMAIL';

  @override
  String authLoginSignUpConfirmationBody(String email) {
    return 'A confirmation email has just been sent to $email. Click the link it contains to activate your account.';
  }

  @override
  String get authLoginBackToLogin => 'Back to login';

  @override
  String get authForgotPasswordTitle => 'Forgot your password?';

  @override
  String get authForgotPasswordDescription =>
      'Enter your email address: we\'ll send you a link to set a new password.';

  @override
  String get authForgotPasswordEmailHint => 'name@example.com';

  @override
  String get authForgotPasswordCancel => 'Cancel';

  @override
  String get authForgotPasswordSubmit => 'Send link';

  @override
  String get authForgotPasswordNeutralMessage =>
      'If an account exists with this email, a reset link has just been sent.';

  @override
  String get authErrorInvalidCredentials => 'Incorrect email or password.';

  @override
  String get authErrorEmailAlreadyExists =>
      'An account already exists with this email address.';

  @override
  String authErrorWeakPassword(int minLength) {
    return 'Password must be at least $minLength characters long.';
  }

  @override
  String get authErrorEmailNotConfirmed =>
      'Confirm your email address before signing in (check your inbox).';

  @override
  String get authErrorInvalidEmail => 'Invalid email address.';

  @override
  String get authErrorTooManyRequests =>
      'Too many attempts. Please try again in a few moments.';

  @override
  String get authErrorNetwork =>
      'Couldn\'t reach the server. Check your internet connection and try again.';

  @override
  String get authErrorBrowserLaunchFailed =>
      'Couldn\'t open the browser to continue with Google. Please try again.';

  @override
  String get authErrorUnexpected =>
      'An unexpected error occurred. Please try again.';

  @override
  String get authValidationEmailRequired => 'Enter your email address.';

  @override
  String get authValidationEmailInvalid => 'Invalid email address.';

  @override
  String get authValidationPasswordRequired => 'Enter your password.';

  @override
  String authValidationPasswordTooShort(int minLength) {
    return 'Password must be at least $minLength characters long.';
  }

  @override
  String get authValidationPasswordConfirmationRequired =>
      'Confirm your password.';

  @override
  String get authValidationPasswordConfirmationMismatch =>
      'Passwords don\'t match.';
}
