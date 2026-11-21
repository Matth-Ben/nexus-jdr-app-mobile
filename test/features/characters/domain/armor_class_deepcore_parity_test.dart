// Parité de la CA de la fiche (Nexus) avec le calcul SQL de DeepCore
// (`private.character_armor_class`, migration `20261120090000` du dépôt
// DeepCore) : chaque cas de `supabase/tests/api_v1_character_armor_class_test
// .sql` (C1 à C27 de `regles-dnd`, compléments et données non lues) est rejoué
// ici avec la MÊME valeur attendue. Grimoire affiche la CA de DeepCore : une
// divergence ici est une divergence visible entre les deux apps (la fiche
// mobile fait foi, décision n° 37 du 20/11/2026).
//
// Chemin réel de la fiche : lignes `character_inventory` brutes (objets du
// catalogue avec `items(... armor_properties(...))` embarqué, objets
// personnalisés avec leurs colonnes `custom_*`) -> `CharacterInventoryRowMapper`
// -> `CharacterDetail.armorClass`. Valeurs du catalogue relues dans les
// migrations de DeepCore (`20260825091000_seed_items_equipment.sql`,
// `20260930090000/090100_seed_srd52_magic_items_part1/2.sql`,
// `20261001090000_feats_ability_increase_and_magic_ac.sql`).
//
// Hors Dart (SQL seulement) : droits EXECUTE/USAGE, personnage inconnu ou
// identifiant NULL (aucune ligne).

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/data/character_inventory_row_mapper.dart';
import 'package:personnages/features/characters/domain/armor_class_resolver.dart';
import 'package:personnages/features/characters/domain/character_class_choice.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/condition_type.dart';

Map<String, dynamic> _armorRow(
  String category,
  int acBase,
  String dex, {
  String? slot,
  bool attunement = false,
  int? acBonus,
  String? acBonusKind,
}) => {
  'category': category,
  'requires_attunement': attunement,
  'ac_bonus': acBonus,
  'ac_bonus_kind': acBonusKind,
  'armor_properties': {'ac_base': acBase, 'ac_dex_bonus': dex, 'slot': slot},
};

Map<String, dynamic> _bonusRow(
  int acBonus,
  String acBonusKind, {
  required bool attunement,
}) => {
  'category': 'objet_magique',
  'requires_attunement': attunement,
  'ac_bonus': acBonus,
  'ac_bonus_kind': acBonusKind,
};

/// Objets du catalogue utilisés par les tests pgTAP : `item_id` arbitraire,
/// ligne `items` embarquée telle que PostgREST la renvoie à la fiche.
final Map<String, ({int id, Map<String, dynamic> items})> _catalog = {
  'Armure de cuir': (id: 101, items: _armorRow('armure', 11, 'illimite')),
  'Armure de cuir clouté': (
    id: 102,
    items: _armorRow('armure', 12, 'illimite'),
  ),
  'Cuirasse': (id: 103, items: _armorRow('armure', 14, 'max_2')),
  'Cotte de mailles': (id: 104, items: _armorRow('armure', 16, 'aucun')),
  'Armure complète': (id: 105, items: _armorRow('armure', 18, 'aucun')),
  'Bouclier': (id: 106, items: _armorRow('bouclier', 2, 'illimite')),
  'Bouclier +2': (
    id: 107,
    items: _armorRow('objet_magique', 4, 'illimite', slot: 'bouclier'),
  ),
  "Armure d'écailles de dragon": (
    id: 108,
    items: _armorRow(
      'objet_magique',
      14,
      'max_2',
      slot: 'armure',
      attunement: true,
      acBonus: 1,
      acBonusKind: 'toujours',
    ),
  ),
  'Armure +1': (id: 109, items: _bonusRow(1, 'avec_armure', attunement: false)),
  'Anneau de protection': (
    id: 110,
    items: _bonusRow(1, 'toujours', attunement: true),
  ),
  'Cape de protection': (
    id: 111,
    items: _bonusRow(1, 'toujours', attunement: true),
  ),
  'Bracelets de défense': (
    id: 112,
    items: _bonusRow(2, 'sans_armure_ni_bouclier', attunement: true),
  ),
  "Robe de l'archimage": (
    id: 113,
    items: _bonusRow(15, 'base_sans_armure', attunement: true),
  ),
  // Objets factices des tests pgTAP (aucun objet du catalogue n'a ces bonus).
  'pgTAP bouclier base sans armure': (
    id: 114,
    items: _armorRow(
      'objet_magique',
      2,
      'illimite',
      slot: 'bouclier',
      acBonus: 15,
      acBonusKind: 'base_sans_armure',
    ),
  ),
  'pgTAP bouclier avec armure': (
    id: 115,
    items: _armorRow(
      'objet_magique',
      2,
      'illimite',
      slot: 'bouclier',
      acBonus: 1,
      acBonusKind: 'avec_armure',
    ),
  ),
  // Compléments Dart (décision n° 37) : objets d'emplacement porteurs d'un
  // `ac_bonus`, pour vérifier qu'un objet non retenu ne donne rien.
  'Test armure avec armure +1': (
    id: 116,
    items: _armorRow(
      'objet_magique',
      11,
      'illimite',
      slot: 'armure',
      acBonus: 1,
      acBonusKind: 'avec_armure',
    ),
  ),
  'Test bouclier toujours +1': (
    id: 117,
    items: _armorRow(
      'objet_magique',
      2,
      'illimite',
      slot: 'bouclier',
      acBonus: 1,
      acBonusKind: 'toujours',
    ),
  ),
};

