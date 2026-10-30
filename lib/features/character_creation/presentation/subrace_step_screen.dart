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
import '../domain/race_option.dart';
import '../domain/subrace_option.dart';
import '../domain/subrace_step_selection.dart';
import 'providers/character_creation_draft_provider.dart';
import 'providers/character_creation_providers.dart';
import 'widgets/abandon_creation_flow.dart';
import 'widgets/creation_mode_title.dart';
import 'widgets/draft_autosave_footer.dart';
import 'widgets/step_help_sheet.dart';

/// Étape 2/10 "Sous-race" de l'assistant de création de personnage, second
/// écran de l'étape "Race" — atteinte uniquement depuis `RaceStepScreen`
/// (`_submit`) quand la race choisie a des sous-races (`RaceCatalog
/// .subracesOf`), jamais directement, jamais pour une race personnalisée.
///
/// Ne fait PAS avancer le compteur d'étape (`currentStep: 2`, comme
/// `RaceStepScreen`) : c'est un second écran de la même étape logique, pas
/// une étape à part entière du parcours en 10 étapes (depuis le chantier
/// "choix d'édition 2014/2024 par personnage", `EditionStepScreen`) — même
/// principe que la numérotation figée de `SubclassStepScreen` (étape 3
/// "Classe").
///
/// `_Header`/`_MinimalHeader`/`_ErrorState` dupliqués localement plutôt que
/// factorisés avec `RaceStepScreen` (`race_step_screen.dart`) : voir la doc
/// de classe de ce dernier pour le rationale de cette duplication assumée
/// dans tout ce module.
///
/// Chantier "différenciation 2014/2024 pour les races" (24/10/2026),
/// étendu aux sous-races le 30/10/2026 : une sous-race sans contenu 2024
/// propre (`SubraceOption.traits2024` nul, ex. Eladrin/Elfe marin/Shadar-kai
/// pour l'Elfe, Svirfnebelin pour le Gnome) est masquée en édition 2024 —
/// voir [_isSubraceAvailable] et son point d'appel dans [_filterSubraces],
/// même principe de masquage complet (pas de griséification) que
/// `RaceStepScreen._isRaceAvailable`/`_filterRaces`. Le Nain/l'Halfelin
/// (`RaceCatalog.isUnifiedRaceIn2024`) n'atteignent jamais cet écran en 2024
/// (sauté entièrement par `RaceStepScreen._submit`) : ce filtre ne les
/// concerne donc jamais en pratique.
class SubraceStepScreen extends ConsumerStatefulWidget {
  const SubraceStepScreen({super.key});

  @override
  ConsumerState<SubraceStepScreen> createState() => _SubraceStepScreenState();
}

class _SubraceStepScreenState extends ConsumerState<SubraceStepScreen> {
  static const int _totalSteps = 10;

  int? _raceId;
  int? _selectedSubraceId;

  /// Édition du brouillon, lue une seule fois comme [_raceId] : fixée à
  /// `EditionStepScreen`, TOUTE PREMIÈRE étape de l'assistant, avant
  /// celle-ci. Pilote [_isSubraceAvailable] — même rationale que
  /// `RaceStepScreen._edition`.
  late String _edition;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(characterCreationDraftControllerProvider);
    _raceId = draft.raceId;
    _edition = draft.edition;
    // Réhydrate le choix déjà fait (retour en arrière depuis une étape
    // suivante) — même rationale que `RaceStepScreen.initState`.
    _selectedSubraceId = draft.subraceId;

    if (_raceId == null) {
      // Cas défensif (ex. deep-link direct sur cette route) : cet écran
      // n'est censé être atteint que depuis `RaceStepScreen`, qui a déjà
      // écrit `raceId` dans le brouillon avant de pousser cette route.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go('/characters/new');
      });
    }
  }

  void _selectSubrace(int subraceId) {
    setState(() {
      _selectedSubraceId = subraceId;
    });
  }

  /// `false` si [subrace] n'existe pas RAW en édition 2024
  /// (`SubraceOption.traits2024` nul) — toujours `true` en édition 2014.
  /// Pilote [_filterSubraces] (sous-races exclues de la liste affichée) —
  /// même principe que `RaceStepScreen._isRaceAvailable`, voir la doc de
  /// classe de [SubraceStepScreen].
  bool _isSubraceAvailable(SubraceOption subrace) {
    if (_edition != '2024') return true;
    return subrace.traits2024 != null;
  }

  /// Sous-races de [catalog] pour [_raceId] disponibles dans l'édition
  /// courante ([_isSubraceAvailable]) — toutes les sous-races de cette race
  /// en édition 2014, puisque [_isSubraceAvailable] y vaut toujours `true`.
  /// Ordre d'origine préservé (`RaceCatalog.subracesOf`), un simple `where`
  /// ne le modifie pas.
  List<SubraceOption> _filterSubraces(RaceCatalog catalog, int raceId) => [
    for (final subrace in catalog.subracesOf(raceId))
      if (_isSubraceAvailable(subrace)) subrace,
  ];

  void _goBack() => context.pop();

  /// Met à jour le brouillon en mémoire et passe à l'étape suivante — aucun
  /// appel réseau ici, même rationale que `RaceStepScreen._submit`.
  void _submit() {
    ref
        .read(characterCreationDraftControllerProvider.notifier)
        .setRace(
          raceId: _raceId,
          subraceId: _selectedSubraceId,
          raceCustomText: null,
        );
    context.push('/characters/new/step-2');
  }

  @override
  Widget build(BuildContext context) {
    final raceId = _raceId;
    if (raceId == null) {
      // Redirection défensive déjà programmée dans `initState` : rien à
      // afficher le temps qu'elle se déclenche.
      return const Scaffold(body: SizedBox.shrink());
    }

    final catalogAsync = ref.watch(raceCatalogProvider);

    return Scaffold(
      body: catalogAsync.when(
        data: (catalog) => _buildContent(catalog, raceId),
        loading: () => Column(
          children: [
            _MinimalHeader(
              onBack: _goBack,
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
              onBack: _goBack,
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

  Widget _buildContent(RaceCatalog catalog, int raceId) {
    final raceName = catalog.races
        .firstWhere(
          (race) => race.id == raceId,
          orElse: () => RaceOption(
            id: raceId,
            name: 'cette race',
            abilityBonuses: const {},
            traits: const [],
            source: '',
          ),
        )
        .name;
    final subraces = _filterSubraces(catalog, raceId);
    final canProceed = SubraceStepSelection.canProceed(
      selectedSubraceId: _selectedSubraceId,
    );

    return Column(
      children: [
        _Header(
          onBack: _goBack,
          currentStep: 2,
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
                      'Choisis une sous-race pour $raceName.',
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
                      for (var i = 0; i < subraces.length; i++) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.sm),
                        SelectableOptionTile(
                          title: subraces[i].name,
                          subtitle: subraces[i].summaryLine,
                          onInfo: () => showStepHelpSheet(
                            context,
                            StepHelpContent(
                              title: subraces[i].name,
                              body: subraces[i].infoText,
                            ),
                          ),
                          selected: _selectedSubraceId == subraces[i].id,
                          leading: AccentIconBadge(
                            index: i,
                            icon: Icons.shield_rounded,
                          ),
                          onTap: () => _selectSubrace(subraces[i].id),
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
/// progression — copié depuis `race_step_screen.dart` (voir sa doc de classe
/// pour le rationale de ne pas factoriser ce composant).
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
                          '2. Sous-race',
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
