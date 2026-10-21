import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/accent_icon_badge.dart';
import '../../../core/widgets/checkable_option_tile.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/selectable_option_tile.dart';
import '../../../core/widgets/step_progress_bar.dart';
import '../../characters/domain/level_up_choice_options.dart';
import '../domain/character_creation_failure.dart';
import '../domain/class_choice_rules.dart';
import '../domain/class_option.dart';
import '../domain/creation_step_help.dart';
import '../domain/expertise_step_selection.dart';
import '../domain/skill_ability_mapping.dart';
import '../domain/skill_proficiency_resolver.dart';
import 'providers/character_creation_draft_provider.dart';
import 'providers/character_creation_providers.dart';
import 'providers/character_edit_session_provider.dart';
import 'widgets/abandon_creation_flow.dart';
import 'widgets/creation_mode_title.dart';
import 'widgets/draft_autosave_footer.dart';
import 'widgets/step_help_sheet.dart';

/// Second écran de l'étape 2/9 "Classe" (Guerrier/Rôdeur) OU second écran de
/// l'étape 5/9 "Compétences et outils" (Roublard) de l'assistant de
/// création — correctif D99 (`docs/dette-technique.md`) : un personnage créé
/// directement dans une classe de départ avec un choix de niveau 1 ne se le
/// voyait jamais proposer à la création, seul le multiclassage tardif via
/// l'écran de montée de niveau le proposait.
///
/// Un seul écran paramétrable par [ClassChoiceKind] (déterminé depuis
/// `draft.classId` via `ClassChoiceRules.kindFor`, ou directement
/// [ClassChoiceKind.expertise] pour le Roublard — voir sa doc de classe pour
/// le rationale de ce cas particulier), pas 3 fichiers séparés, réutilisé aux
/// deux points d'insertion :
/// - Guerrier/Rôdeur : poussé par `ClassStepScreen._submit`, juste après le
///   choix de classe — AVANT la logique "sous-classe concernée ?" (ces 2
///   classes ne sont jamais concernées par un choix de sous-classe au
///   niveau 1, donc pas de conflit d'ordre). "Suivant" pousse directement
///   l'étape 3/9 "Historique".
/// - Roublard : poussé par `SkillsAndToolsStepScreen._submit`, APRÈS la
///   résolution des choix de compétences de cette étape (les compétences
///   candidates à l'Expertise n'existent pas encore avant). Le Roublard
///   n'étant RAW lanceur de sorts à aucun niveau
///   (`SpellcastingRules.isSpellcastingClass`), "Suivant" pousse toujours
///   directement l'étape 7/9 "Équipement" (création) ou 8/9 "Apparence"
///   (mode modification, étape Équipement toujours sautée) — jamais
///   l'étape 6/9 "Sorts", sans recalculer `spellsStepApplies` ici.
///
/// Même registre visuel que `ClassStepScreen`/`SubclassStepScreen` (bandeau
/// bois + corps parchemin), PAS le registre "scène intégrale" de
/// `LevelUpScreen` — ces deux écrans de montée de niveau et de création
/// restent volontairement découplés (voir leur documentation de classe
/// respective). `currentStep: 2` ne compte pas comme une étape à part
/// entière des 9 (même principe que `SubclassStepScreen`).
///
/// `_MinimalHeader`/en-tête dupliqués localement plutôt que factorisés —
/// même rationale que le reste de ce module.
class ClassChoiceStepScreen extends ConsumerStatefulWidget {
  const ClassChoiceStepScreen({super.key});

  @override
  ConsumerState<ClassChoiceStepScreen> createState() =>
      _ClassChoiceStepScreenState();
}

class _ClassChoiceStepScreenState extends ConsumerState<ClassChoiceStepScreen> {
  int? _classId;
  ClassChoiceKind? _kind;

  /// Mode [ClassChoiceKind.fightingStyle]/[ClassChoiceKind.favoredEnemy]
  /// uniquement.
  String? _selectedValue;

  /// Mode [ClassChoiceKind.expertise] uniquement.
  late List<String> _selectedSkillNames;

  bool _announced = false;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(characterCreationDraftControllerProvider);
    _classId = draft.classId;
    final classId = _classId;
    // Le Roublard n'est volontairement pas couvert par
    // `ClassChoiceRules.kindFor`/`.isConcerned` (voir sa doc de classe) :
    // cet écran n'est atteint pour cette classe que depuis
    // `SkillsAndToolsStepScreen`, jamais depuis `ClassStepScreen`, donc pas
    // de conflit à trancher ici.
    _kind = classId == null
        ? null
        : (ClassChoiceRules.kindFor(classId) ??
              (classId == _roublardClassId ? ClassChoiceKind.expertise : null));
    _selectedValue = draft.classFeatureChoiceValue;
    _selectedSkillNames = List.of(draft.expertiseSkillChoices);

