import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/french_text_normalizer.dart';
import '../../../core/widgets/accent_icon_badge.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/selectable_option_tile.dart';
import '../../../core/widgets/step_progress_bar.dart';
import '../domain/character_creation_failure.dart';
import '../domain/creation_step_help.dart';
import '../domain/lineage_choice_catalog.dart';
import '../domain/race_catalog.dart';
import '../domain/race_option.dart';
import '../domain/race_step_selection.dart';
import 'providers/character_creation_draft_provider.dart';
import 'providers/character_creation_providers.dart';
import 'providers/character_edit_session_provider.dart';
import 'providers/lineage_choice_providers.dart';
import 'widgets/abandon_creation_flow.dart';
import 'widgets/creation_mode_title.dart';
import 'widgets/draft_autosave_footer.dart';
import 'widgets/step_help_sheet.dart';

/// Étape 2/10 de l'assistant de création de personnage : choix de la race
/// (`docs/cahier-des-charges/04-fonctionnalites-app-mobile.md` section 3
/// point 1, maquette `02_étape_1_race.png`) — étape 1/10 depuis le chantier
/// "choix d'édition 2014/2024 par personnage" (voir `EditionStepScreen`,
/// poussée AVANT cet écran, qui a décalé d'un cran la numérotation affichée
/// de toutes les étapes suivantes).
///
/// Le choix de sous-race n'est PAS traité sur cet écran : pour une race qui
/// en a, `_submit` pousse `SubraceStepScreen`, une étape séparée (même
/// principe que l'étape 6/9 "Sorts" déjà sautée pour une classe non
/// lanceuse de sorts, voir le commentaire de `/characters/new/step-7` dans
/// `core/router/app_router.dart`) — pour une race sans sous-race,
/// `/characters/new/step-2` est atteinte directement, SAUF si cette race a
/// des lignées 2024 à choisir (Drakéide, Tieffelin, Goliath à ce jour, voir
/// `LineageChoiceCatalog.isConcerned`) : `_submit` pousse alors
/// `LineageStepScreen` à la place — ces deux écrans de second niveau
/// (sous-race / lignée) sont mutuellement exclusifs pour une race donnée
/// (voir le critère de déclenchement dans `_submit`).
///
/// En-tête bois plein (pas le dégradé "scène") : `Scaffold` classique plutôt
/// que `SceneScaffold`, avec un bandeau `wood.medium` posé manuellement au
/// sommet, portant le titre d'étape et la barre de progression — voir
/// `_Header` ci-dessous.
///
/// N'utilise plus `core/widgets/wood_back_header.dart` (`WoodBackHeader`,
/// utilisé par ex. par `character_detail_screen.dart`) : ce composant partagé
/// n'affiche que retour + titre, sans titre d'étape ni `StepProgressBar` —
/// insuffisant ici. `_Header`/`_MinimalHeader` sont donc dupliqués localement
/// depuis `class_step_screen.dart`, comme les étapes 2 à 5, plutôt que
/// d'étendre `WoodBackHeader` (dette de fond signalée par le chef de projet,
/// pattern à ne pas factoriser dans `core/widgets` à cette occasion — voir
/// le principe de duplication assumée documenté dans ce module).
///
/// Chantier "différenciation 2014/2024 pour les races" (24/10/2026) :
/// - le Demi-elfe (et toute race sans équivalent 2024, `RaceOption
///   .traits2024` nul) est grisée/non sélectionnable en édition 2024, voir
///   [_isRaceAvailable] ;
/// - le Nain/l'Halfelin, "unifiés" sans sous-race en 2024 (`RaceCatalog
///   .isUnifiedRaceIn2024`), sautent `SubraceStepScreen` même s'ils ont des
///   lignes `subraces` (réservées à l'édition 2014) — voir [_submit] ;
/// - le Tieffelin en 2014 saute `LineageStepScreen` (RAW 2014 n'a qu'un seul
///   legs, l'Infernal, sans choix) — voir [_submit]/[_infernalLineageId].
///
/// Mode modification (`CharacterEditSession`, voir [_isRaceLocked]) : la
/// race est verrouillée inconditionnellement (décision du 09/10/2026, D53 de
/// `docs/dette-technique.md`) — même patron que la classe verrouillée
/// au-delà du niveau 1 sur `class_step_screen.dart`
/// (`CharacterEditSession.canChangeClass`), mais sans seuil de niveau ici
/// (`CharacterEditSession.canChangeRace` vaut toujours `false`) : changer de
/// race casserait les sorts innés déjà acquis (ceux de l'ancienne race
/// resteraient, ceux de la nouvelle n'arriveraient jamais).
class RaceStepScreen extends ConsumerStatefulWidget {
  const RaceStepScreen({super.key});

