import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/expertise_step_selection.dart';

void main() {
  group('ExpertiseStepSelection.effectiveQuota', () {
    test('plafonné au nombre d\'options disponibles si < 2', () {
      expect(ExpertiseStepSelection.effectiveQuota(1), 1);
      expect(ExpertiseStepSelection.effectiveQuota(0), 0);
    });

    test('reste à 2 (quota RAW) si >= 2 options disponibles', () {
      expect(ExpertiseStepSelection.effectiveQuota(2), 2);
      expect(ExpertiseStepSelection.effectiveQuota(10), 2);
    });
  });

  group('ExpertiseStepSelection.skillQuota', () {
    test(
      'sans substitution outils : quota de compétences = quota effectif',
      () {
        expect(
          ExpertiseStepSelection.skillQuota(
            availableOptionsCount: 5,
            thievesToolsSubstitution: false,
          ),
          2,
        );
      },
    );

    test('avec substitution outils : quota de compétences réduit de 1', () {
      expect(
        ExpertiseStepSelection.skillQuota(
          availableOptionsCount: 5,
          thievesToolsSubstitution: true,
        ),
        1,
      );
    });
  });

  group('ExpertiseStepSelection.selectedCount', () {
    test('compétences seules', () {
      expect(
        ExpertiseStepSelection.selectedCount(
          selectedSkillNames: ['Acrobaties'],
          thievesToolsSubstitution: false,
        ),
        1,
      );
    });

    test('compétence + substitution outils', () {
      expect(
        ExpertiseStepSelection.selectedCount(
          selectedSkillNames: ['Acrobaties'],
          thievesToolsSubstitution: true,
        ),
        2,
      );
    });
  });

  group('ExpertiseStepSelection.canProceed', () {
    test('catalogue vide (cas défensif) -> true, jamais bloquant', () {
      expect(
        ExpertiseStepSelection.canProceed(
          availableOptionsCount: 0,
          selectedSkillNames: const [],
          thievesToolsSubstitution: false,
        ),
        isTrue,
      );
    });

    test('quota non atteint -> false', () {
      expect(
        ExpertiseStepSelection.canProceed(
          availableOptionsCount: 5,
          selectedSkillNames: const ['Acrobaties'],
          thievesToolsSubstitution: false,
        ),
        isFalse,
      );
    });

    test('2 compétences choisies -> true', () {
      expect(
        ExpertiseStepSelection.canProceed(
          availableOptionsCount: 5,
          selectedSkillNames: const ['Acrobaties', 'Discrétion'],
          thievesToolsSubstitution: false,
        ),
        isTrue,
      );
    });

    test('1 compétence + substitution outils -> true', () {
      expect(
        ExpertiseStepSelection.canProceed(
          availableOptionsCount: 5,
          selectedSkillNames: const ['Acrobaties'],
          thievesToolsSubstitution: true,
        ),
        isTrue,
      );
    });

    test('une seule option disponible (quota plafonné à 1) : 1 compétence '
        'suffit', () {
      expect(
        ExpertiseStepSelection.canProceed(
          availableOptionsCount: 1,
          selectedSkillNames: const ['Acrobaties'],
          thievesToolsSubstitution: false,
        ),
        isTrue,
      );
    });

    test('3 compétences choisies (jamais possible via l\'UI, mais testé '
        'défensivement) -> false, le quota effectif ne doit jamais être '
        'dépassé', () {
      expect(
        ExpertiseStepSelection.canProceed(
          availableOptionsCount: 5,
          selectedSkillNames: const ['Acrobaties', 'Discrétion', 'Arcanes'],
          thievesToolsSubstitution: false,
        ),
        isFalse,
      );
    });
  });

  group('ExpertiseStepSelection.upgradeToExpertise', () {
    test('rehausse uniquement les compétences choisies pour l\'Expertise', () {
      final result = ExpertiseStepSelection.upgradeToExpertise(
        skillRows: const [
          (skillId: 1, proficiency: 'competente'),
          (skillId: 2, proficiency: 'competente'),
          (skillId: 3, proficiency: 'competente'),
        ],
        expertiseSkillIds: {2},
      );

      expect(result, [
        (skillId: 1, proficiency: 'competente'),
        (skillId: 2, proficiency: 'expertise'),
        (skillId: 3, proficiency: 'competente'),
      ]);
    });

    test('expertiseSkillIds vide -> renvoie skillRows inchangée', () {
      const rows = [(skillId: 1, proficiency: 'competente')];
      expect(
        ExpertiseStepSelection.upgradeToExpertise(
          skillRows: rows,
          expertiseSkillIds: const {},
        ),
        same(rows),
      );
    });
  });
}
