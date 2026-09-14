import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../../core/widgets/portrait_frame.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/sheet_header_bar.dart';
import '../../../core/widgets/wood_back_header.dart';
import '../../characters/domain/character_failure.dart';
import '../../characters/domain/character_summary.dart';
import '../../characters/presentation/providers/character_providers.dart';
import '../domain/group_invite_failure.dart';
import 'providers/group_providers.dart';

/// Longueur brute (sans le tiret de présentation) d'un code d'invitation de
/// groupe — voir `domain/group_invite_code_generator.dart::_length`.
const int _rawCodeLength = 8;

/// Longueur minimale saisie avant d'activer "Rejoindre" — même seuil que
/// l'ancienne étape 1/3 (`group_join_code_step_screen.dart`, retirée par
/// cette tâche), gardé pour ne pas durcir la validation au-delà de ce qui
/// existait déjà.
const int _rawCodeMinLength = 6;

const String _genericJoinErrorMessage =
    'Impossible de rejoindre ce groupe. Réessayez.';

/// Écran unique "REJOINDRE UN GROUPE", route `/groups/join` — recettage
/// direction-artistique du 13/09/2026 (`docs/cahier-des-charges/
/// 09-maquettes-captures.md`, section "Groupe — Rejoindre") : fusionne les 3
/// écrans de l'ancien flux à étapes (`group_join_code_step_screen.dart`
/// "Code", un écran de confirmation intermédiaire "Nom du groupe/nombre de
/// membres", `group_join_character_step_screen.dart` "Choix du personnage",
/// tous les 3 retirés par cette tâche, ainsi que
/// `widgets/group_join_step_header.dart`) en un seul écran scrollable : code
/// d'invitation, personnage représentant, bouton "Rejoindre" unique.
///
/// **Logique métier migrée telle quelle**, jamais réécrite : la validation
/// du code passe toujours par `GroupRepository.previewGroupInvite` (résout
/// le groupe ciblé, lève une [GroupInviteFailure] `invalidCode`/`generic` —
/// jamais `alreadyInGroup` à ce stade, aucun personnage n'est encore choisi
/// par l'edge function `preview-group-invite`, même remarque que l'ancienne
/// étape 2/3), puis le rattachement par `GroupRepository.joinGroup` (peut,
/// lui, lever les 3 natures d'échec). Les deux appels sont maintenant
/// orchestrés l'un après l'autre par [_submit] plutôt que répartis sur 2
/// routes séparées.
///
/// **Affichage des erreurs, 2 canaux distincts** (spec de la tâche) :
/// - code invalide (`GroupInviteFailureKind.invalidCode`, qu'il vienne de
///   l'aperçu ou du rattachement) → texte d'aide discret sous le champ code
///   ([_CodeErrorHint], triangle + texte, jamais encadré) — la maquette
///   n'étiquette ce texte que d'un "Exemple d'erreur : « ... »" à titre
///   d'illustration statique ; ce libellé "Exemple d'erreur" n'a lui-même
///   aucune vocation à apparaître dans l'app, seul le style (icône + texte
///   sans bordure) est repris pour le vrai message dynamique.
/// - tout le reste (`alreadyInGroup`/`generic`, échec réseau) →
///   [AlertBanner] en tête d'écran, même composant que l'ancienne étape 3/3.
class GroupJoinScreen extends ConsumerStatefulWidget {
  const GroupJoinScreen({this.initialCode, super.key});

  /// Pré-remplissage du champ code (ex. arrivée depuis un lien), comportement
  /// hérité de l'ancienne étape 1/3.
  final String? initialCode;

  @override
  ConsumerState<GroupJoinScreen> createState() => _GroupJoinScreenState();
}

