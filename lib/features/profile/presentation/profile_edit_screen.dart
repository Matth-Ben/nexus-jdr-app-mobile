import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/wood_back_header.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import 'widgets/avatar_edit_sheet.dart';
import 'widgets/change_email_sheet.dart';
import 'widgets/change_password_sheet.dart';
import 'widgets/edit_display_name_sheet.dart';

/// Sous-écran "Modifier le profil", route `/profile/edit` — poussé depuis la
/// tuile "Modifier le profil" de `profile_screen.dart` (qui ouvrait
/// auparavant directement `showEditDisplayNameSheet`, désormais réduite à
/// une des 4 lignes de cet écran).
///
/// Gabarit B (`WoodBackHeader` + corps parchemin scrollable), 4 lignes —
/// pseudo/avatar/mot de passe/adresse email — chacune ouvrant sa propre
/// sheet (ou l'écran de recadrage pour l'avatar) au tap. Pas de bandeau
/// d'identité dupliqué (spec direction-artistique de la tâche) : chaque
/// ligne montre déjà sa valeur courante, un second avatar/pseudo/email en
/// tête d'écran serait redondant avec `profile_screen.dart` juste en
/// dessous dans la pile de navigation.
///
/// Lecture pseudo/avatar/e-mail synchrone (`currentUserProvider`, déjà en
/// mémoire) : ni état de chargement ni appel réseau à l'ouverture de cet
/// écran — même remarque que `ProfileScreen`.
class ProfileEditScreen extends ConsumerWidget {
  const ProfileEditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final rawDisplayName = (user?.userMetadata?['full_name'] as String?)
        ?.trim();
    final displayName = (rawDisplayName == null || rawDisplayName.isEmpty)
        ? 'Aventurier'
        : rawDisplayName;
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.parchmentBg,
      body: Column(
        children: [
          WoodBackHeader(
            title: 'MODIFIER LE PROFIL',
            onBack: () => _goBack(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  _ProfileEditRow(
                    title: 'Pseudo',
                    value: displayName,
                    onTap: () => showEditDisplayNameSheet(context),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ProfileEditRow(
                    title: 'Avatar',
                    value: (avatarUrl == null || avatarUrl.isEmpty)
                        ? 'Aucune photo'
                        : 'Photo définie',
                    onTap: () => showAvatarEditSheet(
                      context,
                      ref: ref,
                      avatarUrl: avatarUrl,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ProfileEditRow(
                    title: 'Mot de passe',
                    value: '••••••••',
                    onTap: () => showChangePasswordSheet(context),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ProfileEditRow(
                    title: 'Email',
                    value: email,
                    onTap: () =>
                        showChangeEmailSheet(context, currentEmail: email),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Même garde que `ProfileScreen._goBack` : cet écran est normalement
  /// toujours atteint via `context.push('/profile/edit')` (donc
  /// `canPop()` vrai), mais reste défensif si jamais poussé un jour comme
  /// route initiale (deep link).
  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }
}

/// Une des 4 lignes de `ProfileEditScreen` — libellé à gauche, valeur
/// condensée à droite, icône crayon dans une zone de tap 44×44px. Copie de
/// `features/character_creation/presentation/summary_step_screen.dart::
/// _SummaryRow` (spec direction-artistique de la tâche, extraction en
/// composant partagé volontairement écartée pour un 2e usage seulement —
/// seuil d'extraction habituel de ce dépôt (3e usage), voir `SheetHeaderBar`/
/// `SheetActionRow`).
class _ProfileEditRow extends StatelessWidget {
  const _ProfileEditRow({
    required this.title,
    required this.value,
    required this.onTap,
  });

  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.parchmentCard,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.woodLight,
              width: AppBorders.card,
            ),
          ),
          child: Row(
            children: [
              Text(
                title,
                style: AppTypography.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
