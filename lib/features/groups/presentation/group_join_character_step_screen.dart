import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../character_creation/presentation/providers/character_creation_draft_provider.dart';
import '../../character_creation/presentation/providers/character_creation_return_route_provider.dart';
import '../../characters/domain/character_failure.dart';
import '../../characters/domain/character_summary.dart';
import '../../characters/presentation/providers/character_providers.dart';
import '../../characters/presentation/widgets/character_card.dart';
import '../domain/group_invite_failure.dart';
import 'group_join_routes.dart';
import 'providers/group_providers.dart';
import 'widgets/group_join_step_header.dart';

/// Étape 3/3 du flux "Rejoindre un groupe" : choix du personnage à
/// rattacher — calque exact de
/// `features/join_story/presentation/join_character_step_screen.dart`, un
/// tap sur une carte enchaîne directement `join-group` (overlay de
/// chargement par-dessus cet écran).
class GroupJoinCharacterStepScreen extends ConsumerStatefulWidget {
  const GroupJoinCharacterStepScreen({required this.code, super.key});

  final String code;

  @override
  ConsumerState<GroupJoinCharacterStepScreen> createState() =>
      _GroupJoinCharacterStepScreenState();
}

class _GroupJoinCharacterStepScreenState
    extends ConsumerState<GroupJoinCharacterStepScreen> {
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

  /// "+ Créer un nouveau personnage" : même mécanisme que
  /// `JoinCharacterStepScreen._startCharacterCreation`, route de retour
  /// posée vers cette même étape.
  void _startCharacterCreation() {
    ref.read(characterCreationDraftControllerProvider.notifier).reset();
    ref
        .read(characterCreationReturnRouteControllerProvider.notifier)
        .set(GroupJoinRoutes.character(widget.code));
    context.push('/characters/new');
  }

  Future<void> _join(CharacterSummary character) async {
    setState(() {
      _isJoining = true;
      _bannerMessage = null;
    });

    try {
      final result = await ref
          .read(groupRepositoryProvider)
          .joinGroup(code: widget.code, characterId: character.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Groupe rejoint !')));
      context.go('/groups/${result.groupId}');
    } on GroupInviteFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _isJoining = false;
        _bannerMessage = _bannerMessageFor(failure.kind);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isJoining = false;
        _bannerMessage = 'Impossible de rejoindre ce groupe. Réessayez.';
      });
    }
  }

  String _bannerMessageFor(GroupInviteFailureKind kind) {
    return switch (kind) {
      GroupInviteFailureKind.alreadyInGroup =>
        'Ce personnage est déjà membre de ce groupe.',
      GroupInviteFailureKind.invalidCode =>
        "Ce code d'invitation n'est pas valide.",
      GroupInviteFailureKind.generic =>
        'Impossible de rejoindre ce groupe. Réessayez.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final charactersAsync = ref.watch(charactersProvider);

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              GroupJoinStepHeader(
                stepTitle: 'Choix du personnage',
                currentStep: 3,
                onBack: _goBack,
              ),
              Expanded(
                child: SafeArea(
                  top: false,
                  child: charactersAsync.when(
                    data: (characters) => _buildContent(characters),
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.woodMedium,
                      ),
                    ),
                    error: (error, stackTrace) => _ErrorState(
                      message: error is CharacterFailure
                          ? error.message
                          : 'Impossible de charger vos personnages. '
                                'Réessayez.',
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

  Widget _buildContent(List<CharacterSummary> characters) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
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
            label: '+ Créer un nouveau personnage',
            surface: SecondaryButtonSurface.parchment,
            onPressed: _isJoining ? null : _startCharacterCreation,
          ),
        ],
      ),
    );
  }
}

/// Overlay de rattachement en cours — calque exact de `_JoinSavingOverlay`
/// (`join_character_step_screen.dart`), texte propre à cette étape.
class _JoinSavingOverlay extends StatelessWidget {
  const _JoinSavingOverlay();

  @override
  Widget build(BuildContext context) {
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
                'Rattachement au groupe...',
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
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
              "Tu n'as pas encore de personnage à rattacher.",
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
