import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/dashed_border_painter.dart';
import '../../../../core/widgets/portrait_frame.dart';
import '../../domain/character_summary.dart';

/// Carte d'un personnage dans la liste d'accueil (`character_list_screen.dart`),
/// conforme au composant "Carte personnage" de
/// `docs/cahier-des-charges/10-design-system.md` section 4 et à la maquette
/// `01_liste_personnages.png`.
///
/// Trois variantes selon [CharacterSummary.isArchived]/[CharacterSummary.isDead]
/// (`docs/cahier-des-charges/11-fonctionnalites-a-ajouter.md` section 2) —
/// voir [_StatusVariant] : normale, archivée (bordure pointillée, opacité
/// ~75 %, badge "ARCHIVÉ") et morte (fond assombri, badge "MORT", icône de
/// substitution dédiée quand le personnage n'a pas de portrait). Un
/// personnage à la fois mort ET archivé affiche les deux badges, la
/// variante "morte" primant sur le fond/la bordure (statut le plus sévère) —
/// combinaison non illustrée par la maquette, extension raisonnable plutôt
/// qu'un cas non géré.
///
/// N'affiche volontairement pas de puce "histoire associée" (visible sur la
/// maquette) : `character_campaigns` n'existe pas encore côté données
/// (Phase 4, voir `02-modele-donnees.md`) — voir la consigne de la tâche qui
/// a produit cet écran.
class CharacterCard extends StatelessWidget {
  const CharacterCard({required this.character, this.onTap, super.key});

  final CharacterSummary character;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDead = character.isDead;
    final isArchived = character.isArchived;

    final nameColor = isDead ? AppColors.textOnWood : AppColors.textPrimary;
    final summaryColor = isDead
        ? AppColors.textOnWoodMuted
        : AppColors.textSecondary;

    final card = Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDead
            ? AppColors.woodDark
            // 94 % d'opacité sur fond "scène", comme spécifié au design
            // système pour ce composant.
            : AppColors.parchmentCard.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppRadius.md),
        // Bordure pointillée (variante "archivée") dessinée séparément par
        // [DashedBorderPainter] ci-dessous plutôt qu'ici : `Border` ne
        // supporte pas nativement un tracé pointillé, même limitation déjà
        // documentée sur `PortraitFrame`/`_JoinStoryButton`.
        border: isArchived
            ? null
            : Border.all(
                color: isDead ? AppColors.woodDark : AppColors.woodMedium,
                width: AppBorders.cardEmphasis,
              ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.woodDark,
            blurRadius: 0,
            spreadRadius: AppBorders.cardEmphasisHalo,
          ),
          BoxShadow(
            color: AppColors.cardDiffuseShadow,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PortraitFrame(
            portraitUrl: character.portraitUrl,
            fallbackIcon: isDead ? Icons.mood_bad : Icons.person_outline,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  character.name,
                  style: AppTypography.body(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: nameColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _summaryLine(character),
                  style: AppTypography.body(
                    fontSize: 13,
                    color: summaryColor,
                  ),
                ),
                if (isArchived || isDead) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (isArchived) const _StatusBadge.archived(),
                      if (isDead) const _StatusBadge.dead(),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                _XpGauge(progress: character.xpProgress),
              ],
            ),
          ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Opacity(
          // ~75 % d'opacité pour la variante "archivée" (design système) —
          // sans effet pour une carte normale/morte.
          opacity: isArchived ? 0.75 : 1,
          child: isArchived
              ? CustomPaint(
                  painter: const DashedBorderPainter(
                    color: AppColors.woodMedium,
                  ),
                  child: card,
                )
              : card,
        ),
      ),
    );
  }

  /// "Race · Classe · Niv. X", en omettant les segments non résolus (race
  /// personnalisée ou personnage sans classe enregistrée) plutôt que
  /// d'afficher "null".
  String _summaryLine(CharacterSummary character) {
    final segments = [
      if (character.raceName != null) character.raceName!,
      if (character.className != null) character.className!,
      'Niv. ${character.level}',
    ];
    return segments.join(' · ');
  }
}

/// Badge pill "ARCHIVÉ"/"MORT" — voir
/// `docs/cahier-des-charges/10-design-system.md` section 4, "Carte
/// personnage" et la maquette `01_liste_personnages.png`. "ARCHIVÉ" en
/// `parchment.card-alt`/`textSecondary` (neutre), "MORT" en `accent.brick`
/// (même couleur que le "Bandeau d'alerte inline"/bouton destructif) avec un
/// texte clair pour rester lisible sur ce fond saturé.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge.archived()
    : _label = 'ARCHIVÉ',
      _background = AppColors.parchmentCardAlt,
      _foreground = AppColors.textSecondary;

  const _StatusBadge.dead()
    : _label = 'MORT',
      _background = AppColors.accentBrick,
      _foreground = AppColors.textOnWood;

  final String _label;
  final Color _background;
  final Color _foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.woodLight, width: 1),
      ),
      child: Text(
        _label,
        style: AppTypography.display(fontSize: 10, color: _foreground),
      ),
    );
  }
}

/// Jauge XP du design système section 3 ("Jauge (PV / XP)") : piste
/// `gaugeTrack` bordée de `gaugeTrackBorder`, remplissage en dégradé
/// `gold-start` → `gold-end`, hauteur 8px, avec le label "XP" à droite.
class _XpGauge extends StatelessWidget {
  const _XpGauge({required this.progress});

  /// Ratio de remplissage entre 0 et 1.
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.gaugeTrack,
                border: Border.all(color: AppColors.gaugeTrackBorder),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryButtonGradient,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          'XP',
          style: AppTypography.body(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
