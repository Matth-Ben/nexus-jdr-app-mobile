import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/legal_section_block.dart';
import '../../../core/widgets/wood_back_header.dart';
import '../../../l10n/app_localizations.dart';

/// Écran "Mentions légales / CGU", route `/profile/help/legal` — poussé
/// depuis la tuile éponyme de `ProfileHelpScreen` (qui affichait auparavant
/// `_showComingSoon`, voir sa doc de classe). Contenu final rédigé et
/// validé par le chef de projet, texte affiché verbatim (jamais reformulé)
/// — voir [_sections] pour le détail.
///
/// Même gabarit exact que `ProfilePrivacyPolicyScreen` (`WoodBackHeader` +
/// corps parchemin scrollable, "gabarit texte légal long" du design système
/// : pas de carte englobante, sections rendues par [LegalSectionBlock],
/// séparées par le motif "`SizedBox(lg)` + `Divider` + `SizedBox(lg)`" —
/// voir sa doc de classe pour le rationale complet, non répété ici).
///
/// Section "Éditeur" : Matthias Benoit (renseigné le 2026-09-25, même
/// identité que la politique de confidentialité).
///
/// Lecture 100% synchrone à l'ouverture (texte statique, aucun appel
/// réseau).
class ProfileLegalScreen extends StatelessWidget {
  const ProfileLegalScreen({super.key});

  /// Contenu de l'écran, dans l'ordre d'affichage — voir la doc de classe
  /// pour le rationale du texte verbatim.
  ///
  /// Fonction plutôt qu'une constante (depuis la migration `.arb`, chantier
  /// "traduction de l'app" Phase B) : le texte dépend désormais de
  /// [AppLocalizations], qui n'est disponible qu'avec un `BuildContext`.
  static List<LegalSectionBlock> _sections(AppLocalizations l10n) => [
    LegalSectionBlock(
      title: l10n.profileLegalEditorTitle,
      paragraphs: [l10n.profileLegalEditorPara1, l10n.profileLegalEditorPara2],
    ),
    LegalSectionBlock(
      title: l10n.profileLegalHostingTitle,
      paragraphs: [l10n.profileLegalHostingPara1],
    ),
    LegalSectionBlock(
      title: l10n.profileLegalPurposeTitle,
      paragraphs: [l10n.profileLegalPurposePara1],
    ),
    LegalSectionBlock(
      title: l10n.profileLegalTermsTitle,
      paragraphs: [l10n.profileLegalTermsPara1],
    ),
    LegalSectionBlock(
      title: l10n.profileLegalIntellectualPropertyTitle,
      paragraphs: [l10n.profileLegalIntellectualPropertyPara1],
    ),
    LegalSectionBlock(
      title: l10n.profileLegalTerminationTitle,
      paragraphs: [l10n.profileLegalTerminationPara1],
    ),
    LegalSectionBlock(
      title: l10n.profileLegalGoverningLawTitle,
      paragraphs: [l10n.profileLegalGoverningLawPara1],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sections = _sections(l10n);
    return Scaffold(
      backgroundColor: AppColors.parchmentBg,
      body: Column(
        children: [
          WoodBackHeader(
            title: l10n.profileLegalScreenTitle,
            onBack: () => _goBack(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < sections.length; i++) ...[
                    sections[i],
                    if (i < sections.length - 1) const _SectionDivider(),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.profileLegalLastUpdated,
                    style: AppTypography.body(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Même garde que `ProfilePrivacyPolicyScreen._goBack` : cet écran est
  /// normalement toujours atteint via `context.push('/profile/help/legal')`
  /// (donc `canPop()` vrai), mais reste défensif si jamais poussé un jour
  /// comme route initiale (deep link).
  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }
}

/// Séparateur entre deux [LegalSectionBlock] — même motif exact que
/// `ProfilePrivacyPolicyScreen._SectionDivider` (voir sa doc pour le
/// rationale de la duplication plutôt qu'une extraction).
class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: AppSpacing.lg),
        Divider(height: 1, thickness: 1, color: AppColors.gaugeTrack),
        SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
