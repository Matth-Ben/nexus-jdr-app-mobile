import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../../core/widgets/portrait_frame.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/sheet_header_bar.dart';
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
/// `ProfileEditScreen`) : texte d'intro, champ "Nom du groupe" (même patron
/// que `edit_display_name_sheet.dart`), puis le choix du personnage du
/// joueur (`charactersProvider`) — recettage direction-artistique du
/// 13/09/2026 : la sélection se fait désormais via une tuile unique
/// affichant le personnage choisi (voir [_CharacterSelectorTile]), qui ouvre
/// au tap une bottom sheet reprenant la liste radio exclusive d'origine
/// (chargement/erreur/vide même patron que `join_character_step_screen.dart`).
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

  /// Ouvre la sheet "Choisir un personnage" (tap sur [_CharacterSelectorTile])
  /// — même gabarit de sheet "mode liste" que
  /// `character_class_filter_sheet.dart` (`SheetHeaderBar` + `ListView`
  /// occupant 75 % de la hauteur), réutilisant [_buildCharacterList] et
  /// [_SelectableCharacterRow] tels quels : seul le `onTap` de chaque ligne
  /// diffère, pour refermer la sheet immédiatement après la sélection.
  Future<void> _openCharacterPicker(List<CharacterSummary> characters) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: FractionallySizedBox(
          heightFactor: 0.75,
          child: DecoratedBox(
            decoration: const BoxDecoration(color: AppColors.parchmentBg),
            child: Column(
              children: [
                const SheetHeaderBar(title: 'CHOISIR UN PERSONNAGE'),
                Expanded(
                  child: _buildCharacterList(
                    characters,
                    onCharacterTap: (characterId) {
                      _selectCharacter(characterId);
                      Navigator.of(sheetContext).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
              Expanded(
                child: SingleChildScrollView(
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
                        'Un groupe permet de suivre les PV de ton équipe en '
                        'direct et de gérer un butin commun, indépendamment '
                        'des histoires du MJ.',
                        style: AppTypography.body(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Nom du groupe',
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
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Ton personnage dans ce groupe',
                        style: AppTypography.body(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Ce personnage représentera ta présence dans le '
                        'tableau de bord du groupe.',
                        style: AppTypography.body(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      charactersAsync.when(
                        data: _buildCharacterSection,
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.woodMedium,
                            ),
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
                    ],
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

  /// Contenu affiché sous le champ "Ton personnage dans ce groupe" une fois
  /// `charactersProvider` résolu : état vide inchangé
  /// ([_EmptyState]), sinon la tuile de sélection unique
  /// ([_CharacterSelectorTile]) + la note sur le code d'invitation
  /// ([_InviteCodeNote]).
  Widget _buildCharacterSection(List<CharacterSummary> characters) {
    if (characters.isEmpty) {
      return const _EmptyState();
    }

    CharacterSummary? selectedCharacter;
    for (final character in characters) {
      if (character.id == _selectedCharacterId) {
        selectedCharacter = character;
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CharacterSelectorTile(
          character: selectedCharacter,
          onTap: _isSaving ? null : () => _openCharacterPicker(characters),
        ),
        const SizedBox(height: AppSpacing.sm),
        const _InviteCodeNote(),
      ],
    );
  }

  /// Liste radio à sélection exclusive — inchangée depuis la version
  /// précédente de cet écran, désormais affichée dans la sheet ouverte par
  /// [_openCharacterPicker] plutôt que directement dans le corps de l'écran.
  /// [onCharacterTap] permet à la sheet de refermer immédiatement après
  /// sélection sans dupliquer cette liste.
  Widget _buildCharacterList(
    List<CharacterSummary> characters, {
    required ValueChanged<String> onCharacterTap,
  }) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: characters.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final character = characters[index];
        return _SelectableCharacterRow(
          character: character,
          selected: character.id == _selectedCharacterId,
          onTap: () => onCharacterTap(character.id),
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

/// Tuile de sélection unique remplaçant l'ancienne liste radio directement
/// dans le corps de l'écran (recettage direction-artistique du 13/09/2026) :
/// affiche le personnage actuellement choisi (portrait + nom), ou un
/// placeholder "Choisir un personnage" (le motif pointillé neutre de
/// [PortraitFrame] sans URL sert déjà de visuel de substitution) quand aucun
/// personnage n'est encore sélectionné. Un tap ouvre
/// [_GroupCreateScreenState._openCharacterPicker].
class _CharacterSelectorTile extends StatelessWidget {
  const _CharacterSelectorTile({required this.character, required this.onTap});

  /// `null` tant qu'aucun personnage n'a été choisi.
  final CharacterSummary? character;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final character = this.character;
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
              PortraitFrame(portraitUrl: character?.portraitUrl, size: 44),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  character?.name ?? 'Choisir un personnage',
                  style: AppTypography.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: character != null
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Note affichée sous [_CharacterSelectorTile] — encadré `parchmentCard`/
/// bordure `woodLight`/`radius.sm` du design système, recettage
/// direction-artistique du 13/09/2026.
class _InviteCodeNote extends StatelessWidget {
  const _InviteCodeNote();

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
          const Icon(Icons.autorenew, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              "Un code d'invitation sera généré automatiquement à la "
              'création.',
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
