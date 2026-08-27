import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_story_fields_resolver.dart';

CharacterDetail _detail({
  String appearanceText = '',
  String traitsText = '',
  String idealsText = '',
  String bondsText = '',
  String flawsText = '',
  String backstoryText = '',
  String alliesText = '',
  String featuresText = '',
  String treasureText = '',
}) {
  return CharacterDetail(
    id: '1',
    name: 'Test',
    classes: const [],
    xp: 0,
    currentHp: 10,
    maxHp: 10,
    temporaryHp: 0,
    abilityScores: const {},
    appearanceText: appearanceText,
    traitsText: traitsText,
    idealsText: idealsText,
    bondsText: bondsText,
    flawsText: flawsText,
    backstoryText: backstoryText,
    alliesText: alliesText,
    featuresText: featuresText,
    treasureText: treasureText,
  );
}

void main() {
  group('CharacterStoryFieldsResolver.resolveRows', () {
    test('retourne les 9 champs dans l\'ordre canonique, Idéaux/Défauts '
        'groupés sur une même ligne (2 champs)', () {
      final detail = _detail(
        appearanceText: 'Apparence',
        traitsText: 'Traits',
        idealsText: 'Idéaux',
        bondsText: 'Liens',
        flawsText: 'Défauts',
        backstoryText: 'Histoire',
        alliesText: 'Alliés',
        featuresText: 'Particularités',
        treasureText: 'Trésor',
      );

      final rows = CharacterStoryFieldsResolver.resolveRows(detail);

      expect(rows, hasLength(8));
      expect(rows[0].single.label, 'APPARENCE PHYSIQUE');
      expect(rows[0].single.text, 'Apparence');
      expect(rows[1].single.label, 'TRAITS DE PERSONNALITÉ');
      expect(rows[2], hasLength(2));
      expect(rows[2][0].label, 'IDÉAUX');
      expect(rows[2][0].text, 'Idéaux');
      expect(rows[2][1].label, 'DÉFAUTS');
      expect(rows[2][1].text, 'Défauts');
      expect(rows[3].single.label, 'LIENS');
      expect(rows[4].single.label, 'HISTOIRE PERSONNELLE');
      expect(rows[5].single.label, 'ALLIÉS');
      expect(rows[6].single.label, 'PARTICULARITÉS');
      expect(rows[7].single.label, 'TRÉSOR');
    });

    test('un champ vide (chaîne vide ou blanche) est retiré de sa ligne', () {
      final detail = _detail(
        appearanceText: 'Apparence',
        traitsText: '   ',
        idealsText: '',
        flawsText: 'Défauts',
      );

      final rows = CharacterStoryFieldsResolver.resolveRows(detail);

      expect(rows.map((row) => row.map((field) => field.label).toList()), [
        ['APPARENCE PHYSIQUE'],
        ['DÉFAUTS'], // Idéaux vide -> ligne réduite au seul champ Défauts.
      ]);
    });

    test('une ligne dont tous les champs sont vides (Idéaux + Défauts) est '
        'entièrement retirée', () {
      final detail = _detail(appearanceText: 'Apparence');

      final rows = CharacterStoryFieldsResolver.resolveRows(detail);

      expect(rows, hasLength(1));
      expect(rows.single.single.label, 'APPARENCE PHYSIQUE');
    });

    test('retourne une liste vide quand les 9 champs sont vides', () {
      expect(CharacterStoryFieldsResolver.resolveRows(_detail()), isEmpty);
    });
  });
}