  @override
  ConsumerState<RaceStepScreen> createState() => _RaceStepScreenState();
}

class _RaceStepScreenState extends ConsumerState<RaceStepScreen> {
  static const int _totalSteps = 10;

  final _customRaceController = TextEditingController();

  /// Champ "Rechercher une race..." au-dessus de la liste, même patron que
  /// `pact_weapon_picker_sheet.dart` ("Rechercher une arme...") : filtre en
  /// tapant, sans bouton de validation séparé (écouté via [_handleSearchChanged]
  /// pour redessiner la liste à chaque frappe).
  final _searchController = TextEditingController();

  int? _selectedRaceId;
  bool _isCustomRaceSelected = false;

  /// Édition du brouillon, lue une seule fois comme [_selectedRaceId] : fixée
  /// à `EditionStepScreen`, TOUTE PREMIÈRE étape de l'assistant, avant
  /// celle-ci. Pilote [_isRaceAvailable]/[_submit] — chantier
  /// "différenciation 2014/2024 pour les races" (24/10/2026).
  late String _edition;

  /// Race Tieffelin — RAW 2014 n'a qu'un seul legs (Infernal), sans choix
  /// (contrairement à 2024, qui en propose trois : Infernal/Abyssal/
  /// Chthonien) : voir [_submit], qui contourne `LineageStepScreen` pour ce
  /// cas précis plutôt que d'y afficher un unique choix verrouillé — option
  /// la plus simple retenue pour ce chantier. Même précédent de constante
  /// figée que `LineageStepScreen._LineageStepCopy`.
  static const int _tieffelinRaceId = 9;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    // Réhydrate la sélection depuis le brouillon déjà en mémoire (retour en
    // arrière depuis une étape suivante) — voir
    // `docs/cahier-des-charges/05-ux-navigation.md` : "Possibilité de revenir
    // en arrière sans perdre les choix déjà faits." Le brouillon `keepAlive`
    // ne perd jamais la donnée, mais sans cette lecture l'écran repartait à
    // zéro visuellement. Si le brouillon est vide (première visite), rien ne
    // change : les deux champs valent `null`/`false` comme avant. La
    // sous-race (`draft.subraceId`) n'est pas réhydratée ici : elle
    // n'appartient plus à cet écran, voir `SubraceStepScreen`.
    final draft = ref.read(characterCreationDraftControllerProvider);
    _selectedRaceId = draft.raceId;
    _edition = draft.edition;
    _isCustomRaceSelected = draft.raceCustomText != null;
    if (_isCustomRaceSelected) {
      _customRaceController.text = draft.raceCustomText!;
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    _customRaceController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    if (mounted) setState(() {});
  }

  /// Mode modification : la race ne peut plus jamais changer, quel que soit
  /// le niveau (contrairement à `ClassStepScreen._isClassLocked`) — voir la
  /// doc de classe de [RaceStepScreen].
  bool get _isRaceLocked {
    final session = ref.read(characterEditSessionControllerProvider);
    return session != null && !session.canChangeRace;
  }

  /// `false` si [race] n'existe pas RAW en édition 2024 (Demi-elfe à ce
  /// jour, remplacée par un choix Elfe/Humain avec personnalisation
  /// narrative non modélisé ici) — toujours `true` en édition 2014. Pilote
  /// `SelectableOptionTile.enabled`/[_selectRace] dans [_raceGroupSection] —
  /// chantier "différenciation 2014/2024 pour les races" (24/10/2026).
  bool _isRaceAvailable(RaceOption race) {
    if (_edition != '2024') return true;
    return race.traits2024 != null;
  }

  void _selectRace(int raceId, {required bool available}) {
    if (_isRaceLocked || !available) return;
    setState(() {
      _isCustomRaceSelected = false;
      _selectedRaceId = raceId;
    });
  }

