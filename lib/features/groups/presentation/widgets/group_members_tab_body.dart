import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/portrait_frame.dart';
import '../../domain/character_vital_status.dart';
import '../../domain/group_detail.dart';
import '../../domain/group_member.dart';

/// Callback "Exclure {personnage}" (owner uniquement, jamais sur sa propre
/// ligne) — la confirmation est gérée par l'appelant (`group_screen.dart`),
/// voir `GroupRepository.removeMember`.
typedef RemoveGroupMemberCallback = void Function(GroupMember member);

/// Contenu de l'onglet "Membres" de l'écran "Groupe" —
/// `docs/cahier-des-charges/12-partage-et-groupes.md` section 2.2.
///
/// Mise à jour temps réel silencieuse : ce widget est purement déclaratif
/// (aucun état local), reconstruit tel quel à chaque nouvelle valeur de
/// `groupDetailProvider` (voir `groupMembersRealtimeWatcherProvider`) — la
/// jauge PV de chaque membre ([_MemberHpGauge]) anime la transition entre
/// deux valeurs plutôt que de "sauter" brutalement, seul mécanisme
/// nécessaire ici pour éviter tout flash visuel.
class GroupMembersTabBody extends StatelessWidget {
  const GroupMembersTabBody({
    required this.detail,
    required this.onRemoveMember,
    super.key,
  });

  final GroupDetail detail;
  final RemoveGroupMemberCallback onRemoveMember;

  @override
  Widget build(BuildContext context) {
    final members = detail.members;
    final showBanner = members.length == 1;
    final itemCount = members.length + (showBanner ? 1 : 0);

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: itemCount,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        if (showBanner && index == 0) {
          return InfoBanner(
            icon: Icons.share_outlined,
            message:
                "Partage le code ${detail.inviteCode} pour inviter d'autres "
                'joueurs.',
          );
        }

        final member = members[showBanner ? index - 1 : index];
        final isSelf = member.userId == detail.currentUserId;
        return _MemberCard(
          member: member,
          isSelf: isSelf,
          canRemove: detail.isOwner && !isSelf,
          onRemove: () => onRemoveMember(member),
        );
      },
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.isSelf,
    required this.canRemove,
    required this.onRemove,
  });

  final GroupMember member;
  final bool isSelf;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.woodLight, width: AppBorders.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PortraitFrame(portraitUrl: member.portraitUrl, size: 64),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: member.name,
                        style: AppTypography.body(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (isSelf)
                        TextSpan(
                          text: ' (toi)',
                          style: AppTypography.body(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (member.vitalStatus != CharacterVitalStatus.alive) ...[
                  const SizedBox(height: AppSpacing.xs),
                  _StatusBadge(status: member.vitalStatus),
                ],
                const SizedBox(height: 4),
                Text(
                  member.summaryLine,
                  style: AppTypography.body(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                _MemberHpGauge(ratio: member.hpRatio),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${member.currentHp}/${member.maxHp}',
                      style: AppTypography.body(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (member.temporaryHp > 0) ...[
                      const SizedBox(width: AppSpacing.xs),
                      _TemporaryHpChip(amount: member.temporaryHp),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (canRemove)
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                tooltip: 'Exclure ${member.name}',
                onPressed: onRemove,
                icon: const Icon(
                  Icons.person_remove_outlined,
                  color: AppColors.accentBrick,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Pilule de statut "INCONSCIENT"/"MORT" — voir
/// `docs/cahier-des-charges/12-partage-et-groupes.md` section 2.2 :
/// `alertBannerBackground`, `font.display` 11px minimum `accentBrick`.
/// [CharacterVitalStatus.alive] n'est jamais passé ici (voir
/// [GroupMembersTabBody], qui ne rend ce badge que si le statut n'est pas
/// "vivant").
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final CharacterVitalStatus status;

  @override
  Widget build(BuildContext context) {
    final isDead = status == CharacterVitalStatus.dead;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.alertBannerBackground,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: AppColors.accentBrick,
          width: isDead ? AppBorders.card : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isDead) ...[
            const Icon(
              Icons.warning_amber_rounded,
              size: 14,
              color: AppColors.accentBrick,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            isDead ? 'MORT' : 'INCONSCIENT',
            style: AppTypography.display(
              fontSize: 11,
              color: AppColors.accentBrick,
            ),
          ),
        ],
      ),
    );
  }
}

/// Jauge PV 12px animée — calque de `CharacterVitalsCard`'s `_HpGauge`
/// (dégradé selon seuil : vert >50 %, orange 25-50 %, rouge <25 %), avec une
/// transition `TweenAnimationBuilder` (~220ms) entre deux valeurs de
/// [ratio] : contrairement à la fiche personnage (variations déclenchées par
/// une action locale immédiate), les changements ici arrivent de façon
/// asynchrone via Supabase Realtime — l'animation évite tout "flash" visuel
/// au moment de la mise à jour silencieuse (voir la doc de classe de
/// [GroupMembersTabBody]).
class _MemberHpGauge extends StatelessWidget {
  const _MemberHpGauge({required this.ratio});

  final double ratio;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        height: 12,
        decoration: BoxDecoration(
          color: AppColors.gaugeTrack,
          border: Border.all(color: AppColors.gaugeTrackBorder),
        ),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: ratio, end: ratio),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value,
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: _gradientFor(value)),
              ),
            );
          },
        ),
      ),
    );
  }

  LinearGradient _gradientFor(double ratio) {
    if (ratio > 0.5) {
      return const LinearGradient(
        colors: [AppColors.hpHealthyStart, AppColors.hpHealthyEnd],
      );
    }
    if (ratio >= 0.25) {
      return const LinearGradient(
        colors: [AppColors.hpCautionStart, AppColors.hpCautionEnd],
      );
    }
    return const LinearGradient(
      colors: [AppColors.hpCriticalStart, AppColors.hpCriticalEnd],
    );
  }
}

class _TemporaryHpChip extends StatelessWidget {
  const _TemporaryHpChip({required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.parchmentCardAlt,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.accentTeal, width: 1),
      ),
      child: Text(
        '+$amount PV temp.',
        style: AppTypography.body(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.accentTeal,
        ),
      ),
    );
  }
}
