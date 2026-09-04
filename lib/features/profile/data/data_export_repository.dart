import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../characters/data/character_repository.dart';
import '../../characters/domain/character_detail.dart';
import '../../characters/domain/character_inventory_item.dart';

/// Passerelle "Export de mes données" (sheet
/// `presentation/widgets/export_data_sheet.dart`, tuile "Export de mes
/// données" de `presentation/profile_privacy_screen.dart`).
///
/// Volontairement une abstraction **dédiée**, plutôt qu'une méthode ajoutée
/// à `CharacterRepository` (`features/characters/data/character_repository.dart`,
/// déjà plus de 2000 lignes) : cette fonctionnalité n'a rien d'un accès
/// "personnage par personnage" habituel de ce dépôt (aucun écran ne
/// l'affiche, elle n'a pas besoin de connaître le cache hors-ligne de la
/// fiche personnage), et vit naturellement à côté du reste de
/// `features/profile/` (même feature que le reste de la tâche
/// "Confidentialité et données"). Elle **consomme** [CharacterRepository]
/// (déjà l'abstraction responsable de toute lecture de personnage) plutôt
/// que de dupliquer ses requêtes PostgREST.
///
/// Abstraction (plutôt qu'une classe concrète directement injectée) pour
/// permettre aux tests de fournir un double sans jamais toucher à
/// `Supabase.instance.client`/au système de fichiers réel — même principe
/// que `AuthRepository`/`CharacterRepository`.
abstract class DataExportRepository {
  /// Récupère tous les personnages du joueur connecté (déjà résolus, y
  /// compris inventaire/sorts/histoire) via [CharacterRepository], assemble
  /// un unique JSON, l'écrit dans un fichier temporaire, et retourne son
  /// chemin.
  ///
  /// **Toujours des données réseau fraîches, jamais le cache local**
  /// (décision chef de projet, tâche "Confidentialité et données") : chaque
  /// personnage est relu via [CharacterRepository.fetchCharacterDetail],
  /// dont la stratégie est déjà "réseau d'abord" (voir sa documentation de
  /// classe) — un éventuel repli sur le cache ne peut donc survenir qu'en
  /// cas d'échec réseau complet pour ce personnage précis, jamais par
  /// choix. L'appelant (`export_data_sheet.dart`) vérifie de toute façon la
  /// connectivité *avant* d'appeler cette méthode (même garde que les
  /// autres écritures/lectures réseau de ce dépôt), ce qui rend ce repli un
  /// cas resté théorique en pratique.
  ///
  /// Propage telle quelle toute exception levée par [CharacterRepository]
  /// (`CharacterFailure` ou autre) — l'appelant n'affiche de toute façon
  /// qu'un message générique fixe quel que soit le détail de l'échec (spec
  /// direction-artistique de la tâche), même principe que
  /// `report_bug_sheet.dart`/`_genericErrorMessage`.
  Future<String> exportMyData();
}

class LocalFileDataExportRepository implements DataExportRepository {
  LocalFileDataExportRepository(this._characterRepository);

  final CharacterRepository _characterRepository;

  @override
  Future<String> exportMyData() async {
    final summaries = await _characterRepository.fetchCharacters();

    final characters = <Map<String, dynamic>>[];
    for (final summary in summaries) {
      final detail = await _characterRepository.fetchCharacterDetail(
        summary.id,
      );
      characters.add(_characterDetailToJson(detail));
    }

    final payload = <String, dynamic>{
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'characters': characters,
    };

    // Nom de fichier horodaté — même rationale que les portraits/avatars
    // (`SupabaseCharacterRepository.uploadPortrait`) : évite toute collision
    // si un joueur relance l'export plusieurs fois de suite sans redémarrer
    // l'app (répertoire temporaire jamais nettoyé automatiquement par ce
    // dépôt entre deux exports).
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/nexus-jdr-export-'
      '${DateTime.now().millisecondsSinceEpoch}.json',
    );
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
    return file.path;
  }
}