    if (classId == null || _kind == null) {
      // Cas défensif (ex. deep-link direct sur cette route) : cet écran
      // n'est censé être atteint que depuis `ClassStepScreen`/
      // `SkillsAndToolsStepScreen`, qui ont déjà écrit `classId` dans le
      // brouillon avant de pousser cette route.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go('/characters/new/step-2');
      });
    }
  }

  /// `classes.id` du Roublard — voir la doc de classe de
  /// `ClassChoiceRules` pour le rationale de ne pas l'y inclure.
  static const int _roublardClassId = 9;

  void _goBack() => context.pop();

  void _announceOnce(String text) {
    if (_announced) return;
    _announced = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SemanticsService.sendAnnouncement(
        View.of(context),
        text,
        TextDirection.ltr,
      );
    });
  }

  void _submit() {
    final notifier = ref.read(
      characterCreationDraftControllerProvider.notifier,
    );
    if (_kind == ClassChoiceKind.expertise) {
      // Jamais de substitution outils de voleur à ce stade (niveau 1,
      // création) — correctif D100, voir `domain/expertise_step_selection.dart`.
      notifier.setExpertiseChoices(
        skillNames: _selectedSkillNames,
        thievesToolsSubstitution: false,
      );
      final editSession = ref.read(characterEditSessionControllerProvider);
      // Roublard non lanceur de sorts à aucun niveau : jamais l'étape 6/9,
      // même route que `SkillsAndToolsStepScreen._submit` choisirait pour
      // cette classe (voir la doc de classe).
      context.push(
        editSession != null
            ? '/characters/new/step-8'
            : '/characters/new/step-7',
      );
    } else {
      notifier.setClassFeatureChoice(_selectedValue);
      context.push('/characters/new/step-3');
    }
  }

  @override
  Widget build(BuildContext context) {
    final classId = _classId;
    final kind = _kind;
    if (classId == null || kind == null) {
      // Redirection défensive déjà programmée dans `initState`.
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      body: kind == ClassChoiceKind.expertise
          ? _ExpertiseBody(
              selectedSkillNames: _selectedSkillNames,
              onToggleSkill: (skill, quota) => setState(() {
                _selectedSkillNames = _toggle(
                  current: _selectedSkillNames,
                  value: skill,
                  quota: quota,
                );
              }),
              onGoBack: _goBack,
              onSubmit: _submit,
              onAnnounce: _announceOnce,
            )
          : _NamedChoiceBody(
              classId: classId,
              kind: kind,
              selectedValue: _selectedValue,
              onSelect: (value) => setState(() => _selectedValue = value),
              onGoBack: _goBack,
              onSubmit: _submit,
              onAnnounce: _announceOnce,
            ),
    );
  }

  static List<String> _toggle({
    required List<String> current,
    required String value,
    required int quota,
  }) {
    if (current.contains(value)) {
      return List<String>.from(current)..remove(value);
    }
    if (current.length >= quota) return current;
    return List<String>.from(current)..add(value);
  }
}

/// Corps de l'écran pour [ClassChoiceKind.fightingStyle]/
/// [ClassChoiceKind.favoredEnemy] (choix exclusif, Guerrier/Rôdeur).
class _NamedChoiceBody extends ConsumerWidget {
  const _NamedChoiceBody({
    required this.classId,
    required this.kind,
    required this.selectedValue,
    required this.onSelect,
    required this.onGoBack,
    required this.onSubmit,
    required this.onAnnounce,
  });

  final int classId;
  final ClassChoiceKind kind;
  final String? selectedValue;
  final ValueChanged<String> onSelect;
  final VoidCallback onGoBack;
  final VoidCallback onSubmit;
  final ValueChanged<String> onAnnounce;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(classCatalogProvider);

