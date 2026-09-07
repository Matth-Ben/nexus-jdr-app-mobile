import '../../characters/domain/character_class_feature.dart';
import '../../characters/domain/character_detail.dart';
import '../../characters/domain/character_detail_class_row.dart';
import '../../characters/domain/character_inventory_item.dart';
import '../../characters/domain/character_skill_row.dart';
import '../../characters/domain/character_spell_entry.dart';
import '../../characters/domain/character_spell_slot.dart';
import 'shared_character_skill_catalog.dart';

/// Convertit le jsonb renvoyé par `public.get_shared_character(p_token)`
/// (dépôt web, `supabase/migrations/20260908090000_add_character_share_token.sql`
/// et ses migrations de suivi `093000`/`094500`/`100000`/`103000`) en
/// [CharacterDetail] — le même modèle déjà utilisé par la fiche personnage
/// authentifiée (`features/characters/data/character_repository.dart
/// ::fetchCharacterDetail`), pour réutiliser telles quelles les cartes/
/// calculateurs déjà validés de cet onglet (grille de caractéristiques,
/// jets de sauvegarde, sorts groupés par niveau, inventaire...) plutôt que
/// de dupliquer toute la présentation pour ce second modèle.
///
/// [json] est le `Map<String, dynamic>` renvoyé tel quel par
/// `SupabaseClient.rpc('get_shared_character', params: {'p_token': token})`
/// — jamais `null` en entrée (l'appelant, `CharacterSharingRepository
/// .fetchSharedCharacter`, traite déjà un résultat RPC `null` comme "aucun
/// personnage partagé sous ce token" avant d'appeler cette fonction).
///
/// Écarts assumés avec [CharacterDetail] tel que rempli par la fiche
/// authentifiée (voir le commentaire d'en-tête de la migration
/// `20260908090000` côté dépôt web pour le rationale complet de ces
/// exclusions) :
/// - [CharacterDetail.adventures] : toujours vide. `get_shared_character`
///   n'inclut jamais `character_campaigns`/`stories` (fuite d'information
///   vers un lecteur anonyme, hors périmètre de "montrer la fiche") — la vue
///   partagée n'affiche donc jamais la carte "Aventures", contrairement à la
///   fiche authentifiée.
/// - [CharacterDetail.skills] : reconstruit à partir des 18 compétences
///   D&D 5e (voir [SharedCharacterSkillCatalog]), le RPC ne renvoyant que les
///   compétences effectivement maîtrisées (voir sa doc de classe).
CharacterDetail mapSharedCharacterJson(Map<String, dynamic> json) {
  final character = _mapOf(json['character']) ?? const {};
  final classes = _listOfMaps(json['classes']);

  return CharacterDetail(
    id: character['id'] as String? ?? '',
    name: character['name'] as String? ?? '',
    portraitUrl: character['portrait_url'] as String?,
    raceName: character['race_name'] as String?,
    subraceName: character['subrace_name'] as String?,
    raceCustomText: character['race_custom_text'] as String?,
    backgroundName: character['background_name'] as String?,
    alignmentName: character['alignment_name'] as String?,
    classes: [for (final row in classes) _mapClassRow(row)],
    xp: _asInt(character['xp']),
    currentHp: _asInt(character['current_hp']),
    maxHp: _asInt(character['max_hp']),
    temporaryHp: _asInt(character['temporary_hp']),
    isDead: character['is_dead'] == true,
    abilityScores: _mapAbilityScores(json['ability_scores']),
    skills: _mapSkills(json['skill_proficiencies']),
    classFeatures: [
      for (final row in _listOfMaps(json['class_features']))
        _mapClassFeature(row, json['feature_uses']),
    ],
    armorProficiencyNames: _mergedProficiencyNames(
      classes,
      'armor_proficiencies',
    ),
    weaponProficiencyNames: _mergedProficiencyNames(
      classes,
      'weapon_proficiencies',
    ),
    toolProficiencyNames: [
      for (final row in _listOfMaps(json['tool_proficiencies']))
        _toolLabel(row),
    ],
    knownLanguageNames: [
      for (final row in _listOfMaps(json['languages']))
        if (row['language_name'] is String) row['language_name'] as String,
    ],
    spells: [for (final row in _listOfMaps(json['spells'])) _mapSpell(row)],
    spellSlots: [
      for (final row in _listOfMaps(json['spell_slots']))
        _mapSpellSlot(row, isPact: false),
    ],
    pactSpellSlot: _firstPactSlot(json['pact_slots']),
    currencyGp: _asInt(character['currency_gp']),
    currencyPp: _asInt(character['currency_pp']),
    currencyEp: _asInt(character['currency_ep']),
    currencySp: _asInt(character['currency_sp']),
    currencyCp: _asInt(character['currency_cp']),
    inventory: [
      for (final row in _listOfMaps(json['inventory'])) _mapInventoryItem(row),
    ],
    sexe: character['sexe'] as String? ?? '',
    age: character['age'] as String? ?? '',
    height: character['height'] as String? ?? '',
    weight: character['weight'] as String? ?? '',
    eyes: character['eyes'] as String? ?? '',
    skin: character['skin'] as String? ?? '',
    hair: character['hair'] as String? ?? '',
    appearanceText: character['appearance_text'] as String? ?? '',
    traitsText: character['traits_text'] as String? ?? '',
    idealsText: character['ideals_text'] as String? ?? '',
    bondsText: character['bonds_text'] as String? ?? '',
    flawsText: character['flaws_text'] as String? ?? '',
    backstoryText: character['backstory_text'] as String? ?? '',
    alliesText: character['allies_text'] as String? ?? '',
    featuresText: character['features_text'] as String? ?? '',
    treasureText: character['treasure_text'] as String? ?? '',
    // adventures : jamais renvoyé par get_shared_character, voir la doc de
    // classe de cette fonction ci-dessus — reste au défaut (liste vide).
  );
}

