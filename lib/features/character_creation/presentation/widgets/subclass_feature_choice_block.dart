import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/accent_icon_badge.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/selectable_option_tile.dart';
import '../../domain/creation_step_help.dart';
import '../../domain/subclass_feature_choice.dart';
import 'step_help_sheet.dart';

/// Second choix de niveau 1 propre à la sous-classe choisie (ex. Ancêtre
/// draconique du Lignage draconique, Ensorceleur) — correctif D99
/// (`docs/dette-technique.md`), inséré juste sous `SubclassChoiceBlock` dans
/// `presentation/subclass_step_screen.dart`, séparé par
/// `SizedBox(height: AppSpacing.md)`.
///
/// Reprend EXACTEMENT la structure visuelle de [SubclassChoiceBlock] (voir
/// sa doc de classe) : colonne indentée, sans carte englobante, 4 états
/// (chargement, erreur avec « Réessayer », liste vide défensive non
/// bloquante, liste d'options à choix exclusif). Seules les icônes diffèrent
/// : cycle standard à 4 couleurs d'accent (`AccentIconBadge` sans couleur
/// explicite) avec une icône unique `Icons.whatshot` — pas de couleur par
/// type de dragon (spec direction-artistique).
///
/// N'est monté par [SubclassStepScreen] que lorsqu'une sous-classe est déjà
/// sélectionnée (voir l'appelant) : [subclassId] est donc toujours défini à
/// ce stade, contrairement à [SubclassChoiceBlock] qui, lui, n'a besoin que
/// de [classId].
class SubclassFeatureChoiceBlock extends StatefulWidget {
  const SubclassFeatureChoiceBlock({
    required this.subclassId,
    required this.catalogAsync,
    required this.selectedOptionName,
    required this.onSelect,
    required this.onRetry,
    super.key,
  });

  final int subclassId;
  final AsyncValue<SubclassFeatureChoice?> catalogAsync;
  final String? selectedOptionName;
  final ValueChanged<String> onSelect;
  final VoidCallback onRetry;

  @override
  State<SubclassFeatureChoiceBlock> createState() =>
      _SubclassFeatureChoiceBlockState();
}

class _SubclassFeatureChoiceBlockState
    extends State<SubclassFeatureChoiceBlock> {
  bool _announced = false;

  @override
  void initState() {
    super.initState();
    _scheduleAnnouncement();
  }

  @override
  void didUpdateWidget(SubclassFeatureChoiceBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subclassId != widget.subclassId) {
      _announced = false;
    }
    _scheduleAnnouncement();
  }

  void _scheduleAnnouncement() {
    final choice = widget.catalogAsync.asData?.value;
    final options = choice?.options;
    if (_announced || choice == null || options == null || options.isEmpty) {
      return;
    }
    _announced = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SemanticsService.sendAnnouncement(
        View.of(context),
        'Choisis ${_articleFor(choice.featureName)}.',
        TextDirection.ltr,
      );
    });
  }

  /// Formule générique "Choisis ton/ta/ses [aptitude]." — contrairement à
  /// `SubclassChoiceRules.announcementFor` (3 libellés fixes connus), cette
  /// aptitude est résolue depuis les données (`featureName`), jamais une
  /// liste de noms de classe codée en dur : accord neutre "le choix de"
  /// plutôt qu'un genre deviné à tort.
  static String _articleFor(String featureName) =>
      'le choix de ${featureName.toLowerCase()}';

  @override
  Widget build(BuildContext context) {
    final choice = widget.catalogAsync.asData?.value;
    final options = choice?.options;
    final isEmptyChoice =
        widget.catalogAsync.hasValue &&
        choice != null &&
        (options?.isEmpty ?? false);
    final title = choice?.featureName ?? 'Choix de sous-classe';

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
                    'Impossible de charger ce choix de sous-classe. '
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
      data: (choice) {
        // Sous-classe sans second choix de niveau 1 (immense majorité) :
        // rien à afficher — ni message défensif (réservé au cas où la ligne
        // `class_features` existe mais les `class_options` manquent, voir
        // D95), ni blocage.
        if (choice == null) return const SizedBox.shrink();

        final options = choice.options;
        if (options.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              "Aucune option n'est disponible pour ce choix. Tu peux "
              'continuer sans en faire.',
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
              'Ce choix se fait dès le niveau 1 de ta sous-classe.',
              style: AppTypography.body(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
            if (widget.selectedOptionName == null) ...[
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
                onInfo: options[i].description == null
                    ? null
                    : () => showStepHelpSheet(
                        context,
                        StepHelpContent(
                          title: options[i].name,
                          body: options[i].description!,
                        ),
                      ),
                selected: widget.selectedOptionName == options[i].name,
                leading: AccentIconBadge(index: i, icon: Icons.whatshot),
                onTap: () => widget.onSelect(options[i].name),
              ),
            ],
          ],
        );
      },
    );
  }
}
