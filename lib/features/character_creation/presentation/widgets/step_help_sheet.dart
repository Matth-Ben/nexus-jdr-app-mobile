import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../domain/creation_step_help.dart';

/// Ouvre l'aide contextuelle d'une étape de l'assistant de création (icône
/// "?" du bandeau bois de chaque écran d'étape) — voir
/// `docs/cahier-des-charges/11-fonctionnalites-a-ajouter.md`, section
/// "Création de personnage (assistant pas-à-pas)".
///
/// Volontairement minimale — pas le gabarit B complet (`SheetHeaderBar` +
/// contenu défilable + pied fixe) des panneaux "Infos" de la fiche
/// personnage (`spell_info_panel.dart`, `item_info_panel.dart`) : un
/// paragraphe d'explication, pas un détail technique multi-lignes, se
/// dimensionne à son contenu (`mainAxisSize.min`) plutôt que d'imposer une
/// hauteur fixe/majoritaire de l'écran. La croix de [SheetHeaderBar] suffit
/// à refermer la sheet — pas de bouton de pied dédié.
Future<void> showStepHelpSheet(
  BuildContext context,
  StepHelpContent content,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(color: AppColors.parchmentBg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeaderBar(title: content.title.toUpperCase()),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                content.body,
                style: AppTypography.body(fontSize: 14, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
