import 'package:supabase_flutter/supabase_flutter.dart';

import '../../character_creation/data/character_creation_error_mapper.dart';
import '../../character_creation/domain/character_creation_failure.dart';
import '../domain/xml_import_save_data.dart';

const String _saveImportedCharacterErrorMessage =
    'Impossible d\'enregistrer le personnage importé. Réessayez.';

/// Passerelle d'écriture pour un personnage importé depuis un export XML
/// aidedd.org (`features/xml_import/`), une fois entièrement résolu par
/// `domain/xml_import_save_data_resolver.dart` (potentiellement après
/// correction manuelle sur l'écran de vérification).
///
/// Réutilise [CharacterCreationFailure]/`mapCharacterCreationError` de
/// `character_creation/data/character_creation_error_mapper.dart` plutôt que
/// de dupliquer un nouveau type d'échec dédié — contrairement au principe de
/// duplication habituel de ce dépôt entre deux fonctionnalités (voir la
/// documentation de classe de `CharacterCreationFailure`) : `xml_import`
/// importe déjà abondamment les modèles de `character_creation/domain/`
/// depuis l'increment 1 (`RaceOption`, `ClassOption`...), le couplage entre
/// les deux fonctionnalités existe donc déjà largement ; introduire un second
/// type d'échec identique n'aurait apporté aucune isolation supplémentaire
/// réelle. Signalé ici plutôt qu'appliqué silencieusement, à valider par le
/// chef de projet si une duplication stricte était malgré tout préférée.
abstract class XmlImportRepository {
  /// Écrit [data] (et [characterName]) dans les mêmes tables que
  /// `CharacterCreationRepository.createCharacter` — voir sa documentation
  /// pour le détail du compromis assumé (pas de transaction Postgres
  /// atomique, nettoyage "best effort" de la ligne `characters` en cas
  /// d'échec d'une table enfant), repris à l'identique ici. Retourne
  /// l'identifiant du personnage créé.
  Future<String> saveImportedCharacter({
    required XmlImportSaveData data,
    required String characterName,
  });
}

