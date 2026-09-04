import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/network/connectivity_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/alert_banner.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../providers/data_export_providers.dart';

/// Ouvre la sheet "Export de mes données" (tuile "Export de mes données" de
/// `presentation/profile_privacy_screen.dart`) — sheet compacte (wrap-content,
/// même famille que `change_password_sheet.dart`) qui génère elle-même le
/// fichier JSON (`DataExportRepository.exportMyData`) et n'appelle
/// `Navigator.pop` qu'une fois celui-ci résolu (même pattern "attend le
/// résultat réseau sur place" que `report_bug_sheet.dart`), en retournant le
/// **chemin du fichier généré** plutôt qu'un simple booléen.
///
/// Split de responsabilité volontaire (spec direction-artistique de la
/// tâche) : cette fonction ouvrante, pas la sheet elle-même, déclenche le
/// partage natif (`share_plus`) puis affiche le `SnackBar` de confirmation —
/// même split que `showReportBugSheet` (SnackBar affiché par l'appelant sur
/// son propre [BuildContext], pas celui — éphémère — de la sheet), étendu
/// ici avec une étape de partage intermédiaire.
Future<void> showExportDataSheet(BuildContext context) async {
  final filePath = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // Même rationale que `report_bug_sheet.dart`/`change_password_sheet.dart` :
    // ne se ferme que via ses propres boutons, jamais par le voile/le swipe/
    // le geste retour Android, qui contourneraient `closeEnabled:
    // !_isGenerating` pendant la génération.
    isDismissible: false,
    enableDrag: false,
    builder: (sheetContext) => const _ExportDataSheetContent(),
  );
  if (filePath == null || !context.mounted) return;

  await SharePlus.instance.share(ShareParams(files: [XFile(filePath)]));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('Export généré.')));
}

/// Hors-ligne (vérifié *avant* l'appel réseau) — même texte que
/// `change_password_sheet.dart`/`report_bug_sheet.dart`, pas de file
/// d'attente hors-ligne pour cette lecture.
const String _offlineMessage =
    "Hors ligne : cette action n'a pas pu être enregistrée. Réessayez une "
    'fois reconnecté.';

const String _genericErrorMessage =
    "Impossible de générer l'export. Réessayez.";

class _ExportDataSheetContent extends ConsumerStatefulWidget {
  const _ExportDataSheetContent();

  @override
  ConsumerState<_ExportDataSheetContent> createState() =>
      _ExportDataSheetContentState();
}

class _ExportDataSheetContentState
    extends ConsumerState<_ExportDataSheetContent> {
  bool _isGenerating = false;
  String? _errorMessage;

  Future<void> _generate() async {
    if (_isGenerating) return;
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    // Vérifié *avant* toute tentative réseau — voir la documentation de
    // [_offlineMessage]. La génération interroge le réseau en direct (jamais
    // le cache local, décision chef de projet), voir la doc de classe de
    // `DataExportRepository.exportMyData`.
    if (!await ref.read(connectivityCheckerProvider).hasConnection()) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _errorMessage = _offlineMessage;
      });
      return;
    }

    try {
      final filePath = await ref
          .read(dataExportRepositoryProvider)
          .exportMyData();
      if (!mounted) return;
      Navigator.of(context).pop(filePath);
    } catch (error) {
      // Voir la documentation de [_genericErrorMessage] : le détail de
      // l'échec n'est jamais affiché tel quel, seulement journalisé pour le
      // diagnostic.
      debugPrint('ExportDataSheet._generate: erreur inattendue: $error');
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _errorMessage = _genericErrorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Voir `change_password_sheet.dart` pour le rationale complet de ce
    // `PopScope` (seul garde-fou qui couvre le geste retour Android, chemin
    // entièrement distinct du voile/du drag bloqués par
    // `isDismissible`/`enableDrag` de `showExportDataSheet`).
    return PopScope(
      canPop: !_isGenerating,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DecoratedBox(
            decoration: const BoxDecoration(color: AppColors.parchmentBg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SheetHeaderBar(
                  title: 'EXPORT DE MES DONNÉES',
                  closeEnabled: !_isGenerating,
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_errorMessage != null) ...[
                        AlertBanner(message: _errorMessage!),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      Text(
                        'Génère un fichier JSON contenant tous tes '
                        'personnages et leurs données associées '
                        '(inventaire, sorts, historique). Le fichier te '
                        'sera proposé au partage/enregistrement depuis ton '
                        'appareil.',
                        style: AppTypography.body(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          label: 'Annuler',
                          surface: SecondaryButtonSurface.parchment,
                          onPressed: _isGenerating
                              ? null
                              : () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: PrimaryButton(
                          label: "Générer l'export",
                          isLoading: _isGenerating,
                          onPressed: _generate,
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
