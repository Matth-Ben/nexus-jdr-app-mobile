import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/connectivity_providers.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../../profile/presentation/providers/package_info_provider.dart';
import '../../data/app_version_repository.dart';
import '../../domain/app_version_check_result.dart';
import '../../domain/app_version_comparator.dart';
import '../../domain/app_version_status.dart';

part 'app_version_providers.g.dart';

/// Délai maximal de la vérification de version au démarrage : au-delà, on
/// laisse passer comme « à jour » plutôt que de garder le splash affiché.
///
/// Sans cette borne, le premier écran attend la fin de la requête
/// `app_versions`, précédée d'un éventuel refresh du jeton expiré
/// (`SupabaseClient._getAccessToken` -> `GoTrueClient.getSession`) : avec un
/// réseau « connecté mais muet » (DNS en panne, portail captif), chacun est
/// borné seulement par le délai global de 15 s de `TimeoutHttpClient` (D12),
/// soit une trentaine de secondes de splash au démarrage à froid.
const Duration appVersionCheckTimeout = Duration(seconds: 6);

@Riverpod(keepAlive: true)
AppVersionRepository appVersionRepository(Ref ref) {
  return SupabaseAppVersionRepository(ref.watch(supabaseClientProvider));
}

/// Délais des relances automatiques de la vérification de version tant qu'elle
/// n'a pas obtenu de vraie réponse du serveur (une relance par délai, puis
/// plus aucune relance temporelle : seul le retour du réseau en relance
/// ensuite). Surchargeable en test.
@Riverpod(keepAlive: true)
List<Duration> appVersionRetryBackoff(Ref ref) => const [
  Duration(seconds: 10),
  Duration(seconds: 30),
  Duration(seconds: 60),
];

/// Résultat d'une tentative : [fromServer] est vrai seulement si la ligne
/// `app_versions` a réellement été lue (pas un repli).
typedef _Attempt = ({AppVersionCheckResult result, bool fromServer});

/// Vérification de version partagée — **seul point de lecture** consommé à
/// la fois par `main.dart::AppBootstrap` (écran bloquant
/// `force_update_screen.dart`) et par `character_list_screen.dart`
/// (bannière `widgets/update_suggested_banner.dart`), voir la documentation
/// de `AppVersionStatus`.
///
/// `keepAlive` : lu depuis 2 endroits distincts sur toute la durée de vie de
/// l'app (démarrage, puis liste de personnages tant que celle-ci reste
/// affichée).
///
/// **Ne bloque jamais l'utilisateur en cas d'échec réseau** (spec de la
/// tâche, cohérent avec `05-ux-navigation.md` sur l'initialisation) : toute
/// exception (pas de connexion, RLS, ligne absente...) est interceptée ici
/// et retombe sur `AppVersionStatus.upToDate` avec la version installée
/// recopiée dans les 3 champs — un statut "neutre" indiscernable d'un
/// "vraiment à jour" pour les deux consommateurs, qui n'affichent jamais
/// rien pour ce statut. Une requête sans réponse après
/// [appVersionCheckTimeout] est traitée de la même façon : cette vérification
/// ne retarde jamais le premier écran au-delà de ce délai.
///
/// **Relance en arrière-plan** : tant que le dernier résultat est un repli
/// (timeout ou erreur) et non une vraie réponse du serveur, la vérification
/// est relancée (a) après chaque délai de [appVersionRetryBackoff] (une
/// relance à la fois, nombre fini), (b) à chaque
/// `ConnectivityChecker.onConnectivityRestored`. Dès qu'une vraie réponse
/// arrive, l'état est mis à jour (`AppBootstrap` bascule alors sur
/// `ForceUpdateScreen` si « mise à jour obligatoire », la bannière apparaît si
/// « suggérée ») et toute relance s'arrête. Minuteur et abonnement sont
/// annulés à la libération du provider.
@Riverpod(keepAlive: true)
class AppVersionCheck extends _$AppVersionCheck {
  Timer? _timer;
  StreamSubscription<bool>? _restoredSubscription;
  var _retrying = false;
  var _disposed = false;
  var _nextBackoff = 0;
  var _installedVersion = '';
  late AppVersionRepository _repository;

  @override
  Future<AppVersionCheckResult> build() async {
    _disposed = false;
    _nextBackoff = 0;
    ref.onDispose(() {
      _disposed = true;
      _stopRetrying();
    });

    // `watch` : un changement de dépôt (ex. surcharge) relance la vérification.
    _repository = ref.watch(appVersionRepositoryProvider);
    final packageInfo = await ref.watch(packageInfoProvider.future);
    _installedVersion = packageInfo.version;

    final attempt = await _attempt();
    if (!attempt.fromServer) _startRetrying();
    return attempt.result;
  }

  Future<_Attempt> _attempt() async {
    try {
      final row = await _repository.fetchCurrentPlatformVersion().timeout(
        appVersionCheckTimeout,
      );
      return (
        result: AppVersionCheckResult(
          status: _resolveStatus(
            installedVersion: _installedVersion,
            minimumVersion: row.minimumSupportedVersion,
            latestVersion: row.latestVersion,
          ),
          installedVersion: _installedVersion,
          minimumVersion: row.minimumSupportedVersion,
          latestVersion: row.latestVersion,
          storeUrl: row.storeUrl,
        ),
        fromServer: true,
      );
    } catch (_) {
      return (
        result: AppVersionCheckResult(
          status: AppVersionStatus.upToDate,
          installedVersion: _installedVersion,
          minimumVersion: _installedVersion,
          latestVersion: _installedVersion,
        ),
        fromServer: false,
      );
    }
  }

  void _startRetrying() {
    try {
      _restoredSubscription ??= ref
          .read(connectivityCheckerProvider)
          .onConnectivityRestored
          .listen((_) => unawaited(_retry()), onError: (Object _) {});
    } catch (_) {
      // Surveillance du réseau indisponible : seuls les délais relancent.
    }
    _scheduleNext();
  }

  void _scheduleNext() {
    _timer?.cancel();
    final backoff = ref.read(appVersionRetryBackoffProvider);
    if (_nextBackoff >= backoff.length) return;
    _timer = Timer(backoff[_nextBackoff++], () => unawaited(_retry()));
  }

  void _stopRetrying() {
    _timer?.cancel();
    _timer = null;
    unawaited(_restoredSubscription?.cancel());
    _restoredSubscription = null;
  }

  Future<void> _retry() async {
    if (_disposed || _retrying) return;
    _retrying = true;
    try {
      final attempt = await _attempt();
      if (_disposed) return;
      if (attempt.fromServer) {
        state = AsyncData(attempt.result);
        _stopRetrying();
      } else {
        _scheduleNext();
      }
    } finally {
      _retrying = false;
    }
  }
}

/// `updateRequired` > `updateSuggested` > `upToDate` — voir la doc de
/// [AppVersionStatus] pour les seuils exacts (`min_supported_version`/
/// `latest_version`).
AppVersionStatus _resolveStatus({
  required String installedVersion,
  required String minimumVersion,
  required String latestVersion,
}) {
  if (AppVersionComparator.isLowerThan(installedVersion, minimumVersion)) {
    return AppVersionStatus.updateRequired;
  }
  if (AppVersionComparator.isLowerThan(installedVersion, latestVersion)) {
    return AppVersionStatus.updateSuggested;
  }
  return AppVersionStatus.upToDate;
}
