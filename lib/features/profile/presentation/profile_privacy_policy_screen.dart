import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/legal_section_block.dart';
import '../../../core/widgets/wood_back_header.dart';

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
/// Le placeholder `[À COMPLÉTER : identité de l'éditeur]` (section "Contact
/// et éditeur") est affiché tel quel, verbatim depuis le contenu validé par
/// le chef de projet — pas encore résolu, à mettre à jour manuellement dans
/// [_sections] dès que l'identité légale de l'éditeur sera arrêtée.
///
/// Lecture 100% synchrone à l'ouverture (texte statique, aucun appel
/// réseau) : ni état de chargement ni appel réseau ici, même remarque que
/// `ProfilePrivacyScreen`/`ProfileHelpScreen`.
class ProfilePrivacyPolicyScreen extends StatelessWidget {
  const ProfilePrivacyPolicyScreen({super.key});

  /// Contenu de l'écran, dans l'ordre d'affichage — voir la doc de classe
  /// pour le rationale du texte verbatim (validé par le chef de projet, non
  /// reformulable sans nouvelle validation).
  static const List<LegalSectionBlock> _sections = [
    LegalSectionBlock(
      title: 'Introduction',
      paragraphs: [
        'Cette politique explique quelles données Nexus JDR — Personnages '
            'collecte, pourquoi, et comment tu peux y accéder, les exporter '
            "ou les supprimer. Elle s'applique à cette application ainsi "
            "qu'à l'app web « Histoires », qui partagent le même compte.",
      ],
    ),
    LegalSectionBlock(
      title: 'Données collectées',
      paragraphs: [
        'Compte : adresse e-mail (authentification), pseudo affiché.',
        'Photos : portrait de personnage, avatar de profil (facultatifs, '
            "ajoutés uniquement si tu choisis d'en importer un).",
        'Contenu de jeu : personnages, caractéristiques, inventaire, sorts, '
            "journal, historique — tout ce que tu crées dans l'app.",
        'Aucune donnée de localisation, de contact ni de paiement '
            "n'est collectée.",
      ],
    ),
    LegalSectionBlock(
      title: 'Pourquoi ces données',
      paragraphs: [
        "L'e-mail identifie ton compte et sécurise la connexion. Les photos "
            'personnalisent ta fiche de personnage et ton profil. Le '
            'contenu de jeu permet de gérer tes personnages et de les '
            "synchroniser avec ton MJ dans l'app « Histoires ».",
      ],
    ),
    LegalSectionBlock(
      title: 'Stockage et hébergement',
      paragraphs: [
        'Toutes les données sont stockées chez Supabase (base de données, '
            'authentification, stockage des fichiers), notre prestataire '
            "technique. Aucune donnée n'est vendue ni partagée avec des "
            'annonceurs.',
      ],
    ),
    LegalSectionBlock(
      title: 'Conservation',
      paragraphs: [
        'Tes données sont conservées tant que ton compte existe. Elles '
            'sont supprimées définitivement, avec tes photos, dès que tu '
            'supprimes ton compte.',
      ],
    ),
    LegalSectionBlock(
      title: 'Tes droits',
      paragraphs: [
        'Tu peux à tout moment : exporter une copie de tes données '
            '(Profil > Confidentialité et données > Exporter mes données) ; '
            'supprimer ton compte et toutes tes données (Profil > '
            'Confidentialité et données > Supprimer mon compte) ; nous '
            'contacter pour toute question sur tes données.',
      ],
    ),
    LegalSectionBlock(
      title: 'Sécurité',
      paragraphs: [
        'Les échanges avec le serveur sont chiffrés (HTTPS). L\'accès à '
            'tes données est protégé par l\'authentification de ton compte.',
      ],
    ),
    LegalSectionBlock(
      title: 'Contact et éditeur',
      paragraphs: [
        'Pour toute question : support@nexus-jdr.app',
        '[À COMPLÉTER : identité de l\'éditeur]',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.parchmentBg,
      body: Column(
        children: [
          WoodBackHeader(
            title: 'POLITIQUE DE CONFIDENTIALITÉ',
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
