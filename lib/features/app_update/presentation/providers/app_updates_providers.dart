import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/in_app_update_gateway.dart';
import '../../domain/changelog_parser.dart';

part 'app_updates_providers.g.dart';

/// Chemin de l'asset `CHANGELOG.md` (racine du dépôt, déclaré dans
/// `pubspec.yaml`) : l'écran « Nouveautés » affiche donc les notes de
/// version jusqu'à la version installée.
const String changelogAssetPath = 'CHANGELOG.md';

@Riverpod(keepAlive: true)
InAppUpdateGateway inAppUpdateGateway(Ref ref) =>
    const PlayInAppUpdateGateway();

/// Versions publiées décrites dans le changelog embarqué, de la plus
/// récente à la plus ancienne.
@riverpod
Future<List<ChangelogRelease>> changelogReleases(Ref ref) async {
  final markdown = await rootBundle.loadString(changelogAssetPath);
  return ChangelogParser.parse(markdown);
}
