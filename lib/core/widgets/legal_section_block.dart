import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Bloc "titre + paragraphes" du gabarit "texte légal long" (spec
/// direction-artistique des écrans "Politique de confidentialité"/"Mentions
/// légales / CGU"/"Crédits & licences") : un titre de section (`font.body`
/// 15px/800 `textPrimary`) suivi d'un ou plusieurs paragraphes (`font.body`
/// 13px/400 `textPrimary`), chacun séparé du précédent (titre inclus) par un
/// `SizedBox(height: AppSpacing.sm)`.
///
/// Extrait directement en composant partagé (`core/widgets/`) plutôt que
/// dupliqué puis refactoré au 3e usage : `ProfilePrivacyPolicyScreen`,
/// `ProfileLegalScreen` et la section "Contenu de jeu" de
/// `ProfileCreditsScreen` (ses 3 seuls usages à ce jour) sont tous introduits
/// dans la même tâche, pas de raison de différer l'extraction.
///
/// Ne porte aucune carte englobante ni séparateur : c'est à l'écran appelant
/// d'empiler plusieurs [LegalSectionBlock] séparés du motif
/// "`SizedBox(lg)` + `Divider` + `SizedBox(lg)`" déjà utilisé ailleurs dans
/// ce dépôt (ex. avant "ZONE DANGEREUSE" de `ProfilePrivacyScreen`) entre
/// deux sections.
class LegalSectionBlock extends StatelessWidget {
  const LegalSectionBlock({
    required this.title,
    required this.paragraphs,
    super.key,
  });

  /// Titre de la section (ex. "Introduction", "Données collectées"...).
  final String title;

  /// Un ou plusieurs paragraphes affichés dans l'ordre, chacun sur son
  /// propre `Text` (jamais concaténés en un seul bloc) pour préserver le
  /// même espacement `AppSpacing.sm` entre chacun d'eux qu'entre le titre et
  /// le premier paragraphe.
  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.body(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        for (final paragraph in paragraphs) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            paragraph,
            style: AppTypography.body(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ],
    );
  }
}
