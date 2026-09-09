import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/portrait_frame.dart';
import '../../../core/widgets/wood_back_header.dart';
import '../../characters/domain/character_detail.dart';
import '../../characters/domain/character_failure.dart';
import '../../characters/domain/character_identity_formatter.dart';
import '../../characters/domain/proficiency_bonus.dart';
import '../../characters/domain/saving_throw_calculator.dart';
import '../../characters/presentation/widgets/character_ability_score_grid.dart';
import '../../characters/presentation/widgets/character_appearance_card.dart';
import '../../characters/presentation/widgets/character_detail_tab_bar.dart';
import '../../characters/presentation/widgets/character_inventory_tab_body.dart';
import '../../characters/presentation/widgets/character_saving_throws_card.dart';
import '../../characters/presentation/widgets/character_skills_tab_body.dart';
import '../../characters/presentation/widgets/character_spells_tab_body.dart';
import '../../characters/presentation/widgets/character_stat_pills_row.dart';
import '../../characters/presentation/widgets/character_story_tab_body.dart';
import 'providers/character_sharing_providers.dart';

/// Écran "Vue en lecture seule" d'un personnage partagé, route `/p/:token`
/// (point d'entrée du deep link `nexus-jdr.app/p/{token}`) — voir
/// `docs/cahier-des-charges/12-partage-et-groupes.md` section 1 et la
/// maquette "Partage — Vue en lecture seule"
/// (`docs/cahier-des-charges/09-maquettes-captures.md`).
///
/// Accessible sans authentification (voir `core/router/app_router.dart
/// ::computeAuthRedirect`, qui exempte explicitement `/p/*` de la
/// redirection `/login`) : [token] seul suffit à consulter la fiche via
/// `public.get_shared_character` (dépôt web), qui ne renvoie jamais
/// l'identité du propriétaire (voir la doc de classe de
/// `shared_character_mapper.dart::mapSharedCharacterJson`) — le bandeau de
/// tête reste donc générique ("Vue en lecture seule"), sans "Partagé par
/// {nom}" contrairement à la maquette, écart assumé documenté ici plutôt
/// qu'élargir la fonction RPC pour exposer une identité que sa conception
/// exclut délibérément.
///
/// Réutilise les mêmes onglets/composants que la fiche personnage
/// authentifiée (`character_detail_screen.dart`) via `actionsDisabled: true`
/// + callbacks no-op pour Compétences/Sorts/Inventaire — voir la doc de
/// classe de `shared_character_mapper.dart` pour le rationale complet de
/// cette réutilisation.
class SharedCharacterViewScreen extends ConsumerStatefulWidget {
  const SharedCharacterViewScreen({required this.token, super.key});

  final String token;

  @override
  ConsumerState<SharedCharacterViewScreen> createState() =>
      _SharedCharacterViewScreenState();
}

class _SharedCharacterViewScreenState
    extends ConsumerState<SharedCharacterViewScreen> {
  CharacterDetailTab _tab = CharacterDetailTab.character;

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final sharedAsync = ref.watch(
      sharedCharacterProvider(token: widget.token),
    );

    return Scaffold(
      backgroundColor: AppColors.parchmentBg,
      body: Column(
        children: [
          WoodBackHeader(
            title: sharedAsync.value != null
                ? _tab.headerTitle
                : 'PERSONNAGE PARTAGÉ',
            onBack: _goBack,
          ),
          Expanded(
            child: sharedAsync.when(
              data: (detail) => detail == null
                  ? _InvalidLinkState(onRetry: _retry)
                  : _buildTabBody(detail),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.woodMedium),
              ),
              error: (error, stackTrace) => _ErrorState(
                message: error is CharacterFailure
                    ? error.message
                    : 'Impossible de charger ce personnage. Réessayez.',
                onRetry: _retry,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: sharedAsync.maybeWhen(
        data: (detail) => detail == null
            ? null
            : CharacterDetailTabBar(
                current: _tab,
                onSelect: (tab) => setState(() => _tab = tab),
              ),
        orElse: () => null,
      ),
    );
  }

  void _retry() {
    ref.invalidate(sharedCharacterProvider(token: widget.token));
  }

  Widget _buildTabBody(CharacterDetail detail) {
    return switch (_tab) {
      CharacterDetailTab.character => _CharacterTabBody(detail: detail),
      CharacterDetailTab.skills => CharacterSkillsTabBody(
        detail: detail,
        onUseFeature: (_) {},
        actionsDisabled: true,
      ),
      CharacterDetailTab.spells => CharacterSpellsTabBody(
        detail: detail,
        onCastSpell: (spell, slot) {},
        onToggleFavorite: (spell) {},
        onTogglePrepared: (spell) {},
        actionsDisabled: true,
      ),
      CharacterDetailTab.inventory => CharacterInventoryTabBody(
        detail: detail,
        onUseItem: (_) {},
        onToggleItemEquipped: (_) {},
        onToggleItemAttuned: (_) {},
        onRemoveItem: (_) {},
        onAdjustCurrency: (currency, newAmount) {},
        onAddInventoryItem: (item, quantity) {},
        onAddCustomInventoryItem: (customName, quantity) {},
        actionsDisabled: true,
      ),
      // `actionsDisabled: true` couvre les 9 champs de texte (état vide sans
      // bouton "Renseigner mon histoire", inapproprié pour un lecteur
      // anonyme) ET la galerie/le journal de campagne (voir la
      // documentation de classe de `CharacterStoryTabBody.actionsDisabled`)
      // — un seul et même flag pour toute la carte, plus besoin d'un état
      // vide dédié à cet écran.
      CharacterDetailTab.story => CharacterStoryTabBody(
        detail: detail,
        onEdit: () {},
        actionsDisabled: true,
      ),
    };
  }
}

class _CharacterTabBody extends StatelessWidget {
  const _CharacterTabBody({required this.detail});

  final CharacterDetail detail;

  @override
  Widget build(BuildContext context) {
    final proficiencyBonus = ProficiencyBonusRules.forTotalLevel(
      detail.totalLevel,
    );
    final savingThrows = SavingThrowCalculator.computeAll(
      abilityScores: detail.abilityScores,
      proficientAbilities: detail.primarySavingThrowProficiencies,
      proficiencyBonus: proficiencyBonus,
    );

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const InfoBanner(
          message: 'Vue en lecture seule',
          icon: Icons.lock_outline,
        ),
        const SizedBox(height: AppSpacing.md),
        _SharedIdentityCard(detail: detail),
        const SizedBox(height: AppSpacing.md),
        CharacterStatPillsRow(
          speed: detail.speed,
          armorClass: detail.armorClass,
          inspiration: detail.inspiration,
        ),
        const SizedBox(height: AppSpacing.md),
        _SharedVitalsCard(detail: detail),
        const SizedBox(height: AppSpacing.md),
        CharacterAbilityScoreGrid(abilityScores: detail.abilityScores),
        const SizedBox(height: AppSpacing.md),
        CharacterSavingThrowsCard(results: savingThrows),
        if (CharacterAppearanceCard.hasContent(detail)) ...[
          const SizedBox(height: AppSpacing.md),
          CharacterAppearanceCard(detail: detail),
        ],
      ],
    );
  }
}

