/// Logique pure d'extraction de la ligne "Bourse (N po)" de
/// `BackgroundOption.equipment` (tableau plat de chaînes de texte libre,
/// `backgrounds.equipment` jsonb — voir le commentaire de classe de
/// `domain/background_option.dart`), utilisée par l'étape 7/9 "Équipement de
/// départ".
///
/// Vérifié contre le contenu peuplé (13 historiques) : chaque historique
/// porte exactement une ligne de ce format, ex. `"Bourse (15 po)"` — voir la
/// consigne d'origine. Extrait dans un fichier dédié (plutôt que
/// `BackgroundRowMapper`, qui mappe des lignes brutes PostgREST) : cette
/// logique s'applique à un [BackgroundOption] déjà résolu, pas à une ligne
/// brute, et reste testable sans réseau.
abstract final class BackgroundEquipmentParser {
  static final RegExp _startingGoldPattern = RegExp(r'^Bourse \((\d+) po\)$');

  /// Montant de "Bourse (N po)" dans [equipment], `null` si aucune ligne de
  /// ce format n'est présente (ne devrait normalement jamais arriver pour le
  /// contenu peuplé actuel, voir le commentaire de classe, mais reste sûr
  /// dans ce cas plutôt que de crasher — l'appelant retombe alors sur 0 po,
  /// voir `presentation/providers/character_creation_providers.dart`).
  static int? extractStartingGold(List<String> equipment) {
    for (final line in equipment) {
      final match = _startingGoldPattern.firstMatch(line);
      if (match != null) {
        return int.parse(match.group(1)!);
      }
    }
    return null;
  }

  /// [equipment] sans la ligne "Bourse (N po)" (retirée de la liste affichée
  /// par l'onglet "Historique", voir la consigne d'origine) — l'ordre des
  /// lignes restantes est conservé.
  static List<String> withoutStartingGoldLine(List<String> equipment) {
    return equipment
        .where((line) => !_startingGoldPattern.hasMatch(line))
        .toList();
  }
}
