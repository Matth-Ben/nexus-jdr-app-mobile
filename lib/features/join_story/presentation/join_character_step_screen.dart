import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../character_creation/presentation/providers/character_creation_draft_provider.dart';
import '../../character_creation/presentation/providers/character_creation_return_route_provider.dart';
import '../../characters/domain/character_failure.dart';
import '../../characters/domain/character_summary.dart';
import '../../characters/presentation/providers/character_providers.dart';
import '../../characters/presentation/widgets/character_card.dart';
import '../domain/story_invite_failure.dart';
import 'join_routes.dart';
import 'providers/join_story_providers.dart';
import 'widgets/join_step_header.dart';

/// Étape 3/4 du flux "Rejoindre une histoire" : choix du personnage à
/// rattacher — un tap sur une carte sélectionne directement et enchaîne
/// l'étape 4/4 (overlay de chargement par-dessus cet écran, pas de second
/// tap de confirmation, voir la spec visuelle de la tâche).
///
/// Réutilise `charactersProvider`/`CharacterCard` tels quels (mêmes fichiers
/// que `character_list_screen.dart`).
class JoinCharacterStepScreen extends ConsumerStatefulWidget {
  const JoinCharacterStepScreen({required this.code, super.key});

  final String code;

  @override
  ConsumerState<JoinCharacterStepScreen> createState() =>
      _JoinCharacterStepScreenState();
}

class _JoinCharacterStepScreenState
    extends ConsumerState<JoinCharacterStepScreen> {
  bool _isJoining = false;
  String? _bannerMessage;

  void _goBack() {
    if (_isJoining) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  /// "+ Créer un nouveau personnage" : lance l'assistant de création
  /// existant, en posant une route de retour vers CETTE étape (avec le code
  /// déjà résolu) — voir la documentation de classe de
  /// `CharacterCreationReturnRouteController` pour le rationale du
  /// mécanisme choisi.
  void _startCharacterCreation() {
    ref.read(characterCreationDraftControllerProvider.notifier).reset();
    ref
        .read(characterCreationReturnRouteControllerProvider.notifier)
        .set(JoinRoutes.character(widget.code));
    context.push('/characters/new/edition');
  }

  /// Tap sur une `CharacterCard` : déclenche directement le rattachement
  /// (étape 4/4, `join-story`) — overlay de chargement par-dessus cet écran
  /// pendant l'appel réseau, voir [_JoinSavingOverlay].
  Future<void> _join(CharacterSummary character) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isJoining = true;
      _bannerMessage = null;
    });

    try {
      final result = await ref
          .read(storyInviteRepositoryProvider)
          .joinStory(code: widget.code, characterId: character.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.joinCharacterStepScreenJoinedSnackbar)),
      );
      context.go('/characters/${result.characterId}');
    } on StoryInviteFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _isJoining = false;
        _bannerMessage = _bannerMessageFor(l10n, failure.kind);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isJoining = false;
        _bannerMessage = l10n.joinCharacterStepScreenGenericErrorMessage;
      });
    }
  }

  /// Libellés du bandeau d'alerte inline (spec visuelle, étape 4/4 —
  /// échec) : [StoryInviteFailureKind.invalidCode]/[inviteDisabled]
  /// reprennent le même libellé principal que l'étape 2/4 (cas de course
  /// improbable — le code a été validé à l'étape 2/4, mais peut avoir été
  /// invalidé/désactivé entre-temps par le MJ).
  String _bannerMessageFor(AppLocalizations l10n, StoryInviteFailureKind kind) {
    return switch (kind) {
      StoryInviteFailureKind.alreadyJoined =>
        l10n.joinCharacterStepScreenAlreadyJoinedErrorMessage,
      StoryInviteFailureKind.invalidCode =>
        l10n.joinCharacterStepScreenInvalidCodeErrorMessage,
      StoryInviteFailureKind.inviteDisabled =>
        l10n.joinCharacterStepScreenInviteDisabledErrorMessage,
      StoryInviteFailureKind.characterNotOwned ||
      StoryInviteFailureKind.generic =>
        l10n.joinCharacterStepScreenGenericErrorMessage,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final charactersAsync = ref.watch(charactersProvider);

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              JoinStepHeader(
                stepTitle: l10n.joinCharacterStepScreenStepTitle,
                currentStep: 3,
                onBack: _goBack,
              ),
              Expanded(
                child: SafeArea(
                  top: false,
                  child: charactersAsync.when(
                    data: (characters) => _buildContent(l10n, characters),
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.woodMedium,
                      ),
                    ),
                    error: (error, stackTrace) => _ErrorState(
                      message: error is CharacterFailure
                          ? error.message
                          : l10n.joinCharacterStepScreenCharactersLoadErrorMessage,
                      onRetry: () => ref.invalidate(charactersProvider),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isJoining) const _JoinSavingOverlay(),
        ],
      ),
    );
  }

  Widget _buildContent(
    AppLocalizations l10n,
    List<CharacterSummary> characters,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          if (characters.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.joinCharacterStepScreenQuestionLabel,
                style: AppTypography.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (_bannerMessage != null) ...[
            AlertBanner(message: _bannerMessage!),
            const SizedBox(height: AppSpacing.sm),
          ],
          Expanded(
            child: characters.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    itemCount: characters.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final character = characters[index];
                      return CharacterCard(
                        character: character,
                        onTap: _isJoining ? null : () => _join(character),
                      );
                    },
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(
            label: l10n.joinCharacterStepScreenCreateCharacterButton,
            surface: SecondaryButtonSurface.parchment,
            onPressed: _isJoining ? null : _startCharacterCreation,
          ),
        ],
      ),
    );
  }
}

/// Overlay de rattachement en cours — calque exact de `_SavingOverlay` de
/// `xml_import/presentation/xml_import_review_screen.dart` (scrim
/// `wood.dark` 60%, carte `parchment.card` centrée, spinner `wood.medium`),
/// texte propre à cette étape ("Rattachement à l'histoire...").
class _JoinSavingOverlay extends StatelessWidget {
  const _JoinSavingOverlay();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ColoredBox(
      color: AppColors.woodDark.withValues(alpha: 0.6),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.parchmentCard,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.woodLight,
              width: AppBorders.cardEmphasis,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.woodMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.joinCharacterStepScreenJoiningOverlayMessage,
                style: AppTypography.body(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// État vide (aucun personnage à rattacher) — mêmes 3 états que
/// `character_list_screen.dart`, rejoués dans ce cadre parchemin (couleurs
/// `textPrimary`/`textSecondary` plutôt que `textOnWood`/`textOnWoodMuted`,
/// voir la spec visuelle de la tâche). Le bouton "+ Créer" du bas reste
/// affiché même dans cet état (voir [JoinCharacterStepScreen._buildContent]).
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shield_moon_outlined,
              size: 56,
              color: AppColors.goldEnd,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.joinCharacterStepScreenEmptyStateMessage,
              textAlign: TextAlign.center,
              style: AppTypography.body(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
              label: l10n.joinCharacterStepScreenRetryButton,
              surface: SecondaryButtonSurface.parchment,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
