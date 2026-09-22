import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/accent_icon_badge.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/selectable_option_tile.dart';
import '../../domain/subclass_choice_catalog.dart';
import '../../domain/subclass_choice_rules.dart';

/// Bloc de choix de sous-classe de l'étape 2/9, inséré juste sous la tuile de
/// la classe sélectionnée (voir `ClassStepScreen`).
///
/// Colonne indentée, sans carte englobante. Quatre états : chargement,
/// erreur (avec « Réessayer »), liste vide (cas défensif, le choix n'est
/// alors pas bloquant) et liste d'options à choix exclusif. L'annonce
/// d'accessibilité est faite une seule fois, dès que les options sont
/// affichées.
class SubclassChoiceBlock extends StatefulWidget {
  const SubclassChoiceBlock({
    required this.classId,
    required this.className,
    required this.catalogAsync,
    required this.selectedSubclassId,
    required this.onSelect,
    required this.onRetry,
    super.key,
  });

  final int classId;
  final String className;
  final AsyncValue<SubclassChoiceCatalog> catalogAsync;
  final int? selectedSubclassId;
  final ValueChanged<int> onSelect;
  final VoidCallback onRetry;

  @override
  State<SubclassChoiceBlock> createState() => _SubclassChoiceBlockState();
}

class _SubclassChoiceBlockState extends State<SubclassChoiceBlock> {
  bool _announced = false;

  @override
  void initState() {
    super.initState();
    _scheduleAnnouncement();
  }

  @override
  void didUpdateWidget(SubclassChoiceBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleAnnouncement();
  }

  void _scheduleAnnouncement() {
    final options = widget.catalogAsync.asData?.value.optionsFor(
      widget.classId,
    );
    if (_announced || options == null || options.isEmpty) return;
    _announced = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SemanticsService.sendAnnouncement(
        View.of(context),
        SubclassChoiceRules.announcementFor(widget.className),
        TextDirection.ltr,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = SubclassChoiceRules.titleFor(widget.className);
    final options = widget.catalogAsync.asData?.value.optionsFor(
      widget.classId,
    );
    final isEmptyChoice =
        widget.catalogAsync.hasValue && (options?.isEmpty ?? false);

    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.md, top: AppSpacing.sm),
      child: Semantics(
        container: true,
        label: isEmptyChoice ? title : '$title, choix obligatoire',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.body(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            _buildBody(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return widget.catalogAsync.when(
      skipLoadingOnRefresh: false,
      loading: () => const SizedBox(
        height: 72,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.woodMedium),
        ),
      ),
      error: (error, stackTrace) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 24,
                  color: AppColors.accentBrick,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Impossible de charger les sous-classes disponibles. '
                    'Réessaie.',
                    style: AppTypography.body(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(
              label: 'Réessayer',
              surface: SecondaryButtonSurface.parchment,
              onPressed: widget.onRetry,
            ),
          ],
        ),
      ),
      data: (catalog) {
        final options = catalog.optionsFor(widget.classId) ?? const [];
        if (options.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              "Aucune sous-classe n'est disponible pour cette classe. Tu "
              'peux continuer sans en choisir.',
              style: AppTypography.body(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ce choix se fait dès le niveau 1 pour cette classe.',
              style: AppTypography.body(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
            if (widget.selectedSubclassId == null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Choisis une option pour continuer.',
                style: AppTypography.body(
                  fontSize: 12,
                  color: AppColors.accentBrick,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.sm),
              SelectableOptionTile(
                title: options[i].name,
                subtitle: options[i].description,
                subtitleMaxLines: null,
                selected: widget.selectedSubclassId == options[i].id,
                leading: AccentIconBadge(index: i, icon: Icons.auto_awesome),
                onTap: () => widget.onSelect(options[i].id),
              ),
            ],
          ],
        );
      },
    );
  }
}
