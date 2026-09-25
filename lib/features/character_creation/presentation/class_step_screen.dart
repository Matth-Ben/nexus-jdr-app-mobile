import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/accent_icon_badge.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/selectable_option_tile.dart';
import '../../../core/widgets/step_progress_bar.dart';
import '../domain/character_creation_failure.dart';
import '../domain/class_catalog.dart';
import '../domain/creation_step_help.dart';
import 'providers/character_creation_draft_provider.dart';
import 'providers/character_creation_providers.dart';
import 'providers/character_edit_session_provider.dart';
import 'providers/subclass_choice_providers.dart';
import 'widgets/abandon_creation_flow.dart';
import 'widgets/creation_mode_title.dart';
import 'widgets/draft_autosave_footer.dart';
import 'widgets/step_help_sheet.dart';

/// Étape 2/9 de l'assistant de création de personnage : choix de la classe
/// (`docs/cahier-des-charges/04-fonctionnalites-app-mobile.md` section 3
/// point 2, maquette `03_étape_2_classe.png`).
///
/// Plus simple que l'étape 1 "Race" : pas de "classe personnalisée".
/// "Suivant" s'active dès qu'une classe est choisie — le choix de
/// sous-classe (pour les classes qui la choisissent dès le niveau 1,
/// déterminées par les données, voir `SubclassChoiceCatalog`) n'est PAS
/// traité sur cet écran : `_submit` pousse `SubclassStepScreen`, une étape
/// séparée, pour les classes concernées (même principe que le choix de
/// sous-race de l'étape 1, voir `race_step_screen.dart`).
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

  @override
  void initState() {
    super.initState();
    // Réhydrate la sélection depuis le brouillon déjà en mémoire (retour en
    // arrière depuis une étape suivante) — voir
    // `docs/cahier-des-charges/05-ux-navigation.md` : "Possibilité de revenir
    // en arrière sans perdre les choix déjà faits." Le brouillon `keepAlive`
    // ne perd jamais la donnée, mais sans cette lecture l'écran repartait à
    // zéro visuellement. Si le brouillon est vide (première visite), rien ne
    // change : `classId` est `null`. La sous-classe (`draft.subclassId`)
    // n'est pas réhydratée ici : elle n'appartient plus à cet écran, voir
    // `SubclassStepScreen`.
    _selectedClassId = ref
        .read(characterCreationDraftControllerProvider)
        .classId;
  }

  /// Mode modification d'un personnage de niveau > 1 : la classe est
  /// affichée mais ne peut plus changer (décision utilisateur du
  /// 2026-09-25 — changer de classe invaliderait toute la progression).
  bool get _isClassLocked {
    final session = ref.read(characterEditSessionControllerProvider);
    return session != null && !session.canChangeClass;
  }

  void _selectClass(int classId) {
    if (_isClassLocked) return;
    setState(() {
      _selectedClassId = classId;
    });
  }

  /// Toujours poussée depuis `/characters/new` (étape 1 "Race") via
  /// `context.push` : `pop()` suffit, pas besoin du repli `context.go('/')`
  /// de `RaceStepScreen._goToCharacterList` (qui, lui, peut être la première
  /// route de la pile).
  void _goBack() => context.pop();

  /// Met à jour le brouillon en mémoire et décide de la navigation — aucun
  /// appel réseau supplémentaire fait par cet écran, même rationale que
  /// `RaceStepScreen._submit` (le catalogue de sous-classes est déjà chargé/
  /// en cours de chargement via [subclassChoiceCatalogProvider]).
  ///
  /// `subclassId` n'est mis à `null` que si la classe sélectionnée diffère
  /// réellement de celle déjà en brouillon (retour en arrière SANS changer de
  /// classe, puis "Suivant" à nouveau) : sinon on repasse `draft.subclassId`
  /// tel quel à `setClass`, pour ne pas effacer à tort un choix de
  /// sous-classe déjà fait sur `SubclassStepScreen` (et les choix de sorts
  /// qui en dépendent, voir `CharacterCreationDraftController.setClass`). Pour
  /// une classe réellement différente, `subclassId` reste `null` ici quelle
  /// qu'elle soit : il sera (ré)écrit par `SubclassStepScreen` pour les
  /// classes concernées — voir la doc de classe. Si le catalogue de
  /// sous-classes est encore en cours de chargement (sans valeur connue), on
  /// attend son résultat avant de trancher la navigation : une classe non
  /// concernée doit toujours filer directement vers l'étape 3, mais une
  /// classe concernée ne doit jamais manquer sa propre étape faute d'avoir
  /// attendu la réponse réseau.
  Future<void> _submit() async {
    // Classe verrouillée : ni sous-classe à choisir ni brouillon à changer.
    if (_isClassLocked) {
      context.push('/characters/new/step-3');
      return;
    }
    var subclassAsync = ref.read(subclassChoiceCatalogProvider);
    if (subclassAsync.isLoading && !subclassAsync.hasValue) {
      try {
        await ref.read(subclassChoiceCatalogProvider.future);
      } catch (_) {
        // Échec : dégradé en "aucune sous-classe requise" (voir ci-dessous).
      }
      if (!mounted) return;
      subclassAsync = ref.read(subclassChoiceCatalogProvider);
    }
    final classId = _selectedClassId!;
    final draft = ref.read(characterCreationDraftControllerProvider);
    ref
        .read(characterCreationDraftControllerProvider.notifier)
        .setClass(
          classId: classId,
          subclassId: draft.classId == classId ? draft.subclassId : null,
        );
    final concerned = subclassAsync.value?.isConcerned(classId) ?? false;
    if (concerned) {
      context.push('/characters/new/subclass');
    } else {
      context.push('/characters/new/step-3');
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(classCatalogProvider);
    // Pré-charge et garde vivant le catalogue de sous-classes pendant toute
    // la durée de vie de cet écran (`autoDispose` : sans ce `watch`, un
    // simple `ref.read` isolé dans `_submit` peut se faire recréer/redisposer
    // avant d'avoir résolu, faisant repartir la requête réseau à zéro à
    // chaque lecture) — jamais utilisé pour le rendu ici (voir `_submit`,
    // seul point qui en a besoin, et `SubclassStepScreen` pour son affichage).
    ref.watch(subclassChoiceCatalogProvider);

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

  /// "Suivant" est actif dès qu'une classe est choisie : le choix de
  /// sous-classe (pour les classes concernées) n'est plus une condition de
  /// CET écran, voir la doc de classe et `SubclassStepScreen`.
  bool get _canProceed => _selectedClassId != null;

  Widget _buildContent(ClassCatalog catalog) {
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
                      if (_isClassLocked) ...[
                        const InfoBanner(
                          message:
                              "La classe et la sous-classe ne peuvent être "
                              "modifiées qu'au niveau 1.",
                          icon: Icons.lock_outline,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      for (var i = 0; i < catalog.classes.length; i++) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.sm),
                        SelectableOptionTile(
                          title: catalog.classes[i].name,
                          subtitle: catalog.classes[i].summaryLine,
                          onInfo: () => showStepHelpSheet(
                            context,
                            StepHelpContent(
                              title: catalog.classes[i].name,
                              body: catalog.classes[i].infoText,
                            ),
                          ),
                          selected: _selectedClassId == catalog.classes[i].id,
                          leading: AccentIconBadge(
                            index: i,
                            icon: Icons.auto_awesome,
                          ),
                          onTap: () => _selectClass(catalog.classes[i].id),
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
                              onPressed: _canProceed ? () => _submit() : null,
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
