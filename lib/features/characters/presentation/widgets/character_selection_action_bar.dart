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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ColoredBox(
      color: AppColors.woodMedium,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _minHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                _CancelButton(
                  enabled: !isDeleting,
                  onTap: onCancel,
                  label: l10n.characterSelectionActionBarCancelButton,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      l10n.characterSelectionActionBarSelectedCount(
                        selectedCount,
                      ),
                      style: AppTypography.body(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textOnWood,
                      ),
                    ),
                  ),
                ),
                DestructiveButton(
                  filled: true,
                  label: l10n.characterSelectionActionBarDeleteButton,
                  isLoading: isDeleting,
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
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