    return catalogAsync.when(
      data: (catalog) {
        final className = catalog.classes
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
        final options = kind == ClassChoiceKind.fightingStyle
            ? LevelUpChoiceOptions.fightingStyles
            : LevelUpChoiceOptions.favoredEnemies;
        final icon = kind == ClassChoiceKind.fightingStyle
            ? Icons.security
            : Icons.gps_fixed;
        onAnnounce(ClassChoiceRules.announcementFor(kind));
        final canProceed = selectedValue != null;

        return _Scaffold(
          title: ClassChoiceRules.titleFor(kind),
          onGoBack: onGoBack,
          canProceed: canProceed,
          onSubmit: onSubmit,
          onAbandon: () => abandonCharacterCreation(context, ref),
          body: Column(
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
                    if (selectedValue == null) ...[
                      Text(
                        'Choisis une option pour continuer.',
                        style: AppTypography.body(
                          fontSize: 12,
                          color: AppColors.accentBrick,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    for (var i = 0; i < options.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.sm),
                      SelectableOptionTile(
                        title: options[i],
                        selected: selectedValue == options[i],
                        leading: AccentIconBadge(index: i, icon: icon),
                        onTap: () => onSelect(options[i]),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => _Scaffold(
        title: ClassChoiceRules.titleFor(kind),
        onGoBack: onGoBack,
        canProceed: false,
        onSubmit: onSubmit,
        onAbandon: () => abandonCharacterCreation(context, ref),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.woodMedium),
        ),
      ),
      error: (error, stackTrace) => _Scaffold(
        title: ClassChoiceRules.titleFor(kind),
        onGoBack: onGoBack,
        canProceed: false,
        onSubmit: onSubmit,
        onAbandon: () => abandonCharacterCreation(context, ref),
        body: _ErrorState(
          message: error is CharacterCreationFailure
              ? error.message
              : 'Impossible de charger les classes disponibles. Réessayez.',
          onRetry: () => ref.invalidate(classCatalogProvider),
        ),
      ),
    );
  }
}

/// Corps de l'écran pour [ClassChoiceKind.expertise] (choix multiple, quota
/// 2, Roublard).
///
/// Jamais de case "outils de voleur" ici — correctif D100
/// (`docs/dette-technique.md`) : RAW, la substitution de l'Expertise du
/// Roublard par la maîtrise des outils de voleur n'existe qu'au niveau 6, pas
/// au niveau 1. Voir la doc de classe de `ExpertiseStepSelection` pour le
/// rationale complet et la doc de ce fichier pour le futur chantier
/// "Expertise niveau 6" qui réutilisera `thievesToolsSubstitution`.
class _ExpertiseBody extends ConsumerWidget {
  const _ExpertiseBody({
    required this.selectedSkillNames,
    required this.onToggleSkill,
    required this.onGoBack,
    required this.onSubmit,
    required this.onAnnounce,
  });

  final List<String> selectedSkillNames;
  final void Function(String skill, int quota) onToggleSkill;
  final VoidCallback onGoBack;
  final VoidCallback onSubmit;
  final ValueChanged<String> onAnnounce;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(skillsAndToolsStepDataProvider);

    return dataAsync.when(
      data: (data) {
        final classOption = data.classOption;
        final backgroundOption = data.backgroundOption;
        final raceSkillNames = <String>[
          ...ref
              .read(characterCreationDraftControllerProvider)
              .raceSkillChoices,
          ...(data.raceOption?.skillProficiencies ?? const <String>[]),
        ];
        final candidateSkillNames = SkillProficiencyResolver.resolveNames(
          classSkillNames: ref
              .read(characterCreationDraftControllerProvider)
              .classSkillChoices,
          backgroundSkillNames: backgroundOption.skillProficiencies,
          raceSkillNames: raceSkillNames,
        );
        // Aucune substitution outils de voleur à ce stade (voir la doc de
        // classe) : [availableOptionsCount] ne compte que les compétences
        // candidates.
        final availableOptionsCount = candidateSkillNames.length;
        final effectiveQuota = ExpertiseStepSelection.effectiveQuota(
          availableOptionsCount,
        );
        final skillQuota = ExpertiseStepSelection.skillQuota(
          availableOptionsCount: availableOptionsCount,
          thievesToolsSubstitution: false,
        );
        final canProceed = ExpertiseStepSelection.canProceed(
          availableOptionsCount: availableOptionsCount,
          selectedSkillNames: selectedSkillNames,
          thievesToolsSubstitution: false,
        );
        final selectedCount = ExpertiseStepSelection.selectedCount(
          selectedSkillNames: selectedSkillNames,
          thievesToolsSubstitution: false,
        );

        if (effectiveQuota > 0) {
          onAnnounce(
            ClassChoiceRules.announcementFor(ClassChoiceKind.expertise),
          );
        }

        return _Scaffold(
          title: ClassChoiceRules.titleFor(ClassChoiceKind.expertise),
          onGoBack: onGoBack,
          canProceed: canProceed,
          onSubmit: onSubmit,
          onAbandon: () => abandonCharacterCreation(context, ref),
          body: Column(
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
                    'Ce choix se fait dès le niveau 1 pour ${classOption.name}.',
                    style: AppTypography.body(fontSize: 14),
                  ),
                ),
              ),
              Expanded(
                child: effectiveQuota <= 0
                    ? Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          "Aucune option n'est disponible pour ce choix. Tu "
                          'peux continuer sans en faire.',
                          style: AppTypography.body(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.md,
                          AppSpacing.lg,
                          AppSpacing.md,
                        ),
                        children: [
                          _SectionHeader(
                            title: 'COMPÉTENCES MAÎTRISÉES',
                            badge: '$selectedCount / $effectiveQuota choisies',
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          for (
                            var i = 0;
                            i < candidateSkillNames.length;
                            i++
                          ) ...[
                            if (i > 0) const SizedBox(height: AppSpacing.xs),
                            _skillTile(candidateSkillNames[i], skillQuota),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        );
      },
      loading: () => _Scaffold(
        title: ClassChoiceRules.titleFor(ClassChoiceKind.expertise),
        onGoBack: onGoBack,
        canProceed: false,
        onSubmit: onSubmit,
        onAbandon: () => abandonCharacterCreation(context, ref),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.woodMedium),
        ),
      ),
      error: (error, stackTrace) => _Scaffold(
        title: ClassChoiceRules.titleFor(ClassChoiceKind.expertise),
        onGoBack: onGoBack,
        canProceed: false,
        onSubmit: onSubmit,
        onAbandon: () => abandonCharacterCreation(context, ref),
        body: _ErrorState(
          message: error is CharacterCreationFailure
              ? error.message
              : 'Impossible de charger les compétences disponibles. '
                    'Réessayez.',
          onRetry: () => ref.invalidate(skillsAndToolsStepDataProvider),
        ),
      ),
    );
  }

  Widget _skillTile(String skill, int quota) {
    final isSelected = selectedSkillNames.contains(skill);
    return CheckableOptionTile(
      title: skill,
      trailingLabel: SkillAbilityMapping.abbreviationFor(skill),
      checked: isSelected,
      enabled: isSelected || selectedSkillNames.length < quota,
      onTap: () => onToggleSkill(skill, quota),
    );
  }
}

/// Titre de section avec un badge de quota — copié depuis
/// `skills_and_tools_step_screen.dart::_SectionHeader`/`_QuotaBadge` (voir
/// la doc de classe de [ClassChoiceStepScreen] pour le rationale de cette
/// duplication).
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.badge});

