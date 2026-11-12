import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/display_text.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/zero_hp_indicator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/character_detail.dart';
import 'condition_chips.dart';

/// Carte combinant les bandeaux PV et XP de l'onglet "Personnage" — voir la
/// spec visuelle de la tâche qui a produit ce fichier.
class CharacterVitalsCard extends StatelessWidget {
  const CharacterVitalsCard({
    required this.detail,
    required this.onTapAdjustHp,
    required this.onTapAddXp,
    required this.onTapLevelUp,
    required this.onTapRest,
    this.hpActionsDisabled = false,
    this.onTapConditions,
    super.key,
  });

  final CharacterDetail detail;

  /// Ouvre la feuille d'ajustement PV détaillée — tap sur l'ensemble du
  /// bandeau PV (demande utilisateur du 15/09 : remplace à la fois le
  /// stepper +/- de soin/dégât rapide, retiré, et l'ancien bouton crayon
  /// isolé, dont la zone de tap ne couvrait que lui-même — voir
  /// [_HpSection]).
  final VoidCallback onTapAdjustHp;

  /// `true` pendant qu'un repos (`RestSheet`) — ou la réaffirmation PV
  /// différée qu'un repos peut déclencher, voir
  /// `_CharacterDetailScreenState._reassertCurrentHpState` — est en vol côté
  /// réseau. Désactive le bandeau PV (tap sur l'ensemble, voir
  /// [onTapAdjustHp]) ET le bouton "Repos" lui-même (jamais masqué, juste
  /// avec un callback `null`, pour que la fiche reste lisible) le temps de
  /// cette fenêtre.
  ///
  /// Ferme la course résiduelle confirmée en revue de code : sans le verrou
  /// sur le bandeau PV, un ajustement PV démarré *pendant* qu'un repos long
  /// écrit encore en base pourrait résoudre *avant* lui et se faire écraser
  /// silencieusement par l'écriture `current_hp = max_hp` du repos, arrivée
  /// après coup. Sans le verrou sur le bouton "Repos" lui-même, un second
  /// repos pourrait de la même façon démarrer et résoudre pendant qu'une
  /// réaffirmation PV différée (déclenchée par
  /// [_restGeneration]/`_reassertCurrentHpState`, l'autre sens de la course :
  /// un ajustement PV démarré *avant* le repos et résolu après lui) est
  /// encore en vol, et se faire écraser à son tour — même bug, un niveau
  /// plus profond. Voir `_CharacterDetailScreenState._isApplyingRest`
  /// (`character_detail_screen.dart`) pour le détail des deux mécanismes.
  final bool hpActionsDisabled;

  /// `PrimaryButton` pleine largeur "+ XP" sous la jauge XP (recettage
  /// direction-artistique du 13/09, remplace l'ancien `IconButton` "+" de
  /// l'en-tête) : ouvre `AddXpSheet`.
  final VoidCallback onTapAddXp;

  /// Lien discret "Monter de niveau manuellement" (XP sous le seuil) ou
  /// bandeau "NIVEAU {n+1} DISPONIBLE" (seuil déjà franchi) : les deux
  /// ouvrent le même flux de montée de niveau, ciblant `totalLevel + 1` —
  /// voir `character_detail_screen.dart`.
  final VoidCallback onTapLevelUp;

  /// Ouvre `RestSheet` (bouton "Repos" unique, voir [_RestButton] — demande
  /// utilisateur du 15/09 : remplace les deux `SecondaryButton` "Repos
  /// court"/"Repos long" introduits par le recettage direction-artistique du
  /// 13/09, le choix du type se fait désormais uniquement via la bascule
  /// segmentée déjà présente à l'intérieur de `RestSheet`) — voir
  /// `character_detail_screen.dart`.
  final VoidCallback onTapRest;

  /// Ouvre le sélecteur d'états (`showConditionsSheet`) : tap sur une
  /// pastille, sur « +N », sur le bouton d'édition ou sur « + État ».
  /// **Jamais** désactivé par [hpActionsDisabled] : les états restent
  /// modifiables même à 0 PV ou pour un personnage mort. `null` = zone en
  /// lecture seule (pastilles sans tap, rien si aucune condition).
  final VoidCallback? onTapConditions;

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
          _HpSection(
            detail: detail,
            onTapAdjustHp: onTapAdjustHp,
            actionsDisabled: hpActionsDisabled,
          ),
          // Zone d'état juste sous le bandeau PV, HORS de son `InkWell` :
          // un tap sur une pastille n'ouvre pas la feuille PV, et
          // inversement (P6).
          if (onTapConditions != null || detail.conditions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            ConditionsZone(
              conditions: detail.conditions,
              onEdit: onTapConditions,
              maxFullChips: 3,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          _RestButton(onTap: hpActionsDisabled ? null : onTapRest),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1, thickness: 1, color: AppColors.gaugeTrack),
          const SizedBox(height: AppSpacing.sm),
          _XpSection(
            detail: detail,
            onTapAddXp: onTapAddXp,
            onTapLevelUp: onTapLevelUp,
          ),
        ],
      ),
    );
  }
}