var _sequence = 0;

/// Objet du catalogue dans l'inventaire (`pg_temp.give`).
Map<String, dynamic> _give(
  String name, {
  bool equipped = true,
  bool attuned = false,
  int quantity = 1,
}) {
  final entry = _catalog[name]!;
  return {
    'id': 'inv-${_sequence++}',
    'item_id': entry.id,
    'quantity': quantity,
    'equipped': equipped,
    'is_attuned': attuned,
    'items': entry.items,
  };
}

/// Objet personnalisé (`pg_temp.give_custom`).
Map<String, dynamic> _giveCustom(
  String? kind,
  int acBase, {
  String? category,
  int? magic,
  bool requiresAttunement = false,
  bool attuned = false,
  bool equipped = true,
}) => {
  'id': 'inv-${_sequence++}',
  'item_id': null,
  'custom_name': 'Objet perso ${kind ?? 'sans type'}',
  'quantity': 1,
  'equipped': equipped,
  'is_attuned': attuned,
  'custom_kind': kind,
  'custom_ac_base': acBase,
  'custom_armor_category': category,
  'custom_magic_bonus': magic,
  'custom_requires_attunement': requiresAttunement,
};

/// Harmonise tous les objets (`pg_temp.attune_all`).
List<Map<String, dynamic>> _attuneAll(List<Map<String, dynamic>> rows) => [
  for (final row in rows) {...row, 'is_attuned': true},
];

/// Fiche (`pg_temp.new_char`) : scores, classes par nom (niveaux variés, jamais
/// lus), sous-classe portée par un Ensorceleur, style de combat choisi sous
/// l'aptitude [style].$1 avec la valeur [style].$2, ajustement manuel.
CharacterDetail _character(
  List<Map<String, dynamic>> rows, {
  Map<String, int> scores = const {},
  List<String> classes = const [],
  String? subclass,
  (String, String)? style,
  int bonus = 0,
  bool isDead = false,
  List<ConditionType> conditions = const [],
  int currentHp = 10,
}) => CharacterDetail(
  id: 'char',
  name: 'CA',
  classes: [
    for (var i = 0; i < classes.length; i++)
      CharacterDetailClassRow(
        classId: i + 1,
        className: classes[i],
        level: 1 + 4 * i,
        isPrimary: i == 0,
        savingThrowProficiencies: const [],
        hitDie: 8,
      ),
    if (subclass != null)
      CharacterDetailClassRow(
        classId: 99,
        className: 'Ensorceleur',
        level: 3,
        isPrimary: classes.isEmpty,
        savingThrowProficiencies: const [],
        hitDie: 6,
        subclassName: subclass,
      ),
  ],
  xp: 0,
  currentHp: currentHp,
  maxHp: 10,
  temporaryHp: 0,
  isDead: isDead,
  conditions: conditions,
  armorClassBonus: bonus,
  abilityScores: scores,
  classChoices: [
    if (style != null)
      CharacterClassChoice(featureName: style.$1, chosenValue: style.$2),
  ],
  inventory: CharacterInventoryRowMapper.toCharacterInventoryItems(
    rows,
    names: const {},
    descriptions: const {},
  ),
);

