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
import '../domain/background_catalog.dart';
import '../domain/character_creation_failure.dart';
import 'providers/character_creation_draft_provider.dart';
import 'providers/character_creation_providers.dart';

/// Étape 3/9 de l'assistant de création de personnage : choix de l'historique
/// (`docs/cahier-des-charges/04-fonctionnalites-app-mobile.md` section 3
/// point 3, maquette `04_étape_3_historique.png`).
///
/// Même gabarit que `ClassStepScreen` (étape 2) : ni historique personnalisé,
/// ni choix de compétences/outils/langues à cette étape (voir
/// `domain/background_catalog.dart`) — "Suivant" s'active dès qu'un
/// historique est choisi.
///
/// Différence par rapport à Race/Classe : chaque ligne affiche en plus
/// "Compétences : X, Y" (toujours visible), et la ligne **sélectionnée
/// uniquement** affiche "Aptitude : {nom} — {description}" en dessous, via le
/// slot `SelectableOptionTile.selectedDetail`.
///
/// En-tête bois plein dupliqué depuis `class_step_screen.dart`/
/// `race_step_screen.dart` (`_Header` ci-dessous) plutôt que factorisé dans
/// `core/widgets` : même principe que `BackgroundRowMapper` dupliqué depuis
/// `ClassRowMapper`, pour ne pas coupler les étapes entre elles.
///
/// Écart assumé par rapport à la maquette `04_étape_3_historique.png` : cette
/// maquette ne montre aucune icône à gauche des tuiles, mais `AccentIconBadge`
/// est conservé ici (décision du chef de projet) pour la cohérence visuelle
/// avec les étapes Race/Classe qui la précèdent — un joueur qui enchaîne les
/// étapes ne doit pas voir l'iconographie disparaître puis réapparaître.
class BackgroundStepScreen extends ConsumerStatefulWidget {
  const BackgroundStepScreen({super.key});

  @override
  ConsumerState<BackgroundStepScreen> createState() =>
      _BackgroundStepScreenState();
}

class _BackgroundStepScreenState extends ConsumerState<BackgroundStepScreen> {
  static const int _totalSteps = 9;

  int? _selectedBackgroundId;

  @override
  void initState() {
    super.initState();
    // Réhydrate la sélection depuis le brouillon déjà en mémoire (retour en
    // arrière depuis une étape suivante) — voir
    // `docs/cahier-des-charges/05-ux-navigation.md` : "Possibilité de revenir
    // en arrière sans perdre les choix déjà faits." Le brouillon `keepAlive`
    // ne perd jamais la donnée, mais sans cette lecture l'écran repartait à
    // zéro visuellement. Si le brouillon est vide (première visite), rien ne
    // change : `backgroundId` est `null`.
    _selectedBackgroundId = ref
        .read(characterCreationDraftControllerProvider)
        .backgroundId;
  }

  void _selectBackground(int backgroundId) {
    setState(() {
      _selectedBackgroundId = backgroundId;
    });
  }

  /// Toujours poussée depuis `/characters/new/step-2` (étape 2 "Classe") via
  /// `context.push` : `pop()` suffit, même rationale que
  /// `ClassStepScreen._goBack`.
  void _goBack() => context.pop();

  /// Met à jour le brouillon en mémoire et passe à l'étape suivante — aucun
  /// appel réseau ici, même rationale que `ClassStepScreen._submit`.
  void _submit() {
    ref
        .read(characterCreationDraftControllerProvider.notifier)
        .setBackground(backgroundId: _selectedBackgroundId!);
    context.push('/characters/new/step-4');
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(backgroundCatalogProvider);

    return Scaffold(
      body: catalogAsync.when(
        data: _buildContent,
        loading: () => Column(
          children: [
            _MinimalHeader(onBack: _goBack),
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.woodMedium),
              ),
            ),
          ],
        ),
        error: (error, stackTrace) => Column(
          children: [
            _MinimalHeader(onBack: _goBack),
            Expanded(
              child: _ErrorState(
                message: error is CharacterCreationFailure
                    ? error.message
                    : 'Impossible de charger les historiques disponibles. '
                          'Réessayez.',
                onRetry: () => ref.invalidate(backgroundCatalogProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BackgroundCatalog catalog) {
    final canProceed = _selectedBackgroundId != null;

    return Column(
      children: [
        _Header(onBack: _goBack, currentStep: 3, totalSteps: _totalSteps),
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
                      "D'où vient ton personnage avant l'aventure ?",
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
                      for (var i = 0; i < catalog.backgrounds.length; i++) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.sm),
                        SelectableOptionTile(
                          title: catalog.backgrounds[i].name,
                          subtitle: catalog.backgrounds[i].skillsSummaryLine,
                          selectedDetail:
                              catalog.backgrounds[i].featureSummaryLine,
                          selected:
                              _selectedBackgroundId ==
                              catalog.backgrounds[i].id,
                          leading: AccentIconBadge(
                            index: i,
                            icon: Icons.menu_book,
                          ),
                          onTap: () =>
                              _selectBackground(catalog.backgrounds[i].id),
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
/// [BackgroundStepScreen]).
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
                          '3. Historique',
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
  const _MinimalHeader({required this.onBack});

  final VoidCallback onBack;

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
