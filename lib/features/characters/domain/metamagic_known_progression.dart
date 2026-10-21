/// Table de progression 5e standard des options de Métamagie CONNUES par
/// niveau d'Ensorceleur — RAW confirmée (haute confiance, texte PHB 2024,
/// applicable sur ce point précis aux deux éditions) : 2 options connues au
/// niveau 3, 3 au niveau 10, 4 au niveau 17. Aptitude de **classe**
/// (`class_features.class_id` rempli — 3 lignes, une par palier, id=211/
/// 214/217, niveaux 3/10/17), PAS de sous-classe : contrairement aux
/// mécaniques de sous-classe voisines (`ArcaneShotsKnownProgression`/
/// `RunesKnownProgression`/`ManeuversKnownProgression`), le gating de
/// l'étape "Métamagie" (`presentation/providers/level_up_provider.dart`)
/// n'a besoin que du NOM DE CLASSE ('Ensorceleur'), jamais d'une sous-classe
/// candidate/déjà connue.
///
/// **Échange RAW-exact, même mécanique que l'Artificier
/// (`domain/infusions_known_progression.dart`, D93 du registre de dette
/// technique)** : "à chaque niveau d'Ensorceleur gagné, le personnage peut
/// remplacer UNE option de Métamagie déjà connue par une autre non connue"
/// (PHB) — à CHAQUE niveau d'Ensorceleur, pas seulement 3/10/17. Ne fait
/// donc volontairement pas partie de cette table (qui ne couvre que le
/// compteur "connues") — voir
/// `presentation/providers/level_up_provider.dart::canSwapMetamagic`, gating
/// indépendant de [newMetamagicOptionsAt].
///
/// **Divergence de contenu assumée, non corrigée ici** : les 3 lignes
/// `class_features` de ce chantier (niveaux 3/10/17) correspondent au texte
/// 2014 plutôt qu'au texte 2024 (qui accorde la première Métamagie plus tôt)
/// — câblé tel quel sur ces niveaux, décision explicite de Matthias de
/// différer la correction de contenu à un chantier séparé.
abstract final class MetamagicKnownProgression {
  static const String className = 'Ensorceleur';

  static const Map<int, int> metamagicKnownByLevel = {
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
    17: 4,
    18: 4,
    19: 4,
    20: 4,
  };

  /// Nouvelles options de Métamagie connues en passant au niveau [level] —
  /// `table[level] - table[level - 1]` (`table[0]` implicitement 0). 0 si
  /// [level] n'est pas dans [metamagicKnownByLevel] (défensif, en dehors de
  /// 1-20).
  static int newMetamagicOptionsAt(int level) {
    final at = metamagicKnownByLevel[level];
    if (at == null) return 0;
    final previous = metamagicKnownByLevel[level - 1] ?? 0;
    return at - previous;
  }
}
