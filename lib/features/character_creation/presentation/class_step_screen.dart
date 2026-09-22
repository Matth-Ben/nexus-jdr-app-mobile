import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/accent_icon_badge.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/selectable_option_tile.dart';
import '../../../core/widgets/step_progress_bar.dart';
import '../domain/character_creation_failure.dart';
import '../domain/class_catalog.dart';
import '../domain/creation_step_help.dart';
import '../domain/subclass_choice_catalog.dart';
import '../domain/subclass_choice_rules.dart';
import 'providers/character_creation_draft_provider.dart';
import 'providers/character_creation_providers.dart';
import 'providers/subclass_choice_providers.dart';
import 'widgets/abandon_creation_flow.dart';
import 'widgets/draft_autosave_footer.dart';
import 'widgets/subclass_choice_block.dart';
import 'widgets/step_help_sheet.dart';

/// Étape 2/9 de l'assistant de création de personnage : choix de la classe
/// (`docs/cahier-des-charges/04-fonctionnalites-app-mobile.md` section 3
/// point 2, maquette `03_étape_2_classe.png`).
///
/// Plus simple que l'étape 1 "Race" : pas de "classe personnalisée". Pour les
/// classes qui choisissent leur sous-classe dès le niveau 1 (déterminées par
/// les données, voir `SubclassChoiceCatalog`), un bloc de choix s'insère sous
/// la tuile de la classe sélectionnée et "Suivant" attend ce choix ; pour
/// toutes les autres, "Suivant" s'active dès qu'une classe est choisie.
///
/// En-tête bois plein dupliqué depuis `race_step_screen.dart`
/// (`_Header` ci-dessous) plutôt que factorisé dans `core/widgets` : même
/// principe que `ClassRowMapper` dupliqué depuis `RaceRowMapper`, pour ne pas
/// coupler les deux étapes entre elles.
class ClassStepScreen extends ConsumerStatefulWidget {
  const ClassStepScreen({super.key});

  @override
  ConsumerState<ClassStepScreen> createState() => _ClassStepScreenState();
}

class _ClassStepScreenState extends ConsumerState<ClassStepScreen> {
  static const int _totalSteps = 9;

  int? _selectedClassId;
  int? _selectedSubclassId;

  /// Ancre du bloc de sous-classe, pour le faire défiler dans la vue après la
  /// sélection d'une classe concernée.
  final GlobalKey _subclassBlockKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Réhydrate la sélection depuis le brouillon déjà en mémoire (retour en
    // arrière depuis une étape suivante) — voir
    // `docs/cahier-des-charges/05-ux-navigation.md` : "Possibilité de revenir
    // en arrière sans perdre les choix déjà faits." Le brouillon `keepAlive`
    // ne perd jamais la donnée, mais sans cette lecture l'écran repartait à
    // zéro visuellement. Si le brouillon est vide (première visite), rien ne
    // change : `classId` est `null`.
    _selectedClassId = ref
        .read(characterCreationDraftControllerProvider)
        .classId;
    _selectedSubclassId = ref
        .read(characterCreationDraftControllerProvider)
        .subclassId;
  }

