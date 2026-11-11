import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/armor_proficiency_rules.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
import 'package:personnages/features/characters/domain/multiclass_proficiencies.dart';

CharacterInventoryItem _item(
  String name, {
  required String? category,
  String? acDexBonus,
  String? slot,
  int? itemId = 1,
  int? acBonus,
  String? acBonusKind,
}) => CharacterInventoryItem(
  id: 'id-$name',
  itemId: itemId,
  name: name,
  category: category,
  quantity: 1,
  equipped: false,
  acBonus: acBonus,
  acBonusKind: acBonusKind,
  armorProperties: acDexBonus == null
      ? null
      : CharacterInventoryArmorProperties(
          slot: slot,
          acBase: 2,
          acDexBonus: acDexBonus,
          stealthDisadvantage: false,
        ),
);

final _leather = _item(
  'Armure de cuir',
  category: 'armure',
  acDexBonus: 'illimite',
);
final _chainShirt = _item(
  'Chemise de mailles',
  category: 'armure',
  acDexBonus: 'max_2',
);
final _chainMail = _item(
  'Cotte de mailles',
  category: 'armure',
  acDexBonus: 'aucun',
);
final _shield = _item('Bouclier', category: 'bouclier', acDexBonus: 'illimite');
// Bouclier magique : `illimite` ressemble à une armure légère, le slot tranche.
final _magicShield = _item(
  'Bouclier +1',
  category: 'objet_magique',
  acDexBonus: 'illimite',
  slot: 'bouclier',
);

ArmorProficiencyProfile _profile({
  List<String> tokens = const [],
  List<String> feats = const [],
  String? subrace,
  List<ArmorProficiencyClassLevel> classes = const [
    ArmorProficiencyClassLevel(className: 'Magicien', level: 1),
  ],
}) => ArmorProficiencyProfile(
  tokens: tokens,
  featNames: feats,
  subraceName: subrace,
  classes: classes,
);

ArmorProficiency _eval(
  CharacterInventoryItem item,
  ArmorProficiencyProfile profile,
) => ArmorProficiencyRules.evaluate(item, profile);

const _fighterTokens = ['légère', 'intermédiaire', 'lourde', 'boucliers'];

