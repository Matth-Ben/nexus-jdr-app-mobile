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
/// long" du design système), avec trois particularités propres à cet écran
/// (spec direction-artistique de la tâche) :
/// - la section "Contenu de jeu" (licence étape 1, décision 79, spec
///   `docs/licence/spec-credits-nexus.md`) : un paragraphe d'introduction,
///   puis un cadre d'attribution par version du SRD ([_SrdAttributionBox] :
///   SRD 5.1 puis SRD 5.2, déclaration officielle de Wizards recopiée mot
///   pour mot + ligne « Modifié » exigée par CC BY 4.0), puis le paragraphe
///   sur le contenu hors SRD et la phrase de marque. Pas de cadre SRD 5.2.1
///   tant que Nexus n'affiche aucun texte qui en est issu (arbitrage 3.2 de
///   la spec). Ces deux derniers paragraphes reprennent le style des
///   paragraphes de [LegalSectionBlock] sans le modifier (partagé par trois
///   écrans).
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
/// réseau). Tout le corps est dans un `SelectionArea` : les adresses des
/// déclarations ne sont pas cliquables (zone de tap trop petite), un appui
/// long permet de les copier.
class ProfileCreditsScreen extends StatelessWidget {
  const ProfileCreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gameContentSection = LegalSectionBlock(
      title: l10n.profileCreditsGameContentTitle,
      paragraphs: [l10n.profileCreditsGameContentPara1],
    );
    final paragraphStyle = AppTypography.body(
      fontSize: 13,
      color: AppColors.textPrimary,
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
              child: SelectionArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    gameContentSection,
                    const SizedBox(height: AppSpacing.md),
                    _SrdAttributionBox(
                      label: l10n.profileCreditsSrd51Label,
                      attribution: l10n.profileCreditsSrd51Attribution,
                      modified: l10n.profileCreditsSrd51Modified,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Déclaration anglaise telle quelle dans les deux
                    // langues (arbitrage 3.1 de la spec).
                    _SrdAttributionBox(
                      label: l10n.profileCreditsSrd52Label,
                      attribution: l10n.profileCreditsSrd52Attribution,
                      modified: l10n.profileCreditsSrd52Modified,
                      attributionLocale: const Locale('en'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.profileCreditsNonSrdContent,
                      style: paragraphStyle,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.profileCreditsGameContentPara2,
                      style: paragraphStyle,
                    ),
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

/// Cadre d'attribution d'une version du SRD (section "Contenu de jeu") :
/// libellé, déclaration officielle de Wizards ([attribution], recopiée mot
/// pour mot, jamais traduite) et ligne « Modifié » ([modified], exigée par
/// CC BY 4.0). Distinct visuellement du reste du texte légal sans ressembler
/// à une tuile tappable : fond `AppColors.parchmentCardAlt` (le token de fond
/// "légèrement différent" le plus proche déjà existant, jamais un nouveau
/// token de couleur), bordure fine `AppColors.woodLight` 1px
/// ([AppBorders.cardEmphasisHalo], seul token de largeur de bordure à 1px
/// déjà défini par [AppBorders] — les autres, `card`/`cardEmphasis`, valent
/// 2px/3px), pas de `Material`/`InkWell` (jamais tappable), pleine largeur
/// pour que les cadres aient tous la même.
///
/// Jamais `textMuted` dans le cadre (4,41:1 sur `parchmentCardAlt`, échec
/// AA) : `textSecondary` (6,5:1) pour la déclaration et la ligne « Modifié ».
/// Ni `maxLines` ni ellipse : le texte légal s'affiche toujours en entier.
class _SrdAttributionBox extends StatelessWidget {
  const _SrdAttributionBox({
    required this.label,
    required this.attribution,
    required this.modified,
    this.attributionLocale,
  });

  final String label;
  final String attribution;
  final String modified;

  /// Langue de [attribution] quand elle diffère de celle de l'interface
  /// (déclaration anglaise du SRD 5.2 dans l'app en français), pour que le
  /// lecteur d'écran la prononce dans la bonne langue. `null` : langue de
  /// l'interface.
  final Locale? attributionLocale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      container: true,
      child: SizedBox(
        width: double.infinity,
        child: DecoratedBox(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.body(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text.rich(
                  TextSpan(text: attribution, locale: attributionLocale),
                  style: AppTypography.body(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: l10n.profileCreditsModifiedPrefix,
                        style: AppTypography.body(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextSpan(
                        text: modified,
                        style: AppTypography.body(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
