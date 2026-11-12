// Tests de caractérisation (P7, PR 0) du calcul de CA : ils figent le
// comportement ACTUEL de `ArmorClassCalculator`/`ArmorClassResolver`, valeur
// par valeur, avant d'enrichir les objets personnalisés (armure, bouclier,
// bonus magique). Complète `armor_class_calculator_test.dart` sans le
// dupliquer. Un test qui échoue après un changement volontaire doit être
// relu : il signale un changement de comportement de la CA.

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/armor_class_calculator.dart';
import 'package:personnages/features/characters/domain/armor_class_resolver.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_feat_summary.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';

CharacterInventoryItem _armor({
  String id = 'armor',
  required int acBase,
  required String acDexBonus,
  bool equipped = true,
  String category = 'armure',
  String? slot,
  bool requiresAttunement = false,
  bool isAttuned = false,
}) => CharacterInventoryItem(
  id: id,
  itemId: id.hashCode,
  name: id,
  category: category,
  quantity: 1,
  equipped: equipped,
  requiresAttunement: requiresAttunement,
  isAttuned: isAttuned,
  armorProperties: CharacterInventoryArmorProperties(
    acBase: acBase,
    acDexBonus: acDexBonus,
    stealthDisadvantage: false,
    slot: slot,
  ),
);

CharacterInventoryItem _shield({
  String id = 'shield',
  int acBase = 2,
  bool equipped = true,
}) => _armor(
  id: id,
  acBase: acBase,
  acDexBonus: 'aucun',
  equipped: equipped,
  category: 'bouclier',
);

CharacterInventoryItem _bonusItem({
  String id = 'bonus',
  int? bonus,
  String? kind,
  bool equipped = true,
  bool requiresAttunement = false,
  bool isAttuned = false,
}) => CharacterInventoryItem(
  id: id,
  itemId: id.hashCode,
  name: id,
  category: 'objet_magique',
  quantity: 1,
  equipped: equipped,
  requiresAttunement: requiresAttunement,
  isAttuned: isAttuned,
  acBonus: bonus,
  acBonusKind: kind,
);

int _ac(
  Map<String, int> scores,
  List<CharacterInventoryItem> inventory, {
  Set<String> classes = const {},
  Set<String> subclasses = const {},
  Set<String> styles = const {},
}) => ArmorClassCalculator.compute(
  abilityScores: scores,
  inventory: inventory,
  classNames: classes,
  subclassNames: subclasses,
  fightingStyles: styles,
);

