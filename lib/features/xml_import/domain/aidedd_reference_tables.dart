/// Tables de correspondance `identifiant numérique aidedd.org → libellé`
/// pour les champs "codés" de l'import XML aidedd.org (compétences, armures,
/// bouclier, armes, outils/instruments physiques, objets d'équipement,
/// paquetages de départ, alignement, sexe).
///
/// Transcription directe de `docs/xml-import-reference-mapping.md` (source
/// de vérité : le HTML serveur `ajax_main.php` d'aidedd.org lui-même, pas
/// une déduction) — donnée de référence figée propre au format d'export
/// d'un outil tiers, volontairement gardée en dehors du modèle de données
/// partagé avec l'app web (voir la section "Recommandation d'implémentation"
/// de ce document). Ne PAS modifier ces tables sans revalider contre
/// `docs/xml-import-reference-mapping.md` (et, en cas de doute, contre
/// aidedd.org lui-même) : voir aussi
/// `docs/cahier-des-charges/03-import-xml-aidedd.md` pour le rationale
/// général du chantier de rétro-ingénierie.
///
/// Placé dans `domain/` plutôt que `data/` (suggestion "ex." de
/// `xml-import-reference-mapping.md`, pas une prescription) : ce sont des
/// constantes Dart pures, sans dépendance réseau/Supabase, et
/// `domain/xml_character_import_resolver.dart` (qui les consomme) a besoin
/// de les importer — aucun fichier `domain/` de ce dépôt n'importe depuis
/// `data/` ailleurs (`character_creation`/`characters`), layering respecté
/// en gardant cette table côté domaine.
///
/// Chaque table ne va que jusqu'au libellé aidedd (`String`), pas jusqu'à un
/// identifiant réel des tables internes de l'app (`items.id`, `skills.id`,
/// ...) : cette seconde étape de résolution (libellé aidedd → entité réelle
/// de l'app) est hors périmètre de cet increment (voir la consigne
/// d'origine de la tâche, qui exclut explicitement la sauvegarde en base) et
/// reviendra le jour où l'écran de récapitulatif / la sauvegarde seront
/// implémentés.
abstract final class AideddReferenceTables {
  /// 18 compétences, ordre alphabétique français — confirmé par le HTML
  /// serveur ET par recoupement narratif sur `pip.xml` (voir
  /// `xml-import-reference-mapping.md`, section "Compétences").
  static const Map<int, String> skills = {
    0: 'Acrobaties',
    1: 'Arcanes',
    2: 'Athlétisme',
    3: 'Discrétion',
    4: 'Dressage',
    5: 'Escamotage',
    6: 'Histoire',
    7: 'Intimidation',
    8: 'Intuition',
    9: 'Investigation',
    10: 'Médecine',
    11: 'Nature',
    12: 'Perception',
    13: 'Persuasion',
    14: 'Religion',
    15: 'Représentation',
    16: 'Survie',
    17: 'Tromperie',
  };

  /// Source du choix pour les 4 index `id="0..3"` de `skillsProf`/
  /// `toolsProf`/`languages` (confirmé par les libellés `<h3>` du HTML
  /// serveur) — purement informatif, pas utilisé pour la résolution
  /// elle-même (voir `XmlCharacterImportResolved.skillProficiencies`, qui
  /// garde ces 4 groupes séparés par cette clé sans avoir besoin de son
  /// libellé).
  static const Map<int, String> proficiencySources = {
    0: 'Race',
    1: 'Classe',
    2: 'Historique (background)',
    3: 'Autres (dons, choix optionnels)',
  };

  /// 13 armures, `0` = "Sans armure" (une valeur légitime, pas un
  /// emplacement vide contrairement à `weapon`/`tools`/`item`).
  static const Map<int, String> armor = {
    0: 'Sans armure',
    1: 'Armure matelassée',
    2: 'Armure de cuir',
    3: 'Armure de cuir clouté',
    4: 'Armure de peaux',
    5: 'Chemise de mailles',
    6: 'Armure d\'écailles',
    7: 'Cuirasse',
    8: 'Demi-plate',
    9: 'Broigne',
    10: 'Cotte de mailles',
    11: 'Clibanion',
    12: 'Harnois',
  };

  /// `0` = "Sans bouclier" (une valeur légitime, même remarque que [armor]).
  static const Map<int, String> shield = {0: 'Sans bouclier', 1: 'Bouclier'};