Map<String, dynamic>? _mapOf(dynamic value) =>
    value is Map<String, dynamic> ? value : null;

List<Map<String, dynamic>> _listOfMaps(dynamic value) {
  if (value is! List) return const [];
  return [for (final item in value) if (item is Map<String, dynamic>) item];
}

int _asInt(dynamic value) => value is num ? value.toInt() : 0;

CharacterDetailClassRow _mapClassRow(Map<String, dynamic> row) {
  return CharacterDetailClassRow(
    classId: row['class_id'],
    className: row['class_name'] as String? ?? 'Classe',
    level: _asInt(row['level']),
    isPrimary: row['is_primary'] == true,
    savingThrowProficiencies: _stringList(row['saving_throw_proficiencies']),
    hitDie: row['hit_die'] is num ? (row['hit_die'] as num).toInt() : null,
    hitDiceSpent: _asInt(row['hit_dice_spent']),
    armorProficiencies: _stringList(row['armor_proficiencies']),
    weaponProficiencies: _stringList(row['weapon_proficiencies']),
  );
}

List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList(growable: false);
}

/// Fusionne les tokens de maîtrise ([field], 'armor_proficiencies' ou
/// 'weapon_proficiencies') de toutes les classes, dédupliqués — même
/// principe que `character_detail_row_mapper.dart::mergeArmorProficiencyNames`/
/// `mergeWeaponProficiencyNames` côté fiche authentifiée, mais sans la
/// restriction "classe principale d'abord puis tokens RAW de multiclassage
/// pour les secondaires" : `get_shared_character` renvoie déjà directement
/// les tokens de CHAQUE classe telle quelle (`cl.armor_proficiencies`/
/// `cl.weapon_proficiencies`, sans distinction primaire/secondaire), donc
/// une simple union suffit ici.
List<String> _mergedProficiencyNames(
  List<Map<String, dynamic>> classes,
  String field,
) {
  final merged = <String>{};
  for (final row in classes) {
    merged.addAll(_stringList(row[field]));
  }
  return merged.toList(growable: false);
}

Map<String, int> _mapAbilityScores(dynamic value) {
  final result = <String, int>{};
  for (final row in _listOfMaps(value)) {
    final abilityId = row['ability_id'] as String?;
    final score = row['score'];
    if (abilityId != null && score is num) {
      result[abilityId] = score.toInt();
    }
  }
  return result;
}

/// Reconstruit les 18 [CharacterSkillRow] (voir la doc de classe de
/// [mapSharedCharacterJson]) : une ligne par compétence de
/// [SharedCharacterSkillCatalog], 'aucune' par défaut, écrasée par la
/// maîtrise réelle si [value] porte une ligne pour ce nom de compétence.
/// [CharacterSkillRow.id] n'est ici qu'un entier synthétique (index+1) —
/// jamais un vrai `skills.id` : vérifié qu'aucun appelant
/// (`SkillBonusCalculator`/`CharacterSkillsCard`) ne s'en sert pour autre
/// chose qu'un affichage/une clé de widget (voir leur documentation).
List<CharacterSkillRow> _mapSkills(dynamic value) {
  final proficiencyByName = <String, String>{};
  for (final row in _listOfMaps(value)) {
    final name = row['skill_name'] as String?;
    final proficiency = row['proficiency'] as String?;
    if (name != null && proficiency != null) {
      proficiencyByName[name] = proficiency;
    }
  }

  final result = <CharacterSkillRow>[];
  var index = 0;
  SharedCharacterSkillCatalog.abilityKeyBySkillName.forEach((
    name,
    abilityKey,
  ) {
    index++;
    result.add(
      CharacterSkillRow(
        id: index,
        name: name,
        abilityId: abilityKey,
        proficiency: proficiencyByName[name] ?? 'aucune',
      ),
    );
  });
  return result;
}

CharacterClassFeature _mapClassFeature(
  Map<String, dynamic> row,
  dynamic featureUsesValue,
) {
  final usesMax = row['uses_max'] is num
      ? (row['uses_max'] as num).toInt()
      : null;
  final usesRemaining = row['uses_remaining'] is num
      ? (row['uses_remaining'] as num).toInt()
      : null;

  return CharacterClassFeature(
    id: _asInt(row['id']),
    name: row['name'] as String? ?? 'Aptitude',
    level: _asInt(row['level']),
    usesMax: usesMax,
    usesRemaining: usesMax != null ? usesRemaining : null,
    restType: row['rest_type'] as String?,
    description: row['description'] as String? ?? '',
  );
}

