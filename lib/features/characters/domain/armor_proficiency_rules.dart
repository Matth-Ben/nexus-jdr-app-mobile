import '../../../core/utils/french_text_normalizer.dart';
import 'armor_proficiency_category.dart';
import 'character_detail.dart';
import 'character_inventory_item.dart';

/// Verdict de [ArmorProficiencyRules.evaluate] pour un objet d'inventaire.
enum ArmorProficiency {
  /// Le personnage maîtrise cette catégorie d'armure (ou les boucliers).
  proficient,

  /// Le personnage ne maîtrise pas cette catégorie : désavantage aux tests,
  /// sauvegardes et attaques de Force/Dextérité, et incantation impossible
  /// (RAW, identique 2014/2024). **Informatif seulement** — rien n'est
  /// appliqué au calcul de la CA ni aux jets.
  notProficient,

  /// Verdict indécidable (objet sans catégorie d'armure fiable, objet
  /// personnalisé, objet non armure, source de maîtrise non résolue) : jamais
  /// de badge ni de bannière. Le code ne devine jamais.
  unknown,
}

/// Une classe du personnage, réduite à ce qui sert aux maîtrises accordées
/// par une sous-classe (le niveau d'acquisition dépend du niveau DANS la
/// classe concernée).
class ArmorProficiencyClassLevel {
  const ArmorProficiencyClassLevel({
    required this.className,
    required this.level,
    this.subclassName,
    this.subclassUnresolved = false,
    this.isPrimary = false,
  });

  final String className;
  final int level;
  final String? subclassName;

  /// `true` quand une sous-classe est choisie (id présent) mais que son nom
  /// n'a pas pu être résolu (cache, hors ligne, requête partielle) : on ne
  /// sait pas si elle accorde une maîtrise d'armure.
  final bool subclassUnresolved;

  /// Classe principale du personnage.
  final bool isPrimary;
}

/// Tout ce qui peut accorder une maîtrise d'armure à un personnage, extrait
/// de la fiche : voir [ArmorProficiencyProfile.fromDetail].
class ArmorProficiencyProfile {
  const ArmorProficiencyProfile({
    this.tokens = const [],
    this.featNames = const [],
    this.subraceName,
    this.racialTraitNames = const [],
    this.classes = const [],
    this.canEvaluate = true,
  });

  /// `CharacterDetail.armorProficiencyNames` : classe principale complète +
  /// jetons de multiclassage des autres classes (`légère`, `intermédiaire`,
  /// `lourde`, `boucliers`, jetons restreints du Druide).
  final List<String> tokens;

  /// Noms (FR) des dons possédés.
  final List<String> featNames;

  /// Nom (FR) de la sous-race.
  final String? subraceName;

  /// Noms (FR) des traits raciaux.
  final List<String> racialTraitNames;

  /// Classes avec niveau et sous-classe, pour les maîtrises de sous-classe.
  final List<ArmorProficiencyClassLevel> classes;

  /// `false` quand la fiche n'a pas assez de données pour décider (aucune
  /// classe résolue : une liste de jetons vide serait alors un faux
  /// « aucune maîtrise »).
  final bool canEvaluate;

  factory ArmorProficiencyProfile.fromDetail(CharacterDetail detail) =>
      ArmorProficiencyProfile(
        tokens: detail.armorProficiencyNames,
        featNames: [
          ...detail.featNames,
          ...detail.feats.map((feat) => feat.name),
        ],
        subraceName: detail.subraceName,
        racialTraitNames: detail.racialTraits.map((t) => t.name).toList(),
        classes: [
          for (final row in detail.classes)
            ArmorProficiencyClassLevel(
              className: row.className,
              level: row.level,
              subclassName: row.subclassName,
              subclassUnresolved:
                  row.subclassName == null && row.subclassId != null,
              isPrimary: row.isPrimary,
            ),
        ],
        canEvaluate: detail.classes.isNotEmpty,
      );
}

/// Catégorie d'équipement visée par une maîtrise (armure légère/
/// intermédiaire/lourde ou boucliers).
enum _Gear { light, medium, heavy, shield }

class _SubclassGrant {
  const _SubclassGrant({
    required this.className,
    required this.aliases,
    required this.minLevel,
    required this.gears,
  });

  final String className;

  /// Noms de sous-classe acceptés (comparés après normalisation).
  final List<String> aliases;

  /// Niveau DANS la classe à partir duquel la maîtrise est acquise.
  final int minLevel;

