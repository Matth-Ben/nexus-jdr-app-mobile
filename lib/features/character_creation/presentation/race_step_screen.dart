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
import '../../../core/widgets/wood_back_header.dart';
import '../domain/character_creation_failure.dart';
import '../domain/race_catalog.dart';
import '../domain/race_step_selection.dart';
import '../domain/subrace_option.dart';
import 'providers/character_creation_draft_provider.dart';
import 'providers/character_creation_providers.dart';

/// Étape 1/9 de l'assistant de création de personnage : choix de la race
/// (`docs/cahier-des-charges/04-fonctionnalites-app-mobile.md` section 3
/// point 1, maquette `02_étape_1_race.png`).
///
/// En-tête bois plein (pas le dégradé "scène") : `Scaffold` classique plutôt
/// que `SceneScaffold`, avec un bandeau `wood.medium` posé manuellement au
/// sommet — voir `_Header` ci-dessous.
class RaceStepScreen extends ConsumerStatefulWidget {
  const RaceStepScreen({super.key});

  @override
  ConsumerState<RaceStepScreen> createState() => _RaceStepScreenState();
}

class _RaceStepScreenState extends ConsumerState<RaceStepScreen> {
  static const int _totalSteps = 9;

  final _customRaceController = TextEditingController();

  int? _selectedRaceId;
  int? _selectedSubraceId;
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
    // change : les trois champs valent `null`/`false` comme avant.
    final draft = ref.read(characterCreationDraftControllerProvider);
    _selectedRaceId = draft.raceId;
    _selectedSubraceId = draft.subraceId;
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
      if (raceId != _selectedRaceId) {
        _selectedSubraceId = null;
      }
      _selectedRaceId = raceId;
    });
  }

  void _selectSubrace(int subraceId) {
    setState(() {
      _selectedSubraceId = subraceId;
    });
  }

  void _selectCustomRace() {
    setState(() {
      _isCustomRaceSelected = true;
      _selectedRaceId = null;
      _selectedSubraceId = null;
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
  void _submit() {
    ref
        .read(characterCreationDraftControllerProvider.notifier)
        .setRace(
          raceId: _isCustomRaceSelected ? null : _selectedRaceId,
          subraceId: _isCustomRaceSelected ? null : _selectedSubraceId,
          raceCustomText: _isCustomRaceSelected
              ? _customRaceController.text.trim()
              : null,
        );
    context.push('/characters/new/step-2');
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(raceCatalogProvider);

    return Scaffold(
      body: Column(
        children: [
          WoodBackHeader(title: 'CRÉATION', onBack: _goToCharacterList),
          Expanded(
            child: catalogAsync.when(
              data: _buildContent,
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.goldEnd),
              ),
              error: (error, stackTrace) => _ErrorState(
                message: error is CharacterCreationFailure
                    ? error.message
                    : 'Impossible de charger les races disponibles. '
                          'Réessayez.',
                onRetry: () => ref.invalidate(raceCatalogProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(RaceCatalog catalog) {
    final subracesForSelectedRace = _selectedRaceId != null
        ? catalog.subracesOf(_selectedRaceId!)
        : const <SubraceOption>[];

    final canProceed = RaceStepSelection.canProceed(
      isCustomRace: _isCustomRaceSelected,
      customRaceText: _customRaceController.text,
      selectedRaceId: _selectedRaceId,
      selectedRaceHasSubraces: subracesForSelectedRace.isNotEmpty,
      selectedSubraceId: _selectedSubraceId,
    );

    return SafeArea(
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
                      ),
                    ),
                    Text(
                      'Étape 1 / $_totalSteps',
                      style: AppTypography.body(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                const StepProgressBar(totalSteps: _totalSteps, currentStep: 1),
                const SizedBox(height: AppSpacing.md),
                Text(
                  "Choisis l'ascendance de ton personnage.",
                  style: AppTypography.body(fontSize: 14),
                ),
              ],
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
                if (subracesForSelectedRace.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Choisis une sous-race.',
                    style: AppTypography.body(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (var i = 0; i < subracesForSelectedRace.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.sm),
                    SelectableOptionTile(
                      title: subracesForSelectedRace[i].name,
                      subtitle: subracesForSelectedRace[i].summaryLine,
                      selected:
                          _selectedSubraceId == subracesForSelectedRace[i].id,
                      leading: AccentIconBadge(
                        index: i,
                        icon: Icons.shield_rounded,
                      ),
                      onTap: () =>
                          _selectSubrace(subracesForSelectedRace[i].id),
                    ),
                  ],
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
            child: Row(
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
                    onPressed: canProceed ? _submit : null,
                  ),
                ),
              ],
            ),
          ),
        ],
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
