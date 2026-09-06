import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/wood_back_header.dart';
import '../../characters/domain/character_failure.dart';
import '../../characters/domain/character_summary.dart';
import '../../characters/presentation/providers/character_providers.dart';
import '../../characters/presentation/widgets/character_card.dart';
import '../domain/group_failure.dart';
import 'providers/group_providers.dart';

/// Écran "Créer un groupe", route `/groups/new` —
/// `docs/cahier-des-charges/12-partage-et-groupes.md` section 2.
///
/// `WoodBackHeader` + corps parchemin scrollable (même gabarit que
/// `ProfileEditScreen`) : champ "NOM DU GROUPE" (même patron que
/// `edit_display_name_sheet.dart`), puis la liste des personnages du joueur
/// (`charactersProvider`) à sélection exclusive (chargement/erreur/vide même
/// patron que `join_character_step_screen.dart`).
class GroupCreateScreen extends ConsumerStatefulWidget {
  const GroupCreateScreen({super.key});

  @override
  ConsumerState<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends ConsumerState<GroupCreateScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedCharacterId;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_handleChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_handleChanged);
    _nameController.dispose();
    super.dispose();
  }

  void _handleChanged() {
    if (mounted) setState(() {});
  }

  void _goBack() {
    if (_isSaving) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  void _selectCharacter(String characterId) {
    if (_isSaving) return;
    setState(() => _selectedCharacterId = characterId);
  }

  bool get _canSubmit =>
      !_isSaving &&
      _nameController.text.trim().isNotEmpty &&
      _selectedCharacterId != null;

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final characterId = _selectedCharacterId;
    if (name.isEmpty || characterId == null || _isSaving) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final created = await ref
          .read(groupRepositoryProvider)
          .createGroup(name: name, characterId: characterId);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Groupe créé !')));
      context.go('/groups/${created.id}');
    } on GroupFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = failure.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = 'Impossible de créer le groupe. Réessayez.';
      });
    }
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
              WoodBackHeader(title: 'CRÉER UN GROUPE', onBack: _goBack),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null) ...[
                      AlertBanner(message: _errorMessage!),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    Text(
                      'NOM DU GROUPE',
                      style: AppTypography.body(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextFormField(
                      controller: _nameController,
                      enabled: !_isSaving,
                      minLines: 1,
                      maxLines: 1,
                      decoration: const InputDecoration(
                        hintText: 'Ex. Les Lames de l\'Aube',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: charactersAsync.when(
                  data: _buildCharacterList,
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.woodMedium,
                    ),
                  ),
                  error: (error, stackTrace) => _ErrorState(
                    message: error is CharacterFailure
                        ? error.message
                        : 'Impossible de charger vos personnages. Réessayez.',
                    onRetry: () => ref.invalidate(charactersProvider),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: PrimaryButton(
                  label: 'Créer le groupe',
                  onPressed: _canSubmit ? _submit : null,
                ),
              ),
            ],
          ),
          if (_isSaving) const _CreatingGroupOverlay(),
        ],
      ),
    );
  }

  Widget _buildCharacterList(List<CharacterSummary> characters) {
    if (characters.isEmpty) {
      return const _EmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: characters.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final character = characters[index];
        return _SelectableCharacterRow(
          character: character,
          selected: character.id == _selectedCharacterId,
          onTap: () => _selectCharacter(character.id),
        );
      },
    );
  }
}

/// Une ligne de la liste de personnages — réutilise `CharacterCard` pour le
/// visuel (`onTap: null` : le tap est géré par l'`InkWell` englobant, pas par
/// la carte elle-même), avec un bouton radio 20×20 en fin de ligne
/// (sélection exclusive) — voir la spec de la tâche "Système de groupe".
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: IgnorePointer(
                  child: CharacterCard(character: character),
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

/// Bouton radio 20×20px du design système — duplication volontaire de
/// `core/widgets/selectable_option_tile.dart::_RadioIndicator` (classe
/// privée à ce fichier, non partageable telle quelle) : même convention de
/// duplication que le reste de ce dépôt (voir `GroupMemberRowMapper`).
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

class _CreatingGroupOverlay extends StatelessWidget {
  const _CreatingGroupOverlay();

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
                'Création du groupe...',
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
              "Tu n'as pas encore de personnage à inscrire dans ce groupe.",
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
