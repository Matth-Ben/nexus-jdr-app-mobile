// Tests unitaires de la résolution des outils/instruments de départ à
// l'étape 9/9 "Récapitulatif"
// (`lib/features/character_creation/domain/tool_proficiency_resolver.dart`).

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/tool_catalog.dart';
import 'package:personnages/features/character_creation/domain/tool_option.dart';
import 'package:personnages/features/character_creation/domain/tool_proficiency_resolver.dart';

void main() {
  const luth = ToolOption(id: 1, name: 'Luth', category: 'instrument');
  const herboriste = ToolOption(
    id: 2,
    name: "Outils d'herboriste",
    category: 'outils_artisan',
  );

  final catalog = const ToolCatalog(tools: [luth, herboriste]);

  test('résout un choix de classe reconnu vers son tool_id', () {
    final rows = ToolProficiencyResolver.resolve(
      classToolNames: const ['Luth'],
      classGrantedToolNames: const [],
      backgroundGrantedToolTexts: const [],
      catalog: catalog,
    );

    expect(rows, [(toolId: luth.id, customText: null)]);
  });

  test('un nom sans correspondance retombe sur custom_text = le nom brut', () {
    final rows = ToolProficiencyResolver.resolve(
      classToolNames: const ['Un jeu au choix'],
      classGrantedToolNames: const [],
      backgroundGrantedToolTexts: const [],
      catalog: catalog,
    );

    expect(rows, [(toolId: null, customText: 'Un jeu au choix')]);
  });

  test('résout un octroi automatique de classe (grantedToolNames) '
      'exactement comme un choix interactif', () {
    final rows = ToolProficiencyResolver.resolve(
      classToolNames: const [],
      classGrantedToolNames: const ["Outils d'herboriste"],
      backgroundGrantedToolTexts: const [],
      catalog: catalog,
    );

    expect(rows, [(toolId: herboriste.id, customText: null)]);
  });

  test('un texte informatif d\'historique reste toujours custom_text, même '
      "s'il correspond par coïncidence à un vrai nom d'outil", () {
    final rows = ToolProficiencyResolver.resolve(
      classToolNames: const [],
      classGrantedToolNames: const [],
      backgroundGrantedToolTexts: const ['Luth'],
      catalog: catalog,
    );

    expect(rows, [(toolId: null, customText: 'Luth')]);
  });

  test(
    'déduplique les entrées résolues en tool_id à travers les 3 sources',
    () {
      final rows = ToolProficiencyResolver.resolve(
        classToolNames: const ['Luth'],
        classGrantedToolNames: const ['Luth'],
        backgroundGrantedToolTexts: const [],
        catalog: catalog,
      );

      expect(rows, [(toolId: luth.id, customText: null)]);
    },
  );

  test('ne déduplique pas les entrées custom_text (cas limite assumé)', () {
    final rows = ToolProficiencyResolver.resolve(
      classToolNames: const ['Un jeu au choix'],
      classGrantedToolNames: const ['Un jeu au choix'],
      backgroundGrantedToolTexts: const [],
      catalog: catalog,
    );

    expect(rows, hasLength(2));
    expect(rows.every((row) => row.customText == 'Un jeu au choix'), isTrue);
  });
}