  void _selectCustomRace() {
    if (_isRaceLocked) return;
    setState(() {
      _isCustomRaceSelected = true;
      _selectedRaceId = null;
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
  ///
  /// `subraceId` n'est mis à `null` que si la race sélectionnée diffère
  /// réellement de celle déjà en brouillon (y compris un changement vers/
  /// depuis une race personnalisée) : retour en arrière SANS changer de race,
  /// puis "Suivant" à nouveau, doit conserver `draft.subraceId` tel quel pour
  /// ne pas effacer à tort un choix déjà fait sur `SubraceStepScreen`. Pour
  /// une race réellement différente, `subraceId` reste `null` ici quelle
  /// qu'elle soit : il sera (ré)écrit par `SubraceStepScreen` pour les races
  /// qui en ont — voir la doc de classe. La navigation dépend de [catalog]
  /// (déjà chargé, voir `_buildContent`) : une race avec sous-races pousse
  /// l'étape "Sous-race" ; sinon, si elle a des lignées à choisir dans
  /// L'ÉDITION DU BROUILLON (`lineageChoiceCatalogProvider(edition:
  /// draft.edition)`, déjà résolu à ce stade — voir `_buildContent`, qui le
  /// `watch` pour qu'il soit préchargé pendant que l'utilisateur parcourt cet
  /// écran), l'étape "Lignée" est poussée à la place ; sinon, l'étape 2/9
  /// "Classe" est atteinte directement. Un catalogue de lignées pas encore
  /// résolu (chargement/erreur, rare — voir `_buildContent`) retombe
  /// silencieusement sur l'étape 2/9 directement : mieux vaut sauter ce choix
  /// que bloquer la progression de l'assistant sur un second appel réseau que
  /// l'utilisateur ne voit jamais échouer explicitement ici.
  void _submit(RaceCatalog catalog) {
    // Race verrouillée : ni sous-race/lignée à choisir ni brouillon à
    // changer — `SubraceStepScreen`/`LineageStepScreen` deviennent
    // inatteignables en édition par ce chemin (voir la doc de classe).
    if (_isRaceLocked) {
      context.push('/characters/new/step-2');
      return;
    }
    final draft = ref.read(characterCreationDraftControllerProvider);
    final newRaceId = _isCustomRaceSelected ? null : _selectedRaceId;
    final raceChanged =
        _isCustomRaceSelected != (draft.raceCustomText != null) ||
        draft.raceId != newRaceId;
    ref
        .read(characterCreationDraftControllerProvider.notifier)
        .setRace(
          raceId: newRaceId,
          subraceId: raceChanged ? null : draft.subraceId,
          raceCustomText: _isCustomRaceSelected
              ? _customRaceController.text.trim()
              : null,
        );
    final selectedRaceId = _selectedRaceId;
    // Nain/Halfelin en édition 2024 : race "unifiée", sans sous-race du tout
    // (voir `RaceCatalog.isUnifiedRaceIn2024`) — `SubraceStepScreen` reste
    // sautée même si [catalog] a bien des lignes `subraces` pour cette race
    // (celles-ci restent utilisées en 2014).
    final skipUnifiedSubrace =
        selectedRaceId != null &&
        draft.edition == '2024' &&
        catalog.isUnifiedRaceIn2024(selectedRaceId);
    if (!_isCustomRaceSelected &&
        selectedRaceId != null &&
        catalog.subracesOf(selectedRaceId).isNotEmpty &&
        !skipUnifiedSubrace) {
      context.push('/characters/new/subrace');
      return;
    }
    // Tieffelin en 2014 : vérifié EN PREMIER, INDÉPENDAMMENT du catalogue de
    // lignées filtré par [draft.edition] ci-dessous — `race_lineages` n'a
    // AUCUNE ligne `phb_ancestry` pour le Tieffelin (RAW 2014 n'a pas de
    // choix d'ascendance du tout, contrairement au Drakéide), donc
    // `isConcerned(9)` y serait toujours `false` et ce cas ne serait jamais
    // atteint s'il dépendait de ce même catalogue. Le legs "Infernal" lui-
    // même n'existe QUE sous `'2024_lineage'` (il représente mécaniquement
    // le Tieffelin RAW 2014, par coïncidence de modélisation) : le lookup
    // interroge donc explicitement `edition: '2024'`, jamais
    // `draft.edition` — voir la doc de [_tieffelinRaceId] et de
    // `LineageChoiceRepository.fetchLineageChoices`.
    if (!_isCustomRaceSelected &&
        selectedRaceId == _tieffelinRaceId &&
        draft.edition == '2014') {
      final infernalCatalog = ref
          .read(lineageChoiceCatalogProvider(edition: '2024'))
          .value;
      final infernalId = infernalCatalog == null
          ? null
          : _infernalLineageId(infernalCatalog);
      if (infernalId != null) {
        ref
            .read(characterCreationDraftControllerProvider.notifier)
            .setLineage(infernalId);
      }
      context.push('/characters/new/step-2');
      return;
    }
    final lineageCatalog = ref
        .read(lineageChoiceCatalogProvider(edition: draft.edition))
        .value;
    final isLineageConcerned =
        !_isCustomRaceSelected &&
        selectedRaceId != null &&
        (lineageCatalog?.isConcerned(selectedRaceId) ?? false);
    if (isLineageConcerned) {
      context.push('/characters/new/lineage');
    } else {
      context.push('/characters/new/step-2');
    }
  }

  /// Legs "Infernal" de [catalog] pour le Tieffelin, seul legs RAW 2014 (voir
  /// [_tieffelinRaceId]) — recherché par nom plutôt qu'un `race_lineages.id`
  /// en dur (potentiellement différent entre environnements de seed), `null`
  /// si introuvable (cas défensif, ne devrait pas arriver avec les données
  /// actuelles : `_submit` retombe alors sur l'étape 2/9 sans lignée
  /// assignée plutôt que de planter).
  int? _infernalLineageId(LineageChoiceCatalog catalog) {
    for (final option in catalog.optionsFor(_tieffelinRaceId)) {
      if (option.name == 'Infernal') return option.id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(raceCatalogProvider);

    return Scaffold(
      body: catalogAsync.when(
        data: _buildContent,
        loading: () => Column(
          children: [
            _MinimalHeader(
              onBack: _goToCharacterList,
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
              onBack: _goToCharacterList,
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

  Widget _buildContent(RaceCatalog catalog) {
    // `watch` (pas seulement `read` dans `_submit`) : déclenche son
    // chargement dès l'affichage de cet écran plutôt qu'à la soumission,
    // pour qu'il soit déjà résolu — pour N'IMPORTE QUELLE race — au moment
    // où l'utilisateur tape "Suivant" (voir la doc de [_submit]). Catalogue
    // de l'édition du brouillon (celui réellement utilisé pour la décision
    // générique de `_submit`) ; en 2014, précharge AUSSI le catalogue
    // `'2024'` (toujours nécessaire pour le lookup du legs "Infernal" du
    // Tieffelin, voir [_infernalLineageId]) — jamais l'inverse (un brouillon
    // 2024 n'a besoin que du sien).
    ref.watch(lineageChoiceCatalogProvider(edition: _edition));
    if (_edition == '2014') {
      ref.watch(lineageChoiceCatalogProvider(edition: '2024'));
    }
    final canProceed = RaceStepSelection.canProceed(
      isCustomRace: _isCustomRaceSelected,
      customRaceText: _customRaceController.text,
      selectedRaceId: _selectedRaceId,
    );
    // `catalog.races` est déjà trié races de base puis races d'extension
    // (voir `data/character_creation_repository.dart::_mapRaceCatalogPayload`)
    // : un simple `where` préserve cet ordre dans chaque groupe, pas besoin
    // de retrier ici.
    final filteredRaces = _filterRaces(catalog.races);
    final coreRaces = [
      for (final race in filteredRaces)
        if (race.isCoreSource) race,
    ];
    final extensionRaces = [
      for (final race in filteredRaces)
        if (!race.isCoreSource) race,
    ];
    final isRaceLocked = _isRaceLocked;

    return Column(
      children: [
        _Header(
          onBack: _goToCharacterList,
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
                      "Choisis l'ascendance de ton personnage.",
                      style: AppTypography.body(fontSize: 14),
                    ),
                  ),
                ),
                // Filtrer une liste qu'on ne peut plus choisir n'a aucune
                // utilité : masqué entièrement en mode modification (voir la
                // doc de classe de [RaceStepScreen]).
                if (!isRaceLocked)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      0,
                    ),
                    child: TextFormField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Rechercher une race...',
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppColors.textMuted,
                        ),
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
                      if (isRaceLocked) ...[
                        const InfoBanner(
                          message:
                              'La race ne peut pas être modifiée après la '
                              'création du personnage : elle est liée aux '
                              'sorts innés déjà acquis.',
                          icon: Icons.lock_outline,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      if (coreRaces.isEmpty && extensionRaces.isEmpty)
                        const _EmptySearchState()
                      else ...[
                        ..._raceGroupSection(
                          title: 'RACES DE BASE',
                          races: coreRaces,
                          startIndex: 0,
                        ),
                        ..._raceGroupSection(
                          title: "RACES D'EXTENSION",
                          races: extensionRaces,
                          startIndex: coreRaces.length,
                          addSpacingBefore: coreRaces.isNotEmpty,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      SelectableOptionTile(
                        title: 'Race personnalisée',
                        selected: _isCustomRaceSelected,
                        // Verrouillée : affiche le nom déjà saisi en lecture
                        // seule au lieu du `TextField` éditable ci-dessous
                        // (voir la doc de classe de [RaceStepScreen]).
                        selectedDetail: isRaceLocked
                            ? _customRaceController.text
                            : null,
                        leading: const AccentIconBadge(
                          index: -1,
                          icon: Icons.shield_rounded,
                          neutralIcon: Icons.edit_note,
                        ),
                        onTap: _selectCustomRace,
                      ),
                      if (_isCustomRaceSelected && !isRaceLocked) ...[
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
                              onPressed: canProceed
                                  ? () => _submit(catalog)
                                  : null,
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

  /// Races dont le nom contient le texte du champ de recherche (sans accents
  /// ni casse, voir [FrenchTextNormalizer]) ; toutes si le champ est vide.
  /// Même patron que `PactWeaponRules.search`, dupliqué ici plutôt que
  /// factorisé (pas de couplage entre cette étape et la fiche personnage,
  /// voir la doc de classe de [RaceStepScreen]).
  List<RaceOption> _filterRaces(List<RaceOption> races) {
    final needle = FrenchTextNormalizer.normalize(_searchController.text);
    if (needle.isEmpty) return races;
    return [
      for (final race in races)
        if (FrenchTextNormalizer.normalize(race.name).contains(needle)) race,
    ];
  }

  /// Un en-tête de section ("RACES DE BASE"/"RACES D'EXTENSION") suivi
  /// d'une tuile par race de [races] — liste vide pour un groupe devenu vide
  /// après filtre, afin que son en-tête disparaisse entièrement plutôt que
  /// de s'afficher au-dessus d'une liste vide (même patron que
  /// `equipment_step_screen.dart::_classSection`/`_historySection`).
  /// [startIndex] poursuit le cycle de couleurs de [AccentIconBadge] entre
  /// les deux groupes plutôt que de le redémarrer à chaque section.
  List<Widget> _raceGroupSection({
    required String title,
    required List<RaceOption> races,
    required int startIndex,
    bool addSpacingBefore = false,
  }) {
    if (races.isEmpty) return const [];
    return [
      if (addSpacingBefore) const SizedBox(height: AppSpacing.md),
      _SectionHeader(title: title),
      const SizedBox(height: AppSpacing.sm),
      for (var i = 0; i < races.length; i++) ...[
        if (i > 0) const SizedBox(height: AppSpacing.sm),
        _raceTile(races[i], startIndex + i),
      ],
    ];
  }

  /// Une tuile de [race] à l'index [badgeIndex] (couleur de
  /// [AccentIconBadge]) — extrait de [_raceGroupSection] pour calculer
  /// [_isRaceAvailable] une seule fois par race plutôt que plusieurs fois
  /// inline.
  Widget _raceTile(RaceOption race, int badgeIndex) {
    final available = _isRaceAvailable(race);
    return SelectableOptionTile(
      title: race.name,
      // Message explicite plutôt qu'un résumé de bonus désormais trompeur
      // (ces bonus 2014 ne s'appliquent plus à cette race en 2024) — voir
      // [_isRaceAvailable].
      subtitle: available
          ? race.summaryLine
          : 'Indisponible en édition 2024 — remplacée par un choix '
                'Elfe/Humain avec personnalisation narrative.',
      enabled: available,
      onInfo: available
          ? () => showStepHelpSheet(
              context,
              StepHelpContent(title: race.name, body: race.infoText),
            )
          : null,
      selected: !_isCustomRaceSelected && _selectedRaceId == race.id,
      leading: AccentIconBadge(index: badgeIndex, icon: Icons.shield_rounded),
      onTap: () => _selectRace(race.id, available: available),
    );
  }
}

/// Titre de section ("RACES DE BASE"/"RACES D'EXTENSION"), sans badge de
/// quota — même style que `equipment_step_screen.dart::_SectionHeader`,
/// dupliqué ici pour ne jamais coupler les deux étapes entre elles (même
/// rationale que les autres duplications déjà documentées dans ce fichier).
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: AppTypography.body(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Affiché quand la recherche ne trouve aucune race (les deux groupes sont
/// vides) — "Race personnalisée" reste toujours proposée en dessous (voir
/// `_buildContent`), ce message ne porte donc que sur le catalogue.
class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Text(
        'Aucune race trouvée.',
        style: AppTypography.body(color: AppColors.textMuted),
      ),
    );
  }
}

/// Bandeau bois plein en tête d'écran, avec le titre d'étape et la barre de
/// progression — copié depuis `equipment_step_screen.dart`/
/// `summary_step_screen.dart` (voir la documentation de classe de
/// [RaceStepScreen] pour le rationale de ne plus utiliser `WoodBackHeader`
/// ici).
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
                          '2. Race',
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
