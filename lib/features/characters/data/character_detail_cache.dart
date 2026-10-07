import '../../../core/cache/reference_data_cache.dart';

/// Point unique de connaissance de l'entrée de cache de la fiche personnage
/// (`SupabaseCharacterRepository.fetchCharacterDetail`) : sa clé, et
/// l'emplacement de la ligne `characters` brute dans son payload.
///
/// Partagé par `SupabaseCharacterRepository` (lecture/écriture du cache,
/// écritures PV/XP en ligne) et `PendingCharacterWriteSyncer` (écritures
/// PV/XP synchronisées au retour du réseau), pour que ni l'un ni l'autre ne
/// duplique la forme de ce payload.
class CharacterDetailCache {
  const CharacterDetailCache(this._cache);

  final ReferenceDataCache _cache;

  /// Clé du payload sous laquelle est rangée la ligne `characters` brute
  /// (colonnes PostgREST telles quelles : `current_hp`, `temporary_hp`,
  /// `xp`...) — voir `SupabaseCharacterRepository._buildCharacterDetailPayload`.
  static const String rowKey = 'row';

  /// Clé de cache de la fiche [characterId] du compte [ownerId]. Scopée par
  /// `ownerId` : voir la documentation de classe de
  /// `SupabaseCharacterRepository` ("Isolation par utilisateur").
  static String keyFor({
    required String ownerId,
    required String characterId,
  }) => 'character_detail:$ownerId:$characterId';

  /// Reporte dans la fiche en cache les colonnes de `characters` qu'un
  /// `UPDATE` vient d'écrire **avec succès** côté serveur ([columns] est le
  /// corps même de cet `UPDATE`, ex. `{'current_hp': 7, 'temporary_hp': 0}`).
  ///
  /// Le cache reste ainsi le "dernier état serveur connu" même quand
  /// personne ne relit la fiche après l'écriture : synchronisation faite
  /// fiche fermée (le provider `autoDispose` invalidé par le coordinateur
  /// n'est alors écouté par personne), ou écriture en ligne réussie dont la
  /// relecture échoue. Sans ce report, la fiche rouverte hors ligne
  /// réaffichait la valeur d'avant l'écriture, et l'ajustement suivant en
  /// repartait.
  ///
  /// Jamais appelé pour une valeur seulement mise en file : seule une valeur
  /// confirmée par le serveur entre dans le cache.
  ///
  /// Ne fait rien si la fiche n'est pas en cache (rien à corriger) ou si son
  /// payload n'a pas la forme attendue ; ne touche à aucune autre partie du
  /// payload. Best-effort : l'écriture serveur a déjà réussi, une erreur ici
  /// n'est jamais remontée.
  Future<void> applyConfirmedColumns({
    required String ownerId,
    required String characterId,
    required Map<String, dynamic> columns,
  }) async {
    try {
      await _cache.updateIfPresent(
        keyFor(ownerId: ownerId, characterId: characterId),
        (payload) {
          if (payload is! Map) return null;
          final row = payload[rowKey];
          if (row is! Map) return null;
          return <String, dynamic>{
            ...Map<String, dynamic>.from(payload),
            rowKey: <String, dynamic>{
              ...Map<String, dynamic>.from(row),
              ...columns,
            },
          };
        },
      );
    } catch (_) {
      // Best-effort : voir la documentation de cette méthode.
    }
  }
}
