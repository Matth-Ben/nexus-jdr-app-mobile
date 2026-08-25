import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/portrait_frame.dart';
import '../../domain/character_summary.dart';

/// Carte d'un personnage dans la liste d'accueil (`character_list_screen.dart`),
/// conforme au composant "Carte personnage" de
/// `docs/cahier-des-charges/10-design-system.md` section 4 et à la maquette
/// `01_liste_personnages.png`.
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            // 94 % d'opacité sur fond "scène", comme spécifié au design
            // système pour ce composant.
            color: AppColors.parchmentCard.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.woodMedium,
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
              PortraitFrame(portraitUrl: character.portraitUrl),
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
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _summaryLine(character),
                      style: AppTypography.body(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _XpGauge(progress: character.xpProgress),
                  ],
                ),
              ),
            ],
          ),
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
