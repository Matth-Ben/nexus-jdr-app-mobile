import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../../core/widgets/destructive_button.dart';
import '../../../core/widgets/portrait_frame.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/wood_back_header.dart';
import '../../character_creation/presentation/providers/character_creation_draft_provider.dart';
import '../../character_creation/presentation/providers/character_creation_return_route_provider.dart';
import '../../characters/domain/character_failure.dart';
import '../../characters/domain/character_summary.dart';
import '../../characters/presentation/providers/character_providers.dart';
import '../domain/group_character_reassignment_failure.dart';
import '../domain/group_failure.dart';
import 'providers/group_providers.dart';
import 'widgets/group_confirmation_dialog.dart';

const String _genericReassignmentErrorMessage =
    'Impossible de mettre à jour le groupe. Réessayez.';

/// Écran "CHOISIR UN NOUVEAU PERSONNAGE" — affiché à un membre ORPHELIN
/// (voir `GroupMember.isAwaitingCharacter`) dont le précédent personnage a
/// été supprimé, pour qu'il rattache un nouveau personnage à sa ligne
/// `group_members` existante plutôt que d'en créer une nouvelle (voir
/// `GroupRepository.setGroupCharacter`).
///
/// Calque allégé de `GroupJoinScreen`, SANS sheet modale intermédiaire : la
/// liste de personnages s'affiche directement dans la page, sans l'option
/// "MJ sans personnage" (jamais utilisable ici, voir la doc de l'edge
/// function `set-group-character`). Affiché par `GroupScreen`, qui
/// intercepte sa propre construction normale des onglets tant que le membre
/// connecté est orphelin.
class GroupCharacterReassignmentScreen extends ConsumerStatefulWidget {
  const GroupCharacterReassignmentScreen({required this.groupId, super.key});

  final String groupId;

  @override
  ConsumerState<GroupCharacterReassignmentScreen> createState() =>
      _GroupCharacterReassignmentScreenState();
}

class _GroupCharacterReassignmentScreenState
    extends ConsumerState<GroupCharacterReassignmentScreen> {
  String? _selectedCharacterId;
  bool _isSaving = false;
  String? _bannerMessage;

  void _goBack() {
    if (_isSaving) return;
    context.go('/groups');
  }

  void _selectCharacter(String characterId) {
    if (_isSaving) return;
    setState(() => _selectedCharacterId = characterId);
  }

  /// "Créer un personnage" — lance l'assistant de création existant ; au
  /// retour (l'assistant est poussé via `context.push`), rafraîchit
  /// `charactersProvider` pour que le personnage tout juste créé apparaisse
  /// immédiatement dans la liste de cet écran.
  Future<void> _createCharacter() async {
    if (_isSaving) return;
    ref.read(characterCreationDraftControllerProvider.notifier).reset();
    ref.read(characterCreationReturnRouteControllerProvider.notifier).set(null);
    await context.push('/characters/new');
    if (!mounted) return;
    ref.invalidate(charactersProvider);
  }

  Future<void> _confirmLeaveGroup() async {
    if (_isSaving) return;
    final confirmed = await showGroupConfirmationDialog(
      context,
      title: 'Quitter ce groupe ?',
      message:
          "Tu perds l'accès au butin commun et au suivi de tes "
          'coéquipiers.',
      confirmLabel: 'Quitter',
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(groupRepositoryProvider).leaveGroup(widget.groupId);
      if (!mounted) return;
      context.go('/groups');
    } on GroupFailure catch (failure) {
      if (!mounted) return;
      setState(() => _bannerMessage = failure.message);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _bannerMessage = 'Impossible de quitter le groupe. Réessayez.',
      );
    }
  }

  Future<void> _submit() async {
    final characterId = _selectedCharacterId;
    if (characterId == null || _isSaving) return;

    setState(() {
      _isSaving = true;
      _bannerMessage = null;
    });

    try {
      await ref
          .read(groupRepositoryProvider)
          .setGroupCharacter(groupId: widget.groupId, characterId: characterId);
      ref.invalidate(groupDetailProvider(widget.groupId));
      if (!mounted) return;
      context.go('/groups/${widget.groupId}');
    } on GroupCharacterReassignmentFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _bannerMessage = _messageFor(failure.kind);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _bannerMessage = _genericReassignmentErrorMessage;
      });
    }
  }

  String _messageFor(GroupCharacterReassignmentFailureKind kind) {
    return switch (kind) {
      GroupCharacterReassignmentFailureKind.characterNotOwned =>
        "Ce personnage ne t'appartient pas.",
      GroupCharacterReassignmentFailureKind.notMember =>
        "Tu n'es plus membre de ce groupe.",
      GroupCharacterReassignmentFailureKind.notEligible =>
        'Cette action ne te concerne plus.',
      GroupCharacterReassignmentFailureKind.alreadyInGroup =>
        'Ce personnage est déjà membre de ce groupe.',
      GroupCharacterReassignmentFailureKind.generic =>
        _genericReassignmentErrorMessage,
    };
  }

  @override
  Widget build(BuildContext context) {
    final charactersAsync = ref.watch(charactersProvider);

    return Scaffold(
      backgroundColor: AppColors.parchmentBg,
      body: Stack(
        children: [
          Column(
            children: [
              WoodBackHeader(
                title: 'CHOISIR UN NOUVEAU PERSONNAGE',
                onBack: _goBack,
              ),
              Expanded(
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_bannerMessage != null) ...[
                          AlertBanner(message: _bannerMessage!),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        Text(
                          'Ton précédent personnage a été supprimé. Choisis '
                          'celui qui te représentera désormais dans ce '
                          'groupe.',
                          style: AppTypography.body(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const _SectionLabel(
                          'Qui te représente dans ce groupe ?',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildCharacterSection(charactersAsync),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: PrimaryButton(
                    label: 'Confirmer',
                    isLoading: _isSaving,
                    onPressed: (!_isSaving && _selectedCharacterId != null)
                        ? _submit
                        : null,
                  ),
                ),
              ),
            ],
          ),
          if (_isSaving) const _ReassignmentSavingOverlay(),
        ],
      ),
    );
  }

  Widget _buildCharacterSection(
    AsyncValue<List<CharacterSummary>> charactersAsync,
  ) {
    return charactersAsync.when(
      data: (characters) => characters.isEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _NoCharacterNote(),
                const SizedBox(height: AppSpacing.md),
                SecondaryButton(
                  label: 'Créer un personnage',
                  surface: SecondaryButtonSurface.parchment,
                  onPressed: _isSaving ? null : _createCharacter,
                ),
                const SizedBox(height: AppSpacing.sm),
                DestructiveButton(
                  label: 'Quitter le groupe',
                  onPressed: _isSaving ? null : _confirmLeaveGroup,
                ),
              ],
            )
          : Column(
              children: [
                for (final character in characters) ...[
                  _SelectableCharacterRow(
                    character: character,
                    selected: character.id == _selectedCharacterId,
                    onTap: () => _selectCharacter(character.id),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.woodMedium),
        ),
      ),
      error: (error, stackTrace) => _CharacterSectionError(
        message: error is CharacterFailure
            ? error.message
            : 'Impossible de charger vos personnages. Réessayez.',
        onRetry: () => ref.invalidate(charactersProvider),
      ),
    );
  }
}

