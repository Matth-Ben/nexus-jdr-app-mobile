import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/crash_reporting/crash_reporter.dart';
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
            id, name, edition, portrait_url, max_hp, current_hp,
            race_id, subrace_id, race_custom_text, background_id, alignment_id,
            sexe, age, height, weight, eyes, skin, hair,
            appearance_text, traits_text, ideals_text, bonds_text, flaws_text,
            backstory_text, allies_text, features_text, treasure_text,
            character_classes(class_id, subclass_id, level, is_primary),
            character_ability_scores(ability_id, score),
            character_skill_proficiencies(skill_id, proficiency),
            character_tool_proficiencies(tool_id, custom_text),
            character_languages(language_id),
            character_spells(spell_id, status),
            character_class_options(class_feature_id, level, chosen_value)
          ''')
          .eq('id', characterId)
          .eq('owner_id', ownerId)
          .maybeSingle();
      if (row == null) {
        throw const CharacterCreationFailure('Personnage introuvable.');
      }
      // Résolution SÉPARÉE de `class_features` (choice_type/class_id/
      // subclass_id) pour les lignes `character_class_options` de niveau 1
      // — correctif D102 (`docs/dette-technique.md`), même convention que
      // `data/character_repository.dart` (jamais une jointure Postgrest
      // embarquée pour `class_features`, voir la doc de classe de
      // `ClassFeatureChoiceInfo`).
      final classOptionRows =
          (row['character_class_options'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>();
      final classFeatureIds = <int>{
        for (final optionRow in classOptionRows)
          if (optionRow['class_feature_id'] is num)
            (optionRow['class_feature_id'] as num).toInt(),
      };
      var classFeaturesById = const <int, ClassFeatureChoiceInfo>{};
      if (classFeatureIds.isNotEmpty) {
        final featureRows = await _client
            .from('class_features')
            .select('id, choice_type, class_id, subclass_id')
            .inFilter('id', classFeatureIds.toList());
        classFeaturesById = {
          for (final featureRow in featureRows)
            (featureRow['id'] as num).toInt(): (
              choiceType: featureRow['choice_type'] as String?,
              classId: featureRow['class_id'] is num
                  ? (featureRow['class_id'] as num).toInt()
                  : null,
              subclassId: featureRow['subclass_id'] is num
                  ? (featureRow['subclass_id'] as num).toInt()
                  : null,
            ),
        };
      }
      return CharacterEditSnapshot.fromRow(
        row,
        classFeaturesById: classFeaturesById,
      );
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

      // Expertise du Roublard : rehausse/réabaisse la maîtrise des
      // compétences concernées — correctif D102 (`docs/dette-
      // technique.md`). APRÈS [plan.skillInserts] : une compétence
      // nouvellement choisie ET mise en Expertise dans le même
      // enregistrement doit déjà exister en base pour que ce `UPDATE` la
      // trouve.
      if (plan.expertiseSkillUpgrades.isNotEmpty) {
        await _client
            .from('character_skill_proficiencies')
            .update({'proficiency': 'expertise'})
            .eq('character_id', characterId)
            .inFilter('skill_id', plan.expertiseSkillUpgrades.toList());
      }
      if (plan.expertiseSkillDowngrades.isNotEmpty) {
        await _client
            .from('character_skill_proficiencies')
            .update({'proficiency': 'competente'})
            .eq('character_id', characterId)
            .inFilter('skill_id', plan.expertiseSkillDowngrades.toList());
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
            .inFilter('spell_id', plan.spellDeletes.toList())
            // Jamais une ligne 'inné' : un sort inné vient de la race, pas
            // d'un choix de classe. Un même sort peut avoir deux lignes
            // (une innée, une ordinaire — aucune contrainte d'unicité en
            // base) : seule la ligne ordinaire part, la ligne innée garde
            // son compteur `innate_uses_spent`.
            .neq('status', CharacterEditSnapshot.innateStatus.value);
      }
      if (plan.spellInserts.isNotEmpty) {
        await _client.from('character_spells').insert([
          for (final spell in plan.spellInserts)
            {
              'character_id': characterId,
              'spell_id': spell.spellId,
              'status': spell.status.value,
              // D40 (`docs/dette-technique.md`) : `plan.classChange?.classId`
              // vaut `null` dès que l'édition ne change NI la classe NI la
              // sous-classe (ex. remplacer un sort de niveau 1 sans toucher
              // à la classe), alors que la classe d'origine est connue et
              // inchangée dans ce cas précis — voir
              // `CharacterEditPlan.spellSourceClassId`.
              'source_class_id': plan.spellSourceClassId,
            },
        ]);
      }

      // Choix nommé de CLASSE (Style de combat/Ennemi juré) — correctif
      // D102. Résolution `class_feature_id` identique à
      // `CharacterCreationRepository.createCharacter` : une classe sans
      // ligne `class_features` correspondante (cas défensif) n'écrit
      // simplement rien.
      final classFeatureWrite = plan.classFeatureChoiceWrite;
      if (classFeatureWrite != null) {
        final featureRows = await _client
            .from('class_features')
            .select('id')
            .eq('class_id', classFeatureWrite.classId)
            .eq('level', 1)
            .eq('choice_type', classFeatureWrite.choiceType)
            .limit(1);
        if (featureRows.isNotEmpty) {
          final featureId = (featureRows.first['id'] as num).toInt();
          // Supprime TOUJOURS la ligne existante avant de réinsérer — sans
          // effet après une purge de `classChange?.classChanged` (déjà
          // fait plus haut), nécessaire pour un changement de VALEUR seule
          // (ex. "Défense" -> "Duel" sans changer de classe).
          await _client
              .from('character_class_options')
              .delete()
              .eq('character_id', characterId)
              .eq('class_feature_id', featureId);
          await _client.from('character_class_options').insert({
            'character_id': characterId,
            'class_feature_id': featureId,
            'level': 1,
            'chosen_value': classFeatureWrite.chosenValue,
          });
        }
      }

      // Second choix de niveau 1 propre à la SOUS-CLASSE (ex. Ancêtre
      // draconique) — correctif D102, même rationale que ci-dessus.
      final subclassFeatureWrite = plan.subclassFeatureChoiceWrite;
      if (subclassFeatureWrite != null) {
        final featureRows = await _client
            .from('class_features')
            .select('id')
            .eq('subclass_id', subclassFeatureWrite.subclassId)
            .eq('level', 1)
            .not('choice_type', 'is', null)
            .neq('choice_type', 'sous_classe')
            .limit(1);
        if (featureRows.isNotEmpty) {
          final featureId = (featureRows.first['id'] as num).toInt();
          await _client
              .from('character_class_options')
              .delete()
              .eq('character_id', characterId)
              .eq('class_feature_id', featureId);
          await _client.from('character_class_options').insert({
            'character_id': characterId,
            'class_feature_id': featureId,
            'level': 1,
            'chosen_value': subclassFeatureWrite.chosenValue,
          });
        }
      }

      // Expertise du Roublard : lignes `character_class_options` purement
      // descriptives (carte "CHOIX DE CLASSE") — correctif D102, même
      // rationale que ci-dessus. Le bonus RÉEL a déjà été écrit plus haut
      // via [plan.expertiseSkillUpgrades]/[plan.expertiseSkillDowngrades].
      final expertiseWrite = plan.expertiseOptionsWrite;
      if (expertiseWrite != null) {
        final featureRows = await _client
            .from('class_features')
            .select('id')
            .eq('class_id', expertiseWrite.classId)
            .eq('level', 1)
            .eq('choice_type', 'expertise')
            .limit(1);
        if (featureRows.isNotEmpty) {
          final featureId = (featureRows.first['id'] as num).toInt();
          await _client
              .from('character_class_options')
              .delete()
              .eq('character_id', characterId)
              .eq('class_feature_id', featureId);
          await _client.from('character_class_options').insert([
            for (final value in expertiseWrite.chosenValues)
              {
                'character_id': characterId,
                'class_feature_id': featureId,
                'level': 1,
                'chosen_value': value,
              },
          ]);
        }
      }
    } on CharacterCreationFailure {
      rethrow;
    } on PostgrestException catch (error) {
      throw mapCharacterCreationError(
        error,
        fallbackMessage: _saveErrorMessage,
      );
    } catch (error, stackTrace) {
      // Remonté à Crashlytics (dette D13) : modification de personnage,
      // écritures séquentielles sans vraie transaction (voir la doc de
      // [save]) — un bug silencieux ici pourrait laisser le personnage dans
      // un état partiellement modifié sans jamais être signalé.
      reportNonFatal(error, stackTrace);
      throw mapUnknownCharacterCreationError();
    }
  }
}
