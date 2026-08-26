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
import 'providers/character_creation_draft_provider.dart';
import 'providers/character_creation_providers.dart';

/// Étape 2/9 de l'assistant de création de personnage : choix de la classe
/// (`docs/cahier-des-charges/04-fonctionnalites-app-mobile.md` section 3
/// point 2, maquette `03_étape_2_classe.png`).
///
/// Plus simple que l'étape 1 "Race" : ni sous-classe (ne s'y ajoute pas à
/// cette étape, décision du chef de projet), ni "classe personnalisée" —
/// "Suivant" s'active dès qu'une classe est choisie.
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
    // change : `classId` est `null`.
    _selectedClassId = ref
        .read(characterCreationDraftControllerProvider)
        .classId;
  }

  void _selectClass(int classId) {
    setState(() {
      _selectedClassId = classId;
    });
  }

  /// Toujours poussée depuis `/characters/new` (étape 1 "Race") via
  /// `context.push` : `pop()` suffit, pas besoin du repli `context.go('/')`
  /// de `RaceStepScreen._goToCharacterList` (qui, lui, peut être la première
  /// route de la pile).
  void _goBack() => context.pop();

  /// Met à jour le brouillon en mémoire et passe à l'étape suivante — aucun
  /// appel réseau ici, même rationale que `RaceStepScreen._submit`.
  void _submit() {
    ref
        .read(characterCreationDraftControllerProvider.notifier)
        .setClass(classId: _selectedClassId!);
    context.push('/characters/new/step-3');
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(classCatalogProvider);

    return Scaffold(
      body: Column(
        children: [
          _Header(onBack: _goBack),
          Expanded(
            child: catalogAsync.when(
              data: _buildContent,
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.goldEnd),
              ),
              error: (error, stackTrace) => _ErrorState(
                message: error is CharacterCreationFailure
                    ? error.message
                    : 'Impossible de charger les classes disponibles. '
                          'Réessayez.',
                onRetry: () => ref.invalidate(classCatalogProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ClassCatalog catalog) {
    final canProceed = _selectedClassId != null;

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
                      '2. Classe',
                      style: AppTypography.body(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Étape 2 / $_totalSteps',
                      style: AppTypography.body(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                const StepProgressBar(totalSteps: _totalSteps, currentStep: 2),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Choisis la voie que ton personnage empruntera.',
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
    );
  }
}

/// Bandeau bois plein en tête d'écran, avec le bouton retour vers l'étape
/// précédente (maquette `03_étape_2_classe.png` : "< CRÉATION").
class _Header extends StatelessWidget {
  const _Header({required this.onBack});

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