  final Set<_Gear> gears;
}

/// Maîtrise d'armures et de boucliers : avertissement **informatif** « armure
/// ou bouclier non maîtrisé » (P10/F16). Fonction pure, 100 % locale (aucune
/// requête, aucune écriture).
///
/// Principes :
/// - **Ne jamais deviner** : un objet dont la catégorie d'armure n'est pas
///   fiable (aucune ligne `armor_properties`, objet personnalisé, `Armure +N`
///   générique, robe de l'archimage, anneaux/capes/bracelets de protection,
///   objets non armure) donne [ArmorProficiency.unknown].
/// - Catégorie d'un objet : d'abord l'emplacement (`armor_properties.slot ??
///   category`) — `bouclier` désigne un bouclier même si son
///   `ac_dex_bonus = illimite` (ce qui ressemble à une armure légère) ;
///   sinon `ac_dex_bonus` (`illimite` = légère, `max_2` = intermédiaire,
///   `aucun` = lourde). Jamais déduite d'un plafond de Dex calculé (le don
///   Maître de l'armure intermédiaire passe le plafond à 3 sans changer la
///   catégorie).
/// - **Druide** : le jeton `intermédiaire (non métallique)` vaut maîtrise de
///   la catégorie intermédiaire, `boucliers (non métalliques)` des boucliers,
///   quelle que soit la matière (le tabou du métal est coutumier, sans effet
///   mécanique) : la parenthèse est ignorée à la lecture des jetons.
/// - Sources hors classe cartographiées EXPLICITEMENT par nom (dons, sous-
///   classes avec niveau d'acquisition, sous-race), faute de donnée
///   structurée en base (dette).
abstract final class ArmorProficiencyRules {
  /// Verdict pour [item] et le profil [profile].
  static ArmorProficiency evaluate(
    CharacterInventoryItem item,
    ArmorProficiencyProfile profile,
  ) {
    final gear = _gearOf(item);
    if (gear == null || !profile.canEvaluate) return ArmorProficiency.unknown;

    final granted = <_Gear>{};
    for (final token in profile.tokens) {
      granted.addAll(_gearsOfToken(token));
    }
    for (final feat in profile.featNames) {
      granted.addAll(_featGrants[_key(feat)] ?? const {});
    }
    if (profile.subraceName != null) {
      granted.addAll(_subraceGrants[_key(profile.subraceName!)] ?? const {});
    }
    for (final trait in profile.racialTraitNames) {
      granted.addAll(_traitGrants[_key(trait)] ?? const {});
    }
    var undecidable = false;
    for (final row in profile.classes) {
      final grant = _subclassGrantOf(row);
      if (grant != null) {
        if (row.level <= 0) {
          // Niveau indisponible : on ne peut pas dire que la maîtrise n'est
          // pas encore acquise.
          undecidable = true;
        } else if (row.level >= grant.minLevel) {
          granted.addAll(grant.gears);
        }
      } else if (_subclassIsUndecidable(row)) {
        undecidable = true;
      }
    }
    // Jetons de la classe principale non chargés (relation `classes` absente) :
    // une liste vide serait un faux « aucune maîtrise ».
    if (profile.tokens.isEmpty &&
        profile.classes.any(
          (row) =>
              row.isPrimary &&
              !_classesWithoutArmor.contains(_key(row.className)),
        )) {
      return ArmorProficiency.unknown;
    }

    if (granted.contains(gear)) return ArmorProficiency.proficient;
    if (undecidable) return ArmorProficiency.unknown;
    return ArmorProficiency.notProficient;
  }

  /// Raccourci : `true` seulement pour [ArmorProficiency.notProficient].
  static bool isNotProficient(
    CharacterInventoryItem item,
    ArmorProficiencyProfile profile,
  ) => evaluate(item, profile) == ArmorProficiency.notProficient;

  /// `true` si [item] est un bouclier (emplacement), pour choisir le texte
  /// de la bannière.
  static bool isShield(CharacterInventoryItem item) =>
      _gearOf(item) == _Gear.shield;

  static _Gear? _gearOf(CharacterInventoryItem item) {
    if (item.isCustom) return null;
    final armor = item.armorProperties;
    final slot = armor?.slot ?? item.category;
    if (slot == 'bouclier') return _Gear.shield;
    if (slot != 'armure' || armor == null) return null;
    return switch (ArmorProficiencyCategoryRules.categoryFor(
      armor.acDexBonus,
    )) {
      ArmorProficiencyCategory.legere => _Gear.light,
      ArmorProficiencyCategory.intermediaire => _Gear.medium,
      ArmorProficiencyCategory.lourde => _Gear.heavy,
      null => null,
    };
  }

