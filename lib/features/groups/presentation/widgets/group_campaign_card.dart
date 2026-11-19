import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/advanced_section.dart';
import '../../../../l10n/app_localizations.dart';

/// Carte « Campagne » de l'onglet Membres de l'écran Groupe (étape 4 de
/// Grimoire, spécification direction-artistique du 19/11/2026) : titre de la
/// campagne associée au groupe et, replié, son résumé public. Le titre et le
/// résumé, écrits par le MJ dans Grimoire, ne sont jamais traduits.
///
/// [title] `null` : titre identique au nom du groupe (décision n° 36), seule
/// la section du résumé est affichée. L'appelant ne monte pas la carte quand
/// [title] et [summary] sont tous deux `null` (voir
/// `GroupDetail.hasCampaignCard`).
class GroupCampaignCard extends StatelessWidget {
  const GroupCampaignCard({
    required this.title,
    required this.summary,
    super.key,
  });

  final String? title;
  final String? summary;

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    final summary = this.summary;

    // `Material` (et non un simple `Container`) : l'en-tête repliable
    // d'`AdvancedSection` est un `InkWell`, qui a besoin d'un `Material`
    // ancêtre pour son effet d'encre.
    return Material(
      color: AppColors.parchmentCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(
          color: AppColors.woodLight,
          width: AppBorders.card,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null)
              Semantics(
                header: true,
                container: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ExcludeSemantics(
                      child: Icon(
                        Icons.auto_stories,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: GroupCampaignTitleText(title: title)),
                  ],
                ),
              ),
            if (summary != null) ...[
              if (title != null) const SizedBox(height: AppSpacing.xs),
              AdvancedSection(
                key: const ValueKey('groupCampaignSummary'),
                title: AppLocalizations.of(context)!.groupCampaignSummaryToggle,
                child: Text(
                  summary,
                  style: AppTypography.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// « Campagne : {titre} » : préfixe traduit en body 14 w700 `textSecondary`,
/// titre (jamais traduit) en body 16 w800 `textPrimary`, sans limite de
/// lignes. Partagé par [GroupCampaignCard] (avec icône) et l'aperçu
/// d'invitation de `group_join_screen.dart` (sans icône).
class GroupCampaignTitleText extends StatelessWidget {
  const GroupCampaignTitleText({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: AppLocalizations.of(context)!.groupCampaignPrefix,
            style: AppTypography.body(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          TextSpan(
            text: title,
            style: AppTypography.body(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
