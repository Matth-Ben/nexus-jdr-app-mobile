// Tests de caractérisation (P7, PR 0) de `ArmorProficiencyRules.evaluate` :
// matrice catégorie x source de maîtrise, valeur par valeur. Complète
// `armor_proficiency_rules_test.dart` sans le dupliquer.

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/armor_proficiency_rules.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';

CharacterInventoryItem _gear(
  String name, {
  String? category = 'armure',
  String? acDexBonus,
  String? slot,
  int? itemId = 1,
}) => CharacterInventoryItem(
  id: 'id-$name',
  itemId: itemId,
  name: name,
  category: category,
  quantity: 1,
  equipped: true,
  armorProperties: acDexBonus == null
      ? null
      : CharacterInventoryArmorProperties(
          slot: slot,
          acBase: 2,
          acDexBonus: acDexBonus,
          stealthDisadvantage: false,
        ),
);

final _light = _gear('Cuir', acDexBonus: 'illimite');
final _medium = _gear('Chemise de mailles', acDexBonus: 'max_2');
final _heavy = _gear('Cotte de mailles', acDexBonus: 'aucun');
final _shield = _gear('Bouclier', category: 'bouclier', acDexBonus: 'aucun');

ArmorProficiencyProfile _profile({
  List<String> tokens = const [],
  List<String> feats = const [],
  String? subrace,
  List<String> traits = const [],
  List<ArmorProficiencyClassLevel> classes = const [
    ArmorProficiencyClassLevel(className: 'Guerrier', level: 1),
  ],
}) => ArmorProficiencyProfile(
  tokens: tokens,
  featNames: feats,
  subraceName: subrace,
  racialTraitNames: traits,
  classes: classes,
);

/// Verdicts dans l'ordre (légère, intermédiaire, lourde, bouclier).
List<ArmorProficiency> _row(ArmorProficiencyProfile profile) => [
  ArmorProficiencyRules.evaluate(_light, profile),
  ArmorProficiencyRules.evaluate(_medium, profile),
  ArmorProficiencyRules.evaluate(_heavy, profile),
  ArmorProficiencyRules.evaluate(_shield, profile),
];

const _y = ArmorProficiency.proficient;
const _n = ArmorProficiency.notProficient;
const _u = ArmorProficiency.unknown;

