/// Statut de version installée vis-à-vis de `app_versions`
/// (`min_supported_version`/`latest_version`, voir
/// `data/app_version_repository.dart`) — résolu par
/// `presentation/providers/app_version_providers.dart::appVersionCheckProvider`,
/// seul point de lecture partagé par `ForceUpdateScreen`
/// (`presentation/force_update_screen.dart`, écran bloquant) et
/// `UpdateSuggestedBanner`
/// (`presentation/widgets/update_suggested_banner.dart`, bannière non
/// bloquante).
enum AppVersionStatus {
  /// Version installée >= `latest_version` : rien à afficher.
  upToDate,

  /// Version installée < `latest_version` mais >= `min_supported_version` :
  /// bannière non bloquante (`UpdateSuggestedBanner`).
  updateSuggested,

  /// Version installée < `min_supported_version` : écran bloquant
  /// (`ForceUpdateScreen`), aucune navigation possible tant que l'app n'est
  /// pas mise à jour.
  updateRequired,
}
