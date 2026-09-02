import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Séparateur 1px `#E0D2AB` entre deux [SheetActionRow] — composant
/// partagé, extrait de
/// `features/characters/presentation/widgets/portrait_upload_sheet.dart`
/// (`_SheetDivider`).
class SheetActionDivider extends StatelessWidget {
  const SheetActionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: Color(0xFFE0D2AB));
  }
}

/// Ligne d'action de bottom sheet (icône 20px + libellé `body 600 14px`,
/// hauteur mini 48px) — composant partagé (`core/widgets/`), extrait de
/// `features/characters/presentation/widgets/portrait_upload_sheet.dart`
/// (`_SheetRow`) : 3e usage identique (sheets "Actions de sort"/"Actions
/// d'aptitude" de la fiche personnage), factorisé ici plutôt que dupliqué
/// une 3e fois.
///
/// Généralisé par rapport à l'original avec [enabled]/[trailingText]/
/// [trailingTextColor] (besoin des nouvelles sheets d'actions, ex. "Aucun
/// emplacement"/"Épuisée") : [enabled] à `false` désactive le tap
/// (`onTap` ignoré) et applique une `Opacity(0.45)` sur toute la ligne,
/// [trailingText] affiche un libellé de fin (aligné à droite) dans
/// [trailingTextColor].
class SheetActionRow extends StatelessWidget {
  const SheetActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.enabled = true,
    this.trailingText,
    this.trailingTextColor,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  /// `false` : `Opacity(0.45)`, tap ignoré — voir la documentation de
  /// classe.
  final bool enabled;

  /// Libellé de fin optionnel (ex. "Aucun emplacement"/"Épuisée"), affiché
  /// uniquement quand fourni — indépendant de [enabled] (toujours affiché
  /// s'il est non nul), mais n'a de sens en pratique qu'avec `enabled:
  /// false` (voir les sheets d'actions de sort/aptitude).
  final String? trailingText;
  final Color? trailingTextColor;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.textPrimary;
    final row = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(icon, color: effectiveColor, size: 20),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.body(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: effectiveColor,
                    ),
                  ),
                ),
                if (trailingText != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    trailingText!,
                    style: AppTypography.body(
                      fontSize: 11,
                      color: trailingTextColor ?? AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return enabled ? row : Opacity(opacity: 0.45, child: row);
  }
}
