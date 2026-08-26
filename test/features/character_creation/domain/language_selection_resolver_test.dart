// Tests unitaires de la résolution des langues de départ à l'étape 9/9
// "Récapitulatif"
// (`lib/features/character_creation/domain/language_selection_resolver.dart`).

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/language_catalog.dart';
import 'package:personnages/features/character_creation/domain/language_option.dart';
import 'package:personnages/features/character_creation/domain/language_selection_resolver.dart';

void main() {
  const commun = LanguageOption(id: 1, name: 'Commun', type: 'standard');
  const elfique = LanguageOption(id: 2, name: 'Elfique', type: 'standard');

  final catalog = const LanguageCatalog(languages: [commun, elfique]);

  test('résout les noms de langue vers leurs ids', () {
    final ids = LanguageSelectionResolver.resolve(
      languageNames: const ['Commun', 'Elfique'],
      catalog: catalog,
    );

    expect(ids.toSet(), {commun.id, elfique.id});
  });

  test('ignore silencieusement un nom sans correspondance', () {
    final ids = LanguageSelectionResolver.resolve(
      languageNames: const ['Commun', 'Langue inconnue'],
      catalog: catalog,
    );

    expect(ids, [commun.id]);
  });

  test('liste vide -> aucun id', () {
    final ids = LanguageSelectionResolver.resolve(
      languageNames: const [],
      catalog: catalog,
    );

    expect(ids, isEmpty);
  });

  test('déduplique un même nom apparaissant deux fois', () {
    final ids = LanguageSelectionResolver.resolve(
      languageNames: const ['Commun', 'Commun'],
      catalog: catalog,
    );

    expect(ids, [commun.id]);
  });
}
