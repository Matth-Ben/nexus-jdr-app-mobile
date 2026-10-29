import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app_update/presentation/providers/update_banner_dismissal_provider.dart'
    show sharedPreferencesProvider;
import '../../domain/spell_preparation_filter.dart';

part 'spell_preparation_filter_preference_provider.g.dart';

/// Persiste le filtre "Tous"/"Préparés"/"Non préparés" de
/// [SpellPreparationCard][spell_preparation_card] (onglet "Sorts" de
/// `CharacterSpellsTabBody`), sous forme de la chaîne [SpellPreparationFilter.name]
/// via `SharedPreferences` — même pattern que
/// `app_update/presentation/providers/update_banner_dismissal_provider.dart`
/// (réutilise [sharedPreferencesProvider], défini là-bas, sans le
/// redéfinir ici).
///
/// **Portée volontairement globale à l'appareil, pas par personnage** :
/// demande utilisateur explicite du 29/10/2026 — contrairement à la
/// recherche de `character_list_screen.dart`, restée volontairement non
/// persistée, ce choix-ci doit survivre à la fermeture/réouverture de
/// n'importe quelle fiche. Stockage purement local (jamais synchronisé
/// entre appareils ni lié à un compte), donc valable aussi pour un lecteur
/// anonyme de `shared_character_view_screen.dart`.
///
/// [spell_preparation_card]: ../widgets/spell_preparation_card.dart
@Riverpod(keepAlive: true)
class SpellPreparationFilterPreferenceController
    extends _$SpellPreparationFilterPreferenceController {
  static const _prefsKey = 'spell_preparation_filter_preference';

  @override
  SpellPreparationFilter build() {
    // `.value` (getter nullable de `AsyncValue`) plutôt que `await` (`build`
    // synchrone) — même rationale que
    // `UpdateBannerDismissalController.build` : si `sharedPreferencesProvider`
    // n'a pas encore résolu, ce provider retombe momentanément sur
    // [SpellPreparationFilter.all] puis se reconstruit automatiquement dès
    // que `sharedPreferencesProvider` résout (`ref.watch`).
    final preferences = ref.watch(sharedPreferencesProvider).value;
    final storedName = preferences?.getString(_prefsKey);
    return SpellPreparationFilter.values.firstWhere(
      (filter) => filter.name == storedName,
      orElse: () => SpellPreparationFilter.all,
    );
  }

  /// Mémorise [filter] — reflété immédiatement dans [state] (sans attendre
  /// l'écriture disque), puis persisté via `SharedPreferences`.
  Future<void> setFilter(SpellPreparationFilter filter) async {
    state = filter;
    final preferences = await ref.read(sharedPreferencesProvider.future);
    await preferences.setString(_prefsKey, filter.name);
  }
}
