import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Section repliable « Options avancées » d'un formulaire (P7) : un en-tête
/// d'au moins 48 dp (icône `expand_more`/`expand_less` + [title]) et un
/// [child] affiché seulement quand la section est dépliée.
///
/// Repliée par défaut ; [initiallyExpanded] la déplie d'emblée (erreur ou
/// valeur non vide en édition). Une fois dépliée par l'utilisateur, elle le
/// reste. `Semantics(expanded)` sur l'en-tête pour les lecteurs d'écran ; le
/// contenu replié n'est pas monté (donc ni focalisable ni lu).
class AdvancedSection extends StatefulWidget {
  const AdvancedSection({
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
    this.forceExpanded = false,
    super.key,
  });

  final String title;
  final Widget child;
  final bool initiallyExpanded;

  /// `true` : déplie la section (ex. une erreur de validation s'y trouve) ;
  /// repasser à `false` ne la replie pas.
  final bool forceExpanded;

  @override
  State<AdvancedSection> createState() => _AdvancedSectionState();
}

class _AdvancedSectionState extends State<AdvancedSection> {
  late bool _expanded = widget.initiallyExpanded || widget.forceExpanded;

  @override
  void didUpdateWidget(AdvancedSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.forceExpanded && !_expanded) _expanded = true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          expanded: _expanded,
          container: true,
          excludeSemantics: true,
          label: widget.title,
          onTap: () => setState(() => _expanded = !_expanded),
          child: InkWell(
            key: const Key('advancedSectionHeader'),
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppTypography.body(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_expanded) widget.child,
      ],
    );
  }
}
