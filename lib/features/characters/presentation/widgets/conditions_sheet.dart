import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/alert_banner.dart';
import '../../../../core/widgets/pixel_icon.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/selection_checkbox.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/condition_type.dart';
import 'condition_texts.dart';

/// Enregistre la sélection : retourne `null` en cas de succès, ou le message
/// d'erreur à afficher dans la feuille (la sélection saisie est alors
/// conservée).
typedef ConditionsSaveCallback = Future<String?> Function(
  List<ConditionType> selection,
);

/// Annonce d'accessibilité émise après un enregistrement réussi (remplaçable
/// dans les tests).
typedef ConditionsAnnouncer = void Function(BuildContext context, String text);

void _defaultAnnouncer(BuildContext context, String text) {
  SemanticsService.sendAnnouncement(
    View.of(context),
    text,
    Directionality.of(context),
  );
}

/// Feuille de sélection des 14 conditions (P6) : cases à cocher, bouton
/// « Enregistrer » explicite (actif seulement si la sélection diffère de
/// l'état initial). Informatif : aucun effet sur les calculs.
///
/// Fermeture avec modifications non enregistrées : comme `RestSheet`, aucune
/// confirmation (fermer abandonne la saisie). Pendant l'enregistrement, la
/// feuille ne peut pas être fermée et les cases sont désactivées.
Future<void> showConditionsSheet(
  BuildContext context, {
  required List<ConditionType> initial,
  required ConditionsSaveCallback onSave,
  ConditionsAnnouncer announcer = _defaultAnnouncer,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enableDrag: false,
    builder: (sheetContext) =>
        ConditionsSheet(initial: initial, onSave: onSave, announcer: announcer),
  );
}

@visibleForTesting
class ConditionsSheet extends StatefulWidget {
  const ConditionsSheet({
    required this.initial,
    required this.onSave,
    this.announcer = _defaultAnnouncer,
    super.key,
  });

  final List<ConditionType> initial;
  final ConditionsSaveCallback onSave;
  final ConditionsAnnouncer announcer;

  @override
  State<ConditionsSheet> createState() => _ConditionsSheetState();
}

class _ConditionsSheetState extends State<ConditionsSheet> {
  late final Set<ConditionType> _initial = widget.initial.toSet();
  late final Set<ConditionType> _selected = widget.initial.toSet();
  bool _isSaving = false;
  String? _errorMessage;

  bool get _hasChanges => !setEquals(_selected, _initial);

  void _toggle(ConditionType condition) {
    if (_isSaving) return;
    setState(() {
      if (!_selected.remove(condition)) _selected.add(condition);
    });
  }

  void _clearAll() {
    if (_isSaving) return;
    setState(_selected.clear);
  }

  Future<void> _save() async {
    if (_isSaving || !_hasChanges) return;
    final l10n = AppLocalizations.of(context)!;
    final selection = ConditionType.canonical(_selected);
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    String? error;
    try {
      error = await widget.onSave(selection);
    } catch (_) {
      error = l10n.conditionsSheetGenericError;
    }
    if (!mounted) return;

    if (error != null) {
      setState(() {
        _isSaving = false;
        _errorMessage = error;
      });
      return;
    }

    widget.announcer(
      context,
      selection.isEmpty
          ? l10n.conditionsNoneAnnouncement
          : l10n.conditionsUpdatedAnnouncement(
              conditionNamesList(selection, l10n),
            ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ordered = sortConditionsForDisplay(ConditionType.values, l10n);

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
                  title: l10n.conditionsSheetTitle,
                  closeEnabled: !_isSaving,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xs,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.conditionsSheetSubtitle,
                      style: AppTypography.body(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xs,
                    ),
                    itemCount: ordered.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, index) {
                      final condition = ordered[index];
                      return _ConditionRow(
                        condition: condition,
                        checked: _selected.contains(condition),
                        enabled: !_isSaving,
                        onTap: () => _toggle(condition),
                      );
                    },
                  ),
                ),
                _Footer(
                  isSaving: _isSaving,
                  canSave: _hasChanges,
                  canClear: _selected.isNotEmpty,
                  errorMessage: _errorMessage,
                  onSave: _save,
                  onCancel: () => Navigator.of(context).pop(),
                  onClear: _clearAll,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConditionRow extends StatelessWidget {
  const _ConditionRow({
    required this.condition,
    required this.checked,
    required this.enabled,
    required this.onTap,
  });

  final ConditionType condition;
  final bool checked;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = condition.label(l10n);
    final rule = condition.rule(l10n);
    return Semantics(
      container: true,
      checked: checked,
      enabled: enabled,
      label: l10n.conditionChipSemanticsLabel(label, rule),
      excludeSemantics: true,
      onTap: enabled ? onTap : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: checked
                  ? AppColors.parchmentCardAlt
                  : AppColors.parchmentCard,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: checked ? AppColors.woodLight : Colors.transparent,
                width: AppBorders.card,
              ),
            ),
            child: Row(
              children: [
                PixelIcon(matrix: condition.pixelMatrix),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTypography.body(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        rule,
                        style: AppTypography.body(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SelectionCheckbox(checked: checked),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.isSaving,
    required this.canSave,
    required this.canClear,
    required this.errorMessage,
    required this.onSave,
    required this.onCancel,
    required this.onClear,
  });

  final bool isSaving;
  final bool canSave;
  final bool canClear;
  final String? errorMessage;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrimaryButton(
            label: l10n.conditionsSheetSaveButton,
            isLoading: isSaving,
            onPressed: canSave ? onSave : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: l10n.conditionsSheetCancelButton,
            surface: SecondaryButtonSurface.parchment,
            onPressed: isSaving ? null : onCancel,
          ),
          if (canClear)
            Align(
              child: TextButton(
                onPressed: isSaving ? null : onClear,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  minimumSize: const Size(44, 44),
                ),
                child: Text(
                  l10n.conditionsSheetClearAllButton,
                  style: AppTypography.body(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          if (errorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AlertBanner(message: errorMessage!),
          ],
        ],
      ),
    );
  }
}
