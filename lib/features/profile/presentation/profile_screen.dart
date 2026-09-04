import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/destructive_button.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/menu_tile.dart';
import '../../../core/widgets/wood_back_header.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import 'providers/package_info_provider.dart';
import 'widgets/report_bug_sheet.dart';

/// Écran "Profil / paramètres du compte", route `/profile` — dernier écran
/// de la navigation principale (bouton profil rond de
/// `character_list_screen.dart::_ProfileButton`, qui poussait jusqu'ici un
/// bottom sheet minimal réduit à "Se déconnecter").
///
/// **Choix d'organisation** : `features/profile/` plutôt que rattaché à
/// `features/characters/` — le profil n'est pas une donnée de personnage
/// (`characters`/`character_campaigns`...), c'est une propriété du compte
/// utilisateur (`auth.users.user_metadata`), au même titre que
/// `features/auth/`. Ce module n'a pas besoin de couche `data/`/`domain/`
/// propre : il ne fait que consommer `AuthRepository`
/// (`features/auth/data/auth_repository.dart`), déjà l'abstraction
/// responsable de toute écriture sur le compte.
///
/// Niveau "Parchemin" (`docs/cahier-des-charges/10-design-system.md` section
/// 6) : un bandeau bois d'ambiance (`WoodBackHeader` + un second bloc bois
/// dédié à l'identité) au-dessus d'un corps parchemin scrollable — même
/// niveau que la fiche personnage. `WoodBackHeader` n'est volontairement pas
/// étendu d'un slot dédié à ce second bloc (spec direction-artistique de la
/// tâche) : il garde son contrat étroit, réutilisé tel quel sur 3+ écrans.
///
/// Lecture nom/e-mail synchrone (`currentUserProvider`, déjà en mémoire) : ni
/// état de chargement ni appel réseau à l'ouverture de cet écran.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final rawDisplayName = (user?.userMetadata?['full_name'] as String?)
        ?.trim();
    final displayName = (rawDisplayName == null || rawDisplayName.isEmpty)
        ? 'Aventurier'
        : rawDisplayName;
    final email = user?.email ?? '';
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;

    return Scaffold(
      backgroundColor: AppColors.parchmentBg,
      body: Column(
        children: [
          WoodBackHeader(title: 'PROFIL', onBack: () => _goBack(context)),
          ColoredBox(
            color: AppColors.woodMedium,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Column(
                children: [
                  _ProfileAvatar(avatarUrl: avatarUrl),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    displayName,
                    style: AppTypography.body(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: AppColors.textOnWood,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    email,
                    style: AppTypography.body(
                      fontSize: 13,
                      color: AppColors.textOnWoodMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  const InfoBanner(
                    icon: Icons.smartphone_outlined,
                    message: "Compte lié à l'app Histoires",
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  MenuTile(
                    icon: Icons.person_outline,
                    label: 'Modifier le profil',
                    onTap: () => context.push('/profile/edit'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  MenuTile(
                    icon: Icons.notifications_none,
                    label: 'Notifications',
                    onTap: () => _showComingSoon(context),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  MenuTile(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Confidentialité et données',
                    onTap: () => context.push('/profile/privacy'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  MenuTile(
                    icon: Icons.help_outline,
                    label: 'Aide et support',
                    onTap: () => context.push('/profile/help'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  MenuTile(
                    icon: Icons.bug_report_outlined,
                    label: 'Signaler un bug',
                    onTap: () => showReportBugSheet(context),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  DestructiveButton(
                    label: 'Se déconnecter',
                    onPressed: () => ref.read(authRepositoryProvider).signOut(),
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

  /// Même garde que `character_detail_screen.dart::_goBack` : cet écran est
  /// normalement toujours atteint via `context.push('/profile')` (donc
  /// `canPop()` vrai), mais reste défensif si jamais poussé un jour comme
  /// route initiale (deep link).
  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  /// Tap sur "Notifications" — seul écran encore inexistant de cette liste
  /// (spec direction-artistique de la tâche) : même texte exact que
  /// `appearance_and_backstory_step_screen.dart::_showPortraitComingSoon`,
  /// réutilisé mot pour mot plutôt qu'une nouvelle constante.
  /// "Confidentialité et données" (incrément B, `ProfilePrivacyScreen`) puis
  /// "Aide et support" (incrément C, `ProfileHelpScreen`) ne passent plus par
  /// cette méthode — leurs propres tuiles "Politique de confidentialité"/
  /// "FAQ / Centre d'aide"/"Mentions légales / CGU" réutilisent en revanche
  /// ce même texte, indépendamment de cette méthode.
  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Bientôt disponible')));
  }
}

/// "Avatar de profil" du design système (section 4) : cercle 76×76px,
/// bordure 3px `gold-end` + halo 1px `wood.dark` (même technique de halo que
/// `PortraitFrame` : `boxShadow` non flouté, `spreadRadius` égal à
/// `AppBorders.cardEmphasisHalo`) — conservés dans tous les cas, avec ou
/// sans photo (spec direction-artistique du flux "Modifier le profil").
/// Sans [avatarUrl] : fond `wood.light` + silhouette `Icons.person`
/// (comportement historique, inchangé). Avec [avatarUrl] : `ClipOval` +
/// `Image.network` (`BoxFit.cover`) remplit le cercle — jamais le
/// traitement "cadre bois sculpté" du portrait de personnage (bordure
/// `wood.light`, coins `radius.md`), qui reste distinct.
///
/// Non interactif ici (pas d'`InkWell`) : le flux d'upload/retrait se fait
/// depuis `ProfileEditScreen`, pas directement sur cet écran.
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;
    return Container(
      width: 76,
      height: 76,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.woodLight,
        shape: BoxShape.circle,
        border: Border.fromBorderSide(
          BorderSide(color: AppColors.goldEnd, width: AppBorders.cardEmphasis),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.woodDark,
            blurRadius: 0,
            spreadRadius: AppBorders.cardEmphasisHalo,
          ),
        ],
      ),
      child: url == null || url.isEmpty
          ? const Icon(Icons.person, size: 40, color: AppColors.textOnWood)
          : ClipOval(
              child: Image.network(
                url,
                width: 76,
                height: 76,
                fit: BoxFit.cover,
                // Même repli que `PortraitFrame` : ne jamais laisser un
                // espace vide/une icône d'erreur brute si le chargement
                // réseau échoue (avatar pas encore retéléchargé, URL
                // périmée...), retombe silencieusement sur la silhouette par
                // défaut.
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.person,
                  size: 40,
                  color: AppColors.textOnWood,
                ),
              ),
            ),
    );
  }
}

/// Pied de page "Nexus JDR — Personnages · vX.Y.Z" — version lue
/// dynamiquement (`packageInfoProvider`), jamais codée en dur. Pendant que
/// [packageInfoProvider] résout (ou en cas d'échec, jamais rencontré en
/// pratique une fois l'app démarrée), affiche le libellé sans le numéro de
/// version plutôt qu'un état de chargement dédié : un pied de page discret
/// n'a pas besoin d'un spinner, voir la doc de classe de [ProfileScreen]
/// ("pas d'état chargement/erreur pleine page").
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
