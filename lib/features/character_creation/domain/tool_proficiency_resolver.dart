import 'tool_catalog.dart';

/// Résout les trois sources d'outils/instruments de départ en lignes prêtes
/// pour `character_tool_proficiencies` (`tool_id` nullable + `custom_text`),
/// à l'étape 9/9 "Récapitulatif" de l'assistant de création :
/// - [classToolNames] : choix interactif d'outils de classe
///   (`CharacterCreationDraft.classToolChoices`, étape 5/9) ;
/// - [classGrantedToolNames] : outils octroyés automatiquement par la classe
///   (`ClassOption.grantedToolNames`, ex. Druide "outils d'herboriste") ;
/// - [backgroundGrantedToolTexts] : texte informatif d'historique
///   (`BackgroundOption.toolOrLanguageGrantedTools`) — **jamais** résolu vers
///   un `tool_id` (décision déjà actée, voir le commentaire de classe de
///   `domain/background_option.dart`), toujours `custom_text` = le texte
///   brut.
///
/// Les deux premières sources tentent une résolution par nom exact contre
/// [catalog] (`tool_id` si trouvé, sinon repli sur `custom_text` = le nom
/// brut — un nom sans correspondance ne fait jamais échouer la création,
/// même garantie que `domain/skill_proficiency_resolver.dart`) ; la
/// troisième reste toujours `custom_text`.
///
/// Dédupliqué "au mieux" sur les entrées résolues en `tool_id` (un
/// `Set<int>` évite une ligne dupliquée si le même outil apparaît dans
/// plusieurs des trois sources) — pas de déduplication sur les entrées
/// `custom_text` (aucune clé naturelle de dédup pour du texte libre, un
/// doublon texte dans ce cas limite n'est pas grave, voir la consigne
/// d'origine).
abstract final class ToolProficiencyResolver {
  static List<({int? toolId, String? customText})> resolve({
    required List<String> classToolNames,
    required List<String> classGrantedToolNames,
    required List<String> backgroundGrantedToolTexts,
    required ToolCatalog catalog,
  }) {
    final idByName = {for (final tool in catalog.tools) tool.name: tool.id};
    final entries = <({int? toolId, String? customText})>[];
    final seenToolIds = <int>{};

    void addResolvable(String name) {
      final id = idByName[name];
      if (id == null) {
        entries.add((toolId: null, customText: name));
        return;
      }
      if (seenToolIds.add(id)) {
        entries.add((toolId: id, customText: null));
      }
    }

    for (final name in classToolNames) {
      addResolvable(name);
    }
    for (final name in classGrantedToolNames) {
      addResolvable(name);
    }
    for (final text in backgroundGrantedToolTexts) {
      entries.add((toolId: null, customText: text));
    }

    return entries;
  }
}
