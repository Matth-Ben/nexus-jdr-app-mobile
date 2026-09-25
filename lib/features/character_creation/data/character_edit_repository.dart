import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/character_creation_failure.dart';
import '../domain/character_edit_planner.dart';
import '../domain/character_edit_snapshot.dart';
import 'character_creation_error_mapper.dart';

/// Lecture et enregistrement d'une modification de personnage via
/// l'assistant de création (mode modification, voir
/// `presentation/providers/character_edit_session_provider.dart`).
///
/// Séparé de `CharacterCreationRepository` pour ne pas alourdir son contrat
/// (et ses nombreux faux de test) avec un parcours qui ne sert qu'ici.
abstract class CharacterEditRepository {
  Future<CharacterEditSnapshot> fetchSnapshot(String characterId);

  /// Exécute [plan] pour [characterId]. Écritures séquentielles, sans vraie
  /// transaction (même compromis assumé que `createCharacter`) : en cas
  /// d'échec au milieu, une partie des modifications peut déjà être
  /// enregistrée — l'erreur est remontée et le joueur peut relancer
  /// l'enregistrement (le plan étant un diff, le relancer est sans danger).
  Future<void> save({
    required String characterId,
    required CharacterEditPlan plan,
  });
}

class SupabaseCharacterEditRepository implements CharacterEditRepository {
  SupabaseCharacterEditRepository(this._client);

  final SupabaseClient _client;

  static const String _fetchErrorMessage =
      'Impossible de charger le personnage à modifier. Réessayez.';
  static const String _saveErrorMessage =
      "Impossible d'enregistrer les modifications. Réessayez.";

  String _requireOwnerId() {
    final ownerId = _client.auth.currentUser?.id;
    if (ownerId == null) {
      throw const CharacterCreationFailure(
        'Session expirée. Reconnectez-vous puis réessayez.',
      );
    }
    return ownerId;
  }

  @override
  Future<CharacterEditSnapshot> fetchSnapshot(String characterId) async {
    final ownerId = _requireOwnerId();
    try {
      final row = await _client
          .from('characters')
          .select('''
            id, name, portrait_url, max_hp, current_hp,
            race_id, subrace_id, race_custom_text, background_id, alignment_id,
            sexe, age, height, weight, eyes, skin, hair,
            appearance_text, traits_text, ideals_text, bonds_text, flaws_text,
            backstory_text, allies_text, features_text, treasure_text,
            character_classes(class_id, subclass_id, level, is_primary),
            character_ability_scores(ability_id, score),
            character_skill_proficiencies(skill_id, proficiency),
            character_tool_proficiencies(tool_id, custom_text),
            character_languages(language_id),
            character_spells(spell_id, status)
          ''')
          .eq('id', characterId)
          .eq('owner_id', ownerId)
          .maybeSingle();
      if (row == null) {
        throw const CharacterCreationFailure('Personnage introuvable.');
      }
      return CharacterEditSnapshot.fromRow(row);
    } on CharacterCreationFailure {
      rethrow;
    } on PostgrestException catch (error) {
      throw mapCharacterCreationError(
        error,
        fallbackMessage: _fetchErrorMessage,
      );
    } catch (_) {
      throw mapUnknownCharacterCreationError();
    }
  }

  @override
  Future<void> save({
    required String characterId,
    required CharacterEditPlan plan,
  }) async {
    final ownerId = _requireOwnerId();
    try {
      await _client
          .from('characters')
          .update(plan.characterUpdate)
          .eq('id', characterId)
          .eq('owner_id', ownerId);

      final classChange = plan.classChange;
      if (classChange != null) {
        await _client
            .from('character_classes')
            .update({
              'class_id': classChange.classId,
              'subclass_id': classChange.subclassId,
            })
            .eq('character_id', characterId)
            .eq('is_primary', true);
        if (classChange.hpRolled != null) {
          await _client
              .from('character_level_hp')
              .update({'hp_rolled': classChange.hpRolled})
              .eq('character_id', characterId)
              .eq('level', 1);
        }
        if (classChange.classChanged) {
          // Données propres à l'ancienne classe (niveau 1 : aucune montée de
          // niveau à préserver).
          for (final table in const [
            'character_feature_uses',
            'character_class_options',
            'character_spell_slots',
            'character_pact_slots',
          ]) {
            await _client.from(table).delete().eq('character_id', characterId);
          }
        }
      }

      final scores = plan.abilityScores;
      if (scores != null) {
        await _client
            .from('character_ability_scores')
            .delete()
            .eq('character_id', characterId);
        await _client.from('character_ability_scores').insert([
          for (final entry in scores.entries)
            {
              'character_id': characterId,
              'ability_id': entry.key,
              'score': entry.value,
            },
        ]);
      }

      if (plan.skillDeletes.isNotEmpty) {
        await _client
            .from('character_skill_proficiencies')
            .delete()
            .eq('character_id', characterId)
            .inFilter('skill_id', plan.skillDeletes.toList());
      }
      if (plan.skillInserts.isNotEmpty) {
        await _client.from('character_skill_proficiencies').insert([
          for (final skillId in plan.skillInserts)
            {
              'character_id': characterId,
              'skill_id': skillId,
              'proficiency': 'competente',
            },
        ]);
      }

      for (final tool in plan.toolDeletes) {
        var query = _client
            .from('character_tool_proficiencies')
            .delete()
            .eq('character_id', characterId);
        query = tool.toolId != null
            ? query.eq('tool_id', tool.toolId!)
            : query.isFilter('tool_id', null);
        query = tool.customText != null
            ? query.eq('custom_text', tool.customText!)
            : query.isFilter('custom_text', null);
        await query;
      }
      if (plan.toolInserts.isNotEmpty) {
        await _client.from('character_tool_proficiencies').insert([
          for (final tool in plan.toolInserts)
            {
              'character_id': characterId,
              'tool_id': tool.toolId,
              'custom_text': tool.customText,
            },
        ]);
      }

      if (plan.languageDeletes.isNotEmpty) {
        await _client
            .from('character_languages')
            .delete()
            .eq('character_id', characterId)
            .inFilter('language_id', plan.languageDeletes.toList());
      }
      if (plan.languageInserts.isNotEmpty) {
        await _client.from('character_languages').insert([
          for (final languageId in plan.languageInserts)
            {'character_id': characterId, 'language_id': languageId},
        ]);
      }

      if (plan.spellDeletes.isNotEmpty) {
        await _client
            .from('character_spells')
            .delete()
            .eq('character_id', characterId)
            .inFilter('spell_id', plan.spellDeletes.toList());
      }
      if (plan.spellInserts.isNotEmpty) {
        await _client.from('character_spells').insert([
          for (final spell in plan.spellInserts)
            {
              'character_id': characterId,
              'spell_id': spell.spellId,
              'status': spell.status,
              'source_class_id': plan.classChange?.classId,
            },
        ]);
      }
    } on CharacterCreationFailure {
      rethrow;
    } on PostgrestException catch (error) {
      throw mapCharacterCreationError(
        error,
        fallbackMessage: _saveErrorMessage,
      );
    } catch (_) {
      throw mapUnknownCharacterCreationError();
    }
  }
}
