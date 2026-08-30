// Tests unitaires du parseur XML aidedd.org
// (`lib/features/xml_import/data/xml_character_import_parser.dart`) contre
// les deux fixtures réelles (`test/fixtures/xml_import/`) et quelques cas
// malformés/synthétiques.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/xml_import/data/xml_character_import_parser.dart';
import 'package:personnages/features/xml_import/domain/xml_import_parse_result.dart';

String _readFixture(String fileName) =>
    File('test/fixtures/xml_import/$fileName').readAsStringSync();

void main() {
  group('solan-valerius.xml (Aasimar Paladin niv. 2)', () {
    final result = XmlCharacterImportParser.parse(
      _readFixture('solan-valerius.xml'),
    );

    test('parse avec succès', () {
      expect(result, isA<XmlImportParseSuccess>());
    });

    final raw = (result as XmlImportParseSuccess).character;

    test('identité et progression', () {
      expect(raw.name, 'Solan Valerius');
      expect(raw.race, 'Aasimar');
      expect(raw.characterClass, 'Paladin');
      expect(raw.classPath, isNull);
      expect(raw.level, 2);
      expect(raw.background, 'Héros du peuple');
      expect(raw.raceCustom, '1');
    });

    test('caractéristiques', () {
      expect(raw.abilityScores, {
        'str': 14,
        'dex': 10,
        'con': 14,
        'int': 10,
        'wis': 10,
        'cha': 14,
      });
    });

    test('20 entrées de niveau, hp_brut renseigné aux niveaux 1 et 2', () {
      expect(raw.levels, hasLength(20));
      expect(raw.levels[0].level, 1);
      expect(raw.levels[0].hpBrut, 10);
      expect(raw.levels[0].abilityIncreases, [5, -1, 5]);
      expect(raw.levels[1].level, 2);
      expect(raw.levels[1].hpBrut, 6);
      expect(raw.levels[19].level, 20);
      expect(raw.levels[19].hpBrut, 0);
    });

    test('skillsProf/toolsProf/languages par source (id 0 à 3)', () {
      expect(raw.skillsProf[0], isEmpty);
      expect(raw.skillsProf[1], ['14', '8']);
      expect(raw.skillsProf[2], ['4', '16']);
      expect(raw.skillsProf[3], isEmpty);

      expect(raw.toolsProf[2], [
        'matériel de peintre',
        'véhicules (terrestres)',
      ]);
      expect(raw.toolsProf[0], isEmpty);

      expect(raw.languages[0], ['commun', 'céleste']);
      expect(raw.languages[1], isEmpty);
    });

    test('sorts innés et connus, en clair', () {
      expect(raw.innateSpells, hasLength(1));
      expect(raw.innateSpells.single.level, 0);
      expect(raw.innateSpells.single.name, 'lumière');

      expect(raw.knownSpells, hasLength(11));
      expect(raw.knownSpells.every((s) => s.level == 1), isTrue);
      expect(raw.knownSpells.map((s) => s.name), contains('bénédiction'));
      expect(raw.knownSpells.map((s) => s.name), contains('cérémonie'));

      expect(raw.knownInvocations, isEmpty);
    });

    test('monnaie', () {
      expect(raw.gp, 10);
      expect(raw.pp, 0);
      expect(raw.ep, 0);
      expect(raw.sp, 0);
      expect(raw.cp, 0);
    });

    test('équipement codé : armure, bouclier, armes, outils, objets', () {
      expect(raw.armor, 10);
      expect(raw.shield, 1);
      expect(raw.weaponIds, ['20', '6']);
      expect(raw.weaponQuantities, [1, 5]);
      expect(raw.toolEquipmentIds, ['0', '32']);
      expect(raw.itemIds, [
        '56',
        '88',
        '80',
        '19',
        '6',
        '5',
        '76',
        '39',
        '63',
        '74',
        '92',
      ]);
      expect(raw.itemQuantities, [1, 1, 1, 1, 10, 1, 2, 1, 1, 1, 1]);
      expect(raw.customItemTexts, [
        'boîte pour l\'aumône',
        'bâtonnets d\'encens (2)',
        'encensoir',
        'habits de cérémonie',
        'bourse',
      ]);
      expect(raw.pack, 16);
    });

    test('champs codés singuliers : sexe, alignement', () {
      expect(raw.sexe, 0);
      expect(raw.alignment, 0);
    });

    test('champs libres/narratifs non vides', () {
      expect(raw.age, 20);
      expect(raw.height, '1,90 m');
      expect(raw.weight, '80 kg');
      expect(raw.eyes, 'bleu azur');
      expect(raw.appearanceText, isNotEmpty);
      expect(raw.backstoryText, isNotEmpty);
      expect(raw.treasureText, ''); // <treasure></treasure> -> vide -> ''
    });
  });

  group('pip.xml (Conil Barde niv. 2)', () {
    final result = XmlCharacterImportParser.parse(_readFixture('pip.xml'));
    final raw = (result as XmlImportParseSuccess).character;

    test('identité', () {
      expect(raw.name, 'Pip');
      expect(raw.race, 'Conil');
      expect(raw.characterClass, 'Barde');
      expect(raw.background, 'Grand voyageur');
      expect(raw.raceCustom, isNull); // <raceCustom></raceCustom> -> vide
    });

    test('skillsProf/toolsProf/languages par source', () {
      expect(raw.skillsProf[0], ['12']);
      expect(raw.skillsProf[1], ['17', '16', '0']);
      expect(raw.skillsProf[2], ['8', '17']);

      expect(raw.toolsProf[1], ['flûte', 'luth', 'tambour']);
      expect(raw.toolsProf[2], ['flûte']);

      expect(raw.languages[0], ['commun', 'sylvestre']);
      expect(raw.languages[2], ['elfique']);
    });

    test('sorts connus : 5 mineurs + 7 de niveau 1', () {
      expect(raw.innateSpells, isEmpty);
      expect(raw.knownSpells, hasLength(12));
      expect(raw.knownSpells.where((s) => s.level == 0), hasLength(5));
      expect(raw.knownSpells.where((s) => s.level == 1), hasLength(7));
    });

    test('équipement codé', () {
      expect(raw.armor, 2);
      expect(raw.shield, 0);
      expect(raw.weaponIds, ['32', '3']);
      expect(raw.weaponQuantities, [1, 1]);
      expect(raw.toolEquipmentIds, ['12', '10']);
      expect(raw.itemIds, [
        '16',
        '25',
        '94',
        '23',
        '71',
        '43',
        '42',
        '60',
        '62',
        '14',
        '83',
        '95',
      ]);
      expect(raw.itemQuantities, [1, 2, 1, 1, 1, 1, 2, 5, 1, 1, 1, 1]);
      expect(raw.customItemTexts, [
        'cartes grossièrement tracées',
        'petit bijou valant 10 po',
      ]);
      expect(raw.pack, 2);
    });

    test('sexe/alignement', () {
      expect(raw.sexe, 0);
      expect(raw.alignment, 6);
    });
  });

  group('cas malformés / non reconnus', () {
    test('XML illisible -> failure explicite', () {
      final result = XmlCharacterImportParser.parse(
        'ceci n\'est pas du xml <<<',
      );
      expect(result, isA<XmlImportParseFailure>());
    });

    test('chaîne vide -> failure explicite', () {
      final result = XmlCharacterImportParser.parse('');
      expect(result, isA<XmlImportParseFailure>());
    });

    test('XML valide mais racine inattendue -> failure explicite', () {
      final result = XmlCharacterImportParser.parse(
        '<?xml version="1.0"?><notBuilder></notBuilder>',
      );
      expect(result, isA<XmlImportParseFailure>());
    });

    test('<builder> sans <character> -> failure explicite', () {
      final result = XmlCharacterImportParser.parse(
        '<?xml version="1.0"?><builder></builder>',
      );
      expect(result, isA<XmlImportParseFailure>());
    });

    test('<character> sans les champs minimaux -> failure explicite', () {
      final result = XmlCharacterImportParser.parse(
        '<?xml version="1.0"?><builder><character></character></builder>',
      );
      expect(result, isA<XmlImportParseFailure>());
    });
  });

  group('cas synthétiques non couverts par les deux fixtures réelles', () {
    test('sous-classe (classPath) et invocations présentes sont parsées', () {
      const xml = '''
<?xml version="1.0" encoding="UTF-8"?>
<builder>
<character>
<name>Test Occultiste</name>
<race>Tieffelin</race>
<class>Occultiste</class>
<classPath>Mort-vivant</classPath>
<level>3</level>
<background>Ermite</background>
<knownInvocation>Armure d'ombres</knownInvocation>
<knownInvocation>Lame assoiffée</knownInvocation>
</character>
</builder>
''';
      final result = XmlCharacterImportParser.parse(xml);
      expect(result, isA<XmlImportParseSuccess>());
      final raw = (result as XmlImportParseSuccess).character;

      expect(raw.classPath, 'Mort-vivant');
      expect(raw.knownInvocations, ['Armure d\'ombres', 'Lame assoiffée']);
    });
  });

  group("champs style de combat / ennemi juré / notes (parsés mais non testés jusqu'ici)", () {
    test("solan-valerius.xml : styleCombat1 vaut '11' (numérique) — "
        "raceCustom/backSpe également vérifiés au passage", () {
      final result = XmlCharacterImportParser.parse(
        _readFixture('solan-valerius.xml'),
      );
      final raw = (result as XmlImportParseSuccess).character;
      expect(raw.raceCustom, '1');
      expect(raw.styleCombat1, '11');
      expect(raw.styleCombat2, isNull);
      expect(raw.favoredEnemy0, isNull);
      expect(raw.favoredEnemy6, isNull);
      expect(raw.favoredEnemy14, isNull);
      expect(
        raw.backSpe,
        "Recruté dans l'armée d'un seigneur, je suis devenu un leader "
        "et j'ai été félicité pour mon héroïsme",
      );
    });

    test('pip.xml : styleCombat1/2, favoredEnemyN et raceCustom tous vides -> null', () {
      final result = XmlCharacterImportParser.parse(_readFixture('pip.xml'));
      final raw = (result as XmlImportParseSuccess).character;
      expect(raw.raceCustom, isNull);
      expect(raw.styleCombat1, isNull);
      expect(raw.styleCombat2, isNull);
      expect(raw.favoredEnemy0, isNull);
      expect(raw.favoredEnemy6, isNull);
      expect(raw.favoredEnemy14, isNull);
      expect(raw.backSpe, 'Vagabond');
    });
  });

  group(
    'robustesse : cas limites non couverts par les deux fixtures réelles',
    () {
      test("jeton non numérique dans une liste positionnelle ('12,abc,5') -> "
          'préservé tel quel en String, jamais silencieusement remplacé par 0 '
          "(voir la revue QA de l'increment 1 : un tel repli aurait confondu "
          "le jeton corrompu avec l'identifiant 0 = emplacement vide côté "
          'résolution — voir `xml_character_import_resolver_test.dart` pour '
          "la vérification bout en bout que l'objet corrompu ressort bien "
          "'non reconnu' au lieu de disparaître de l'import)", () {
        const xml = '''
<?xml version="1.0" encoding="UTF-8"?>
<builder>
<character>
<name>Test</name>
<race>Aasimar</race>
<class>Paladin</class>
<background>Ermite</background>
<item>12,abc,5</item>
<itemQ>1,1,1</itemQ>
</character>
</builder>
''';
        final result = XmlCharacterImportParser.parse(xml);
        expect(result, isA<XmlImportParseSuccess>());
        final raw = (result as XmlImportParseSuccess).character;
        expect(raw.itemIds, ['12', 'abc', '5']);
      });

      test(
        'tag numérique présent mais vide (<armor></armor>) -> null, pas 0',
        () {
          const xml = '''
<?xml version="1.0" encoding="UTF-8"?>
<builder>
<character>
<name>Test</name>
<race>Aasimar</race>
<class>Paladin</class>
<background>Ermite</background>
<armor></armor>
</character>
</builder>
''';
          final result = XmlCharacterImportParser.parse(xml);
          final raw = (result as XmlImportParseSuccess).character;
          expect(raw.armor, isNull);
        },
      );

      test('<level> non numérique -> repli sur 1, pas d\'exception', () {
        const xml = '''
<?xml version="1.0" encoding="UTF-8"?>
<builder>
<character>
<name>Test</name>
<race>Aasimar</race>
<class>Paladin</class>
<background>Ermite</background>
<level>deux</level>
</character>
</builder>
''';
        final result = XmlCharacterImportParser.parse(xml);
        expect(result, isA<XmlImportParseSuccess>());
        final raw = (result as XmlImportParseSuccess).character;
        expect(raw.level, 1);
      });

      test(
        '<lvl> sans attribut lvl= -> level replié sur 0, pas d\'exception',
        () {
          const xml = '''
<?xml version="1.0" encoding="UTF-8"?>
<builder>
<character>
<name>Test</name>
<race>Aasimar</race>
<class>Paladin</class>
<background>Ermite</background>
<lvl><hp_brut>8</hp_brut></lvl>
</character>
</builder>
''';
          final result = XmlCharacterImportParser.parse(xml);
          expect(result, isA<XmlImportParseSuccess>());
          final raw = (result as XmlImportParseSuccess).character;
          expect(raw.levels.single.level, 0);
          expect(raw.levels.single.hpBrut, 8);
        },
      );
    },
  );
}
