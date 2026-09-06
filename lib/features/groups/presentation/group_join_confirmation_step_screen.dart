import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/portrait_frame.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../domain/group_invite_failure.dart';
import '../domain/group_preview.dart';
import 'group_join_routes.dart';
import 'providers/group_providers.dart';
import 'widgets/group_join_step_header.dart';

/// Message générique réseau — même texte que
/// `features/characters/data/character_error_mapper.dart::_networkErrorMessage`
/// (voir `join_confirmation_step_screen.dart` pour le même choix de
/// duplication).
const String _genericNetworkErrorMessage =
    'Impossible de contacter le serveur. Vérifiez votre connexion internet '
    'et réessayez.';

/// Étape 2/3 du flux "Rejoindre un groupe" : confirmation (nom + nombre de
/// membres du groupe), avant tout engagement — `preview-group-invite` est
/// appelée au chargement de cette étape, `join-group` ne l'est qu'à l'étape
/// 3/3. Calque exact de
/// `features/join_story/presentation/join_confirmation_step_screen.dart`,
/// avec **seulement 2 cas d'erreur** (contrairement au flux "Rejoindre une
/// histoire") : un groupe n'a pas de notion "invitation désactivée" — voir
/// `docs/cahier-des-charges/12-partage-et-groupes.md` section 2.
class GroupJoinConfirmationStepScreen extends ConsumerWidget {
  const GroupJoinConfirmationStepScreen({required this.code, super.key});

  final String code;

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  /// "Modifier le code" (code invalide) : repousse l'étape 1/3 avec [code]
  /// pré-rempli.
  void _editCode(BuildContext context) {
    context.push(GroupJoinRoutes.code(initialCode: code));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewAsync = ref.watch(groupInvitePreviewProvider(code: code));

    return Scaffold(
      body: previewAsync.when(
        data: (preview) => Column(
          children: [
            GroupJoinStepHeader(
              stepTitle: 'Confirmation',
              currentStep: 2,
              onBack: () => _goBack(context),
            ),
            Expanded(child: _buildConfirmation(context, preview)),
          ],
        ),
        loading: () => Column(
          children: [
            GroupJoinStepMinimalHeader(onBack: () => _goBack(context)),
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.woodMedium),
              ),
            ),
          ],
        ),
        error: (error, stackTrace) => Column(
          children: [
            GroupJoinStepMinimalHeader(onBack: () => _goBack(context)),
            Expanded(child: _buildError(context, ref, error)),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmation(BuildContext context, GroupPreview preview) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const PortraitFrame(
                      portraitUrl: null,
                      size: 120,
                      fallbackIcon: Icons.groups,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      preview.name,
                      textAlign: TextAlign.center,
                      // Jamais `font.display` : un nom de groupe est une
                      // donnée saisie par un joueur, pas un titre décoratif —
                      // même exception que `JoinConfirmationStepScreen`.
                      style: AppTypography.body(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${preview.memberCount} membres',
                      textAlign: TextAlign.center,
                      style: AppTypography.body(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            PrimaryButton(
              label: 'Rejoindre',
              onPressed: () => context.push(GroupJoinRoutes.character(code)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    final kind = error is GroupInviteFailure
        ? error.kind
        : GroupInviteFailureKind.generic;

    return switch (kind) {
      GroupInviteFailureKind.invalidCode => _CodeErrorState(
        message: "Ce code d'invitation n'est pas valide.",
        secondaryMessage:
            'Vérifie le code transmis par le créateur du groupe et réessaye.',
        onEditCode: () => _editCode(context),
      ),
      GroupInviteFailureKind.alreadyInGroup ||
      GroupInviteFailureKind.generic => _NetworkErrorState(
        message: _genericNetworkErrorMessage,
        onRetry: () => ref.invalidate(groupInvitePreviewProvider(code: code)),
      ),
    };
  }
}

/// État d'erreur "code invalide" — calque exact de
/// `join_confirmation_step_screen.dart::_CodeErrorState`.
class _CodeErrorState extends StatelessWidget {
  const _CodeErrorState({
    required this.message,
    required this.secondaryMessage,
    required this.onEditCode,
  });

  final String message;
  final String secondaryMessage;
  final VoidCallback onEditCode;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.accentBrick,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.body(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              secondaryMessage,
              textAlign: TextAlign.center,
              style: AppTypography.body(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: SecondaryButton(
                label: 'Modifier le code',
                surface: SecondaryButtonSurface.parchment,
                onPressed: onEditCode,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// État d'erreur réseau/générique.
class _NetworkErrorState extends StatelessWidget {
  const _NetworkErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.accentBrick,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.body(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(
              label: 'Réessayer',
              surface: SecondaryButtonSurface.parchment,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
