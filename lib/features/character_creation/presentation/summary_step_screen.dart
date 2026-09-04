import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../../core/widgets/portrait_frame.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/step_progress_bar.dart';
import '../../characters/presentation/providers/character_providers.dart';
import '../domain/ability_score_definitions.dart';
import '../domain/character_creation_draft.dart';
import '../domain/character_creation_failure.dart';
import '../domain/equipment_choice_tab.dart';
import '../domain/final_ability_scores_resolver.dart';
import '../domain/spellcasting_rules.dart';
import 'providers/character_creation_draft_provider.dart';
import 'providers/character_creation_providers.dart';
import 'providers/character_creation_return_route_provider.dart';

/// Étape 9/9 de l'assistant de création de personnage : récapitulatif
/// (`docs/cahier-des-charges/04-fonctionnalites-app-mobile.md` section 3
/// point 9, spec visuelle validée par l'agent `direction-artistique`).
///
/// Dernière étape, et la seule de tout l'assistant qui écrit réellement en
/// base : "Créer le personnage" déclenche
/// `CharacterCreationRepository.createCharacter` (voir sa documentation pour
/// le détail de la séquence d'écriture et du compromis assumé en cas
/// d'échec partiel), toutes les étapes précédentes se contentant de mettre à
/// jour le brouillon en mémoire (`CharacterCreationDraftController`).
///
/// Capture aussi le seul champ de tout l'assistant qu'aucune étape 1-8 ne
/// capture : le nom du personnage (`CharacterCreationDraft.characterName`,
/// gap identifié et validé avec l'utilisateur). `characters.name` est `not
/// null default ''` en base (un nom vide passerait donc techniquement), mais
/// "Créer le personnage" reste désactivé tant que le nom (trim) est vide —
/// décision produit tranchée, un personnage sans nom serait une régression
/// visible immédiatement dans `CharacterListScreen`/`CharacterCard`.
///
/// En-tête bois plein portant le titre d'étape et la barre de progression,
/// copié depuis `equipment_step_screen.dart`/
/// `appearance_and_backstory_step_screen.dart` (étapes 7/8) — pas l'ancien
/// pattern de `background_step_screen.dart` (étape 3, dette déjà signalée
/// séparément).
///
/// Navigation d'édition (icône crayon d'une ligne de résumé) : implémentée en
/// dépilant (`context.pop()`) le nombre exact d'écrans séparant cette étape
/// de l'étape cible, plutôt que `context.go` (remplacerait toute la pile de
/// navigation par une pile à un seul écran, cassant le bouton "Retour" de
/// l'étape cible — vérifié dans les sources de `go_router` : `go()` restaure
/// une toute nouvelle `RouteMatchList` ne contenant que la destination) ou un
/// `popUntil` par prédicat sur le nom de route (fragile : `go_router` ne
/// garantit pas un `Route.settings.name` stable exploitable ici) — choix
/// technique signalé au chef de projet plutôt qu'une des deux mécaniques
/// suggérées à l'origine.
///
/// **Piège déjà corrigé une fois** (régression relevée par `qa-testeur`) :
/// l'étape 6/9 "Sorts" est absente de la pile pour une classe non lanceuse de
/// sorts (`SkillsAndToolsStepScreen._submit` la saute, poussant directement
/// l'étape 7/9) — la pile ne contient alors que 8 écrans au lieu de 9. Le
/// simple calcul `_totalSteps - stepNumber` suppose à tort que les 9 étapes
/// sont toujours présentes : il dépile une fois de trop pour toute étape
/// cible **avant** l'étape 6 absente (4 "Caractéristiques" et 5 "Compétences"
/// /"Outils"/"Langues"), même si aucune ligne ne cible jamais l'étape 6
/// elle-même pour une telle classe (les lignes "Sorts mineurs"/"Sorts niveau
/// 1" sont masquées, voir [_SummaryStepScreenState._buildContent]) — ce
/// masquage ne suffisait donc pas à rendre le calcul correct pour les
/// étapes situées *avant* le trou. Voir [_SummaryStepScreenState._editStep].
class SummaryStepScreen extends ConsumerStatefulWidget {
  const SummaryStepScreen({super.key});

