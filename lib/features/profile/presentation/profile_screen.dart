import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/destructive_button.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/menu_tile.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../core/widgets/settings_list_card.dart';
import '../../../core/widgets/wood_back_header.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import 'providers/package_info_provider.dart';

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
                  ProfileAvatar(avatarUrl: avatarUrl),
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
                  SettingsListCard(
                    children: [
                      MenuTile(
                        standalone: false,
                        icon: Icons.person_outline,
                        label: 'Modifier le profil',
                        onTap: () => context.push('/profile/edit'),
                      ),
                      MenuTile(
                        standalone: false,
                        icon: Icons.notifications_none,
                        label: 'Notifications',
                        onTap: () => context.push('/profile/notifications'),
                      ),
                      MenuTile(
                        standalone: false,
                        icon: Icons.privacy_tip_outlined,
                        label: 'Confidentialité et données',
                        onTap: () => context.push('/profile/privacy'),
                      ),
                      MenuTile(
                        standalone: false,
                        icon: Icons.help_outline,
                        label: 'Aide et support',
                        onTap: () => context.push('/profile/help'),
                      ),
                    ],
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
