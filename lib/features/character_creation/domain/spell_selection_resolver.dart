import '../../../core/rules/spell_status.dart';
import '../../characters/domain/prepared_spells_limit.dart';
import 'ability_score_rules.dart';
import 'spell_catalog.dart';
import 'spellcasting_rules.dart';

/// Résout les sorts mineurs (`CharacterCreationDraft.classCantripChoices`) et
/// de niveau 1 (`classLevelOneSpellChoices`) choisis à l'étape 6/9 (noms) en
/// lignes prêtes pour `character_spells`, à l'étape 9/9 "Récapitulatif" de
/// l'assistant de création.
///
/// Les deux quotas partagent le même [SpellStatus] (dérivé de [className] via
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
  static List<({int spellId, SpellStatus status})> resolve({
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

  /// Rétrograde l'excédent de sorts de niveau >= 1 au-delà du vrai plafond
  /// RAW (`PreparedSpellsLimit.limitFor`) de `'préparé'` vers `'connu'` — D79
  /// du registre de dette technique (`docs/dette-technique.md`) : [resolve]
  /// marque TOUT le quota de sélection d'une classe à préparation (Clerc,
  /// Druide, Magicien, Paladin, Artificier) comme `'préparé'`, sans jamais
  /// tenir compte du vrai modificateur de caractéristique — un quota de
  /// sélection (nombre de sorts proposés au choix, ex. 6 pour le grimoire du
  /// Magicien) n'est pas la même chose que le plafond de préparation RAW
  /// (modificateur + niveau de classe, minimum 1). Appelée depuis les deux
  /// points d'écriture concernés : `CharacterCreationRepository
  /// .createCharacter` et `CharacterEditPlanner.plan` (changement de classe/
  /// multiclassage au niveau 1, seul niveau où l'un ou l'autre peut
  /// écrire `'préparé'` pour la totalité d'un quota de sélection).
  ///
  /// Ne retire ni n'ajoute aucune ligne : [rows] garde exactement les mêmes
  /// `spellId` dans le même ordre — le quota de SÉLECTION (ce que le joueur
  /// connaît/a dans son grimoire) ne change jamais, seul le `status` d'une
  /// partie des lignes change. Les cantrips (niveau 0, résolus depuis
  /// [catalog]) ne sont jamais rétrogradés : ils ne comptent pas dans
  /// `PreparedSpellsLimit.limitFor` (toujours "préparés" en 5e, jamais
  /// dépréparés), ni les lignes déjà au statut `'connu'` (classes à sorts
  /// connus, pour lesquelles [PreparedSpellsLimit.preparesSpells] vaut déjà
  /// `false` — retournées inchangées sans même construire la table des
  /// niveaux). L'ordre de rétrogradation (les premières lignes de niveau >= 1
  /// de [rows] gardent la priorité sur `'préparé'`) suit l'ordre de [rows]
  /// lui-même, donc l'ordre de sélection du joueur (cantrips puis sorts de
  /// niveau 1, voir [resolve]) — déterministe, mais arbitraire du point de
  /// vue RAW (la règle ne dit pas lesquels parmi le quota restent préparés) :
  /// assumé plutôt que de demander un choix supplémentaire au joueur à la
  /// création, qui pourra de toute façon re-préparer librement ensuite
  /// (`CharacterRepository.setSpellPrepared`, jamais touché par cette
  /// méthode).
  static List<({int spellId, SpellStatus status})> capToPreparedLimit({
    required List<({int spellId, SpellStatus status})> rows,
    required SpellCatalog catalog,
    required String className,
    required int classLevel,
    required Map<String, int> abilityScores,
  }) {
    if (!PreparedSpellsLimit.preparesSpells(className)) return rows;
    final abilityKey = PreparedSpellsLimit.abilityKeyFor(className);
    final score = abilityKey == null ? 10 : (abilityScores[abilityKey] ?? 10);
    final limit =
        PreparedSpellsLimit.limitFor(
          className: className,
          classLevel: classLevel,
          abilityModifier: AbilityScoreRules.abilityModifier(score),
        ) ??
        1;
    final levelById = {
      for (final spell in catalog.spells) spell.id: spell.level,
    };

    return capRowsToPreparedLimit(
      rows: rows,
      levelById: levelById,
      limit: limit,
    );
  }

  /// Cœur de [capToPreparedLimit], séparé pour être appelable sans
  /// [SpellCatalog] complet — utilisé par `CharacterRepository.applyLevelUp`
  /// (D79 du registre de dette technique, `docs/dette-technique.md`,
  /// troisième site concerné : croissance du grimoire du Magicien à chaque
  /// montée de niveau et multiclassage tardif vers le Magicien), qui ne
  /// charge jamais de catalogue de sorts complet et ne connaît chaque sort
  /// de [rows] que par son identifiant et son niveau (requête `spells.level`
  /// dédiée, bien moins coûteuse qu'un catalogue entier à ce point du code).
  ///
  /// [initialPreparedCount] : nombre de sorts DÉJÀ préparés par cette classe
  /// avant [rows] — 0 par défaut, le cas de [capToPreparedLimit] et de ses
  /// deux appelants historiques (création et édition niveau 1), qui partent
  /// toujours d'un personnage sans aucun sort encore préparé de cette
  /// classe. `CharacterRepository.applyLevelUp`, lui, doit plafonner le
  /// TOTAL cumulé sur toute la progression de la classe, pas seulement les
  /// sorts nouvellement ajoutés à CE niveau — d'où ce paramètre, qui décale
  /// simplement le compteur de rétrogradation à son appel.
  static List<({int spellId, SpellStatus status})> capRowsToPreparedLimit({
    required List<({int spellId, SpellStatus status})> rows,
    required Map<int, int> levelById,
    required int limit,
    int initialPreparedCount = 0,
  }) {
    var preparedCount = initialPreparedCount;
    return [
      for (final row in rows)
        if (row.status != SpellStatus.prepared ||
            (levelById[row.spellId] ?? 0) == 0)
          row
        else if (++preparedCount <= limit)
          row
        else
          (spellId: row.spellId, status: SpellStatus.known),
    ];
  }
}