  /// 39 armes (ids 0 à 38). `0` = emplacement vide (à ignorer lors de la
  /// résolution positionnelle avec `weaponQ`, pas une "arme non reconnue" —
  /// voir `XmlCharacterImportResolver`). `1` = "Mains nues" n'apparaît
  /// jamais dans un export réel (non achetable) mais reste dans la table par
  /// exhaustivité (voir `xml-import-reference-mapping.md`).
  static const Map<int, String> weapons = {
    0: '(vide)',
    1: 'Mains nues',
    2: 'Bâton',
    3: 'Dague',
    4: 'Gourdin',
    5: 'Hachette',
    6: 'Javeline',
    7: 'Lance',
    8: 'Marteau léger',
    9: 'Masse d\'armes',
    10: 'Massue',
    11: 'Serpe',
    12: 'Arbalète légère',
    13: 'Arc court',
    14: 'Fléchette',
    15: 'Fronde',
    16: 'Cimeterre',
    17: 'Coutille',
    18: 'Épée à deux mains',
    19: 'Épée courte',
    20: 'Épée longue',
    21: 'Fléau d\'armes',
    22: 'Fouet',
    23: 'Hache à deux mains',
    24: 'Hache d\'armes',
    25: 'Hallebarde',
    26: 'Lance d\'arçon',
    27: 'Maillet',
    28: 'Marteau de guerre',
    29: 'Morgenstern',
    30: 'Pic de guerre',
    31: 'Pique',
    32: 'Rapière',
    33: 'Trident',
    34: 'Arbalète de poing',
    35: 'Arbalète lourde',
    36: 'Arc long',
    37: 'Filet',
    38: 'Sarbacane',
  };

  /// Outils/instruments **physiques possédés** (champ `tools`, positionnel
  /// avec quantité implicite 1 — pas de liste `toolsQ`), *différent* de
  /// `toolsProf` (maîtrises, déjà en texte clair, résolu via `ToolCatalog`
  /// dans `XmlCharacterImportResolver`, pas via cette table). `0` =
  /// emplacement vide, à ignorer comme pour [weapons].
  ///
  /// 40 entrées (ids 0 à 39) — le texte de
  /// `xml-import-reference-mapping.md` annonce "39 valeurs" mais son propre
  /// tableau liste bien 40 ids (0 à 39 inclus) : transcription fidèle du
  /// tableau (source vérifiée contre le HTML serveur) plutôt que de sa
  /// phrase de résumé, en cas de divergence entre les deux.
  static const Map<int, String> toolsEquipment = {
    0: '(vide)',
    1: 'Kit d\'empoisonneur',
    2: 'Kit d\'herboriste',
    3: 'Kit de contrefaçon',
    4: 'Kit de déguisement',
    5: 'Outils de navigateur',
    6: 'Outils de voleur',
    7: 'Chalemie',
    8: 'Cor',
    9: 'Cornemuse',
    10: 'Flûte',
    11: 'Flûte de pan',
    12: 'Luth',
    13: 'Lyre',
    14: 'Tambour',
    15: 'Tympanon',
    16: 'Viole',
    17: 'Dés',
    18: 'Jeu d\'échecs draconiques',
    19: 'Jeu de cartes',
    20: 'Jeu des Dragons',
    21: 'Matériel d\'alchimiste',
    22: 'Matériel de brasseur',
    23: 'Matériel de calligraphe',
    24: 'Matériel de peintre',
    25: 'Outils de bijoutier',
    26: 'Outils de bricoleur',
    27: 'Outils de cartographe',
    28: 'Outils de charpentier',
    29: 'Outils de cordonnier',
    30: 'Outils de forgeron',
    31: 'Outils de maçon',
    32: 'Outils de menuisier',
    33: 'Outils de potier',
    34: 'Outils de souffleur de verre',
    35: 'Outils de tanneur',
    36: 'Outils de tisserand',
    37: 'Ustensiles de cuisinier',
    38: 'Véhicules (terrestres)',
    39: 'Véhicules (aquatiques)',
  };