  /// Minuscules, sans accents, apostrophes typographiques unifiées, mots
  /// singularisés (« boucliers » -> « bouclier », « légères » -> « légère »).
  static String _key(String value) {
    final normalized = FrenchTextNormalizer.normalize(
      value.replaceAll('’', "'"),
    );
    return normalized
        .split(' ')
        .map(
          (word) => word.length > 1 && word.endsWith('s')
              ? word.substring(0, word.length - 1)
              : word,
        )
        .join(' ');
  }

  /// Lit un jeton de `classes.armor_proficiencies`. La parenthèse est
  /// retirée : `intermédiaire (non métallique)` (Druide) vaut `intermédiaire`.
  static Set<_Gear> _gearsOfToken(String token) {
    final withoutParenthesis = token.replaceAll(RegExp(r'\([^)]*\)'), ' ');
    final name = _key(withoutParenthesis)
        .split(' ')
        .where((word) => word.isNotEmpty && word != 'armure')
        .join(' ');
    return switch (name) {
      'legere' => {_Gear.light},
      'intermediaire' => {_Gear.medium},
      'lourde' => {_Gear.heavy},
      'bouclier' => {_Gear.shield},
      _ => const {},
    };
  }

  /// Cas où l'absence de maîtrise de sous-classe ne peut pas être affirmée :
  /// sous-classe choisie mais non résolue ; sous-classe absente alors que le
  /// niveau l'exige pour une classe dont une sous-classe peut accorder une
  /// armure ; sous-classe renseignée mais ni cartographiée ni connue comme
  /// n'accordant rien. Principe : jamais deviné.
  static bool _subclassIsUndecidable(ArmorProficiencyClassLevel row) {
    if (row.subclassUnresolved) return true;
    final className = _key(row.className);
    final minLevel = _subclassRequiredFrom[className];
    if (minLevel == null) return false;
    final subclass = row.subclassName;
    if (subclass == null) return row.level >= minLevel;
    final knownWithout = _subclassesWithoutArmor[className];
    return !(knownWithout?.contains(_key(subclass)) ?? false);
  }

  static _SubclassGrant? _subclassGrantOf(ArmorProficiencyClassLevel row) {
    final subclass = row.subclassName;
    if (subclass == null) return null;
    final className = _key(row.className);
    final subclassKey = _key(subclass);
    for (final grant in _subclassGrants) {
      if (_key(grant.className) == className &&
          grant.aliases.map(_key).contains(subclassKey)) {
        return grant;
      }
    }
    return null;
  }

  // --- Cartographie par nom (clés déjà singularisées/normalisées via _key
  // à la comparaison). Noms exacts des seeds du dépôt web : dons
  // (`20260905020000_seed_feats.sql`, `20260930170000_seed_feats_complements_2
  // .sql`), sous-classes (`20260902020000_*`, `20260929100000_*`,
  // `20260930120*`), sous-race (`20260825090600_seed_races_subraces.sql`).

  static final Map<String, Set<_Gear>> _featGrants = {
    _key('Armure légère'): {_Gear.light},
    _key('Armure intermédiaire'): {_Gear.medium, _Gear.shield},
    _key('Armure lourde'): {_Gear.heavy},
    // Don 2024 tel que seedé (texte : formation au port des armures légères,
    // intermédiaires et des boucliers).
    _key('Entraînement aux armes de guerre'): {
      _Gear.light,
      _Gear.medium,
      _Gear.shield,
    },
  };

  /// Sous-race : « Nain des montagnes » (et non « des collines »).
  static final Map<String, Set<_Gear>> _subraceGrants = {
    _key('Nain des montagnes'): {_Gear.light, _Gear.medium},
  };

  /// Trait racial seedé de la même sous-race (filet si le nom de sous-race
  /// n'est pas résolu).
  static final Map<String, Set<_Gear>> _traitGrants = {
    _key('Entraînement au combat nain (armures)'): {_Gear.light, _Gear.medium},
  };

  /// Classes sans aucune maîtrise d'armure de départ (jetons vides normaux).
  static final Set<String> _classesWithoutArmor = {
    _key('Magicien'),
    _key('Moine'),
    _key('Ensorceleur'),
  };

