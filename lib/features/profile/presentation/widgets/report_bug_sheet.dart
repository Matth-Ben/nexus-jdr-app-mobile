import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/connectivity_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/alert_banner.dart';
import '../../../../core/widgets/compact_action_button.dart';
import '../../../../core/widgets/dashed_add_tile.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/selectable_option_tile.dart';
import '../../../../core/widgets/sheet_action_row.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bug_report/domain/bug_report_failure.dart';
import '../../../bug_report/domain/bug_report_screenshot.dart';
import '../../../bug_report/presentation/providers/bug_report_providers.dart';

/// Ouvre la sheet "Signaler un bug" (tuile "Signaler un bug" de la section
/// "NOUS CONTACTER" de `profile_help_screen.dart` — déplacée depuis le hub
/// `profile_screen.dart` au recettage direction-artistique du 13/09/2026)
/// — sheet autoportante calquée sur
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
  final l10n = AppLocalizations.of(context)!;
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(l10n.profileReportBugSentSnackbar)));
}

/// Une des 4 sévérités proposées (`SelectableOptionTile`, spec
/// direction-artistique de la tâche) — [value] porte la valeur technique du
/// contrat `report-bug` (`mineur`/`majeur`/`bloquant`/`contenu`), jamais
/// [title]
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
///
/// Fonction plutôt qu'une constante (depuis la migration `.arb`, chantier
/// "traduction de l'app" Phase B) : [_SeverityOption.title]/`.subtitle`
/// dépendent désormais de [AppLocalizations], qui n'est disponible qu'avec
/// un `BuildContext`. [_defaultSeverityValue] (valeur technique seule, pas
/// de texte) reste une constante utilisable sans `l10n`, pour l'état initial
/// de [_ReportBugSheetContentState].
List<_SeverityOption> _severityOptions(AppLocalizations l10n) => [
  _SeverityOption(
    value: 'mineur',
    title: l10n.profileReportBugSeverityMinorTitle,
    subtitle: l10n.profileReportBugSeverityMinorSubtitle,
  ),
  _SeverityOption(
    value: 'majeur',
    title: l10n.profileReportBugSeverityMajorTitle,
    subtitle: l10n.profileReportBugSeverityMajorSubtitle,
  ),
  _SeverityOption(
    value: 'bloquant',
    title: l10n.profileReportBugSeverityBlockingTitle,
    subtitle: l10n.profileReportBugSeverityBlockingSubtitle,
  ),
  _SeverityOption(
    value: 'contenu',
    title: l10n.profileReportBugSeverityContentTitle,
    subtitle: l10n.profileReportBugSeverityContentSubtitle,
  ),
];

/// Valeur technique de la sévérité sélectionnée par défaut (`mineur`,
/// toujours la 1ère entrée de [_severityOptions]) — séparée du texte affiché
/// pour rester disponible sans `l10n` (état initial de
/// [_ReportBugSheetContentState]).
const String _defaultSeverityValue = 'mineur';

String _captureErrorMessageFor(
  AppLocalizations l10n,
  BugReportScreenshotFailureKind kind,
) {
  return switch (kind) {
    BugReportScreenshotFailureKind.tooLarge =>
      l10n.profileReportBugCaptureTooLarge,
    BugReportScreenshotFailureKind.unsupportedFormat =>
      l10n.profileReportBugCaptureUnsupportedFormat,
    BugReportScreenshotFailureKind.accessDenied =>
      l10n.profileReportBugCaptureAccessDenied,
  };
}

