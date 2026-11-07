import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/alert_banner.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../domain/group_failure.dart';
import '../../domain/group_note_entry.dart';
import '../providers/group_providers.dart';

/// Ouvre la sheet "Ajouter une note"/"Modifier la note" de l'onglet "Notes"
/// de l'écran "Groupe" (`group_notes_tab_body.dart`) — [entry] `null` pour un
/// ajout, non nul pour une modification (préremplit les champs, appelle
/// `updateGroupNoteEntry` plutôt que `addGroupNoteEntry` à l'enregistrement).
///
/// Calque direct de
/// `features/characters/presentation/widgets/character_journal_entry_edit_sheet.dart`
/// (même architecture autoportante : la sheet effectue elle-même l'appel
/// réseau, ne se ferme qu'une fois celui-ci résolu, bandeau d'erreur inline
/// plutôt qu'un `SnackBar` sur échec), avec un champ titre optionnel en plus
/// et sans file d'attente hors-ligne (`GroupRepository` n'en a pas, voir sa
/// doc de classe — un échec réseau lève simplement une [GroupFailure]).
Future<void> showGroupNoteEntryEditSheet(
  BuildContext context, {
  required String groupId,
  GroupNoteEntry? entry,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: false,
    builder: (sheetContext) =>
        _GroupNoteEntryEditSheetContent(groupId: groupId, entry: entry),
  );
  if (saved != true || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(entry == null ? 'Note ajoutée.' : 'Note modifiée.')),
  );
}

class _GroupNoteEntryEditSheetContent extends ConsumerStatefulWidget {
  const _GroupNoteEntryEditSheetContent({
    required this.groupId,
    required this.entry,
  });

  final String groupId;
  final GroupNoteEntry? entry;

  @override
  ConsumerState<_GroupNoteEntryEditSheetContent> createState() =>
      _GroupNoteEntryEditSheetContentState();
}

class _GroupNoteEntryEditSheetContentState
    extends ConsumerState<_GroupNoteEntryEditSheetContent> {
  late final TextEditingController _titleController = TextEditingController(
    text: widget.entry?.title ?? '',
  );
  late final TextEditingController _bodyController = TextEditingController(
    text: widget.entry?.body ?? '',
  );
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _handleDictationError(String message) {
    setState(() => _errorMessage = message);
  }

  Future<void> _submit() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty || _isSaving) return;
    final rawTitle = _titleController.text.trim();
    final title = rawTitle.isEmpty ? null : rawTitle;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final entry = widget.entry;
      final repository = ref.read(groupRepositoryProvider);
      if (entry == null) {
        await repository.addGroupNoteEntry(
          groupId: widget.groupId,
          title: title,
          body: body,
        );
      } else {
        await repository.updateGroupNoteEntry(
          entryId: entry.id,
          title: title,
          body: body,
        );
      }

      // `mounted` vérifié avant `ref.invalidate`, même précaution que
      // `character_journal_entry_edit_sheet.dart::_submit`.
      if (!mounted) return;
      ref.invalidate(groupNoteEntriesProvider(widget.groupId));
      Navigator.of(context).pop(true);
    } on GroupFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = failure.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = 'Impossible d\'enregistrer cette note. Réessayez.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.entry != null;
    return PopScope(
      canPop: !_isSaving,
      child: SafeArea(
        top: false,
        child: FractionallySizedBox(
          heightFactor: 0.7,
          child: Container(
            decoration: const BoxDecoration(color: AppColors.parchmentBg),
            child: Column(
              children: [
                SheetHeaderBar(
                  title: isEditing ? 'MODIFIER LA NOTE' : 'AJOUTER UNE NOTE',
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
                        TextFormField(
                          controller: _titleController,
                          autofocus: !isEditing,
                          decoration: const InputDecoration(
                            hintText: 'Titre de la note (optionnel)',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _DictationButton(
                              controller: _bodyController,
                              onTextChanged: () => setState(() {}),
                              onError: _handleDictationError,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _bodyController,
                          minLines: 6,
                          maxLines: null,
                          decoration: const InputDecoration(
                            hintText: 'Événements, indices, rebondissements…',
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
                          label: 'Enregistrer',
                          isLoading: _isSaving,
                          onPressed: _submit,
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

/// Bouton micro : dictée vocale via `speech_to_text` — déplacé tel quel
/// depuis l'ancien `group_notes_tab_body.dart` (texte intégral plein écran,
/// remplacé par ce fractionnement en entrées multiples), voir sa
/// documentation de classe d'origine pour le rationale complet (dictée
/// ponctuelle, pas de transcription continue). Toujours lié au controller du
/// corps de la note, jamais à celui du titre.
class _DictationButton extends StatefulWidget {
  const _DictationButton({
    required this.controller,
    required this.onTextChanged,
    required this.onError,
  });

  final TextEditingController controller;
  final VoidCallback onTextChanged;
  final ValueChanged<String> onError;

  @override
  State<_DictationButton> createState() => _DictationButtonState();
}

class _DictationButtonState extends State<_DictationButton> {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _isBusy = false;
  String _baseText = '';

  @override
  void dispose() {
    if (_isListening) unawaited(_speech.stop());
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_isBusy) return;
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    setState(() => _isBusy = true);
    final available = await _speech.initialize(
      onError: (error) => _handleError(error),
      onStatus: (status) {
        if ((status == 'done' || status == 'notListening') && mounted) {
          setState(() => _isListening = false);
        }
      },
    );
    if (!mounted) return;
    if (!available) {
      setState(() => _isBusy = false);
      widget.onError(
        'Reconnaissance vocale indisponible sur cet appareil ou accès '
        'micro refusé.',
      );
      return;
    }

    _baseText = widget.controller.text;
    setState(() {
      _isBusy = false;
      _isListening = true;
    });
    await _speech.listen(onResult: _handleResult);
  }

  void _handleError(SpeechRecognitionError error) {
    if (mounted) setState(() => _isListening = false);
    widget.onError('Erreur de reconnaissance vocale : ${error.errorMsg}');
  }

  void _handleResult(SpeechRecognitionResult result) {
    final needsSeparator =
        _baseText.isNotEmpty &&
        !_baseText.endsWith('\n') &&
        !_baseText.endsWith(' ');
    final newText =
        '$_baseText${needsSeparator ? ' ' : ''}${result.recognizedWords}';
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
    widget.onTextChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _isListening ? AppColors.accentBrick : AppColors.parchmentCard,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: _isBusy ? null : _toggle,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            _isListening ? Icons.mic : Icons.mic_none,
            color: _isListening
                ? AppColors.parchmentBg
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
