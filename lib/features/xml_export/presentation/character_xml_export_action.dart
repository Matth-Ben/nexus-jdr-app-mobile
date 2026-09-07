import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../characters/domain/character_detail.dart';
import '../data/xml_character_exporter.dart';

/// Point d'entrée "Exporter en XML" de la fiche personnage
/// (`characters/presentation/character_detail_screen.dart`, bouton
/// `WoodBackHeader.trailing` de l'onglet "Personnage") — génère le fichier
/// via [XmlCharacterExporter], l'écrit dans un répertoire temporaire
/// (`path_provider`) puis le propose au partage natif (`share_plus`), même
/// patron exact que
/// `profile/presentation/widgets/export_data_sheet.dart::showExportDataSheet`
/// (`SharePlus.instance.share(ShareParams(files: [XFile(filePath)]))`).
///
/// Si [detail] est multiclassé (voir
/// [XmlCharacterExporter.hasUnsupportedMulticlass]), avertit l'utilisateur
/// *avant* de générer quoi que ce soit (dialogue "Annuler"/"Exporter la
/// classe principale") plutôt que de produire un fichier silencieusement
/// tronqué — voir la documentation de classe de [XmlCharacterExporter] pour
/// le rationale complet (le format aidedd.org ne modélise qu'une seule
/// classe par personnage).
Future<void> exportCharacterAsXml(
  BuildContext context,
  CharacterDetail detail,
) async {
  if (XmlCharacterExporter.hasUnsupportedMulticlass(detail)) {
    final confirmed = await _showMulticlassWarningDialog(context, detail);
    if (confirmed != true || !context.mounted) return;
  }

  try {
    final xmlContent = XmlCharacterExporter.export(detail);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/${_fileNameFor(detail.name)}');
    await file.writeAsString(xmlContent);
    if (!context.mounted) return;
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  } catch (error) {
    // Même principe que `export_data_sheet.dart::_genericErrorMessage` : le
    // détail de l'échec n'est jamais affiché tel quel, seulement journalisé
    // pour le diagnostic.
    debugPrint('exportCharacterAsXml: erreur inattendue: $error');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Impossible de générer l'export XML. Réessayez."),
      ),
    );
  }
}

/// `{nom du personnage}.xml`, nom de fichier assaini (aucun des caractères
/// interdits par les systèmes de fichiers usuels — Windows est le plus
/// restrictif des deux OS visés, voir `13-depot-versioning-publication.md`)
/// — un nom de personnage entièrement composé de tels caractères (cas
/// dégénéré) retombe sur "personnage.xml" plutôt qu'un nom de fichier vide.
String _fileNameFor(String characterName) {
  final sanitized = characterName
      .trim()
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
      .replaceAll(RegExp(r'\s+'), '_');
  return '${sanitized.isEmpty ? 'personnage' : sanitized}.xml';
}

/// Dialogue d'avertissement "Personnage multiclassé" — calque visuel de
/// `characters/presentation/widgets/portrait_upload_sheet.dart::
/// showRemovePortraitConfirmationDialog` (`Dialog` + `parchmentCard`, mêmes
/// tokens). Retourne `true` si le joueur confirme malgré tout l'export
/// (classe primaire uniquement), `false`/`null` sinon.
Future<bool?> _showMulticlassWarningDialog(
  BuildContext context,
  CharacterDetail detail,
) {
  final primaryClassName = detail.primaryClass?.className ?? 'principale';
  return showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: AppColors.parchmentCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(
          color: AppColors.woodLight,
          width: AppBorders.card,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personnage multiclassé',
              style: AppTypography.body(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Le format XML compatible aidedd.org ne prend en charge '
              "qu'une seule classe par personnage. Seule la classe "
              '$primaryClassName sera exportée, les autres classes de ce '
              'personnage seront absentes du fichier généré.',
              style: AppTypography.body(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Annuler',
                    surface: SecondaryButtonSurface.parchment,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: PrimaryButton(
                    label: 'Exporter quand même',
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