  /// Objets d'équipement (champ `item`, positionnel avec `itemQ`), catalogue
  /// **non séquentiel** (pas un ordre alphabétique ni devinable) — 99
  /// entrées (ids 1 à 99). `0` = emplacement vide, à ignorer comme pour
  /// [weapons]/[toolsEquipment]. Même remarque que [toolsEquipment] sur la
  /// divergence entre le texte de `xml-import-reference-mapping.md` ("98
  /// objets [...] avec quelques trous") et son propre tableau, qui ne montre
  /// en réalité aucun trou entre 1 et 99 : transcription fidèle du tableau.
  static const Map<int, String> items = {
    0: '(vide)',
    1: 'Acide/fiole',
    2: 'Antidote/fiole',
    3: 'Bélier portable',
    4: 'Billes/1000',
    5: 'Boite d\'allume-feu',
    6: 'Bougie',
    7: 'Boulier',
    8: 'Sacoche',
    9: 'Cadenas',
    10: 'Carquois',
    11: 'Chaîne de 3 m',
    12: 'Chevalière',
    13: 'Chausse-trappes/20',
    14: 'Cire à cacheter',
    15: 'Cloche',
    16: 'Coffre',
    17: 'Corde en chanvre de 15 m',
    18: 'Corde en soie de 15 m',
    19: 'Couverture',
    20: 'Craie',
    21: 'Eau bénite/flasque',
    22: 'Échelle de 3 m',
    23: 'Encre/bouteille',
    24: 'Étui à carreaux',
    25: 'Étui à cartes ou parchemins',
    26: 'Feu grégeois/flasque',
    27: 'Fiole',
    28: 'Flasque',
    29: 'Focaliseur arcanique/baguette',
    30: 'Focaliseur arcanique/bâton',
    31: 'Focaliseur arcanique/boule de cristal',
    32: 'Focaliseur arcanique/orbe',
    33: 'Focaliseur arcanique/sceptre',
    34: 'Focaliseur druidique/baguette d\'if',
    35: 'Focaliseur druidique/bâton',
    36: 'Focaliseur druidique/branche de gui',
    37: 'Focaliseur druidique/totem',
    38: 'Gamelle',
    39: 'Gourde',
    40: 'Grappin',
    41: 'Grimoire',
    42: 'Huile/flasque',
    43: 'Lampe',
    44: 'Lanterne sourde',
    45: 'Lanterne à capote',
    46: 'Livre',
    47: 'Longue-vue',
    48: 'Loupe',
    49: 'Marteau',
    50: 'Marteau de forgeron',
    51: 'Kit d\'escalade',
    52: 'Balance de marchand',
    53: 'Matériel de pêche',
    54: 'Menottes',
    55: '20 billes de fronde',
    56: '20 carreaux',
    57: '20 flèches',
    58: '50 aiguilles de sarbacane',
    59: 'Palan',
    60: 'Papier',
    61: 'Parchemin',
    62: 'Parfum/fiole',
    63: 'Pelle',
    64: 'Perche de 3 m',
    65: 'Miroir en acier',
    66: 'Pied-de-biche',
    67: 'Piège à mâchoires',
    68: 'Pierre à aiguiser',
    69: 'Pioche de mineur',
    70: 'Piton',
    71: 'Plume d\'écriture',
    72: 'Pointes en fer/10',
    73: 'Poison/fiole',
    74: 'Pot en fer',
    75: 'Potion de guérison',
    76: 'Rations/1 jour',
    77: 'Robes',
    78: 'Sablier',
    79: 'Sac',
    80: 'Sac à dos',
    81: 'Sac de couchage',
    82: 'Sacoche à composantes',
    83: 'Savon',
    84: 'Seau',
    85: 'Sifflet',
    86: 'Symbole sacré/amulette',
    87: 'Symbole sacré/emblème',
    88: 'Symbole sacré/reliquaire',
    89: 'Tente',
    90: 'Torche',
    91: 'Trousse de soins',
    92: 'Vêtements communs',
    93: 'Vêtements/costume',
    94: 'Vêtements fins',
    95: 'Vêtements de voyage',
    96: 'Tonneau',
    97: 'Panier',
    98: 'Cruche',
    99: 'Bouteille',
  };

  /// 26 paquetages de départ (2 par classe : a/b), array `PACK` du serveur.
  /// Utilisé uniquement pour la traçabilité/validation croisée à ce stade
  /// (l'équipement réel importé vient de `armor`/`shield`/`weapon`/`tools`/
  /// `item`, pas recalculé depuis le libellé du pack) — voir
  /// `xml-import-reference-mapping.md`.
  static const Map<int, String> packs = {
    0: 'Pack (a) de barbare',
    1: 'Pack (b) de barbare',
    2: 'Pack (a) de barde',
    3: 'Pack (b) de barde',
    4: 'Pack (a) de clerc',
    5: 'Pack (b) de clerc',
    6: 'Pack (a) de druide',
    7: 'Pack (b) de druide',
    8: 'Pack (a) d\'ensorceleur',
    9: 'Pack (b) d\'ensorceleur',
    10: 'Pack (a) de guerrier',
    11: 'Pack (b) de guerrier',
    12: 'Pack (a) de magicien',
    13: 'Pack (b) de magicien',
    14: 'Pack (a) de moine',
    15: 'Pack (b) de moine',
    16: 'Pack (a) de paladin',
    17: 'Pack (b) de paladin',
    18: 'Pack (a) de rôdeur',
    19: 'Pack (b) de rôdeur',
    20: 'Pack (a) de roublard',
    21: 'Pack (b) de roublard',
    22: 'Pack (a) d\'occultiste',
    23: 'Pack (b) d\'occultiste',
    24: 'Pack (a) d\'artificier',
    25: 'Pack (b) d\'artificier',
  };

  /// 9 alignements, grille 3×3 [Loyal/Neutre/Chaotique] × [bon/neutre/
  /// mauvais] — confirmé et corrige une hypothèse d'ordre erronée posée lors
  /// d'une première tentative de déduction narrative seule (voir
  /// `xml-import-reference-mapping.md`).
  static const Map<int, String> alignments = {
    0: 'Loyal bon',
    1: 'Loyal neutre',
    2: 'Loyal mauvais',
    3: 'Neutre bon',
    4: 'Neutre',
    5: 'Neutre mauvais',
    6: 'Chaotique bon',
    7: 'Chaotique neutre',
    8: 'Chaotique mauvais',
  };

  /// 3 valeurs de sexe.
  static const Map<int, String> sexes = {
    0: 'Homme',
    1: 'Femme',
    2: 'Non binaire',
  };
}
