import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Ligne `app_versions` de la plateforme courante — table de référence
/// partagée avec l'app web "Histoires" (lecture authentifiée seule côté
/// client, écriture réservée aux admins, voir le cahier des charges) :
/// `platform` (`'android'`/`'ios'`, clé primaire), `minimum_supported_version`,
/// `latest_version` (toutes deux au format `major.minor.patch`, voir
/// `domain/app_version_comparator.dart`).
class AppVersionRow {
  const AppVersionRow({
    required this.minimumSupportedVersion,
    required this.latestVersion,
  });

  final String minimumSupportedVersion;
  final String latestVersion;
}

/// Passerelle vers `app_versions` — abstraction (plutôt qu'une classe
/// concrète directement injectée) pour permettre aux tests de fournir un
/// double sans jamais toucher à `Supabase.instance.client`, même principe que
/// `CharacterRepository`/`GroupRepository`.
abstract class AppVersionRepository {
  /// Ligne `app_versions` de la plateforme courante (`Platform.isAndroid`/
  /// `isIOS`, même discipline que
  /// `bug_report_repository.dart::_platformLabel` — jamais codé en dur).
  /// Lève toute exception rencontrée (réseau, RLS...) telle quelle : c'est
  /// `appVersionCheckProvider`
  /// (`presentation/providers/app_version_providers.dart`) qui décide de ne
  /// jamais bloquer l'utilisateur en cas d'échec, pas cette couche.
  Future<AppVersionRow> fetchCurrentPlatformVersion();
}

class SupabaseAppVersionRepository implements AppVersionRepository {
  SupabaseAppVersionRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<AppVersionRow> fetchCurrentPlatformVersion() async {
    final row = await _client
        .from('app_versions')
        .select('minimum_supported_version, latest_version')
        .eq('platform', _platformLabel())
        .maybeSingle();

    if (row == null) {
      throw StateError(
        'Aucune ligne app_versions pour la plateforme ${_platformLabel()}.',
      );
    }

    return AppVersionRow(
      minimumSupportedVersion: row['minimum_supported_version'] as String,
      latestVersion: row['latest_version'] as String,
    );
  }

  /// `'android'`/`'ios'` — même discipline que
  /// `bug_report_repository.dart::_platformLabel`, dupliquée ici plutôt que
  /// partagée (même précédent que `RaceRowMapper`/`GroupRepository`
  /// `_fetchTranslatedNames` : ce dépôt duplique systématiquement ce genre de
  /// petit utilitaire plutôt que de créer une dépendance transverse pour 2
  /// appelants). Repli `Platform.operatingSystem` volontairement absent ici
  /// (contrairement à `bug_report_repository.dart`) : `app_versions` n'a que
  /// 2 lignes (`android`/`ios`), aucune autre plateforme cible pour ce dépôt
  /// (voir `01-architecture-technique.md`) — une valeur de repli
  /// n'aboutirait qu'à une ligne introuvable de toute façon.
  String _platformLabel() => Platform.isIOS ? 'ios' : 'android';
}
