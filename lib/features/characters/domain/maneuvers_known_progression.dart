/// Table de progression 5e standard des manœuvres CONNUES par niveau de
/// classe (Guerrier, Maître de guerre uniquement) — RAW confirmée par
/// l'agent `regles-dnd` : 3 manœuvres au niveau 3, +2 supplémentaires aux
/// niveaux 7/10/15 (jamais +1, contrairement aux disciplines élémentaires du
/// Moine). Même convention que `InvocationsKnownProgression`/
/// `ElementalDisciplinesKnownProgression` (voisines, même chantier) : delta
/// entre deux niveaux consécutifs, jamais négatif, jamais d'échange d'une
/// manœuvre déjà connue contre une autre (même simplification assumée que
/// les sorts/invocations/disciplines).
///
/// Étape "Manœuvres" de la montée de niveau
/// (`presentation/level_up_screen.dart`) — déclenchée à CHAQUE niveau où
/// [newManeuversAt] est strictement positif (3, 7, 10, 15), indépendamment du
/// fait qu'une seule ligne `class_features.choice_type = 'manoeuvre'` existe
/// en base (niveau 3 uniquement, id747 "Supériorité martiale") — voir
/// `domain/level_up_block_reason.dart`, même situation que les disciplines
/// élémentaires/invocations.
///
/// Distinct de `domain/superiority_dice_progression.dart` (réserve de dés de
/// supériorité) : les deux mécaniques du Maître de guerre progressent à des
/// niveaux différents (3/7/10/15 pour les manœuvres connues, 3/7/10/15/18
/// pour les dés — le niveau 18 change seulement la TAILLE du dé, jamais le
/// nombre de manœuvres connues) et ne doivent jamais être confondues.
abstract final class ManeuversKnownProgression {
  /// Seule sous-classe de Guerrier concernée par les manœuvres — voir
  /// `presentation/providers/level_up_provider.dart` (gating de
  /// `requiresManeuverSelection`, même garde-fou que le bug corrigé pour le
  /// Moine le 19/10/2026 : un Guerrier d'une AUTRE sous-classe ne doit jamais
  /// déclencher cette étape), même convention que
  /// `ElementalDisciplinesKnownProgression.subclassName`.
  static const String subclassName = 'Maître de guerre';

  static const Map<int, int> maneuversKnownByLevel = {
    1: 0,
    2: 0,
    3: 3,
    4: 3,
    5: 3,
    6: 3,
    7: 5,
    8: 5,
    9: 5,
    10: 7,
    11: 7,
    12: 7,
    13: 7,
    14: 7,
    15: 9,
    16: 9,
    17: 9,
    18: 9,
    19: 9,
    20: 9,
  };

  /// Nouvelles manœuvres connues en passant au niveau [level] —
  /// `table[level] - table[level - 1]` (`table[0]` implicitement 0). 0 si
  /// [level] n'est pas dans [maneuversKnownByLevel] (défensif, en dehors de
  /// 1-20).
  static int newManeuversAt(int level) {
    final at = maneuversKnownByLevel[level];
    if (at == null) return 0;
    final previous = maneuversKnownByLevel[level - 1] ?? 0;
    return at - previous;
  }
}
