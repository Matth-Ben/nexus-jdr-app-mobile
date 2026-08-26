import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/checkable_option_tile.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/step_progress_bar.dart';
import '../domain/background_option.dart';
import '../domain/character_creation_failure.dart';
import '../domain/class_option.dart';
import '../domain/skill_ability_mapping.dart';
import '../domain/skills_and_tools_step_selection.dart';
import '../domain/spellcasting_rules.dart';
import 'providers/character_creation_draft_provider.dart';
import 'providers/character_creation_providers.dart';

/// Étape 5/9 de l'assistant de création de personnage : compétences et
/// outils (`docs/cahier-des-charges/04-fonctionnalites-app-mobile.md`
/// section 3 point 5, maquette `06_étape_5_compétences_et_outils.png`).
///
/// L'étape la plus hétérogène de l'assistant jusqu'ici : jusqu'à 4 sections,
/// chacune affichée seulement si applicable selon la classe/l'historique
/// déjà choisis (étapes 2 et 3) — voir `domain
/// /skills_and_tools_step_selection.dart` pour le détail des règles de
/// visibilité/activation, volontairement extraites de ce fichier pour
/// rester testables sans widget.
///
/// En-tête bois plein dupliqué depuis `ability_score_step_screen.dart`
/// (`_Header` ci-dessous) — même principe que les étapes précédentes, pour
/// ne pas coupler les étapes entre elles.
class SkillsAndToolsStepScreen extends ConsumerStatefulWidget {
  const SkillsAndToolsStepScreen({super.key});

  @override
  ConsumerState<SkillsAndToolsStepScreen> createState() =>
      _SkillsAndToolsStepScreenState();
}

