import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cache/reference_data_cache.dart';
import '../domain/proficiency_catalog.dart';
import 'character_error_mapper.dart';
import 'proficiency_catalog_row_mapper.dart';

/// Langue d'affichage des noms d'armes/armures/boucliers, en dur pour
/// l'instant — même rationale que `_locale` de `character_repository.dart`.
const String _locale = 'fr';

const String _cacheKey = 'proficiency_catalog';

/// Lecture de référence de TOUT le catalogue d'armes/armures/boucliers
/// ordinaires (objets magiques exclus) — alimente le panneau "Infos" ouvert
/// depuis une chip de maîtrise de l'onglet "Compétences"
/// (`proficiency_detail_panel.dart`), résolu ensuite par
/// `ProficiencyTokenResolver`.
///
/// Abstraction dédiée (plutôt qu'une méthode ajoutée à
/// `CharacterRepository`) : même rationale que `PactWeaponRepository`/
/// `WarlockPactSpellRepository`/`SubclassChoiceRepository` — lecture seule
/// sur des tables de référence, ne doit pas s'imposer aux doubles de test
/// des autres écrans.
///
/// Contrairement à `PactWeaponRepository.fetchEligibleWeapons` (armes de
/// corps à corps uniquement, pour la feuille « FORME DE L'ARME »),
/// [fetchCatalog] renvoie TOUTES les armes (corps à corps ET à distance :
/// les tokens `'courantes'`/`'martiales'` couvrent les deux) ainsi que
/// toutes les armures/tous les boucliers ordinaires (`items.category`
/// `'armure'`/`'bouclier'`, `'objet_magique'` explicitement exclu par les
/// filtres de requête).
abstract class ProficiencyCatalogRepository {
  /// Réseau d'abord, dernière lecture réussie en secours (même stratégie que
  /// [PactWeaponRepository.fetchEligibleWeapons]).
  Future<ProficiencyCatalog> fetchCatalog();
}

class SupabaseProficiencyCatalogRepository
    implements ProficiencyCatalogRepository {
  const SupabaseProficiencyCatalogRepository(this._client, [this._cache]);

  final SupabaseClient _client;

  /// Cache de secours — stratégie identique à `PactWeaponRepository`/
  /// `WarlockPactSpellRepository.fetchPatronExtendedSpells` (réseau d'abord,
  /// résultat écrit au cache ; en cas d'échec réseau, dernière lecture
  /// réussie, même périmée). Dupliquée une 4e fois plutôt que factorisée :
  /// signalé en revue de code que ces trois repositories partagent déjà ce
  /// patron (`try`/`put`/`catch`/`get` + `_rows` helper) — une factorisation
  /// propre aurait dû généraliser la forme du payload mis en cache (un seul
  /// tableau `items` pour `PactWeaponRepository`, trois tableaux distincts
  /// ici) sans rien casser des trois repositories déjà en production ; jugé
  /// hors périmètre de ce chantier (risque de régression disproportionné par
  /// rapport au gain de duplication évité pour ce 4e cas). Signalé au chef
  /// de projet dans le rapport de cette tâche plutôt que tranché seul.
  final ReferenceDataCache? _cache;

  @override
  Future<ProficiencyCatalog> fetchCatalog() async {
    try {
      final weaponRows = await _client
          .from('items')
          .select(
            'id, category, '
            'weapon_properties(damage_dice, damage_type, properties)',
          )
          .eq('category', 'arme')
          .order('id', ascending: true);
      final armorRows = await _client
          .from('items')
          .select(
            'id, category, '
            'armor_properties(ac_base, ac_dex_bonus, strength_requirement, '
            'stealth_disadvantage)',
          )
          .eq('category', 'armure')
          .order('id', ascending: true);
      final shieldRows = await _client
          .from('items')
          .select(
            'id, category, '
            'armor_properties(ac_base, ac_dex_bonus, strength_requirement, '
            'stealth_disadvantage)',
          )
          .eq('category', 'bouclier')
          .order('id', ascending: true);

      final ids = <String>{
        ...ProficiencyCatalogRowMapper.collectIds(weaponRows),
        ...ProficiencyCatalogRowMapper.collectIds(armorRows),
        ...ProficiencyCatalogRowMapper.collectIds(shieldRows),
      };
      final nameRows = await _fetchNameRows(ids);
      final payload = <String, dynamic>{
        'weapons': weaponRows,
        'armors': armorRows,
        'shields': shieldRows,
        'names': nameRows,
      };
      try {
        await _cache?.put(_cacheKey, payload);
      } catch (_) {
        // Best-effort.
      }
      return _parse(payload);
    } catch (error) {
      try {
        final cached = await _cache?.get(_cacheKey);
        if (cached is Map<String, dynamic>) return _parse(cached);
      } catch (_) {
        // Cache illisible : on relance l'erreur d'origine.
      }
      if (error is PostgrestException) throw mapCharacterError(error);
      throw mapUnknownCharacterError();
    }
  }

  Future<List<Map<String, dynamic>>> _fetchNameRows(Set<String> ids) async {
    if (ids.isEmpty) return const [];
    return _client
        .from('translations')
        .select('entity_id, value')
        .eq('entity_type', 'item')
        .eq('field_name', 'name')
        .eq('locale', _locale)
        .inFilter('entity_id', ids.toList());
  }

  static List<Map<String, dynamic>> _rows(Object? value) => value is List
      ? [for (final row in value) Map<String, dynamic>.from(row as Map)]
      : const [];

  static ProficiencyCatalog _parse(Map<String, dynamic> payload) {
    final names = <String, String>{
      for (final row in _rows(payload['names']))
        if (row['entity_id'] != null && row['value'] is String)
          row['entity_id'].toString(): row['value'] as String,
    };
    return ProficiencyCatalog(
      weapons: ProficiencyCatalogRowMapper.toWeapons(
        _rows(payload['weapons']),
        names: names,
      ),
      armors: ProficiencyCatalogRowMapper.toArmors(
        _rows(payload['armors']),
        names: names,
        category: 'armure',
      ),
      shields: ProficiencyCatalogRowMapper.toArmors(
        _rows(payload['shields']),
        names: names,
        category: 'bouclier',
      ),
    );
  }
}