/// `pg_temp.ac` : CA SANS l'ajustement manuel (`armor_class`).
int _ac(
  List<Map<String, dynamic>> rows, {
  Map<String, int> scores = const {},
  List<String> classes = const [],
  String? subclass,
  (String, String)? style,
}) => _character(
  rows,
  scores: scores,
  classes: classes,
  subclass: subclass,
  style: style,
).armorClass;

const _defense = ('Style de combat', 'Défense');

/// Toutes les permutations de [items] (au plus 4 objets ici : 24 ordres).
List<List<T>> _permutations<T>(List<T> items) {
  if (items.length <= 1) return [items];
  return [
    for (var i = 0; i < items.length; i++)
      for (final rest in _permutations([
        ...items.sublist(0, i),
        ...items.sublist(i + 1),
      ]))
        [items[i], ...rest],
  ];
}

/// [expected] dans TOUS les ordres de l'inventaire [rows] (déterminisme).
void _expectInAllOrders(
  List<Map<String, dynamic>> rows,
  int expected, {
  Map<String, int> scores = const {},
  List<String> classes = const [],
  (String, String)? style,
}) {
  final orders = _permutations(rows);
  expect(orders.length, greaterThan(1));
  for (final order in orders) {
    expect(
      _ac(order, scores: scores, classes: classes, style: style),
      expected,
      reason:
          'ordre : ${[for (final row in order) row['item_id'] ?? row['custom_kind']]}',
    );
  }
}