/// Libellé de section — même gabarit que `GroupJoinScreen::_SectionLabel`,
/// dupliqué ici (classe privée à son fichier, même convention de
/// duplication que le reste de ce module).
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.body(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }
}

/// Ligne sélectionnable de personnage — même patron que
/// `GroupJoinScreen::_SelectableCharacterRow`/
/// `GroupCreateScreen::_SelectableCharacterRow`, dupliqué ici (convention
/// déjà en place dans ce module : classes privées dupliquées par fichier
/// plutôt que partagées).
class _SelectableCharacterRow extends StatelessWidget {
  const _SelectableCharacterRow({
    required this.character,
    required this.selected,
    required this.onTap,
  });

  final CharacterSummary character;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
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
              PortraitFrame(portraitUrl: character.portraitUrl, size: 44),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  character.name,
                  style: AppTypography.body(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _RadioIndicator(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bouton radio 20×20px du design système — duplication volontaire, même
/// convention que `GroupJoinScreen::_RadioIndicator`.
class _RadioIndicator extends StatelessWidget {
  const _RadioIndicator({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.goldEnd : Colors.transparent,
        border: Border.all(
          color: selected ? AppColors.woodDark : AppColors.woodLight,
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }
}

/// État "aucun personnage" — même gabarit que
/// `GroupJoinScreen::_NoCharacterNote`, dupliqué ici avec un texte adapté au
/// contexte de rattachement.
class _NoCharacterNote extends StatelessWidget {
  const _NoCharacterNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.woodLight, width: AppBorders.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 18,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              "Tu n'as pas encore de personnage à rattacher.",
              style: AppTypography.body(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CharacterSectionError extends StatelessWidget {
  const _CharacterSectionError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.woodLight, width: AppBorders.card),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: AppTypography.body(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}

/// Overlay de sauvegarde en cours — calque de
/// `GroupJoinScreen::_JoinSavingOverlay`, dupliqué ici avec un texte adapté.
class _ReassignmentSavingOverlay extends StatelessWidget {
  const _ReassignmentSavingOverlay();

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
                'Mise à jour du groupe...',
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
