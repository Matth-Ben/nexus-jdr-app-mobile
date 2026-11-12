import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/destructive_button.dart';
import '../../../../l10n/app_localizations.dart';

/// Barre d'action en pied de `CharacterListScreen` pendant le mode
/// sélection multiple — remplace la `Row` "+ Créer"/"Importer XML" (mode
/// normal) tant que ce mode est actif. Même fond que
/// `character_detail_tab_bar.dart::CharacterDetailTabBar` (`wood.medium` +
/// `SafeArea(top: false)`), gabarit visuel direction-artistique dédié.
class CharacterSelectionActionBar extends StatelessWidget {
  const CharacterSelectionActionBar({
    required this.selectedCount,
    required this.onCancel,
    required this.onDelete,
    this.isDeleting = false,
    super.key,
  });

  final int selectedCount;

  /// Sort du mode sélection et désélectionne tout. Désactivé pendant une
  /// suppression en cours (voir [isDeleting]) : éviter de quitter le mode
  /// sélection alors qu'une suppression réseau est encore en vol pour les
  /// personnages actuellement sélectionnés.
  final VoidCallback onCancel;

  /// `null` désactive le bouton "Supprimer" (aucune sélection).
  final VoidCallback? onDelete;

  /// `true` : suppression groupée en cours — voir
  /// `DestructiveButton.isLoading`.
  final bool isDeleting;

  static const double _minHeight = 56;

  /// Facteur de police au-delà duquel la barre passe en colonne.
  static const double _stackedTextScale = 1.1;

  /// Largeur disponible en deçà de laquelle la barre passe en colonne.
  static const double _narrowWidth = 300;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // À police agrandie, le texte coincé entre « Annuler » et « Supprimer »
    // n'aurait plus que quelques pixels de large (une lettre par ligne) : il
    // prend alors toute la largeur et les deux boutons passent dessous.
    final largeText =
        MediaQuery.textScalerOf(context).scale(14) / 14 > _stackedTextScale;
    final count = Text(
      l10n.characterSelectionActionBarSelectedCount(selectedCount),
      textAlign: TextAlign.center,
      style: AppTypography.body(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textOnWood,
      ),
    );
    final cancel = _CancelButton(
      enabled: !isDeleting,
      onTap: onCancel,
      label: l10n.characterSelectionActionBarCancelButton,
    );
    final deleteButton = DestructiveButton(
      filled: true,
      label: l10n.characterSelectionActionBarDeleteButton,
      isLoading: isDeleting,
      onPressed: onDelete,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        // Étroit : même à police normale, le texte n'aurait que ~50 px entre
        // les deux boutons (écran de 320 dp).
        final stacked = largeText || constraints.maxWidth < _narrowWidth;
        return ColoredBox(
          color: AppColors.woodMedium,
          child: SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _minHeight),
              child: Padding(
                // En colonne, marges réduites : chaque pixel compte pour le
                // plus long mot du texte à police agrandie.
                padding: EdgeInsets.symmetric(
                  horizontal: stacked ? AppSpacing.sm : AppSpacing.lg,
                ),
                child: stacked
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            count,
                            const SizedBox(height: AppSpacing.sm),
                            cancel,
                            const SizedBox(height: AppSpacing.xs),
                            deleteButton,
                          ],
                        ),
                      )
                    : Row(
                        children: [
                          cancel,
                          Expanded(child: Center(child: count)),
                          deleteButton,
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Lien "Annuler" (texte seul, pas de bordure) — zone de tap ≥44×44 malgré
/// l'absence d'habillage visuel (contrainte d'accessibilité, même principe
/// que `character_list_screen.dart::_FilterButton`/`_ProfileButton`).
class _CancelButton extends StatelessWidget {
  const _CancelButton({
    required this.enabled,
    required this.onTap,
    required this.label,
  });

  final bool enabled;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Container(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          alignment: Alignment.center,
          child: Opacity(
            opacity: enabled ? 1 : 0.6,
            child: Text(
              label,
              style: AppTypography.body(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textOnWood,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
