/// Exceptions à la règle « premier `NdM` de la description » de
/// `SpellDamageDiceExtractor`, par nom français du sort (`translations`,
/// tels qu'en production au 25/11/2026).
///
/// Source : `docs/spec-pastille-degats-sorts.md` (table vérifiée une à une
/// par `regles-dnd` sur les textes de production après la PR DeepCore #63),
/// décisions 85, 86, 88 et 89 de Matthias du 25/11/2026
/// (`docs/api-refonte/00-decisions-et-vision.md`) :
/// - 85 : liste explicite d'exceptions côté Nexus, aucun changement de
///   DeepCore ;
/// - 86 : la pastille ne montre que le dé de dégâts infligé à la cible au
///   niveau d'emplacement minimal (option d'attaque principale) — rien pour
///   un bonus, une réserve de points de vie, des points de vie temporaires,
///   un soin, une durée, un nombre, un pourcentage ou des dégâts subis par le
///   lanceur ; sort à deux dés de dégâts : le premier, inchangé ;
/// - 88 : les 7 sorts qui infligent des dégâts sans motif `NdM` dans leur
///   texte reçoivent une pastille ([_added]) ;
/// - 89 : pas de pastille pour un sort utilitaire dont l'option offensive est
///   secondaire.
///
/// Comparaison exacte du nom (casse, accents et apostrophes droites compris),
/// après `trim` uniquement. Un sort absent de ces tables garde le
/// comportement par défaut de l'extracteur.
///
/// Donnée autoritaire, encodée telle quelle — même convention que
/// `DruidNonMetallicEquipment`. Un sort renommé côté DeepCore sort de la
/// table sans erreur : mettre la spec et cette table à jour ensemble.
abstract final class SpellDamageDiceExceptions {
  /// Sorts sans pastille, bien qu'un `NdM` figure dans leur description
  /// (30 sorts, plus l'autre nom de « Fausse vie »).
  static const Set<String> _noBadge = {
    // Bonus aux dégâts des armes de la cible (décision 86).
    'Agrandissement/Rapetissement',
    // Points de vie temporaires ou maximum.
    'Amélioration de caractéristique',
    'Fausse vie',
    // Même sort que « Fausse vie » sous un autre nom (dette D261).
    'Simulacre de vie',
    'Festin des héros',
    // Soin.
    'Aura de vitalité',
    'Esprit guérisseur',
    'Mot de guérison',
    'Mot de guérison de groupe',
    'Prière de guérison',
    'Régénération',
    'Soins',
    'Soins de groupe',
    // Réserve de points de vie.
    'Couleurs dansantes',
    'Sommeil',
    // Dégâts subis par le lanceur.
    'Bond cinétique',
    'Contact avec un autre plan',
    'Fusion dans la pierre',
    'Porte dimensionnelle',
    'Souhait',
    'Transfert de vie',
    // Durée ou pourcentage d'écart.
    'Arrêt du temps',
    'Contrôle du climat',
    'Téléportation',
    // Dés des objets animés, table d'effets sans dégâts.
    "Animation d'objets",
    'Espièglerie de Nathair',
    // Dégâts accidentels.
    "Toile d'araignée",
    // Option offensive secondaire (décision 89).
    "Contrôle de l'eau",
    "Modification d'apparence",
    'Quête',
    'Songe',
  };

  /// Sorts dont le premier `NdM` n'est pas le dé de dégâts principal
  /// (décision 85).
  static const Map<String, ({int count, int sides})> _replaced = {
    // Premier dé du texte : 2d6 ; poing serré.
    'Main de Bigby': (count: 4, sides: 8),
    // Premier dé du texte : 1d6 ; effondrement.
    'Tremblement de terre': (count: 5, sides: 6),
  };

  /// Sorts qui infligent des dégâts sans motif `NdM` dans leur texte (résumé
  /// ou « d8 » seul) — décision 88.
  static const Map<String, ({int count, int sides})> _added = {
    'Dragon illusoire': (count: 7, sides: 6),
    'Force fantasmagorique': (count: 1, sides: 6),
    "Fouet d'épines": (count: 1, sides: 6),
    'Fureur de la nature': (count: 4, sides: 6),
    'Gardien de la nature': (count: 1, sides: 6),
    'Murmures dissonants': (count: 3, sides: 6),
    'Trique noueuse': (count: 1, sides: 8),
  };

  /// `true` si le sort [name] ne doit afficher aucune pastille, quelle que
  /// soit sa description.
  static bool hidesBadge(String name) => _noBadge.contains(name.trim());

  /// Dé imposé pour le sort [name] (remplacement ou ajout), `null` si le sort
  /// n'en a pas — il garde alors le comportement par défaut, sauf s'il est
  /// sans pastille (voir [hidesBadge]).
  static ({int count, int sides})? forcedDice(String name) {
    final key = name.trim();
    return _replaced[key] ?? _added[key];
  }
}
