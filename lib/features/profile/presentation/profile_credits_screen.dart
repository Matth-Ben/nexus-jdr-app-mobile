import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/legal_section_block.dart';
import '../../../core/widgets/wood_back_header.dart';

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
///
/// Lecture 100% synchrone à l'ouverture (texte statique, aucun appel
/// réseau).
class ProfileCreditsScreen extends StatelessWidget {
  const ProfileCreditsScreen({super.key});

  static const LegalSectionBlock _gameContentSection = LegalSectionBlock(
    title: 'Contenu de jeu',
    paragraphs: [
      'Le contenu de règles Donjons & Dragons 5e (races, classes, '
          'historiques, sorts, objets, monstres...) provient d\'Open5e et '
          'du System Reference Document (SRD 5.1/5.2) de Wizards of the '
          'Coast, sous licence Creative Commons Attribution 4.0 '
          'International (CC-BY 4.0).',
      'Donjons & Dragons, D&D et leurs logos sont des marques de Wizards '
          "of the Coast LLC. Wizards of the Coast n'a ni produit, ni "
          'approuvé, ni autorisé cette application.',
    ],
  );

  static const LegalSectionBlock _openSourceSection = LegalSectionBlock(
    title: 'Bibliothèques open source',
    paragraphs: [
      'Flutter · Riverpod · Supabase Flutter · Drift · Freezed · '
          'go_router · google_fonts · image_picker · file_picker · '
          'connectivity_plus · package_info_plus · share_plus · '
          'app_settings · url_launcher · Firebase (Core, Messaging) · '
          'shared_preferences',
      'Ainsi que les autres bibliothèques listées dans le fichier '
          'pubspec.yaml du projet, chacune sous sa licence open source '
          "d'origine.",
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.parchmentBg,
      body: Column(
        children: [
          WoodBackHeader(
            title: 'CRÉDITS & LICENCES',
            onBack: () => _goBack(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _gameContentSection,
                  const SizedBox(height: AppSpacing.lg),
                  const _LicenseNoticeBox(),
                  const _SectionDivider(),
                  _openSourceSection,
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Dernière mise à jour : 15 septembre 2026',
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
          'Ce produit inclut des éléments du System Reference Document '
          '5.1 et 5.2, disponibles sur dndbeyond.com/srd et open5e.com, '
          'sous licence Creative Commons Attribution 4.0 International '
          '(creativecommons.org/licenses/by/4.0/legalcode).',
          style: AppTypography.body(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