void main() {
  group('sans armure : valeurs limites', () {
    test('Dex 20 (+5) : 15', () {
      expect(_ac({'dex': 20}, const []), 15);
    });

    test('Dex 1 (-5) : 5, aucun plancher', () {
      expect(_ac({'dex': 1}, const []), 5);
    });

    test('Défense sans armure ni armure : aucun effet, même avec bouclier', () {
      expect(
        _ac(
          {'dex': 14},
          [_shield()],
          styles: {ArmorClassCalculator.defenseFightingStyle},
        ),
        14, // 10 + 2 + 2, pas de +1
      );
    });

    test('objet personnalisé équipé (sans armor_properties ni ac_bonus) : '
        'aucun effet', () {
      const custom = CharacterInventoryItem(
        id: 'perso',
        name: 'Armure maison',
        quantity: 1,
        equipped: true,
      );
      expect(_ac({'dex': 14}, const [custom]), 12);
    });
  });

  group('armure : plafond de Dex et valeurs limites', () {
    test('légère 11 + Dex 20 (+5) : 16, sans plafond', () {
      expect(
        _ac({'dex': 20}, [_armor(acBase: 11, acDexBonus: 'illimite')]),
        16,
      );
    });

    test('légère 11 + Dex 6 (-2) : 9, le malus s\'applique', () {
      expect(_ac({'dex': 6}, [_armor(acBase: 11, acDexBonus: 'illimite')]), 9);
    });

    test('intermédiaire 14 : Dex 20 -> 16, Dex 16 -> 16, Dex 14 -> 16 '
        '(plafond atteint à +2)', () {
      final armor = _armor(acBase: 14, acDexBonus: 'max_2');
      expect(_ac({'dex': 20}, [armor]), 16);
      expect(_ac({'dex': 16}, [armor]), 16);
      expect(_ac({'dex': 14}, [armor]), 16);
    });

    test('intermédiaire 14 : Dex 12 (+1) -> 15, Dex 6 (-2) -> 12', () {
      final armor = _armor(acBase: 14, acDexBonus: 'max_2');
      expect(_ac({'dex': 12}, [armor]), 15);
      expect(_ac({'dex': 6}, [armor]), 12);
    });

    test('lourde 18 : Dex 20 et Dex 6 sans effet (pas de malus non plus)', () {
      final armor = _armor(acBase: 18, acDexBonus: 'aucun');
      expect(_ac({'dex': 20}, [armor]), 18);
      expect(_ac({'dex': 6}, [armor]), 18);
    });

    test('ac_dex_bonus inattendu : traité comme « aucun » (pas de crash)', () {
      expect(_ac({'dex': 18}, [_armor(acBase: 13, acDexBonus: '???')]), 13);
    });

    test('aucune caractéristique : Dex 10 par défaut, armure intermédiaire '
        '14 -> 14', () {
      expect(_ac(const {}, [_armor(acBase: 14, acDexBonus: 'max_2')]), 14);
    });

    test('bouclier : utilise son ac_base (3 -> +3), jamais le Dex', () {
      expect(_ac({'dex': 20}, [_shield(acBase: 3)]), 18); // 10 + 5 + 3
      expect(
        _ac({'dex': 20}, [_armor(acBase: 18, acDexBonus: 'aucun'), _shield()]),
        20,
      );
    });

    test('bouclier listé avant l\'armure : même résultat', () {
      expect(
        _ac({'dex': 14}, [_shield(), _armor(acBase: 13, acDexBonus: 'max_2')]),
        17,
      );
    });

    test('Défense : +1 avec armure (légère, intermédiaire, lourde) et se '
        'cumule avec le bouclier', () {
      const defense = {ArmorClassCalculator.defenseFightingStyle};
      expect(
        _ac(
          {'dex': 14},
          [_armor(acBase: 13, acDexBonus: 'max_2')],
          styles: defense,
        ),
        16,
      );
      expect(
        _ac(
          {'dex': 20},
          [_armor(acBase: 14, acDexBonus: 'max_2'), _shield()],
          styles: defense,
        ),
        19, // 14 + 2 + 2 + 1
      );
    });

    test('Défense : la comparaison est sensible à la casse et au libellé '
        'exact', () {
      final armor = _armor(acBase: 13, acDexBonus: 'max_2');
      expect(_ac({'dex': 14}, [armor], styles: {'défense'}), 15);
      expect(_ac({'dex': 14}, [armor], styles: {'Archerie'}), 15);
    });
  });

  group('aptitudes de classe : valeurs limites', () {
    test('Barbare avec Con 6 (-2) : la meilleure base reste 10 + Dex', () {
      expect(
        _ac(
          {'dex': 14, 'con': 6},
          const [],
          classes: {ArmorClassCalculator.barbarianClassName},
        ),
        12,
      );
    });

    test('Moine avec Sag 6 (-2) : la meilleure base reste 10 + Dex', () {
      expect(
        _ac(
          {'dex': 14, 'wis': 6},
          const [],
          classes: {ArmorClassCalculator.monkClassName},
        ),
        12,
      );
    });

    test('Moine en armure : pas de Sagesse', () {
      expect(
        _ac(
          {'dex': 14, 'wis': 18},
          [_armor(acBase: 13, acDexBonus: 'max_2')],
          classes: {ArmorClassCalculator.monkClassName},
        ),
        15,
      );
    });

    test('nom de classe en minuscules ou inconnu : aucune Défense sans '
        'armure (comparaison exacte)', () {
      expect(_ac({'dex': 14, 'con': 16}, const [], classes: {'barbare'}), 12);
      expect(_ac({'dex': 14, 'con': 16}, const [], classes: {'Guerrier'}), 12);
    });

    test('Lignage draconique : Dex 20 -> 18, bouclier -> +2, ignoré en '
        'armure', () {
      const sub = {ArmorClassCalculator.draconicSubclassName};
      expect(_ac({'dex': 20}, const [], subclasses: sub), 18);
      expect(_ac({'dex': 14}, [_shield()], subclasses: sub), 17);
      expect(
        _ac(
          {'dex': 14},
          [_armor(acBase: 18, acDexBonus: 'aucun')],
          subclasses: sub,
        ),
        18,
      );
    });

    test('Lignage draconique : seul le nom de sous-classe compte (aucune '
        'vérification de la classe)', () {
      expect(
        _ac(
          {'dex': 14},
          const [],
          classes: {'Guerrier'},
          subclasses: {ArmorClassCalculator.draconicSubclassName},
        ),
        15,
      );
    });

    test('meilleure base : Barbare Con 20 (17) bat draconique (15) ; Moine '
        'Sag 20 (17) bat draconique (15)', () {
      expect(
        _ac(
          {'dex': 14, 'con': 20},
          const [],
          classes: {ArmorClassCalculator.barbarianClassName},
          subclasses: {ArmorClassCalculator.draconicSubclassName},
        ),
        17,
      );
      expect(
        _ac(
          {'dex': 14, 'wis': 20},
          const [],
          classes: {ArmorClassCalculator.monkClassName},
          subclasses: {ArmorClassCalculator.draconicSubclassName},
        ),
        17,
      );
    });
  });

  group('bonus d\'objet ac_bonus / ac_bonus_kind (Dex 14, +2)', () {
    final armor = _armor(acBase: 13, acDexBonus: 'max_2'); // 15 sans bonus
    const scores = {'dex': 14, 'con': 16, 'wis': 18};

    test('toujours : +bonus sans armure (13) et avec armure (16)', () {
      final item = _bonusItem(bonus: 1, kind: 'toujours');
      expect(_ac(scores, [item]), 13);
      expect(_ac(scores, [item, armor]), 16);
    });

    test('toujours : s\'applique aussi avec un bouclier seul', () {
      final item = _bonusItem(bonus: 1, kind: 'toujours');
      expect(_ac(scores, [item, _shield()]), 15); // 10 + 2 + 2 + 1
    });

    test('avec_armure : ignoré sans armure (12), compté avec (16)', () {
      final item = _bonusItem(bonus: 1, kind: 'avec_armure');
      expect(_ac(scores, [item]), 12);
      expect(_ac(scores, [item, armor]), 16);
    });

    test('avec_armure : un bouclier seul ne suffit pas', () {
      final item = _bonusItem(bonus: 1, kind: 'avec_armure');
      expect(_ac(scores, [item, _shield()]), 14);
    });

    test('avec_armure : une armure non équipée ne suffit pas', () {
      final item = _bonusItem(bonus: 1, kind: 'avec_armure');
      expect(
        _ac(scores, [
          item,
          _armor(acBase: 13, acDexBonus: 'max_2', equipped: false),
        ]),
        12,
      );
    });

    test('sans_armure_ni_bouclier : compté seul (14), ignoré avec armure '
        '(15), avec bouclier (14) ou les deux (17)', () {
      final item = _bonusItem(bonus: 2, kind: 'sans_armure_ni_bouclier');
      expect(_ac(scores, [item]), 14);
      expect(_ac(scores, [item, armor]), 15);
      expect(_ac(scores, [item, _shield()]), 14); // 10 + 2 + 2, bonus ignoré
      expect(_ac(scores, [item, armor, _shield()]), 17);
    });

    test('base_sans_armure 15 : 15 + Dex (17) sans armure, ignoré avec '
        'armure (15), bouclier cumulé (19)', () {
      final item = _bonusItem(bonus: 15, kind: 'base_sans_armure');
      expect(_ac(scores, [item]), 17);
      expect(_ac(scores, [item, armor]), 15);
      expect(_ac(scores, [item, _shield()]), 19);
    });

    test('base_sans_armure : concurrence les autres bases sans armure '
        '(la meilleure gagne)', () {
      final low = _bonusItem(id: 'low', bonus: 11, kind: 'base_sans_armure');
      // Barbare : 10 + 2 + 3 = 15 > 11 + 2 = 13.
      expect(
        _ac(scores, [low], classes: {ArmorClassCalculator.barbarianClassName}),
        15,
      );
      // Moine : 10 + 2 + 4 = 16 < 15 + 2 = 17.
      final robe = _bonusItem(id: 'robe', bonus: 15, kind: 'base_sans_armure');
      expect(
        _ac(scores, [robe], classes: {ArmorClassCalculator.monkClassName}),
        17,
      );
      // Deux objets : la plus haute base seule compte (pas de somme).
      expect(_ac(scores, [low, robe]), 17);
    });

    test('kind absent, inconnu ou bonus nul : aucun effet', () {
      expect(_ac(scores, [_bonusItem(bonus: 3)]), 12);
      expect(_ac(scores, [_bonusItem(bonus: 3, kind: 'bizarre')]), 12);
      expect(_ac(scores, [_bonusItem(kind: 'toujours')]), 12);
    });

    test('plusieurs bonus s\'additionnent ; un bonus négatif (objet maudit) '
        'réduit la CA', () {
      expect(
        _ac(scores, [
          _bonusItem(id: 'a', bonus: 1, kind: 'toujours'),
          _bonusItem(id: 'b', bonus: 2, kind: 'toujours'),
        ]),
        15,
      );
      expect(_ac(scores, [_bonusItem(bonus: -1, kind: 'toujours')]), 11);
    });

    test('combinaison complète : armure lourde 16, bouclier, Défense, '
        '« toujours » +1 et « avec_armure » +1 -> 21', () {
      expect(
        _ac(
          {'dex': 20},
          [
            _armor(acBase: 16, acDexBonus: 'aucun'),
            _shield(),
            _bonusItem(id: 'a', bonus: 1, kind: 'toujours'),
            _bonusItem(id: 'b', bonus: 1, kind: 'avec_armure'),
          ],
          styles: {ArmorClassCalculator.defenseFightingStyle},
        ),
        21,
      );
    });
  });

  group('harmonisation et équipement des objets à bonus (Dex 14)', () {
    const scores = {'dex': 14};

    test(
      'requiert une harmonisation et non harmonisé : bonus suspendu (12)',
      () {
        for (final kind in ['toujours', 'base_sans_armure']) {
          final item = _bonusItem(
            bonus: kind == 'toujours' ? 1 : 15,
            kind: kind,
            requiresAttunement: true,
          );
          expect(_ac(scores, [item]), 12, reason: kind);
        }
        expect(
          _ac(scores, [
            _bonusItem(bonus: 1, kind: 'avec_armure', requiresAttunement: true),
            _armor(acBase: 13, acDexBonus: 'max_2'),
          ]),
          15,
        );
        expect(
          _ac(scores, [
            _bonusItem(
              bonus: 2,
              kind: 'sans_armure_ni_bouclier',
              requiresAttunement: true,
            ),
          ]),
          12,
        );
      },
    );

    test('requiert une harmonisation et harmonisé : bonus actif', () {
      final item = _bonusItem(
        bonus: 1,
        kind: 'toujours',
        requiresAttunement: true,
        isAttuned: true,
      );
      expect(_ac(scores, [item]), 13);
    });

    test('ne requiert pas d\'harmonisation : is_attuned est sans effet '
        '(bonus actif dans les deux cas)', () {
      expect(_ac(scores, [_bonusItem(bonus: 1, kind: 'toujours')]), 13);
      expect(
        _ac(scores, [_bonusItem(bonus: 1, kind: 'toujours', isAttuned: true)]),
        13,
      );
    });

    test('non équipé : bonus ignoré, harmonisé ou non', () {
      expect(
        _ac(scores, [_bonusItem(bonus: 1, kind: 'toujours', equipped: false)]),
        12,
      );
      expect(
        _ac(scores, [
          _bonusItem(
            bonus: 1,
            kind: 'toujours',
            equipped: false,
            requiresAttunement: true,
            isAttuned: true,
          ),
        ]),
        12,
      );
    });

    test('COMPORTEMENT ACTUEL : l\'harmonisation ne suspend que ac_bonus ; '
        'la base d\'une armure/bouclier magique (armor_properties) compte '
        'même non harmonisée', () {
      final magicArmor = _armor(
        acBase: 16,
        acDexBonus: 'aucun',
        category: 'objet_magique',
        slot: 'armure',
        requiresAttunement: true,
      );
      final magicShield = _armor(
        id: 'magic-shield',
        acBase: 4,
        acDexBonus: 'aucun',
        category: 'objet_magique',
        slot: 'bouclier',
        requiresAttunement: true,
      );
      expect(_ac(scores, [magicArmor]), 16);
      expect(_ac(scores, [magicShield]), 10 + 2 + 4);
    });
  });

  group('plusieurs armures/boucliers équipés : le premier de chaque '
      'emplacement (comportement actuel, « Non couvert »)', () {
    const scores = {'dex': 14};

    test('deux armures équipées : la première de la liste', () {
      final heavy = _armor(id: 'heavy', acBase: 18, acDexBonus: 'aucun');
      final light = _armor(id: 'light', acBase: 11, acDexBonus: 'illimite');
      expect(_ac(scores, [heavy, light]), 18);
      expect(_ac(scores, [light, heavy]), 13);
    });

    test('une armure non équipée est sautée : la première ÉQUIPÉE compte', () {
      expect(
        _ac(scores, [
          _armor(id: 'a', acBase: 18, acDexBonus: 'aucun', equipped: false),
          _armor(id: 'b', acBase: 13, acDexBonus: 'max_2'),
        ]),
        15,
      );
    });

    test('deux boucliers équipés : seul le premier compte (pas de somme)', () {
      final two = _shield(id: 's2', acBase: 3);
      final one = _shield(id: 's1');
      expect(_ac(scores, [one, two]), 14); // 10 + 2 + 2
      expect(_ac(scores, [two, one]), 15); // 10 + 2 + 3
    });

    test('un bouclier magique (slot bouclier) occupe le même emplacement '
        'qu\'un bouclier ordinaire', () {
      final magic = _armor(
        id: 'm',
        acBase: 4,
        acDexBonus: 'aucun',
        category: 'objet_magique',
        slot: 'bouclier',
      );
      expect(_ac(scores, [_shield(), magic]), 14);
      expect(_ac(scores, [magic, _shield()]), 16);
    });

    test('le slot prime sur la catégorie ; une ligne « bouclier » sans '
        'armor_properties est ignorée', () {
      final slotShield = _armor(
        acBase: 2,
        acDexBonus: 'aucun',
        category: 'armure',
        slot: 'bouclier',
      );
      expect(_ac(scores, [slotShield]), 14); // traité comme bouclier
      const empty = CharacterInventoryItem(
        id: 'x',
        itemId: 9,
        name: 'Bouclier sans données',
        category: 'bouclier',
        quantity: 1,
        equipped: true,
      );
      expect(_ac(scores, const [empty]), 12);
    });
  });

  group('ArmorClassResolver.resolve', () {
    test('sans bonus : identique à ArmorClassCalculator.compute', () {
      final inventory = [_armor(acBase: 14, acDexBonus: 'max_2'), _shield()];
      expect(
        ArmorClassResolver.resolve(
          abilityScores: const {'dex': 18},
          inventory: inventory,
          classNames: const {},
          subclassNames: const {},
          fightingStyles: const {},
        ),
        18, // 14 + 2 + 2
      );
    });

    test('bonus manuel : ajouté au calcul, positif ou négatif', () {
      int resolve(int bonus) => ArmorClassResolver.resolve(
        abilityScores: const {'dex': 14},
        inventory: const [],
        classNames: const {},
        subclassNames: const {},
        fightingStyles: const {},
        bonus: bonus,
      );
      expect(resolve(0), 12);
      expect(resolve(3), 15);
      expect(resolve(-3), 9);
    });

    test('transmet classes, sous-classes et styles au calcul', () {
      expect(
        ArmorClassResolver.resolve(
          abilityScores: const {'dex': 14, 'con': 16},
          inventory: const [],
          classNames: const {ArmorClassCalculator.barbarianClassName},
          subclassNames: const {},
          fightingStyles: const {},
        ),
        15,
      );
      expect(
        ArmorClassResolver.resolve(
          abilityScores: const {'dex': 14},
          inventory: const [],
          classNames: const {},
          subclassNames: const {ArmorClassCalculator.draconicSubclassName},
          fightingStyles: const {},
        ),
        15,
      );
      expect(
        ArmorClassResolver.resolve(
          abilityScores: const {'dex': 14},
          inventory: [_armor(acBase: 13, acDexBonus: 'max_2')],
          classNames: const {},
          subclassNames: const {},
          fightingStyles: const {ArmorClassCalculator.defenseFightingStyle},
        ),
        16,
      );
    });
  });

  group('D215 : don Maître de l\'armure intermédiaire', () {
    // RAW (Medium Armor Master, 5e) : avec une armure intermédiaire, le
    // plafond du modificateur de Dextérité passe de +2 à +3 (Dex 16+).
    // Une chemise de mailles/cuirasse 14 avec Dex 16 (+3) devrait donc
    // donner 17. COMPORTEMENT ACTUEL (bug connu D215) : le calculateur ne
    // reçoit aucune information sur les dons, le plafond reste +2 -> 16.
    // La future correction devra casser CE test volontairement (attendre 17).
    test('D215 : le don n\'élève pas le plafond de Dex à +3 (actuel : 16, '
        'RAW attendu : 17)', () {
      final detail = CharacterDetail(
        id: 'c',
        name: 'Maître des armures',
        classes: const [],
        xp: 0,
        currentHp: 1,
        maxHp: 1,
        temporaryHp: 0,
        abilityScores: const {'dex': 16},
        inventory: [_armor(acBase: 14, acDexBonus: 'max_2')],
        featNames: const ["Maître de l'armure intermédiaire"],
        feats: const [
          CharacterFeatSummary(
            name: "Maître de l'armure intermédiaire",
            description: '',
          ),
        ],
      );
      expect(detail.armorClass, 16); // RAW : 17
    });

    test('D215 : sans don non plus, le plafond +2 (Dex 16 -> 16) ; le '
        'calculateur n\'a aucun paramètre de dons', () {
      expect(_ac({'dex': 16}, [_armor(acBase: 14, acDexBonus: 'max_2')]), 16);
    });
  });
}
