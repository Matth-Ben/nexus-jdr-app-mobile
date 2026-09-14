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
/// `docs/cahier-des-charges/12-partage-et-groupes.md` section 2.2, revu par
/// le recettage direction-artistique du 13/09.
///
/// Mise à jour temps réel silencieuse : ce widget est purement déclaratif
/// (aucun état local), reconstruit tel quel à chaque nouvelle valeur de
/// `groupDetailProvider` (voir `groupMembersRealtimeWatcherProvider`) — la
/// jauge PV de chaque membre ([_MemberHpGauge]) anime la transition entre
/// deux valeurs plutôt que de "sauter" brutalement, seul mécanisme
/// nécessaire ici pour éviter tout flash visuel. [_LiveUpdateIndicator] en
/// tête de liste rend ce comportement explicite pour le joueur plutôt que de
/// rester un détail d'implémentation invisible.
class GroupMembersTabBody extends StatelessWidget {
  const GroupMembersTabBody({
    required this.detail,
    required this.onRemoveMember,
    required this.onLeaveGroup,
    super.key,
  });

  final GroupDetail detail;
  final RemoveGroupMemberCallback onRemoveMember;

  /// "Quitter le groupe" — affiché en pied de cet onglet pour les membres
  /// non-fondateurs uniquement (recettage direction-artistique du 13/09 :
  /// auparavant réservé aux non-fondateurs via l'icône déconnexion du
  /// header de `group_screen.dart`, qui reste par ailleurs inchangée).
  /// Décision explicite du chef de projet : ne PAS l'afficher au fondateur
  /// — `docs/cahier-des-charges/12-partage-et-groupes.md` ligne 60 ne
  /// documente que "Quitter un groupe (un membre) ou exclure un membre (le
  /// owner)", jamais un fondateur qui quitte son propre groupe, et
  /// `GroupRepository.leaveGroup` ne gère pas le transfert de
  /// `groups.owner_id` que ce cas supposerait. Un fondateur qui veut se
  /// détacher du groupe doit le dissoudre (`group_settings_screen.dart`,
  /// "ZONE DANGEREUSE").
  final VoidCallback onLeaveGroup;