  void _selectClass(int classId) {
    final previous = _selectedClassId;
    setState(() {
      // Une classe DIFFÉRENTE efface la sous-classe (locale ; le brouillon
      // n'est écrit qu'à "Suivant") ; recliquer la même classe ne change rien.
      _selectedSubclassId = SubclassChoiceRules.subclassAfterClassChange(
        previousClassId: previous,
        newClassId: classId,
        currentSubclassId: _selectedSubclassId,
      );
      _selectedClassId = classId;
    });
    if (previous == classId) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final blockContext = _subclassBlockKey.currentContext;
      if (!mounted || blockContext == null) return;
      Scrollable.ensureVisible(
        blockContext,
        duration: const Duration(milliseconds: 250),
      );
    });
  }

  /// Toujours poussée depuis `/characters/new` (étape 1 "Race") via
  /// `context.push` : `pop()` suffit, pas besoin du repli `context.go('/')`
  /// de `RaceStepScreen._goToCharacterList` (qui, lui, peut être la première
  /// route de la pile).
  void _goBack() => context.pop();

  /// Met à jour le brouillon en mémoire et passe à l'étape suivante — aucun
  /// appel réseau ici, même rationale que `RaceStepScreen._submit`.
  ///
  /// Si le catalogue de sous-classes est encore en cours de chargement (sans
  /// valeur connue), on attend son résultat avant de trancher : "Suivant"
  /// n'est jamais bloqué pour une classe non concernée, mais une classe
  /// concernée ne doit pas passer sans son choix.
  Future<void> _submit() async {
    var subclassAsync = ref.read(subclassChoiceCatalogProvider);
    if (subclassAsync.isLoading && !subclassAsync.hasValue) {
      try {
        await ref.read(subclassChoiceCatalogProvider.future);
      } catch (_) {
        // Échec : dégradé en "aucune sous-classe requise" (voir _canProceed).
      }
      if (!mounted) return;
      subclassAsync = ref.read(subclassChoiceCatalogProvider);
    }
    if (!_canProceed(subclassAsync)) return;
    ref
        .read(characterCreationDraftControllerProvider.notifier)
        .setClass(classId: _selectedClassId!, subclassId: _selectedSubclassId);
    context.push('/characters/new/step-3');
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(classCatalogProvider);

    return Scaffold(
      body: catalogAsync.when(
        data: _buildContent,
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

  /// `true` si le catalogue de sous-classes (éventuellement une valeur
  /// précédente, conservée pendant un rechargement ou après un échec) indique
  /// que [classId] choisit sa sous-classe au niveau 1.
  bool _isKnownConcerned(
    AsyncValue<SubclassChoiceCatalog> subclassAsync,
    int classId,
  ) => subclassAsync.value?.isConcerned(classId) ?? false;

  /// "Suivant" est actif si une classe est choisie et, seulement quand elle
  /// est CONNUE pour choisir une sous-classe au niveau 1, que ce choix est
  /// fait. Une classe non concernée, ou dont on ne sait rien (catalogue en
  /// cours de chargement ou indisponible : ni réseau ni cache), n'est jamais
  /// bloquée ; une liste d'options vide non plus. Pendant un rechargement ou
  /// après un échec d'une classe connue concernée, "Suivant" reste désactivé.
  bool _canProceed(AsyncValue<SubclassChoiceCatalog> subclassAsync) {
    final classId = _selectedClassId;
    if (classId == null) return false;
    if (!_isKnownConcerned(subclassAsync, classId)) return true;
    if (subclassAsync.isLoading || subclassAsync.hasError) return false;
    final options = subclassAsync.requireValue.optionsFor(classId);
    if (options == null || options.isEmpty) return true;
    return options.any((option) => option.id == _selectedSubclassId);
  }

  Widget _buildContent(ClassCatalog catalog) {
    final subclassAsync = ref.watch(subclassChoiceCatalogProvider);
    final canProceed = _canProceed(subclassAsync);

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
                      'Choisis la voie que ton personnage empruntera.',
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
                      for (var i = 0; i < catalog.classes.length; i++) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.sm),
                        SelectableOptionTile(
                          title: catalog.classes[i].name,
                          subtitle: catalog.classes[i].summaryLine,
                          selected: _selectedClassId == catalog.classes[i].id,
                          leading: AccentIconBadge(
                            index: i,
                            icon: Icons.auto_awesome,
                          ),
                          onTap: () => _selectClass(catalog.classes[i].id),
                        ),
                        if (_selectedClassId == catalog.classes[i].id &&
                            _isKnownConcerned(
                              subclassAsync,
                              catalog.classes[i].id,
                            ))
                          KeyedSubtree(
                            key: _subclassBlockKey,
                            child: SubclassChoiceBlock(
                              key: ValueKey(catalog.classes[i].id),
                              classId: catalog.classes[i].id,
                              className: catalog.classes[i].name,
                              catalogAsync: subclassAsync,
                              selectedSubclassId: _selectedSubclassId,
                              onSelect: (id) =>
                                  setState(() => _selectedSubclassId = id),
                              onRetry: () =>
                                  ref.invalidate(subclassChoiceCatalogProvider),
                            ),
                          ),
                      ],
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
                              onPressed: canProceed ? () => _submit() : null,
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
/// progression — copié depuis `equipment_step_screen.dart`/
/// `summary_step_screen.dart` (voir la documentation de classe de
/// [ClassStepScreen]).
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
                          '2. Classe',
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
/// chargement/l'erreur — copie exacte du pattern des étapes 6/7/9.
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
