import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../../../core/widgets/stepper_counter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/initiative_input.dart';
import '../../domain/monster_numbering.dart';
import '../combat_announcer.dart';
import 'initiative_field.dart';
import 'initiative_roll_block.dart';

/// Envoie l'ajout au serveur : renvoie `null` en cas de succès, sinon le
/// message d'erreur localisé à afficher dans la feuille.
typedef AddMonsterSubmit = Future<String?> Function({
  required String name,
  required int? initiative,
  required int count,
});

/// Feuille « Ajouter un monstre » : nom (1..80), initiative facultative,
/// quantité ×N (1..20, initiative commune), aperçu `liveRegion` de la
/// numérotation, « Ajouter » (ferme) et « Ajouter et continuer » (garde la
/// feuille, remet la quantité à 1, focus sur « Nom »).
Future<void> showAddMonsterSheet(
  BuildContext context, {
  required AddMonsterSubmit onSubmit,
  required List<String> Function() existingNames,
  CombatSheetAnnouncer announcer = defaultCombatAnnouncer,
  InitiativeRollOpener rollOpener = defaultInitiativeRollOpener,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.parchmentBg,
    builder: (_) => AddMonsterSheet(
      onSubmit: onSubmit,
      existingNames: existingNames,
      announcer: announcer,
      rollOpener: rollOpener,
    ),
  );
}

class AddMonsterSheet extends StatefulWidget {
  const AddMonsterSheet({
    required this.onSubmit,
    required this.existingNames,
    this.announcer = defaultCombatAnnouncer,
    this.rollOpener = defaultInitiativeRollOpener,
    super.key,
  });

  final AddMonsterSubmit onSubmit;
  final List<String> Function() existingNames;
  final CombatSheetAnnouncer announcer;
  final InitiativeRollOpener rollOpener;

  @override
  State<AddMonsterSheet> createState() => _AddMonsterSheetState();
}

class _AddMonsterSheetState extends State<AddMonsterSheet> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _initiative = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _initiativeFocus = FocusNode();
  int _quantity = 1;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _initiative.dispose();
    _nameFocus.dispose();
    _initiativeFocus.dispose();
    super.dispose();
  }

  InitiativeInput get _input => parseInitiativeInput(_initiative.text);

  bool get _canSubmit =>
      !_busy &&
      _name.text.trim().isNotEmpty &&
      _input.status != InitiativeInputStatus.invalid;

  Future<void> _submit({required bool keepOpen}) async {
    if (!_canSubmit) return;
    final count = _quantity;
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await widget.onSubmit(
      name: _name.text.trim(),
      initiative: _input.value,
      count: count,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }
    if (!keepOpen) {
      Navigator.of(context).pop();
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _busy = false;
      _quantity = 1;
    });
    _nameFocus.requestFocus();
    _name.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _name.text.length,
    );
    widget.announcer(context, l10n.combatAddedAnnounce(count));
  }

  String? _preview(AppLocalizations l10n) {
    final base = _name.text.trim();
    if (base.isEmpty) return null;
    final names = monsterNames(
      base,
      _quantity,
      existingNames: widget.existingNames(),
    );
    if (names.length <= 4) return l10n.combatMonsterPreview(names.join(', '));
    return l10n.combatMonsterPreview(
      l10n.combatMonsterPreviewMany(names.first, names.last, names.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final preview = _preview(l10n);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeaderBar(title: l10n.combatAddMonster),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.combatMonsterName,
                    style: AppTypography.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Semantics(
                      label: l10n.combatMonsterName,
                      textField: true,
                      child: TextField(
                        key: const Key('combatMonsterName'),
                        controller: _name,
                        focusNode: _nameFocus,
                        autofocus: true,
                        textCapitalization: TextCapitalization.sentences,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(kParticipantNameMax),
                        ],
                        onChanged: (_) => setState(() {}),
                        style: AppTypography.body(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.parchmentCard,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.sm,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            borderSide: const BorderSide(
                              color: AppColors.woodLight,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            borderSide: const BorderSide(
                              color: AppColors.woodMedium,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  InitiativeField(
                    controller: _initiative,
                    focusNode: _initiativeFocus,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Monstre : d20 + 0 (modificateur de Dex inconnu), pas d'aide.
                  InitiativeRollBlock(
                    controller: _initiative,
                    focusNode: _initiativeFocus,
                    modifier: 0,
                    announcer: widget.announcer,
                    opener: widget.rollOpener,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.combatMonsterQuantity,
                          style: AppTypography.body(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      StepperCounter(
                        value: _quantity,
                        decrementLabel: l10n.combatQuantityDecrease,
                        incrementLabel: l10n.combatQuantityIncrease,
                        onDecrement: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                        onIncrement: _quantity < kMonsterBatchMax
                            ? () => setState(() => _quantity++)
                            : null,
                      ),
                    ],
                  ),
                  if (preview != null)
                    Semantics(
                      liveRegion: true,
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          preview,
                          key: const Key('combatMonsterPreview'),
                          style: AppTypography.body(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  if (_error != null)
                    Semantics(
                      liveRegion: true,
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 16,
                              color: AppColors.accentBrick,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                _error!,
                                style: AppTypography.body(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentBrick,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: l10n.combatAdd,
                    isLoading: _busy,
                    onPressed: _canSubmit
                        ? () => _submit(keepOpen: false)
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SecondaryButton(
                    label: l10n.combatAddAndContinue,
                    surface: SecondaryButtonSurface.parchment,
                    onPressed: _canSubmit
                        ? () => _submit(keepOpen: true)
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