void main() {
  group('C1 à C3 : sans armure', () {
    test("C1 : aucun score, rien d'équipé -> 10", () {
      expect(_ac(const []), 10);
    });

    test('C2 : Dex 14 -> 12 ; + bouclier (+2) -> 14', () {
      expect(_ac(const [], scores: {'dex': 14}), 12);
      expect(_ac([_give('Bouclier')], scores: {'dex': 14}), 14);
    });

    test('C3 : Dex 9 -> 9 (modificateur -1 : plancher, pas troncature)', () {
      expect(_ac(const [], scores: {'dex': 9}), 9);
    });
  });

  group('C4 à C9 : armures du catalogue', () {
    test('C4 : Dex 20, légère 12 illimitée -> 17', () {
      expect(_ac([_give('Armure de cuir clouté')], scores: {'dex': 20}), 17);
    });

    test('C5 : Dex 6, légère 11 -> 9', () {
      expect(_ac([_give('Armure de cuir')], scores: {'dex': 6}), 9);
    });

    test('C6 : Dex 18, intermédiaire 14 max 2 -> 16', () {
      expect(_ac([_give('Cuirasse')], scores: {'dex': 18}), 16);
    });

    test('C7 : Dex 7, intermédiaire 14 -> 12 (Dex négative non plafonnée)', () {
      expect(_ac([_give('Cuirasse')], scores: {'dex': 7}), 12);
    });

    test('C8 : Dex 20, lourde 18 + bouclier -> 20', () {
      expect(
        _ac([_give('Armure complète'), _give('Bouclier')], scores: {'dex': 20}),
        20,
      );
    });

    test('C9 : Dex 6, lourde 16 -> 16 (Dex ignorée)', () {
      expect(_ac([_give('Cotte de mailles')], scores: {'dex': 6}), 16);
    });
  });

  group('C10, C11 : style Défense', () {
    test('C10 : Dex 14, intermédiaire 14 + bouclier + Défense -> 19', () {
      expect(
        _ac(
          [_give('Cuirasse'), _give('Bouclier')],
          scores: {'dex': 14},
          style: _defense,
        ),
        19,
      );
    });

    test('C11 : Dex 14 sans armure, Défense -> 12 (Défense exige une '
        'armure)', () {
      expect(_ac(const [], scores: {'dex': 14}, style: _defense), 12);
    });
  });

  group('C12 à C16 : Défense sans armure et Résilience draconique', () {
    const barbarian = {'dex': 14, 'con': 16};

    test('C12 : Barbare Dex 14 Con 16 -> 15 ; + bouclier -> 17', () {
      expect(_ac(const [], scores: barbarian, classes: ['Barbare']), 15);
      expect(
        _ac([_give('Bouclier')], scores: barbarian, classes: ['Barbare']),
        17,
      );
    });

    test('C13 : Barbare Dex 14 Con 16, intermédiaire 14 -> 16', () {
      expect(
        _ac([_give('Cuirasse')], scores: barbarian, classes: ['Barbare']),
        16,
      );
    });

    test('C14 : Moine Dex 16 Sag 16 -> 16 ; + bouclier -> 15 (Défense du '
        'Moine perdue)', () {
      const monk = {'dex': 16, 'wis': 16};
      expect(_ac(const [], scores: monk, classes: ['Moine']), 16);
      expect(_ac([_give('Bouclier')], scores: monk, classes: ['Moine']), 15);
    });

    test('C15 : Barbare + Moine Dex 14 Con 12 Sag 18 -> 16 (maximum, écart '
        'E1 de D234) ; + bouclier -> 15', () {
      const scores = {'dex': 14, 'con': 12, 'wis': 18};
      const both = ['Barbare', 'Moine'];
      expect(_ac(const [], scores: scores, classes: both), 16);
      expect(_ac([_give('Bouclier')], scores: scores, classes: both), 15);
    });

    test('C16 : Lignage draconique Dex 14 -> 15 ; + bouclier -> 17', () {
      expect(
        _ac(const [], scores: {'dex': 14}, subclass: 'Lignage draconique'),
        15,
      );
      expect(
        _ac(
          [_give('Bouclier')],
          scores: {'dex': 14},
          subclass: 'Lignage draconique',
        ),
        17,
      );
    });
  });

  group('C17 à C22 : objets magiques du catalogue', () {
    test(
      'C17 : Anneau de protection non harmonisé -> 12 ; harmonisé -> 13',
      () {
        final rows = [_give('Anneau de protection')];
        expect(_ac(rows, scores: {'dex': 14}), 12);
        expect(_ac(_attuneAll(rows), scores: {'dex': 14}), 13);
      },
    );

    test('C18 : Écailles de dragon non harmonisées -> 16 (la base compte '
        'toujours) ; harmonisées -> 17', () {
      final rows = [_give("Armure d'écailles de dragon")];
      expect(_ac(rows, scores: {'dex': 16}), 16);
      expect(_ac(_attuneAll(rows), scores: {'dex': 16}), 17);
    });

    test('C19 : cotte de mailles 16 + Armure +1 -> 17 ; Armure +1 seule -> '
        '12 (écart E7 de D234)', () {
      expect(
        _ac(
          [_give('Cotte de mailles'), _give('Armure +1')],
          scores: {'dex': 14},
        ),
        17,
      );
      expect(_ac([_give('Armure +1')], scores: {'dex': 14}), 12);
    });

    test('C20 : Bracelets harmonisés -> 14 ; + bouclier -> 14 (bonus des '
        'bracelets perdu) ; Moine Dex 16 Sag 16 + Bracelets -> 18', () {
      final bracers = _give('Bracelets de défense', attuned: true);
      expect(_ac([bracers], scores: {'dex': 14}), 14);
      expect(_ac([bracers, _give('Bouclier')], scores: {'dex': 14}), 14);
      expect(
        _ac([bracers], scores: {'dex': 16, 'wis': 16}, classes: ['Moine']),
        18,
      );
    });

    test("C21 : Robe de l'archimage harmonisée -> 17 ; + bouclier -> 19 ; "
        'non harmonisée -> 12 ; Moine Dex 14 Sag 18 + Robe -> 17', () {
      final robe = _give("Robe de l'archimage", attuned: true);
      expect(_ac([robe], scores: {'dex': 14}), 17);
      expect(_ac([robe, _give('Bouclier')], scores: {'dex': 14}), 19);
      expect(_ac([_give("Robe de l'archimage")], scores: {'dex': 14}), 12);
      expect(
        _ac([robe], scores: {'dex': 14, 'wis': 18}, classes: ['Moine']),
        17,
      );
    });

    test('C22 : Bouclier +2 (emplacement bouclier, base 4) -> 16', () {
      expect(_ac([_give('Bouclier +2')], scores: {'dex': 14}), 16);
    });
  });

  group('C23, C24 : objets personnalisés', () {
    test('C23 : armure perso 15 intermédiaire +1 à harmoniser, non '
        'harmonisée -> 17 ; harmonisée -> 18', () {
      final rows = [
        _giveCustom(
          'armure',
          15,
          category: 'intermediaire',
          magic: 1,
          requiresAttunement: true,
        ),
      ];
      expect(_ac(rows, scores: {'dex': 16}), 17);
      expect(_ac(_attuneAll(rows), scores: {'dex': 16}), 18);
    });

    test('C24 : bouclier perso 2 +2 sans harmonisation -> 16 ; objets perso '
        '« autre » ou sans type avec custom_ac_base 15 ignorés (12) ; Barbare '
        'Con 16 + objet « autre » -> 15', () {
      expect(
        _ac([_giveCustom('bouclier', 2, magic: 2)], scores: {'dex': 14}),
        16,
      );
      expect(_ac([_giveCustom('autre', 15)], scores: {'dex': 14}), 12);
      expect(_ac([_giveCustom(null, 15)], scores: {'dex': 14}), 12);
      expect(
        _ac(
          [_giveCustom('autre', 15)],
          scores: {'dex': 14, 'con': 16},
          classes: ['Barbare'],
        ),
        15,
      );
    });
  });

  group('C25 : ajustement manuel, séparé', () {
    for (final (bonus, total) in [(2, 14), (-3, 9)]) {
      test('ajustement $bonus -> CA 12, ajustement $bonus, total $total', () {
        final detail = _character(const [], scores: {'dex': 14}, bonus: bonus);
        expect(detail.armorClass, 12, reason: 'armor_class');
        expect(detail.armorClassBonus, bonus, reason: 'armor_class_bonus');
        expect(
          ArmorClassResolver.resolve(
            abilityScores: detail.abilityScores,
            inventory: detail.inventory,
            classNames: const {},
            subclassNames: const {},
            fightingStyles: const {},
            bonus: detail.armorClassBonus,
          ),
          total,
          reason: 'armor_class_total (tuile du groupe)',
        );
      });
    }
  });

  group('C26 : non équipé, aucun score', () {
    test('armure, bouclier et anneau harmonisé non équipés -> 12', () {
      expect(
        _ac(
          [
            _give('Armure complète', equipped: false),
            _give('Bouclier', equipped: false),
            _give('Anneau de protection', equipped: false, attuned: true),
          ],
          scores: {'dex': 14},
        ),
        12,
      );
    });

    test('intermédiaire 14 sans aucun score -> 14', () {
      expect(_ac([_give('Cuirasse')]), 14);
    });
  });

  group('C27 : décision n° 37, plusieurs armures ou boucliers équipés -> '
      'meilleure CA, quel que soit l\'ordre', () {
    test('C27 / C27r : lourde 18 et légère 11 équipées -> 18 (dans tous les '
        'ordres)', () {
      _expectInAllOrders(
        [_give('Armure complète'), _give('Armure de cuir')],
        18,
        scores: {'dex': 14},
      );
    });

    test('C27s : deux boucliers (2 et 4) -> 16 ; + intermédiaire 14 -> 20', () {
      final shields = [_give('Bouclier'), _give('Bouclier +2')];
      _expectInAllOrders(shields, 16, scores: {'dex': 14});
      _expectInAllOrders(
        [...shields, _give('Cuirasse')],
        20,
        scores: {'dex': 14},
      );
    });

    test('C27m : Moine avec deux boucliers -> 17 (toujours avec bouclier)', () {
      _expectInAllOrders(
        [_give('Bouclier'), _give('Bouclier +2')],
        17,
        scores: {'dex': 16, 'wis': 16},
        classes: ['Moine'],
      );
    });

    test('C27d : écailles de dragon harmonisées + armure complète -> 18 '
        "(l'armure non retenue ne donne rien, ni son +1 « toujours »)", () {
      // Écailles 14 + min(Dex 3, 2) + 1 = 17 ; armure complète 18 -> 18.
      _expectInAllOrders(
        [
          _give("Armure d'écailles de dragon", attuned: true),
          _give('Armure complète'),
        ],
        18,
        scores: {'dex': 16},
      );
    });

    test('C27e : écailles harmonisées + cuirasse -> 17 (meilleure '
        'combinaison choisie bonus compris)', () {
      // Écailles 14 + 2 + 1 = 17 contre cuirasse 14 + 2 = 16.
      _expectInAllOrders(
        [
          _give("Armure d'écailles de dragon", attuned: true),
          _give('Cuirasse'),
        ],
        17,
        scores: {'dex': 16},
      );
    });

    test('C27c : cotte 16 contre armure perso légère 12 +3 -> 18 (bonus '
        'magique de la combinaison)', () {
      _expectInAllOrders(
        [
          _give('Cotte de mailles'),
          _giveCustom('armure', 12, category: 'legere', magic: 3),
        ],
        18,
        scores: {'dex': 16},
      );
    });

    test('C27h : même armure perso non harmonisée -> 16 (la cotte gagne)', () {
      _expectInAllOrders(
        [
          _giveCustom(
            'armure',
            12,
            category: 'legere',
            magic: 3,
            requiresAttunement: true,
          ),
          _give('Cotte de mailles'),
        ],
        16,
        scores: {'dex': 16},
      );
    });

    test('C27a : deux armures + Armure +1 -> 19 (bonus « avec armure » '
        'compté une fois)', () {
      _expectInAllOrders(
        [_give('Armure complète'), _give('Armure de cuir'), _give('Armure +1')],
        19,
        scores: {'dex': 14},
      );
    });
  });

  group('C27, compléments Dart : un objet non retenu ne donne RIEN', () {
    test('armure non retenue : son ac_bonus « avec armure » ne compte pas', () {
      // Armure magique 11 + 2 + 1 = 14 contre armure complète 18 : 18, pas 19.
      _expectInAllOrders(
        [_give('Test armure avec armure +1'), _give('Armure complète')],
        18,
        scores: {'dex': 14},
      );
    });

    test('bouclier non retenu : son ac_bonus « toujours » ne compte pas', () {
      // 12 + 2 + 1 = 15 contre 12 + 4 = 16 : 16, pas 17.
      _expectInAllOrders(
        [_give('Test bouclier toujours +1'), _give('Bouclier +2')],
        16,
        scores: {'dex': 14},
      );
    });

    test('bouclier retenu grâce à son ac_bonus « toujours » : compté une '
        'fois', () {
      // 12 + 2 + 1 = 15 contre bouclier ordinaire 12 + 2 = 14.
      _expectInAllOrders(
        [_give('Bouclier'), _give('Test bouclier toujours +1')],
        15,
        scores: {'dex': 14},
      );
    });

    test('bouclier perso non retenu : son bonus magique ne compte pas', () {
      // 12 + 2 + 1 = 15 contre 12 + 4 = 16 : 16, pas 17.
      _expectInAllOrders(
        [_giveCustom('bouclier', 2, magic: 1), _give('Bouclier +2')],
        16,
        scores: {'dex': 14},
      );
    });

    test('deux armures et deux boucliers : la meilleure paire, dans les 24 '
        'ordres', () {
      // Armure complète 18 + Bouclier +2 4 = 22.
      _expectInAllOrders(
        [
          _give('Cuirasse'),
          _give('Bouclier'),
          _give('Armure complète'),
          _give('Bouclier +2'),
        ],
        22,
        scores: {'dex': 14},
      );
    });

    test('Défense avec deux armures : +1 sur la combinaison retenue', () {
      // Armure complète 18 + 1 = 19 contre cuirasse 14 + 2 + 1 = 17.
      _expectInAllOrders(
        [_give('Cuirasse'), _give('Armure complète')],
        19,
        scores: {'dex': 14},
        style: _defense,
      );
    });

    test('anneau harmonisé avec deux armures : ajouté une seule fois', () {
      _expectInAllOrders(
        [
          _give('Armure de cuir'),
          _give('Anneau de protection', attuned: true),
          _give('Cotte de mailles'),
        ],
        17,
        scores: {'dex': 14},
      );
    });
  });

  group('compléments de regles-dnd (20/11/2026)', () {
    test('Armure +1 avec un bouclier seul (sans armure) -> 14 (bonus « avec '
        'armure » ignoré)', () {
      expect(
        _ac([_give('Bouclier'), _give('Armure +1')], scores: {'dex': 14}),
        14,
      );
    });

    test('Lignage draconique en armure de cuir -> 13 (base draconique non '
        'appliquée)', () {
      expect(
        _ac(
          [_give('Armure de cuir')],
          scores: {'dex': 14},
          subclass: 'Lignage draconique',
        ),
        13,
      );
    });

    test('Bouclier perso 2 +2 à harmoniser, non harmonisé -> 14 (base '
        'seule)', () {
      expect(
        _ac(
          [_giveCustom('bouclier', 2, magic: 2, requiresAttunement: true)],
          scores: {'dex': 14},
        ),
        14,
      );
    });

    test('Anneau et Cape de protection harmonisés -> 14 (deux bonus '
        '« toujours » cumulés)', () {
      expect(
        _ac(
          [
            _give('Anneau de protection', attuned: true),
            _give('Cape de protection', attuned: true),
          ],
          scores: {'dex': 14},
        ),
        14,
      );
    });
  });

  group('données non lues et cas limites', () {
    test('Q0 : quantité non lue, armure équipée en quantité 0 -> 16', () {
      expect(_ac([_give('Cuirasse', quantity: 0)], scores: {'dex': 14}), 16);
    });

    test('SUP : Défense choisie sous « Style de combat supplémentaire » : '
        'ignorée -> 16', () {
      expect(
        _ac(
          [_give('Cuirasse')],
          scores: {'dex': 14},
          style: ('Style de combat supplémentaire', 'Défense'),
        ),
        16,
      );
    });

    test('OTH : comparaison exacte, casse comprise (« défense » ignoré) -> '
        '16', () {
      expect(
        _ac(
          [_give('Cuirasse')],
          scores: {'dex': 14},
          style: ('Style de combat', 'défense'),
        ),
        16,
      );
    });

    test('STR : Force non lue (lourde avec Force 3) ; Con et Sag sans effet '
        'hors Barbare/Moine -> 18', () {
      expect(
        _ac(
          [_give('Armure complète')],
          scores: {'dex': 14, 'str': 3, 'con': 20, 'wis': 20},
        ),
        18,
      );
    });

    test('LVL : Barbare en seconde classe -> 15 ; états, mort et PV non '
        'lus -> 15', () {
      const scores = {'dex': 14, 'con': 16};
      expect(
        _ac(const [], scores: scores, classes: ['Guerrier', 'Barbare']),
        15,
      );
      expect(
        _character(
          const [],
          scores: scores,
          classes: ['Guerrier', 'Barbare'],
          isDead: true,
          currentHp: 0,
          conditions: const [ConditionType.unconscious, ConditionType.prone],
        ).armorClass,
        15,
      );
    });

    test('CUS : armure perso lourde 13 +2 non équipée -> 12 ; équipée -> 15 '
        '(Dex ignorée)', () {
      expect(
        _ac(
          [
            _giveCustom(
              'armure',
              13,
              category: 'lourde',
              magic: 2,
              equipped: false,
            ),
          ],
          scores: {'dex': 14},
        ),
        12,
      );
      expect(
        _ac(
          [_giveCustom('armure', 13, category: 'lourde', magic: 2)],
          scores: {'dex': 14},
        ),
        15,
      );
    });

    test('ROB2 : Robe harmonisée + armure de cuir -> 13 (la base de la robe '
        'ne vaut que sans armure)', () {
      expect(
        _ac(
          [
            _give("Robe de l'archimage", attuned: true),
            _give('Armure de cuir'),
          ],
          scores: {'dex': 14},
        ),
        13,
      );
    });

    test('ARM1 : cotte 16 + bracelets (ignorés avec armure) + anneau (+1) -> '
        '17', () {
      expect(
        _ac(
          [
            _give('Cotte de mailles'),
            _give('Bracelets de défense', attuned: true),
            _give('Anneau de protection', attuned: true),
          ],
          scores: {'dex': 14},
        ),
        17,
      );
    });

    test('FBS : bouclier « base sans armure » 15, sans armure -> 19 ; avec '
        'une cuirasse -> 18', () {
      final shield = _give('pgTAP bouclier base sans armure');
      expect(_ac([shield], scores: {'dex': 14}), 19);
      expect(_ac([shield, _give('Cuirasse')], scores: {'dex': 14}), 18);
    });

    test('FBA : bouclier « avec armure » +1, sans armure -> 14 ; avec une '
        'cuirasse -> 19', () {
      final shield = _give('pgTAP bouclier avec armure');
      expect(_ac([shield], scores: {'dex': 14}), 14);
      expect(_ac([shield, _give('Cuirasse')], scores: {'dex': 14}), 19);
    });

    test('NOCAT : armure perso 15 +2 sans catégorie -> 12 (ignorée)', () {
      expect(
        _ac([_giveCustom('armure', 15, magic: 2)], scores: {'dex': 14}),
        12,
      );
    });
  });
}
