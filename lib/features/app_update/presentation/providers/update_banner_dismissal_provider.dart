import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'update_banner_dismissal_provider.g.dart';

/// Instance partagée de `SharedPreferences` — `keepAlive`, résolue une seule
/// fois pour toute la session (même rationale que `packageInfoProvider`).
@Riverpod(keepAlive: true)
Future<SharedPreferences> sharedPreferences(Ref ref) =>
    SharedPreferences.getInstance();

/// Persiste, sous forme d'une simple chaîne `SharedPreferences` (stockage
/// local à l'appareil, jamais synchronisé), la dernière valeur de
/// `AppVersionCheckResult.latestVersion` pour laquelle la bannière "Mise à
/// jour suggérée" (`widgets/update_suggested_banner.dart`) a été refermée
/// par le joueur.
///
/// **Pourquoi par version plutôt qu'un simple booléen "refermée"** : si une
/// NOUVELLE version sort après la fermeture (`latestVersion` change), la
/// comparaison `state == result.latestVersion` échoue et la bannière
/// réapparaît normalement pour cette nouvelle version — spec explicite de la
/// tâche ("si une NOUVELLE version sort, la bannière doit pouvoir
/// réapparaître même si l'ancienne avait été fermée").
@Riverpod(keepAlive: true)
class UpdateBannerDismissalController
    extends _$UpdateBannerDismissalController {
  static const _prefsKey = 'app_update_banner_dismissed_version';

  @override
  String? build() {
    // `.value` (getter nullable de `AsyncValue`, même convention que
    // `character_list_screen.dart::charactersAsync.value`) plutôt que
    // `await` (`build` synchrone) : si `sharedPreferencesProvider` n'a pas
    // encore résolu (très bref, stockage local), ce provider retombe
    // momentanément sur `null` (rien de refermé) puis se reconstruit
    // automatiquement dès que `sharedPreferencesProvider` résout
    // (`ref.watch`) — au pire un flash très bref de la bannière si elle
    // avait déjà été refermée lors d'une session précédente, jamais un
    // blocage/une exception.
    final preferences = ref.watch(sharedPreferencesProvider).value;
    return preferences?.getString(_prefsKey);
  }

  /// Marque [latestVersion] comme refermée — reflété immédiatement dans
  /// [state] (la bannière disparaît sans attendre l'écriture disque), puis
  /// persisté via `SharedPreferences`.
  Future<void> dismiss(String latestVersion) async {
    state = latestVersion;
    final preferences = await ref.read(sharedPreferencesProvider.future);
    await preferences.setString(_prefsKey, latestVersion);
  }
}
