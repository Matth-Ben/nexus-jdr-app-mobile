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
import 'providers/character_creation_draft_provider.dart';

/// Étape 8/9 de l'assistant de création de personnage : apparence, histoire
/// et portrait (`docs/cahier-des-charges/04-fonctionnalites-app-mobile.md`
/// section 3 point 8).
///
/// Contrairement aux étapes précédentes, cet écran ne lit aucune donnée de
/// référence côté serveur : les 9 champs sont du texte libre et le portrait
/// n'est qu'un placeholder non fonctionnel pour cette itération (voir
/// [_PortraitTile]) — construction entièrement synchrone, pas de
/// `FutureProvider`/`.when(data/loading/error)` comme les étapes catalogue,
/// et donc pas d'état de chargement/erreur réseau à prévoir ici.
///
/// Ordre des 9 champs texte : l'ordre canonique du XML aidedd.org / des
/// colonnes `characters.*` (décision du chef de projet), **pas** l'ordre
/// partiel visible sur la maquette d'origine (qui n'en montre que 4 sur 9,
/// coupée avant la fin — extrait tronqué, pas une réduction volontaire du
/// périmètre). Les 6 colonnes structurées `characters.sexe`/`age`/`height`/
/// `weight`/`eyes`/`skin`/`hair` ne sont pas dans le périmètre de cette
/// étape (absentes de la maquette et de l'énoncé fonctionnel).
///
/// "Suivant" est toujours actif dès l'affichage : les 9 champs sont
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

  /// Ordre canonique des 9 champs texte, voir le commentaire de classe
  /// ci-dessus. L'index dans cette liste est aussi l'index utilisé dans
  /// [_controllers]/[_focusNodes] et dans [_submit] pour retrouver la bonne
  /// valeur du brouillon — les deux listes ci-dessous doivent donc toujours
  /// rester alignées avec celle-ci.
  static const List<_TextFieldSpec> _fieldSpecs = [
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
    // Réhydrate les 9 champs depuis le brouillon déjà en mémoire (retour en
    // arrière depuis l'étape 9) — même rationale que les étapes précédentes.
    // `ref.read` (pas `ref.watch`) : cet écran ne doit réagir à aucune
    // modification externe du brouillon pendant qu'il est affiché, seule sa
    // propre saisie locale (via les `TextEditingController`) compte jusqu'à
    // "Suivant".
    final draft = ref.read(characterCreationDraftControllerProvider);
    final draftValues = <String?>[
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
          appearanceText: valueAt(0),
          traitsText: valueAt(1),
          idealsText: valueAt(2),
          bondsText: valueAt(3),
          flawsText: valueAt(4),
          backstoryText: valueAt(5),
          alliesText: valueAt(6),
          featuresText: valueAt(7),
          treasureText: valueAt(8),
        );
    context.push('/characters/new/step-9');
  }

  /// Tap sur la tuile "Portrait" : aucun flux d'upload fonctionnel à cette
  /// itération (décision du chef de projet, voir le commentaire de classe) —
  /// se contente de signaler que la fonctionnalité arrive plus tard, sans
  /// naviguer ni écrire quoi que ce soit.
  void _showPortraitComingSoon() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Bientôt disponible')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _Header(onBack: _goBack, currentStep: 8, totalSteps: _totalSteps),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
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
                _PortraitTile(onTap: _showPortraitComingSoon),
                const SizedBox(height: AppSpacing.md),
                for (var i = 0; i < _fieldSpecs.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.md),
                  _TextFieldBlock(
                    spec: _fieldSpecs[i],
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    textInputAction: i == _fieldSpecs.length - 1
                        ? TextInputAction.done
                        : TextInputAction.next,
                    onFieldSubmitted: (_) {
                      if (i == _fieldSpecs.length - 1) {
                        _focusNodes[i].unfocus();
                      } else {
                        FocusScope.of(context).requestFocus(_focusNodes[i + 1]);
                      }
                    },
                  ),
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
            child: Row(
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
                  child: PrimaryButton(label: 'Suivant', onPressed: _submit),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Libellé + placeholder d'un des 9 champs texte, afin de garder
/// [_AppearanceAndBackstoryStepScreenState._fieldSpecs] lisible comme un
/// tableau de données plutôt que 9 blocs de code dupliqués.
class _TextFieldSpec {
  const _TextFieldSpec({required this.label, required this.hint});

  final String label;
  final String hint;
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
          maxLines: null,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          decoration: InputDecoration(hintText: spec.hint),
        ),
      ],
    );
  }
}

/// Tuile "Portrait" en tête du corps de l'écran : simple placeholder non
/// fonctionnel pour cette itération (décision du chef de projet, voir le
/// commentaire de classe de [AppearanceAndBackstoryStepScreen]) — aucun flux
/// d'upload caméra/galerie/URL/recadrage, le vrai flux sera une tâche
/// séparée future réutilisée aussi par la fiche personnage
/// (`docs/cahier-des-charges/04-fonctionnalites-app-mobile.md` section 5).
///
/// Carré pointillé via [DashedBorderPainter], extrait de
/// `core/widgets/portrait_frame.dart` pour être partagé ici sans dupliquer
/// le peintre (même stroke/dash/gap/couleur que [PortraitFrame]).
class _PortraitTile extends StatelessWidget {
  const _PortraitTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
              child: CustomPaint(
                painter: const DashedBorderPainter(color: AppColors.textMuted),
                child: const Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 28,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
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
                    'Optionnel — ajoutable plus tard',
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
  });

  final VoidCallback onBack;
  final int currentStep;
  final int totalSteps;

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
                    Text(
                      'CRÉATION',
                      style: AppTypography.display(
                        fontSize: 11,
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
