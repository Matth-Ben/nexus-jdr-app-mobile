import 'spell_catalog.dart';
import 'spellcasting_rules.dart';

/// Résout les sorts mineurs (`CharacterCreationDraft.classCantripChoices`) et
/// de niveau 1 (`classLevelOneSpellChoices`) choisis à l'étape 6/9 (noms) en
/// lignes prêtes pour `character_spells`, à l'étape 9/9 "Récapitulatif" de
/// l'assistant de création.
///
/// Les deux quotas partagent le même `status` (dérivé de [className] via
/// [SpellcastingRules.statusFor], voir sa documentation pour la règle 5e) :
/// pas de distinction cantrips/niveau 1 sur ce point, une classe "préparée"
/// prépare autant ses cantrips que ses sorts de niveau 1 (les cantrips ne
/// sont d'ailleurs jamais "dépréparés" en 5e, mais le statut stocké reste le
/// même que le reste de la liste de sorts de la classe pour cette
/// itération).
///
/// Une entrée sans correspondance dans [catalog] est ignorée silencieusement
/// — même garantie que `domain/skill_proficiency_resolver.dart`, à ceci près
/// qu'ici aucun repli `custom_name` n'est possible : `character_spells
/// .spell_id` est `not null` (contrairement à `character_inventory.item_id`).
abstract final class SpellSelectionResolver {
  static List<({int spellId, String status})> resolve({
    required List<String> cantripNames,
    required List<String> levelOneSpellNames,
    required SpellCatalog catalog,
    required String className,
  }) {
    final status = SpellcastingRules.statusFor(className);
    final idByName = {for (final spell in catalog.spells) spell.name: spell.id};

    final ids = <int>{};
    for (final name in [...cantripNames, ...levelOneSpellNames]) {
      final id = idByName[name];
      if (id != null) {
        ids.add(id);
      }
    }

    return [for (final id in ids) (spellId: id, status: status)];
  }
}