String _toolLabel(Map<String, dynamic> row) {
  final customText = row['custom_text'] as String?;
  if (customText != null && customText.trim().isNotEmpty) {
    return customText;
  }
  return row['tool_name'] as String? ?? 'Outil';
}

CharacterSpellEntry _mapSpell(Map<String, dynamic> row) {
  return CharacterSpellEntry(
    id: _asInt(row['spell_id']),
    name: row['spell_name'] as String? ?? 'Sort',
    level: _asInt(row['level']),
    school: row['school'] as String? ?? '',
    status: row['status'] as String? ?? 'connu',
    castingTime: row['casting_time'] as String? ?? '',
    range: row['range'] as String? ?? '',
    components: _mapOf(row['components']) ?? const {},
    duration: row['duration'] as String? ?? '',
    concentration: row['concentration'] == true,
    description: row['description'] as String? ?? '',
  );
}

CharacterSpellSlot _mapSpellSlot(
  Map<String, dynamic> row, {
  required bool isPact,
}) {
  return CharacterSpellSlot(
    level: _asInt(row['slot_level']),
    total: _asInt(row['slots_total']),
    used: _asInt(row['slots_used']),
    isPact: isPact,
  );
}

/// `character_pact_slots` porte au plus une ligne par personnage
/// (Occultiste) — même hypothèse que
/// `character_detail_row_mapper.dart::parsePactSpellSlot` côté fiche
/// authentifiée.
CharacterSpellSlot? _firstPactSlot(dynamic value) {
  final rows = _listOfMaps(value);
  if (rows.isEmpty) return null;
  return _mapSpellSlot(rows.first, isPact: true);
}

CharacterInventoryItem _mapInventoryItem(Map<String, dynamic> row) {
  final itemId = row['item_id'] is num ? (row['item_id'] as num).toInt() : null;
  final quantity = _asInt(row['quantity']);
  final weight = row['weight'];
  final unitWeight = weight is num ? weight.toDouble() : null;
  final hasKnownWeight = unitWeight != null && quantity > 0;

  final String name;
  if (itemId != null) {
    name = row['item_name'] as String? ?? 'Objet #$itemId';
  } else {
    name = row['custom_name'] as String? ?? 'Objet personnalisé';
  }

  return CharacterInventoryItem(
    id: row['id'] as String? ?? '',
    itemId: itemId,
    name: name,
    category: row['category'] as String?,
    quantity: quantity,
    equipped: row['equipped'] == true,
    totalWeight: hasKnownWeight ? unitWeight * quantity : null,
    unitWeight: unitWeight,
    costAmount: _costAmount(row['cost']),
    description: row['description'] as String?,
    rarity: row['rarity'] as String?,
    requiresAttunement: row['requires_attunement'] == true,
    consumable: row['consumable'] == true,
    notes: row['notes'] as String?,
    weaponProperties: _mapWeaponProperties(_mapOf(row['weapon_properties'])),
    armorProperties: _mapArmorProperties(_mapOf(row['armor_properties'])),
  );
}

double? _costAmount(dynamic raw) {
  if (raw is! Map) return null;
  final amount = raw['amount'];
  return amount is num ? amount.toDouble() : null;
}

CharacterInventoryWeaponProperties? _mapWeaponProperties(
  Map<String, dynamic>? raw,
) {
  // `jsonb_build_object(...)` du RPC produit toujours un objet, même quand
  // aucune ligne `weapon_properties` ne correspond (les valeurs sont alors
  // toutes `null`, jamais l'objet entier) : `damage_dice` sert de sentinelle
  // "aucune arme" — même garde que `damage_type`/`properties` vides
  // simultanément, ceinture et bretelles plutôt qu'une seule condition.
  if (raw == null) return null;
  final hasContent =
      raw['damage_dice'] != null ||
      raw['damage_type'] != null ||
      (raw['properties'] is List && (raw['properties'] as List).isNotEmpty);
  if (!hasContent) return null;

  final properties = raw['properties'];
  final range = _mapOf(raw['range']);

  return CharacterInventoryWeaponProperties(
    damageDice: raw['damage_dice'] as String?,
    damageType: raw['damage_type'] as String?,
    properties: properties is List
        ? properties.whereType<String>().toList()
        : const [],
    rangeNormal: (range?['normal'] as num?)?.toDouble(),
    rangeMax: (range?['max'] as num?)?.toDouble(),
  );
}

CharacterInventoryArmorProperties? _mapArmorProperties(
  Map<String, dynamic>? raw,
) {
  if (raw == null) return null;
  final acBase = raw['ac_base'];
  if (acBase is! num) return null;

  return CharacterInventoryArmorProperties(
    acBase: acBase.toInt(),
    acDexBonus: raw['ac_dex_bonus'] as String? ?? 'aucun',
    strengthRequirement: (raw['strength_requirement'] as num?)?.toInt(),
    stealthDisadvantage: raw['stealth_disadvantage'] == true,
  );
}