void main() {
  group('matrice des jetons de classe (légère, intermédiaire, lourde, '
      'bouclier)', () {
    test('aucun jeton, classe sans armure (Moine) : tout non maîtrisé', () {
      final p = _profile(
        classes: const [
          ArmorProficiencyClassLevel(className: 'Moine', level: 3),
        ],
      );
      expect(_row(p), [_n, _n, _n, _n]);
    });

    test('un seul jeton à la fois', () {
      expect(_row(_profile(tokens: ['légère'])), [_y, _n, _n, _n]);
      expect(_row(_profile(tokens: ['intermédiaire'])), [_n, _y, _n, _n]);
      expect(_row(_profile(tokens: ['lourde'])), [_n, _n, _y, _n]);
      expect(_row(_profile(tokens: ['boucliers'])), [_n, _n, _n, _y]);
    });

    test('formes équivalentes d\'un jeton : singulier, pluriel, « armure '
        '... », majuscules', () {
      expect(_row(_profile(tokens: ['bouclier'])), [_n, _n, _n, _y]);
      expect(_row(_profile(tokens: ['Armures légères'])), [_y, _n, _n, _n]);
      expect(_row(_profile(tokens: ['armure lourde'])), [_n, _n, _y, _n]);
    });

    test('jeton inconnu : aucune maîtrise (pas de crash)', () {
      expect(_row(_profile(tokens: ['mithral', ''])), [_n, _n, _n, _n]);
    });

    test('jetons du Guerrier complets : tout maîtrisé', () {
      final p = _profile(
        tokens: ['légère', 'intermédiaire', 'lourde', 'boucliers'],
      );
      expect(_row(p), [_y, _y, _y, _y]);
    });
  });

  group('jetons de classe principale vides -> unknown (jamais « non '
      'maîtrisé »)', () {
    test('classe principale avec armure (Guerrier) et jetons vides : '
        'unknown partout', () {
      final p = _profile(
        classes: const [
          ArmorProficiencyClassLevel(
            className: 'Guerrier',
            level: 5,
            isPrimary: true,
          ),
        ],
      );
      expect(_row(p), [_u, _u, _u, _u]);
    });

    test('classe principale sans armure (Magicien, Moine, Ensorceleur) et '
        'jetons vides : verdict ferme « non maîtrisé »', () {
      for (final name in ['Magicien', 'Moine', 'Ensorceleur']) {
        final p = _profile(
          classes: [
            ArmorProficiencyClassLevel(
              className: name,
              level: 1,
              isPrimary: true,
            ),
          ],
        );
        expect(_row(p), [_n, _n, _n, _n], reason: name);
      }
    });

    test('jetons vides sur une classe NON principale : pas unknown', () {
      final p = _profile(
        classes: const [
          ArmorProficiencyClassLevel(className: 'Guerrier', level: 1),
        ],
      );
      expect(_row(p), [_n, _n, _n, _n]);
    });

    test('aucune classe résolue (canEvaluate false) : unknown, même avec '
        'des jetons', () {
      const p = ArmorProficiencyProfile(
        tokens: ['légère', 'intermédiaire', 'lourde', 'boucliers'],
        canEvaluate: false,
      );
      expect(_row(p), [_u, _u, _u, _u]);
    });
  });

  group('objets sans catégorie d\'armure fiable -> unknown', () {
    final full = _profile(
      tokens: ['légère', 'intermédiaire', 'lourde', 'boucliers'],
    );

    test('objet personnalisé, même avec armor_properties : unknown', () {
      final customArmor = _gear(
        'Armure maison',
        acDexBonus: 'aucun',
        itemId: null,
      );
      final customShield = _gear(
        'Bouclier maison',
        category: 'bouclier',
        acDexBonus: 'aucun',
        itemId: null,
      );
      expect(ArmorProficiencyRules.evaluate(customArmor, full), _u);
      expect(ArmorProficiencyRules.evaluate(customShield, full), _u);
      expect(ArmorProficiencyRules.isShield(customShield), isFalse);
      expect(
        ArmorProficiencyRules.isNotProficient(customArmor, _profile()),
        isFalse,
      );
    });

    test('objet personnalisé : unknown aussi pour un personnage sans '
        'aucune maîtrise (jamais « non maîtrisé »)', () {
      final custom = _gear('Armure maison', category: null, itemId: null);
      final nobody = _profile(
        classes: const [
          ArmorProficiencyClassLevel(
            className: 'Magicien',
            level: 1,
            isPrimary: true,
          ),
        ],
      );
      expect(ArmorProficiencyRules.evaluate(custom, nobody), _u);
    });

    test('armure sans armor_properties, arme, équipement : unknown', () {
      for (final item in [
        _gear('Armure', category: 'armure'),
        _gear('Épée', category: 'arme'),
        _gear('Corde', category: 'equipement_general'),
      ]) {
        expect(ArmorProficiencyRules.evaluate(item, full), _u);
      }
    });

    test('bouclier sans armor_properties : reconnu par la catégorie '
        '(bouclier)', () {
      final bare = _gear('Bouclier', category: 'bouclier');
      expect(ArmorProficiencyRules.evaluate(bare, full), _y);
      expect(ArmorProficiencyRules.evaluate(bare, _profile()), _n);
    });
  });

  group('dons : matrice complète', () {
    test('Armure légère : légère seule', () {
      expect(_row(_profile(feats: ['Armure légère'])), [_y, _n, _n, _n]);
    });

    test('Armure intermédiaire : intermédiaire + bouclier', () {
      expect(_row(_profile(feats: ['Armure intermédiaire'])), [_n, _y, _n, _y]);
    });

    test('Armure lourde : lourde seule', () {
      expect(_row(_profile(feats: ['Armure lourde'])), [_n, _n, _y, _n]);
    });

    test('Entraînement aux armes de guerre : légère + intermédiaire + '
        'bouclier', () {
      expect(_row(_profile(feats: ['Entraînement aux armes de guerre'])), [
        _y,
        _y,
        _n,
        _y,
      ]);
    });

    test('un don sans rapport n\'accorde rien', () {
      expect(_row(_profile(feats: ['Chanceux', 'Alerte'])), [_n, _n, _n, _n]);
    });

    test('plusieurs dons se cumulent', () {
      expect(_row(_profile(feats: ['Armure légère', 'Armure lourde'])), [
        _y,
        _n,
        _y,
        _n,
      ]);
    });

    test('maîtrise par don cumulée aux jetons de classe', () {
      expect(_row(_profile(tokens: ['légère'], feats: ['Armure lourde'])), [
        _y,
        _n,
        _y,
        _n,
      ]);
    });
  });

  group('race', () {
    test('Nain des montagnes : légère + intermédiaire, ni lourde ni '
        'bouclier', () {
      expect(_row(_profile(subrace: 'Nain des montagnes')), [_y, _y, _n, _n]);
    });

    test('Nain des collines et sous-race inconnue : rien', () {
      expect(_row(_profile(subrace: 'Nain des collines')), [_n, _n, _n, _n]);
      expect(_row(_profile(subrace: 'Elfe noble')), [_n, _n, _n, _n]);
    });

    test('trait racial seedé du Nain (filet si la sous-race est absente)', () {
      expect(
        _row(_profile(traits: ['Entraînement au combat nain (armures)'])),
        [_y, _y, _n, _n],
      );
    });
  });

  group('sous-classes : matrice niveau x catégorie', () {
    ArmorProficiencyProfile sub(String cls, String subclass, int level) =>
        _profile(
          classes: [
            ArmorProficiencyClassLevel(
              className: cls,
              level: level,
              subclassName: subclass,
              isPrimary: true,
            ),
          ],
          tokens: const ['légère'], // jetons non vides : pas de unknown
        );

    test('Clerc Vie niveau 1 : lourde ajoutée (+ légère du jeton)', () {
      expect(_row(sub('Clerc', 'Vie', 1)), [_y, _n, _y, _n]);
    });

    test('Barde Vaillance : niveau 2 -> intermédiaire/bouclier non acquis '
        'et sous-classe non encore exigée ; niveau 3 -> acquis', () {
      expect(_row(sub('Barde', 'Collège de la vaillance', 2)), [
        _y,
        _n,
        _n,
        _n,
      ]);
      expect(_row(sub('Barde', 'Collège de la vaillance', 3)), [
        _y,
        _y,
        _n,
        _y,
      ]);
    });

    test('Barde Épées : intermédiaire seule (pas de bouclier)', () {
      expect(_row(sub('Barde', 'Collège des épées', 3)), [_y, _y, _n, _n]);
    });

    test('Occultiste Lame maudite : intermédiaire + bouclier dès le 1', () {
      expect(_row(sub('Occultiste', 'Lame maudite', 1)), [_y, _y, _n, _y]);
    });

    test('Artificier Armurier niveau 3 : lourde', () {
      expect(_row(sub('Artificier', 'Armurier', 3)), [_y, _n, _y, _n]);
    });

    test('Magicien Chantelames niveau 2 : légère (le jeton légère est '
        'déjà présent) ; sans le jeton, légère acquise par la sous-classe', () {
      final p = _profile(
        classes: const [
          ArmorProficiencyClassLevel(
            className: 'Magicien',
            level: 2,
            subclassName: 'Chantelames',
            isPrimary: true,
          ),
        ],
        tokens: const ['boucliers'],
      );
      expect(_row(p), [_y, _n, _n, _y]);
    });

    test('Clerc de la Lumière niveau 1 (aucune armure lourde) : ferme '
        '« non maîtrisé » pour la lourde', () {
      expect(_row(sub('Clerc', 'Domaine de la Lumière', 1)), [_y, _n, _n, _n]);
    });

    test('sous-classe non cartographiée d\'une classe à risque : unknown '
        'pour ce que les jetons n\'accordent pas, proficient sinon', () {
      final p = sub('Clerc', 'Domaine inconnu', 1);
      expect(_row(p), [_y, _u, _u, _u]);
    });

    test('la sous-classe d\'une classe ne vaut que pour cette classe', () {
      // « Vie » sur un Guerrier n'accorde rien.
      expect(_row(sub('Guerrier', 'Vie', 5)), [_y, _n, _n, _n]);
    });
  });

  group('multiclassage', () {
    test('Artificier secondaire (jetons légère, intermédiaire, boucliers) '
        '+ Armurier niveau 3 : tout sauf rien', () {
      final p = _profile(
        tokens: ['légère', 'intermédiaire', 'boucliers'],
        classes: const [
          ArmorProficiencyClassLevel(
            className: 'Magicien',
            level: 3,
            isPrimary: true,
          ),
          ArmorProficiencyClassLevel(
            className: 'Artificier',
            level: 3,
            subclassName: 'Armurier',
          ),
        ],
      );
      expect(_row(p), [_y, _y, _y, _y]);
    });

    test('Artificier secondaire sans Armurier : lourde non maîtrisée', () {
      final p = _profile(
        tokens: ['légère', 'intermédiaire', 'boucliers'],
        classes: const [
          ArmorProficiencyClassLevel(
            className: 'Magicien',
            level: 3,
            isPrimary: true,
            subclassName: 'Abjuration',
          ),
          ArmorProficiencyClassLevel(
            className: 'Artificier',
            level: 3,
            subclassName: 'Alchimiste',
          ),
        ],
      );
      expect(_row(p), [_y, _y, _n, _y]);
    });
  });

  group('slot et catégorie', () {
    test('armure magique (slot armure) : catégorie via ac_dex_bonus pour '
        'les trois', () {
      final profile = _profile(tokens: ['légère', 'intermédiaire']);
      for (final entry in {'illimite': _y, 'max_2': _y, 'aucun': _n}.entries) {
        final item = _gear(
          'Magique',
          category: 'objet_magique',
          acDexBonus: entry.key,
          slot: 'armure',
        );
        expect(
          ArmorProficiencyRules.evaluate(item, profile),
          entry.value,
          reason: entry.key,
        );
      }
    });

    test('objet_magique avec armor_properties sans slot : unknown', () {
      final item = _gear(
        'Magique',
        category: 'objet_magique',
        acDexBonus: 'aucun',
      );
      expect(
        ArmorProficiencyRules.evaluate(item, _profile(tokens: ['lourde'])),
        _u,
      );
    });

    test('isNotProficient : vrai seulement pour notProficient (pas pour '
        'unknown)', () {
      final p = _profile(tokens: ['légère']);
      expect(ArmorProficiencyRules.isNotProficient(_light, p), isFalse);
      expect(ArmorProficiencyRules.isNotProficient(_heavy, p), isTrue);
      expect(
        ArmorProficiencyRules.isNotProficient(_gear('x', category: 'arme'), p),
        isFalse,
      );
    });
  });
}
