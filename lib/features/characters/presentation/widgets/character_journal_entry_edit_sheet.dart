import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/alert_banner.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../domain/character_failure.dart';
import '../../domain/character_journal_entry.dart';
import '../../domain/write_outcome.dart';
import '../providers/character_detail_provider.dart';
import '../providers/character_providers.dart';

const String _offlineMessage =
    "Hors ligne : cette action n'a pas pu être enregistrée. Réessayez une "
    'fois reconnecté.';

const String _genericErrorMessage =
    "Impossible d'enregistrer cette note. Réessayez.";

/// Ouvre la sheet "Ajouter une note"/"Modifier la note" du journal de
/// campagne (carte "Journal de campagne" de l'onglet "Histoire",
/// `character_journal_card.dart`) — [entry] `null` pour un ajout, non nul
/// pour une modification (préremplit le champ, appelle `updateJournalEntry`
/// plutôt que `addJournalEntry` à l'enregistrement).
///
/// Même architecture autoportante que
/// `character_story_edit_sheet.dart::showCharacterStoryEditSheet` (la sheet
/// effectue elle-même l'appel réseau, ne se ferme qu'une fois celui-ci
/// résolu, bandeau d'erreur inline plutôt qu'un `SnackBar` sur échec) : une
/// note de séance peut être longue, la perdre sur une fermeture aveugle
/// serait tout aussi coûteux que pour les 9 champs de l'histoire figée.
Future<void> showJournalEntryEditSheet(
  BuildContext context, {
  required String characterId,
  CharacterJournalEntry? entry,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: false,
    builder: (sheetContext) => _JournalEntryEditSheetContent(
      characterId: characterId,
      entry: entry,
    ),
  );
  if (saved != true || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(entry == null ? 'Note ajoutée.' : 'Note modifiée.')),
  );
}

class _JournalEntryEditSheetContent extends ConsumerStatefulWidget {
  const _JournalEntryEditSheetContent({
    required this.characterId,
    required this.entry,
  });

  final String characterId;
  final CharacterJournalEntry? entry;

  @override
  ConsumerState<_JournalEntryEditSheetContent> createState() =>
      _JournalEntryEditSheetContentState();
}

class _JournalEntryEditSheetContentState
    extends ConsumerState<_JournalEntryEditSheetContent> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.entry?.body ?? '',
  );
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _isSaving) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final entry = widget.entry;
      final outcome = entry == null
          ? await ref
                .read(characterRepositoryProvider)
                .addJournalEntry(characterId: widget.characterId, body: body)
          : await ref
                .read(characterRepositoryProvider)
                .updateJournalEntry(
                  characterId: widget.characterId,
                  entryId: entry.id,
                  body: body,
                );

      if (outcome == WriteOutcome.queued) {
        if (!mounted) return;
        setState(() {
          _isSaving = false;
          _errorMessage = _offlineMessage;
        });
        return;
      }

      // `mounted` vérifié avant `ref.invalidate`, même précaution que
      // `character_story_edit_sheet.dart::_submit`.
      if (!mounted) return;
      ref.invalidate(characterDetailProvider(widget.characterId));
      Navigator.of(context).pop(true);
    } on CharacterFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = failure.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = _genericErrorMessage;
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
                          controller: _controller,
                          autofocus: !isEditing,
                          minLines: 6,
                          maxLines: null,
                          decoration: const InputDecoration(
                            hintText: 'Note de séance, événement marquant…',
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