class _GroupJoinScreenState extends ConsumerState<GroupJoinScreen> {
  late final TextEditingController _codeController = TextEditingController(
    text: _formatCodeDisplay(_rawCode(widget.initialCode ?? '')),
  );
  String? _selectedCharacterId;
  bool _isJoining = false;
  String? _codeErrorMessage;
  String? _bannerMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (_isJoining) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  String get _rawCurrentCode => _rawCode(_codeController.text);

  CharacterSummary? _selectedCharacter(List<CharacterSummary> characters) {
    for (final character in characters) {
      if (character.id == _selectedCharacterId) return character;
    }
    return characters.isEmpty ? null : characters.first;
  }

  void _selectCharacter(String characterId) {
    if (_isJoining) return;
    setState(() => _selectedCharacterId = characterId);
  }

  /// Ouvre "CHOISIR UN PERSONNAGE" (tap sur la tuile de personnage) — même
  /// gabarit de sheet "mode liste" que
  /// `group_create_screen.dart::_openCharacterPicker` (liste radio exclusive,
  /// `SheetHeaderBar` + 75 % de la hauteur), dupliqué ici : classes privées à
  /// leur fichier, même rationale de duplication que le reste de ce dépôt
  /// (voir `GroupMemberRowMapper`).
  Future<void> _openCharacterPicker(List<CharacterSummary> characters) {
    final selected = _selectedCharacter(characters);
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
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: characters.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final character = characters[index];
                      return _SelectableCharacterRow(
                        character: character,
                        selected: character.id == selected?.id,
                        onTap: () {
                          _selectCharacter(character.id);
                          Navigator.of(sheetContext).pop();
                        },
                      );
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

  /// Enchaîne `previewGroupInvite` (validation/résolution du code) puis
  /// `joinGroup` (rattachement) — voir la documentation de classe pour le
  /// détail de la migration et le routage des 2 canaux d'erreur.
  Future<void> _submit(List<CharacterSummary> characters) async {
    final code = _rawCurrentCode;
    final character = _selectedCharacter(characters);
    if (code.length < _rawCodeMinLength || character == null || _isJoining) {
      return;
    }

    setState(() {
      _isJoining = true;
      _codeErrorMessage = null;
      _bannerMessage = null;
    });

    try {
      await ref.read(groupRepositoryProvider).previewGroupInvite(code);
    } on GroupInviteFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _isJoining = false;
        if (failure.kind == GroupInviteFailureKind.invalidCode) {
          _codeErrorMessage = "Ce code d'invitation n'est pas valide.";
        } else {
          _bannerMessage = _genericJoinErrorMessage;
        }
      });
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isJoining = false;
        _bannerMessage = _genericJoinErrorMessage;
      });
      return;
    }

    try {
      final result = await ref
          .read(groupRepositoryProvider)
          .joinGroup(code: code, characterId: character.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Groupe rejoint !')));
      context.go('/groups/${result.groupId}');
    } on GroupInviteFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _isJoining = false;
        switch (failure.kind) {
          case GroupInviteFailureKind.invalidCode:
            _codeErrorMessage = "Ce code d'invitation n'est pas valide.";
          case GroupInviteFailureKind.alreadyInGroup:
            _bannerMessage = 'Ce personnage est déjà membre de ce groupe.';
          case GroupInviteFailureKind.generic:
            _bannerMessage = _genericJoinErrorMessage;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isJoining = false;
        _bannerMessage = _genericJoinErrorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final charactersAsync = ref.watch(charactersProvider);

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              WoodBackHeader(title: 'REJOINDRE UN GROUPE', onBack: _goBack),
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
                          'Demande le code d\'invitation à un membre du '
                          'groupe, puis choisis le personnage qui vous '
                          'rejoindra.',
                          style: AppTypography.body(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const _SectionLabel('Code d\'invitation'),
                        const SizedBox(height: AppSpacing.xs),
                        _CodeField(
                          controller: _codeController,
                          enabled: !_isJoining,
                          onChanged: (_) => setState(() {}),
                        ),
                        if (_codeErrorMessage != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          _CodeErrorHint(message: _codeErrorMessage!),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        const _SectionLabel('Ton personnage dans ce groupe'),
                        const SizedBox(height: AppSpacing.xs),
                        charactersAsync.when(
                          data: (characters) => _CharacterSelectorTile(
                            character: _selectedCharacter(characters),
                            enabled: !_isJoining && characters.isNotEmpty,
                            onTap: () => _openCharacterPicker(characters),
                          ),
                          loading: () => const _CharacterTileLoading(),
                          error: (error, stackTrace) => _CharacterTileError(
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
                  child: charactersAsync.maybeWhen(
                    data: (characters) => PrimaryButton(
                      label: 'Rejoindre',
                      isLoading: _isJoining,
                      onPressed:
                          _rawCurrentCode.length >= _rawCodeMinLength &&
                              _selectedCharacter(characters) != null &&
                              !_isJoining
                          ? () => _submit(characters)
                          : null,
                    ),
                    orElse: () => const PrimaryButton(
                      label: 'Rejoindre',
                      onPressed: null,
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
}

/// Libellé de section normal case/gras — distinct de la convention
/// "MAJUSCULES + `textSecondary`" utilisée ailleurs dans ce module
/// (`NOM DU GROUPE`, `MES DONNÉES`...) : la maquette "Groupe — Rejoindre"
/// (`docs/cahier-des-charges/09-maquettes-captures.md`) montre explicitement
/// "Code d'invitation"/"Ton personnage dans ce groupe" en casse normale, plus
/// grand et plus sombre — recettage direction-artistique du 13/09/2026, écart
/// assumé par rapport à la convention majuscule des autres écrans du module.
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

/// Champ code — encadré `parchmentCard`/bordure `goldEnd`, texte centré large
/// avec un tiret de présentation ("AB3F - 7K2M"), inspiré du style visuel de
/// `_InviteCodeChip` (`group_screen.dart`) mais éditable (`TextField`) — voir
/// [_GroupCodeInputFormatter] pour la logique de formatage/validation.
class _CodeField extends StatelessWidget {
  const _CodeField({
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.goldEnd, width: AppBorders.card),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        autofocus: controller.text.isEmpty,
        textAlign: TextAlign.center,
        textCapitalization: TextCapitalization.characters,
        inputFormatters: [_GroupCodeInputFormatter()],
        onChanged: onChanged,
        style: AppTypography.body(
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ).copyWith(letterSpacing: 4),
        decoration: const InputDecoration(
          hintText: 'AB3F - 7K2M',
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
        ),
      ),
    );
  }
}

/// Texte d'aide discret sous le champ code (triangle + texte, jamais encadré)
/// — voir la documentation de classe de [GroupJoinScreen] pour le rationale
/// de ce choix face à [AlertBanner].
class _CodeErrorHint extends StatelessWidget {
  const _CodeErrorHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.warning_amber_rounded,
          size: 16,
          color: AppColors.accentBrick,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            message,
            style: AppTypography.body(
              fontSize: 12,
              color: AppColors.accentBrick,
            ),
          ),
        ),
      ],
    );
  }
}

