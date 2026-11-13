import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/rules/character_class.dart';
import 'package:personnages/core/rules/spell_status.dart';
import 'package:personnages/features/characters/domain/character_class_choice.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/ritual_casting.dart';
import 'package:personnages/features/characters/domain/spell_grant_source.dart';

CharacterDetailClassRow _row(
  CharacterClass c, {
  String? subclass,
  bool primary = false,
}) => CharacterDetailClassRow(
  classId: c.id,
  className: c.frenchName,
  level: 5,
  isPrimary: primary,
  savingThrowProficiencies: const [],
  hitDie: 8,
  subclassName: subclass,
  subclassId: subclass == null ? null : 99,
);

CharacterSpellEntry _spell({
  bool ritual = true,
  SpellStatus status = SpellStatus.known,
  Set<int> sources = const {},
  SpellGrantSource? grant,
  bool? hasInnateRoute,
}) => CharacterSpellEntry(
  id: 1,
  name: 'Détection de la magie',
  level: 1,
  school: 'Divination',
  status: status,
  ritual: ritual,
  sourceClassIds: sources,
  grantSource: grant,
  hasInnateRoute: hasInnateRoute,
);

RitualEligibility _eval(
  CharacterSpellEntry spell,
  List<CharacterDetailClassRow> classes, {
  List<CharacterClassChoice> choices = const [],
}) => RitualCasting.evaluate(
  spell: spell,
  classes: classes,
  classChoices: choices,
);

const _tome = CharacterClassChoice(
  featureName: 'Faveur de pacte',
  chosenValue: 'grimoire',
);
const _blade = CharacterClassChoice(
  featureName: 'Faveur de pacte',
  chosenValue: 'lame',
);

void _expectNo(RitualEligibility r, RitualIneligibility reason) {
  expect(r.isEligible, isFalse);
  expect(r.reason, reason);
  expect(r.viaClass, isNull);
}

