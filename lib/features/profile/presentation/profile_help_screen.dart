import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/menu_tile.dart';
import '../../../core/widgets/wood_back_header.dart';

/// Sous-écran "Aide et support", route `/profile/help` — poussé depuis la
/// tuile éponyme de `profile_screen.dart` (qui affichait auparavant
/// `_showComingSoon`, voir la doc de classe de `ProfileScreen`).
///
/// Même gabarit exact que `ProfilePrivacyScreen` (`WoodBackHeader` + corps
/// parchemin scrollable) : 3 tuiles de menu ("FAQ / Centre d'aide",
/// "Contacter le support", "Mentions légales / CGU"), sans bandeau
/// `InfoBanner` ni bouton destructif — spec direction-artistique de la tâche
/// "Aide et support" (incrément C du chantier "Profil/Paramètres").
///
/// **"Signaler un bug" et "Version de l'app" sont volontairement absents**
/// de cet écran : le premier est déjà une tuile séparée de `ProfileScreen`
/// (`showReportBugSheet`), le second déjà affiché en pied de page de
/// `ProfileScreen` (`_FooterVersion`) — décision déjà actée par le chef de
/// projet, pas une omission.
///
/// Seule "Contacter le support" est réellement fonctionnelle : ouvre le
/// client e-mail natif (`url_launcher`) sur une adresse/sujet/corps
/// pré-remplis (voir [buildSupportEmailUri]). "FAQ / Centre d'aide" et
/// "Mentions légales / CGU" affichent le même `SnackBar` "Bientôt
/// disponible" que `ProfileScreen._showComingSoon`/
/// `ProfilePrivacyScreen._showComingSoon`, réutilisé mot pour mot.
///
/// Lecture 100% synchrone à l'ouverture (aucune donnée à charger) : ni état
/// de chargement ni appel réseau ici, même remarque que `ProfileScreen`/
/// `ProfilePrivacyScreen`. `PackageInfo.fromPlatform()` n'est lu qu'au tap
/// sur "Contacter le support", pas à l'ouverture de l'écran — pas besoin
/// d'un provider Riverpod dédié (contrairement à
/// `providers/package_info_provider.dart`, qui alimente le pied de page
/// affiché en permanence de `ProfileScreen`) pour un unique appel ponctuel.
class ProfileHelpScreen extends StatelessWidget {
  const ProfileHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.parchmentBg,
      body: Column(
        children: [
          WoodBackHeader(
            title: 'AIDE ET SUPPORT',
            onBack: () => _goBack(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  MenuTile(
                    icon: Icons.menu_book_outlined,
                    label: 'FAQ / Centre d\'aide',
                    onTap: () => _showComingSoon(context),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  MenuTile(
                    icon: Icons.email_outlined,
                    label: 'Contacter le support',
                    onTap: () => _contactSupport(context),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  MenuTile(
                    icon: Icons.gavel_outlined,
                    label: 'Mentions légales / CGU',
                    onTap: () => _showComingSoon(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Même garde que `ProfileScreen._goBack`/`ProfilePrivacyScreen._goBack` :
  /// cet écran est normalement toujours atteint via
  /// `context.push('/profile/help')` (donc `canPop()` vrai), mais reste
  /// défensif si jamais poussé un jour comme route initiale (deep link).
  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  /// Tap sur "FAQ / Centre d'aide"/"Mentions légales / CGU", pas encore
  /// implémentées (spec direction-artistique de la tâche) — même texte exact
  /// que `ProfileScreen._showComingSoon`/
  /// `ProfilePrivacyScreen._showComingSoon`, réutilisé mot pour mot plutôt
  /// qu'une nouvelle constante.
  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Bientôt disponible')));
  }

  /// Tap sur "Contacter le support" — seule action réellement fonctionnelle
  /// de cet écran (spec direction-artistique de la tâche).
  ///
  /// `canLaunchUrl` est vérifié *avant* `launchUrl` (jamais une ouverture à
  /// l'aveugle) : `false` affiche un premier `SnackBar` dédié (aucune
  /// application e-mail configurée), tandis que le bloc `canLaunchUrl`
  /// + `launchUrl` est enveloppé dans un `try`/`catch` défensif pour toute
  /// exception plateforme inattendue — même discipline que le message
  /// générique déjà utilisé par `widgets/report_bug_sheet.dart`
  /// ([_genericMailErrorMessage] : jamais le détail technique de
  /// l'exception affiché à l'utilisateur, jamais de crash silencieux).
  Future<void> _contactSupport(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final packageInfo = await PackageInfo.fromPlatform();
    final uri = buildSupportEmailUri(packageInfo);

    try {
      if (!await canLaunchUrl(uri)) {
        messenger.showSnackBar(
          const SnackBar(content: Text(_noMailAppMessage)),
        );
        return;
      }
      await launchUrl(uri);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text(_genericMailErrorMessage)),
      );
    }
  }
}

/// Aucune application e-mail configurée sur l'appareil (`canLaunchUrl` a
/// répondu `false`) — distinct de [_genericMailErrorMessage], qui couvre
/// plutôt une exception plateforme inattendue.
const String _noMailAppMessage =
    "Aucune application e-mail n'est configurée sur cet appareil.";

/// Erreur générique/inattendue (exception plateforme pendant
/// `canLaunchUrl`/`launchUrl`) — même discipline que
/// `widgets/report_bug_sheet.dart::_genericErrorMessage` : jamais le détail
/// technique de l'exception affiché à l'utilisateur.
const String _genericMailErrorMessage =
    "Impossible d'ouvrir l'application e-mail. Réessayez.";

/// Adresse destinataire de "Contacter le support" — confirmée par le chef de
/// projet, jamais codée en dur ailleurs que dans ce fichier (voir
/// [buildSupportEmailUri]).
const String supportEmailAddress = 'support@nexus-jdr.app';

/// Sujet de "Contacter le support" — fixe, jamais généré dynamiquement.
const String supportEmailSubject = 'Support Nexus JDR — Personnages';

/// Construit l'URI `mailto:` de "Contacter le support" — isolée de l'appel
/// `launchUrl` lui-même (fonction pure, testable indépendamment de tout
/// canal de plateforme) pour permettre un test unitaire dédié
/// (`test/features/profile/presentation/profile_help_screen_test.dart`) qui
/// n'a pas besoin de simuler l'ouverture réelle d'un client e-mail.
///
/// Query string construite à la main via `Uri.encodeComponent` plutôt que
/// `Uri(scheme: 'mailto', queryParameters: {...})` : ce dernier encode les
/// espaces en `+` (convention `application/x-www-form-urlencoded`), que le
/// schéma `mailto:` (RFC 6068) ne traite pas comme équivalent de l'espace —
/// de nombreux clients mail (Gmail Android, Apple Mail) afficheraient alors
/// un `+` littéral à la place de chaque espace du sujet/corps.
/// `Uri.encodeComponent` encode bien l'espace en `%20` et gère correctement
/// accents/sauts de ligne, sans ce piège.
Uri buildSupportEmailUri(PackageInfo packageInfo) {
  final subject = Uri.encodeComponent(supportEmailSubject);
  final body = Uri.encodeComponent(_buildSupportEmailBody(packageInfo));
  return Uri.parse('mailto:$supportEmailAddress?subject=$subject&body=$body');
}

/// Corps du message de "Contacter le support" — infos techniques injectées
/// silencieusement (version + build + plateforme), jamais à saisir par le
/// joueur.
String _buildSupportEmailBody(PackageInfo packageInfo) {
  return 'Bonjour,\n'
      '\n'
      '(Décris ici ta question ou ton problème)\n'
      '\n'
      '\n'
      '---\n'
      'Infos techniques (ne pas modifier) :\n'
      'Application : Nexus JDR — Personnages\n'
      'Version : v${packageInfo.version} (build ${packageInfo.buildNumber})\n'
      'Plateforme : $_platformLabel ${Platform.operatingSystemVersion}';
}

/// Libellé de plateforme lisible ("Android"/"iOS") — même logique exacte que
/// `features/bug_report/data/bug_report_repository.dart::_platformLabel`
/// (`Platform.isAndroid`/`isIOS`, repli `Platform.operatingSystem`), non
/// réutilisée telle quelle car cette dernière est privée à son fichier et
/// retourne des valeurs techniques minuscules (`'android'`/`'ios'`, contrat
/// de l'edge function `report-bug`) plutôt que ce libellé humain capitalisé.
String get _platformLabel {
  if (Platform.isAndroid) return 'Android';
  if (Platform.isIOS) return 'iOS';
  return Platform.operatingSystem;
}
