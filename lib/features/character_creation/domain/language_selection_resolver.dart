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
  /// Toujours connue de tout personnage (règle 5e) — jamais un choix parmi
  /// les langues bonus de l'historique : exclue de la liste proposée à
  /// l'étape 5/9 (`skills_and_tools_step_screen.dart`) et du brouillon
  /// reconstruit en modification (`character_edit_hydrator.dart`), toujours
  /// insérée en plus de [resolve] par l'appelant de création
  /// (`character_creation_repository.dart::createCharacter`).
  static const String commonLanguageName = 'Commun';

  /// `language_id` de [commonLanguageName] dans [catalog], `null` si absent
  /// (cas défensif : ne devrait jamais arriver, le catalogue est un contenu
  /// de référence toujours peuplé).
  static int? resolveCommonLanguageId(LanguageCatalog catalog) {
    for (final language in catalog.languages) {
      if (language.name == commonLanguageName) return language.id;
    }
    return null;
  }

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
