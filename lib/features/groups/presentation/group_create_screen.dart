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
/// que `edit_display_name_sheet.dart`), puis le choix du rôle du joueur dans
/// ce groupe (`charactersProvider`) — recettage direction-artistique du
/// 13/09/2026 : la sélection se fait via une tuile unique affichant le
/// personnage choisi (voir [_RoleSelectorTile]), qui ouvre au tap une bottom
/// sheet reprenant la liste radio exclusive d'origine (chargement/erreur/vide
/// même patron que `join_character_step_screen.dart`).
///
/// **MJ sans personnage** (décision de Matthias du 12-13/10/2026) : le
/// sélecteur devient tri-état — rien choisi / personnage choisi / MJ choisi
/// ([_joinAsGameMaster]) — voir [_RoleSelectorTile]/[_GmOptionRow]. La ligne
/// MJ de la sheet reste toujours visible/sélectionnable quel que soit l'état
/// de `charactersProvider` (correctif d'un bug trouvé par
/// direction-artistique : la tuile/la sheet et le bouton primaire ne doivent
/// jamais être gatés par le chargement des personnages quand le joueur veut
/// simplement suivre le groupe comme MJ).
class GroupCreateScreen extends ConsumerStatefulWidget {
  const GroupCreateScreen({super.key});

