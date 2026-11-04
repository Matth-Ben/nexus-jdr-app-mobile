import '../../../l10n/app_localizations.dart';

/// Règles de validation du formulaire de connexion/inscription
/// (`presentation/login_screen.dart`), isolées ici pour être testées
/// unitairement sans monter de widget ni appeler Supabase.
///
/// **Choix architectural** (chantier "traduction de l'app" Phase B, lot
/// "Auth") : cette classe vit dans `domain/`, sans `BuildContext`. La
/// solution standard Flutter ("passer `AppLocalizations` en paramètre
/// jusqu'au point de production du message") s'applique ici — mais, à la
/// différence de `data/auth_error_mapper.dart`/`AuthErrorCode` (voir sa doc
/// de classe), ce n'est pas un paramètre *requis* : cette classe a aussi
/// des appelants hors du périmètre de ce lot
/// (`features/profile/presentation/widgets/change_password_sheet.dart`,
/// `change_email_sheet.dart`), qui passent chaque validateur directement en
/// référence à `TextFormField.validator` (`validator: AuthValidators
/// .password`, sans fermeture) et qu'il n'était pas question de toucher
/// pour ce lot.
///
/// [l10n] est donc un paramètre **optionnel** : fourni (par
/// `login_screen.dart`/`forgot_password_dialog.dart`, seuls appelants
/// migrés à ce stade), chaque message est résolu via `AppLocalizations` ;
/// omis (appelants pas encore migrés), chaque validateur retombe sur son
/// message français d'origine, inchangé, pour que ces écrans continuent de
/// fonctionner sans aucune modification. **Précédent pour les prochains
/// lots** : chaque futur lot qui migre un écran utilisant `AuthValidators`
/// doit se contenter de passer [l10n] à l'appel existant (`validator:
/// (value) => AuthValidators.password(value, l10n)`) — une fois plus aucun
/// appelant n'omettant [l10n], les messages français en dur ci-dessous
/// pourront être retirés.
abstract final class AuthValidators {
  /// Longueur minimale acceptée par Supabase Auth pour un mot de passe.
  static const int minPasswordLength = 6;

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value, [AppLocalizations? l10n]) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return l10n?.authValidationEmailRequired ??
          'Saisissez votre adresse e-mail.';
    }
    if (!_emailPattern.hasMatch(trimmed)) {
      return l10n?.authValidationEmailInvalid ?? 'Adresse e-mail invalide.';
    }
    return null;
  }

  static String? password(String? value, [AppLocalizations? l10n]) {
    final password = value ?? '';
    if (password.isEmpty) {
      return l10n?.authValidationPasswordRequired ??
          'Saisissez votre mot de passe.';
    }
    if (password.length < minPasswordLength) {
      return l10n?.authValidationPasswordTooShort(minPasswordLength) ??
          'Le mot de passe doit contenir au moins '
              '$minPasswordLength caractères.';
    }
    return null;
  }

  static String? passwordConfirmation(
    String? value,
    String password, [
    AppLocalizations? l10n,
  ]) {
    final confirmation = value ?? '';
    if (confirmation.isEmpty) {
      return l10n?.authValidationPasswordConfirmationRequired ??
          'Confirmez votre mot de passe.';
    }
    if (confirmation != password) {
      return l10n?.authValidationPasswordConfirmationMismatch ??
          'Les mots de passe ne correspondent pas.';
    }
    return null;
  }
}
