/// Table de progression 5e standard des disciplines élémentaires CONNUES par
/// niveau de classe (Moine, Voie des quatre éléments uniquement) — RAW
/// confirmée par l'agent `regles-dnd` : 2 disciplines au niveau 3, +1
/// supplémentaire (cumulative, jamais remplacée) aux niveaux 6, 11 et 17.
/// Même convention que `InvocationsKnownProgression`/`SpellsKnownProgression`
/// (voisines, même chantier) : delta entre deux niveaux consécutifs, jamais
/// négatif.
///
/// Étape "Disciplines élémentaires" de la montée de niveau
/// (`presentation/level_up_screen.dart`) — déclenchée à CHAQUE niveau où
/// [newDisciplinesAt] est strictement positif (3, 6, 11, 17), indépendamment
/// du nombre de lignes `class_features.choice_type = 'discipline_elementaire'`
/// réellement présentes en base (potentiellement une seule, au niveau 3 —
/// voir `domain/level_up_block_reason.dart`, même situation que les
/// invocations occultistes).
abstract final class ElementalDisciplinesKnownProgression {
  /// Seule sous-classe de Moine concernée par les disciplines élémentaires —
  /// voir `presentation/providers/level_up_provider.dart` (gating de
  /// `requiresElementalDisciplineSelection`, bug corrigé le 19/10/2026 : un
  /// Moine d'une AUTRE sous-classe ne doit jamais déclencher cette étape),
  /// même convention que `PatronExtendedSpells.warlockClassName`.
  static const String subclassName = 'Voie des quatre éléments';

  static const Map<int, int> disciplinesKnownByLevel = {
    1: 0,
    2: 0,
    3: 2,
    4: 2,
    5: 2,
    6: 3,
    7: 3,
    8: 3,
    9: 3,
    10: 3,
    11: 4,
    12: 4,
    13: 4,
    14: 4,
    15: 4,
    16: 4,
    17: 5,
    18: 5,
    19: 5,
    20: 5,
  };

  /// Nouvelles disciplines élémentaires connues en passant au niveau [level]
  /// — `table[level] - table[level - 1]` (`table[0]` implicitement 0). 0 si
  /// [level] n'est pas dans [disciplinesKnownByLevel] (défensif, en dehors de
  /// 1-20).
  static int newDisciplinesAt(int level) {
    final at = disciplinesKnownByLevel[level];
    if (at == null) return 0;
    final previous = disciplinesKnownByLevel[level - 1] ?? 0;
    return at - previous;
  }
}
