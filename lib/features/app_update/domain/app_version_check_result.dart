import 'package:freezed_annotation/freezed_annotation.dart';

import 'app_version_status.dart';

part 'app_version_check_result.freezed.dart';

/// Résultat structuré de `appVersionCheckProvider`
/// (`presentation/providers/app_version_providers.dart`) : le [status]
/// résolu (voir `app_version_status.dart`) accompagné des 3 chaînes de
/// version nécessaires à l'affichage (`ForceUpdateScreen` : "Version
/// installée : X · minimum requis : Y" ; `UpdateSuggestedBanner` : version
/// de dismissal par [latestVersion], voir
/// `presentation/providers/update_banner_dismissal_provider.dart`).
@freezed
abstract class AppVersionCheckResult with _$AppVersionCheckResult {
  const factory AppVersionCheckResult({
    required AppVersionStatus status,
    required String installedVersion,
    required String minimumVersion,
    required String latestVersion,
    String? storeUrl,
  }) = _AppVersionCheckResult;
}
