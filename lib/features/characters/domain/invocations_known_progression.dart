/// Table de progression 5e standard des invocations occultistes CONNUES par
/// niveau de classe (Occultiste uniquement) — contenu fourni par le chef de
/// projet, vérifié via l'API Open5e/SRD, autoritaire : encodé tel quel, non
/// re-vérifié ici. Même convention que `SpellsKnownProgression` (voisine,
/// même chantier) : delta entre deux niveaux consécutifs, jamais négatif.
///
/// Étape "Invocations" de la montée de niveau
/// (`presentation/level_up_screen.dart`) — déclenchée à CHAQUE niveau où
/// [newInvocationsAt] est strictement positif (2, 5, 7, 9, 12, 15, 18),
/// indépendamment de la ligne `class_features.choice_type = 'invocation'` en
/// base (une seule, au niveau 2 — voir `domain/level_up_block_reason.dart`).
abstract final class InvocationsKnownProgression {
  static const Map<int, int> invocationsKnownByLevel = {
    1: 0,
    2: 2,
    3: 2,
    4: 2,
    5: 3,
    6: 3,
    7: 4,
    8: 4,
    9: 5,
    10: 5,
    11: 5,
    12: 6,
    13: 6,
    14: 6,
    15: 7,
    16: 7,
    17: 7,
    18: 8,
    19: 8,
    20: 8,
  };

  /// Nouvelles invocations connues en passant au niveau [level] —
  /// `table[level] - table[level - 1]` (`table[0]` implicitement 0). 0 si
  /// [level] n'est pas dans [invocationsKnownByLevel] (défensif, en dehors de
  /// 1-20).
  static int newInvocationsAt(int level) {
    final at = invocationsKnownByLevel[level];
    if (at == null) return 0;
    final previous = invocationsKnownByLevel[level - 1] ?? 0;
    return at - previous;
  }
}
