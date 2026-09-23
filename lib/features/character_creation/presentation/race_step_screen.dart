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
import '../domain/creation_step_help.dart';
import '../domain/race_catalog.dart';
import '../domain/race_step_selection.dart';
import 'providers/character_creation_draft_provider.dart';
import 'providers/character_creation_providers.dart';
import 'widgets/abandon_creation_flow.dart';
import 'widgets/draft_autosave_footer.dart';
import 'widgets/step_help_sheet.dart';

/// Étape 1/9 de l'assistant de création de personnage : choix de la race
/// (`docs/cahier-des-charges/04-fonctionnalites-app-mobile.md` section 3
/// point 1, maquette `02_étape_1_race.png`).
///
/// Le choix de sous-race n'est PAS traité sur cet écran : pour une race qui
/// en a, `_submit` pousse `SubraceStepScreen`, une étape séparée (même
/// principe que l'étape 6/9 "Sorts" déjà sautée pour une classe non
/// lanceuse de sorts, voir le commentaire de `/characters/new/step-7` dans
/// `core/router/app_router.dart`) — pour une race sans sous-race,
/// `/characters/new/step-2` est atteinte directement.
///
/// En-tête bois plein (pas le dégradé "scène") : `Scaffold` classique plutôt
/// que `SceneScaffold`, avec un bandeau `wood.medium` posé manuellement au
/// sommet, portant le titre d'étape et la barre de progression — voir
/// `_Header` ci-dessous.
///
/// N'utilise plus `core/widgets/wood_back_header.dart` (`WoodBackHeader`,
/// utilisé par ex. par `character_detail_screen.dart`) : ce composant partagé
/// n'affiche que retour + titre, sans titre d'étape ni `StepProgressBar` —
/// insuffisant ici. `_Header`/`_MinimalHeader` sont donc dupliqués localement
/// depuis `class_step_screen.dart`, comme les étapes 2 à 5, plutôt que
/// d'étendre `WoodBackHeader` (dette de fond signalée par le chef de projet,
/// pattern à ne pas factoriser dans `core/widgets` à cette occasion — voir
/// le principe de duplication assumée documenté dans ce module).
class RaceStepScreen extends ConsumerStatefulWidget {
  const RaceStepScreen({super.key});

  @override
  ConsumerState<RaceStepScreen> createState() => _RaceStepScreenState();
}

class _RaceStepScreenState extends ConsumerState<RaceStepScreen> {
  static const int _totalSteps = 9;

  final _customRaceController = TextEditingController();

  int? _selectedRaceId;
  bool _isCustomRaceSelected = false;

  @override
  void initState() {
    super.initState();
    // Réhydrate la sélection depuis le brouillon déjà en mémoire (retour en
    // arrière depuis une étape suivante) — voir
    // `docs/cahier-des-charges/05-ux-navigation.md` : "Possibilité de revenir
    // en arrière sans perdre les choix déjà faits." Le brouillon `keepAlive`
    // ne perd jamais la donnée, mais sans cette lecture l'écran repartait à
    // zéro visuellement. Si le brouillon est vide (première visite), rien ne
    // change : les deux champs valent `null`/`false` comme avant. La
    // sous-race (`draft.subraceId`) n'est pas réhydratée ici : elle
    // n'appartient plus à cet écran, voir `SubraceStepScreen`.
    final draft = ref.read(characterCreationDraftControllerProvider);
    _selectedRaceId = draft.raceId;
    _isCustomRaceSelected = draft.raceCustomText != null;
    if (_isCustomRaceSelected) {
      _customRaceController.text = draft.raceCustomText!;
    }
  }

  @override
  void dispose() {
    _customRaceController.dispose();
    super.dispose();
  }

  void _selectRace(int raceId) {
    setState(() {
      _isCustomRaceSelected = false;
      _selectedRaceId = raceId;
    });
  }

  void _selectCustomRace() {
    setState(() {
      _isCustomRaceSelected = true;
      _selectedRaceId = null;
    });
  }

