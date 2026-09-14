import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/app_store_urls.dart';

/// Ouvre la fiche store (Play Store/App Store, voir
/// `domain/app_store_urls.dart::AppStoreUrls.current`) — action partagée par
/// le bouton "METTRE À JOUR" de `force_update_screen.dart` et le lien
/// "Mettre à jour" de `widgets/update_suggested_banner.dart`.
///
/// Même discipline défensive que
/// `profile_help_screen.dart::_contactSupport` : `canLaunchUrl` vérifié
/// *avant* `launchUrl` (jamais une ouverture à l'aveugle), le tout enveloppé
/// dans un `try`/`catch` pour toute exception plateforme inattendue — jamais
/// de crash silencieux, jamais le détail technique de l'exception affiché à
/// l'utilisateur.
Future<void> openAppStorePage(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final uri = AppStoreUrls.current();

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