/// Bouton "Repos" unique — remplace les deux `SecondaryButton` côte à côte
/// "Repos court"/"Repos long" (recettage direction-artistique du 13/09),
/// eux-mêmes un remplacement du lien texte unique "Prendre un repos"
/// d'origine (demande utilisateur du 15/09 : le choix du type se fait
/// désormais uniquement via la bascule segmentée déjà présente à
/// l'intérieur de `RestSheet`, pas la peine de le dupliquer ici).
class _RestButton extends StatelessWidget {
  const _RestButton({required this.onTap});

  /// `null` pendant qu'un repos (ou sa réaffirmation PV différée, voir
  /// `_CharacterDetailScreenState._isApplyingRest`) est déjà en vol — évite
  /// qu'un second repos parte avant que le premier n'ait fini d'écrire, même
  /// verrou que l'ancien `_RestLink`/`_RestButtonsRow`.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SecondaryButton(
      label: AppLocalizations.of(context)!.characterVitalsCardRestButton,
      surface: SecondaryButtonSurface.parchment,
      onPressed: onTap,
    );
  }
}

/// Valeur `body` jumelée à une étiquette display PV/XP de la carte (décision
/// du 10/11/2026) : plafonnée à [AppTypography.maxVitalsValueScaleFactor]
/// (x1,6) pour que la paire étiquette + valeur tienne sur une ligne à largeur
/// contrainte (la `Row` de l'étiquette), même si la carte est dans une page
/// défilante (le défilement est vertical, la largeur reste bornée). Exception
/// ciblée : le corps reste libre partout ailleurs, y compris dans le reste de
/// cette carte.
class _VitalsValueText extends StatelessWidget {
  const _VitalsValueText(this.data, {required this.style});

  final String data;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      style: style,
      textScaler: MediaQuery.textScalerOf(context)
          .clamp(maxScaleFactor: AppTypography.maxVitalsValueScaleFactor),
    );
  }
}

/// Ligne « étiquette à gauche, valeur à droite » qui passe à la ligne quand
/// les deux ne tiennent plus côte à côte (grande police sur 320 dp, D196) : la
/// valeur descend sous l'étiquette au lieu de déborder. Pas de largeur fixe.
class _LabelValueRow extends StatelessWidget {
  const _LabelValueRow({required this.label, required this.value});

  final Widget label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    // `SizedBox(width: infinity)` : un `Wrap` se réduit à la largeur de son
    // contenu sous une contrainte lâche (parent `Column` aligné au début), et
    // `spaceBetween` n'écartait alors plus rien — étiquette et valeur collées.
    // `spacing` garantit un espace minimal avant de passer à la ligne.
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: [label, value],
      ),
    );
  }
}

/// Bandeau PV entièrement tappable (demande utilisateur du 15/09 : remplace
/// le stepper +/- de soin/dégât rapide, retiré, et l'ancien bouton crayon
/// isolé — l'icône crayon reste affichée comme simple indice visuel
/// "modifiable", mais n'est plus elle-même un `IconButton` séparé : tout le
/// bandeau ouvre désormais la feuille d'ajustement détaillée au tap).
class _HpSection extends StatelessWidget {
  const _HpSection({
    required this.detail,
    required this.onTapAdjustHp,
    required this.actionsDisabled,
  });

  final CharacterDetail detail;
  final VoidCallback onTapAdjustHp;

