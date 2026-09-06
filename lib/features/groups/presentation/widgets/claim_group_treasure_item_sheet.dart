import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/stepper_counter.dart';
import '../../domain/group_treasure_item.dart';

/// Sheet légère "Réclamer {nom}" — calque `_ItemQuantitySheetContent`
/// (`characters/presentation/widgets/add_item_flow.dart`), `StepperCounter`
/// plafonné à [GroupTreasureItem.quantity] (quantité réellement disponible
/// au moment de l'ouverture) plutôt que sans limite haute — voir
/// `docs/cahier-des-charges/12-partage-et-groupes.md` section 2.2. Retourne
/// la quantité choisie, `null` si annulée.
Future<int?> showClaimGroupTreasureItemSheet(
  BuildContext context, {
  required GroupTreasureItem item,
}) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: AppColors.parchmentCard,
    isScrollControlled: true,
    builder: (sheetContext) => _ClaimItemSheetContent(item: item),
  );
}

class _ClaimItemSheetContent extends StatefulWidget {
  const _ClaimItemSheetContent({required this.item});

  final GroupTreasureItem item;

  @override
  State<_ClaimItemSheetContent> createState() => _ClaimItemSheetContentState();
}

class _ClaimItemSheetContentState extends State<_ClaimItemSheetContent> {
  late int _quantity = widget.item.quantity > 0 ? 1 : 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Réclamer ${widget.item.displayName}',
              style: AppTypography.body(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.item.quantity} disponible(s)',
              style: AppTypography.body(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: StepperCounter(
                value: _quantity,
                onIncrement: _quantity < widget.item.quantity
                    ? () => setState(() => _quantity++)
                    : null,
                onDecrement: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Réclamer',
              onPressed: _quantity > 0
                  ? () => Navigator.of(context).pop(_quantity)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
