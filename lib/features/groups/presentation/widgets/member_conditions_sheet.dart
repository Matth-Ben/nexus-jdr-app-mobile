import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/pixel_icon.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../characters/domain/condition_type.dart';
import '../../../characters/presentation/widgets/condition_texts.dart';

/// Part maximale de la hauteur de l'écran occupée par la feuille.
const double kMemberConditionsSheetMaxHeightFactor = 0.6;

/// Ouvre la feuille en lecture seule de TOUS les états d'un membre (V3-5),
/// depuis la pastille « +N » de sa carte. Instantané figé à l'ouverture
/// ([conditions] est déjà en mémoire : aucun appel réseau).
Future<void> showMemberConditionsSheet(
  BuildContext context,
  String memberName,
  List<ConditionType> conditions,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) =>
        MemberConditionsSheet(memberName: memberName, conditions: conditions),
  );
}

/// Contenu de la feuille : titre « États de {name} », une ligne par condition
/// (icône, libellé, règle courte), sans case ni pied. Hauteur au contenu,
/// plafonnée à [kMemberConditionsSheetMaxHeightFactor] de l'écran, corps
/// défilant.
class MemberConditionsSheet extends StatelessWidget {
  const MemberConditionsSheet({
    required this.memberName,
    required this.conditions,
    super.key,
  });

  final String memberName;
  final List<ConditionType> conditions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sorted = sortConditionsForDisplay(conditions, l10n);

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.sizeOf(context).height *
              kMemberConditionsSheetMaxHeightFactor,
        ),
        child: Container(
          color: AppColors.parchmentBg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetHeaderBar(
                title: l10n.memberConditionsSheetTitle(memberName),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: sorted.isEmpty
                      ? Text(
                          l10n.memberConditionsSheetEmpty,
                          style: AppTypography.body(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < sorted.length; i++) ...[
                              if (i > 0) const SizedBox(height: AppSpacing.xs),
                              _ReadOnlyConditionRow(condition: sorted[i]),
                            ],
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyConditionRow extends StatelessWidget {
  const _ReadOnlyConditionRow({required this.condition});

  final ConditionType condition;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = condition.label(l10n);
    final rule = condition.rule(l10n);
    return Semantics(
      container: true,
      label: l10n.conditionChipSemanticsLabel(label, rule),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.parchmentCardAlt,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.accentBrick),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: PixelIcon(
                matrix: condition.pixelMatrix,
                size: 16,
                color: AppColors.accentBrick,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.body(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
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
          ],
        ),
      ),
    );
  }
}