  /// Voir `CharacterVitalsCard.hpActionsDisabled`.
  final bool actionsDisabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: actionsDisabled ? null : onTapAdjustHp,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LabelValueRow(
              label: DisplayText(
                l10n.characterVitalsCardHpLabel,
                style: AppTypography.display(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              value: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: _VitalsValueText(
                      '${detail.currentHp} / ${detail.maxHp}',
                      style: AppTypography.body(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            _HpGauge(ratio: detail.hpRatio),
            if (detail.currentHp == 0) ...[
              const SizedBox(height: AppSpacing.xs),
              const ZeroHpIndicator(),
            ],
            if (detail.temporaryHp > 0) ...[
              const SizedBox(height: AppSpacing.xs),
              _TemporaryHpChip(amount: detail.temporaryHp),
            ],
          ],
        ),
      ),
    );
  }
}

/// Jauge PV 12px, dégradé selon le seuil de [ratio] (PV temporaires exclus,
/// voir `CharacterDetail.hpRatio`) : vert au-dessus de 50 %, orange entre 25
/// et 50 % (bornes incluses), rouge en-dessous de 25 %.
class _HpGauge extends StatelessWidget {
  const _HpGauge({required this.ratio});

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
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: ratio,
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: _gradientFor(ratio)),
          ),
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
        AppLocalizations.of(context)!
            .characterVitalsCardTemporaryHpChip(amount),
        style: AppTypography.body(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.accentTeal,
        ),
      ),
    );
  }
}

class _XpSection extends StatelessWidget {
  const _XpSection({
    required this.detail,
    required this.onTapAddXp,
    required this.onTapLevelUp,
  });

  final CharacterDetail detail;
  final VoidCallback onTapAddXp;
  final VoidCallback onTapLevelUp;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Au niveau maximum (`nextLevelXpThreshold` nul), il n'y a plus de
    // "prochain seuil" vers lequel afficher une progression : le seuil
    // affiché retombe alors sur l'XP actuelle elle-même (jauge pleine,
    // valeur affichée "{xp} / {xp}") plutôt qu'un cas non couvert par la
    // spec visuelle.
    final threshold = detail.nextLevelXpThreshold ?? detail.xp;
    // Seuil déjà franchi (montée en attente) : `nextLevelXpThreshold` non
    // nul (donc pas déjà au niveau maximum) ET l'XP actuelle l'a atteint ou
    // dépassé.
    final thresholdReached =
        detail.nextLevelXpThreshold != null &&
        detail.xp >= detail.nextLevelXpThreshold!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LabelValueRow(
          label: DisplayText(
            l10n.characterVitalsCardXpLabel,
            style: AppTypography.display(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          value: _VitalsValueText(
            '${detail.xp} / $threshold',
            style: AppTypography.body(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.gaugeTrack,
              border: Border.all(color: AppColors.gaugeTrackBorder),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: detail.xpProgress,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryButtonGradient,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // `PrimaryButton` pleine largeur "+ XP" — remplace l'`IconButton`
        // "+" de l'en-tête ci-dessus (recettage direction-artistique du
        // 13/09), même callback [onTapAddXp] (ouvre `AddXpSheet`).
        PrimaryButton(
          label: l10n.characterVitalsCardAddXpButton,
          onPressed: onTapAddXp,
        ),
        // Lien discret "Monter de niveau manuellement" retiré d'ici (demande
        // utilisateur du 15/09) : relogé dans `AddXpSheet` (bouton "+ XP"
        // ci-dessus), voir sa documentation de classe. Le bandeau "NIVEAU
        // {n} DISPONIBLE" reste seul ici : contrairement au lien, il ne fait
        // pas doublon avec un contenu de la sheet (rien d'équivalent n'y est
        // proposé une fois le seuil déjà franchi).
        if (thresholdReached) ...[
          const SizedBox(height: AppSpacing.xs),
          _LevelUpAvailableBanner(
            targetLevel: detail.totalLevel + 1,
            onTap: onTapLevelUp,
          ),
        ],
      ],
    );
  }
}

/// Bandeau "NIVEAU {n} DISPONIBLE" (seuil franchi, montée en attente) —
/// remplace [_ManualLevelUpLink] tant que la montée n'a pas été effectuée
/// (spec visuelle section 1b).
class _LevelUpAvailableBanner extends StatelessWidget {
  const _LevelUpAvailableBanner({
    required this.targetLevel,
    required this.onTap,
  });

  final int targetLevel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.parchmentCardAlt,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.goldEnd,
              width: AppBorders.card,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.arrow_upward,
                size: 16,
                color: AppColors.accentBrick,
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: DisplayText(
                  AppLocalizations.of(context)!
                      .characterVitalsCardLevelUpBanner(targetLevel),
                  textAlign: TextAlign.center,
                  style: AppTypography.display(
                    fontSize: 11,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