  void _goToCharacterList() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  /// Met à jour le brouillon en mémoire et passe à l'étape suivante.
  ///
  /// Aucun appel réseau ici : contrairement à l'ancienne architecture (voir
  /// `data/character_creation_repository.dart`), cette étape n'écrit plus
  /// rien en base — juste l'état local du brouillon
  /// (`providers/character_creation_draft_provider.dart`), donc pas d'état
  /// de chargement ni de gestion d'erreur réseau nécessaires ici (à la
  /// différence du chargement du catalogue races/sous-races, un vrai appel
  /// réseau).
  ///
  /// `subraceId` n'est mis à `null` que si la race sélectionnée diffère
  /// réellement de celle déjà en brouillon (y compris un changement vers/
  /// depuis une race personnalisée) : retour en arrière SANS changer de race,
  /// puis "Suivant" à nouveau, doit conserver `draft.subraceId` tel quel pour
  /// ne pas effacer à tort un choix déjà fait sur `SubraceStepScreen`. Pour
  /// une race réellement différente, `subraceId` reste `null` ici quelle
  /// qu'elle soit : il sera (ré)écrit par `SubraceStepScreen` pour les races
  /// qui en ont — voir la doc de classe. La navigation dépend de [catalog]
  /// (déjà chargé, voir `_buildContent`) : une race avec sous-races pousse
  /// l'étape "Sous-race" ; sinon, l'étape 2/9 "Classe" est atteinte
  /// directement.
  void _submit(RaceCatalog catalog) {
    final draft = ref.read(characterCreationDraftControllerProvider);
    final newRaceId = _isCustomRaceSelected ? null : _selectedRaceId;
    final raceChanged =
        _isCustomRaceSelected != (draft.raceCustomText != null) ||
        draft.raceId != newRaceId;
    ref
        .read(characterCreationDraftControllerProvider.notifier)
        .setRace(
          raceId: newRaceId,
          subraceId: raceChanged ? null : draft.subraceId,
          raceCustomText: _isCustomRaceSelected
              ? _customRaceController.text.trim()
              : null,
        );
    final selectedRaceId = _selectedRaceId;
    if (!_isCustomRaceSelected &&
        selectedRaceId != null &&
        catalog.subracesOf(selectedRaceId).isNotEmpty) {
      context.push('/characters/new/subrace');
    } else {
      context.push('/characters/new/step-2');
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(raceCatalogProvider);

    return Scaffold(
      body: catalogAsync.when(
        data: _buildContent,
        loading: () => Column(
          children: [
            _MinimalHeader(
              onBack: _goToCharacterList,
              onHelp: () => showStepHelpSheet(context, CreationStepHelp.race),
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
              onBack: _goToCharacterList,
              onHelp: () => showStepHelpSheet(context, CreationStepHelp.race),
            ),
            Expanded(
              child: _ErrorState(
                message: error is CharacterCreationFailure
                    ? error.message
                    : 'Impossible de charger les races disponibles. '
                          'Réessayez.',
                onRetry: () => ref.invalidate(raceCatalogProvider),
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

  Widget _buildContent(RaceCatalog catalog) {
    final canProceed = RaceStepSelection.canProceed(
      isCustomRace: _isCustomRaceSelected,
      customRaceText: _customRaceController.text,
      selectedRaceId: _selectedRaceId,
    );

    return Column(
      children: [
        _Header(
          onBack: _goToCharacterList,
          currentStep: 1,
          totalSteps: _totalSteps,
          onHelp: () => showStepHelpSheet(context, CreationStepHelp.race),
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
                      "Choisis l'ascendance de ton personnage.",
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
                      for (var i = 0; i < catalog.races.length; i++) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.sm),
                        SelectableOptionTile(
                          title: catalog.races[i].name,
                          subtitle: catalog.races[i].summaryLine,
                          selected:
                              !_isCustomRaceSelected &&
                              _selectedRaceId == catalog.races[i].id,
                          leading: AccentIconBadge(
                            index: i,
                            icon: Icons.shield_rounded,
                          ),
                          onTap: () => _selectRace(catalog.races[i].id),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      SelectableOptionTile(
                        title: 'Race personnalisée',
                        selected: _isCustomRaceSelected,
                        leading: const AccentIconBadge(
                          index: -1,
                          icon: Icons.shield_rounded,
                          neutralIcon: Icons.edit_note,
                        ),
                        onTap: _selectCustomRace,
                      ),
                      if (_isCustomRaceSelected) ...[
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: _customRaceController,
                          decoration: const InputDecoration(
                            hintText: 'Nom de la race personnalisée',
                          ),
                          onChanged: (_) => setState(() {}),
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
                              onPressed: _goToCharacterList,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: PrimaryButton(
                              label: 'Suivant',
                              onPressed: canProceed
                                  ? () => _submit(catalog)
                                  : null,
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
/// [RaceStepScreen] pour le rationale de ne plus utiliser `WoodBackHeader`
/// ici).
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
                          '1. Race',
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
