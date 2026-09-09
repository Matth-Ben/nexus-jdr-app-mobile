import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/wood_back_header.dart';
import '../domain/group_failure.dart';
import '../domain/group_summary.dart';
import 'providers/group_providers.dart';

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

    return Scaffold(
      backgroundColor: AppColors.parchmentBg,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            WoodBackHeader(title: 'GROUPES', onBack: () => _goBack(context)),
            Expanded(
              child: groupsAsync.when(
                data: (groups) => _GroupList(groups: groups),
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.woodMedium,
                  ),
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
                      surface: SecondaryButtonSurface.parchment,
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

class _GroupList extends StatelessWidget {
  const _GroupList({required this.groups});

  final List<GroupSummary> groups;

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
          onTap: () => context.push('/groups/${group.id}'),
        );
      },
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({required this.group, required this.onTap});

  final GroupSummary group;
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${group.memberCount} membres',
                      style: AppTypography.body(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
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
            Container(
              width: 88,
              height: 88,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                  BorderSide(color: AppColors.textMuted, width: 1.5),
                ),
              ),
              child: const Icon(
                Icons.groups_outlined,
                size: 40,
                color: AppColors.woodMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              "AUCUN GROUPE POUR L'INSTANT",
              textAlign: TextAlign.center,
              style: AppTypography.display(
                fontSize: 11,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              "Crée un groupe pour ton équipe, ou rejoins celui de tes "
              "coéquipiers avec un code d'invitation.",
              textAlign: TextAlign.center,
              style: AppTypography.body(color: AppColors.textSecondary),
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
              style: AppTypography.body(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(
              label: 'Réessayer',
              surface: SecondaryButtonSurface.parchment,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