class _SharedIdentityCard extends StatelessWidget {
  const _SharedIdentityCard({required this.detail});

  final CharacterDetail detail;

  @override
  Widget build(BuildContext context) {
    final subtitle = CharacterIdentityFormatter.subtitleLine1(detail);

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
          PortraitFrame(portraitUrl: detail.portraitUrl),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.name,
                  style: AppTypography.body(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: AppTypography.body(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bandeaux PV/XP statiques (sans stepper ni action) — version en lecture
/// seule de `character_vitals_card.dart::CharacterVitalsCard`, non réutilisée
/// telle quelle : celle-ci est entièrement couplée à ses actions d'écriture
/// (ajustement PV, repos, montée de niveau, statut mort), voir le rapport de
/// la tâche qui a introduit cet écran. Mêmes seuils de dégradé PV (`> 0.5`
/// sain, `0.25`-`0.5` prudent, `< 0.25` critique) et tokens
/// (`AppColors.hp*`/`gaugeTrack*`) que l'original, recopiés à l'identique.
class _SharedVitalsCard extends StatelessWidget {
  const _SharedVitalsCard({required this.detail});

  final CharacterDetail detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.woodLight, width: AppBorders.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'POINTS DE VIE',
                style: AppTypography.display(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '${detail.currentHp} / ${detail.maxHp}',
                style: AppTypography.body(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          _Gauge(height: 12, ratio: detail.hpRatio, gradient: _hpGradient(detail.hpRatio)),
          if (detail.temporaryHp > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '+${detail.temporaryHp} PV temp.',
              style: AppTypography.body(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.accentTeal,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                'EXPÉRIENCE',
                style: AppTypography.display(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '${detail.xp} / ${detail.nextLevelXpThreshold ?? detail.xp}',
                style: AppTypography.body(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          _Gauge(
            height: 8,
            ratio: detail.xpProgress,
            gradient: AppColors.primaryButtonGradient,
          ),
        ],
      ),
    );
  }

  LinearGradient _hpGradient(double ratio) {
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

class _Gauge extends StatelessWidget {
  const _Gauge({
    required this.height,
    required this.ratio,
    required this.gradient,
  });

  final double height;
  final double ratio;
  final LinearGradient gradient;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.gaugeTrack,
          border: Border.all(color: AppColors.gaugeTrackBorder),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: ratio,
          child: DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
        ),
      ),
    );
  }
}

class _InvalidLinkState extends StatelessWidget {
  const _InvalidLinkState({required this.onRetry});

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
              Icons.link_off,
              size: 48,
              color: AppColors.accentBrick,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Ce lien de partage n\'est plus valide',
              textAlign: TextAlign.center,
              style: AppTypography.display(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Le partage a peut-être été désactivé, ou le lien a été mal '
              'recopié. Demande un nouveau lien à son propriétaire.',
              textAlign: TextAlign.center,
              style: AppTypography.body(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(onPressed: onRetry, child: const Text('Réessayer')),
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
            TextButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
