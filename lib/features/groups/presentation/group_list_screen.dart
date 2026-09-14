import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/dashed_border_painter.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/scene_scaffold.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../domain/group_color_assigner.dart';
import '../domain/group_failure.dart';
import '../domain/group_summary.dart';
import 'providers/group_providers.dart';
import 'widgets/member_color_chips_row.dart';

/// Écran "Groupes", route `/groups` — point d'entrée UNIQUE du bouton
/// "groupes" de `character_list_screen.dart` (`_GroupsButton`), quel que
/// soit le nombre de groupes dont le joueur est déjà membre : liste les
/// groupes rejoints (nom + nombre de membres, tap -> `/groups/:id`) et
/// propose TOUJOURS "Créer un groupe"/"Rejoindre un groupe" en pied
/// d'écran — remplace l'ancien comportement (`showGroupEntrySheet`/
/// `showGroupListSheet`) qui, dès qu'un joueur avait exactement 1 groupe,
/// naviguait directement dedans sans jamais lui laisser la possibilité
/// d'en créer ou d'en rejoindre un second.
class GroupListScreen extends ConsumerWidget {
  const GroupListScreen({super.key});

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(myGroupsProvider);
    final currentUserId = ref.watch(currentUserProvider)?.id;

    return SceneScaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: _Header(onBack: () => _goBack(context)),
            ),
            Expanded(
              child: groupsAsync.when(
                data: (groups) =>
                    _GroupList(groups: groups, currentUserId: currentUserId),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.goldEnd),
                ),
                error: (error, stackTrace) => _ErrorState(
                  message: error is GroupFailure
                      ? error.message
                      : 'Impossible de charger vos groupes. Réessayez.',
                  onRetry: () => ref.invalidate(myGroupsProvider),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'Créer un groupe',
                      onPressed: () => context.push('/groups/new'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: SecondaryButton(
                      label: 'Rejoindre un groupe',
                      onPressed: () => context.push('/groups/join'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// En-tête sans bandeau bois contrastant, posé directement sur le fond
/// "scène" — même patron que `_Header` de `character_list_screen.dart`,
/// mais avec un bouton retour (cet écran est toujours poussé par-dessus la
/// liste des personnages, contrairement à celle-ci).
class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textOnWood,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          'GROUPES',
          style: AppTypography.display(
            fontSize: 15,
            color: AppColors.textOnWood,
          ),
        ),
      ],
    );
  }
}

class _GroupList extends StatelessWidget {
  const _GroupList({required this.groups, required this.currentUserId});

  final List<GroupSummary> groups;

  /// `null` si aucun utilisateur connecté (ne devrait pas arriver sur cet
  /// écran, protégé par l'auth guard du routeur) — dans ce cas, aucun groupe
  /// n'affiche le badge "TOI".
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return const _EmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: groups.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final group = groups[index];
        return _GroupRow(
          group: group,
          isFoundedByCurrentUser:
              currentUserId != null && group.founderId == currentUserId,
          onTap: () => context.push('/groups/${group.id}'),
        );
      },
    );
  }
}

/// Identifiants factices pour [MemberColorChipsRow] : `GroupSummary` (le
/// résumé léger utilisé par cet écran, voir sa doc de classe) ne porte que
/// [GroupSummary.memberCount], jamais la liste réelle des membres — obtenir
/// leurs vrais identifiants demanderait d'étendre `fetchMyGroups` pour
/// joindre `group_members`, hors périmètre du recettage direction-
/// artistique du 13/09 (purement une prévisualisation décorative, voir
/// `GroupColorAssigner`). En attendant, `'${group.id}-member-$i'` fournit
/// des identifiants stables (donc des couleurs stables) et du bon nombre —
/// juste jamais liés aux vrais membres. À remplacer par de vrais
/// identifiants si `fetchMyGroups` est un jour étendu pour les exposer.
List<String> _placeholderMemberIds(GroupSummary group) => [
  for (var i = 0; i < group.memberCount; i++) '${group.id}-member-$i',
];

class _GroupRow extends StatelessWidget {
  const _GroupRow({
    required this.group,
    required this.isFoundedByCurrentUser,
    required this.onTap,
  });

  final GroupSummary group;
  final bool isFoundedByCurrentUser;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.parchmentCard,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.woodLight,
              width: AppBorders.card,
            ),
          ),
          child: Row(
            children: [
              _GroupAvatar(groupId: group.id),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            group.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.body(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (isFoundedByCurrentUser) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const _FounderBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${group.memberCount} membres',
                      style: AppTypography.body(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    MemberColorChipsRow(ids: _placeholderMemberIds(group)),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Avatar rond d'un groupe : couleur stable dérivée de son id
/// (`GroupColorAssigner`), simple variation visuelle sans signification
/// métier — voir la doc de classe de `GroupColorAssigner`.
class _GroupAvatar extends StatelessWidget {
  const _GroupAvatar({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: GroupColorAssigner.colorFor(groupId),
      ),
      child: const Icon(Icons.groups, size: 22, color: AppColors.textOnWood),
    );
  }
}

/// Badge "TOI" à côté du nom d'un groupe fondé par le joueur connecté (voir
/// `GroupSummary.founderId`).
class _FounderBadge extends StatelessWidget {
  const _FounderBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.parchmentCardAlt,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.woodLight, width: 1),
      ),
      child: Text(
        'TOI',
        style: AppTypography.display(
          fontSize: 9,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Recettage direction-artistique du 13/09 : cet écran (`GroupListScreen`)
/// est un niveau "scène" (`SceneScaffold`, fond sombre) — [_EmptyState] et
/// [_ErrorState] utilisaient encore par erreur les tokens "parchemin" (fond
/// clair) hérités de leur écriture initiale plutôt que les tokens "on-wood"
/// (texte clair sur fond sombre) déjà utilisés partout ailleurs sur cet
/// écran (voir `_Header`, `_GroupRow`...). Corrigé ici pour correspondre à
/// `character_list_screen.dart::_EmptyState`/`_ErrorState`, mêmes états sur
/// un écran "scène" comparable.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 88,
              height: 88,
              child: CustomPaint(
                painter: const DashedBorderPainter(
                  color: AppColors.textOnWoodMuted,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.groups_outlined,
                    size: 40,
                    color: AppColors.goldEnd,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              "AUCUN GROUPE POUR L'INSTANT",
              textAlign: TextAlign.center,
              style: AppTypography.display(
                fontSize: 11,
                color: AppColors.textOnWood,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              "Crée un groupe pour ton équipe, ou rejoins celui de tes "
              "coéquipiers avec un code d'invitation.",
              textAlign: TextAlign.center,
              style: AppTypography.body(color: AppColors.textOnWoodMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.accentBrick,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.body(color: AppColors.textOnWood),
            ),
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(label: 'Réessayer', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
