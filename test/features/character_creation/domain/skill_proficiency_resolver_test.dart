// Tests unitaires de la résolution + déduplication des compétences de départ
// à l'étape 9/9 "Récapitulatif"
// (`lib/features/character_creation/domain/skill_proficiency_resolver.dart`).

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/skill_catalog.dart';
import 'package:personnages/features/character_creation/domain/skill_option.dart';
import 'package:personnages/features/character_creation/domain/skill_proficiency_resolver.dart';

void main() {
  const arcanes = SkillOption(id: 1, name: 'Arcanes', abilityId: 'int');
  const religion = SkillOption(id: 2, name: 'Religion', abilityId: 'int');
  const perception = SkillOption(id: 3, name: 'Perception', abilityId: 'wis');

  final catalog = const SkillCatalog(skills: [arcanes, religion, perception]);

  test('résout les compétences de classe et d\'historique en proficiency '
      '"competente"', () {
    final rows = SkillProficiencyResolver.resolve(
      classSkillNames: const ['Arcanes'],
      backgroundSkillNames: const ['Religion'],
      catalog: catalog,
    );

    expect(rows, hasLength(2));
    expect(rows.map((r) => r.skillId).toSet(), {arcanes.id, religion.id});
    expect(rows.every((r) => r.proficiency == 'competente'), isTrue);
  });

  test('déduplique une compétence choisie à la fois par la classe ET '
      "l'historique (une seule ligne, PK composite)", () {
    final rows = SkillProficiencyResolver.resolve(
      classSkillNames: const ['Arcanes', 'Perception'],
      backgroundSkillNames: const ['Perception'],
      catalog: catalog,
    );

    expect(rows, hasLength(2));
    expect(rows.map((r) => r.skillId).toSet(), {arcanes.id, perception.id});
  });

  test('ignore silencieusement un nom sans correspondance dans le '
      'catalogue', () {
    final rows = SkillProficiencyResolver.resolve(
      classSkillNames: const ['Compétence inconnue'],
      backgroundSkillNames: const ['Arcanes'],
      catalog: catalog,
    );

    expect(rows, hasLength(1));
    expect(rows.single.skillId, arcanes.id);
  });

  test('listes vides -> aucune ligne', () {
    final rows = SkillProficiencyResolver.resolve(
      classSkillNames: const [],
      backgroundSkillNames: const [],
      catalog: catalog,
    );

    expect(rows, isEmpty);
  });
}
