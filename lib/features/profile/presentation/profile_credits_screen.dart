import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/legal_section_block.dart';
import '../../../core/widgets/wood_back_header.dart';
import '../../../l10n/app_localizations.dart';

/// Écran "Crédits & licences", route `/profile/help/credits` — poussé
/// depuis la tuile éponyme de `ProfileHelpScreen` (qui affichait auparavant
/// `_showComingSoon`, voir sa doc de classe). Contenu final rédigé et
/// validé par le chef de projet, texte affiché verbatim (jamais reformulé).
///
/// Même gabarit exact que `ProfilePrivacyPolicyScreen`/`ProfileLegalScreen`
/// (`WoodBackHeader` + corps parchemin scrollable, "gabarit texte légal
/// long" du design système), avec deux particularités propres à cet écran
/// (spec direction-artistique de la tâche) :
/// - la section "Contenu de jeu" ([_gameContentSection]) est suivie d'un
///   bloc encadré supplémentaire ([_LicenseNoticeBox], texte légal formel
///   de la licence CC-BY, distinct visuellement du reste — fond
///   `AppColors.parchmentCardAlt`, bordure fine 1px `AppColors.woodLight`
///   ([AppBorders.cardEmphasisHalo], le token 1px le plus proche du design
///   système existant) — plutôt qu'une carte tappable comme `MenuTile`.
/// - la section "Bibliothèques open source" ([_openSourceSection]) n'est
///   pas une vraie liste de lignes séparées (pas de `SettingsListCard`,
///   spec de la tâche) : le nom des bibliothèques est affiché en un seul
///   paragraphe énuméré par des « · », suivi d'un second paragraphe de
///   clôture — les deux au même style `font.body` 13px `textPrimary` que
///   n'importe quel paragraphe de [LegalSectionBlock], pas de composant
///   dédié à cette liste.
/// - la section "Polices" ([_fontsSection]) suit le même gabarit que
///   "Contenu de jeu" (licence + source citées en toutes lettres dans le
///   paragraphe, pas de composant dédié) plutôt que la liste à puces
///   "Bibliothèques open source" : les polices ne sont plus chargées par un
///   package (`google_fonts`, retiré de `pubspec.yaml` — dette D22,
///   `docs/dette-technique.md`) mais embarquées en asset
///   (`assets/fonts/`), donc listées à part de la liste de bibliothèques.
///
/// Lecture 100% synchrone à l'ouverture (texte statique, aucun appel
/// réseau).
class ProfileCreditsScreen extends StatelessWidget {
  const ProfileCreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gameContentSection = LegalSectionBlock(
      title: l10n.profileCreditsGameContentTitle,
      paragraphs: [
        l10n.profileCreditsGameContentPara1,
        l10n.profileCreditsGameContentPara2,
      ],
    );
    final openSourceSection = LegalSectionBlock(
      title: l10n.profileCreditsOpenSourceTitle,
      paragraphs: [
        l10n.profileCreditsOpenSourcePara1,
        l10n.profileCreditsOpenSourcePara2,
      ],
    );
    final fontsSection = LegalSectionBlock(
      title: l10n.profileCreditsFontsTitle,
      paragraphs: [l10n.profileCreditsFontsPara1],
    );

    return Scaffold(
      backgroundColor: AppColors.parchmentBg,
      body: Column(
        children: [
          WoodBackHeader(
            title: l10n.profileCreditsScreenTitle,
            onBack: () => _goBack(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  gameContentSection,
                  const SizedBox(height: AppSpacing.lg),
                  const _LicenseNoticeBox(),
                  const _SectionDivider(),
                  fontsSection,
                  const _SectionDivider(),
                  openSourceSection,
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.profileCreditsLastUpdated,
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
  /// normalement toujours atteint via `context.push('/profile/help/credits')`
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

/// Séparateur entre deux sections — même motif exact que
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

/// Bloc encadré de la licence CC-BY formelle (section "Contenu de jeu") —
/// distinct visuellement du reste du texte légal (spec direction-
/// artistique de la tâche : "juste pour distinguer visuellement ce
/// paragraphe de licence formel du reste, sans que ça ressemble à une
/// tuile tappable") : fond `AppColors.parchmentCardAlt` (le token de fond
/// "légèrement différent" le plus proche déjà existant, jamais un nouveau
/// token de couleur), bordure fine `AppColors.woodLight` 1px
/// ([AppBorders.cardEmphasisHalo], seul token de largeur de bordure à 1px
/// déjà défini par [AppBorders] — les autres, `card`/`cardEmphasis`, valent
/// 2px/3px), pas de `Material`/`InkWell` (jamais tappable).
class _LicenseNoticeBox extends StatelessWidget {
  const _LicenseNoticeBox();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.parchmentCardAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.woodLight,
          width: AppBorders.cardEmphasisHalo,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          l10n.profileCreditsLicenseNotice,
          style: AppTypography.body(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
