import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_identity_formatter.dart';

CharacterDetail _detail({
  String? raceName,
  String? subraceName,
  String? raceCustomText,
  String? backgroundName,
  String? alignmentName,
  List<CharacterDetailClassRow> classes = const [],
}) {
  return CharacterDetail(
    id: '1',
    name: 'Test',
    raceName: raceName,
    subraceName: subraceName,
    raceCustomText: raceCustomText,
    backgroundName: backgroundName,
    alignmentName: alignmentName,
    classes: classes,
    xp: 0,
    currentHp: 10,
    maxHp: 10,
    temporaryHp: 0,
    abilityScores: const {},
  );
}

void main() {
  group('CharacterIdentityFormatter.subtitleLine1', () {
    test('race + classe + niveau, cas simple mono-classe', () {
      final detail = _detail(
        raceName: 'Elfe',
        classes: const [
          CharacterDetailClassRow(
            classId: 1,
            className: 'Magicienne',
            level: 5,
            isPrimary: true,
            savingThrowProficiencies: [],
          ),
        ],
      );
      expect(
        CharacterIdentityFormatter.subtitleLine1(detail),
        'Elfe · Magicienne · Niveau 5',
      );
    });

    test('race avec sous-race entre parenthèses', () {
      final detail = _detail(
        raceName: 'Elfe',
        subraceName: 'Haut-elfe',
        classes: const [
          CharacterDetailClassRow(
            classId: 1,
            className: 'Magicienne',
            level: 1,
            isPrimary: true,
            savingThrowProficiencies: [],
          ),
        ],
      );
      expect(
        CharacterIdentityFormatter.subtitleLine1(detail),
        'Elfe (Haut-elfe) · Magicienne · Niveau 1',
      );
    });

    test('race personnalisée affichée à la place du nom résolu', () {
      final detail = _detail(
        raceName: 'Elfe', // ne devrait jamais être renseigné en même temps
        raceCustomText: 'Sylvanien des brumes',
        classes: const [
          CharacterDetailClassRow(
            classId: 1,
            className: 'Guerrier',
            level: 2,
            isPrimary: true,
            savingThrowProficiencies: [],
          ),
        ],
      );
      expect(
        CharacterIdentityFormatter.subtitleLine1(detail),
        'Sylvanien des brumes · Guerrier · Niveau 2',
      );
    });

    test(
      'segments non résolus omis proprement (pas de séparateur orphelin)',
      () {
        final detail = _detail(classes: const []);
        expect(CharacterIdentityFormatter.subtitleLine1(detail), '');
      },
    );

    test('personnage sans classe : seulement le segment race', () {
      final detail = _detail(raceName: 'Nain');
      expect(CharacterIdentityFormatter.subtitleLine1(detail), 'Nain');
    });

    test('multiclassage : "{ClasseA} {niveauA} / {ClasseB} {niveauB}" à la '
        'place de "{Classe} · Niveau N"', () {
      final detail = _detail(
        raceName: 'Nain',
        classes: const [
          CharacterDetailClassRow(
            classId: 1,
            className: 'Guerrier',
            level: 3,
            isPrimary: true,
            savingThrowProficiencies: [],
          ),
          CharacterDetailClassRow(
            classId: 2,
            className: 'Magicien',
            level: 2,
            isPrimary: false,
            savingThrowProficiencies: [],
          ),
        ],
      );
      expect(
        CharacterIdentityFormatter.subtitleLine1(detail),
        'Guerrier 3 / Magicien 2',
      );
    });
  });

  group('CharacterIdentityFormatter.subtitleLine2', () {
    test('masquée entièrement si background ET alignment sont nuls', () {
      final detail = _detail();
      expect(CharacterIdentityFormatter.subtitleLine2(detail), isNull);
    });

    test('historique + alignement tous les deux résolus', () {
      final detail = _detail(
        backgroundName: 'Noble',
        alignmentName: 'Loyal Bon',
      );
      expect(
        CharacterIdentityFormatter.subtitleLine2(detail),
        'Historique : Noble · Loyal Bon',
      );
    });

    test('seulement l\'historique résolu', () {
      final detail = _detail(backgroundName: 'Noble');
      expect(
        CharacterIdentityFormatter.subtitleLine2(detail),
        'Historique : Noble',
      );
    });

    test('seulement l\'alignement résolu', () {
      final detail = _detail(alignmentName: 'Neutre');
      expect(CharacterIdentityFormatter.subtitleLine2(detail), 'Neutre');
    });
  });
}
