import 'package:supabase_flutter/supabase_flutter.dart';

import '../../character_creation/data/background_row_mapper.dart';
import '../../character_creation/data/race_row_mapper.dart';
import '../../character_creation/data/spell_row_mapper.dart';
import '../../character_creation/domain/background_option.dart';
import '../../character_creation/domain/race_option.dart';
import '../../character_creation/domain/spell_option.dart';

/// Langue des noms créés/recherchés via `translations` — même valeur en dur
/// que `_locale` de `character_creation/data/character_creation_repository
/// .dart` (voir sa doc pour le rationale, non répété ici).
const String _locale = 'fr';

/// Crée (ou retrouve) une entrée "placeholder" dans un catalogue partagé
/// (`races`/`backgrounds`/`spells`) pour un nom brut issu d'un export XML
/// aidedd.org qui ne correspond à rien de connu dans ces catalogues.
///
/// Point d'entrée du bouton "Garder comme élément personnalisé" de l'écran de
/// vérification d'import (`presentation/xml_import_review_screen.dart`), pour
/// les 4 champs "en clair" concernés (Race, Historique, Sorts innés, Sorts
/// connus — PAS Classe, ni les champs codés armure/objets/compétences/
/// alignement/sexe, voir la consigne d'origine de la tâche) : contrairement
/// au comportement historique de ce bouton (`null` = "garder tel quel",
/// c'est-à-dire ne rien faire, voir `XmlFieldResolution.unrecognized` qui
/// reste alors inchangé), ces 4 champs créent désormais une vraie ligne dans
/// le catalogue partagé, marquée `is_incomplete = true` pour signaler qu'il
/// manque des informations à compléter plus tard côté contenu — la donnée du
/// joueur n'est ainsi plus jamais perdue silencieusement.
///
/// Chaque `findOrCreateXxx` fait deux inserts séquentiels côté création (la
/// table du catalogue elle-même, puis `translations` pour son nom) — jamais
/// une vraie transaction Postgres, même compromis assumé que
/// `CharacterCreationRepository.createCharacter`/`XmlImportRepository
/// .saveImportedCharacter` (voir leur documentation) : si le second insert
/// échoue, la ligne du premier est nettoyée au mieux ("best effort") avant de
/// relancer l'erreur d'origine.
abstract class XmlImportPlaceholderCatalogRepository {
  /// Retrouve une race déjà créée comme placeholder par un import précédent
  /// (recherche `ilike` insensible à la casse sur `translations.value`) ou,
  /// à défaut, en crée une nouvelle marquée `is_incomplete = true`.
  Future<RaceOption> findOrCreateRace(String rawName);

  /// Même mécanique que [findOrCreateRace], pour `backgrounds`.
  Future<BackgroundOption> findOrCreateBackground(String rawName);

  /// Même mécanique que [findOrCreateRace], pour `spells` — force toujours
  /// `level: 0` à la création (valeur arbitraire assumée, imposée aussi par
  /// la RLS d'insertion de `spells`, voir la migration correspondante du
  /// dépôt web).
  Future<SpellOption> findOrCreateSpell(String rawName);
}