  final String title;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTypography.body(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
          ),
        ),
        if (badge != null) _QuotaBadge(text: badge!),
      ],
    );
  }
}

class _QuotaBadge extends StatelessWidget {
  const _QuotaBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.parchmentCardAlt,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.woodLight, width: 1),
      ),
      child: Text(
        text,
        style: AppTypography.body(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Carcasse commune (bandeau bois + corps parchemin + pied de page) des deux
/// modes de cet écran — factorisée ICI (contrairement au reste de ce
/// module, qui duplique plutôt ses en-têtes) car les deux corps
/// ([_NamedChoiceBody]/[_ExpertiseBody]) sont déjà deux classes séparées du
/// même fichier, pas deux écrans/fichiers distincts : pas le même risque de
/// couplage inter-étapes que `ClassStepScreen`/`SubclassStepScreen`.
class _Scaffold extends StatelessWidget {
  const _Scaffold({
    required this.title,
    required this.onGoBack,
    required this.canProceed,
    required this.onSubmit,
    required this.onAbandon,
    required this.body,
  });

  final String title;
  final VoidCallback onGoBack;
  final bool canProceed;
  final VoidCallback onSubmit;
  final VoidCallback onAbandon;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Header(
          onBack: onGoBack,
          title: title,
          currentStep: 2,
          totalSteps: 9,
          onHelp: () => showStepHelpSheet(
            context,
            title == ClassChoiceRules.titleFor(ClassChoiceKind.expertise)
                ? CreationStepHelp.skillsAndTools
                : CreationStepHelp.classStep,
          ),
        ),
        Expanded(
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(child: body),
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
                              onPressed: onGoBack,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: PrimaryButton(
                              label: 'Suivant',
                              onPressed: canProceed ? onSubmit : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      DraftAutosaveFooter(onAbandon: onAbandon),
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

/// Bandeau bois plein en tête d'écran — copié depuis
/// `subclass_step_screen.dart::_Header` (voir la doc de classe de
/// [ClassChoiceStepScreen] pour le rationale), [title] dynamique selon le
/// mode (`"2. Style de combat"`/`"2. Ennemi juré"`/`"2. Expertise"`).
class _Header extends StatelessWidget {
  const _Header({
    required this.onBack,
    required this.title,
    required this.currentStep,
    required this.totalSteps,
    required this.onHelp,
  });

  final VoidCallback onBack;
  final String title;
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
                          '2. $title',
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
