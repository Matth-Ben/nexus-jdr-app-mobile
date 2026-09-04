import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/connectivity_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/alert_banner.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/selectable_option_tile.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../../bug_report/presentation/providers/bug_report_providers.dart';

/// Ouvre la sheet "Signaler un bug" (tuile "Signaler un bug" de
/// `profile_screen.dart`) — sheet autoportante calquée sur
/// `character_story_edit_sheet.dart` (voir sa documentation de classe pour le
/// rationale complet du pattern "attend le résultat réseau sur place") :
/// envoie elle-même `BugReportRepository.submitReport` et n'appelle
/// `Navigator.pop` qu'une fois celui-ci résolu.
///
/// [characterId] : paramètre optionnel, toujours `null` pour cet incrément
/// (spec direction-artistique de la tâche section 6 — aucun second point
/// d'entrée depuis la fiche personnage pour l'instant), déjà câblé jusqu'au
/// corps de la requête pour ne pas avoir à retoucher cette signature le jour
/// où ce second point d'entrée sera demandé.
///
/// Même split de responsabilité que `showCharacterStoryEditSheet`/
/// `showEditDisplayNameSheet` : cette fonction ouvrante affiche le
/// `SnackBar` de confirmation une fois la sheet refermée avec succès
/// (`pop(true)`), sur le [BuildContext] de l'écran appelant plutôt que celui
/// — éphémère — de la sheet.
Future<void> showReportBugSheet(
  BuildContext context, {
  String? characterId,
}) async {
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // Même rationale que `character_story_edit_sheet.dart` : ne se ferme que
    // via ses propres boutons, jamais par le voile/le swipe/le geste retour
    // Android, qui contourneraient `closeEnabled: !_isSaving` pendant
    // l'appel réseau `submitReport`.
    isDismissible: false,
    enableDrag: false,
    builder: (sheetContext) => _ReportBugSheetContent(characterId: characterId),
  );
  if (sent != true || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Merci, ton signalement a bien été envoyé !')),
  );
}

/// Une des 3 sévérités proposées (`SelectableOptionTile`, spec
/// direction-artistique de la tâche) — [value] porte la valeur technique du
/// contrat `report-bug` (`mineur`/`majeur`/`bloquant`), jamais [title]
/// (libellé affiché, plus explicite que le vocabulaire serveur).
class _SeverityOption {
  const _SeverityOption({
    required this.value,
    required this.title,
    required this.subtitle,
  });

  final String value;
  final String title;
  final String subtitle;
}

/// Ordre d'affichage fixe (spec direction-artistique de la tâche) — la
/// première entrée (`mineur`) est la sélection par défaut de la sheet.
const List<_SeverityOption> _severityOptions = [
  _SeverityOption(
    value: 'mineur',
    title: 'Gênant',
    subtitle: 'Un désagrément, mais tu peux continuer à jouer',
  ),
  _SeverityOption(
    value: 'majeur',
    title: 'Problématique',
    subtitle: 'Ça complique les choses, mais il y a moyen de contourner',
  ),
  _SeverityOption(
    value: 'bloquant',
    title: 'Ça bloque tout',
    subtitle: 'Impossible de continuer sans ça',
  ),
];

/// Hors-ligne (vérifié *avant* l'appel réseau, voir
/// [_ReportBugSheetContentState._submit]) — même texte que
/// `edit_display_name_sheet.dart`/`character_story_edit_sheet.dart`, pas de
/// file d'attente hors-ligne pour cette écriture (spec de la tâche).
const String _offlineMessage =
    "Hors ligne : cette action n'a pas pu être enregistrée. Réessayez une "
    'fois reconnecté.';

/// Erreur générique/inattendue (4xx/5xx HTTP, exception) — texte fixe unique
/// quel que soit le détail de l'échec (spec direction-artistique de la
/// tâche : contrairement à `edit_display_name_sheet.dart`, jamais
/// `BugReportFailure.message`, qui n'est porté que pour le diagnostic).
const String _genericErrorMessage =
    "Impossible d'envoyer le signalement. Réessayez.";

/// Gabarit B autoportant (`showModalBottomSheet`, `isScrollControlled: true`,
/// `FractionallySizedBox(heightFactor: 0.92)`) : `SheetHeaderBar`, 2 champs
/// texte + sélecteur de sévérité, pied fixe "Annuler"/"Envoyer".
///
/// `ConsumerStatefulWidget` — appelle elle-même
/// `ref.read(bugReportRepositoryProvider).submitReport(...)` au tap
/// "Envoyer" et **attend le résultat avant de se fermer**, même pattern que
/// `character_story_edit_sheet.dart`/`edit_display_name_sheet.dart` : en cas
/// d'échec, la saisie reste intacte et un bandeau d'alerte inline (jamais un
/// `SnackBar`) explique l'échec, pour que le joueur puisse retenter
/// "Envoyer" sans retaper.
class _ReportBugSheetContent extends ConsumerStatefulWidget {
  const _ReportBugSheetContent({this.characterId});

