// Tests de la logique pure de l'étape 5/9 "Compétences et outils" —
// `SkillsAndToolsStepSelection`, voir le commentaire de classe de ce fichier
// pour le détail des 4 sections potentielles.
//
// Fixtures pensées pour reproduire les vraies formes constatées en base
// (voir `ClassRowMapper`/`BackgroundRowMapper`) plutôt que des valeurs
// arbitraires : classe avec `toolChoice` non null (Barde/Moine), classe avec
// seulement `grantedToolNames` (Druide/Roublard), classe sans aucun des deux
// (la majorité), historique avec `toolOrLanguageGrantedTools` vide/non vide,
// historique avec/sans `languageChoiceCount`.

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/background_option.dart';
import 'package:personnages/features/character_creation/domain/class_option.dart';
import 'package:personnages/features/character_creation/domain/class_skill_choices.dart';
import 'package:personnages/features/character_creation/domain/class_tool_choice.dart';
import 'package:personnages/features/character_creation/domain/skills_and_tools_step_selection.dart';

const _classSansOutils = ClassOption(
  id: 1,
  name: 'Guerrier',
  description: '',
  hitDie: 10,
  skillChoices: ClassSkillChoices(
    count: 2,
    choices: ['Athlétisme', 'Intimidation', 'Perception'],
  ),
);

const _classeAvecChoixOutils = ClassOption(
  id: 2,
  name: 'Barde',
  description: '',
  hitDie: 8,
  skillChoices: ClassSkillChoices(count: 3, choices: []),
  toolChoice: ClassToolChoice(count: 1, categories: ['instrument']),
);

const _classeAvecOutilsOctroyes = ClassOption(
  id: 3,
  name: 'Druide',
  description: '',
  hitDie: 8,
  grantedToolNames: ["Outils d'herboriste"],
);

const _backgroundSansRien = BackgroundOption(
  id: 10,
  name: 'Ermite',
  skillProficiencies: [],
  featureName: '',
  featureDescription: '',
);

const _backgroundAvecOutilsOctroyes = BackgroundOption(
  id: 11,
  name: 'Marin',
  skillProficiencies: [],
  featureName: '',
  featureDescription: '',
  toolOrLanguageGrantedTools: ['Kit de déguisement'],
);

const _backgroundAvecLangues = BackgroundOption(
  id: 12,
  name: 'Noble',
  skillProficiencies: [],
  featureName: '',
  featureDescription: '',
  languageChoiceCount: 2,
);

const _backgroundAvecLanguesZero = BackgroundOption(
  id: 13,
  name: 'Soldat',
  skillProficiencies: [],
  featureName: '',
  featureDescription: '',
  languageChoiceCount: 0,
);

