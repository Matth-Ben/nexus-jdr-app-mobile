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
import '../domain/creation_step_help.dart';
import 'providers/character_creation_draft_provider.dart';
import 'widgets/abandon_creation_flow.dart';
import 'widgets/creation_mode_title.dart';
import 'widgets/draft_autosave_footer.dart';
import 'widgets/step_help_sheet.dart';

/// Étape 1/10, TOUTE PREMIÈRE étape de l'assistant de création de
/// personnage — AVANT même `RaceStepScreen` : choix de l'édition de règles
/// D&D 5e (`'2014'` Manuel des Joueurs / `'2024'` Manuel des Joueurs revu),
/// chantier "choix d'édition 2014/2024 par personnage". Choix figé pour
/// toute la vie du personnage (`CharacterCreationDraft.edition`, persisté
/// immuable sur `characters.edition` par `createCharacter`) : aucun écran de
/// la fiche personnage ne permet de le changer après coup, contrairement aux
/// autres choix de cet assistant qui restent éditables via "Modifier"
/// (`character_edit_flow.dart`) — voir [RaceStepScreen] pour la race,
/// verrouillée elle aussi mais pour une raison RAW différente (sorts innés
/// déjà acquis).
///
/// Décale la numérotation affichée de toutes les étapes suivantes d'un cran
/// (9 → 10 au total) : `RaceStepScreen` devient l'étape 2/10, etc. — voir le
/// commentaire de `core/router/app_router.dart` sur `/characters/new`.
///
/// Atteint uniquement par un chemin de création BRAND NEW (`+ Créer` de
/// `CharacterListScreen`, "+ Créer un nouveau personnage" du flux "Rejoindre
/// une histoire", "Créer un personnage" du flux de réaffectation de groupe —
/// voir `core/router/app_router.dart`, route `/characters/new/edition`),
/// JAMAIS en mode modification (`startCharacterEdit`,
/// `widgets/character_edit_flow.dart`) : un personnage existant a déjà une
/// édition figée, cet écran n'a donc aucune raison d'être réatteint pour lui
/// — `startCharacterEdit` pousse directement `/characters/new` (Race).
///
/// Même registre visuel que `RaceStepScreen`/`ClassStepScreen` (bandeau bois
/// plein + corps parchemin, `_Header`/`_MinimalHeader` dupliqués localement
/// plutôt que factorisés — voir leur documentation de classe pour le
/// rationale de cette duplication assumée dans tout ce module). Pas de
/// catalogue réseau à charger (2 options figées en dur, jamais issues de
/// Supabase) : contrairement à `RaceStepScreen`, aucun état de
/// chargement/erreur n'est donc nécessaire ici.
class EditionStepScreen extends ConsumerStatefulWidget {
  const EditionStepScreen({super.key});

  @override
  ConsumerState<EditionStepScreen> createState() => _EditionStepScreenState();
}

class _EditionStepScreenState extends ConsumerState<EditionStepScreen> {
  static const int _totalSteps = 10;

  late String _selectedEdition;

  @override
  void initState() {
    super.initState();
    // Réhydrate la sélection depuis le brouillon déjà en mémoire (retour en
    // arrière depuis une étape suivante) — même rationale que
    // `RaceStepScreen.initState`. `CharacterCreationDraft.edition` vaut
    // toujours `'2014'` par défaut (jamais `null`), donc cette tuile est
    // déjà présélectionnée à la toute première visite de cet écran, même
    // principe que `AbilityScoreStepScreen` retombant sur
    // `AbilityScoreMethod.standardArray`.
    _selectedEdition = ref
        .read(characterCreationDraftControllerProvider)
        .edition;
  }

  void _selectEdition(String edition) {
    setState(() => _selectedEdition = edition);
  }

  void _goToCharacterList() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  /// Met à jour le brouillon en mémoire et passe à l'étape suivante (Race) —
  /// aucun appel réseau ici, même rationale que `RaceStepScreen._submit`.
  void _submit() {
    ref
        .read(characterCreationDraftControllerProvider.notifier)
        .setEdition(_selectedEdition);
    context.push('/characters/new');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _Header(
            onBack: _goToCharacterList,
            currentStep: 1,
            totalSteps: _totalSteps,
            onHelp: () => showStepHelpSheet(context, CreationStepHelp.edition),
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
                        "Choisis l'édition des règles D&D 5e pour ce "
                        'personnage. Ce choix est définitif.',
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
                        SelectableOptionTile(
                          title: '2014 — Manuel des Joueurs',
                          subtitle:
                              "L'édition originale des règles D&D 5e, "
                              'publiée en 2014.',
                          selected: _selectedEdition == '2014',
                          leading: const AccentIconBadge(
                            index: 0,
                            icon: Icons.menu_book,
                          ),
                          onTap: () => _selectEdition('2014'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SelectableOptionTile(
                          title: '2024 — Manuel des Joueurs revu',
                          subtitle:
                              "L'édition révisée des règles D&D 5e, "
                              'publiée en 2024, avec certains '
                              'ajustements de règles.',
                          selected: _selectedEdition == '2024',
                          leading: const AccentIconBadge(
                            index: 1,
                            icon: Icons.menu_book,
                          ),
                          onTap: () => _selectEdition('2024'),
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
                                onPressed: _goToCharacterList,
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
                          onAbandon: () =>
                              abandonCharacterCreation(context, ref),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bandeau bois plein en tête d'écran, avec le titre d'étape et la barre de
/// progression — copié depuis `race_step_screen.dart` (voir sa doc de classe
/// pour le rationale de ne pas factoriser ce composant dans `core/widgets`).
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
                          '1. Édition',
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