  final String? characterId;

  @override
  ConsumerState<_ReportBugSheetContent> createState() =>
      _ReportBugSheetContentState();
}

class _ReportBugSheetContentState
    extends ConsumerState<_ReportBugSheetContent> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  String _severity = _severityOptions.first.value;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController()..addListener(_handleChanged);
    _descriptionController = TextEditingController()
      ..addListener(_handleChanged);
  }

  @override
  void dispose() {
    _titleController.removeListener(_handleChanged);
    _titleController.dispose();
    _descriptionController.removeListener(_handleChanged);
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleChanged() {
    if (mounted) setState(() {});
  }

  /// "Envoyer" activé seulement si titre et description sont tous les deux
  /// non blancs (spec de la tâche) — la sévérité a toujours une valeur par
  /// défaut, jamais bloquante.
  bool get _canSubmit =>
      _titleController.text.trim().isNotEmpty &&
      _descriptionController.text.trim().isNotEmpty;

  void _selectSeverity(String value) {
    if (_isSaving) return;
    setState(() => _severity = value);
  }

  Future<void> _submit() async {
    if (_isSaving || !_canSubmit) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    // Vérifié *avant* toute tentative réseau — voir la documentation de
    // [_offlineMessage] : pas de file d'attente hors-ligne pour cette
    // écriture.
    if (!await ref.read(connectivityCheckerProvider).hasConnection()) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = _offlineMessage;
      });
      return;
    }

    try {
      await ref
          .read(bugReportRepositoryProvider)
          .submitReport(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            severity: _severity,
            characterId: widget.characterId,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      // Voir la documentation de [_genericErrorMessage] : le détail de
      // l'échec (`BugReportFailure.message`, une exception réseau...) n'est
      // jamais affiché tel quel, seulement journalisé pour le diagnostic.
      debugPrint('ReportBugSheet._submit: erreur inattendue: $error');
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = _genericErrorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Voir `character_story_edit_sheet.dart` pour le rationale complet de ce
    // `PopScope` (seul garde-fou qui couvre le geste retour Android, chemin
    // entièrement distinct du voile/du drag bloqués par
    // `isDismissible`/`enableDrag` de `showReportBugSheet`).
    return PopScope(
      canPop: !_isSaving,
      child: SafeArea(
        top: false,
        child: FractionallySizedBox(
          heightFactor: 0.92,
          child: Container(
            color: AppColors.parchmentBg,
            child: Column(
              children: [
                SheetHeaderBar(
                  title: 'SIGNALER UN BUG',
                  closeEnabled: !_isSaving,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_errorMessage != null) ...[
                          AlertBanner(message: _errorMessage!),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        // Pendant l'envoi : champs texte + sélecteur de
                        // sévérité grisés et non interactifs — au-delà du
                        // pattern strict des 2 sheets précédentes (qui ne
                        // désactivent que boutons/en-tête, jamais les champs
                        // eux-mêmes), justifié ici par la présence d'un
                        // sélecteur plus risqué à toucher par erreur pendant
                        // l'attente réseau (spec direction-artistique de la
                        // tâche, explicitement non rétroactive aux 2 sheets
                        // existantes).
                        IgnorePointer(
                          key: const Key('reportBugFieldsIgnorePointer'),
                          ignoring: _isSaving,
                          child: Opacity(
                            opacity: _isSaving ? 0.6 : 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TITRE',
                                  style: AppTypography.body(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                TextFormField(
                                  controller: _titleController,
                                  minLines: 1,
                                  maxLines: 1,
                                  decoration: const InputDecoration(
                                    hintText:
                                        'Résumé en une phrase (ex. « Le '
                                        'bouton PV ne répond pas »)',
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  'DESCRIPTION',
                                  style: AppTypography.body(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                TextFormField(
                                  controller: _descriptionController,
                                  minLines: 3,
                                  maxLines: null,
                                  decoration: const InputDecoration(
                                    hintText:
                                        "Que s'est-il passé ? Que "
                                        'faisais-tu au moment du bug ?',
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  'À QUEL POINT ÇA TE BLOQUE ?',
                                  style: AppTypography.body(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                for (
                                  var i = 0;
                                  i < _severityOptions.length;
                                  i++
                                ) ...[
                                  if (i > 0)
                                    const SizedBox(height: AppSpacing.sm),
                                  SelectableOptionTile(
                                    title: _severityOptions[i].title,
                                    subtitle: _severityOptions[i].subtitle,
                                    selected:
                                        _severity == _severityOptions[i].value,
                                    onTap: () => _selectSeverity(
                                      _severityOptions[i].value,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          label: 'Annuler',
                          surface: SecondaryButtonSurface.parchment,
                          onPressed: _isSaving
                              ? null
                              : () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: PrimaryButton(
                          label: 'Envoyer',
                          isLoading: _isSaving,
                          onPressed: _canSubmit ? _submit : null,
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
