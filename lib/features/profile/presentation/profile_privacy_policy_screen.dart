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
/// Contenu identique à la page publique https://nexus-jdr.app/confidentialite
/// (dépôt web, `apps/web/app/confidentialite/page.tsx`, exigée par Google
/// Play) — mis à jour le 2026-09-25 (statistiques, notifications, dictée,
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
  static const List<LegalSectionBlock> _sections = [
    LegalSectionBlock(
      title: 'Introduction',
      paragraphs: [
        'Cette politique explique quelles données Nexus JDR collecte, '
            'pourquoi, avec qui elles sont partagées, et comment tu peux y '
            'accéder, les exporter ou les supprimer.',
      ],
    ),
    LegalSectionBlock(
      title: '1. Qui est responsable de tes données',
      paragraphs: [
        "Cette politique s'applique à l'application mobile Nexus JDR — "
            "Personnages (Android) et à l'application web Nexus JDR "
            '« Histoires » (nexus-jdr.app), qui partagent le même compte.',
        'Responsable du traitement : Matthias Benoit, éditeur de Nexus JDR. '
            'Contact : support@nexus-jdr.app.',
      ],
    ),
    LegalSectionBlock(
      title: '2. Données collectées',
      paragraphs: [
        '• Compte : adresse e-mail et mot de passe (le mot de passe est '
            "stocké chiffré par notre service d'authentification, nous ne le "
            'voyons jamais), pseudo affiché et avatar facultatif.',
        '• Contenu de jeu : tout ce que tu crées — personnages '
            '(caractéristiques, compétences, sorts, inventaire, apparence, '
            'histoire), journal, notes de groupe, groupes et histoires '
            'rejoints, fichiers de personnage que tu importes.',
        '• Photos : portrait de personnage, galerie et avatar, uniquement '
            "les images que tu choisis de prendre avec l'appareil photo, "
            "d'importer depuis ta galerie ou depuis une adresse web.",
        "• Dictée vocale (notes de groupe, facultative) : le micro n'est "
            'utilisé que pendant que tu dictes. La reconnaissance vocale est '
            'assurée par le service de ton téléphone (par exemple Google sur '
            'Android) ; nous ne recevons que le texte obtenu, jamais '
            "l'enregistrement audio.",
        '• Notifications : un identifiant technique de ton appareil (jeton '
            'de notification) et tes préférences de notification, pour '
            "t'envoyer les rappels et nouvelles de tes groupes.",
        "• Statistiques d'utilisation : écrans consultés et actions "
            "réalisées dans l'app, accompagnés d'informations techniques "
            "(modèle d'appareil, système, version de l'app) et d'un "
            "identifiant pseudonyme généré par l'outil de mesure. Ces "
            'statistiques ne sont pas rattachées à ton compte ni à ton '
            'adresse e-mail.',
        '• Signalements de bug : titre, description et gravité que tu '
            "saisis, version de l'app, plateforme et, si tu le choisis, le "
            'personnage concerné.',
      ],
    ),
    LegalSectionBlock(
      title: '3. Ce que nous ne collectons pas',
      paragraphs: [
        'Aucune donnée de localisation, aucun contact, aucune donnée de '
            "paiement. Aucune publicité n'est affichée et aucune donnée "
            "n'est vendue.",
      ],
    ),
    LegalSectionBlock(
      title: '4. Pourquoi nous utilisons ces données',
      paragraphs: [
        '• Fournir le service (compte, fiches, groupes, synchronisation avec '
            'ton MJ, photos, notifications que tu actives) : c’est '
            "nécessaire à l'exécution du service que tu utilises.",
        "• Améliorer l'app (statistiques d'utilisation) : intérêt légitime "
            'à comprendre quelles fonctionnalités sont utilisées. Tu peux '
            "t'y opposer à tout moment dans Profil > Confidentialité et "
            "données > Partager mes données d'usage.",
        '• Corriger les bugs que tu nous signales.',
      ],
    ),
    LegalSectionBlock(
      title: '5. Avec qui tes données sont partagées',
      paragraphs: [
        "Avec d'autres utilisateurs, uniquement à ton initiative : le MJ et "
            'les membres des histoires ou groupes que tu rejoins voient les '
            'personnages que tu y rattaches ; si tu crées un lien de partage '
            'de fiche, toute personne disposant de ce lien peut consulter la '
            "fiche en lecture seule, jusqu'à ce que tu le désactives.",
        'Avec nos prestataires techniques, qui traitent les données pour '
            'notre compte :',
        '• Supabase — hébergement de la base de données, de '
            "l'authentification et des photos.",
        '• Google Firebase — envoi des notifications (Firebase Cloud '
            "Messaging) et statistiques d'utilisation (Firebase Analytics).",
        "• PostHog (hébergement dans l'Union européenne) — statistiques "
            "d'utilisation.",
        "• GitHub — suivi des bugs signalés : le contenu d'un signalement "
            '(titre, description, gravité, version, plateforme) est publié '
            'comme ticket dans un dépôt public, sans ton adresse e-mail ni '
            "ton nom. N'y indique donc aucune information personnelle.",
        '• Vercel — hébergement du site nexus-jdr.app.',
        'Certains de ces prestataires peuvent traiter des données hors de '
            "l'Union européenne ; ces transferts sont encadrés par les "
            'garanties prévues par le RGPD (clauses contractuelles types de '
            'la Commission européenne ou cadre de protection des données '
            'UE–États-Unis).',
      ],
    ),
    LegalSectionBlock(
      title: '6. Durée de conservation',
      paragraphs: [
        '• Compte, contenu de jeu et photos : tant que ton compte existe. '
            'Ils sont supprimés définitivement dès que tu supprimes ton '
            'compte.',
        "• Statistiques d'utilisation : conservées sous forme pseudonyme, "
            'sans lien avec ton compte, pendant la durée de conservation '
            'paramétrée dans les outils de mesure.',
        '• Signalements de bug : le temps nécessaire à leur traitement.',
      ],
    ),
    LegalSectionBlock(
      title: '7. Tes droits',
      paragraphs: [
        "Conformément au RGPD, tu disposes d'un droit d'accès, de "
            "rectification, d'effacement, de portabilité, d'opposition et de "
            "limitation du traitement. Directement depuis l'app :",
        '• Exporter tes données : Profil > Confidentialité et données > '
            'Exporter mes données.',
        '• Supprimer ton compte et toutes tes données : Profil > '
            'Confidentialité et données > Supprimer mon compte.',
        "• Désactiver les statistiques d'utilisation : Profil > "
            'Confidentialité et données.',
        '• Désactiver les notifications : dans les réglages de notification '
            "de l'app ou de ton téléphone.",
        'Pour toute autre demande, écris à support@nexus-jdr.app. Tu peux '
            'aussi introduire une réclamation auprès de la CNIL '
            '(www.cnil.fr).',
      ],
    ),
    LegalSectionBlock(
      title: '8. Sécurité',
      paragraphs: [
        'Les échanges avec nos serveurs sont chiffrés (HTTPS). L’accès '
            "à tes données est protégé par l'authentification de ton compte "
            "et par des règles d'accès qui empêchent tout autre utilisateur "
            'de lire ou modifier ce que tu ne partages pas.',
      ],
    ),
    LegalSectionBlock(
      title: '9. Modifications de cette politique',
      paragraphs: [
        "Cette politique peut évoluer avec l'application. La date de "
            'dernière mise à jour figure en bas de cet écran ; en cas de '
            "changement important, tu en seras informé dans l'app.",
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
                    'Dernière mise à jour : 25 septembre 2026',
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
