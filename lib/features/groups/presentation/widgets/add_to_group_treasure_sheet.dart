import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/dashed_add_tile.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../../characters/domain/currency_kind.dart';
import '../../../characters/domain/reward_item_draft.dart';
import '../../../characters/presentation/widgets/add_item_flow.dart';
import '../../../characters/presentation/widgets/add_reward_sheet.dart'
    show AddRewardCallback;

/// Même ordre d'affichage que `add_reward_sheet.dart`.
const List<CurrencyKind> _currencyFieldsOrder = [
  CurrencyKind.gold,
  CurrencyKind.silver,
  CurrencyKind.copper,
  CurrencyKind.platinum,
  CurrencyKind.electrum,
];

/// Sheet "AJOUTER AU BUTIN DU GROUPE" — variante de
/// `characters/presentation/widgets/add_reward_sheet.dart` (calque visuel
/// identique : 5 champs de monnaie à ajouter + composition locale d'objets
/// via [pickInventoryAddition]), retitrée pour l'onglet "Butin" de l'écran
/// "Groupe" — voir `docs/cahier-des-charges/12-partage-et-groupes.md`
/// section 2.2. Réutilise [AddRewardCallback]/[RewardItemDraft]
/// (`features/characters/`) tels quels : la composition "monnaie à ajouter +
/// objets en cours" est strictement identique entre les deux sheets, seule
/// la destination de l'écriture réseau diffère (`group_treasure` plutôt que
/// `characters`/`character_inventory` d'un personnage), gérée par
/// l'appelant (`group_screen.dart`), pas par cette sheet.
Future<void> showAddToGroupTreasureSheet(
  BuildContext context, {
  required AddRewardCallback onApply,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) =>
        _AddToGroupTreasureSheetContent(onApply: onApply),
  );
}

class _AddToGroupTreasureSheetContent extends StatefulWidget {
  const _AddToGroupTreasureSheetContent({required this.onApply});

  final AddRewardCallback onApply;

  @override
  State<_AddToGroupTreasureSheetContent> createState() =>
      _AddToGroupTreasureSheetContentState();
}

class _AddToGroupTreasureSheetContentState
    extends State<_AddToGroupTreasureSheetContent> {
  final Map<CurrencyKind, TextEditingController> _controllers = {
    for (final currency in _currencyFieldsOrder)
      currency: TextEditingController(),
  };
  final List<RewardItemDraft> _items = [];

  @override
  void initState() {
    super.initState();
    for (final controller in _controllers.values) {
      controller.addListener(_handleChanged);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.removeListener(_handleChanged);
      controller.dispose();
    }
    super.dispose();
  }

  void _handleChanged() {
    if (mounted) setState(() {});
  }

  Map<CurrencyKind, int> get _currencyDeltas {
    final deltas = <CurrencyKind, int>{};
    for (final entry in _controllers.entries) {
      final amount = int.tryParse(entry.value.text) ?? 0;
      if (amount > 0) deltas[entry.key] = amount;
    }
    return deltas;
  }

  bool get _canApply => _currencyDeltas.isNotEmpty || _items.isNotEmpty;

  Future<void> _addItem() async {
    final picked = await pickInventoryAddition(context);
    if (picked == null || !mounted) return;

    setState(() {
      _items.add(
        picked.isCustom
            ? RewardItemDraft(
                customName: picked.customName,
                displayName: picked.displayName,
                quantity: picked.quantity,
              )
            : RewardItemDraft(
                itemId: picked.item!.id,
                displayName: picked.displayName,
                quantity: picked.quantity,
              ),
      );
    });
  }

  void _removeItemAt(int index) => setState(() => _items.removeAt(index));

  void _submit() {
    widget.onApply(_currencyDeltas, List.of(_items));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: Container(
          decoration: const BoxDecoration(color: AppColors.parchmentBg),
          child: Column(
            children: [
              const SheetHeaderBar(title: 'AJOUTER AU BUTIN DU GROUPE'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MONNAIE',
                        style: AppTypography.display(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          for (var i = 0; i < 3; i++) ...[
                            if (i > 0) const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _CurrencyField(
                                currency: _currencyFieldsOrder[i],
                                controller:
                                    _controllers[_currencyFieldsOrder[i]]!,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          for (var i = 3; i < 5; i++) ...[
                            if (i > 3) const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _CurrencyField(
                                currency: _currencyFieldsOrder[i],
                                controller:
                                    _controllers[_currencyFieldsOrder[i]]!,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'OBJETS',
                        style: AppTypography.display(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      for (var i = 0; i < _items.length; i++) ...[
                        _TreasureDraftItemRow(
                          item: _items[i],
                          onRemove: () => _removeItemAt(i),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                      ],
                      DashedAddTile(label: 'Ajouter un objet', onTap: _addItem),
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
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Ajouter au butin',
                        onPressed: _canApply ? _submit : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrencyField extends StatelessWidget {
  const _CurrencyField({required this.currency, required this.controller});

  final CurrencyKind currency;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          currency.unitLabel,
          style: AppTypography.body(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(hintText: '0'),
        ),
      ],
    );
  }
}

class _TreasureDraftItemRow extends StatelessWidget {
  const _TreasureDraftItemRow({required this.item, required this.onRemove});

  final RewardItemDraft item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.woodLight, width: AppBorders.card),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${item.displayName} × ${item.quantity}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
