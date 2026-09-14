import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/supabase_client_provider.dart';
import '../../../profile/presentation/providers/package_info_provider.dart';
import '../../data/app_version_repository.dart';
import '../../domain/app_version_check_result.dart';
import '../../domain/app_version_comparator.dart';
import '../../domain/app_version_status.dart';

part 'app_version_providers.g.dart';

@Riverpod(keepAlive: true)
AppVersionRepository appVersionRepository(Ref ref) {
  return SupabaseAppVersionRepository(ref.watch(supabaseClientProvider));
}

/// Vérification de version partagée — **seul point de lecture** consommé à
/// la fois par `main.dart::AppBootstrap` (écran bloquant
/// `force_update_screen.dart`) et par `character_list_screen.dart`
/// (bannière `widgets/update_suggested_banner.dart`), voir la documentation
/// de `AppVersionStatus`.
///
/// `keepAlive` : lu depuis 2 endroits distincts sur toute la durée de vie de
/// l'app (démarrage, puis liste de personnages tant que celle-ci reste
/// affichée) — la ligne `app_versions` ne change jamais au cours d'une
/// session (une nouvelle version publiée implique un redémarrage de l'app de
/// toute façon), pas besoin de relancer une requête réseau à chaque
/// navigation entre les deux.
///
/// **Ne bloque jamais l'utilisateur en cas d'échec réseau** (spec de la
/// tâche, cohérent avec `05-ux-navigation.md` sur l'initialisation) : toute
/// exception (pas de connexion, RLS, ligne absente...) est interceptée ici
/// et retombe sur `AppVersionStatus.upToDate` avec la version installée
/// recopiée dans les 3 champs — un statut "neutre" indiscernable d'un
/// "vraiment à jour" pour les deux consommateurs, qui n'affichent jamais
/// rien pour ce statut.
@Riverpod(keepAlive: true)
Future<AppVersionCheckResult> appVersionCheck(Ref ref) async {
  final packageInfo = await ref.watch(packageInfoProvider.future);
  final installedVersion = packageInfo.version;

  try {
    final row = await ref
        .watch(appVersionRepositoryProvider)
        .fetchCurrentPlatformVersion();

    return AppVersionCheckResult(
      status: _resolveStatus(
        installedVersion: installedVersion,
        minimumVersion: row.minimumSupportedVersion,
        latestVersion: row.latestVersion,
      ),
      installedVersion: installedVersion,
      minimumVersion: row.minimumSupportedVersion,
      latestVersion: row.latestVersion,
      storeUrl: row.storeUrl,
    );
  } catch (_) {
    return AppVersionCheckResult(
      status: AppVersionStatus.upToDate,
      installedVersion: installedVersion,
      minimumVersion: installedVersion,
      latestVersion: installedVersion,
    );
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
