/// Règles de validation du formulaire de connexion/inscription
/// (`presentation/login_screen.dart`), isolées ici pour être testées
/// unitairement sans monter de widget ni appeler Supabase.
///
/// Chaque validateur retourne `null` si la valeur est valide, ou un message
/// d'erreur (déjà en français, prêt pour l'affichage) sinon — signature
/// compatible avec `FormFieldValidator<String>`.
abstract final class AuthValidators {
  /// Longueur minimale acceptée par Supabase Auth pour un mot de passe.
  static const int minPasswordLength = 6;

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Saisissez votre adresse e-mail.';
    }
    if (!_emailPattern.hasMatch(trimmed)) {
      return 'Adresse e-mail invalide.';
    }
    return null;
  }

  static String? password(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Saisissez votre mot de passe.';
    }
    if (password.length < minPasswordLength) {
      return 'Le mot de passe doit contenir au moins '
          '$minPasswordLength caractères.';
    }
    return null;
  }

  static String? passwordConfirmation(String? value, String password) {
    final confirmation = value ?? '';
    if (confirmation.isEmpty) {
      return 'Confirmez votre mot de passe.';
    }
    if (confirmation != password) {
      return 'Les mots de passe ne correspondent pas.';
    }
    return null;
  }
}
