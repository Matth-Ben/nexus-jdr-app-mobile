import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/step_progress_bar.dart';
import '../domain/character_creation_failure.dart';
import '../domain/class_catalog.dart';
import '../domain/class_option.dart';
import '../domain/creation_step_help.dart';
import '../domain/subclass_step_selection.dart';
import 'providers/character_creation_draft_provider.dart';
import 'providers/character_creation_providers.dart';
import 'providers/subclass_choice_providers.dart';
import 'widgets/abandon_creation_flow.dart';
import 'widgets/draft_autosave_footer.dart';
import 'widgets/step_help_sheet.dart';
import 'widgets/subclass_choice_block.dart';

/// Étape 2/9 "Sous-classe" de l'assistant de création de personnage, second
/// écran de l'étape "Classe" — atteinte uniquement depuis `ClassStepScreen`
/// (`_submit`) quand la classe choisie choisit sa sous-classe dès le
/// niveau 1 (`SubclassChoiceCatalog.isConcerned`).
///
/// Ne fait PAS avancer le compteur d'étape (`currentStep: 2`, comme
/// `ClassStepScreen`) : c'est un second écran de la même étape logique, pas
/// une étape à part entière du parcours en 9 étapes — même principe que
/// `SubraceStepScreen` (étape 1 "Race").
///
/// Réutilise `SubclassChoiceBlock` (`widgets/subclass_choice_block.dart`)
/// tel quel comme corps principal : ce widget est déjà autonome (chargement/
/// erreur/retry/liste, voir sa doc de classe "sans carte englobante"),
/// auparavant inséré sous la tuile de classe de `ClassStepScreen`.
///
/// `_Header`/`_MinimalHeader` dupliqués localement plutôt que factorisés
/// avec `ClassStepScreen` : voir la doc de classe de
/// `RaceStepScreen`/`SubraceStepScreen` pour le rationale de cette
/// duplication assumée dans tout ce module.
class SubclassStepScreen extends ConsumerStatefulWidget {
  const SubclassStepScreen({super.key});

  @override
  ConsumerState<SubclassStepScreen> createState() => _SubclassStepScreenState();
}

class _SubclassStepScreenState extends ConsumerState<SubclassStepScreen> {
  static const int _totalSteps = 9;

  int? _classId;
  int? _selectedSubclassId;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(characterCreationDraftControllerProvider);
    _classId = draft.classId;
    // Réhydrate le choix déjà fait (retour en arrière depuis une étape
    // suivante) — même rationale que `ClassStepScreen.initState`.
    _selectedSubclassId = draft.subclassId;

    if (_classId == null) {
      // Cas défensif (ex. deep-link direct sur cette route) : cet écran
      // n'est censé être atteint que depuis `ClassStepScreen`, qui a déjà
      // écrit `classId` dans le brouillon avant de pousser cette route.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go('/characters/new/step-2');
      });
    }
  }

  void _goBack() => context.pop();

  /// Met à jour le brouillon en mémoire et passe à l'étape suivante — aucun
  /// appel réseau ici, même rationale que `ClassStepScreen._submit`.
  void _submit() {
    ref
        .read(characterCreationDraftControllerProvider.notifier)
        .setClass(classId: _classId!, subclassId: _selectedSubclassId);
    context.push('/characters/new/step-3');
  }

  @override
  Widget build(BuildContext context) {
    final classId = _classId;
    if (classId == null) {
      // Redirection défensive déjà programmée dans `initState` : rien à
      // afficher le temps qu'elle se déclenche.
      return const Scaffold(body: SizedBox.shrink());
    }

    final classCatalogAsync = ref.watch(classCatalogProvider);

    return Scaffold(
      body: classCatalogAsync.when(
        data: (catalog) => _buildContent(catalog, classId),
        loading: () => Column(
          children: [
            _MinimalHeader(
              onBack: _goBack,
              onHelp: () =>
                  showStepHelpSheet(context, CreationStepHelp.classStep),
            ),
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.woodMedium),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: DraftAutosaveFooter(
                onAbandon: () => abandonCharacterCreation(context, ref),
              ),
            ),
          ],
        ),
        error: (error, stackTrace) => Column(
          children: [
            _MinimalHeader(
              onBack: _goBack,
              onHelp: () =>
                  showStepHelpSheet(context, CreationStepHelp.classStep),
            ),
            Expanded(
              child: _ErrorState(
                message: error is CharacterCreationFailure
                    ? error.message
                    : 'Impossible de charger les classes disponibles. '
                          'Réessayez.',
                onRetry: () => ref.invalidate(classCatalogProvider),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: DraftAutosaveFooter(
                onAbandon: () => abandonCharacterCreation(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ClassCatalog classCatalog, int classId) {
    final className = classCatalog.classes
        .firstWhere(
          (classOption) => classOption.id == classId,
          orElse: () => ClassOption(
            id: classId,
            name: 'cette classe',
            description: '',
            hitDie: 6,
          ),
        )
        .name;
    final subclassAsync = ref.watch(subclassChoiceCatalogProvider);
    final canProceed = SubclassStepSelection.canProceed(
      catalogAsync: subclassAsync,
      classId: classId,
      selectedSubclassId: _selectedSubclassId,
    );

    return Column(
      children: [
        _Header(
          onBack: _goBack,
          currentStep: 2,
          totalSteps: _totalSteps,
          onHelp: () => showStepHelpSheet(context, CreationStepHelp.classStep),
        ),
        Expanded(
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Ce choix se fait dès le niveau 1 pour $className.',
                      style: AppTypography.body(fontSize: 14),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    children: [
                      SubclassChoiceBlock(
                        classId: classId,
                        className: className,
                        catalogAsync: subclassAsync,
                        selectedSubclassId: _selectedSubclassId,
                        onSelect: (id) =>
                            setState(() => _selectedSubclassId = id),
                        onRetry: () =>
                            ref.invalidate(subclassChoiceCatalogProvider),
                      ),
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
                              onPressed: canProceed ? _submit : null,
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
          ),
        ),
      ],
    );
  }
}

/// Bandeau bois plein en tête d'écran, avec le titre d'étape et la barre de
/// progression — copié depuis `class_step_screen.dart` (voir sa doc de
/// classe pour le rationale de ne pas factoriser ce composant).
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
                    Text(
                      'CRÉATION',
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
                          '2. Sous-classe',
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

/// Bandeau bois minimal (retour + "CRÉATION" uniquement), affiché pendant le
/// chargement/l'erreur — copie exacte du pattern des autres étapes.
class _MinimalHeader extends StatelessWidget {
  const _MinimalHeader({required this.onBack, required this.onHelp});

  final VoidCallback onBack;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.woodMedium,
      child: SafeArea(
        bottom: false,
        child: Padding(
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
            SecondaryButton(label: 'Réessayer', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
