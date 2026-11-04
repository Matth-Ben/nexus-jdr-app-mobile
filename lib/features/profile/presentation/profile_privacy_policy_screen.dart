import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/legal_section_block.dart';
import '../../../core/widgets/wood_back_header.dart';
import '../../../l10n/app_localizations.dart';

/// Écran "Politique de confidentialité", route `/profile/privacy/policy` —
/// poussé depuis la tuile éponyme de `ProfilePrivacyScreen` (qui affichait
/// auparavant `_showComingSoon`, voir sa doc de classe). Contenu final rédigé
/// et validé par le chef de projet, texte affiché verbatim (jamais
/// reformulé) — voir [_sections] pour le détail.
///
/// Même gabarit exact que `ProfilePrivacyScreen`/`ProfileHelpScreen`
/// (`WoodBackHeader` + corps parchemin scrollable), mais dans le "gabarit
/// texte légal long" du design système (spec direction-artistique de la
/// tâche) : pas de carte englobante, texte à plat sur `parchmentBg`, chaque
/// section rendue par [LegalSectionBlock] (titre + paragraphes) et séparée
/// de la suivante par le motif "`SizedBox(lg)` + `Divider` + `SizedBox(lg)`"
/// déjà utilisé ailleurs dans ce dépôt (ex. avant "ZONE DANGEREUSE" de
/// `ProfilePrivacyScreen`) — jamais de séparateur après la dernière section,
/// juste avant le pied de page "Dernière mise à jour".
///
/// Contenu identique à la page publique https://nexus-jdr.app/confidentialite
/// (dépôt web, `apps/web/app/confidentialite/page.tsx`, exigée par Google
/// Play) — mis à jour le 2026-11-01 (registre d'audit RGPD, A2/B4 : entrée
/// dédiée Firebase Crashlytics distincte de la ligne Firebase existante, et
/// entrée Resend pour les e-mails transactionnels Supabase Auth) ; mise à
/// jour précédente le 2026-09-25 (statistiques, notifications, dictée,
/// signalements de bug, éditeur). Les deux textes sont à garder alignés ;
/// l'écran reste affiché dans l'app, sans redirection vers le site
/// (décision utilisateur).
///
/// Lecture 100% synchrone à l'ouverture (texte statique, aucun appel
/// réseau) : ni état de chargement ni appel réseau ici, même remarque que
/// `ProfilePrivacyScreen`/`ProfileHelpScreen`.
class ProfilePrivacyPolicyScreen extends StatelessWidget {
  const ProfilePrivacyPolicyScreen({super.key});

  /// Contenu de l'écran, dans l'ordre d'affichage — voir la doc de classe
  /// pour le rationale du texte verbatim (validé par le chef de projet, non
  /// reformulable sans nouvelle validation).
  ///
  /// Fonction plutôt qu'une constante (depuis la migration `.arb`, chantier
  /// "traduction de l'app" Phase B) : le texte dépend désormais de
  /// [AppLocalizations], qui n'est disponible qu'avec un `BuildContext`.
  static List<LegalSectionBlock> _sections(AppLocalizations l10n) => [
    LegalSectionBlock(
      title: l10n.profilePrivacyPolicyIntroductionTitle,
      paragraphs: [l10n.profilePrivacyPolicyIntroductionPara1],
    ),
    LegalSectionBlock(
      title: l10n.profilePrivacyPolicySection1Title,
      paragraphs: [
        l10n.profilePrivacyPolicySection1Para1,
        l10n.profilePrivacyPolicySection1Para2,
      ],
    ),
    LegalSectionBlock(
      title: l10n.profilePrivacyPolicySection2Title,
      paragraphs: [
        l10n.profilePrivacyPolicySection2Para1,
        l10n.profilePrivacyPolicySection2Para2,
        l10n.profilePrivacyPolicySection2Para3,
        l10n.profilePrivacyPolicySection2Para4,
        l10n.profilePrivacyPolicySection2Para5,
        l10n.profilePrivacyPolicySection2Para6,
        l10n.profilePrivacyPolicySection2Para7,
      ],
    ),
    LegalSectionBlock(
      title: l10n.profilePrivacyPolicySection3Title,
      paragraphs: [l10n.profilePrivacyPolicySection3Para1],
    ),
    LegalSectionBlock(
      title: l10n.profilePrivacyPolicySection4Title,
      paragraphs: [
        l10n.profilePrivacyPolicySection4Para1,
        l10n.profilePrivacyPolicySection4Para2,
        l10n.profilePrivacyPolicySection4Para3,
      ],
    ),
    LegalSectionBlock(
      title: l10n.profilePrivacyPolicySection5Title,
      paragraphs: [
        l10n.profilePrivacyPolicySection5Para1,
        l10n.profilePrivacyPolicySection5Para2,
        l10n.profilePrivacyPolicySection5Para3,
        l10n.profilePrivacyPolicySection5Para4,
        l10n.profilePrivacyPolicySection5Para5,
        l10n.profilePrivacyPolicySection5Para6,
        l10n.profilePrivacyPolicySection5Para7,
        l10n.profilePrivacyPolicySection5Para8,
        l10n.profilePrivacyPolicySection5Para9,
        l10n.profilePrivacyPolicySection5Para10,
      ],
    ),
    LegalSectionBlock(
      title: l10n.profilePrivacyPolicySection6Title,
      paragraphs: [
        l10n.profilePrivacyPolicySection6Para1,
        l10n.profilePrivacyPolicySection6Para2,
        l10n.profilePrivacyPolicySection6Para3,
      ],
    ),
    LegalSectionBlock(
      title: l10n.profilePrivacyPolicySection7Title,
      paragraphs: [
        l10n.profilePrivacyPolicySection7Para1,
        l10n.profilePrivacyPolicySection7Para2,
        l10n.profilePrivacyPolicySection7Para3,
        l10n.profilePrivacyPolicySection7Para4,
        l10n.profilePrivacyPolicySection7Para5,
        l10n.profilePrivacyPolicySection7Para6,
      ],
    ),
    LegalSectionBlock(
      title: l10n.profilePrivacyPolicySection8Title,
      paragraphs: [l10n.profilePrivacyPolicySection8Para1],
    ),
    LegalSectionBlock(
      title: l10n.profilePrivacyPolicySection9Title,
      paragraphs: [l10n.profilePrivacyPolicySection9Para1],
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
            title: l10n.profilePrivacyPolicyScreenTitle,
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
                    l10n.profilePrivacyPolicyLastUpdated,
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

  /// Même garde que `ProfilePrivacyScreen._goBack`/`ProfileHelpScreen._goBack`
  /// : cet écran est normalement toujours atteint via
  /// `context.push('/profile/privacy/policy')` (donc `canPop()` vrai), mais
  /// reste défensif si jamais poussé un jour comme route initiale (deep
  /// link).
  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }
}

/// Séparateur entre deux [LegalSectionBlock] — même motif exact que celui
/// utilisé avant "ZONE DANGEREUSE" de `ProfilePrivacyScreen`
/// (`SizedBox(lg)` + `Divider` 1px `gaugeTrack` + `SizedBox(lg)`), non
/// extrait en composant partagé car ce motif de 3 lignes reste plus simple
/// à lire inline qu'à travers un widget dédié — même choix que
/// `ProfilePrivacyScreen`/`ProfileDeleteAccountScreen`, qui ne l'ont jamais
/// extrait non plus.
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
