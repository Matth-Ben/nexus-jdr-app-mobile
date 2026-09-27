import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Code d'invitation d'un groupe, copiable d'un toucher (demande
/// utilisateur, 2026-09-27 : le code affiché ne pouvait pas être copié).
/// Toute la pastille est tappable ; l'icône « copier » à droite rend
/// l'action visible. Confirmation par un SnackBar, même principe que le lien
/// de partage de fiche (`character_share_screen.dart::_copyLink`).
///
/// Utilisé par l'onglet « Membres » (bandeau affiché juste après la création
/// du groupe) et par les réglages du groupe.
class GroupInviteCodeChip extends StatelessWidget {
  const GroupInviteCodeChip({required this.code, super.key});

  final String code;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Code $code copié.')));
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: "Copier le code d'invitation $code",
      excludeSemantics: true,
      child: Material(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: () => _copy(context),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: AppColors.woodLight,
                width: AppBorders.card,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    code,
                    textAlign: TextAlign.center,
                    style: AppTypography.body(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ).copyWith(letterSpacing: 3),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(
                  Icons.copy_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