/// Sérialise un [CharacterDetail] en `Map` JSON-safe — aucune de ces classes
/// domaine n'est `json_serializable` (contrairement au modèle de personnage
/// de `character_creation/`, généré depuis le schéma Supabase) : la plupart
/// sont d'ailleurs de simples classes (pas même `freezed`, voir leur
/// documentation de classe respective, ex. `CharacterInventoryItem`), donc
/// jamais de `toJson()` déjà généré à réutiliser ici. Structure raisonnable
/// pour un export lisible par le joueur, pas un contrat d'API figé.
Map<String, dynamic> _characterDetailToJson(CharacterDetail detail) {
  return {
    'id': detail.id,
    'name': detail.name,
    'portraitUrl': detail.portraitUrl,
    'race': {
      'name': detail.raceName,
      'subraceName': detail.subraceName,
      'customText': detail.raceCustomText,
    },
    'backgroundName': detail.backgroundName,
    'alignmentName': detail.alignmentName,
    'classes': [
      for (final classRow in detail.classes)
        {
          'classId': classRow.classId,
          'className': classRow.className,
          'level': classRow.level,
          'isPrimary': classRow.isPrimary,
          'hitDie': classRow.hitDie,
          'savingThrowProficiencies': classRow.savingThrowProficiencies,
        },
    ],
    'totalLevel': detail.totalLevel,
    'xp': detail.xp,
    'currentHp': detail.currentHp,
    'maxHp': detail.maxHp,
    'temporaryHp': detail.temporaryHp,
    'abilityScores': detail.abilityScores,
    'skills': [
      for (final skill in detail.skills)
        {
          'id': skill.id,
          'name': skill.name,
          'abilityId': skill.abilityId,
          'proficiency': skill.proficiency,
        },
    ],
    'classFeatures': [
      for (final feature in detail.classFeatures)
        {
          'id': feature.id,
          'name': feature.name,
          'level': feature.level,
          'usesMax': feature.usesMax,
          'usesRemaining': feature.usesRemaining,
          'restType': feature.restType,
          'description': feature.description,
        },
    ],
    'toolProficiencyNames': detail.toolProficiencyNames,
    'knownLanguageNames': detail.knownLanguageNames,
    'spells': [
      for (final spell in detail.spells)
        {
          'id': spell.id,
          'name': spell.name,
          'level': spell.level,
          'school': spell.school,
          'status': spell.status,
          'castingTime': spell.castingTime,
          'range': spell.range,
          'components': spell.components,
          'duration': spell.duration,
          'concentration': spell.concentration,
          'description': spell.description,
        },
    ],
    'spellSlots': [
      for (final slot in detail.spellSlots)
        {'level': slot.level, 'total': slot.total, 'used': slot.used},
    ],
    'currency': {
      'gp': detail.currencyGp,
      'pp': detail.currencyPp,
      'ep': detail.currencyEp,
      'sp': detail.currencySp,
      'cp': detail.currencyCp,
    },
    'inventory': [
      for (final item in detail.inventory) _inventoryItemToJson(item),
    ],
    'appearance': {
      'sexe': detail.sexe,
      'age': detail.age,
      'height': detail.height,
      'weight': detail.weight,
      'eyes': detail.eyes,
      'skin': detail.skin,
      'hair': detail.hair,
    },
    'story': {
      'appearanceText': detail.appearanceText,
      'traitsText': detail.traitsText,
      'idealsText': detail.idealsText,
      'bondsText': detail.bondsText,
      'flawsText': detail.flawsText,
      'backstoryText': detail.backstoryText,
      'alliesText': detail.alliesText,
      'featuresText': detail.featuresText,
      'treasureText': detail.treasureText,
    },
    'adventures': [
      for (final adventure in detail.adventures)
        {
          'characterCampaignId': adventure.characterCampaignId,
          'storyId': adventure.storyId,
          'storyTitle': adventure.storyTitle,
          'storyCoverUrl': adventure.storyCoverUrl,
        },
    ],
  };
}

Map<String, dynamic> _inventoryItemToJson(CharacterInventoryItem item) {
  return {
    'id': item.id,
    'itemId': item.itemId,
    'name': item.name,
    'category': item.category,
    'quantity': item.quantity,
    'equipped': item.equipped,
    'totalWeight': item.totalWeight,
    'unitWeight': item.unitWeight,
    'costAmount': item.costAmount,
    'description': item.description,
    'rarity': item.rarity,
    'requiresAttunement': item.requiresAttunement,
    'consumable': item.consumable,
    'notes': item.notes,
    'weaponProperties': item.weaponProperties == null
        ? null
        : {
            'damageDice': item.weaponProperties!.damageDice,
            'damageType': item.weaponProperties!.damageType,
            'properties': item.weaponProperties!.properties,
            'rangeNormal': item.weaponProperties!.rangeNormal,
            'rangeMax': item.weaponProperties!.rangeMax,
          },
    'armorProperties': item.armorProperties == null
        ? null
        : {
            'acBase': item.armorProperties!.acBase,
            'acDexBonus': item.armorProperties!.acDexBonus,
            'strengthRequirement': item.armorProperties!.strengthRequirement,
            'stealthDisadvantage': item.armorProperties!.stealthDisadvantage,
          },
  };
}
