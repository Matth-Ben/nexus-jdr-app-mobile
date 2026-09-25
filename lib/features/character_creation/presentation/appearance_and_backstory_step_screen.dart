import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/dashed_border_painter.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/step_progress_bar.dart';
import '../../characters/presentation/widgets/portrait_upload_sheet.dart';
import '../domain/creation_step_help.dart';
import '../../characters/presentation/providers/character_detail_provider.dart';
import 'providers/character_creation_draft_provider.dart';
import 'providers/character_creation_providers.dart';
import 'providers/character_edit_session_provider.dart';
import 'widgets/abandon_creation_flow.dart';
import 'widgets/creation_mode_title.dart';
import 'widgets/draft_autosave_footer.dart';
import 'widgets/step_help_sheet.dart';

/// Étape 8/9 de l'assistant de création de personnage : apparence, histoire
/// et portrait (`docs/cahier-des-charges/04-fonctionnalites-app-mobile.md`
/// section 3 point 8).
///
/// Contrairement aux étapes précédentes, cet écran ne lit aucune donnée de
/// référence côté serveur : les 9 champs sont du texte libre et le portrait
/// est choisi localement (voir [_PortraitTile]), envoyé seulement à l'étape
/// 9 — construction entièrement synchrone, pas de
/// `FutureProvider`/`.when(data/loading/error)` comme les étapes catalogue,
/// et donc pas d'état de chargement/erreur réseau à prévoir ici.
///
/// Ordre des 9 champs texte : l'ordre canonique du XML aidedd.org / des
/// colonnes `characters.*` (décision du chef de projet), **pas** l'ordre
/// partiel visible sur la maquette d'origine (qui n'en montre que 4 sur 9,
/// coupée avant la fin — extrait tronqué, pas une réduction volontaire du
/// périmètre). Ils sont précédés des 7 champs courts d'identité
/// (`characters.sexe`/`age`/`height`/`weight`/`eyes`/`skin`/`hair`, ajoutés
/// à la demande de l'utilisateur le 2026-09-24), affichés deux par ligne.
///
/// "Suivant" est toujours actif dès l'affichage : les 16 champs sont
/// optionnels, aucune validation ni quota à cette étape.
///
/// En-tête bois plein portant le titre d'étape et la barre de progression
/// (`_Header` ci-dessous), copié depuis `equipment_step_screen.dart` (étape
/// 7/9) — comme sur cette étape et l'étape 6/9, le bois s'étend jusque sous
/// `StepProgressBar` (maquette réelle `etape8_histoire_mockup.png`, revue
/// direction artistique), contrairement à `background_step_screen.dart`
/// (étape 3/9) qui pose ces deux éléments sur le fond parchemin — écart déjà
/// identifié sur cet écran-là mais laissé hors périmètre ici (déjà mergé, à
/// traiter séparément). Pas de `_MinimalHeader` séparé pour un état
/// chargement/erreur ici : cet écran n'en a aucun (voir plus haut), `_Header`
/// est donc affiché tel quel en permanence.
class AppearanceAndBackstoryStepScreen extends ConsumerStatefulWidget {
  const AppearanceAndBackstoryStepScreen({super.key});

  @override
  ConsumerState<AppearanceAndBackstoryStepScreen> createState() =>
      _AppearanceAndBackstoryStepScreenState();
}

