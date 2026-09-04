import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/dashed_add_tile.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../domain/currency_kind.dart';
import '../../domain/reward_item_draft.dart';
import 'add_item_flow.dart';

/// Callback de validation de la sheet "Ajouter une récompense" — reçoit les
/// **deltas** de monnaie déjà saisis (montant à ajouter par monnaie, jamais
/// une valeur absolue — contrairement à [CurrencyAdjustmentSheetContent],
/// voir `character_detail_screen.dart::_addReward` pour le calcul du
/// nouveau total absolu à partir de la dernière fiche connue) et la liste
/// complète des objets composés localement, jamais écrits en base avant
/// validation (voir la documentation de classe de [showAddRewardSheet]).
typedef AddRewardCallback = void Function(
  Map<CurrencyKind, int> currencyDeltas,
  List<RewardItemDraft> items,
);

/// Ordre d'affichage des 5 champs de monnaie — "PO/PA/PC/PP/PE" (spec
/// visuelle de la tâche), distinct de l'ordre de valeur décroissante des
/// stat boxes de tête d'onglet (`InventoryStatBoxesResolver`) : l'or reste
/// en tête ici aussi (monnaie de référence), mais platine/électrum, plus
/// rares, sont relégués en fin de liste plutôt qu'insérés entre les autres.
const List<CurrencyKind> _currencyFieldsOrder = [
  CurrencyKind.gold,
  CurrencyKind.silver,
  CurrencyKind.copper,
  CurrencyKind.platinum,
  CurrencyKind.electrum,
];

/// Ouvre la sheet "Ajouter une récompense" (bouton `trailing` du
/// `WoodBackHeader` de l'onglet "Inventaire" — voir
/// `character_detail_screen.dart`) : section "MONNAIE" (5 champs numériques
/// PO/PA/PC/PP/PE, valeurs à *ajouter*) puis section "OBJETS" (liste
/// composée localement via [pickInventoryAddition], **aucune écriture en
/// base avant validation** — spec de la tâche : "un seul appel réseau à la
/// validation", voir `CharacterRepository.addReward`).
Future<void> showAddRewardSheet(
  BuildContext context, {
  required AddRewardCallback onApply,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _AddRewardSheetContent(onApply: onApply),
  );
}

class _AddRewardSheetContent extends StatefulWidget {
  const _AddRewardSheetContent({required this.onApply});

  final AddRewardCallback onApply;

  @override
  State<_AddRewardSheetContent> createState() => _AddRewardSheetContentState();
}

class _AddRewardSheetContentState extends State<_AddRewardSheetContent> {
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
              const SheetHeaderBar(title: 'AJOUTER UNE RÉCOMPENSE'),
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
                        _RewardItemRow(
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
                        label: 'Ajouter la récompense',
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

class _RewardItemRow extends StatelessWidget {
  const _RewardItemRow({required this.item, required this.onRemove});

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
          // Zone de tap 44×44 explicite (consigne d'accessibilité de la
          // tâche) — le `IconButton` seul, compact, n'atteint pas cette
          // taille par défaut.
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
