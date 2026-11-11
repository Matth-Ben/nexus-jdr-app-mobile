import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/analytics/analytics_preferences_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

part 'character_last_opened_provider.g.dart';

/// Horodatage **local** (par appareil, jamais synchronisé) de la dernière
/// ouverture de la fiche de chaque personnage, `{characterId: epochMs}` —
/// alimente le tri « Dernière ouverture » de la liste (P18).
///
/// Persisté dans `SharedPreferences` sous une clé **scopée par `ownerId`**
/// (`character_last_opened:<ownerId>`) : un autre compte du même appareil ne
/// relit jamais ces horodatages. Aucun champ serveur, aucune migration.
@Riverpod(keepAlive: true)
class CharacterLastOpened extends _$CharacterLastOpened {
  static const _keyPrefix = 'character_last_opened:';

  @override
  Map<String, int> build() {
    final ownerId = ref.watch(currentUserProvider)?.id;
    final prefs = ref.watch(sharedPreferencesProvider).value;
    if (ownerId == null || prefs == null) return const {};
    return _decode(prefs.getString('$_keyPrefix$ownerId'));
  }

  /// Écrit l'horodatage d'ouverture de [characterId] (à l'ouverture de la
  /// fiche). [now] : injectable pour les tests.
  Future<void> record(String characterId, {DateTime? now}) async {
    final ownerId = ref.read(currentUserProvider)?.id;
    if (ownerId == null) return;
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final key = '$_keyPrefix$ownerId';
    final next = {
      ..._decode(prefs.getString(key)),
      characterId: (now ?? DateTime.now()).millisecondsSinceEpoch,
    };
    state = next;
    await prefs.setString(key, jsonEncode(next));
  }

  /// Retire les identifiants qui ne figurent plus dans [existingIds]
  /// (personnages supprimés), à chaque chargement de la liste.
  Future<void> purge(Set<String> existingIds) async {
    final ownerId = ref.read(currentUserProvider)?.id;
    if (ownerId == null) return;
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final key = '$_keyPrefix$ownerId';
    final current = _decode(prefs.getString(key));
    final kept = {
      for (final entry in current.entries)
        if (existingIds.contains(entry.key)) entry.key: entry.value,
    };
    if (kept.length == current.length) return;
    state = kept;
    await prefs.setString(key, jsonEncode(kept));
  }

  static Map<String, int> _decode(String? raw) {
    if (raw == null) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      return {
        for (final entry in decoded.entries)
          if (entry.key is String && entry.value is num)
            entry.key as String: (entry.value as num).toInt(),
      };
    } catch (_) {
      return const {};
    }
  }
}
