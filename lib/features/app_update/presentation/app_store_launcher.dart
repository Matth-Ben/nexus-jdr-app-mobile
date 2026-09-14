import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/app_store_urls.dart';

/// Ouvre la fiche store — priorité à [storeUrl] (`app_versions.store_url`,
/// voir `data/app_version_repository.dart`) quand la table en fournit un,
/// sinon repli sur l'URL construite côté client
/// (`domain/app_store_urls.dart::AppStoreUrls.current`, approximation tant
/// que l'app n'est pas publiée) — action partagée par le bouton "METTRE À
/// JOUR" de `force_update_screen.dart` et le lien "Mettre à jour" de
/// `widgets/update_suggested_banner.dart`.
///
/// Même discipline défensive que
/// `profile_help_screen.dart::_contactSupport` : `canLaunchUrl` vérifié
/// *avant* `launchUrl` (jamais une ouverture à l'aveugle), le tout enveloppé
/// dans un `try`/`catch` pour toute exception plateforme inattendue — jamais
/// de crash silencieux, jamais le détail technique de l'exception affiché à
/// l'utilisateur. [storeUrl] invalide/vide retombe silencieusement sur le
/// même repli qu'un `storeUrl` absent, plutôt que d'échouer sur une valeur
/// mal formée en base.
Future<void> openAppStorePage(BuildContext context, {String? storeUrl}) async {
  final messenger = ScaffoldMessenger.of(context);
  final uri =
      (storeUrl != null && storeUrl.isNotEmpty
          ? Uri.tryParse(storeUrl)
          : null) ??
      AppStoreUrls.current();

  try {
    if (!await canLaunchUrl(uri)) {
      messenger.showSnackBar(
        const SnackBar(content: Text(_cannotOpenStoreMessage)),
      );
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text(_cannotOpenStoreMessage)),
    );
  }
}

const String _cannotOpenStoreMessage =
    "Impossible d'ouvrir la fiche de l'application. Réessayez.";
