import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'locale_preference_provider.g.dart';

/// Instance partagée de `SharedPreferences` — `keepAlive`, résolue une seule
/// fois pour toute la session. Dupliquée depuis
/// `core/analytics/analytics_preferences_provider.dart::sharedPreferencesProvider`
/// (aucun import cross-feature établi pour ce provider ailleurs dans ce
/// dépôt à ce jour, voir aussi `features/app_update/presentation/providers/
/// update_banner_dismissal_provider.dart::sharedPreferencesProvider`) plutôt
/// que réutilisée en import cross-feature — même convention de duplication
/// assumée que ces deux providers.
@Riverpod(keepAlive: true)
Future<SharedPreferences> sharedPreferences(Ref ref) =>
    SharedPreferences.getInstance();

/// Clé `SharedPreferences` de la préférence de langue forcée — absente tant
/// que l'utilisateur n'a rien choisi explicitement dans l'écran "Langue"
/// (`features/profile/presentation/profile_language_screen.dart`).
const _localePrefsKey = 'locale_preference';

/// Préférence locale de langue forcée (écran "Langue", poussé depuis la
/// tuile "Langue" de l'écran Profil) — chantier "traduction de l'app" Phase
/// A : décision direction-artistique, stockage local uniquement (aucune
/// table Supabase), même précédent que
/// `AnalyticsPreferencesController`/`UpdateBannerDismissalController`.
///
/// État = [Locale]`?` : `null` signifie "suit la langue du téléphone" (valeur
/// par défaut, aucune clé écrite en `SharedPreferences` tant que
/// l'utilisateur n'a rien choisi explicitement) — câblé tel quel sur
/// `MaterialApp.router(locale: ...)` dans `main.dart::NexusJdrApp`, où
/// `null` laisse Flutter résoudre automatiquement la langue selon
/// l'appareil. Une valeur explicite (`Locale('fr')`/`Locale('en')`) force
/// cette langue indépendamment du téléphone.
@Riverpod(keepAlive: true)
class LocalePreferenceController extends _$LocalePreferenceController {
  @override
  Locale? build() {
    // `.value` (getter nullable de `AsyncValue`), pas `await` (`build`
    // synchrone) : si `sharedPreferencesProvider` n'a pas encore résolu (très
    // bref, stockage local), ce provider retombe momentanément sur `null`
    // (suit la langue du téléphone) puis se reconstruit automatiquement dès
    // que `sharedPreferencesProvider` résout (`ref.watch`) — même mécanisme
    // que `AnalyticsPreferencesController.build`.
    final preferences = ref.watch(sharedPreferencesProvider).value;
    final languageCode = preferences?.getString(_localePrefsKey);
    return languageCode == null ? null : Locale(languageCode);
  }

  /// Force [locale] (`null` -> revient à "suit la langue du téléphone") —
  /// reflété immédiatement dans [state] (avant même l'écriture disque, même
  /// esprit que `AnalyticsPreferencesController.setEnabled`), puis persisté
  /// via `SharedPreferences` (`setString`/`remove` selon que [locale] est
  /// `null` ou pas).
  ///
  /// Si l'écriture disque échoue, [state] est reverté à sa valeur précédente
  /// (sinon ce provider `keepAlive` resterait désynchronisé du disque pour le
  /// reste de la session, l'UI continuant d'afficher la langue "choisie"
  /// comme active alors qu'elle n'a jamais été persistée) puis l'exception
  /// est relancée pour que l'appelant (`profile_language_screen.dart`)
  /// affiche toujours son `SnackBar` d'erreur.
  Future<void> setLocale(Locale? locale) async {
    final previous = state;
    state = locale;
    try {
      final preferences = await ref.read(sharedPreferencesProvider.future);
      if (locale == null) {
        await preferences.remove(_localePrefsKey);
      } else {
        await preferences.setString(_localePrefsKey, locale.languageCode);
      }
    } catch (_) {
      state = previous;
      rethrow;
    }
  }
}
