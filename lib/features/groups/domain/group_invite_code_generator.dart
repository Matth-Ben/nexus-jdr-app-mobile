import 'dart:math';

/// Génère un code d'invitation de groupe côté client, pour "Régénérer le
/// code" (l'écriture passe directement par `UPDATE groups`, pas par une edge
/// function — voir `data/group_repository.dart::regenerateInviteCode`).
///
/// Même alphabet que le reste du projet ([_alphabet], 8 caractères) — voir
/// la spec de la tâche "Système de groupe".
abstract final class GroupInviteCodeGenerator {
  static const String _alphabet = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
  static const int _length = 8;

  static String generate({Random? random}) {
    final rng = random ?? Random.secure();
    return List.generate(
      _length,
      (_) => _alphabet[rng.nextInt(_alphabet.length)],
    ).join();
  }
}