void main() {
  group('par classe, sort rituel', () {
    test('Magicien : sort connu, même non préparé', () {
      final r = _eval(
        _spell(status: SpellStatus.known, sources: {CharacterClass.wizard.id}),
        [_row(CharacterClass.wizard)],
      );
      expect(r.isEligible, isTrue);
      expect(r.viaClass, CharacterClass.wizard);
    });

    test('Magicien : sort préparé aussi', () {
      expect(
        _eval(
          _spell(
            status: SpellStatus.prepared,
            sources: {CharacterClass.wizard.id},
          ),
          [_row(CharacterClass.wizard)],
        ).isEligible,
        isTrue,
      );
    });

    for (final c in [
      CharacterClass.cleric,
      CharacterClass.druid,
      CharacterClass.artificer,
    ]) {
      test('${c.frenchName} : sort préparé -> éligible', () {
        final r = _eval(_spell(status: SpellStatus.prepared, sources: {c.id}), [
          _row(c),
        ]);
        expect(r.isEligible, isTrue);
        expect(r.viaClass, c);
      });
      test('${c.frenchName} : sort non préparé -> notPrepared', () {
        _expectNo(
          _eval(_spell(status: SpellStatus.known, sources: {c.id}), [_row(c)]),
          RitualIneligibility.notPrepared,
        );
      });
    }

    test('Clerc : sort toujours préparé (domaine) sans préparation', () {
      final r = _eval(
        _spell(status: SpellStatus.prepared, grant: SpellGrantSource.domain),
        [_row(CharacterClass.cleric, subclass: 'Domaine de la vie')],
      );
      expect(r.isEligible, isTrue);
      expect(r.viaClass, CharacterClass.cleric);
    });

    test('Druide : sort de cercle (octroi de sous-classe) -> éligible', () {
      final r = _eval(
        _spell(status: SpellStatus.prepared, grant: SpellGrantSource.subclass),
        [_row(CharacterClass.druid, subclass: 'Cercle de la terre')],
      );
      expect(r.isEligible, isTrue);
      expect(r.viaClass, CharacterClass.druid);
    });

    test('Barde : sort connu', () {
      final r = _eval(_spell(sources: {CharacterClass.bard.id}), [
        _row(CharacterClass.bard),
      ]);
      expect(r.isEligible, isTrue);
      expect(r.viaClass, CharacterClass.bard);
    });

    test('Occultiste avec Pacte du livre : éligible', () {
      final r = _eval(
        _spell(sources: {CharacterClass.warlock.id}),
        [_row(CharacterClass.warlock)],
        choices: [_tome],
      );
      expect(r.isEligible, isTrue);
      expect(r.viaClass, CharacterClass.warlock);
    });

    test('Occultiste sans Pacte du livre (lame, ou aucun pacte)', () {
      for (final choices in [
        <CharacterClassChoice>[],
        [_blade],
      ]) {
        _expectNo(
          _eval(_spell(sources: {CharacterClass.warlock.id}), [
            _row(CharacterClass.warlock),
          ], choices: choices),
          RitualIneligibility.warlockNeedsBook,
        );
      }
    });

    for (final c in [
      CharacterClass.sorcerer,
      CharacterClass.paladin,
      CharacterClass.ranger,
      CharacterClass.barbarian,
      CharacterClass.monk,
      CharacterClass.fighter,
      CharacterClass.rogue,
    ]) {
      test('${c.frenchName} : jamais (classNoRitual), même sous-classe', () {
        _expectNo(
          _eval(_spell(status: SpellStatus.prepared, sources: {c.id}), [
            _row(c, subclass: 'Une sous-classe'),
          ]),
          RitualIneligibility.classNoRitual,
        );
      });
    }

    test('Paladin : un sort octroyé par serment reste non rituel', () {
      _expectNo(
        _eval(
          _spell(status: SpellStatus.prepared, grant: SpellGrantSource.oath),
          [_row(CharacterClass.paladin, subclass: 'Serment de dévotion')],
        ),
        RitualIneligibility.classNoRitual,
      );
    });
  });

  group('multiclassage (jugé par classe via sourceClassIds)', () {
    test('Magicien/Paladin : sort du livre -> éligible via le Magicien', () {
      final r = _eval(_spell(sources: {CharacterClass.wizard.id}), [
        _row(CharacterClass.wizard, primary: true),
        _row(CharacterClass.paladin),
      ]);
      expect(r.isEligible, isTrue);
      expect(r.viaClass, CharacterClass.wizard);
    });

    test('Magicien/Paladin : sort préparé par le Paladin -> classNoRitual', () {
      _expectNo(
        _eval(
          _spell(
            status: SpellStatus.prepared,
            sources: {CharacterClass.paladin.id},
          ),
          [
            _row(CharacterClass.wizard, primary: true),
            _row(CharacterClass.paladin),
          ],
        ),
        RitualIneligibility.classNoRitual,
      );
    });

    test('Clerc/Paladin : sort préparé via le Clerc -> éligible', () {
      final r = _eval(
        _spell(
          status: SpellStatus.prepared,
          sources: {CharacterClass.cleric.id},
        ),
        [
          _row(CharacterClass.cleric, primary: true),
          _row(CharacterClass.paladin),
        ],
      );
      expect(r.isEligible, isTrue);
      expect(r.viaClass, CharacterClass.cleric);
    });

    test('Clerc/Paladin : sort préparé via le Paladin -> classNoRitual', () {
      _expectNo(
        _eval(
          _spell(
            status: SpellStatus.prepared,
            sources: {CharacterClass.paladin.id},
          ),
          [
            _row(CharacterClass.cleric, primary: true),
            _row(CharacterClass.paladin),
          ],
        ),
        RitualIneligibility.classNoRitual,
      );
    });

    test(
      'Clerc/Paladin : sort de liste du Clerc non préparé -> notPrepared',
      () {
        _expectNo(
          _eval(
            _spell(
              status: SpellStatus.known,
              sources: {CharacterClass.cleric.id},
            ),
            [
              _row(CharacterClass.cleric, primary: true),
              _row(CharacterClass.paladin),
            ],
          ),
          RitualIneligibility.notPrepared,
        );
      },
    );

    test(
      'deux classes porteuses : une seule suffit, motif le plus utile sinon',
      () {
        final classes = [
          _row(CharacterClass.cleric, primary: true),
          _row(CharacterClass.sorcerer),
        ];
        final both = {CharacterClass.cleric.id, CharacterClass.sorcerer.id};
        _expectNo(
          _eval(_spell(sources: both), classes),
          RitualIneligibility.notPrepared,
        );
        expect(
          _eval(
            _spell(status: SpellStatus.prepared, sources: both),
            classes,
          ).viaClass,
          CharacterClass.cleric,
        );
      },
    );

    test('Occultiste/Magicien : le livre du Magicien suffit sans pacte', () {
      final r = _eval(_spell(sources: {CharacterClass.wizard.id}), [
        _row(CharacterClass.warlock, primary: true),
        _row(CharacterClass.wizard),
      ]);
      expect(r.viaClass, CharacterClass.wizard);
    });
  });

  group('sort innée, non rituel et origines inconnues', () {
    test('sort non rituel : notRitual, quelle que soit la classe', () {
      _expectNo(
        _eval(_spell(ritual: false, sources: {CharacterClass.wizard.id}), [
          _row(CharacterClass.wizard),
        ]),
        RitualIneligibility.notRitual,
      );
    });

    test('route innée seule : innateOnly', () {
      _expectNo(
        _eval(_spell(status: SpellStatus.innate), [
          _row(CharacterClass.wizard),
        ]),
        RitualIneligibility.innateOnly,
      );
    });

    test('inné + route de classe : jugé par la classe', () {
      final r = _eval(
        _spell(
          status: SpellStatus.known,
          sources: {CharacterClass.wizard.id},
          hasInnateRoute: true,
        ),
        [_row(CharacterClass.wizard)],
      );
      expect(r.isEligible, isTrue);
      _expectNo(
        _eval(
          _spell(
            status: SpellStatus.known,
            sources: {CharacterClass.sorcerer.id},
            hasInnateRoute: true,
          ),
          [_row(CharacterClass.sorcerer)],
        ),
        RitualIneligibility.classNoRitual,
      );
    });

    test('origine inconnue, classe unique : jugée sur cette classe', () {
      expect(
        _eval(_spell(), [_row(CharacterClass.bard)]).viaClass,
        CharacterClass.bard,
      );
      _expectNo(
        _eval(_spell(), [_row(CharacterClass.sorcerer)]),
        RitualIneligibility.classNoRitual,
      );
    });

    test('origine inconnue, multiclassé : notKnown, rien de deviné', () {
      _expectNo(
        _eval(_spell(), [
          _row(CharacterClass.wizard),
          _row(CharacterClass.bard),
        ]),
        RitualIneligibility.notKnown,
      );
    });

    test('aucune classe du personnage ne porte le sort : notKnown', () {
      _expectNo(
        _eval(_spell(sources: {CharacterClass.wizard.id}), [
          _row(CharacterClass.cleric),
        ]),
        RitualIneligibility.notKnown,
      );
    });
  });
}