class _SkillsAndToolsStepScreenState
    extends ConsumerState<SkillsAndToolsStepScreen> {
  static const int _totalSteps = 9;

  late List<String> _selectedClassSkills;
  late List<String> _selectedClassTools;
  late List<String> _selectedBackgroundLanguages;

  @override
  void initState() {
    super.initState();
    // Réhydrate la sélection depuis le brouillon déjà en mémoire (retour en
    // arrière depuis une étape suivante) — même rationale que les étapes
    // précédentes. Copies défensives (`List.of`) : `setState` reconstruit
    // toujours une nouvelle liste (voir `SkillsAndToolsStepSelection.toggle`),
    // jamais de mutation en place de la liste du brouillon.
    final draft = ref.read(characterCreationDraftControllerProvider);
    _selectedClassSkills = List.of(draft.classSkillChoices);
    _selectedClassTools = List.of(draft.classToolChoices);
    _selectedBackgroundLanguages = List.of(draft.backgroundLanguageChoices);
  }

  void _toggleClassSkill(String skill, int quota) {
    setState(() {
      _selectedClassSkills = SkillsAndToolsStepSelection.toggle(
        current: _selectedClassSkills,
        value: skill,
        quota: quota,
      );
    });
  }

  void _toggleClassTool(String tool, int quota) {
    setState(() {
      _selectedClassTools = SkillsAndToolsStepSelection.toggle(
        current: _selectedClassTools,
        value: tool,
        quota: quota,
      );
    });
  }

  void _toggleBackgroundLanguage(String language, int quota) {
    setState(() {
      _selectedBackgroundLanguages = SkillsAndToolsStepSelection.toggle(
        current: _selectedBackgroundLanguages,
        value: language,
        quota: quota,
      );
    });
  }

  /// Toujours poussée depuis `/characters/new/step-4` (étape 4
  /// "Caractéristiques") via `context.push` : `pop()` suffit, même
  /// rationale que les étapes précédentes.
  void _goBack() => context.pop();

  /// Met à jour le brouillon en mémoire et passe à l'étape suivante — aucun
  /// appel réseau ici, même rationale que les étapes précédentes.
  ///
  /// [classOption] détermine la route suivante : l'étape 6/9 "Sorts" est
  /// sautée directement vers l'étape 7/9 "Équipement" si la classe n'est pas
  /// lanceuse de sorts (`SpellcastingRules.isSpellcastingClass`, voir
  /// `domain/spellcasting_rules.dart`) — cette étape n'aurait alors rien à
  /// afficher (aucune ligne `spell_classes` pour cette classe). Le chemin
  /// retour depuis l'étape 7/9 revient alors automatiquement à cette étape 5
  /// (pas à une étape 6 vide) : la pile de navigation `go_router`
  /// (`context.push` à chaque étape) n'a jamais empilé l'étape 6 pour ce
  /// personnage, donc `pop()` depuis l'étape 7 atterrit directement ici, sans
  /// logique supplémentaire à écrire côté étape 7.
  void _submit(ClassOption classOption) {
    ref
        .read(characterCreationDraftControllerProvider.notifier)
        .setSkillsAndTools(
          classSkillChoices: _selectedClassSkills,
          classToolChoices: _selectedClassTools,
          backgroundLanguageChoices: _selectedBackgroundLanguages,
        );
    final nextStepRoute =
        SpellcastingRules.isSpellcastingClass(classOption.name)
        ? '/characters/new/step-6'
        : '/characters/new/step-7';
    context.push(nextStepRoute);
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(skillsAndToolsStepDataProvider);

    return Scaffold(
      body: Column(
        children: [
          _Header(onBack: _goBack),
          Expanded(
            child: dataAsync.when(
              data: _buildContent,
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.goldEnd),
              ),
              error: (error, stackTrace) => _ErrorState(
                message: error is CharacterCreationFailure
                    ? error.message
                    : 'Impossible de charger les compétences et outils '
                          'disponibles. Réessayez.',
                // Invalide les 4 providers *feuilles* plutôt que le seul
                // `skillsAndToolsStepDataProvider` : bug corrigé en écrivant
                // les tests de cet écran (reproduit isolément avec un
                // ProviderContainer avant correction) — invalider seulement
                // le provider combiné ne force PAS un nouvel appel réseau
                // sur celui des 4 catalogues qui a échoué, puisque ce
                // catalogue reste caché dans son état d'erreur (retry
                // automatique désactivé via `_noRetry`, voir
                // `providers/character_creation_providers.dart`) : le
                // combiné se contente de relire ce même Future déjà résolu
                // en erreur, sans jamais rappeler
                // `fetchClassCatalog`/`fetchBackgroundCatalog`/
                // `fetchToolCatalog`/`fetchLanguageCatalog`. Invalider les
                // feuilles fonctionne : Riverpod recalcule alors bien tout
                // provider qui les regarde (`ref.watch`), y compris ce
                // provider combiné.
                onRetry: () {
                  ref.invalidate(classCatalogProvider);
                  ref.invalidate(backgroundCatalogProvider);
                  ref.invalidate(toolCatalogProvider);
                  ref.invalidate(languageCatalogProvider);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(SkillsAndToolsStepData data) {
    final classOption = data.classOption;
    final backgroundOption = data.backgroundOption;

    final showClassTools =
        SkillsAndToolsStepSelection.isClassToolSectionVisible(classOption);
    final showBackgroundTools =
        SkillsAndToolsStepSelection.isBackgroundToolSectionVisible(
          backgroundOption,
        );
    final showLanguages = SkillsAndToolsStepSelection.isLanguageSectionVisible(
      backgroundOption,
    );

    final canProceed = SkillsAndToolsStepSelection.canProceed(
      classOption: classOption,
      backgroundOption: backgroundOption,
      selectedClassSkills: _selectedClassSkills,
      selectedClassTools: _selectedClassTools,
      selectedBackgroundLanguages: _selectedBackgroundLanguages,
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
                      '5. Compétences',
                      style: AppTypography.body(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Étape 5 / $_totalSteps',
                      style: AppTypography.body(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                const StepProgressBar(totalSteps: _totalSteps, currentStep: 5),
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
                // Section 1 : "COMPÉTENCES DE CLASSE" — toujours affichée.
                _SectionHeader(
                  title: 'COMPÉTENCES DE CLASSE',
                  badge:
                      '${_selectedClassSkills.length} / '
                      '${classOption.skillChoices.count} choisies',
                ),
                const SizedBox(height: AppSpacing.sm),
                for (
                  var i = 0;
                  i < classOption.skillChoices.choices.length;
                  i++
                ) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.xs),
                  _skillTile(
                    classOption.skillChoices.choices[i],
                    classOption.skillChoices.count,
                  ),
                ],

                // Section 2 : "OUTILS (CLASSE)" — si applicable.
                if (showClassTools) ...[
                  const SizedBox(height: AppSpacing.md),
                  ..._classToolSection(classOption, data),
                ],

                // Section 3 : "OUTILS (HISTORIQUE)" — si applicable, jamais
                // interactive.
                if (showBackgroundTools) ...[
                  const SizedBox(height: AppSpacing.md),
                  const _SectionHeader(title: 'OUTILS (HISTORIQUE)'),
                  const SizedBox(height: AppSpacing.sm),
                  for (
                    var i = 0;
                    i < backgroundOption.toolOrLanguageGrantedTools.length;
                    i++
                  ) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.xs),
                    CheckableOptionTile(
                      title: backgroundOption.toolOrLanguageGrantedTools[i],
                      checked: true,
                      enabled: false,
                    ),
                  ],
                ],

                // Section 4 : "LANGUES (HISTORIQUE)" — si applicable.
                if (showLanguages) ...[
                  const SizedBox(height: AppSpacing.md),
                  ..._languageSection(backgroundOption, data),
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
                    onPressed: canProceed ? () => _submit(classOption) : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _skillTile(String skill, int quota) {
    final isSelected = _selectedClassSkills.contains(skill);
    return CheckableOptionTile(
      title: skill,
      trailingLabel: SkillAbilityMapping.abbreviationFor(skill),
      checked: isSelected,
      enabled: !SkillsAndToolsStepSelection.isChoiceLocked(
        isSelected: isSelected,
        selectedCount: _selectedClassSkills.length,
        quota: quota,
      ),
      onTap: () => _toggleClassSkill(skill, quota),
    );
  }

  /// Section 2 "OUTILS (CLASSE)" : soit un vrai choix interactif
  /// (`classOption.toolChoice` non `null`, candidats filtrés par catégorie
  /// dans `data.toolCatalog`), soit un octroi automatique non interactif
  /// (`classOption.grantedToolNames`) — voir le commentaire de classe de
  /// `ClassOption` pour le rationale des deux formes partageant la même
  /// section. Les deux sont mutuellement exclusives (voir
  /// `ClassRowMapper.parseToolChoice`/`parseGrantedToolNames`).
  List<Widget> _classToolSection(
    ClassOption classOption,
    SkillsAndToolsStepData data,
  ) {
    final toolChoice = classOption.toolChoice;
    if (toolChoice != null) {
      final candidates = data.toolCatalog.tools
          .where((tool) => toolChoice.categories.contains(tool.category))
          .map((tool) => tool.name)
          .toList();
      return [
        _SectionHeader(
          title: 'OUTILS (CLASSE)',
          badge: '${_selectedClassTools.length} / ${toolChoice.count} choisies',
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < candidates.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.xs),
          _toolTile(candidates[i], toolChoice.count),
        ],
      ];
    }

    return [
      const _SectionHeader(title: 'OUTILS (CLASSE)'),
      const SizedBox(height: AppSpacing.sm),
      for (var i = 0; i < classOption.grantedToolNames.length; i++) ...[
        if (i > 0) const SizedBox(height: AppSpacing.xs),
        CheckableOptionTile(
          title: classOption.grantedToolNames[i],
          checked: true,
          enabled: false,
        ),
      ],
    ];
  }

  Widget _toolTile(String tool, int quota) {
    final isSelected = _selectedClassTools.contains(tool);
    return CheckableOptionTile(
      title: tool,
      checked: isSelected,
      enabled: !SkillsAndToolsStepSelection.isChoiceLocked(
        isSelected: isSelected,
        selectedCount: _selectedClassTools.length,
        quota: quota,
      ),
      onTap: () => _toggleClassTool(tool, quota),
    );
  }

  List<Widget> _languageSection(
    BackgroundOption backgroundOption,
    SkillsAndToolsStepData data,
  ) {
    final quota = backgroundOption.languageChoiceCount ?? 0;
    final candidates = data.languageCatalog.languages
        .map((language) => language.name)
        .toList();
    return [
      _SectionHeader(
        title: 'LANGUES (HISTORIQUE)',
        badge: '${_selectedBackgroundLanguages.length} / $quota choisies',
      ),
      const SizedBox(height: AppSpacing.sm),
      for (var i = 0; i < candidates.length; i++) ...[
        if (i > 0) const SizedBox(height: AppSpacing.xs),
        _languageTile(candidates[i], quota),
      ],
    ];
  }

  Widget _languageTile(String language, int quota) {
    final isSelected = _selectedBackgroundLanguages.contains(language);
    return CheckableOptionTile(
      title: language,
      checked: isSelected,
      enabled: !SkillsAndToolsStepSelection.isChoiceLocked(
        isSelected: isSelected,
        selectedCount: _selectedBackgroundLanguages.length,
        quota: quota,
      ),
      onTap: () => _toggleBackgroundLanguage(language, quota),
    );
  }
}

/// Titre de section ("COMPÉTENCES DE CLASSE"...) avec un badge de quota
/// optionnel à droite ("2 / 2 choisies", maquette
/// `06_étape_5_compétences_et_outils.png`).
///
/// `font.body` en semi-gras plutôt que `font.display` : ce n'est ni un titre
/// d'écran, ni un titre de carte, ni un libellé de bouton/navigation (les
/// seuls usages prescrits pour `font.display`,
/// `docs/cahier-des-charges/10-design-system.md` section 2) — c'est un
/// sous-titre de section à l'intérieur d'un écran, choix technique du
/// sous-agent `dev-flutter` à valider par l'agent `direction-artistique`.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.badge});

  final String title;

  /// `null` pour les sections sans quota (octroi automatique, ex. "OUTILS
  /// (HISTORIQUE)").
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

/// Badge "X / Y choisies" à droite d'un [_SectionHeader], fond clair et
/// bordure fine (maquette `06_étape_5_compétences_et_outils.png`).
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

/// Bandeau bois plein en tête d'écran, avec le bouton retour vers l'étape
/// précédente (maquette `06_étape_5_compétences_et_outils.png` :
/// "< CRÉATION").
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