  @override
  Widget build(BuildContext context) {
    final members = detail.members;
    final showBanner = members.length == 1;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const _LiveUpdateIndicator(),
        const SizedBox(height: AppSpacing.md),
        if (showBanner) ...[
          InfoBanner(
            icon: Icons.share_outlined,
            message:
                "Partage le code ${detail.inviteCode} pour inviter d'autres "
                'joueurs.',
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        for (final member in members) ...[
          _MemberCard(
            member: member,
            isSelf: member.userId == detail.currentUserId,
            canRemove: detail.isOwner && member.userId != detail.currentUserId,
            onRemove: () => onRemoveMember(member),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        const SizedBox(height: AppSpacing.xs),
        const _PrivacyExplanation(),
        if (!detail.isOwner) ...[
          const SizedBox(height: AppSpacing.md),
          _LeaveGroupLink(onTap: onLeaveGroup),
        ],
      ],
    );
  }
}

/// "● Mis à jour en direct" en tête de liste — rend visible pour le joueur ce
/// que [GroupMembersTabBody] fait déjà silencieusement (Realtime). Puce verte
/// [AppColors.accentTeal] : pas de token "vert" dédié dans la palette, mais
/// même choix déjà fait pour la puce de succès de [InfoBanner.success]
/// (`core/widgets/info_banner.dart`, "Partage actif") — réutilisé ici pour la
/// même sémantique "état actif/à jour" plutôt qu'introduire une couleur en
/// dur.
class _LiveUpdateIndicator extends StatelessWidget {
  const _LiveUpdateIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.circle, size: 8, color: AppColors.accentTeal),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            'Mis à jour en direct',
            style: AppTypography.body(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
      ],
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
    final isDead = member.vitalStatus == CharacterVitalStatus.dead;
    final nameColor = isDead ? AppColors.textMuted : AppColors.textPrimary;

    final portrait = PortraitFrame(portraitUrl: member.portraitUrl, size: 64);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDead ? AppColors.deadCardBackground : AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDead ? AppColors.accentBrick : AppColors.woodLight,
          width: isDead ? AppBorders.cardEmphasis : AppBorders.card,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Portrait désaturé pour la variante "MORT" (recettage
          // direction-artistique du 13/09) : `PortraitFrame` n'a pas de
          // paramètre dédié, enveloppé d'un `ColorFiltered` en niveaux de
          // gris plutôt que de lui ajouter un paramètre pour un unique usage.
          isDead
              ? ColorFiltered(
                  colorFilter: const ColorFilter.matrix(_greyscaleMatrix),
                  child: portrait,
                )
              : portrait,
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ligne 1 : nom + badges (recettage direction-artistique du
                // 13/09 — auparavant nom et badge de statut sur 2 lignes
                // séparées).
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: member.name,
                              style: AppTypography.body(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: nameColor,
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
                    ),
                    if (member.vitalStatus != CharacterVitalStatus.alive) ...[
                      const SizedBox(width: AppSpacing.xs),
                      _StatusBadge(status: member.vitalStatus),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                // Ligne 2 : jauge + fraction PV sur la même ligne (recettage
                // direction-artistique du 13/09 — auparavant la fraction PV
                // (+ éventuel chip PV temp.) formait une 3e ligne sous la
                // jauge ; la ligne "résumé race/classe/niveau" est retirée).
                Row(
                  children: [
                    Expanded(child: _MemberHpGauge(ratio: member.hpRatio)),
                    const SizedBox(width: AppSpacing.sm),
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

/// Matrice `ColorFilter` en niveaux de gris (coefficients de luminance
/// standard Rec. 601) — voir son usage sur le portrait de [_MemberCard]
/// quand [CharacterVitalStatus.dead].
const List<double> _greyscaleMatrix = <double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0, //
];

/// Pilule de statut "INCONSCIENT"/"MORT" — voir
/// `docs/cahier-des-charges/12-partage-et-groupes.md` section 2.2 :
/// `alertBannerBackground`, `font.display` 11px minimum `accentBrick`.
/// [CharacterVitalStatus.alive] n'est jamais passé ici (voir
/// [GroupMembersTabBody], qui ne rend ce badge que si le statut n'est pas
/// "vivant"). Depuis le recettage direction-artistique du 13/09,
/// "INCONSCIENT" a ses propres tokens ([AppColors.statusUnconsciousBackground]/
/// [AppColors.statusUnconsciousAccent]) plutôt que de partager ceux de
/// "MORT" ([AppColors.alertBannerBackground]/[AppColors.accentBrick],
/// inchangés) — jugés insuffisamment distinctifs entre les deux statuts.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final CharacterVitalStatus status;

  @override
  Widget build(BuildContext context) {
    final isDead = status == CharacterVitalStatus.dead;
    final background = isDead
        ? AppColors.alertBannerBackground
        : AppColors.statusUnconsciousBackground;
    final accent = isDead
        ? AppColors.accentBrick
        : AppColors.statusUnconsciousAccent;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: accent, width: isDead ? AppBorders.card : 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isDead) ...[
            Icon(Icons.warning_amber_rounded, size: 14, color: accent),
            const SizedBox(width: 4),
          ],
          Text(
            isDead ? 'MORT' : 'INCONSCIENT',
            style: AppTypography.display(fontSize: 11, color: accent),
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

/// Texte explicatif en pied de liste (recettage direction-artistique du
/// 13/09) — rappelle explicitement ce que la RLS de groupe autorise déjà à
/// lire côté serveur (voir la doc de classe de `GroupRepository`), pour que
/// le joueur n'en déduise pas à tort que le reste de la fiche d'un
/// coéquipier est visible ici.
class _PrivacyExplanation extends StatelessWidget {
  const _PrivacyExplanation();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Seuls les PV et le statut sont visibles ici — compétences, sorts, '
      'inventaire et histoire restent privés.',
      textAlign: TextAlign.center,
      style: AppTypography.body(fontSize: 12, color: AppColors.textMuted),
    );
  }
}

/// Lien "Quitter le groupe" — voir la documentation de
/// [GroupMembersTabBody.onLeaveGroup]. Calque `_ClaimCurrencyLink`
/// (`group_treasure_tab_body.dart`) pour le gabarit "lien texte" (zone de tap
/// 44px min-height, icône + libellé `body` 700/13), en `AppColors.accentBrick`
/// plutôt que `textSecondary` : seul lien de cet onglet à déclencher une
/// action de départ du groupe (même famille de couleur que
/// `DestructiveButton`, utilisé par la boîte de confirmation qui suit ce tap
/// — voir `_GroupScreenState._confirmLeaveGroup`).
class _LeaveGroupLink extends StatelessWidget {
  const _LeaveGroupLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: _LeaveGroupLinkLabel(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LeaveGroupLinkLabel extends StatelessWidget {
  const _LeaveGroupLinkLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.logout, size: 14, color: AppColors.accentBrick),
        const SizedBox(width: 4),
        Text(
          'Quitter le groupe',
          style: AppTypography.body(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.accentBrick,
          ),
        ),
      ],
    );
  }
}
