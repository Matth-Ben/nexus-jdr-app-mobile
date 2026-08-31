import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/portrait_frame.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../domain/story_invite_failure.dart';
import '../domain/story_preview.dart';
import 'join_routes.dart';
import 'providers/join_story_providers.dart';
import 'widgets/join_step_header.dart';

/// Message générique réseau — même texte que
/// `features/characters/data/character_error_mapper.dart::_networkErrorMessage`
/// (déjà réutilisé partout ailleurs dans l'app pour ce cas), dupliqué ici
/// plutôt qu'importé depuis la feature `characters` : même principe de
/// duplication assumée que le reste de ce dépôt (voir la documentation de
/// classe de `RaceRowMapper`).
const String _genericNetworkErrorMessage =
    'Impossible de contacter le serveur. Vérifiez votre connexion internet '
    'et réessayez.';

/// Étape 2/4 du flux "Rejoindre une histoire" : confirmation (nom + image de
/// couverture de l'histoire), avant tout engagement — `preview-story-invite`
/// est appelée au chargement de cette étape, `join-story` ne l'est qu'à
/// l'étape 4/4 (`presentation/join_character_step_screen.dart`).
///
/// Atteinte soit normalement (poussée par l'étape 1/4 avec `?code=...`),
/// soit directement via le deep link `nexus-jdr.app/join/{code}` (route
/// `/join/:code`, voir `core/router/app_router.dart`) — les deux cas
/// utilisent exactement ce même écran, [code] étant simplement résolu
/// depuis une source différente par le routeur.
class JoinConfirmationStepScreen extends ConsumerWidget {
  const JoinConfirmationStepScreen({required this.code, super.key});

  final String code;

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  /// "Modifier le code" (erreurs code invalide/invitation désactivée) :
  /// repousse l'étape 1/4 avec [code] pré-rempli — jamais un simple retour
  /// arrière, qui échouerait silencieusement si cette étape a été atteinte
  /// directement via le deep link (aucune étape 1/4 dans la pile dans ce
  /// cas, voir la documentation de classe).
  void _editCode(BuildContext context) {
    context.push(JoinRoutes.code(initialCode: code));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewAsync = ref.watch(storyInvitePreviewProvider(code: code));

    return Scaffold(
      body: previewAsync.when(
        data: (preview) => Column(
          children: [
            JoinStepHeader(
              stepTitle: 'Confirmation',
              currentStep: 2,
              onBack: () => _goBack(context),
            ),
            Expanded(child: _buildConfirmation(context, preview)),
          ],
        ),
        loading: () => Column(
          children: [
            JoinStepMinimalHeader(onBack: () => _goBack(context)),
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.woodMedium),
              ),
            ),
          ],
        ),
        error: (error, stackTrace) => Column(
          children: [
            JoinStepMinimalHeader(onBack: () => _goBack(context)),
            Expanded(child: _buildError(context, ref, error)),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmation(BuildContext context, StoryPreview preview) {
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
                    PortraitFrame(
                      portraitUrl: preview.coverUrl,
                      size: 120,
                      fallbackIcon: Icons.auto_stories,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      preview.title,
                      textAlign: TextAlign.center,
                      // Jamais `font.display` : un nom d'histoire est une
                      // donnée saisie par un MJ, pas un titre décoratif —
                      // même exception déjà actée pour `CharacterCard.name`
                      // et le nom saisi de `SummaryStepScreen`.
                      style: AppTypography.body(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            PrimaryButton(
              label: 'Rejoindre',
              onPressed: () => context.push(JoinRoutes.character(code)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    final kind = error is StoryInviteFailure
        ? error.kind
        : StoryInviteFailureKind.generic;

    return switch (kind) {
      StoryInviteFailureKind.invalidCode => _CodeErrorState(
        message: 'Ce code d\'invitation n\'est pas valide.',
        secondaryMessage: 'Vérifie le code transmis par ton MJ et réessaye.',
        onEditCode: () => _editCode(context),
      ),
      StoryInviteFailureKind.inviteDisabled => _CodeErrorState(
        message: 'Cette invitation a été désactivée.',
        secondaryMessage: 'Demande à ton MJ de générer un nouveau lien.',
        onEditCode: () => _editCode(context),
      ),
      StoryInviteFailureKind.characterNotOwned ||
      StoryInviteFailureKind.alreadyJoined ||
      StoryInviteFailureKind.generic => _NetworkErrorState(
        message: _genericNetworkErrorMessage,
        onRetry: () => ref.invalidate(storyInvitePreviewProvider(code: code)),
      ),
    };
  }
}

/// État d'erreur "code invalide"/"invitation désactivée" — icône alerte,
/// message principal, message secondaire, bouton "Modifier le code" (jamais
/// "Réessayer" : relancer le même appel échouerait à l'identique).
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

/// État d'erreur réseau/générique — même patron que le reste de l'app
/// (message + "Réessayer").
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
