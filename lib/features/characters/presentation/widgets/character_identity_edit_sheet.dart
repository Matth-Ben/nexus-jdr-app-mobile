import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/alert_banner.dart';
import '../../../../core/widgets/portrait_frame.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../../character_creation/domain/alignment_option.dart';
import '../../../character_creation/presentation/providers/character_creation_providers.dart';
import '../../domain/character_detail.dart';
import '../../domain/character_failure.dart';
import '../../domain/write_outcome.dart';
import '../providers/character_detail_provider.dart';
import '../providers/character_providers.dart';
import 'character_story_edit_sheet.dart';
import 'portrait_upload_sheet.dart';

/// Ouvre la feuille "Modifier le personnage" (entrée "Modifier" du menu ⋮
/// de la fiche). Décision utilisateur du 2026-09-24 : **identité seule** —
/// portrait, nom, alignement, sexe/âge/taille/poids/yeux/peau/cheveux et les
/// 9 textes d'apparence/histoire. Aucune valeur de jeu (race, classe,
/// caractéristiques...) n'est modifiable ici.
///
/// Même gabarit et mêmes garde-fous que `showCharacterStoryEditSheet`
/// (fermeture uniquement par ses boutons, `PopScope` pendant l'écriture).
Future<void> showCharacterIdentityEditSheet(
  BuildContext context, {
  required String characterId,
  required CharacterDetail detail,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: false,
    builder: (sheetContext) => _CharacterIdentityEditSheetContent(
      characterId: characterId,
      detail: detail,
    ),
  );
  if (saved != true || !context.mounted) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('Personnage mis à jour.')));
}

/// Les 7 champs courts d'identité, dans l'ordre de l'étape 8/9 de
/// l'assistant de création.
const List<StoryFieldSpec> _identityFieldSpecs = [
  StoryFieldSpec(label: 'SEXE', hint: 'Ex. femme'),
  StoryFieldSpec(label: 'ÂGE', hint: 'Ex. 27 ans'),
  StoryFieldSpec(label: 'TAILLE', hint: 'Ex. 1,75 m'),
  StoryFieldSpec(label: 'POIDS', hint: 'Ex. 70 kg'),
  StoryFieldSpec(label: 'YEUX', hint: 'Ex. verts'),
  StoryFieldSpec(label: 'PEAU', hint: 'Ex. hâlée'),
  StoryFieldSpec(label: 'CHEVEUX', hint: 'Ex. bruns, courts'),
];

const String _offlineMessage =
    "Hors ligne : cette action n'a pas pu être enregistrée. Réessayez une "
    'fois reconnecté.';

const String _genericErrorMessage =
    "Impossible d'enregistrer les modifications. Réessayez.";

class _CharacterIdentityEditSheetContent extends ConsumerStatefulWidget {
  const _CharacterIdentityEditSheetContent({
    required this.characterId,
    required this.detail,
  });

  final String characterId;
  final CharacterDetail detail;

  @override
  ConsumerState<_CharacterIdentityEditSheetContent> createState() =>
      _CharacterIdentityEditSheetContentState();
}

