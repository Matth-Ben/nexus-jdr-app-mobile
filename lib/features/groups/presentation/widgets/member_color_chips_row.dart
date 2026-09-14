import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/dashed_border_painter.dart';
import '../../domain/group_color_assigner.dart';

/// Rangée de puces de couleur, une par identifiant fourni — recettage
/// direction-artistique du 13/09, écran "Groupes — Liste" (`_GroupRow`) :
/// "Row de petits carrés colorés sous le nom [du groupe], un par membre,
/// +1 en pointillé si dépassement". Purement décoratif (voir
/// `GroupColorAssigner`) : aucune information de statut/appartenance n'est
/// déduite de ces couleurs.
///
/// [ids] n'a besoin d'être qu'une liste d'identifiants stables, pas
/// forcément des identifiants de personnage réels — voir l'appelant pour
/// savoir ce qu'il fournit concrètement.
class MemberColorChipsRow extends StatelessWidget {
  const MemberColorChipsRow({
    required this.ids,
    this.maxVisible = 6,
    super.key,
  });

  final List<String> ids;

  /// Au-delà de ce nombre, un badge pointillé "+N" remplace le reste des
  /// puces plutôt que d'allonger la rangée indéfiniment (spec de la tâche :
  /// "au-delà de 5-6 membres visibles" — 6 retenu comme borne haute).
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    final visible = ids.take(maxVisible).toList();
    final overflow = ids.length - visible.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final id in visible) ...[
          _ColorChip(color: GroupColorAssigner.colorFor(id)),
          const SizedBox(width: 4),
        ],
        if (overflow > 0) _ColorChipOverflowBadge(count: overflow),
      ],
    );
  }
}

class _ColorChip extends StatelessWidget {
  const _ColorChip({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.woodLight),
      ),
    );
  }
}

/// Badge pointillé "+N" — identifiants au-delà de
/// [MemberColorChipsRow.maxVisible].
class _ColorChipOverflowBadge extends StatelessWidget {
  const _ColorChipOverflowBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const DashedBorderPainter(color: AppColors.textMuted),
      child: Container(
        height: 16,
        constraints: const BoxConstraints(minWidth: 16),
        padding: const EdgeInsets.symmetric(horizontal: 3),
        alignment: Alignment.center,
        child: Text(
          '+$count',
          style: AppTypography.body(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
