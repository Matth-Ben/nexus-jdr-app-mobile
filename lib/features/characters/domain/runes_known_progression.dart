/// Table de progression 5e standard des runes CONNUES par niveau de classe
/// (Guerrier, Chevalier runique uniquement) — RAW confirmée par l'agent
/// `regles-dnd` : 2 runes au niveau 3, +1 au niveau **10** (PAS 7,
/// contrairement aux manœuvres/tirs arcaniques du Guerrier), puis TOUTES les
/// runes restantes au niveau **18** ("Maître des runes", capstone de la
/// sous-classe). Même convention que `ManeuversKnownProgression`/
/// `ArcaneShotsKnownProgression` (voisines, même chantier) : delta entre deux
/// niveaux consécutifs, jamais négatif, jamais d'échange d'une rune déjà
/// connue contre une autre (même simplification assumée que les manœuvres/
/// tirs arcaniques — si une mention RAW contraire apparaît, remonter au chef
/// de projet plutôt que de trancher seul, mais cette simplification
/// s'applique par défaut tant qu'elle n'a pas été infirmée).
///
/// **Niveau 18 ("Maître des runes")** : traité comme n'importe quel autre
/// palier de delta positif plutôt que comme un cas "automatique" à part — à
/// ce niveau, le delta RAW (3 : 6 runes au total - 3 déjà connues) est
/// systématiquement égal au nombre de runes encore disponibles au catalogue
/// (les 6 runes RAW du jeu, moins les 3 déjà connues), donc le quota EFFECTIF
/// de l'étape "Runes" (voir `presentation/level_up_screen.dart`) finit par
/// forcer la sélection de TOUTES les runes restantes — même résultat RAW
/// qu'un octroi automatique, sans code dédié supplémentaire. Documenté ici
/// explicitement : ne pas (re)introduire un octroi automatique silencieux
/// pour ce niveau, le patron delta+quota existant suffit.
///
/// Étape "Runes" de la montée de niveau (`presentation/level_up_screen.dart`)
/// — déclenchée à CHAQUE niveau où [newRunesAt] est strictement positif (3,
/// 10, 18), indépendamment du fait qu'une seule ligne
/// `class_features.choice_type = 'rune'` existe en base (niveau 3
/// uniquement, id=97 "Gravure runique") — voir
/// `domain/level_up_block_reason.dart`, même situation que les manœuvres/
/// tirs arcaniques/disciplines élémentaires/invocations.
///
/// Les 6 runes du catalogue (`class_options`, `option_type = 'rune'`,
/// `subclass_id` du Chevalier runique) ont `min_level` ∈ {3, 7} — ce
/// `min_level = 7` sur 2 d'entre elles est un PRÉREQUIS propre à ces 2 runes
/// précises (confirmé par `regles-dnd`), pas un palier de gain
/// supplémentaire : elles ne deviennent choisissables qu'au palier de gain
/// SUIVANT (niveau 10), jamais dès le niveau 7 lui-même (aucun gain à ce
/// niveau, voir [newRunesAt]). Le filtre `min_level <= targetLevel` déjà
/// appliqué côté requête (`CharacterRepository.fetchAvailableRunes`, même
/// filtre que `fetchAvailableManeuvers`) suffit à matérialiser ce
/// comportement sans logique dédiée : au niveau 3, seules les 4 runes
/// `min_level = 3` sont candidates ; au niveau 10 (et au-delà), les 6 runes
/// le sont.
abstract final class RunesKnownProgression {
  /// Seule sous-classe de Guerrier concernée par les runes — voir
  /// `presentation/providers/level_up_provider.dart` (gating de
  /// `requiresRuneSelection`, même garde-fou que le bug corrigé pour le
  /// Moine/le Maître de guerre : un Guerrier d'une AUTRE sous-classe
  /// (Maître de guerre, Archer arcanique, Champion...) ne doit jamais
  /// déclencher cette étape), même convention que
  /// `ArcaneShotsKnownProgression.subclassName`.
  static const String subclassName = 'Chevalier runique';

  static const Map<int, int> runesKnownByLevel = {
    1: 0,
    2: 0,
    3: 2,
    4: 2,
    5: 2,
    6: 2,
    7: 2,
    8: 2,
    9: 2,
    10: 3,
    11: 3,
    12: 3,
    13: 3,
    14: 3,
    15: 3,
    16: 3,
    17: 3,
    18: 6,
    19: 6,
    20: 6,
  };

  /// Nouvelles runes connues en passant au niveau [level] —
  /// `table[level] - table[level - 1]` (`table[0]` implicitement 0). 0 si
  /// [level] n'est pas dans [runesKnownByLevel] (défensif, en dehors de
  /// 1-20).
  static int newRunesAt(int level) {
    final at = runesKnownByLevel[level];
    if (at == null) return 0;
    final previous = runesKnownByLevel[level - 1] ?? 0;
    return at - previous;
  }
}