void main() {
  group('isClassToolSectionVisible', () {
    test('classe sans toolChoice ni grantedToolNames -> non visible', () {
      expect(
        SkillsAndToolsStepSelection.isClassToolSectionVisible(_classSansOutils),
        isFalse,
      );
    });

    test('classe avec toolChoice non null (Barde/Moine) -> visible', () {
      expect(
        SkillsAndToolsStepSelection.isClassToolSectionVisible(
          _classeAvecChoixOutils,
        ),
        isTrue,
      );
    });

    test('classe avec seulement grantedToolNames non vide (Druide/Roublard) -> '
        'visible', () {
      expect(
        SkillsAndToolsStepSelection.isClassToolSectionVisible(
          _classeAvecOutilsOctroyes,
        ),
        isTrue,
      );
    });
  });

  group('isBackgroundToolSectionVisible', () {
    test('toolOrLanguageGrantedTools vide -> non visible', () {
      expect(
        SkillsAndToolsStepSelection.isBackgroundToolSectionVisible(
          _backgroundSansRien,
        ),
        isFalse,
      );
    });

    test('toolOrLanguageGrantedTools non vide -> visible', () {
      expect(
        SkillsAndToolsStepSelection.isBackgroundToolSectionVisible(
          _backgroundAvecOutilsOctroyes,
        ),
        isTrue,
      );
    });
  });

  group('isLanguageSectionVisible', () {
    test('languageChoiceCount null -> non visible', () {
      expect(
        SkillsAndToolsStepSelection.isLanguageSectionVisible(
          _backgroundSansRien,
        ),
        isFalse,
      );
    });

    test(
      'languageChoiceCount à 0 -> non visible (pas strictement positif)',
      () {
        expect(
          SkillsAndToolsStepSelection.isLanguageSectionVisible(
            _backgroundAvecLanguesZero,
          ),
          isFalse,
        );
      },
    );

    test('languageChoiceCount strictement positif -> visible', () {
      expect(
        SkillsAndToolsStepSelection.isLanguageSectionVisible(
          _backgroundAvecLangues,
        ),
        isTrue,
      );
    });
  });

  group('isChoiceLocked', () {
    test('option déjà cochée -> jamais verrouillée, même quota atteint', () {
      expect(
        SkillsAndToolsStepSelection.isChoiceLocked(
          isSelected: true,
          selectedCount: 2,
          quota: 2,
        ),
        isFalse,
      );
    });

    test('option non cochée, quota non atteint -> non verrouillée', () {
      expect(
        SkillsAndToolsStepSelection.isChoiceLocked(
          isSelected: false,
          selectedCount: 1,
          quota: 2,
        ),
        isFalse,
      );
    });

    test('option non cochée, quota exactement atteint -> verrouillée', () {
      expect(
        SkillsAndToolsStepSelection.isChoiceLocked(
          isSelected: false,
          selectedCount: 2,
          quota: 2,
        ),
        isTrue,
      );
    });

    test('option non cochée, quota dépassé -> verrouillée', () {
      expect(
        SkillsAndToolsStepSelection.isChoiceLocked(
          isSelected: false,
          selectedCount: 3,
          quota: 2,
        ),
        isTrue,
      );
    });

    test(
      'quota nul -> toute option non cochée est immédiatement verrouillée',
      () {
        expect(
          SkillsAndToolsStepSelection.isChoiceLocked(
            isSelected: false,
            selectedCount: 0,
            quota: 0,
          ),
          isTrue,
        );
      },
    );
  });

  group('toggle', () {
    test('ajoute la valeur si absente et quota non atteint', () {
      final result = SkillsAndToolsStepSelection.toggle(
        current: const ['Arcanes'],
        value: 'Histoire',
        quota: 2,
      );
      expect(result, ['Arcanes', 'Histoire']);
    });

    test('retire la valeur si déjà présente, quel que soit le quota', () {
      final result = SkillsAndToolsStepSelection.toggle(
        current: const ['Arcanes', 'Histoire'],
        value: 'Arcanes',
        quota: 1,
      );
      expect(result, ['Histoire']);
    });

    test('refuse l\'ajout si le quota est déjà atteint : renvoie la liste '
        'inchangée', () {
      final current = const ['Arcanes', 'Histoire'];
      final result = SkillsAndToolsStepSelection.toggle(
        current: current,
        value: 'Nature',
        quota: 2,
      );
      expect(result, ['Arcanes', 'Histoire']);
    });

    test('quota nul -> aucun ajout possible', () {
      final result = SkillsAndToolsStepSelection.toggle(
        current: const [],
        value: 'Arcanes',
        quota: 0,
      );
      expect(result, isEmpty);
    });

    test('ne mute jamais la liste passée en entrée', () {
      final current = <String>['Arcanes'];
      SkillsAndToolsStepSelection.toggle(
        current: current,
        value: 'Histoire',
        quota: 2,
      );
      expect(current, ['Arcanes']);
    });
  });

  group('canProceed', () {
    test('aucune section optionnelle active, quota de compétences atteint -> '
        'true', () {
      expect(
        SkillsAndToolsStepSelection.canProceed(
          classOption: _classSansOutils,
          backgroundOption: _backgroundSansRien,
          selectedClassSkills: const ['Athlétisme', 'Intimidation'],
          selectedClassTools: const [],
          selectedBackgroundLanguages: const [],
        ),
        isTrue,
      );
    });

    test('quota de compétences non atteint -> false', () {
      expect(
        SkillsAndToolsStepSelection.canProceed(
          classOption: _classSansOutils,
          backgroundOption: _backgroundSansRien,
          selectedClassSkills: const ['Athlétisme'],
          selectedClassTools: const [],
          selectedBackgroundLanguages: const [],
        ),
        isFalse,
      );
    });

    test('quota de compétences dépassé (ne devrait jamais arriver via toggle, '
        'mais canProceed exige une égalité stricte) -> false', () {
      expect(
        SkillsAndToolsStepSelection.canProceed(
          classOption: _classSansOutils,
          backgroundOption: _backgroundSansRien,
          selectedClassSkills: const [
            'Athlétisme',
            'Intimidation',
            'Perception',
          ],
          selectedClassTools: const [],
          selectedBackgroundLanguages: const [],
        ),
        isFalse,
      );
    });

    test('section outils de classe active (toolChoice) : compétences ET outils '
        'doivent atteindre leur quota exact', () {
      expect(
        SkillsAndToolsStepSelection.canProceed(
          classOption: _classeAvecChoixOutils,
          backgroundOption: _backgroundSansRien,
          selectedClassSkills: const ['Arcanes', 'Histoire', 'Nature'],
          selectedClassTools: const ['Luth'],
          selectedBackgroundLanguages: const [],
        ),
        isTrue,
      );
    });

    test('section outils de classe active mais quota d\'outils manquant -> '
        'false même si les compétences sont complètes', () {
      expect(
        SkillsAndToolsStepSelection.canProceed(
          classOption: _classeAvecChoixOutils,
          backgroundOption: _backgroundSansRien,
          selectedClassSkills: const ['Arcanes', 'Histoire', 'Nature'],
          selectedClassTools: const [],
          selectedBackgroundLanguages: const [],
        ),
        isFalse,
      );
    });

    test(
      'classe avec outils octroyés automatiquement (grantedToolNames, pas '
      'de toolChoice) : aucun quota d\'outils à vérifier, ne bloque jamais',
      () {
        expect(
          SkillsAndToolsStepSelection.canProceed(
            classOption: _classeAvecOutilsOctroyes,
            backgroundOption: _backgroundSansRien,
            selectedClassSkills: const [],
            selectedClassTools: const [],
            selectedBackgroundLanguages: const [],
          ),
          isTrue,
        );
      },
    );

    test('section langues d\'historique active : compétences ET langues '
        'doivent atteindre leur quota exact', () {
      expect(
        SkillsAndToolsStepSelection.canProceed(
          classOption: _classSansOutils,
          backgroundOption: _backgroundAvecLangues,
          selectedClassSkills: const ['Athlétisme', 'Intimidation'],
          selectedClassTools: const [],
          selectedBackgroundLanguages: const ['Nain', 'Elfique'],
        ),
        isTrue,
      );
    });

    test('section langues active mais quota de langues manquant -> false même '
        'si les compétences sont complètes', () {
      expect(
        SkillsAndToolsStepSelection.canProceed(
          classOption: _classSansOutils,
          backgroundOption: _backgroundAvecLangues,
          selectedClassSkills: const ['Athlétisme', 'Intimidation'],
          selectedClassTools: const [],
          selectedBackgroundLanguages: const ['Nain'],
        ),
        isFalse,
      );
    });

    test(
      'historique avec outils octroyés automatiquement (section verrouillée) '
      'ne bloque jamais "Suivant", même sans rien sélectionner pour cette '
      'section (pas de champ dédié à vérifier)',
      () {
        expect(
          SkillsAndToolsStepSelection.canProceed(
            classOption: _classSansOutils,
            backgroundOption: _backgroundAvecOutilsOctroyes,
            selectedClassSkills: const ['Athlétisme', 'Intimidation'],
            selectedClassTools: const [],
            selectedBackgroundLanguages: const [],
          ),
          isTrue,
        );
      },
    );

    test('les 4 sections actives simultanément : "Suivant" ne s\'active que '
        'lorsque les 3 quotas interactifs (compétences, outils, langues) sont '
        'exactement atteints, la section historique verrouillée ne comptant '
        'pas', () {
      const classeComplete = ClassOption(
        id: 4,
        name: 'Moine',
        description: '',
        hitDie: 8,
        skillChoices: ClassSkillChoices(
          count: 2,
          choices: ['Acrobaties', 'Discrétion', 'Perspicacité'],
        ),
        toolChoice: ClassToolChoice(
          count: 1,
          categories: ['outils_artisan', 'instrument'],
        ),
      );
      const backgroundComplet = BackgroundOption(
        id: 20,
        name: 'Marin',
        skillProficiencies: [],
        featureName: '',
        featureDescription: '',
        toolOrLanguageGrantedTools: ['Outils de navigateur'],
        languageChoiceCount: 1,
      );

      // Un seul quota manquant (langues) bloque tout, même si les trois
      // autres sont corrects.
      expect(
        SkillsAndToolsStepSelection.canProceed(
          classOption: classeComplete,
          backgroundOption: backgroundComplet,
          selectedClassSkills: const ['Acrobaties', 'Discrétion'],
          selectedClassTools: const ['Kit de forgeron'],
          selectedBackgroundLanguages: const [],
        ),
        isFalse,
      );

      // Les 4 sections à quota exact -> true (section 3, verrouillée,
      // n'a besoin d'aucune sélection).
      expect(
        SkillsAndToolsStepSelection.canProceed(
          classOption: classeComplete,
          backgroundOption: backgroundComplet,
          selectedClassSkills: const ['Acrobaties', 'Discrétion'],
          selectedClassTools: const ['Kit de forgeron'],
          selectedBackgroundLanguages: const ['Commun'],
        ),
        isTrue,
      );
    });
  });
}