/// Implémentation réelle, basée sur `Supabase.instance.client`.
class SupabaseXmlImportRepository implements XmlImportRepository {
  const SupabaseXmlImportRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<String> saveImportedCharacter({
    required XmlImportSaveData data,
    required String characterName,
  }) async {
    final ownerId = _client.auth.currentUser?.id;
    if (ownerId == null) {
      throw const CharacterCreationFailure(
        'Session expirée. Reconnectez-vous pour importer un personnage.',
      );
    }

    String? characterId;
    try {
      final characterRow = await _client
          .from('characters')
          .insert({
            'owner_id': ownerId,
            'name': characterName,
            'race_id': data.raceId,
            // Le XML aidedd.org n'exporte aucun champ sous-race séparé de
            // `<race>` (voir `docs/xml-import-reference-mapping.md`, section
            // "Point encore ouvert : raceCustom" — `raceCustom` lui-même
            // reste ambigu/non vérifié empiriquement, traité comme
            // purement informatif via [XmlImportSaveData.raceCustomText],
            // jamais comme une sous-race) : toujours `null`.
            'subrace_id': null,
            'race_custom_text': data.raceCustomText,
            'background_id': data.backgroundId,
            'background_custom_text': data.backgroundCustomText,
            'alignment_id': data.alignmentId,
            'xp': data.xp,
            'max_hp': data.maxHp,
            'current_hp': data.maxHp,
            'temporary_hp': 0,
            'sexe': data.sexe,
            'age': data.age,
            'height': data.height,
            'weight': data.weight,
            'eyes': data.eyes,
            'skin': data.skin,
            'hair': data.hair,
            'portrait_url': null,
            'appearance_text': data.appearanceText,
            'traits_text': data.traitsText,
            'ideals_text': data.idealsText,
            'bonds_text': data.bondsText,
            'flaws_text': data.flawsText,
            'backstory_text': data.backstoryText,
            'allies_text': data.alliesText,
            'features_text': data.featuresText,
            'treasure_text': data.treasureText,
            'currency_gp': data.currencyGp,
            'currency_pp': data.currencyPp,
            'currency_ep': data.currencyEp,
            'currency_sp': data.currencySp,
            'currency_cp': data.currencyCp,
          })
          .select('id')
          .single();
      characterId = characterRow['id'] as String;

      // Défense en profondeur : `xml_import_review_screen.dart` bloque déjà
      // la validation tant que la classe reste `unrecognized`, donc
      // `data.classId` ne devrait plus jamais être `null` ici en usage
      // normal — ce garde ne fait que protéger contre un bug amont.
      if (data.classId != null) {
        await _client.from('character_classes').insert({
          'character_id': characterId,
          'class_id': data.classId,
          // Sous-classe non câblée dans cet increment (voir
          // `xml_character_import_resolver.dart` : `subclassCandidates` est
          // toujours vide faute de catalogue Supabase dédié) — cohérent avec
          // l'assistant de création manuel, qui ne propose lui-même encore
          // aucun choix de sous-classe (`CharacterCreationDraft` n'a pas de
          // `subclassId`).
          'subclass_id': null,
          'level': data.level,
          'is_primary': true,
        });
      }

      if (data.levelHp.isNotEmpty) {
        await _client.from('character_level_hp').insert([
          for (final line in data.levelHp)
            {
              'character_id': characterId,
              'level': line.level,
              'hp_rolled': line.hpRolled,
              // 'lance' (pas 'moyenne') : un export aidedd.org porte une
              // valeur de PV réellement gagnée à chaque niveau (`hp_brut`),
              // par opposition au calcul RAW moyen que
              // `character_creation_repository.dart` applique au niveau 1
              // d'un personnage encore en cours de création — voir
              // `domain/xml_import_hit_points_calculator.dart`.
              'method': 'lance',
            },
        ]);
      }

      if (data.abilityScores.isNotEmpty) {
        await _client.from('character_ability_scores').insert([
          for (final entry in data.abilityScores.entries)
            {
              'character_id': characterId,
              'ability_id': entry.key,
              'score': entry.value,
            },
        ]);
      }

      if (data.skillProficiencyLines.isNotEmpty) {
        await _client.from('character_skill_proficiencies').insert([
          for (final line in data.skillProficiencyLines)
            {
              'character_id': characterId,
              'skill_id': line.skillId,
              'proficiency': 'competente',
            },
        ]);
      }

      if (data.toolProficiencyLines.isNotEmpty) {
        await _client.from('character_tool_proficiencies').insert([
          for (final line in data.toolProficiencyLines)
            {
              'character_id': characterId,
              'tool_id': line.toolId,
              'custom_text': line.customText,
            },
        ]);
      }

      if (data.languageIds.isNotEmpty) {
        await _client.from('character_languages').insert([
          for (final languageId in data.languageIds)
            {'character_id': characterId, 'language_id': languageId},
        ]);
      }

      if (data.spellLines.isNotEmpty) {
        await _client.from('character_spells').insert([
          for (final line in data.spellLines)
            {
              'character_id': characterId,
              'spell_id': line.spellId,
              'status': line.status,
              'source_class_id': line.sourceClassId,
            },
        ]);
      }

      if (data.inventoryLines.isNotEmpty) {
        await _client.from('character_inventory').insert([
          for (final line in data.inventoryLines)
            {
              'character_id': characterId,
              'item_id': line.itemId,
              'custom_name': line.customName,
              'quantity': line.quantity,
              'equipped': line.equipped,
              'notes': null,
            },
        ]);
      }

      return characterId;
    } on PostgrestException catch (error) {
      await _cleanupPartialCharacter(characterId);
      throw mapCharacterCreationError(
        error,
        fallbackMessage: _saveImportedCharacterErrorMessage,
      );
    } catch (_) {
      await _cleanupPartialCharacter(characterId);
      throw mapUnknownCharacterCreationError();
    }
  }

  /// Nettoyage best-effort après un échec d'insert de table enfant — voir
  /// `CharacterCreationRepository.createCharacter._cleanupPartialCharacter`
  /// pour le rationale complet de ce compromis, repris à l'identique ici.
  Future<void> _cleanupPartialCharacter(String? characterId) async {
    if (characterId == null) return;
    try {
      await _client.from('characters').delete().eq('id', characterId);
    } catch (_) {
      // Best-effort : voir la documentation de cette méthode.
    }
  }
}
