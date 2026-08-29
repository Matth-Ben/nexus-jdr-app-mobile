import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/segmented_toggle.dart';
import '../../domain/rest_type.dart';

/// Ouvre la feuille "Repos" (lien texte "Prendre un repos", en fin de
/// `CharacterVitalsCard`) — sibling direct de `hp_adjustment_sheet.dart`/
/// `add_xp_sheet.dart`, même patron (`showModalBottomSheet`, fond
/// `parchment.card`, `isScrollControlled: true`).
///
/// [onApply] reçoit uniquement le [RestType] choisi par le joueur (un
/// segment est toujours sélectionné, "Repos long" par défaut) : l'appelant
/// (`character_detail_screen.dart`) est responsable d'écrire l'effet en
/// base (`CharacterRepository.applyRest`), de rafraîchir la fiche et
/// d'afficher la confirmation/erreur. La feuille se ferme immédiatement au
/// tap "Appliquer" (fire-and-forget, même patron que `showHpAdjustmentSheet`/
/// `showAddXpSheet`) — écart volontaire par rapport aux 2 feuilles sœurs :
/// l'appelant affiche ensuite un `SnackBar` de confirmation, nécessaire ici
/// car l'effet d'un repos n'est pas toujours visible sur la fiche (repos
/// court, notamment).
Future<void> showRestSheet(
  BuildContext context, {
  required int currentHp,
  required int maxHp,
  required ValueChanged<RestType> onApply,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.parchmentCard,
    isScrollControlled: true,
    builder: (context) =>
        _RestSheetContent(currentHp: currentHp, maxHp: maxHp, onApply: onApply),
  );
}

class _RestSheetContent extends StatefulWidget {
  const _RestSheetContent({
    required this.currentHp,
    required this.maxHp,
    required this.onApply,
  });

  final int currentHp;
  final int maxHp;
  final ValueChanged<RestType> onApply;

  @override
  State<_RestSheetContent> createState() => _RestSheetContentState();
}

class _RestSheetContentState extends State<_RestSheetContent> {
  // Valeur par défaut "Repos long" — spec visuelle direction-artistique.
  RestType _type = RestType.long;

  void _apply() {
    widget.onApply(_type);
    Navigator.of(context).pop();
  }

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
              'Repos',
              style: AppTypography.body(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'PV actuels : ${widget.currentHp} / ${widget.maxHp}',
              style: AppTypography.body(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SegmentedToggle<RestType>(
              options: const [
                SegmentedToggleOption(
                  value: RestType.short,
                  label: 'Repos court',
                ),
                SegmentedToggleOption(
                  value: RestType.long,
                  label: 'Repos long',
                ),
              ],
              value: _type,
              onChanged: (type) => setState(() => _type = type),
            ),
            const SizedBox(height: AppSpacing.sm),
            _RestHelpBlock(type: _type, maxHp: widget.maxHp),
            const SizedBox(height: AppSpacing.md),
            Row(
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
                  // Toujours activé : un segment est toujours sélectionné,
                  // aucune saisie à valider (spec visuelle).
                  child: PrimaryButton(label: 'Appliquer', onPressed: _apply),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bloc d'aide sous la bascule segmentée, dont le contenu dépend du
/// [RestType] sélectionné — spec visuelle direction-artistique.
class _RestHelpBlock extends StatelessWidget {
  const _RestHelpBlock({required this.type, required this.maxHp});

  final RestType type;
  final int maxHp;

  @override
  Widget build(BuildContext context) {
    if (type == RestType.short) {
      return Text(
        'Recharge les aptitudes rechargeables au repos court. Ne restaure '
        "pas de PV : la dépense de dés de vie n'est pas encore prise en "
        'charge par la fiche.',
        style: AppTypography.body(fontSize: 11, color: AppColors.textMuted),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Restaure les PV au maximum, réinitialise les emplacements de '
          'sorts et recharge toutes les aptitudes rechargeables (repos '
          'court comme repos long).',
          style: AppTypography.body(fontSize: 11, color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'PV après repos : $maxHp / $maxHp',
          style: AppTypography.body(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
