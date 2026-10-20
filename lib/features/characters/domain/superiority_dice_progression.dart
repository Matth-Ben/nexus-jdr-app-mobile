/// Table de progression 5e standard de la réserve de dés de supériorité du
/// Guerrier Maître de guerre (nombre de dés ET taille du dé, par niveau de
/// classe) — RAW confirmée par l'agent `regles-dnd` :
///
/// | Niveau | Dés | Taille |
/// |---|---|---|
/// | 3  | 4 | d8  |
/// | 7  | 5 | d8  |
/// | 10 | 5 | d10 |
/// | 15 | 6 | d10 |
/// | 18 | 6 | d12 |
///
/// **Jamais en base** (confirmé par `regles-dnd`) : `class_features.id = 747`
/// ("Supériorité martiale", niveau 3) porte `uses_per_rest =
/// {amount: 4, rest_type: 'repos_court'}`, RAW-exact seulement pour les
/// niveaux 3 à 6 — `uses_per_rest` est une colonne statique, incapable de
/// représenter une valeur qui change avec le niveau du personnage (et
/// `amount` seul ne peut de toute façon pas porter la taille du dé). Les 3
/// aptitudes suivantes (id748 "Observation de l'ennemi" niv.7, id749
/// "Supériorité martiale améliorée" niv.10, id750 "Implacable" niv.15) sont
/// purement passives côté base (`uses_per_rest` nul) : leur TEXTE RAW porte
/// l'information (nombre/taille) de façon informative, mais aucune ne
/// représente une ligne de ressource séparée — y compris le palier 18, qui
/// n'a volontairement AUCUNE ligne `class_features` dédiée (seule la taille
/// du dé change à ce niveau, déjà couverte par le texte RAW de id749).
///
/// Cette table remplace donc dynamiquement, à l'affichage (carte "APTITUDES
/// DE CLASSE" de l'onglet Compétences) ET à la recharge (repos court/long,
/// `character_feature_uses.uses_remaining`), la valeur statique de
/// `uses_per_rest->>'amount'` pour la seule aptitude dont
/// `class_features.choice_type == 'manoeuvre'` — voir
/// `data/class_feature_row_mapper.dart::ClassFeatureRowMapper.effectiveUsesMax`
/// pour le point d'application unique de cet override, partagé par les deux
/// chemins de lecture/écriture.
///
/// **Choix d'architecture (override ciblé, pas un mécanisme générique)** :
/// cet override est délibérément spécifique à cette aptitude précise
/// (repérée par son `choice_type`, globalement unique dans toute la base à
/// ce jour — aucune autre sous-classe du jeu n'utilise `'manoeuvre'`),
/// jamais un mécanisme générique "total à usage limité qui scale avec le
/// niveau". Généraliser aurait demandé une vraie colonne/table de
/// progression par niveau côté base (hors périmètre : aucune migration SQL
/// n'est de ce ressort, voir `CLAUDE.md`), ou un registre Dart `choice_type
/// -> fonction de niveau` pour toutes les aptitudes futures qui auraient le
/// même besoin — non justifié pour une seule aptitude à ce jour. **Le
/// Barbare a une mécanique de rage structurellement similaire** (nombre de
/// rages RAW : 2 aux niveaux 1-2, 3 aux niveaux 3-5, 4 aux niveaux 6-11, 5
/// aux niveaux 12-16, 6 aux niveaux 17-19, illimité au niveau 20) qui
/// pourrait souffrir du même défaut si `class_features` ne porte qu'une
/// seule ligne "Rage" avec un `uses_per_rest->>'amount'` statique — **non
/// vérifié dans cette tâche** (lecture directe de la base hors périmètre de
/// cet agent, voir `docs/dette-technique.md`) : à confirmer par
/// `dev-backend-supabase`/le chef de projet et à consigner comme nouvelle
/// entrée de dette si le même défaut est présent, plutôt que généralisé ici
/// sans confirmation.
abstract final class SuperiorityDiceProgression {
  /// Seule sous-classe de Guerrier concernée — voir
  /// `domain/maneuvers_known_progression.dart::ManeuversKnownProgression
  /// .subclassName` (même convention, même chantier).
  static const String subclassName = 'Maître de guerre';

  /// `class_features.choice_type` qui identifie SANS AMBIGUÏTÉ "Supériorité
  /// martiale" dans toute la base (valeur globalement unique à ce jour,
  /// confirmée par `regles-dnd`) — repère à la fois la ligne candidate à
  /// l'étape "Manœuvres" (voir `domain/level_up_choice_kind.dart`) et celle
  /// dont le total de dés doit être remplacé dynamiquement (voir
  /// `ClassFeatureRowMapper.effectiveUsesMax`), sans jamais dépendre d'un
  /// `class_features.id` câblé en dur ni du nom de la sous-classe porteuse.
  static const String choiceType = 'manoeuvre';

  static const Map<int, int> diceCountByLevel = {
    1: 0,
    2: 0,
    3: 4,
    4: 4,
    5: 4,
    6: 4,
    7: 5,
    8: 5,
    9: 5,
    10: 5,
    11: 5,
    12: 5,
    13: 5,
    14: 5,
    15: 6,
    16: 6,
    17: 6,
    18: 6,
    19: 6,
    20: 6,
  };

  /// Taille du dé de supériorité (`8`/`10`/`12`) — jamais consommée par
  /// l'écriture `character_feature_uses` (qui ne porte qu'un décompte
  /// d'usages, pas une taille de dé) ni affichée séparément à ce jour : le
  /// texte RAW de "Supériorité martiale améliorée" (id749) porte déjà cette
  /// information pour les joueurs. Exposée ici pour que la table RAW
  /// complète (dés ET taille) vive en un seul endroit, prête à être câblée
  /// si un futur écran en a besoin (ex. un helper de jet de dé).
  static const Map<int, int> diceSizeByLevel = {
    1: 0,
    2: 0,
    3: 8,
    4: 8,
    5: 8,
    6: 8,
    7: 8,
    8: 8,
    9: 8,
    10: 10,
    11: 10,
    12: 10,
    13: 10,
    14: 10,
    15: 10,
    16: 10,
    17: 10,
    18: 12,
    19: 12,
    20: 12,
  };

  /// Nombre de dés de supériorité au niveau [level] (total, jamais un
  /// delta — contrairement à `ManeuversKnownProgression.newManeuversAt`,
  /// cette mécanique n'a jamais besoin d'un delta : elle ne déclenche aucune
  /// étape de choix, seulement un override d'affichage/recharge). 0 si
  /// [level] n'est pas dans [diceCountByLevel] (défensif, en dehors de
  /// 1-20).
  static int diceCountAt(int level) => diceCountByLevel[level] ?? 0;

  /// Taille du dé de supériorité au niveau [level] (`8`/`10`/`12`), 0 si
  /// [level] n'est pas dans [diceSizeByLevel] (défensif).
  static int diceSizeAt(int level) => diceSizeByLevel[level] ?? 0;
}