/// Tuile affichant le personnage actuellement sélectionné (portrait, nom,
/// "Race · Classe · Niv. X", chevron) — tap ouvre "CHOISIR UN PERSONNAGE"
/// (voir `GroupJoinScreen._openCharacterPicker`). `character` `null` (liste
/// vide) affiche un état neutre non interactif plutôt qu'un chevron trompeur.
class _CharacterSelectorTile extends StatelessWidget {
  const _CharacterSelectorTile({
    required this.character,
    required this.enabled,
    required this.onTap,
  });

  final CharacterSummary? character;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final summary = character;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
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
              PortraitFrame(
                portraitUrl: summary?.portraitUrl,
                size: 44,
                classThemeColor: _classThemeColor(summary?.className),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: summary == null
                    ? Text(
                        "Tu n'as pas encore de personnage à rattacher.",
                        style: AppTypography.body(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            summary.name,
                            style: AppTypography.body(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            _summaryLine(summary),
                            style: AppTypography.body(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
              ),
              if (enabled)
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

  /// "Race · Classe · Niv. X" — même omission des segments non résolus que
  /// `CharacterCard._summaryLine`, dupliqué ici (classe privée à son
  /// fichier).
  String _summaryLine(CharacterSummary character) {
    final segments = [
      if (character.raceName != null) character.raceName!,
      if (character.className != null) character.className!,
      'Niv. ${character.level}',
    ];
    return segments.join(' · ');
  }

  /// Même mapping que `CharacterCard._classThemeColor` (dupliqué ici, classe
  /// privée à son fichier).
  Color? _classThemeColor(String? className) {
    return switch (className) {
      'Magicien' => AppColors.accentTeal,
      'Guerrier' => AppColors.accentBrick,
      'Clerc' => AppColors.accentBlue,
      _ => null,
    };
  }
}

class _CharacterTileLoading extends StatelessWidget {
  const _CharacterTileLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.woodLight, width: AppBorders.card),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.woodMedium,
          ),
        ),
      ),
    );
  }
}

