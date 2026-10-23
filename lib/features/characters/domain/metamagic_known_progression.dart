/// Table de progression 5e standard des options de Métamagie CONNUES par
/// niveau d'Ensorceleur — RAW confirmée par source primaire (PHB) : en
/// édition 2014, 2 options connues au niveau 3, 3 au niveau 10, 4 au niveau
/// 17 (voir [metamagicKnownByLevel2014]) ; en édition 2024, la première
/// Métamagie est accordée plus tôt et la progression est cumulative
/// 2/4/6 aux niveaux 2/10/17 (voir [metamagicKnownByLevel2024]) —
/// [newMetamagicOptionsAt] est désormais sensible à `edition` (chantier
/// "choix d'édition 2014/2024 par personnage",
/// `character_creation/domain/character_creation_draft.dart::edition`) :
/// avant ce chantier, seule la table 2014 était câblée, avec une divergence
/// RAW documentée et assumée (voir l'historique git de ce fichier) —
/// désormais résolue. Aptitude de **classe** (`class_features.class_id`
/// rempli — 3 lignes, une par palier, id=211/214/217, niveaux 3/10/17 pour
/// 2014), PAS de sous-classe : contrairement aux mécaniques de sous-classe
/// voisines (`ArcaneShotsKnownProgression`/`RunesKnownProgression`/
/// `ManeuversKnownProgression`), le gating de l'étape "Métamagie"
/// (`presentation/providers/level_up_provider.dart`) n'a besoin que du NOM
/// DE CLASSE ('Ensorceleur') et de [edition], jamais d'une sous-classe
/// candidate/déjà connue.
///
/// **Échange RAW-exact, même mécanique que l'Artificier
/// (`domain/infusions_known_progression.dart`, D93 du registre de dette
/// technique)** : "à chaque niveau d'Ensorceleur gagné, le personnage peut
/// remplacer UNE option de Métamagie déjà connue par une autre non connue"
/// (PHB) — à CHAQUE niveau d'Ensorceleur, pas seulement aux paliers de
/// cette table. Ne fait donc volontairement pas partie de cette table (qui
/// ne couvre que le compteur "connues") — voir
/// `presentation/providers/level_up_provider.dart::canSwapMetamagic`, gating
/// indépendant de [newMetamagicOptionsAt].
abstract final class MetamagicKnownProgression {
  static const String className = 'Ensorceleur';

  /// Table de progression en édition 2014 (défaut historique de ce
  /// fichier) — voir la doc de classe.
  static const Map<int, int> metamagicKnownByLevel2014 = {
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

  /// Table de progression en édition 2024 — voir la doc de classe. Le texte
  /// 2024 avance le premier palier d'un niveau par rapport à 2014 (3→2) et
  /// augmente les quotas cumulatifs (2/3/4 → 2/4/6).
  static const Map<int, int> metamagicKnownByLevel2024 = {
    1: 0,
    2: 2,
    3: 2,
    4: 2,
    5: 2,
    6: 2,
    7: 2,
    8: 2,
    9: 2,
    10: 4,
    11: 4,
    12: 4,
    13: 4,
    14: 4,
    15: 4,
    16: 4,
    17: 6,
    18: 6,
    19: 6,
    20: 6,
  };

  /// Nouvelles options de Métamagie connues en passant au niveau [level],
  /// pour l'édition [edition] (`'2014'` par défaut, même convention que
  /// `CharacterDetail.edition`) — `table[level] - table[level - 1]`
  /// (`table[0]` implicitement 0), table choisie selon [edition] (voir
  /// [metamagicKnownByLevel2014]/[metamagicKnownByLevel2024]). 0 si [level]
  /// n'est pas dans la table (défensif, en dehors de 1-20).
  static int newMetamagicOptionsAt(int level, {String edition = '2014'}) {
    final table = edition == '2024'
        ? metamagicKnownByLevel2024
        : metamagicKnownByLevel2014;
    final at = table[level];
    if (at == null) return 0;
    final previous = table[level - 1] ?? 0;
    return at - previous;
  }
}
