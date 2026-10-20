/// Table de progression 5e standard des infusions CONNUES par niveau
/// d'Artificier — RAW confirmée (haute confiance) par l'agent `regles-dnd` :
/// 4 infusions connues au niveau 2, 6 au niveau 6, 8 au niveau 10, 10 au
/// niveau 14, 12 au niveau 18. Aptitude de **classe** (`class_features.id =
/// 1296`, "Infusion d'objets", niveau 2), PAS de sous-classe — contrairement
/// aux 3 autres mécaniques voisines de ce chantier
/// (`ArcaneShotsKnownProgression`/`RunesKnownProgression`/
/// `ManeuversKnownProgression`, toutes gatées par une sous-classe de
/// Guerrier/Moine), le gating de l'étape "Infusions"
/// (`presentation/providers/level_up_provider.dart`) n'a donc besoin que du
/// NOM DE CLASSE ('Artificier'), jamais d'un nom de sous-classe candidate/
/// déjà connue.
///
/// **RAW 5e : DEUX compteurs indépendants**, à ne jamais confondre :
/// - "Infusions connues" (cette classe, [infusionsKnownByLevel]) : combien de
///   recettes d'infusion l'Artificier connaît, point de départ de l'étape
///   "Infusions" de la montée de niveau (choix de nouvelles infusions,
///   delta de cette table).
/// - "Objets infusés simultanément" (RAW : 2/3/4/5/6 aux mêmes paliers
///   2/6/10/14/18) : combien d'objets magiques réels peuvent porter une
///   infusion active en même temps — mécanique de GESTION D'OBJETS (quel
///   objet réel du personnage porte quelle infusion), pas de progression
///   "connue". **Hors périmètre de ce chantier** : l'app ne modélise pas
///   encore d'objet magique infusé individuellement dans l'inventaire (aucun
///   champ "infusion active" sur une ligne d'inventaire, vérifié —
///   `domain/inventory_catalog_item.dart` et les modèles d'inventaire de
///   fiche n'ont aucune notion d'infusion). Décision assumée par cet agent
///   plutôt qu'inventée en silence : la sélection d'infusions CONNUES n'est
///   donc jamais plafonnée par ce second compteur ici — à documenter comme
///   dette fonctionnelle si une future fonctionnalité "assigner une infusion
///   à un objet" voit le jour (voir `docs/dette-technique.md`).
///
/// **Différence assumée avec les 3 mécaniques voisines (tirs arcaniques/
/// runes/manœuvres)** : contrairement à elles, l'échange d'une infusion
/// CONNUE contre une autre est RAW-exact et implémenté (décision de
/// Matthias, voir `docs/dette-technique.md` et
/// `presentation/level_up_screen.dart::_buildInfusionsStep`) : "À chaque
/// niveau où il gagne un niveau d'Artificier, le personnage peut aussi
/// remplacer une des infusions qu'il connaît par une autre" (PHB/TCE) — à
/// chaque niveau d'Artificier, pas seulement aux paliers où
/// [newInfusionsAt] est strictement positif. Ne fait donc volontairement pas
/// partie de cette table de progression (qui ne couvre que le compteur
/// "connues", jamais l'échange) — voir
/// `presentation/providers/level_up_provider.dart::requiresInfusionSwap`
/// pour le gating de cette capacité, indépendant de [newInfusionsAt].
abstract final class InfusionsKnownProgression {
  static const String className = 'Artificier';

  static const Map<int, int> infusionsKnownByLevel = {
    1: 0,
    2: 4,
    3: 4,
    4: 4,
    5: 4,
    6: 6,
    7: 6,
    8: 6,
    9: 6,
    10: 8,
    11: 8,
    12: 8,
    13: 8,
    14: 10,
    15: 10,
    16: 10,
    17: 10,
    18: 12,
    19: 12,
    20: 12,
  };

  /// Nouvelles infusions connues en passant au niveau [level] —
  /// `table[level] - table[level - 1]` (`table[0]` implicitement 0). 0 si
  /// [level] n'est pas dans [infusionsKnownByLevel] (défensif, en dehors de
  /// 1-20).
  static int newInfusionsAt(int level) {
    final at = infusionsKnownByLevel[level];
    if (at == null) return 0;
    final previous = infusionsKnownByLevel[level - 1] ?? 0;
    return at - previous;
  }
}