  /// Classes dont une sous-classe peut accorder une armure, et niveau de
  /// classe à partir duquel la sous-classe existe.
  static final Map<String, int> _subclassRequiredFrom = {
    _key('Clerc'): 1,
    _key('Occultiste'): 1,
    _key('Barde'): 3,
    _key('Magicien'): 2,
    _key('Artificier'): 3,
  };

  /// Sous-classes (noms des seeds) dont on est sûr qu'elles n'accordent
  /// aucune maîtrise d'armure. Toute autre sous-classe non cartographiée est
  /// indécidable (Clerc Tombe/Mort volontairement absents : à valider).
  static final Map<String, Set<String>> _subclassesWithoutArmor = {
    _key('Clerc'): {
      'Lumière',
      'Domaine de la Lumière',
      'Savoir',
      'Domaine du Savoir',
      'Duperie',
      'Domaine de la Duperie',
      'Arcanes',
      'Domaine des Arcanes',
      'Paix',
      'Domaine de la Paix',
    }.map(_key).toSet(),
    _key('Occultiste'): {
      'Archifée',
      'Grand Ancien',
      'Céleste',
      'Génie - Dao',
      'Génie - Djinn',
      'Génie - Éfrit',
      'Génie - Maride',
      'Insondable',
      'Mort-vivant',
      'Protecteur Fiélon',
      'Fiélon',
    }.map(_key).toSet(),
    _key('Barde'): {
      'Collège du Savoir',
      "Collège de l'éloquence",
      'Collège de la création',
      'Collège de la séduction',
      'Collège des esprits',
      'Collège des murmures',
    }.map(_key).toSet(),
    _key('Magicien'): {
      'Abjuration',
      'Divination',
      'Enchantement',
      'Évocation',
      "École de l'évocation",
      'Illusion',
      'Invocation',
      'Nécromancie',
      'Transmutation',
      'Magie de guerre',
      'Scribes',
    }.map(_key).toSet(),
    _key('Artificier'): {
      'Alchimiste',
      'Artilleur',
      'Forgeron de guerre',
    }.map(_key).toSet(),
  };

  static const List<_SubclassGrant> _subclassGrants = [
    _SubclassGrant(
      className: 'Clerc',
      aliases: ['Vie', 'Domaine de la Vie'],
      minLevel: 1,
      gears: {_Gear.heavy},
    ),
    _SubclassGrant(
      className: 'Clerc',
      aliases: ['Guerre', 'Domaine de la Guerre'],
      minLevel: 1,
      gears: {_Gear.heavy},
    ),
    _SubclassGrant(
      className: 'Clerc',
      aliases: ['Nature', 'Domaine de la Nature'],
      minLevel: 1,
      gears: {_Gear.heavy},
    ),
    _SubclassGrant(
      className: 'Clerc',
      aliases: ['Tempête', 'Domaine de la Tempête'],
      minLevel: 1,
      gears: {_Gear.heavy},
    ),
    _SubclassGrant(
      className: 'Clerc',
      aliases: ['Forge', 'Domaine de la Forge'],
      minLevel: 1,
      gears: {_Gear.heavy},
    ),
    _SubclassGrant(
      className: 'Clerc',
      aliases: ['Ordre', 'Domaine de l\'Ordre'],
      minLevel: 1,
      gears: {_Gear.heavy},
    ),
    _SubclassGrant(
      className: 'Clerc',
      aliases: ['Crépuscule', 'Domaine du Crépuscule'],
      minLevel: 1,
      gears: {_Gear.heavy},
    ),
    _SubclassGrant(
      className: 'Barde',
      aliases: ['Collège de la vaillance'],
      minLevel: 3,
      gears: {_Gear.medium, _Gear.shield},
    ),
    _SubclassGrant(
      className: 'Barde',
      aliases: ['Collège des épées', 'Collège des lames'],
      minLevel: 3,
      gears: {_Gear.medium},
    ),
    _SubclassGrant(
      className: 'Magicien',
      aliases: ['Chantelames', 'Chantelame'],
      minLevel: 2,
      gears: {_Gear.light},
    ),
    _SubclassGrant(
      className: 'Occultiste',
      aliases: ['Lame maudite', 'Guerrier maléfique', 'Hexblade'],
      minLevel: 1,
      gears: {_Gear.medium, _Gear.shield},
    ),
    _SubclassGrant(
      className: 'Artificier',
      aliases: ['Armurier'],
      minLevel: 3,
      gears: {_Gear.heavy},
    ),
  ];
}
