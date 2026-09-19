import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/legal_section_block.dart';
import '../../../core/widgets/wood_back_header.dart';

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
/// Le placeholder `[À COMPLÉTER : identité de l'éditeur]` (section
/// "Éditeur") est affiché tel quel, verbatim depuis le contenu validé par
/// le chef de projet — même remarque que
/// `ProfilePrivacyPolicyScreen._sections`.
///
/// Lecture 100% synchrone à l'ouverture (texte statique, aucun appel
/// réseau).
class ProfileLegalScreen extends StatelessWidget {
  const ProfileLegalScreen({super.key});

  /// Contenu de l'écran, dans l'ordre d'affichage — voir la doc de classe
  /// pour le rationale du texte verbatim.
  static const List<LegalSectionBlock> _sections = [
    LegalSectionBlock(
      title: 'Éditeur',
      paragraphs: [
        '[À COMPLÉTER : identité de l\'éditeur]',
        'Contact : support@nexus-jdr.app',
      ],
    ),
    LegalSectionBlock(
      title: 'Hébergement',
      paragraphs: [
        "L'application et ses données sont hébergées par Supabase (base "
            'de données, authentification, stockage des fichiers).',
      ],
    ),
    LegalSectionBlock(
      title: "Objet de l'application",
      paragraphs: [
        'Nexus JDR — Personnages permet de créer, importer et gérer des '
            'personnages de Donjons & Dragons 5e, seul ou synchronisé avec '
            "l'app « Histoires » utilisée par ton Maître du Jeu.",
      ],
    ),
    LegalSectionBlock(
      title: "Conditions d'utilisation",
      paragraphs: [
        "L'usage de l'application nécessite un compte. Tu es responsable "
            'de l\'exactitude des informations que tu y renseignes et de '
            'la confidentialité de tes identifiants. L\'éditeur se réserve '
            "le droit de suspendre un compte en cas d'usage abusif.",
      ],
    ),
    LegalSectionBlock(
      title: 'Propriété intellectuelle',
      paragraphs: [
        'Le contenu de règles Donjons & Dragons 5e (races, classes, '
            "sorts, objets...) provient d'Open5e et du System Reference "
            'Document (SRD), sous licence Creative Commons Attribution '
            '4.0 (CC-BY 4.0) — voir « Crédits & licences » pour le détail. '
            'Le reste de l\'application (code, design, marque '
            '« Nexus JDR ») appartient à son éditeur.',
      ],
    ),
    LegalSectionBlock(
      title: 'Résiliation',
      paragraphs: [
        'Tu peux supprimer ton compte à tout moment depuis Profil > '
            'Confidentialité et données > Supprimer mon compte.',
      ],
    ),
    LegalSectionBlock(
      title: 'Droit applicable',
      paragraphs: ['Ces mentions sont soumises au droit français.'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.parchmentBg,
      body: Column(
        children: [
          WoodBackHeader(
            title: 'MENTIONS LÉGALES / CGU',
            onBack: () => _goBack(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < _sections.length; i++) ...[
                    _sections[i],
                    if (i < _sections.length - 1) const _SectionDivider(),
                  ],
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