  @override
  ConsumerState<SummaryStepScreen> createState() => _SummaryStepScreenState();
}

class _SummaryStepScreenState extends ConsumerState<SummaryStepScreen> {
  static const int _totalSteps = 9;

  late final TextEditingController _nameController;

  /// Dernier [SummaryStepData] reçu par [_buildContent], conservé pour que
  /// [_submit] (déclenché par un tap utilisateur, pas par une reconstruction
  /// de `build`) ait accès aux catalogues déjà chargés sans les regarder une
  /// seconde fois — même donnée que celle déjà affichée à l'écran au moment
  /// du tap.
  SummaryStepData? _data;

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Réhydrate le nom depuis le brouillon déjà en mémoire (retour en
    // arrière depuis une navigation d'édition) — `ref.read` (pas
    // `ref.watch`) : même rationale que les étapes précédentes.
    final draft = ref.read(characterCreationDraftControllerProvider);
    _nameController = TextEditingController(text: draft.characterName ?? '')
      ..addListener(_handleNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_handleNameChanged);
    _nameController.dispose();
    super.dispose();
  }

  /// Le nom saisi pilote à la fois l'activation de "Créer le personnage" et
  /// l'aperçu affiché dans la carte d'en-tête : un simple `setState` vide sur
  /// chaque frappe suffit à tenir les deux à jour, plutôt qu'un `ValueNotifier`
  /// dédié pour un champ unique sur cet écran.
  void _handleNameChanged() {
    if (mounted) setState(() {});
  }

  /// Commite le nom déjà saisi dans le brouillon avant toute navigation qui
  /// quitte cet écran (retour arrière, édition d'une étape antérieure) :
  /// contrairement aux étapes 1-8, l'étape 9 n'a pas de "Suivant" qui
  /// écrirait ce champ au brouillon avant de naviguer — voir la
  /// documentation de `CharacterCreationDraftController.setCharacterName`.
  void _persistNameToDraft() {
    final trimmed = _nameController.text.trim();
    ref
        .read(characterCreationDraftControllerProvider.notifier)
        .setCharacterName(trimmed.isEmpty ? null : trimmed);
  }

  /// Toujours poussée depuis `/characters/new/step-8` via `context.push` :
  /// `pop()` suffit, même rationale que les étapes précédentes.
  void _goBack() {
    if (_isSubmitting) return;
    _persistNameToDraft();
    context.pop();
  }

  /// Dépile jusqu'à l'étape [stepNumber] — voir la documentation de classe
  /// pour le rationale de cette mécanique plutôt que `context.go`/`popUntil`,
  /// et pour le piège déjà corrigé une fois (étape 6/9 absente de la pile
  /// pour une classe non lanceuse de sorts).
  void _editStep(int stepNumber) {
    if (_isSubmitting) return;
    _persistNameToDraft();

    final className = _data?.classOption.name;
    final isSpellcaster =
        className != null && SpellcastingRules.isSpellcastingClass(className);

    var popsNeeded = _totalSteps - stepNumber;
    // L'étape 6/9 "Sorts" est absente de la pile pour une classe non
    // lanceuse de sorts (voir la documentation de classe) : toute étape
    // cible strictement avant elle (4 ou 5) doit alors franchir un écran de
    // moins pour être atteinte. Ne s'applique jamais à `stepNumber == 6`
    // lui-même : aucune ligne ne le cible pour une telle classe (lignes
    // "Sorts mineurs"/"Sorts niveau 1" masquées, voir [_buildContent]).
    if (!isSpellcaster && stepNumber <= 5) {
      popsNeeded -= 1;
    }

    for (var i = 0; i < popsNeeded; i++) {
      if (!context.canPop()) break;
      context.pop();
    }
  }

