/// Table de progression 5e standard des tirs arcaniques CONNUS par niveau de
/// classe (Guerrier, Archer arcanique uniquement) — RAW confirmée par l'agent
/// `regles-dnd` : 2 tirs arcaniques au niveau 3, +1 supplémentaire aux
/// niveaux 7, 10, 15 et 18 (6 au total à 18, jamais +2 d'un coup). Même
/// convention que `ManeuversKnownProgression`/
/// `ElementalDisciplinesKnownProgression` (voisines, même chantier) : delta
/// entre deux niveaux consécutifs, jamais négatif, jamais d'échange d'un tir
/// arcanique déjà connu contre un autre (même simplification assumée que les
/// sorts/invocations/disciplines/manœuvres).
///
/// Étape "Tirs arcaniques" de la montée de niveau
/// (`presentation/level_up_screen.dart`) — déclenchée à CHAQUE niveau où
/// [newArcaneShotsAt] est strictement positif (3, 7, 10, 15, 18),
/// indépendamment du fait qu'une seule ligne
/// `class_features.choice_type = 'tir_arcanique'` existe en base (niveau 3
/// uniquement, id=95 "Tir arcanique") — voir
/// `domain/level_up_block_reason.dart`, même situation que les manœuvres/
/// disciplines élémentaires/invocations.
///
/// Les 8 options du catalogue (`class_options`, `option_type =
/// 'tir_arcanique'`, `subclass_id` de l'Archer arcanique) ont toutes
/// `min_level = 3` (confirmé par `regles-dnd`) : n'importe laquelle est
/// choisissable dès le premier palier, ce filtre n'exclut donc jamais rien
/// par le niveau en pratique — seule l'exclusion "déjà connu" est réellement
/// discriminante (même remarque que `ManeuversKnownProgression`).
abstract final class ArcaneShotsKnownProgression {
  /// Seule sous-classe de Guerrier concernée par les tirs arcaniques — voir
  /// `presentation/providers/level_up_provider.dart` (gating de
  /// `requiresArcaneShotSelection`, même garde-fou que le bug corrigé pour le
  /// Moine/le Maître de guerre : un Guerrier d'une AUTRE sous-classe (Maître
  /// de guerre, Chevalier runique, Champion...) ne doit jamais déclencher
  /// cette étape), même convention que
  /// `ElementalDisciplinesKnownProgression.subclassName`.
  static const String subclassName = 'Archer arcanique';

  static const Map<int, int> arcaneShotsKnownByLevel = {
    1: 0,
    2: 0,
    3: 2,
    4: 2,
    5: 2,
    6: 2,
    7: 3,
    8: 3,
    9: 3,
    10: 4,
    11: 4,
    12: 4,
    13: 4,
    14: 4,
    15: 5,
    16: 5,
    17: 5,
    18: 6,
    19: 6,
    20: 6,
  };

  /// Nouveaux tirs arcaniques connus en passant au niveau [level] —
  /// `table[level] - table[level - 1]` (`table[0]` implicitement 0). 0 si
  /// [level] n'est pas dans [arcaneShotsKnownByLevel] (défensif, en dehors de
  /// 1-20).
  static int newArcaneShotsAt(int level) {
    final at = arcaneShotsKnownByLevel[level];
    if (at == null) return 0;
    final previous = arcaneShotsKnownByLevel[level - 1] ?? 0;
    return at - previous;
  }
}
