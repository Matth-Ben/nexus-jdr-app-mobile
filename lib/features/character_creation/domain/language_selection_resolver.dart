import 'language_catalog.dart';

/// Résout les langues d'historique choisies à l'étape 5/9
/// (`CharacterCreationDraft.backgroundLanguageChoices`, noms) en identifiants
/// `language_id` prêts pour `character_languages`, à l'étape 9/9
/// "Récapitulatif" de l'assistant de création.
///
/// Une entrée sans correspondance dans [catalog] est ignorée silencieusement
/// — même garantie que `domain/skill_proficiency_resolver.dart`.
/// Dédupliqué par construction (`Set<int>`) : même rationale défensive que
/// `domain/tool_proficiency_resolver.dart` pour ses entrées résolues en id,
/// même si le nombre de langues choisies à l'étape 5/9 est déjà borné par
/// `BackgroundOption.languageChoiceCount` et ne devrait normalement jamais
/// contenir de doublon.
abstract final class LanguageSelectionResolver {
  static List<int> resolve({
    required List<String> languageNames,
    required LanguageCatalog catalog,
  }) {
    final idByName = {
      for (final language in catalog.languages) language.name: language.id,
    };

    final ids = <int>{};
    for (final name in languageNames) {
      final id = idByName[name];
      if (id != null) {
        ids.add(id);
      }
    }
    return ids.toList();
  }
}