void main() {
  group('ArmorProficiencyRules.evaluate', () {
    test('Magicien + cotte de mailles : non maîtrisé', () {
      expect(_eval(_chainMail, _profile()), ArmorProficiency.notProficient);
      expect(_eval(_leather, _profile()), ArmorProficiency.notProficient);
      expect(_eval(_shield, _profile()), ArmorProficiency.notProficient);
    });

    test('Guerrier + cotte de mailles : maîtrisé', () {
      final p = _profile(
        tokens: _fighterTokens,
        classes: const [
          ArmorProficiencyClassLevel(className: 'Guerrier', level: 1),
        ],
      );
      expect(_eval(_chainMail, p), ArmorProficiency.proficient);
      expect(_eval(_shield, p), ArmorProficiency.proficient);
    });

    test('Magicien 1 / Guerrier 1 : légère, intermédiaire, bouclier '
        'maîtrisés, lourde non', () {
      final p = _profile(
        tokens: MulticlassProficiencies.multiclassArmorProficiencyTokensFor(
          'Guerrier',
        ),
      );
      expect(_eval(_leather, p), ArmorProficiency.proficient);
      expect(_eval(_chainShirt, p), ArmorProficiency.proficient);
      expect(_eval(_shield, p), ArmorProficiency.proficient);
      expect(_eval(_chainMail, p), ArmorProficiency.notProficient);
    });

    test('Magicien 1 / Clerc 1 : boucliers maîtrisés, lourde non', () {
      final p = _profile(
        tokens: MulticlassProficiencies.multiclassArmorProficiencyTokensFor(
          'Clerc',
        ),
      );
      expect(_eval(_shield, p), ArmorProficiency.proficient);
      expect(_eval(_chainMail, p), ArmorProficiency.notProficient);
    });

    test('Barbare multiclassé : bouclier seul', () {
      final p = _profile(
        tokens: MulticlassProficiencies.multiclassArmorProficiencyTokensFor(
          'Barbare',
        ),
      );
      expect(_eval(_shield, p), ArmorProficiency.proficient);
      expect(_eval(_leather, p), ArmorProficiency.notProficient);
    });

    test('Artificier multiclassé : légère, intermédiaire et boucliers', () {
      final p = _profile(
        tokens: MulticlassProficiencies.multiclassArmorProficiencyTokensFor(
          'Artificier',
        ),
      );
      expect(_eval(_leather, p), ArmorProficiency.proficient);
      expect(_eval(_chainShirt, p), ArmorProficiency.proficient);
      expect(_eval(_shield, p), ArmorProficiency.proficient);
      expect(_eval(_chainMail, p), ArmorProficiency.notProficient);
    });

    test('jetons au pluriel, accentués ou non, en majuscules', () {
      final p = _profile(tokens: ['Armures LEGERES', 'Intermediaires']);
      expect(_eval(_leather, p), ArmorProficiency.proficient);
      expect(_eval(_chainShirt, p), ArmorProficiency.proficient);
      expect(_eval(_shield, p), ArmorProficiency.notProficient);
    });
  });

  group('slot et catégorie', () {
    test(
      'bouclier magique (slot bouclier, illimite) : bouclier, pas légère',
      () {
        final onlyLight = _profile(tokens: ['légère']);
        expect(_eval(_magicShield, onlyLight), ArmorProficiency.notProficient);
        final onlyShields = _profile(tokens: ['boucliers']);
        expect(_eval(_magicShield, onlyShields), ArmorProficiency.proficient);
        expect(ArmorProficiencyRules.isShield(_magicShield), isTrue);
        expect(ArmorProficiencyRules.isShield(_leather), isFalse);
      },
    );

    test('armure magique de type fixe (slot armure) : catégorie via Dex', () {
      final magicMail = _item(
        'Cotte de mailles +1',
        category: 'objet_magique',
        acDexBonus: 'aucun',
        slot: 'armure',
      );
      expect(_eval(magicMail, _profile()), ArmorProficiency.notProficient);
      expect(
        _eval(magicMail, _profile(tokens: ['lourde'])),
        ArmorProficiency.proficient,
      );
    });
  });

  group('unknown : ne jamais deviner', () {
    final nobody = _profile();

    test("Armure +N / mithral générique sans ligne d'armure de base", () {
      final plusOne = _item(
        'Armure +1',
        category: 'objet_magique',
        acBonus: 1,
        acBonusKind: 'avec_armure',
      );
      expect(_eval(plusOne, nobody), ArmorProficiency.unknown);
    });

    test("robe de l'archimage, bracelets, anneau de protection", () {
      for (final name in [
        "Robe de l'archimage",
        'Bracelets de défense',
        'Anneau de protection',
      ]) {
        final item = _item(
          name,
          category: 'objet_magique',
          acBonus: 1,
          acBonusKind: 'toujours',
        );
        expect(_eval(item, nobody), ArmorProficiency.unknown, reason: name);
      }
    });

    test('objet personnalisé', () {
      final custom = _item('Armure maison', category: null, itemId: null);
      expect(_eval(custom, nobody), ArmorProficiency.unknown);
    });

    test('catégorie armure sans armor_properties', () {
      final noProps = _item('Armure', category: 'armure');
      expect(_eval(noProps, nobody), ArmorProficiency.unknown);
    });

    test('ac_dex_bonus hors ensemble contraint', () {
      final odd = _item('Armure', category: 'armure', acDexBonus: '???');
      expect(_eval(odd, nobody), ArmorProficiency.unknown);
    });

    test('objet non armure : jamais de badge', () {
      final sword = _item('Épée longue', category: 'arme');
      final rope = _item('Corde', category: 'equipement_general');
      expect(_eval(sword, nobody), ArmorProficiency.unknown);
      expect(_eval(rope, nobody), ArmorProficiency.unknown);
    });

    test('fiche sans classe résolue : indécidable', () {
      const p = ArmorProficiencyProfile(canEvaluate: false);
      expect(_eval(_chainMail, p), ArmorProficiency.unknown);
    });

    test("le don Maître de l'armure intermédiaire ne change pas la "
        'catégorie ni ne donne la maîtrise', () {
      final p = _profile(feats: ["Maître de l'armure intermédiaire"]);
      expect(_eval(_chainShirt, p), ArmorProficiency.notProficient);
    });
  });

  group('Druide', () {
    final druid = _profile(
      tokens: const [
        'légère',
        'intermédiaire (non métallique)',
        'boucliers (non métalliques)',
      ],
      classes: const [
        ArmorProficiencyClassLevel(className: 'Druide', level: 3),
      ],
    );

    test('chemise de mailles et bouclier métalliques : aucun badge', () {
      expect(_eval(_chainShirt, druid), ArmorProficiency.proficient);
      expect(_eval(_shield, druid), ArmorProficiency.proficient);
      expect(_eval(_magicShield, druid), ArmorProficiency.proficient);
    });

    test('la lourde reste non maîtrisée', () {
      expect(_eval(_chainMail, druid), ArmorProficiency.notProficient);
    });

    test('Druide secondaire (jetons de multiclassage) : idem', () {
      final p = _profile(
        tokens: MulticlassProficiencies.multiclassArmorProficiencyTokensFor(
          'Druide',
        ),
      );
      expect(_eval(_chainShirt, p), ArmorProficiency.proficient);
      expect(_eval(_shield, p), ArmorProficiency.proficient);
    });
  });

  group('dons', () {
    test('Armure légère', () {
      final p = _profile(feats: ['Armure légère']);
      expect(_eval(_leather, p), ArmorProficiency.proficient);
      expect(_eval(_chainShirt, p), ArmorProficiency.notProficient);
    });

    test('Armure intermédiaire : intermédiaire + boucliers', () {
      final p = _profile(feats: ['Armure intermédiaire']);
      expect(_eval(_chainShirt, p), ArmorProficiency.proficient);
      expect(_eval(_shield, p), ArmorProficiency.proficient);
      expect(_eval(_chainMail, p), ArmorProficiency.notProficient);
    });

    test('Armure lourde', () {
      final p = _profile(feats: ['Armure lourde']);
      expect(_eval(_chainMail, p), ArmorProficiency.proficient);
      expect(_eval(_shield, p), ArmorProficiency.notProficient);
    });

    test('don 2024 seedé « Entraînement aux armes de guerre »', () {
      final p = _profile(feats: ['Entraînement aux armes de guerre']);
      expect(_eval(_leather, p), ArmorProficiency.proficient);
      expect(_eval(_chainShirt, p), ArmorProficiency.proficient);
      expect(_eval(_shield, p), ArmorProficiency.proficient);
      expect(_eval(_chainMail, p), ArmorProficiency.notProficient);
    });
  });

  group("sous-classes (niveau d'acquisition)", () {
    ArmorProficiencyProfile sub(String cls, String subclass, int level) =>
        _profile(
          classes: [
            ArmorProficiencyClassLevel(
              className: cls,
              level: level,
              subclassName: subclass,
            ),
          ],
        );

    test('Clerc de la Vie : lourde dès le niveau 1', () {
      expect(
        _eval(_chainMail, sub('Clerc', 'Domaine de la Vie', 1)),
        ArmorProficiency.proficient,
      );
      expect(
        _eval(_chainMail, sub('Clerc', 'Vie', 1)),
        ArmorProficiency.proficient,
      );
    });

    test('domaines du Clerc donnant la lourde', () {
      for (final d in [
        'Guerre',
        'Nature',
        'Tempête',
        'Forge',
        'Ordre',
        'Crépuscule',
      ]) {
        expect(
          _eval(_chainMail, sub('Clerc', d, 1)),
          ArmorProficiency.proficient,
          reason: d,
        );
      }
      // Domaine sans armure lourde.
      expect(
        _eval(_chainMail, sub('Clerc', 'Savoir', 5)),
        ArmorProficiency.notProficient,
      );
    });

    test('Barde Vaillance : niveau 2 pas encore, niveau 3 oui', () {
      expect(
        _eval(_chainShirt, sub('Barde', 'Collège de la vaillance', 2)),
        ArmorProficiency.notProficient,
      );
      final lvl3 = sub('Barde', 'Collège de la vaillance', 3);
      expect(_eval(_chainShirt, lvl3), ArmorProficiency.proficient);
      expect(_eval(_shield, lvl3), ArmorProficiency.proficient);
      expect(_eval(_chainMail, lvl3), ArmorProficiency.notProficient);
    });

    test('Barde Collège des épées / lames : intermédiaire seule', () {
      final p = sub('Barde', 'Collège des épées', 3);
      expect(_eval(_chainShirt, p), ArmorProficiency.proficient);
      expect(_eval(_shield, p), ArmorProficiency.notProficient);
      expect(
        _eval(_chainShirt, sub('Barde', 'Collège des lames', 3)),
        ArmorProficiency.proficient,
      );
    });

    test('Chantelames : légère dès le niveau 2', () {
      expect(
        _eval(_leather, sub('Magicien', 'Chantelames', 1)),
        ArmorProficiency.notProficient,
      );
      expect(
        _eval(_leather, sub('Magicien', 'Chantelames', 2)),
        ArmorProficiency.proficient,
      );
    });

    test('Occultiste Lame maudite : intermédiaire + boucliers dès 1', () {
      final p = sub('Occultiste', 'Lame maudite', 1);
      expect(_eval(_chainShirt, p), ArmorProficiency.proficient);
      expect(_eval(_shield, p), ArmorProficiency.proficient);
    });

    test('Artificier Armurier : lourde dès le niveau 3', () {
      expect(
        _eval(_chainMail, sub('Artificier', 'Armurier', 2)),
        ArmorProficiency.notProficient,
      );
      expect(
        _eval(_chainMail, sub('Artificier', 'Armurier', 3)),
        ArmorProficiency.proficient,
      );
    });

    test("la sous-classe d'une autre classe n'accorde rien (un nom inconnu "
        'du Magicien reste indécidable)', () {
      expect(
        _eval(_chainMail, sub('Magicien', 'Forge', 5)),
        ArmorProficiency.unknown,
      );
      expect(
        _eval(_chainMail, sub('Magicien', 'Abjuration', 5)),
        ArmorProficiency.notProficient,
      );
    });

    test('niveau indisponible : indécidable, jamais « non maîtrisé »', () {
      expect(
        _eval(_chainMail, sub('Clerc', 'Vie', 0)),
        ArmorProficiency.unknown,
      );
    });

    test("un jeton de classe l'emporte sur un niveau indisponible", () {
      const p = ArmorProficiencyProfile(
        tokens: ['lourde'],
        classes: [
          ArmorProficiencyClassLevel(
            className: 'Clerc',
            level: 0,
            subclassName: 'Vie',
          ),
        ],
      );
      expect(_eval(_chainMail, p), ArmorProficiency.proficient);
    });
  });

  group('sous-classe absente, non résolue ou inconnue : jamais devinée', () {
    const clericTokens = ['légère', 'intermédiaire', 'boucliers'];

    ArmorProficiencyProfile cleric({
      String? subclass,
      bool unresolved = false,
      int level = 3,
      List<String> tokens = clericTokens,
    }) => ArmorProficiencyProfile(
      tokens: tokens,
      classes: [
        ArmorProficiencyClassLevel(
          className: 'Clerc',
          level: level,
          subclassName: subclass,
          subclassUnresolved: unresolved,
          isPrimary: true,
        ),
      ],
    );

    test('Clerc niveau 3 sans sous-classe, cotte de mailles : indécidable', () {
      expect(_eval(_chainMail, cleric()), ArmorProficiency.unknown);
    });

    test('sous-classe choisie mais non résolue : indécidable', () {
      expect(
        _eval(_chainMail, cleric(unresolved: true)),
        ArmorProficiency.unknown,
      );
    });

    test('Domaine de la Lumière (aucune armure lourde) : non maîtrisé', () {
      expect(
        _eval(_chainMail, cleric(subclass: 'Domaine de la Lumière')),
        ArmorProficiency.notProficient,
      );
    });

    test('sous-classe inconnue : indécidable', () {
      expect(
        _eval(_chainMail, cleric(subclass: 'Domaine du Futur')),
        ArmorProficiency.unknown,
      );
    });

    test('les jetons de classe suffisent : maîtrisé malgré tout', () {
      expect(_eval(_chainShirt, cleric()), ArmorProficiency.proficient);
    });

    test('Guerrier (jetons complets) : inchangé, sans sous-classe', () {
      const p = ArmorProficiencyProfile(
        tokens: _fighterTokens,
        classes: [
          ArmorProficiencyClassLevel(
            className: 'Guerrier',
            level: 3,
            isPrimary: true,
          ),
        ],
      );
      expect(_eval(_chainMail, p), ArmorProficiency.proficient);
    });

    test('Magicien niveau 1 : lourde non maîtrisée (pas de sous-classe avant '
        'le niveau 2)', () {
      const p = ArmorProficiencyProfile(
        classes: [
          ArmorProficiencyClassLevel(
            className: 'Magicien',
            level: 1,
            isPrimary: true,
          ),
        ],
      );
      expect(_eval(_chainMail, p), ArmorProficiency.notProficient);
    });

    test('Magicien niveau 3 sans école résolue : indécidable', () {
      const p = ArmorProficiencyProfile(
        classes: [
          ArmorProficiencyClassLevel(
            className: 'Magicien',
            level: 3,
            isPrimary: true,
          ),
        ],
      );
      expect(_eval(_chainMail, p), ArmorProficiency.unknown);
    });

    test('Guerrier sans jetons chargés (classe non résolue) : indécidable', () {
      const p = ArmorProficiencyProfile(
        classes: [
          ArmorProficiencyClassLevel(
            className: 'Guerrier',
            level: 3,
            isPrimary: true,
          ),
        ],
      );
      expect(_eval(_chainMail, p), ArmorProficiency.unknown);
      expect(_eval(_shield, p), ArmorProficiency.unknown);
    });
  });

  group('race', () {
    test('Nain des montagnes : légère + intermédiaire', () {
      final p = _profile(subrace: 'Nain des montagnes');
      expect(_eval(_leather, p), ArmorProficiency.proficient);
      expect(_eval(_chainShirt, p), ArmorProficiency.proficient);
      expect(_eval(_chainMail, p), ArmorProficiency.notProficient);
      expect(_eval(_shield, p), ArmorProficiency.notProficient);
    });

    test("Nain des collines : aucune maîtrise d'armure", () {
      final p = _profile(subrace: 'Nain des collines');
      expect(_eval(_chainShirt, p), ArmorProficiency.notProficient);
    });
  });
}