class _CharacterIdentityEditSheetContentState
    extends ConsumerState<_CharacterIdentityEditSheetContent> {
  late final TextEditingController _nameController;
  late final List<TextEditingController> _identityControllers;
  late final List<TextEditingController> _storyControllers;

  /// Alignement choisi. `null` tant que le catalogue n'a pas permis de
  /// retrouver l'alignement actuel (voir [_resolveInitialAlignment]) ou si
  /// le joueur choisit "Aucun".
  int? _alignmentId;
  bool _alignmentResolved = false;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final detail = widget.detail;
    _nameController = TextEditingController(text: detail.name)
      ..addListener(() => setState(() {}));
    _identityControllers = [
      for (final value in [
        detail.sexe,
        detail.age,
        detail.height,
        detail.weight,
        detail.eyes,
        detail.skin,
        detail.hair,
      ])
        TextEditingController(text: value),
    ];
    _storyControllers = [
      for (final value in [
        detail.appearanceText,
        detail.traitsText,
        detail.idealsText,
        detail.bondsText,
        detail.flawsText,
        detail.backstoryText,
        detail.alliesText,
        detail.featuresText,
        detail.treasureText,
      ])
        TextEditingController(text: value),
    ];
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final controller in [..._identityControllers, ..._storyControllers]) {
      controller.dispose();
    }
    super.dispose();
  }

  /// `CharacterDetail` ne porte que le nom traduit de l'alignement : on
  /// retrouve son identifiant dans le catalogue, une seule fois.
  void _resolveInitialAlignment(List<AlignmentOption> alignments) {
    if (_alignmentResolved) return;
    _alignmentResolved = true;
    final currentName = widget.detail.alignmentName;
    for (final option in alignments) {
      if (option.name == currentName) _alignmentId = option.id;
    }
  }

  static String? _trimmed(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (_isSaving || name.isEmpty) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final identity = [for (final c in _identityControllers) _trimmed(c)];
    final story = [for (final c in _storyControllers) _trimmed(c)];

    try {
      final outcome = await ref
          .read(characterRepositoryProvider)
          .updateIdentity(
            characterId: widget.characterId,
            name: name,
            alignmentId: _alignmentId,
            sexe: identity[0],
            age: identity[1],
            height: identity[2],
            weight: identity[3],
            eyes: identity[4],
            skin: identity[5],
            hair: identity[6],
            appearanceText: story[0],
            traitsText: story[1],
            idealsText: story[2],
            bondsText: story[3],
            flawsText: story[4],
            backstoryText: story[5],
            alliesText: story[6],
            featuresText: story[7],
            treasureText: story[8],
          );

      if (outcome == WriteOutcome.queued) {
        if (!mounted) return;
        setState(() {
          _isSaving = false;
          _errorMessage = _offlineMessage;
        });
        return;
      }

      // `mounted` vérifié AVANT `ref.invalidate` — même rationale que
      // `CharacterStoryEditSheet._submit`.
      if (!mounted) return;
      ref.invalidate(characterDetailProvider(widget.characterId));
      ref.invalidate(charactersProvider);
      Navigator.of(context).pop(true);
    } on CharacterFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = failure.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = _genericErrorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Portrait lu en direct : il est envoyé immédiatement par son propre
    // flux (`showPortraitUploadSheet`), qui rafraîchit la fiche.
    final portraitUrl =
        ref
            .watch(characterDetailProvider(widget.characterId))
            .value
            ?.portraitUrl ??
        widget.detail.portraitUrl;
    final hasName = _nameController.text.trim().isNotEmpty;
    // Enregistrement possible seulement une fois le catalogue d'alignements
    // chargé : sans lui, l'alignement actuel ne peut pas être retrouvé et
    // serait effacé par erreur.
    final canSave = hasName && ref.watch(alignmentCatalogProvider).hasValue;

    return PopScope(
      canPop: !_isSaving,
      child: SafeArea(
        top: false,
        child: FractionallySizedBox(
          heightFactor: 0.92,
          child: Container(
            decoration: const BoxDecoration(color: AppColors.parchmentBg),
            child: Column(
              children: [
                SheetHeaderBar(
                  title: 'MODIFIER LE PERSONNAGE',
                  closeEnabled: !_isSaving,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_errorMessage != null) ...[
                          AlertBanner(message: _errorMessage!),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        _PortraitRow(
                          portraitUrl: portraitUrl,
                          onTap: _isSaving
                              ? null
                              : () => showPortraitUploadSheet(
                                  context,
                                  ref: ref,
                                  characterId: widget.characterId,
                                  portraitUrl: portraitUrl,
                                ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _FieldBlock(
                          label: 'NOM',
                          child: TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              hintText: 'Nom du personnage',
                              errorText: hasName
                                  ? null
                                  : 'Le nom est obligatoire.',
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _FieldBlock(
                          label: 'ALIGNEMENT',
                          child: _buildAlignmentField(),
                        ),
                        for (
                          var i = 0;
                          i < _identityFieldSpecs.length;
                          i += 2
                        ) ...[
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _identityField(i)),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: i + 1 < _identityFieldSpecs.length
                                    ? _identityField(i + 1)
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ],
                        for (var i = 0; i < storyFieldSpecs.length; i++) ...[
                          const SizedBox(height: AppSpacing.md),
                          _FieldBlock(
                            label: storyFieldSpecs[i].label,
                            child: TextFormField(
                              controller: _storyControllers[i],
                              minLines: 1,
                              maxLines: null,
                              decoration: InputDecoration(
                                hintText: storyFieldSpecs[i].hint,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          label: 'Annuler',
                          surface: SecondaryButtonSurface.parchment,
                          onPressed: _isSaving
                              ? null
                              : () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: PrimaryButton(
                          label: 'Enregistrer',
                          isLoading: _isSaving,
                          onPressed: canSave ? _submit : null,
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

  Widget _identityField(int i) {
    return _FieldBlock(
      label: _identityFieldSpecs[i].label,
      child: TextFormField(
        controller: _identityControllers[i],
        maxLines: 1,
        decoration: InputDecoration(hintText: _identityFieldSpecs[i].hint),
      ),
    );
  }

  Widget _buildAlignmentField() {
    final alignmentsAsync = ref.watch(alignmentCatalogProvider);
    return alignmentsAsync.when(
      data: (catalog) {
        _resolveInitialAlignment(catalog.alignments);
        return DropdownButtonFormField<int?>(
          initialValue: _alignmentId,
          isExpanded: true,
          items: [
            const DropdownMenuItem<int?>(child: Text('Aucun')),
            for (final option in catalog.alignments)
              DropdownMenuItem<int?>(
                value: option.id,
                child: Text(option.name),
              ),
          ],
          onChanged: _isSaving
              ? null
              : (value) => setState(() => _alignmentId = value),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => Row(
        children: [
          Expanded(
            child: Text(
              'Impossible de charger les alignements.',
              style: AppTypography.body(
                fontSize: 13,
                color: AppColors.accentBrick,
              ),
            ),
          ),
          TextButton(
            onPressed: () => ref.invalidate(alignmentCatalogProvider),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

class _FieldBlock extends StatelessWidget {
  const _FieldBlock({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.body(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        child,
      ],
    );
  }
}

class _PortraitRow extends StatelessWidget {
  const _PortraitRow({required this.portraitUrl, required this.onTap});

  final String? portraitUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Row(
        children: [
          PortraitFrame(portraitUrl: portraitUrl, size: 64),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Changer le portrait',
              style: AppTypography.body(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