  Future<void> _submit() async {
    final data = _data;
    final name = _nameController.text.trim();
    if (data == null || name.isEmpty || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final repository = ref.read(characterCreationRepositoryProvider);
    final draft = ref.read(characterCreationDraftControllerProvider);

    try {
      await repository.createCharacter(
        draft: draft,
        characterName: name,
        raceCatalog: data.raceCatalog,
        classOption: data.classOption,
        backgroundOption: data.backgroundOption,
        skillCatalog: data.skillCatalog,
        toolCatalog: data.toolCatalog,
        languageCatalog: data.languageCatalog,
        spellCatalog: data.spellCatalog,
        itemCatalog: data.itemCatalog,
      );

      // Invalide la liste des personnages *avant* de naviguer, pour qu'elle
      // réaffiche immédiatement le nouveau personnage sans pull-to-refresh
      // manuel — voir `features/characters/presentation/providers/character_providers.dart`.
      ref.invalidate(charactersProvider);
      if (!mounted) return;
      // Retour paramétrable (ex. étape 3/4 "Rejoindre une histoire") si un
      // sous-flux en a posé un avant de lancer cet assistant — voir la
      // documentation de classe de `CharacterCreationReturnRouteController`.
      // Toujours consommé (jamais juste lu) : cette route de retour ne doit
      // servir qu'une seule fois.
      final returnRoute = ref
          .read(characterCreationReturnRouteControllerProvider.notifier)
          .consume();
      context.go(returnRoute ?? '/');
    } on CharacterCreationFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = failure.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Une erreur est survenue. Réessayez.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(summaryStepDataProvider);

    return Scaffold(
      body: dataAsync.when(
        data: (data) => Column(
          children: [
            _Header(onBack: _goBack, currentStep: 9, totalSteps: _totalSteps),
            Expanded(child: _buildContent(data)),
          ],
        ),
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
                    : 'Impossible de charger le récapitulatif. Réessayez.',
                // Invalide les providers *feuilles* plutôt que le seul
                // `summaryStepDataProvider` — même bug déjà corrigé sur les
                // étapes précédentes (voir leur documentation) : invalider
                // seulement le provider combiné ne force pas un nouvel appel
                // réseau sur celui des catalogues qui a échoué.
                onRetry: () {
                  ref.invalidate(raceCatalogProvider);
                  ref.invalidate(classCatalogProvider);
                  ref.invalidate(backgroundCatalogProvider);
                  ref.invalidate(skillCatalogProvider);
                  ref.invalidate(toolCatalogProvider);
                  ref.invalidate(languageCatalogProvider);
                  ref.invalidate(itemCatalogProvider);
                  final classId = ref
                      .read(characterCreationDraftControllerProvider)
                      .classId;
                  if (classId != null) {
                    ref.invalidate(spellCatalogProvider(classId: classId));
                  }
                  ref.invalidate(summaryStepDataProvider);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(SummaryStepData data) {
    _data = data;
    final draft = ref.watch(characterCreationDraftControllerProvider);

    final finalAbilityScores = FinalAbilityScoresResolver.resolve(
      baseScores: draft.abilityScores ?? const {},
      raceCatalog: data.raceCatalog,
      raceId: draft.raceId,
      subraceId: draft.subraceId,
    );

    final className = data.classOption.name;
    final showCantripRow = SpellcastingRules.cantripQuotaFor(className) > 0;
    final showLevelOneRow =
        SpellcastingRules.levelOneSpellQuotaFor(className) > 0;

    final rows = <({String title, String value, int stepNumber})>[
      (
        title: 'Caractéristiques',
        value: _formatAbilityScores(finalAbilityScores),
        stepNumber: 4,
      ),
      (
        title: 'Compétences',
        value: draft.classSkillChoices.join(', '),
        stepNumber: 5,
      ),
      if (draft.classToolChoices.isNotEmpty)
        (
          title: 'Outils',
          value: draft.classToolChoices.join(', '),
          stepNumber: 5,
        ),
      if (draft.backgroundLanguageChoices.isNotEmpty)
        (
          title: 'Langues',
          value: draft.backgroundLanguageChoices.join(', '),
          stepNumber: 5,
        ),
      if (showCantripRow)
        (
          title: 'Sorts mineurs',
          value: '${draft.classCantripChoices.length} sélectionné(s)',
          stepNumber: 6,
        ),
      if (showLevelOneRow)
        (
          title: 'Sorts niveau 1',
          value: '${draft.classLevelOneSpellChoices.length} sélectionné(s)',
          stepNumber: 6,
        ),
      (
        title: 'Équipement',
        value: _formatEquipmentSummary(draft, data),
        stepNumber: 7,
      ),
      (
        title: 'Histoire & portrait',
        value: _hasAnyAppearanceText(draft) ? 'Renseignés' : 'Non renseignés',
        stepNumber: 8,
      ),
    ];

    final trimmedName = _nameController.text.trim();
    final canSubmit = trimmedName.isNotEmpty && !_isSubmitting;

    return SafeArea(
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
              children: [
                _NameFieldBlock(
                  controller: _nameController,
                  enabled: !_isSubmitting,
                ),
                const SizedBox(height: AppSpacing.md),
                _HeaderCard(
                  name: trimmedName,
                  subtitle: _formatHeaderSubtitle(draft, data),
                ),
                const SizedBox(height: AppSpacing.md),
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.sm),
                  _SummaryRow(
                    title: rows[i].title,
                    value: rows[i].value,
                    onTap: _isSubmitting
                        ? null
                        : () => _editStep(rows[i].stepNumber),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              children: [
                if (_errorMessage != null) ...[
                  AlertBanner(message: _errorMessage!),
                  const SizedBox(height: AppSpacing.sm),
                ],
                InkWell(
                  onTap: _isSubmitting ? null : _goBack,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Center(
                      child: Text(
                        '‹ Retour',
                        style: AppTypography.body(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ).copyWith(decoration: TextDecoration.underline),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                PrimaryButton(
                  label: 'Créer le personnage',
                  isLoading: _isSubmitting,
                  onPressed: canSubmit ? _submit : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "For 16 · Dex 14 · ..." dans l'ordre canonique de
/// `ability_score_definitions.dart` — abréviations dupliquées depuis
/// `RaceSummaryFormatter._abilityAbbreviations` (privée, non réutilisable
/// telle quelle) plutôt que promues en constante partagée, même rationale de
/// duplication systématique que le reste de ce module (voir le commentaire
/// de classe de `RaceRowMapper`).
const Map<String, String> _abilityAbbreviations = {
  'str': 'For',
  'dex': 'Dex',
  'con': 'Con',
  'int': 'Int',
  'wis': 'Sag',
  'cha': 'Cha',
};

String _formatAbilityScores(Map<String, int> finalScores) {
  final parts = <String>[
    for (final definition in abilityScoreDefinitions)
      if (finalScores.containsKey(definition.key))
        '${_abilityAbbreviations[definition.key]} '
            '${finalScores[definition.key]}',
  ];
  return parts.join(' · ');
}

/// "{Race}{ (Sous-race)} · {Classe} · Niveau 1", segments omis proprement si
/// non résolus (voir la spec visuelle). Une race personnalisée (texte libre
/// de l'étape 1, `raceCustomText`) compte comme "résolue" et s'affiche telle
/// quelle : décision prise faute de précision explicite du brief sur ce cas,
/// pour ne jamais laisser le segment race disparaître silencieusement alors
/// que le joueur a bien renseigné quelque chose à l'étape 1.
String _formatHeaderSubtitle(
  CharacterCreationDraft draft,
  SummaryStepData data,
) {
  String? raceSegment;
  if (draft.raceId != null) {
    for (final race in data.raceCatalog.races) {
      if (race.id == draft.raceId) {
        String? subraceName;
        if (draft.subraceId != null) {
          for (final subrace in data.raceCatalog.subraces) {
            if (subrace.id == draft.subraceId) {
              subraceName = subrace.name;
              break;
            }
          }
        }
        raceSegment = subraceName != null
            ? '${race.name} ($subraceName)'
            : race.name;
        break;
      }
    }
  } else if ((draft.raceCustomText?.trim().isNotEmpty) ?? false) {
    raceSegment = draft.raceCustomText!.trim();
  }

  final segments = [?raceSegment, data.classOption.name, 'Niveau 1'];
  return segments.join(' · ');
}

/// "Historique : {nom}" ou "Achat ({N} objets)" selon
/// `CharacterCreationDraft.equipmentChoiceTab` — voir la spec visuelle.
String _formatEquipmentSummary(
  CharacterCreationDraft draft,
  SummaryStepData data,
) {
  final tab = draft.equipmentChoiceTab ?? EquipmentChoiceTab.background;
  if (tab == EquipmentChoiceTab.background) {
    return 'Historique : ${data.backgroundOption.name}';
  }
  return 'Achat (${draft.purchasedEquipment.length} objets)';
}

/// `true` si au moins un des 9 champs texte de l'étape 8 est non-null (une
/// fois trim, un champ rempli puis entièrement effacé redevient déjà `null`
/// dans le brouillon — voir `CharacterCreationDraftController
/// .setAppearanceAndBackstory`, donc pas besoin de re-trim ici).
bool _hasAnyAppearanceText(CharacterCreationDraft draft) {
  final texts = <String?>[
    draft.appearanceText,
    draft.traitsText,
    draft.idealsText,
    draft.bondsText,
    draft.flawsText,
    draft.backstoryText,
    draft.alliesText,
    draft.featuresText,
    draft.treasureText,
  ];
  return texts.any((text) => text != null);
}

/// Champ "Nom du personnage" en tête du contenu scrollable — reproduit
/// `_TextFieldBlock` de l'étape 8 (label 13/800 `textSecondary` majuscules,
/// thème `AppTheme.light.inputDecorationTheme` sans surcharge), mais
/// mono-ligne (pas de croissance libre comme les 9 champs texte de l'étape
/// 8) avec un texte d'aide discret sous le champ plutôt qu'un style
/// d'erreur — voir la documentation de classe de [SummaryStepScreen] pour le
/// rationale de cette désactivation douce plutôt qu'un message d'erreur.
class _NameFieldBlock extends StatelessWidget {
  const _NameFieldBlock({required this.controller, required this.enabled});

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NOM DU PERSONNAGE',
          style: AppTypography.body(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: controller,
          enabled: enabled,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            hintText: 'Ex. Halltesse Ambrelune',
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Requis pour retrouver facilement ton personnage',
          style: AppTypography.body(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

/// Carte d'en-tête : portrait (toujours vide à cette itération), nom saisi et
/// résumé race/classe/niveau — voir la spec visuelle.
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.name, required this.subtitle});

  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.goldEnd,
          width: AppBorders.cardEmphasis,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PortraitFrame(portraitUrl: null, size: 64),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // Jamais `font.display` : c'est une donnée saisie, pas un
                  // titre décoratif — même exception déjà actée pour
                  // `CharacterCard.name`.
                  name.isEmpty ? 'Personnage sans nom' : name,
                  // Repli "Personnage sans nom" (avant toute saisie) rendu
                  // avec le même traitement que `hintStyle`
                  // (`app_theme.dart`, `InputDecorationTheme.hintStyle` :
                  // `textMuted`/poids normal) plutôt que le style plein d'un
                  // vrai nom déjà saisi — évite de laisser croire qu'un nom a
                  // déjà été renseigné (retour direction-artistique).
                  style: name.isEmpty
                      ? AppTypography.body(
                          fontSize: 16,
                          color: AppColors.textMuted,
                        )
                      : AppTypography.body(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: AppTypography.body(
                    fontSize: 13,
                    color: AppColors.textSecondary,
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

/// Une ligne de résumé éditable — style visuel de `SelectableOptionTile` non
/// sélectionné, mais mise en page différente (titre à gauche, valeur à
/// droite, icône crayon) : voir la spec visuelle pour le rationale de ne pas
/// réutiliser `SelectableOptionTile` tel quel ici.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.title,
    required this.value,
    required this.onTap,
  });

  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.parchmentCard,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.woodLight,
              width: AppBorders.card,
            ),
          ),
          child: Row(
            children: [
              Text(
                title,
                style: AppTypography.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bandeau bois plein en tête d'écran, avec le titre d'étape et la barre de
/// progression — copié depuis `equipment_step_screen.dart`/
/// `appearance_and_backstory_step_screen.dart` (voir la documentation de
/// classe de [SummaryStepScreen]).
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
                          '9. Récapitulatif',
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
/// chargement/l'erreur — copie exacte du pattern des étapes précédentes.
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