class _CharacterTileError extends StatelessWidget {
  const _CharacterTileError({required this.message, required this.onRetry});

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

/// Ligne sélectionnable de la sheet "CHOISIR UN PERSONNAGE" — même patron que
/// `group_create_screen.dart::_SelectableCharacterRow` (`CharacterCard` +
/// bouton radio 20×20), dupliqué ici (classe privée à son fichier).
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      character.name,
                      style: AppTypography.body(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
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
/// `group_create_screen.dart::_RadioIndicator` (classe privée à son fichier).
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

/// Overlay de rattachement en cours — calque exact de l'ancien
/// `_JoinSavingOverlay` (`group_join_character_step_screen.dart`, retiré par
/// cette tâche), affiché pendant `previewGroupInvite` ET `joinGroup` (les 2
/// appels de [_GroupJoinScreenState._submit]) : le joueur n'a pas besoin de
/// distinguer les 2 phases, le libellé reste générique.
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

/// Ne garde que les caractères alphanumériques de [text], en majuscules — le
/// code réellement transmis à `previewGroupInvite`/`joinGroup` ne doit jamais
/// porter le tiret de présentation ajouté par [_GroupCodeInputFormatter].
String _rawCode(String text) =>
    text.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');

/// "AB3F - 7K2M" : insère un tiret de présentation après la moitié de
/// [_rawCodeLength] caractères, une fois [raw] assez long — voir la maquette
/// "Groupe — Rejoindre" (`docs/cahier-des-charges/09-maquettes-captures.md`),
/// qui illustre ce même séparateur sur un exemple de code plus court. Rendu
/// inchangé tant que [raw] ne dépasse pas la moitié de [_rawCodeLength].
String _formatCodeDisplay(String raw) {
  const splitAt = _rawCodeLength ~/ 2;
  if (raw.length <= splitAt) return raw;
  return '${raw.substring(0, splitAt)} - ${raw.substring(splitAt)}';
}

/// Met en majuscules, ne garde que les caractères alphanumériques, limite à
/// [_rawCodeLength] caractères bruts et insère le tiret de présentation
/// ([_formatCodeDisplay]) à chaque frappe — le curseur est systématiquement
/// replacé en fin de champ (simplification assumée, même principe que
/// `_UpperCaseTextFormatter` des flux "Rejoindre" existants : un code court
/// ne justifie pas de préserver une position de curseur au milieu du texte).
class _GroupCodeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = _rawCode(newValue.text);
    final truncated = raw.length > _rawCodeLength
        ? raw.substring(0, _rawCodeLength)
        : raw;
    final formatted = _formatCodeDisplay(truncated);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
