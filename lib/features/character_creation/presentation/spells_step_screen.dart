import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/accent_icon_badge.dart';
import '../../../core/widgets/checkable_option_tile.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/spell_level_tab_selector.dart';
import '../../../core/widgets/step_progress_bar.dart';
import '../domain/character_creation_failure.dart';
import '../domain/spell_option.dart';
import '../domain/spellcasting_rules.dart';
import '../domain/spells_step_selection.dart';
import 'providers/character_creation_draft_provider.dart';
import 'providers/character_creation_providers.dart';

/// Étape 6/9 de l'assistant de création de personnage : sorts
/// (`docs/cahier-des-charges/04-fonctionnalites-app-mobile.md` section 3
/// point 6, maquette réelle vérifiée au pixel près, voir la tâche qui a
/// produit ce fichier pour le rapport de vérification).
///
/// Seule étape de l'assistant réservée aux classes lanceuses de sorts (Barde,
/// Clerc, Druide, Paladin, Rôdeur, Occultiste, Magicien, Ensorceleur — voir
/// `domain/spellcasting_rules.dart`) : `presentation
/// /skills_and_tools_step_screen.dart` saute directement à l'étape 7/9 pour
/// toute autre classe, cette route n'est donc jamais atteinte pour elles.
///
/// Contrairement aux étapes précédentes, l'en-tête bois plein porte lui-même
/// le titre d'étape, la barre de progression ET le nouveau sélecteur
/// d'onglets "Mineurs"/"Niveau 1" (maquette réelle : ces trois éléments sont
/// peints sur le bandeau bois, pas sur le fond parchemin comme aux étapes
/// 1-5) — `_Header` ci-dessous a donc besoin des données déjà résolues
/// (nom de classe, quotas) et n'est construit qu'une fois `dataAsync` chargé,
/// contrairement au `_Header` minimal (retour + "CRÉATION" uniquement) des
/// étapes précédentes, conservé ici pour les états chargement/erreur.
class SpellsStepScreen extends ConsumerStatefulWidget {
  const SpellsStepScreen({super.key});

  @override
  ConsumerState<SpellsStepScreen> createState() => _SpellsStepScreenState();
}

/// Onglet actif de l'étape — mineurs ("cantrips", `SpellOption.level == 0`)
/// ou niveau 1 (`SpellOption.level == 1`).
enum _SpellTab { cantrip, levelOne }

class _SpellsStepScreenState extends ConsumerState<SpellsStepScreen> {
  static const int _totalSteps = 9;

  late List<String> _selectedCantrips;
  late List<String> _selectedLevelOneSpells;

  /// `null` tant qu'aucun onglet par défaut n'a encore été déterminé (les
  /// onglets visibles ne sont connus qu'une fois les données chargées, voir
  /// la documentation de classe) — fixé une seule fois au premier
  /// `_buildContent` plutôt que recalculé à chaque reconstruction, pour ne
  /// jamais écraser un changement d'onglet fait par l'utilisateur (voir
  /// [_buildContent]).
  _SpellTab? _activeTab;

  @override
  void initState() {
    super.initState();
    // Réhydrate la sélection depuis le brouillon déjà en mémoire (retour en
    // arrière depuis une étape suivante) — même rationale que les étapes
    // précédentes.
    final draft = ref.read(characterCreationDraftControllerProvider);
    _selectedCantrips = List.of(draft.classCantripChoices);
    _selectedLevelOneSpells = List.of(draft.classLevelOneSpellChoices);
  }

  void _selectTab(_SpellTab tab) {
    if (tab == _activeTab) return;
    setState(() => _activeTab = tab);
  }

  void _toggleCantrip(String name, int quota) {
    setState(() {
      _selectedCantrips = SpellsStepSelection.toggle(
        current: _selectedCantrips,
        value: name,
        quota: quota,
      );
    });
  }

  void _toggleLevelOneSpell(String name, int quota) {
    setState(() {
      _selectedLevelOneSpells = SpellsStepSelection.toggle(
        current: _selectedLevelOneSpells,
        value: name,
        quota: quota,
      );
    });
  }

  /// Toujours poussée depuis `/characters/new/step-5` (étape 5 "Compétences
  /// et outils") via `context.push` : `pop()` suffit, même rationale que les
  /// étapes précédentes.
  void _goBack() => context.pop();