/// Gabarit B autoportant (`showModalBottomSheet`, `isScrollControlled: true`,
/// `FractionallySizedBox(heightFactor: 0.92)`) : `SheetHeaderBar`, 2 champs
/// texte + sélecteur de sévérité + capture d'écran facultative, pied fixe
/// "Annuler"/"Envoyer".
///
/// Capture : choisie via `bugReportScreenshotPickerProvider` (sheet de
/// source empilée sur celle-ci, qui reste ouverte), préparée (JPEG
/// compressé) avant d'être jointe, puis transmise telle quelle à
/// `submitReport` — un échec d'envoi conserve la saisie ET l'image.
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

  /// Ramène le bandeau d'erreur d'envoi (en tête du défilement) dans le
  /// champ quand l'envoi échoue depuis le bas de la sheet.
  final ScrollController _scrollController = ScrollController();
  String _severity = _defaultSeverityValue;
  bool _isSaving = false;
  String? _errorMessage;

  /// Capture jointe, déjà préparée (JPEG compressé) — `null` : aucune.
  Uint8List? _capture;
  bool _isPreparingCapture = false;
  String? _captureErrorMessage;

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
    _scrollController.dispose();
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
      _descriptionController.text.trim().isNotEmpty &&
      !_isPreparingCapture;

  void _selectSeverity(String value) {
    if (_isSaving) return;
    setState(() => _severity = value);
  }

  Future<void> _openCaptureSourceSheet() async {
    if (_isSaving || _isPreparingCapture) return;
    // Capturé avant tout `await` (même précaution que
    // `avatar_crop_screen.dart`) : les gardes `mounted` ci-dessous couvrent
    // déjà l'usage de `context`/`l10n` après chaque point d'attente.
    final l10n = AppLocalizations.of(context)!;
    setState(() => _captureErrorMessage = null);

    final source = await showModalBottomSheet<BugReportScreenshotSource>(
      context: context,
      backgroundColor: AppColors.parchmentCard,
      builder: (sheetContext) => const _CaptureSourceSheetContent(),
    );
    if (source == null || !mounted) return;

    final picker = ref.read(bugReportScreenshotPickerProvider);
    try {
      final rawBytes = await picker.pick(source);
      if (rawBytes == null || !mounted) return;
      setState(() => _isPreparingCapture = true);
      final prepared = await picker.prepare(rawBytes);
      if (!mounted) return;
      setState(() {
        _capture = prepared;
        _isPreparingCapture = false;
        if (_errorMessage == l10n.profileReportBugScreenshotUploadError) {
          _errorMessage = null;
        }
      });
    } on BugReportScreenshotFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _isPreparingCapture = false;
        _captureErrorMessage = _captureErrorMessageFor(l10n, failure.kind);
      });
    } catch (error) {
      debugPrint('ReportBugSheet._openCaptureSourceSheet: erreur: $error');
      if (!mounted) return;
      setState(() {
        _isPreparingCapture = false;
        _captureErrorMessage = l10n.profileReportBugCaptureUnsupportedFormat;
      });
    }
  }

  void _removeCapture() {
    if (_isSaving) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _capture = null;
      _captureErrorMessage = null;
      if (_errorMessage == l10n.profileReportBugScreenshotUploadError) {
        _errorMessage = null;
      }
    });
  }

  Future<void> _submit() async {
    if (_isSaving || !_canSubmit) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    // Vérifié *avant* toute tentative réseau — voir la documentation de
    // `profileReportBugOfflineMessage` : pas de file d'attente hors-ligne
    // pour cette écriture.
    if (!await ref.read(connectivityCheckerProvider).hasConnection()) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = l10n.profileReportBugOfflineMessage;
      });
      _scrollToErrorBanner();
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
            screenshotJpeg: _capture,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on BugReportFailure catch (failure) {
      debugPrint('ReportBugSheet._submit: échec: ${failure.message}');
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = failure.kind == BugReportFailureKind.screenshotUpload
            ? l10n.profileReportBugScreenshotUploadError
            : l10n.profileReportBugGenericError;
      });
      _scrollToErrorBanner();
    } catch (error) {
      // Voir la documentation de `profileReportBugGenericError` : le détail
      // de l'échec (`BugReportFailure.message`, une exception réseau...)
      // n'est jamais affiché tel quel, seulement journalisé pour le
      // diagnostic.
      debugPrint('ReportBugSheet._submit: erreur inattendue: $error');
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = l10n.profileReportBugGenericError;
      });
      _scrollToErrorBanner();
    }
  }

  void _scrollToErrorBanner() {
    if (!mounted || !_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  /// Bloc « Capture d'écran » (spec B.1-B.7) : en-tête et mention de
  /// confidentialité toujours visibles, puis l'état courant (vide,
  /// préparation, image jointe), puis l'éventuelle erreur de choix d'image.
  Widget _buildCaptureSection(AppLocalizations l10n) {
    final capture = _capture;
    final Widget body;
    if (_isPreparingCapture) {
      body = const _CapturePreparingFrame();
    } else if (capture != null) {
      body = _CaptureAttachedCard(
        bytes: capture,
        onReplace: _openCaptureSourceSheet,
        onRemove: _removeCapture,
      );
    } else {
      body = Semantics(
        button: true,
        label: l10n.profileReportBugAddCaptureSemanticLabel,
        excludeSemantics: true,
        onTap: _openCaptureSourceSheet,
        // Hauteur fixe 48 px : seul endroit de la sheet où le facteur de
        // texte est plafonné (spec B.9, règle D24).
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: AppTypography.maxTextScaleFactor,
          child: DashedAddTile(
            label: l10n.profileReportBugAddCapture,
            onTap: _openCaptureSourceSheet,
          ),
        ),
      );
    }

    final captureError = _captureErrorMessage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.profileReportBugCaptureSectionTitle,
          style: AppTypography.body(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ExcludeSemantics(
              child: Icon(
                Icons.lock_outline,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                l10n.profileReportBugCapturePrivacyNotice,
                style: AppTypography.body(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        body,
        if (captureError != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            liveRegion: true,
            child: AlertBanner(message: captureError),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final severityOptions = _severityOptions(l10n);
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
                  title: l10n.profileReportBugTitle,
                  closeEnabled: !_isSaving,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_errorMessage != null) ...[
                          Semantics(
                            liveRegion: true,
                            child: AlertBanner(message: _errorMessage!),
                          ),
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
                                  l10n.profileReportBugFieldTitleLabel,
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
                                  decoration: InputDecoration(
                                    hintText:
                                        l10n.profileReportBugFieldTitleHint,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  l10n.profileReportBugFieldDescriptionLabel,
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
                                  decoration: InputDecoration(
                                    hintText: l10n
                                        .profileReportBugFieldDescriptionHint,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  l10n.profileReportBugSeveritySectionTitle,
                                  style: AppTypography.body(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                for (
                                  var i = 0;
                                  i < severityOptions.length;
                                  i++
                                ) ...[
                                  if (i > 0)
                                    const SizedBox(height: AppSpacing.sm),
                                  SelectableOptionTile(
                                    title: severityOptions[i].title,
                                    subtitle: severityOptions[i].subtitle,
                                    subtitleMaxLines: null,
                                    selected:
                                        _severity == severityOptions[i].value,
                                    onTap: () => _selectSeverity(
                                      severityOptions[i].value,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: AppSpacing.md),
                                _buildCaptureSection(l10n),
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
                          label: l10n.profileReportBugCancel,
                          surface: SecondaryButtonSurface.parchment,
                          onPressed: _isSaving
                              ? null
                              : () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: PrimaryButton(
                          label: l10n.profileReportBugSend,
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

/// Sheet de choix de la source de la capture — même pattern que
/// `avatar_edit_sheet.dart::_AvatarEditSheetContent`, galerie en premier,
/// sans recadrage, URL ni « Retirer » (spec B.4). S'empile sur la sheet du
/// signalement, qui reste ouverte.
class _CaptureSourceSheetContent extends StatelessWidget {
  const _CaptureSourceSheetContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetActionRow(
            icon: Icons.image_outlined,
            label: l10n.profileReportBugChooseGallery,
            onTap: () =>
                Navigator.of(context).pop(BugReportScreenshotSource.gallery),
          ),
          const SheetActionDivider(),
          SheetActionRow(
            icon: Icons.photo_camera_outlined,
            label: l10n.profileReportBugTakePhoto,
            onTap: () =>
                Navigator.of(context).pop(BugReportScreenshotSource.camera),
          ),
        ],
      ),
    );
  }
}

/// Cadre « Préparation de l'image… » (spec B.5), hauteur fixe 48 px comme le
/// `DashedAddTile` qu'il remplace — d'où le plafonnement local du facteur de
/// texte (spec B.9).
class _CapturePreparingFrame extends StatelessWidget {
  const _CapturePreparingFrame();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      liveRegion: true,
      label: l10n.profileReportBugPreparingImageSemanticLabel,
      excludeSemantics: true,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: AppTypography.maxTextScaleFactor,
        child: Container(
          key: const Key('reportBugCapturePreparing'),
          height: 48,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.parchmentCard,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.woodLight,
              width: AppBorders.card,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.woodMedium,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    l10n.profileReportBugPreparingImage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
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

/// Capture jointe (spec B.6) : vignette 80 × 120, poids compressé,
/// « Remplacer » et « Retirer » empilés.
class _CaptureAttachedCard extends StatelessWidget {
  const _CaptureAttachedCard({
    required this.bytes,
    required this.onReplace,
    required this.onRemove,
  });

  final Uint8List bytes;
  final VoidCallback onReplace;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      key: const Key('reportBugCaptureAttached'),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.woodLight, width: AppBorders.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            image: true,
            label: l10n.profileReportBugAttachedImageSemanticLabel,
            child: Container(
              width: 80,
              height: 120,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: AppColors.woodLight,
                  width: AppBorders.card,
                ),
              ),
              child: Image.memory(
                bytes,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                excludeFromSemantics: true,
                errorBuilder: (context, error, stackTrace) => const ColoredBox(
                  color: AppColors.parchmentCardAlt,
                  child: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.profileReportBugAttachedLabel,
                  style: AppTypography.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatBugReportScreenshotSize(bytes.length),
                  style: AppTypography.body(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Semantics(
                  button: true,
                  label: l10n.profileReportBugReplaceSemanticLabel,
                  excludeSemantics: true,
                  onTap: onReplace,
                  child: CompactActionButton(
                    icon: Icons.autorenew,
                    label: l10n.profileReportBugReplace,
                    onTap: onReplace,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Semantics(
                  button: true,
                  label: l10n.profileReportBugRemoveSemanticLabel,
                  excludeSemantics: true,
                  onTap: onRemove,
                  child: CompactActionButton(
                    icon: Icons.delete_outline,
                    label: l10n.profileReportBugRemove,
                    onTap: onRemove,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
