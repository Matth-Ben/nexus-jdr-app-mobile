import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/menu_tile.dart';
import '../../../core/widgets/settings_list_card.dart';
import '../../../core/widgets/wood_back_header.dart';
import 'providers/package_info_provider.dart';
import 'widgets/report_bug_sheet.dart';

/// Sous-écran "Aide et support", route `/profile/help` — poussé depuis la
/// tuile éponyme de `profile_screen.dart` (qui affichait auparavant
/// `_showComingSoon`, voir la doc de classe de `ProfileScreen`).
///
/// Même gabarit exact que `ProfilePrivacyScreen` (`WoodBackHeader` + corps
/// parchemin scrollable, en-têtes de section `font.body` 13px/800
/// `textSecondary` en `Text` inline plutôt qu'un composant dédié — même choix
/// que `ProfilePrivacyScreen`, jamais `font.display`, réservé aux libellés
/// capitalisés par le style lui-même) : 3 sections regroupées en
/// `SettingsListCard` — recettage direction-artistique du 13/09/2026.
///
/// - "QUESTIONS FRÉQUENTES" : 3 vraies questions + "Voir toutes les
///   questions" — remplace l'ancienne tuile générique unique "FAQ / Centre
///   d'aide". Les 3 questions poussent `ProfileFaqScreen`
///   (`/profile/help/faq?question=N`) en pré-ouvrant leur question
///   respective (1/2/3 dans `ProfileFaqScreen._faqItems`) ; "Voir toutes les
///   questions" pousse le même écran sans pré-ouverture
///   (`/profile/help/faq`) — les 4 tuiles gardent le chevron par défaut
///   (poussent un écran interne, pas une action qui sort de l'app/ouvre une
///   sheet système, seul cas où `MenuTile.trailingIcon: Icons.north_east`
///   est réservé — voir sa doc de classe).
/// - "NOUS CONTACTER" : "Contacter le support" (déjà existant sur cet écran)
///   + "Signaler un bug", **déplacée ici depuis le hub `ProfileScreen`**
///   (retirée de là au recettage du 13/09/2026, voir la doc de classe de
///   `ProfileScreen` — même action [showReportBugSheet], câblée à
///   l'identique).
/// - "À PROPOS" : "Mentions légales / CGU" (pousse `ProfileLegalScreen`,
///   `/profile/help/legal`) + "Crédits & licences" (pousse
///   `ProfileCreditsScreen`, `/profile/help/credits`).
///
/// "Contacter le support" (ouvre le client e-mail natif via `url_launcher`,
/// voir [buildSupportEmailUri]) et "Signaler un bug" (ouvre
/// [showReportBugSheet]) restent les 2 seules actions de cet écran à ne pas
/// pousser une route `go_router` — toutes les autres tuiles de cet écran
/// poussent désormais un écran réel, plus aucune tuile n'affiche
/// `_showComingSoon` (retiré de ce fichier).
///
/// Pied de page version identique à `ProfileScreen._FooterVersion`
/// ([_FooterVersion] ci-dessous, dupliqué plutôt qu'extrait en composant
/// partagé — 2e usage seulement, même convention "dupliquer jusqu'à 2 usages,
/// extraire au 3e" déjà documentée sur `MenuTile`/`SettingsListCard`) :
/// réutilise le même `packageInfoProvider` partagé (`keepAlive`), jamais une
/// 2e lecture indépendante de la version.
///
/// Lecture 100% synchrone à l'ouverture pour tout le reste (aucune autre
/// donnée à charger) : ni état de chargement ni appel réseau ici en dehors du
/// pied de page, même remarque que `ProfileScreen`/`ProfilePrivacyScreen`.
/// `PackageInfo.fromPlatform()` n'est lu qu'au tap sur "Contacter le
/// support", pas à l'ouverture de l'écran (contrairement au pied de page, qui
/// le lit via `packageInfoProvider` dès la construction) — pas besoin d'un
/// 2e provider dédié pour cet unique appel ponctuel.
class ProfileHelpScreen extends ConsumerWidget {
  const ProfileHelpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader('QUESTIONS FRÉQUENTES'),
                  const SizedBox(height: AppSpacing.sm),
                  SettingsListCard(
                    children: [
                      MenuTile(
                        standalone: false,
                        icon: Icons.file_upload_outlined,
                        label:
                            'Comment importer un personnage '
                            'aidedd.org ?',
                        onTap: () =>
                            context.push('/profile/help/faq?question=1'),
                      ),
                      MenuTile(
                        standalone: false,
                        icon: Icons.group_add_outlined,
                        label: 'Comment rejoindre l\'histoire de mon MJ ?',
                        onTap: () =>
                            context.push('/profile/help/faq?question=2'),
                      ),
                      MenuTile(
                        standalone: false,
                        icon: Icons.cloud_off_outlined,
                        label:
                            'Mes personnages sont-ils sauvegardés hors '
                            'ligne ?',
                        onTap: () =>
                            context.push('/profile/help/faq?question=3'),
                      ),
                      MenuTile(
                        standalone: false,
                        icon: Icons.menu_book_outlined,
                        label: 'Voir toutes les questions',
                        onTap: () => context.push('/profile/help/faq'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _SectionHeader('NOUS CONTACTER'),
                  const SizedBox(height: AppSpacing.sm),
                  SettingsListCard(
                    children: [
                      MenuTile(
                        standalone: false,
                        icon: Icons.email_outlined,
                        label: 'Contacter le support',
                        onTap: () => _contactSupport(context),
                      ),
                      MenuTile(
                        standalone: false,
                        icon: Icons.bug_report_outlined,
                        label: 'Signaler un bug',
                        onTap: () => showReportBugSheet(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Réponse sous 48h en semaine. Un aperçu des infos '
                    "techniques de l'appareil est joint automatiquement.",
                    style: AppTypography.body(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _SectionHeader('À PROPOS'),
                  const SizedBox(height: AppSpacing.sm),
                  SettingsListCard(
                    children: [
                      MenuTile(
                        standalone: false,
                        icon: Icons.gavel_outlined,
                        label: 'Mentions légales / CGU',
                        onTap: () => context.push('/profile/help/legal'),
                      ),
                      MenuTile(
                        standalone: false,
                        icon: Icons.copyright_outlined,
                        label: 'Crédits & licences',
                        onTap: () => context.push('/profile/help/credits'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Contenu D&D 5e sous licence Open5e / SRD. Voir les '
                    'crédits complets pour le détail des sources.',
                    style: AppTypography.body(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _FooterVersion(),
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

  /// Tap sur "Contacter le support" — avec [showReportBugSheet] pour
  /// "Signaler un bug", l'une des 2 seules tuiles de cet écran à ne pas
  /// pousser une route `go_router` (voir la doc de classe).
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

/// Titre de section ("QUESTIONS FRÉQUENTES"/"NOUS CONTACTER"/"À PROPOS"),
/// recréé localement plutôt qu'un composant partagé — même précédent que
/// `profile_notifications_screen.dart::_SectionHeader`/
/// `character_creation/presentation/equipment_step_screen.dart::_SectionHeader`
/// (voir leur doc de classe pour le rationale de la duplication).
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.body(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: AppColors.textSecondary,
      ),
    );
  }
}

/// Pied de page "Nexus JDR — Personnages · vX.Y.Z" — dupliqué à l'identique
/// depuis `ProfileScreen._FooterVersion` (voir la doc de classe de
/// [ProfileHelpScreen] pour le rationale de la duplication plutôt qu'une
/// extraction) : même `packageInfoProvider` partagé, même repli "sans le
/// numéro de version" pendant la résolution (jamais un état de chargement
/// dédié pour un pied de page discret).
class _FooterVersion extends ConsumerWidget {
  const _FooterVersion();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(packageInfoProvider).value?.version;
    final label = version == null
        ? 'Nexus JDR — Personnages'
        : 'Nexus JDR — Personnages · v$version';

    return Text(
      label,
      textAlign: TextAlign.center,
      style: AppTypography.body(fontSize: 11, color: AppColors.textMuted),
    );
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