  @override
  ConsumerState<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends ConsumerState<GroupCreateScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedCharacterId;
  bool _joinAsGameMaster = false;
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
    setState(() {
      _selectedCharacterId = characterId;
      _joinAsGameMaster = false;
    });
  }

  /// Sélectionne le rôle "MJ — sans personnage" — mutuellement exclusif avec
  /// [_selectCharacter] (voir la doc de classe).
  void _selectGameMaster() {
    if (_isSaving) return;
    setState(() {
      _joinAsGameMaster = true;
      _selectedCharacterId = null;
    });
  }

  /// Ouvre la sheet "CHOISIR TON RÔLE" (tap sur [_RoleSelectorTile]) — même
  /// gabarit de sheet "mode liste" que `character_class_filter_sheet.dart`
  /// (`SheetHeaderBar` + `ListView` occupant 75 % de la hauteur). La ligne MJ
  /// ([_GmOptionRow]) est toujours en première position, toujours
  /// sélectionnable ; seule la zone SOUS elle reflète l'état de
  /// [charactersAsync] (chargement/erreur/liste/vide) — voir la doc de
  /// classe.
  Future<void> _openRolePicker(
    AsyncValue<List<CharacterSummary>> charactersAsync,
  ) {
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
                const SheetHeaderBar(title: 'CHOISIR TON RÔLE'),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      _GmOptionRow(
                        selected: _joinAsGameMaster,
                        onTap: () {
                          _selectGameMaster();
                          Navigator.of(sheetContext).pop();
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      charactersAsync.when(
                        data: (characters) => characters.isEmpty
                            ? const _NoCharacterNote()
                            : Column(
                                children: [
                                  for (final character in characters) ...[
                                    _SelectableCharacterRow(
                                      character: character,
                                      selected:
                                          !_joinAsGameMaster &&
                                          character.id == _selectedCharacterId,
                                      onTap: () {
                                        _selectCharacter(character.id);
                                        Navigator.of(sheetContext).pop();
                                      },
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                  ],
                                ],
                              ),
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
      (_selectedCharacterId != null || _joinAsGameMaster);

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final characterId = _joinAsGameMaster ? null : _selectedCharacterId;
    if (name.isEmpty ||
        (!_joinAsGameMaster && characterId == null) ||
        _isSaving) {
      return;
    }

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
                        'Qui te représente dans ce groupe ?',
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
                      _buildCharacterSection(charactersAsync),
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

  /// Tuile de sélection ([_RoleSelectorTile]) + note sur le code d'invitation
  /// ([_InviteCodeNote]) — toujours affichées quel que soit l'état de
  /// [charactersAsync] (correctif de bug, voir la doc de classe) : l'état
  /// "aucun personnage" ne remplace plus tout ce bloc (ancien [_EmptyState]
  /// retiré), il n'apparaît désormais que dans la sheet ([_NoCharacterNote]).
  Widget _buildCharacterSection(
    AsyncValue<List<CharacterSummary>> charactersAsync,
  ) {
    CharacterSummary? selectedCharacter;
    if (!_joinAsGameMaster) {
      final characters = charactersAsync.value;
      if (characters != null) {
        for (final character in characters) {
          if (character.id == _selectedCharacterId) {
            selectedCharacter = character;
            break;
          }
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RoleSelectorTile(
          character: selectedCharacter,
          isGameMaster: _joinAsGameMaster,
          onTap: _isSaving ? null : () => _openRolePicker(charactersAsync),
        ),
        const SizedBox(height: AppSpacing.sm),
        const _InviteCodeNote(),
      ],
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

/// Ligne "MJ — sans personnage" de la sheet "CHOISIR TON RÔLE" — toujours en
/// première position, toujours sélectionnable indépendamment de l'état de
/// `charactersProvider` (voir la doc de classe de [GroupCreateScreen]). Même
/// gabarit visuel que [_SelectableCharacterRow] (`parchment.card`/
/// `wood.light` 2px, statique, ne change pas de couleur à la sélection — seul
/// le radio change), même tuile 44×44 que [_RoleSelectorTile]. Pas de
/// sous-titre sur cet écran (voir `group_join_screen.dart::_GmOptionRow` pour
/// la variante avec sous-titre).
class _GmOptionRow extends StatelessWidget {
  const _GmOptionRow({required this.selected, required this.onTap});

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
              const PortraitFrame(
                portraitUrl: null,
                fallbackIcon: Icons.visibility_outlined,
                classThemeColor: AppColors.woodMedium,
                size: 44,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'MJ — sans personnage',
                  style: AppTypography.body(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
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
/// affiche le personnage actuellement choisi (portrait + nom), le rôle "MJ —
/// sans personnage" si [isGameMaster], ou un placeholder "Choisir un
/// personnage ou un rôle" quand rien n'est encore sélectionné. Un tap ouvre
/// [_GroupCreateScreenState._openRolePicker].
class _RoleSelectorTile extends StatelessWidget {
  const _RoleSelectorTile({
    required this.character,
    required this.isGameMaster,
    required this.onTap,
  });

  /// `null` tant qu'aucun personnage n'a été choisi (ou si [isGameMaster]).
  final CharacterSummary? character;
  final bool isGameMaster;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final character = this.character;
    final hasSelection = isGameMaster || character != null;
    final label = isGameMaster
        ? 'MJ — sans personnage'
        : character?.name ?? 'Choisir un personnage ou un rôle';

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
              isGameMaster
                  ? const PortraitFrame(
                      portraitUrl: null,
                      fallbackIcon: Icons.visibility_outlined,
                      classThemeColor: AppColors.woodMedium,
                      size: 44,
                    )
                  : PortraitFrame(
                      portraitUrl: character?.portraitUrl,
                      size: 44,
                    ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: isGameMaster
                      ? AppTypography.body(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        )
                      : AppTypography.body(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: hasSelection
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

/// Note affichée sous [_RoleSelectorTile] — encadré `parchmentCard`/
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

/// Note compacte "aucun personnage" affichée SOUS [_GmOptionRow] dans la
/// sheet "CHOISIR TON RÔLE" — remplace l'ancien `_EmptyState` (grand état
/// centré qui remplaçait tout le bloc de sélection, y compris la tuile) :
/// même gabarit que [_InviteCodeNote] (boîte `parchment.card`/`wood.light`/
/// `radius.sm`, icône + texte sur une ligne), voir la doc de classe de
/// [GroupCreateScreen].
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
              "Tu n'as pas encore de personnage à inscrire dans ce groupe.",
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