  /// Met à jour le brouillon en mémoire et passe à l'étape suivante — aucun
  /// appel réseau ici, même rationale que les étapes précédentes.
  void _submit() {
    ref
        .read(characterCreationDraftControllerProvider.notifier)
        .setSpells(
          classCantripChoices: _selectedCantrips,
          classLevelOneSpellChoices: _selectedLevelOneSpells,
        );
    context.push('/characters/new/step-7');
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(spellsStepDataProvider);

    return Scaffold(
      body: dataAsync.when(
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
                    : 'Impossible de charger les sorts disponibles. '
                          'Réessayez.',
                onRetry: () {
                  // Même rationale que `SkillsAndToolsStepScreen._buildContent`
                  // (voir son commentaire) : invalider les providers feuilles
                  // plutôt que le seul combiné `spellsStepDataProvider`, qui
                  // ne rappellerait jamais `fetchClassCatalog`/
                  // `fetchSpellCatalog` si c'est l'un d'eux qui a échoué —
                  // `spellsStepDataProvider` se contenterait de relire la
                  // même instance déjà résolue en erreur de ces providers,
                  // qu'il `watch`e.
                  //
                  // Correction (bug trouvé par qa-testeur, régression
                  // couverte par `spells_step_screen_test.dart`) :
                  // `spellCatalogProvider` est une `family` paramétrée par
                  // `classId` — invalider `classCatalogProvider` seul ne
                  // suffit pas quand c'est `fetchSpellCatalog` qui a échoué,
                  // car `spellsStepDataProvider` reste `watch`-dépendant de
                  // la même instance `spellCatalogProvider(classId: X)`
                  // déjà en erreur. Le `classId` du brouillon (toujours
                  // renseigné : cette étape n'est atteinte qu'après avoir
                  // choisi une classe à l'étape 2/9) suffit à retrouver
                  // cette instance sans dépendre de `SpellsStepData` (jamais
                  // résolu ici, puisqu'on est dans la branche `error`).
                  ref.invalidate(classCatalogProvider);
                  final classId = ref
                      .read(characterCreationDraftControllerProvider)
                      .classId;
                  if (classId != null) {
                    ref.invalidate(spellCatalogProvider(classId: classId));
                  }
                  ref.invalidate(spellsStepDataProvider);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(SpellsStepData data) {
    final className = data.classOption.name;
    final cantripQuota = SpellcastingRules.cantripQuotaFor(className);
    final levelOneQuota = SpellcastingRules.levelOneSpellQuotaFor(className);
    final showCantripTab = cantripQuota > 0;
    final showLevelOneTab = levelOneQuota > 0;

    // Onglet par défaut, déterminé une seule fois (voir la documentation de
    // [_activeTab]) : "Mineurs" s'il est visible, sinon "Niveau 1" (l'un des
    // deux est nécessairement visible pour une classe lanceuse, voir
    // `SpellcastingRules`).
    _activeTab ??= showCantripTab ? _SpellTab.cantrip : _SpellTab.levelOne;
    final activeTab = _activeTab!;

    final cantrips = data.spellCatalog.spells
        .where((spell) => spell.level == 0)
        .toList();
    final levelOneSpells = data.spellCatalog.spells
        .where((spell) => spell.level == 1)
        .toList();

    final canProceed = SpellsStepSelection.canProceed(
      cantripQuota: cantripQuota,
      selectedCantrips: _selectedCantrips,
      levelOneSpellQuota: levelOneQuota,
      selectedLevelOneSpells: _selectedLevelOneSpells,
    );

    return Column(
      children: [
        _Header(
          onBack: _goBack,
          currentStep: 6,
          totalSteps: _totalSteps,
          showCantripTab: showCantripTab,
          showLevelOneTab: showLevelOneTab,
          activeTab: activeTab,
          onTabChanged: _selectTab,
        ),
        Expanded(
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    children: activeTab == _SpellTab.cantrip
                        ? _spellSection(
                            title: 'SORTS MINEURS CONNUS',
                            quota: cantripQuota,
                            selected: _selectedCantrips,
                            candidates: cantrips,
                            onToggle: _toggleCantrip,
                          )
                        : _spellSection(
                            title: 'SORTS DE NIVEAU 1 CONNUS',
                            quota: levelOneQuota,
                            selected: _selectedLevelOneSpells,
                            candidates: levelOneSpells,
                            onToggle: _toggleLevelOneSpell,
                          ),
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

  /// Contenu de l'onglet actif : titre de section + badge de quota, puis un
  /// [_SpellTile] par sort candidat, trié alphabétiquement (déjà fait par
  /// `SupabaseCharacterCreationRepository.fetchSpellCatalog`).
  List<Widget> _spellSection({
    required String title,
    required int quota,
    required List<String> selected,
    required List<SpellOption> candidates,
    required void Function(String name, int quota) onToggle,
  }) {
    return [
      _SectionHeader(title: title, badge: '${selected.length} / $quota'),
      const SizedBox(height: AppSpacing.sm),
      for (var i = 0; i < candidates.length; i++) ...[
        if (i > 0) const SizedBox(height: AppSpacing.xs),
        _spellTile(
          candidates[i],
          index: i,
          selected: selected,
          quota: quota,
          onToggle: onToggle,
        ),
      ],
    ];
  }

  Widget _spellTile(
    SpellOption spell, {
    required int index,
    required List<String> selected,
    required int quota,
    required void Function(String name, int quota) onToggle,
  }) {
    final isSelected = selected.contains(spell.name);
    return CheckableOptionTile(
      title: spell.name,
      subtitle: spell.metaLine,
      leading: AccentIconBadge(index: index, icon: Icons.auto_awesome),
      checked: isSelected,
      enabled: !SpellsStepSelection.isChoiceLocked(
        isSelected: isSelected,
        selectedCount: selected.length,
        quota: quota,
      ),
      onTap: () => onToggle(spell.name, quota),
    );
  }
}

/// Titre de section ("SORTS MINEURS CONNUS"...) avec un badge de quota à
/// droite ("3 / 4", maquette réelle) — même pattern que `_SectionHeader` de
/// `skills_and_tools_step_screen.dart` (étape 5/9), dupliqué ici plutôt que
/// partagé pour ne pas coupler les deux étapes (même rationale que
/// `SpellRowMapper` dupliqué depuis `ToolRowMapper`). Format du badge
/// volontairement différent ("3 / 4", sans le suffixe "choisies" de l'étape
/// 5) : la maquette réelle de cette étape ne porte pas ce suffixe.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.badge});

  final String title;
  final String badge;

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
        _QuotaBadge(text: badge),
      ],
    );
  }
}

/// Badge "X / Y" à droite d'un [_SectionHeader] — même pattern que
/// `_QuotaBadge` de `skills_and_tools_step_screen.dart`, dupliqué ici (voir
/// la documentation de [_SectionHeader]).
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

/// Bandeau bois plein en tête d'écran, portant le retour, le titre d'étape,
/// la barre de progression ET le sélecteur d'onglets "Mineurs"/"Niveau 1" —
/// voir la documentation de classe de [SpellsStepScreen] pour le rationale
/// de cette différence avec les étapes précédentes.
///
/// N'affiche [SpellLevelTabSelector] que si les DEUX onglets sont visibles
/// ([showCantripTab] ET [showLevelOneTab]) : avec un seul onglet visible
/// (Paladin/Rôdeur, sans cantrip), il n'y a rien à basculer — décision
/// documentée sur la consigne d'origine ("pas de sélecteur à un seul choix")
/// plutôt que d'afficher une pilule unique désactivée, pour ne pas laisser un
/// élément d'apparence interactive qui ne ferait jamais rien au tap.
class _Header extends StatelessWidget {
  const _Header({
    required this.onBack,
    required this.currentStep,
    required this.totalSteps,
    required this.showCantripTab,
    required this.showLevelOneTab,
    required this.activeTab,
    required this.onTabChanged,
  });

  final VoidCallback onBack;
  final int currentStep;
  final int totalSteps;
  final bool showCantripTab;
  final bool showLevelOneTab;
  final _SpellTab activeTab;
  final ValueChanged<_SpellTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final showTabSelector = showCantripTab && showLevelOneTab;

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
                          '6. Sorts',
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
                    if (showTabSelector) ...[
                      const SizedBox(height: AppSpacing.sm),
                      SpellLevelTabSelector<_SpellTab>(
                        options: const [
                          SpellLevelTabOption(
                            value: _SpellTab.cantrip,
                            label: 'Mineurs',
                          ),
                          SpellLevelTabOption(
                            value: _SpellTab.levelOne,
                            label: 'Niveau 1',
                          ),
                        ],
                        value: activeTab,
                        onChanged: onTabChanged,
                      ),
                    ],
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
/// chargement/l'erreur — avant que la classe et ses quotas ne soient connus,
/// impossible d'afficher le titre/la barre de progression/les onglets sur le
/// bandeau (voir la documentation de classe de [SpellsStepScreen]).
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
