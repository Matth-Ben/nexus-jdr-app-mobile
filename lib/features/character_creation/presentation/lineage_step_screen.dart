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
import '../domain/lineage_choice_catalog.dart';
import '../domain/lineage_step_selection.dart';
import 'providers/character_creation_draft_provider.dart';
import 'providers/lineage_choice_providers.dart';
import 'widgets/abandon_creation_flow.dart';
import 'widgets/creation_mode_title.dart';
import 'widgets/draft_autosave_footer.dart';
import 'widgets/step_help_sheet.dart';

/// Étape 1/9 "Lignée" de l'assistant de création de personnage, second écran
/// de l'étape "Race" — atteinte uniquement depuis `RaceStepScreen`
/// (`_submit`) quand la race choisie a des lignées 2024 à choisir SANS
/// sous-race (`LineageChoiceCatalog.isConcerned`, critère générique dérivé
/// des données — jamais une liste de races en dur), jamais directement,
/// jamais pour une race personnalisée. À ce jour, seules trois races
/// remplissent ce critère (Drakéide, Tieffelin, Goliath, voir
/// [_LineageStepCopy] pour leurs textes d'écran respectifs) — l'Elfe, qui a
/// aussi des lignées 2024, en est exclu par ce même critère car il a par
/// ailleurs des sous-races (voir `RaceCatalog.subracesOf`), tout comme le
/// Gnome/le Génasi dont la lignée se déduit automatiquement de la sous-race
/// choisie (voir `data/character_creation_repository.dart::createCharacter`).
///
/// Ne fait PAS avancer le compteur d'étape (`currentStep: 1`, comme
/// `RaceStepScreen`/`SubraceStepScreen`) : c'est un second écran de la même
/// étape logique, pas une étape à part entière du parcours en 9 étapes.
///
/// `_Header`/`_MinimalHeader`/`_ErrorState` dupliqués localement plutôt que
/// factorisés avec `RaceStepScreen`/`SubraceStepScreen` : voir la doc de
/// classe de ce dernier pour le rationale de cette duplication assumée dans
/// tout ce module.
class LineageStepScreen extends ConsumerStatefulWidget {
  const LineageStepScreen({super.key});

  @override
  ConsumerState<LineageStepScreen> createState() => _LineageStepScreenState();
}

class _LineageStepScreenState extends ConsumerState<LineageStepScreen> {
  static const int _totalSteps = 9;

  int? _raceId;
  int? _selectedLineageId;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(characterCreationDraftControllerProvider);
    _raceId = draft.raceId;
    // Réhydrate le choix déjà fait (retour en arrière depuis une étape
    // suivante) — même rationale que `SubraceStepScreen.initState`.
    _selectedLineageId = draft.lineageId;

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

  void _selectLineage(int lineageId) {
    setState(() {
      _selectedLineageId = lineageId;
    });
  }

  void _goBack() => context.pop();

  /// Met à jour le brouillon en mémoire et passe à l'étape suivante — aucun
  /// appel réseau ici, même rationale que `SubraceStepScreen._submit`.
  void _submit() {
    ref
        .read(characterCreationDraftControllerProvider.notifier)
        .setLineage(_selectedLineageId!);
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

    final copy = _LineageStepCopy.forRaceId(raceId);
    final catalogAsync = ref.watch(lineageChoiceCatalogProvider);

    return Scaffold(
      body: catalogAsync.when(
        data: (catalog) => _buildContent(catalog, raceId, copy),
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
                    : 'Impossible de charger les ascendances/lignées '
                          'disponibles. Réessayez.',
                onRetry: () => ref.invalidate(lineageChoiceCatalogProvider),
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

  Widget _buildContent(
    LineageChoiceCatalog catalog,
    int raceId,
    _LineageStepCopy copy,
  ) {
    final options = catalog.optionsFor(raceId);
    final canProceed = LineageStepSelection.canProceed(
      selectedLineageId: _selectedLineageId,
    );

    return Column(
      children: [
        _Header(
          onBack: _goBack,
          currentStep: 1,
          totalSteps: _totalSteps,
          bannerTitle: copy.bannerTitle,
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
                      copy.introText,
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
                      for (var i = 0; i < options.length; i++) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.sm),
                        SelectableOptionTile(
                          title: options[i].name,
                          subtitle: options[i].subtitle,
                          selected: _selectedLineageId == options[i].id,
                          leading: AccentIconBadge(
                            index: i,
                            icon: Icons.shield_rounded,
                          ),
                          onTap: () => _selectLineage(options[i].id),
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

/// Titre de bandeau et phrase d'intro affichés par [LineageStepScreen],
/// propres à chaque race — identifiants `races.id` figés par les données
/// actuelles (5 Drakéide, 9 Tieffelin, 24 Goliath), jamais dérivés
/// dynamiquement : ce sont de simples libellés d'écran pour une race DÉJÀ
/// connue (celle choisie à `RaceStepScreen`), pas le critère de
/// déclenchement de cet écran (générique, voir la doc de classe de
/// [LineageStepScreen]). Toute autre race (ne devrait pas arriver, voir le
/// critère de déclenchement) retombe sur le libellé générique "Ascendance".
class _LineageStepCopy {
  const _LineageStepCopy({required this.bannerTitle, required this.introText});

  final String bannerTitle;
  final String introText;

  static const int _drakeideRaceId = 5;
  static const int _tieffelinRaceId = 9;
  static const int _goliathRaceId = 24;

  factory _LineageStepCopy.forRaceId(int raceId) {
    switch (raceId) {
      case _tieffelinRaceId:
        return const _LineageStepCopy(
          bannerTitle: '1. Lignée',
          introText: 'Choisis ta lignée fiélonne.',
        );
      case _goliathRaceId:
        return const _LineageStepCopy(
          bannerTitle: '1. Ascendance',
          introText: 'Choisis ton ascendance géante.',
        );
      case _drakeideRaceId:
      default:
        return const _LineageStepCopy(
          bannerTitle: '1. Ascendance',
          introText: 'Choisis ton ascendance draconique.',
        );
    }
  }
}

/// Bandeau bois plein en tête d'écran, avec le titre d'étape et la barre de
/// progression — copié depuis `subrace_step_screen.dart` (voir sa doc de
/// classe pour le rationale de ne pas factoriser ce composant), [bannerTitle]
/// paramétré (contrairement aux autres écrans) puisqu'il dépend de la race —
/// voir [_LineageStepCopy].
class _Header extends StatelessWidget {
  const _Header({
    required this.onBack,
    required this.currentStep,
    required this.totalSteps,
    required this.bannerTitle,
    required this.onHelp,
  });

  final VoidCallback onBack;
  final int currentStep;
  final int totalSteps;
  final String bannerTitle;
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
                          bannerTitle,
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