/// Implémentation réelle, basée sur `Supabase.instance.client`.
class SupabaseXmlImportPlaceholderCatalogRepository
    implements XmlImportPlaceholderCatalogRepository {
  const SupabaseXmlImportPlaceholderCatalogRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<RaceOption> findOrCreateRace(String rawName) async {
    final existing = await _findExistingTranslation(
      entityType: 'race',
      rawName: rawName,
    );
    if (existing != null) {
      final row = await _client
          .from('races')
          .select('id, ability_bonuses, traits, is_incomplete')
          .eq('id', existing.entityId)
          .single();
      return RaceRowMapper.toRaceOption(
        row,
        names: {existing.entityId: existing.value},
      );
    }

    int? insertedId;
    try {
      final row = await _client
          .from('races')
          .insert({'is_incomplete': true})
          .select('id, ability_bonuses, traits, is_incomplete')
          .single();
      insertedId = (row['id'] as num).toInt();
      await _insertNameTranslation(
        entityType: 'race',
        entityId: insertedId,
        rawName: rawName,
      );
      return RaceRowMapper.toRaceOption(
        row,
        names: {insertedId.toString(): rawName},
      );
    } catch (_) {
      await _cleanupPartialEntity('races', insertedId);
      rethrow;
    }
  }

  @override
  Future<BackgroundOption> findOrCreateBackground(String rawName) async {
    final existing = await _findExistingTranslation(
      entityType: 'background',
      rawName: rawName,
    );
    if (existing != null) {
      final row = await _client
          .from('backgrounds')
          .select(
            'id, skill_proficiencies, tool_or_language_choices, equipment, '
            'is_incomplete',
          )
          .eq('id', existing.entityId)
          .single();
      return BackgroundRowMapper.toBackgroundOption(
        row,
        names: {existing.entityId: existing.value},
        featureNames: const {},
        featureDescriptions: const {},
      );
    }

    int? insertedId;
    try {
      final row = await _client
          .from('backgrounds')
          .insert({'is_incomplete': true})
          .select(
            'id, skill_proficiencies, tool_or_language_choices, equipment, '
            'is_incomplete',
          )
          .single();
      insertedId = (row['id'] as num).toInt();
      await _insertNameTranslation(
        entityType: 'background',
        entityId: insertedId,
        rawName: rawName,
      );
      return BackgroundRowMapper.toBackgroundOption(
        row,
        names: {insertedId.toString(): rawName},
        featureNames: const {},
        featureDescriptions: const {},
      );
    } catch (_) {
      await _cleanupPartialEntity('backgrounds', insertedId);
      rethrow;
    }
  }

  @override
  Future<SpellOption> findOrCreateSpell(String rawName) async {
    final existing = await _findExistingTranslation(
      entityType: 'spell',
      rawName: rawName,
    );
    if (existing != null) {
      final row = await _client
          .from('spells')
          .select('id, level, school, casting_time, is_incomplete')
          .eq('id', existing.entityId)
          .single();
      return SpellRowMapper.toSpellOption(
        row,
        names: {existing.entityId: existing.value},
      );
    }

    int? insertedId;
    try {
      // `level: 0` en dur (voir la doc de classe de
      // [findOrCreateSpell]/[XmlImportPlaceholderCatalogRepository]) : ni
      // deviné depuis le XML (aucune info fiable de niveau pour un sort non
      // catalogué), ni laissé à un défaut base — la RLS d'insertion de
      // `spells` l'exige explicitement (`is_incomplete = true and level =
      // 0`).
      final row = await _client
          .from('spells')
          .insert({'is_incomplete': true, 'level': 0})
          .select('id, level, school, casting_time, is_incomplete')
          .single();
      insertedId = (row['id'] as num).toInt();
      await _insertNameTranslation(
        entityType: 'spell',
        entityId: insertedId,
        rawName: rawName,
      );
      return SpellRowMapper.toSpellOption(
        row,
        names: {insertedId.toString(): rawName},
      );
    } catch (_) {
      await _cleanupPartialEntity('spells', insertedId);
      rethrow;
    }
  }

  /// Recherche une traduction `name` déjà existante pour [entityType] dont la
  /// valeur correspond à [rawName] (`ilike`, insensible à la casse) — évite
  /// de dupliquer une entrée déjà créée par un import précédent pour le même
  /// nom brut. Best-effort, pas d'accent-insensibilité (une entrée "Sort
  /// Maison" créée avec un accent différent de la recherche d'un import
  /// suivant ne sera pas retrouvée, une nouvelle entrée sera créée à côté) —
  /// limite assumée plutôt qu'une normalisation d'accents plus complexe pour
  /// ce dédoublonnage volontairement imparfait.
  Future<({String entityId, String value})?> _findExistingTranslation({
    required String entityType,
    required String rawName,
  }) async {
    final rows = await _client
        .from('translations')
        .select('entity_id, value')
        .eq('entity_type', entityType)
        .eq('field_name', 'name')
        .eq('locale', _locale)
        .ilike('value', rawName)
        .limit(1);
    if (rows.isEmpty) return null;
    final row = rows.first;
    final entityId = row['entity_id'] as String?;
    final value = row['value'] as String?;
    if (entityId == null || value == null) return null;
    return (entityId: entityId, value: value);
  }

  Future<void> _insertNameTranslation({
    required String entityType,
    required int entityId,
    required String rawName,
  }) async {
    await _client.from('translations').insert({
      'entity_type': entityType,
      'entity_id': entityId.toString(),
      'field_name': 'name',
      'locale': _locale,
      'value': rawName,
    });
  }

  /// Nettoyage best-effort après l'échec de l'insert `translations` qui suit
  /// la création d'une ligne [table]/[id] — même rationale que
  /// `CharacterCreationRepository.createCharacter._cleanupPartialCharacter`,
  /// avale silencieusement une éventuelle erreur de suppression pour ne
  /// jamais masquer l'erreur d'origine déjà en cours de propagation.
  Future<void> _cleanupPartialEntity(String table, int? id) async {
    if (id == null) return;
    try {
      await _client.from(table).delete().eq('id', id);
    } catch (_) {
      // Best-effort : voir la documentation de cette méthode.
    }
  }
}