class _AppearanceAndBackstoryStepScreenState
    extends ConsumerState<AppearanceAndBackstoryStepScreen> {
  static const int _totalSteps = 9;

  /// Les 7 champs courts d'identité puis les 9 champs texte dans l'ordre
  /// canonique, voir le commentaire de classe ci-dessus. L'index dans cette liste est aussi l'index utilisé dans
  /// [_controllers]/[_focusNodes] et dans [_submit] pour retrouver la bonne
  /// valeur du brouillon — les deux listes ci-dessous doivent donc toujours
  /// rester alignées avec celle-ci.
  static const List<_TextFieldSpec> _fieldSpecs = [
    _TextFieldSpec(label: 'SEXE', hint: 'Ex. femme', isShort: true),
    _TextFieldSpec(label: 'ÂGE', hint: 'Ex. 27 ans', isShort: true),
    _TextFieldSpec(label: 'TAILLE', hint: 'Ex. 1,75 m', isShort: true),
    _TextFieldSpec(label: 'POIDS', hint: 'Ex. 70 kg', isShort: true),
    _TextFieldSpec(label: 'YEUX', hint: 'Ex. verts', isShort: true),
    _TextFieldSpec(label: 'PEAU', hint: 'Ex. hâlée', isShort: true),
    _TextFieldSpec(label: 'CHEVEUX', hint: 'Ex. bruns, courts', isShort: true),
    _TextFieldSpec(
      label: 'APPARENCE PHYSIQUE',
      hint: "Décris l'apparence physique de ton personnage…",
    ),
    _TextFieldSpec(
      label: 'TRAITS DE PERSONNALITÉ',
      hint: 'Décris les traits de personnalité de ton personnage…',
    ),
    _TextFieldSpec(
      label: 'IDÉAUX',
      hint: 'Quels idéaux guident ton personnage ?',
    ),
    _TextFieldSpec(
      label: 'LIENS',
      hint: "Quels liens unissent ton personnage à d'autres ?",
    ),
    _TextFieldSpec(
      label: 'DÉFAUTS',
      hint: 'Quels défauts ou faiblesses a ton personnage ?',
    ),
    _TextFieldSpec(
      label: 'HISTOIRE PERSONNELLE',
      hint: "Raconte l'histoire personnelle de ton personnage…",
    ),
    _TextFieldSpec(
      label: 'ALLIÉS',
      hint: 'Quels alliés ou organisations soutiennent ton personnage ?',
    ),
    _TextFieldSpec(
      label: 'PARTICULARITÉS',
      hint: 'Décris les particularités de ton personnage…',
    ),
    _TextFieldSpec(
      label: 'TRÉSOR',
      hint: 'Quels trésors ou objets précieux possède ton personnage ?',
    ),
  ];

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    // Réhydrate les 16 champs depuis le brouillon déjà en mémoire (retour en
    // arrière depuis l'étape 9) — même rationale que les étapes précédentes.
    // `ref.read` (pas `ref.watch`) : cet écran ne doit réagir à aucune
    // modification externe du brouillon pendant qu'il est affiché, seule sa
    // propre saisie locale (via les `TextEditingController`) compte jusqu'à
    // "Suivant".
    final draft = ref.read(characterCreationDraftControllerProvider);
    final draftValues = <String?>[
      draft.sexe,
      draft.age,
      draft.height,
      draft.weight,
      draft.eyes,
      draft.skin,
      draft.hair,
      draft.appearanceText,
      draft.traitsText,
      draft.idealsText,
      draft.bondsText,
      draft.flawsText,
      draft.backstoryText,
      draft.alliesText,
      draft.featuresText,
      draft.treasureText,
    ];
    _controllers = [
      for (final value in draftValues) TextEditingController(text: value ?? ''),
    ];
    _focusNodes = [for (final _ in _fieldSpecs) FocusNode()];
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  /// Toujours poussée depuis `/characters/new/step-7` (étape 7 "Équipement
  /// de départ") via `context.push` : `pop()` suffit, même rationale que les
  /// étapes précédentes.
  void _goBack() => context.pop();

  /// Met à jour le brouillon en mémoire et passe à l'étape suivante — aucun
  /// appel réseau ici, même rationale que les étapes précédentes. Un champ
  /// vidé (texte blanc après `trim`) redevient `null` dans le brouillon
  /// plutôt qu'une chaîne vide, pour rester cohérent avec l'état initial
  /// "jamais renseigné" (voir `domain/character_creation_draft.dart`).
  void _submit() {
    String? valueAt(int index) {
      final text = _controllers[index].text.trim();
      return text.isEmpty ? null : text;
    }

    ref
        .read(characterCreationDraftControllerProvider.notifier)
        .setAppearanceAndBackstory(
          sexe: valueAt(0),
          age: valueAt(1),
          height: valueAt(2),
          weight: valueAt(3),
          eyes: valueAt(4),
          skin: valueAt(5),
          hair: valueAt(6),
          appearanceText: valueAt(7),
          traitsText: valueAt(8),
          idealsText: valueAt(9),
          bondsText: valueAt(10),
          flawsText: valueAt(11),
          backstoryText: valueAt(12),
          alliesText: valueAt(13),
          featuresText: valueAt(14),
          treasureText: valueAt(15),
        );
    context.push('/characters/new/step-9');
  }

  /// Tap sur la tuile "Portrait" : même choix de source et même recadrage
  /// que la fiche personnage (`pickLocalPortrait`), mais le PNG recadré est
  /// seulement gardé dans le brouillon — envoyé dans Storage à l'étape 9,
  /// une fois le personnage créé.
  Future<void> _pickPortrait() async {
    // Mode modification : le personnage existe déjà, le portrait est donc
    // envoyé/retiré tout de suite par le flux habituel de la fiche.
    final session = ref.read(characterEditSessionControllerProvider);
    if (session != null) {
      await showPortraitUploadSheet(
        context,
        ref: ref,
        characterId: session.characterId,
        portraitUrl: _currentPortraitUrl(session, listen: false),
      );
      return;
    }
    final draftController = ref.read(
      characterCreationDraftControllerProvider.notifier,
    );
    final result = await pickLocalPortrait(
      context,
      hasPortrait:
          ref.read(characterCreationDraftControllerProvider).portraitBytes !=
          null,
    );
    if (result == null || !mounted) return;
    draftController.setPortraitBytes(result.bytes);
  }

  /// Portrait actuel du personnage modifié (rafraîchi après un envoi).
  String? _currentPortraitUrl(
    CharacterEditSession session, {
    bool listen = true,
  }) =>
      (listen
              ? ref.watch(characterDetailProvider(session.characterId))
              : ref.read(characterDetailProvider(session.characterId)))
          .value
          ?.portraitUrl ??
      session.snapshot.portraitUrl;

  /// Nombre de champs courts d'identité en tête de [_fieldSpecs].
  static final int _shortFieldCount = _fieldSpecs
      .where((spec) => spec.isShort)
      .length;

  Widget _fieldBlock(int i) {
    final isLast = i == _fieldSpecs.length - 1;
    return _TextFieldBlock(
      spec: _fieldSpecs[i],
      controller: _controllers[i],
      focusNode: _focusNodes[i],
      textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: (_) {
        if (isLast) {
          _focusNodes[i].unfocus();
        } else {
          FocusScope.of(context).requestFocus(_focusNodes[i + 1]);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _Header(
            onBack: _goBack,
            currentStep: 8,
            totalSteps: _totalSteps,
            onHelp: () => showStepHelpSheet(
              context,
              CreationStepHelp.appearanceAndBackstory,
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final editSession = ref.watch(characterEditSessionControllerProvider);
    return SafeArea(
      top: false,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              children: [
                _PortraitTile(
                  portraitBytes: ref.watch(
                    characterCreationDraftControllerProvider.select(
                      (draft) => draft.portraitBytes,
                    ),
                  ),
                  portraitUrl: editSession == null
                      ? null
                      : _currentPortraitUrl(editSession),
                  onTap: _pickPortrait,
                ),
                const SizedBox(height: AppSpacing.md),
                const _AlignmentField(),
                const SizedBox(height: AppSpacing.md),
                // Champs courts d'identité, deux par ligne.
                for (var i = 0; i < _shortFieldCount; i += 2) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _fieldBlock(i)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: i + 1 < _shortFieldCount
                            ? _fieldBlock(i + 1)
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
                for (var i = _shortFieldCount; i < _fieldSpecs.length; i++) ...[
                  const SizedBox(height: AppSpacing.md),
                  _fieldBlock(i),
                ],
                // Marge basse supplémentaire pour que le 9e champ ("Trésor")
                // ne reste jamais masqué par le clavier une fois focus —
                // le scroll-to-focus natif de Flutter fait le reste (voir
                // commentaire de classe : `resizeToAvoidBottomInset` reste au
                // comportement par défaut, pas de `SingleChildScrollView`
                // custom ici).
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: 'Retour',
                        surface: SecondaryButtonSurface.parchment,
                        onPressed: _goBack,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Suivant',
                        onPressed: _submit,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                DraftAutosaveFooter(
                  onAbandon: () => abandonCharacterCreation(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Libellé + placeholder d'un des 16 champs texte, afin de garder
/// [_AppearanceAndBackstoryStepScreenState._fieldSpecs] lisible comme un
/// tableau de données plutôt que 9 blocs de code dupliqués.
class _TextFieldSpec {
  const _TextFieldSpec({
    required this.label,
    required this.hint,
    this.isShort = false,
  });

  final String label;
  final String hint;

  /// Champ court d'identité (une seule ligne, affiché deux par ligne).
  final bool isShort;
}

/// Titre + `TextFormField` d'un champ texte de l'étape (maquette, spec
/// direction artistique) : titre en majuscules au-dessus, champ à croissance
/// libre en dessous (`minLines: 1, maxLines: null`), réutilisant tel quel
/// `AppTheme.light.inputDecorationTheme` (pas de surcharge locale).
class _TextFieldBlock extends StatelessWidget {
  const _TextFieldBlock({
    required this.spec,
    required this.controller,
    required this.focusNode,
    required this.textInputAction,
    required this.onFieldSubmitted,
  });

  final _TextFieldSpec spec;
  final TextEditingController controller;
  final FocusNode focusNode;
  final TextInputAction textInputAction;
  final ValueChanged<String> onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          spec.label,
          style: AppTypography.body(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          minLines: 1,
          maxLines: spec.isShort ? 1 : null,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          decoration: InputDecoration(hintText: spec.hint),
        ),
      ],
    );
  }
}

/// Tuile "Portrait" en tête du corps de l'écran : ouvre le flux de choix +
/// recadrage (`pickLocalPortrait`, partagé avec la fiche personnage) ;
/// affiche la miniature une fois un portrait choisi.
///
/// Carré pointillé via [DashedBorderPainter], extrait de
/// `core/widgets/portrait_frame.dart` pour être partagé ici sans dupliquer
/// le peintre (même stroke/dash/gap/couleur que [PortraitFrame]).
class _PortraitTile extends StatelessWidget {
  const _PortraitTile({
    required this.portraitBytes,
    required this.onTap,
    this.portraitUrl,
  });

  final Uint8List? portraitBytes;

  /// Portrait déjà enregistré (mode modification uniquement).
  final String? portraitUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final placeholder = CustomPaint(
      painter: const DashedBorderPainter(color: AppColors.textMuted),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 28, color: AppColors.textMuted),
      ),
    );
    final hasPortrait = portraitBytes != null || portraitUrl != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: SizedBox(
        height: 72,
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              clipBehavior: Clip.antiAlias,
              child: portraitBytes != null
                  ? Image.memory(portraitBytes!, fit: BoxFit.cover)
                  : portraitUrl != null
                  ? Image.network(
                      portraitUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => placeholder,
                    )
                  : placeholder,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Portrait',
                    style: AppTypography.body(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    hasPortrait
                        ? 'Touchez pour changer ou retirer'
                        : 'Optionnel — touchez pour en ajouter un',
                    style: AppTypography.body(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Choix de l'alignement (`characters.alignment_id`), écrit tout de suite
/// dans le brouillon. Facultatif : "Aucun" par défaut.
class _AlignmentField extends ConsumerWidget {
  const _AlignmentField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alignmentId = ref.watch(
      characterCreationDraftControllerProvider.select(
        (draft) => draft.alignmentId,
      ),
    );
    final catalogAsync = ref.watch(alignmentCatalogProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ALIGNEMENT',
          style: AppTypography.body(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        catalogAsync.when(
          data: (catalog) => DropdownButtonFormField<int?>(
            initialValue:
                catalog.alignments.any((option) => option.id == alignmentId)
                ? alignmentId
                : null,
            isExpanded: true,
            items: [
              const DropdownMenuItem<int?>(child: Text('Aucun')),
              for (final option in catalog.alignments)
                DropdownMenuItem<int?>(
                  value: option.id,
                  child: Text(option.name),
                ),
            ],
            onChanged: (value) => ref
                .read(characterCreationDraftControllerProvider.notifier)
                .setAlignment(value),
          ),
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => Row(
            children: [
              Expanded(
                child: Text(
                  'Impossible de charger les alignements.',
                  style: AppTypography.body(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => ref.invalidate(alignmentCatalogProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bandeau bois plein en tête d'écran : retour + "CRÉATION" + titre d'étape
/// + barre de progression, copié depuis `equipment_step_screen.dart`
/// (`_Header`, étape 7/9) — voir le commentaire de classe de
/// [AppearanceAndBackstoryStepScreen] pour le rationale (le bois s'étend
/// jusque sous [StepProgressBar] sur la maquette réelle de cette étape).
class _Header extends StatelessWidget {
  const _Header({
    required this.onBack,
    required this.currentStep,
    required this.totalSteps,
    required this.onHelp,
  });

  final VoidCallback onBack;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.woodMedium,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.textOnWood,
                      ),
                    ),
                    CreationModeTitle(
                      style: AppTypography.display(
                        fontSize: 11,
                        color: AppColors.textOnWood,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: onHelp,
                      tooltip: 'Aide',
                      icon: const Icon(
                        Icons.help_outline,
                        color: AppColors.textOnWood,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '8. Histoire',
                          style: AppTypography.body(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textOnWood,
                          ),
                        ),
                        Text(
                          'Étape $currentStep / $totalSteps',
                          style: AppTypography.body(
                            fontSize: 13,
                            color: AppColors.textOnWoodMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    StepProgressBar(
                      totalSteps: totalSteps,
                      currentStep: currentStep,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
