import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_observer_provider.dart';
import '../../../core/sync/sync_banner_engine.dart';
import '../../../core/sync/sync_status_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/dashed_border_painter.dart';
import '../../../core/widgets/display_text.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/scene_scaffold.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/sync_status_banner.dart';
import '../../../l10n/app_localizations.dart';
import '../../app_update/presentation/widgets/update_suggested_banner.dart';
import '../../character_creation/presentation/providers/character_creation_draft_provider.dart';
import '../../character_creation/presentation/providers/character_creation_return_route_provider.dart';
import '../../character_creation/presentation/providers/character_edit_session_provider.dart';
import '../domain/character_failure.dart';
import '../domain/character_list_filter.dart';
import '../domain/character_list_sort.dart';
import '../domain/character_list_sorter.dart';
import '../domain/character_status_filter.dart';
import '../domain/character_summary.dart';
import '../domain/write_outcome.dart';
import 'providers/character_last_opened_provider.dart';
import 'providers/character_providers.dart';
import 'widgets/character_card.dart';
import 'widgets/character_card_action_sheet.dart';
import 'widgets/character_delete_confirmation.dart';
import 'widgets/character_list_filter_sheet.dart';
import 'widgets/character_selection_action_bar.dart';
import 'widgets/connection_error_state.dart';
import 'widgets/sync_exit_dialog.dart';

/// Facteur d'échelle de police au-delà duquel la recherche cesse d'être
/// épinglée (elle défile avec le reste) et le pied passe en colonne ; même
/// seuil que la bannière de mise à jour.
const double _largeTextScale = 1.3;

/// Hauteur disponible en deçà de laquelle la recherche n'est plus épinglée et
/// le pied est plafonné : petit écran ou clavier ouvert (sinon les éléments
/// fixes mangeraient toute la zone de défilement).
const double _compactHeight = 420;

/// Largeur maximale de lecture (tablette) : le contenu est centré, la barre
/// de défilement reste au bord de l'écran.
const double _readingWidth = 600;

/// Part de la hauteur disponible que le pied fixe (Créer / Importer, ou barre
/// d'actions de la sélection) ne dépasse jamais — seule exception documentée
/// au défilement unique : au-delà, le pied défile en interne.
const double _footerMaxHeightFraction = 0.35;

/// Part de la hauteur disponible que le bandeau de synchro épinglé ne dépasse
/// jamais à police agrandie (défilement interne au-delà). 0,2 depuis le
/// panneau des alertes : le bandeau ne porte plus qu'un libellé court et un
/// lien (plus le texte de la première alerte), il tient dans ce plafond.
///
/// D211 résolu : pendant une alerte de synchro, la bannière de mise à jour
/// passe en forme compacte d'une ligne (`UpdateSuggestedBanner.compact`) et ce
/// plafond reste à 0,2 (valeur conservée). Le critère « liste >= 40 % au repos
/// à x2,0 sur 320x568 » n'est pas atteignable avec une alerte (en-tête 136 px
/// + alerte 113,6 px sur 440 px) : les tests mesurent le critère reformulé.
const double _syncBandMaxHeightFraction = 0.2;

/// `true` quand la police système est agrandie au-delà de [_largeTextScale].
bool _isLargeText(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(14) / 14 > _largeTextScale;

/// Écran d'accueil listant les personnages du joueur connecté
/// (`docs/cahier-des-charges/04-fonctionnalites-app-mobile.md` section 2,
/// maquette `01_liste_personnages.png`).
///
/// `ConsumerStatefulWidget` + `RouteAware` (plutôt que `ConsumerWidget`) :
/// `character_detail_screen.dart` (fiche personnage) et `level_up_screen.dart`
/// écrivent en base depuis de nombreux endroits (PV/XP, repos, montée de
/// niveau, portrait, sorts, inventaire, histoire...) sans jamais invalider
/// `charactersProvider` eux-mêmes — chasser chaque point d'écriture serait
/// fragile (un futur oubli reproduirait le même bug). [didPopNext] se
/// déclenche à chaque retour au premier plan de cet écran suite à un `pop`
/// d'une route poussée par-dessus lui (retour direct de la fiche, ou retour
/// en cascade depuis "Montée de niveau" via la fiche), peu importe la cause
/// — voir `route_observer_provider.dart`. Un refetch systématique au retour
/// (même si rien n'a changé) est acceptable ici, cohérent avec la stratégie
/// "réseau d'abord" déjà en place ailleurs dans ce dépôt : pas besoin
/// d'optimiser pour éviter un refetch inutile.
class CharacterListScreen extends ConsumerStatefulWidget {
  const CharacterListScreen({super.key});

  @override
  ConsumerState<CharacterListScreen> createState() =>
      _CharacterListScreenState();
}

class _CharacterListScreenState extends ConsumerState<CharacterListScreen>
    with RouteAware {
  // Résolu via `ref.read` dans [didChangeDependencies] puis conservé ici :
  // `ref` n'est plus utilisable en toute sécurité dans [dispose] (le widget
  // est en cours de démontage, voir la documentation de
  // `ConsumerStatefulElement.read`) — sans ce champ, `unsubscribe` lèverait
  // un `StateError` à chaque fermeture de cet écran.
  RouteObserver<PageRoute<dynamic>>? _routeObserver;

  /// Voir `character_list_filter.dart::CharacterListFilter.apply`. Un
  /// `TextEditingController` (plutôt qu'un simple `String` d'état) : même
  /// convention que `add_item_flow.dart` (recherche dans le catalogue
  /// d'objets), seul autre champ de recherche existant dans ce dépôt.
  final TextEditingController _searchController = TextEditingController();

  /// Clé de la rangée de recherche : conserve l'état (focus, saisie) quand
  /// elle passe d'un sliver épinglé à un sliver qui défile (ex. ouverture du
  /// clavier, qui réduit la hauteur sous [_compactHeight]).
  final GlobalKey _searchRowKey = GlobalKey();
  Set<String> _selectedClassNames = {};
  Set<CharacterStatusFilter> _selectedStatuses = {};

  /// Tri choisi (P18) — par session, non persisté, comme les filtres. Jamais
  /// remis à zéro par [_resetSearch] (qui ne concerne que la recherche et les
  /// filtres) : seul « Réinitialiser » de la feuille y touche.
  CharacterListSort _selectedSort = CharacterListSort.defaultOrder;

  /// `true` pendant le mode sélection multiple (bouton `_SelectionModeButton`
  /// de `_SearchRow`) — voir la spec de la tâche "Mode sélection multiple +
  /// suppression groupée".
  bool _selectionMode = false;

  /// Identifiants des personnages cochés en mode sélection — toujours vide
  /// hors de ce mode (voir [_enterSelectionMode]/[_exitSelectionMode]).
  Set<String> _selectedCharacterIds = {};

  /// `true` pendant l'exécution de [_deleteSelectedCharacters] — désactive
  /// "Annuler" et bascule `DestructiveButton.isLoading` sur
  /// `CharacterSelectionActionBar`.
  bool _isDeletingSelection = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
  }

  void _handleSearchChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic>) {
      final observer = ref.read(routeObserverProvider);
      observer.subscribe(this, route);
      _routeObserver = observer;
    }
  }

  @override
  void dispose() {
    _routeObserver?.unsubscribe(this);
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _resetSearch() {
    setState(() {
      _searchController.clear();
      _selectedClassNames = {};
      _selectedStatuses = {};
    });
  }

  Future<void> _openFilterSheet(List<CharacterSummary> characters) async {
    final result = await showCharacterListFilterSheet(
      context,
      availableClassNames: CharacterListFilter.distinctClassNames(characters),
      selectedClassNames: _selectedClassNames,
      selectedStatuses: _selectedStatuses,
      selectedSort: _selectedSort,
    );
    if (result == null || !mounted) return;
    setState(() {
      _selectedClassNames = result.classNames;
      _selectedStatuses = result.statuses;
      _selectedSort = result.sort;
    });
  }

  /// Appelé par le [RouteObserver] quand une route poussée par-dessus cet
  /// écran est dépilée et que celui-ci redevient visible — voir la
  /// documentation de classe de [CharacterListScreen].
  ///
  /// L'invalidation est reportée après la frame en cours : quand le retour
  /// vient d'un `context.go` (fin de la création d'un personnage), le
  /// `RouteObserver` notifie pendant le `didUpdateWidget` du `Navigator`, donc
  /// en pleine phase de build — invalider un provider à ce moment lève
  /// « setState() or markNeedsBuild() called during build » (écran rouge en
  /// debug). Un seul refetch même si l'observateur notifie plusieurs fois
  /// avant la fin de la frame ; rien n'est fait si l'écran est démonté entre
  /// temps.
  @override
  void didPopNext() {
    if (_refreshScheduled) return;
    _refreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshScheduled = false;
      if (!mounted) return;
      ref.invalidate(charactersProvider);
    });
  }

  bool _refreshScheduled = false;

  void _enterSelectionMode() {
    setState(() {
      _selectionMode = true;
      _selectedCharacterIds = {};
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedCharacterIds = {};
    });
  }

  void _toggleCharacterSelected(String characterId) {
    setState(() {
      if (!_selectedCharacterIds.remove(characterId)) {
        _selectedCharacterIds.add(characterId);
      }
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// Supprime tous les personnages actuellement sélectionnés (bouton
  /// "Supprimer" de [CharacterSelectionActionBar]), après confirmation.
  ///
  /// Appelle `CharacterRepository.deleteCharacter` séquentiellement plutôt
  /// qu'en parallèle (`Future.wait`) : la méthode elle-même ne touche aucun
  /// état mutable partagé (ni `PendingCharacterWriteQueue`, ni cache — voir
  /// sa documentation, cette écriture n'est jamais mise en file), donc rien
  /// n'empêcherait techniquement un envoi parallèle ; le choix séquentiel
  /// est fait pour garder un suivi simple et fiable de quel personnage a
  /// précisément échoué (nécessaire pour l'échec partiel, voir la spec de la
  /// tâche) plutôt que pour une contrainte technique du dépôt — une
  /// suppression groupée reste une action rare, le coût de latence d'un
  /// enchaînement séquentiel est négligeable pour les volumes réalistes de
  /// cette liste.
  Future<void> _deleteSelectedCharacters(
    List<CharacterSummary> allCharacters,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final selected = allCharacters
        .where((character) => _selectedCharacterIds.contains(character.id))
        .toList();
    if (selected.isEmpty) return;

    final confirmed = selected.length == 1
        ? await showDeleteCharacterConfirmationDialog(
            context,
            characterName: selected.single.name,
          )
        : await showDeleteCharactersConfirmationDialog(
            context,
            count: selected.length,
          );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeletingSelection = true);

    final repository = ref.read(characterRepositoryProvider);
    final failedIds = <String>{};
    var offlineFailureCount = 0;

    for (final character in selected) {
      try {
        final outcome = await repository.deleteCharacter(
          characterId: character.id,
        );
        if (outcome == WriteOutcome.rejectedOffline) {
          failedIds.add(character.id);
          offlineFailureCount++;
        }
      } on CharacterFailure {
        failedIds.add(character.id);
      } catch (_) {
        failedIds.add(character.id);
      }
    }

    if (!mounted) return;
    ref.invalidate(charactersProvider);

    final succeededCount = selected.length - failedIds.length;

    if (failedIds.isEmpty) {
      setState(() {
        _isDeletingSelection = false;
        _selectionMode = false;
        _selectedCharacterIds = {};
      });
      return;
    }

    setState(() {
      _isDeletingSelection = false;
      // Le mode sélection reste actif avec seulement les personnages en
      // échec encore cochés (spec de la tâche).
      _selectedCharacterIds = failedIds;
    });

    if (succeededCount == 0) {
      // `CharacterRepository.deleteCharacter` ne met jamais cette écriture
      // en file de synchro (voir [offlineNotPersistedMessage],
      // `widgets/character_write_feedback.dart`) : une suppression groupée
      // entièrement en échec faute de réseau se signale donc avec ce
      // message plutôt qu'avec la promesse d'une synchronisation future.
      _showSnackBar(
        offlineFailureCount == failedIds.length
            ? l10n.characterOfflineNotPersistedMessage
            : l10n.characterListDeleteSelectionGenericError,
      );
      return;
    }

    _showSnackBar(
      _partialDeleteMessage(l10n, succeededCount, failedIds.length),
    );
  }

  /// "X personnage(s) supprimé(s), Y n'a/n'ont pas pu être supprimé(s)."
  /// (spec de la tâche) — accords au singulier/pluriel via les messages ICU
  /// `characterListDeleteSelectionSucceededLabel`/`...FailedLabel` plutôt
  /// qu'un gabarit littéral "(s)", cohérent avec le reste de la copie de cet
  /// écran (voir `CharacterSelectionActionBar`, même principe à plusieurs
  /// formes).
  String _partialDeleteMessage(
    AppLocalizations l10n,
    int succeededCount,
    int failedCount,
  ) {
    final succeededLabel = l10n.characterListDeleteSelectionSucceededLabel(
      succeededCount,
    );
    final failedLabel = l10n.characterListDeleteSelectionFailedLabel(
      failedCount,
    );
    return '$succeededLabel, $failedLabel.';
  }

  @override
  Widget build(BuildContext context) {
    // Retour Android depuis la liste racine : si des écritures hors-ligne
    // attendent encore d'être envoyées, confirmation avant de quitter
    // (T2 du chantier hors-ligne). Sans écriture en attente, le retour
    // quitte l'app normalement. Aucun équivalent iOS.
    final pendingCount = ref.watch(pendingWriteCountProvider()).value ?? 0;
    return PopScope(
      canPop: pendingCount == 0,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await showSyncExitDialog(
          context,
          pendingCount: pendingCount,
        );
        if (leave == true) await SystemNavigator.pop();
      },
      child: _buildList(context),
    );
  }

  Widget _buildList(BuildContext context) {
    final charactersAsync = ref.watch(charactersProvider);
    // Purge des horodatages « dernière ouverture » des personnages disparus, à
    // chaque chargement de la liste (P18).
    ref.listen(charactersProvider, (_, next) {
      final loaded = next.value;
      if (loaded != null) {
        unawaited(
          ref.read(characterLastOpenedProvider.notifier).purge({
            for (final c in loaded) c.id,
          }),
        );
      }
    });

    // Échec du chargement initial : écran dédié plein écran ("Connexion
    // impossible", recettage direction artistique du 13/09/2026 — voir
    // `widgets/connection_error_state.dart`), pas seulement la zone de liste
    // — l'en-tête "TES AVENTURIERS"/la barre de recherche n'ont aucun sens
    // tant qu'aucune donnée n'a pu être chargée. `hasError` reflète bien
    // l'état actuellement "actif" de l'`AsyncValue` (comme le ferait la
    // branche `error:` d'un `.when`) : un `ref.invalidate` déclenché par
    // [ConnectionErrorState.onRetry] fait immédiatement retomber l'état sur
    // `AsyncLoading`, donc quitter cet écran, avant toute nouvelle erreur
    // éventuelle.
    if (charactersAsync.hasError) {
      return ConnectionErrorState(
        onRetry: () => ref.invalidate(charactersProvider),
      );
    }

    final characters = charactersAsync.value;
    // Calculé une fois ici (plutôt que recalculé dans la branche `data:` du
    // `maybeWhen` ci-dessous) : `_SelectionModeButton` a besoin de connaître
    // la liste visible (après recherche/filtre) pour son état désactivé,
    // avant même d'atteindre la zone de contenu.
    final lastOpened = ref.watch(characterLastOpenedProvider);
    final visible = characters == null
        ? null
        : CharacterListSorter.sortBy(
            CharacterListFilter.apply(
              characters: characters,
              query: _searchController.text,
              classNames: _selectedClassNames,
              statuses: _selectedStatuses,
            ),
            _selectedSort,
            lastOpened,
          );

    final searchRow = _SearchRow(
      key: _searchRowKey,
      controller: _searchController,
      filterActive:
          _selectedClassNames.isNotEmpty ||
          _selectedStatuses.isNotEmpty ||
          _selectedSort != CharacterListSort.defaultOrder,
      // `null` (chargement) : bouton filtre sans effet, rien à filtrer tant
      // que la liste n'a pas résolu.
      onTapFilter: characters == null
          ? null
          : () => _openFilterSheet(characters),
      selectionMode: _selectionMode,
      // Désactivé tant que la liste charge ou que la liste visible est vide
      // (spec de la tâche) : rien à sélectionner dans les deux cas.
      onTapSelectionMode: (visible == null || visible.isEmpty)
          ? null
          : _enterSelectionMode,
    );

    final largeText = _isLargeText(context);

    return SceneScaffold(
      body: SafeArea(
        // Un seul défilement (refonte du 12/11/2026) : titre, bandeaux,
        // recherche et cartes défilent ensemble dans un unique
        // `CustomScrollView` ; seuls restent fixes le bandeau de synchro
        // (épinglé tant qu'il a quelque chose à dire), la recherche (épinglée
        // sauf police agrandie ou hauteur réduite) et le pied Créer/Importer.
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = math.max(
              AppSpacing.lg,
              (constraints.maxWidth - _readingWidth) / 2,
            );
            final compact = constraints.maxHeight < _compactHeight;
            final pinSearch = !largeText && !compact;
            return Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            side,
                            AppSpacing.md,
                            side,
                            AppSpacing.sm,
                          ),
                          child: const _Header(),
                        ),
                      ),
                      // Bandeau de synchro hors-ligne (T2 du chantier
                      // hors-ligne) : épinglé, hauteur nulle tant qu'il n'y a
                      // rien à dire. Total du compte.
                      PinnedHeaderSliver(
                        child: ColoredBox(
                          color: AppColors.woodDeepBgStart,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: side),
                            child: _SyncBand(
                              capHeight: largeText
                                  ? constraints.maxHeight *
                                        _syncBandMaxHeightFraction
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      // Bandeau "Mise à jour suggérée" : défile ; se réduit
                      // lui-même à `SizedBox.shrink()` tant qu'aucune mise à
                      // jour n'est suggérée (voir sa documentation).
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: side),
                          // Compact tant qu'une alerte de synchro est
                          // affichée (D211) ; la bannière ne lit pas l'état de
                          // synchro elle-même.
                          child: Consumer(
                            builder: (context, ref, _) => UpdateSuggestedBanner(
                              compact: ref.watch(
                                syncBannerProvider(
                                  characterId: null,
                                ).select((s) => s.kind == SyncBannerKind.alert),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (pinSearch)
                        PinnedHeaderSliver(
                          child: ColoredBox(
                            color: AppColors.woodDeepBgStart,
                            child: _searchPadding(side, searchRow),
                          ),
                        )
                      else
                        SliverToBoxAdapter(
                          child: _searchPadding(side, searchRow),
                        ),
                      // `maybeWhen` plutôt que `when` : l'erreur est déjà
                      // interceptée plus haut — seuls `data`/`loading`
                      // restent possibles ici.
                      ..._bodySlivers(
                        charactersAsync: charactersAsync,
                        characters: characters,
                        visible: visible,
                        side: side,
                      ),
                    ],
                  ),
                ),
                _buildFooter(
                  context,
                  characters: characters,
                  side: side,
                  availableHeight: constraints.maxHeight,
                  largeText: largeText,
                  compact: compact,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _searchPadding(double side, Widget child) => Padding(
    padding: EdgeInsets.fromLTRB(side, AppSpacing.sm, side, AppSpacing.md),
    child: child,
  );

  /// Corps de la liste : chargement, vide, « aucun résultat » (centrés dans
  /// l'espace restant) ou cartes.
  List<Widget> _bodySlivers({
    required AsyncValue<List<CharacterSummary>> charactersAsync,
    required List<CharacterSummary>? characters,
    required List<CharacterSummary>? visible,
    required double side,
  }) {
    return charactersAsync.maybeWhen(
      data: (_) {
        if (characters!.isNotEmpty && visible!.isEmpty) {
          return [
            _fillRemaining(
              side,
              _SearchEmptyState(
                query: _searchController.text.trim(),
                onReset: _resetSearch,
              ),
            ),
          ];
        }
        if (visible!.isEmpty) {
          return [_fillRemaining(side, const _EmptyState())];
        }
        return [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(side, 0, side, AppSpacing.lg),
            sliver: _CharacterSliverList(
              characters: visible,
              selectionMode: _selectionMode,
              selectedCharacterIds: _selectedCharacterIds,
              isDeletingSelection: _isDeletingSelection,
              onToggleSelected: _toggleCharacterSelected,
            ),
          ),
        ];
      },
      orElse: () => [
        _fillRemaining(
          side,
          const Center(
            child: CircularProgressIndicator(color: AppColors.goldEnd),
          ),
        ),
      ],
    );
  }

  /// Centre [child] dans l'espace restant de la zone de défilement (équivalent
  /// de `SliverFillRemaining(hasScrollBody: false)`, qui exige les dimensions
  /// intrinsèques de son enfant — or [SecondaryButton] contient un
  /// `LayoutBuilder` qui n'en fournit pas). Quand le contenu dépasse l'espace
  /// restant, il garde sa hauteur naturelle et le défilement unique prend le
  /// relais.
  Widget _fillRemaining(double side, Widget child) => SliverLayoutBuilder(
    builder: (context, constraints) => SliverToBoxAdapter(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: math.max(
            0,
            constraints.remainingPaintExtent - constraints.overlap,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: side - AppSpacing.lg),
          child: Center(child: child),
        ),
      ),
    ),
  );

  /// Pied fixe : « Créer » / « Importer » ou, en mode sélection, la barre
  /// d'actions. À police agrandie les boutons passent en colonne pleine
  /// largeur ; le pied est plafonné à [_footerMaxHeightFraction] de la hauteur
  /// avec défilement interne (seule exception au défilement unique).
  Widget _buildFooter(
    BuildContext context, {
    required List<CharacterSummary>? characters,
    required double side,
    required double availableHeight,
    required bool largeText,
    required bool compact,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final Widget content;
    if (_selectionMode) {
      content = CharacterSelectionActionBar(
        selectedCount: _selectedCharacterIds.length,
        isDeleting: _isDeletingSelection,
        onCancel: _exitSelectionMode,
        onDelete: _selectedCharacterIds.isEmpty
            ? null
            : () => _deleteSelectedCharacters(characters ?? []),
      );
    } else {
      // Le bouton "Rejoindre une histoire" (`_JoinStoryButton`, flux
      // `features/join_story/`) est volontairement masqué ici : cette
      // fonctionnalité est mise de côté le temps de terminer le reste du
      // recettage direction-artistique. Le flux et ses routes (`/join`,
      // `/join/step-2`, `/join/step-3`, `/join/:code`) restent en place dans
      // le code, simplement plus atteignables depuis l'UI.
      final create = PrimaryButton(
        label: l10n.characterListCreateButton,
        onPressed: () => _startCreation(context, ref),
      );
      final import = SecondaryButton(
        label: l10n.characterListImportXmlButton,
        onPressed: () => _startXmlImport(context),
      );
      content = largeText
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                create,
                const SizedBox(height: AppSpacing.sm),
                import,
              ],
            )
          : Row(
              children: [
                Expanded(child: create),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: import),
              ],
            );
    }
    final padding = EdgeInsets.fromLTRB(side, 0, side, AppSpacing.lg);
    if (largeText || compact) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: availableHeight * _footerMaxHeightFraction,
        ),
        child: ListView(
          key: const Key('characterListFooterScroll'),
          shrinkWrap: true,
          padding: padding,
          children: [content],
        ),
      );
    }
    return Padding(padding: padding, child: content);
  }

  /// Réinitialise le brouillon de création avant de démarrer l'assistant.
  ///
  /// Le brouillon (`character_creation_draft_provider.dart`) est
  /// volontairement `keepAlive` pour survivre à la navigation entre les
  /// étapes d'une même session de création : sans ce `reset()` explicite,
  /// une création abandonnée en cours de route (retour à cette liste sans
  /// avoir atteint l'étape 9) laisserait ses choix en mémoire et serait
  /// reprise silencieusement à la prochaine tentative de "+ Créer".
  void _startCreation(BuildContext context, WidgetRef ref) {
    ref.read(characterCreationDraftControllerProvider.notifier).reset();
    // Une modification de personnage abandonnée sans passer par « Annuler »
    // ne doit jamais faire passer cette création en mode modification.
    ref.read(characterEditSessionControllerProvider.notifier).clear();
    // Filet de sécurité : efface toute route de retour laissée par une
    // session "Rejoindre une histoire" abandonnée avant l'étape 9 (voir la
    // documentation de classe de `CharacterCreationReturnRouteController`) —
    // une création normale lancée depuis cet écran doit toujours atterrir
    // sur `/` une fois terminée, jamais reprendre un retour paramétré d'une
    // tentative précédente.
    ref.read(characterCreationReturnRouteControllerProvider.notifier).set(null);
    context.push('/characters/new/edition');
  }

  /// Ouvre le sélecteur de fichier natif (`file_picker`, seul package du
  /// dépôt capable de choisir un fichier arbitraire — `image_picker` ne gère
  /// que les images), lit le contenu du `.xml` choisi puis pousse l'écran de
  /// vérification (`features/xml_import/presentation/xml_import_review_screen.dart`),
  /// qui porte lui-même le parsing/la résolution (état "Chargement" de sa
  /// spec visuelle) — voir la documentation de la route `/characters/import`
  /// (`core/router/app_router.dart`) pour le choix de lui passer le contenu
  /// déjà lu via `extra` plutôt que de reparser ici.
  ///
  /// `withData: true` : demande à `file_picker` de charger le contenu en
  /// mémoire (`PlatformFile.bytes`) plutôt que de ne renvoyer qu'un chemin de
  /// fichier (`PlatformFile.path`, non disponible sur web) — un export
  /// aidedd.org est un petit fichier texte, charger tout son contenu en
  /// mémoire d'un coup est un compromis sûr ici.
  Future<void> _startXmlImport(BuildContext context) async {
    PlatformFile? file;
    Uint8List bytes;
    try {
      file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['xml'],
      );
      // `file == null` : sélection annulée par l'utilisateur, rien à faire.
      if (file == null) return;
      bytes = await file.readAsBytes();
    } catch (_) {
      if (!context.mounted) return;
      _showImportError(context);
      return;
    }

    final String xmlSource;
    try {
      xmlSource = utf8.decode(bytes);
    } catch (_) {
      if (!context.mounted) return;
      _showImportError(context);
      return;
    }

    if (!context.mounted) return;
    context.push<void>(
      '/characters/import',
      extra: (fileName: file.name, xmlSource: xmlSource),
    );
  }

  void _showImportError(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.characterListImportErrorMessage)),
    );
  }
}

/// Bandeau de synchro épinglé. Hauteur nulle tant qu'il n'y a rien à dire
/// ([SyncStatusBanner] se réduit alors à une boîte vide). À police agrandie
/// ([capHeight] non nul) et bandeau actif, sa hauteur est plafonnée avec
/// défilement interne pour ne jamais manger la zone de défilement principale.
///
/// `ConsumerWidget` : seul ce sliver observe l'état du bandeau, un changement
/// de synchro ne reconstruit donc pas tout l'écran.
class _SyncBand extends ConsumerWidget {
  const _SyncBand({required this.capHeight});

  final double? capHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active =
        ref.watch(syncBannerProvider(characterId: null)).kind !=
        SyncBannerKind.none;
    const banner = SyncStatusBanner(
      visiblePadding: EdgeInsets.only(bottom: AppSpacing.sm),
    );
    if (capHeight == null || !active) return banner;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: capHeight!),
      child: ListView(
        key: const Key('characterListSyncBandScroll'),
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        children: const [banner],
      ),
    );
  }
}

/// En-tête « TES AVENTURIERS » + boutons groupes/profil (44×44).
///
/// D174 : sur une ligne tant que le plus long mot du titre tient à côté des
/// deux boutons ; sinon le titre passe sur sa propre ligne (pleine largeur) et
/// les boutons descendent dessous, alignés à droite — rien n'est jamais
/// poussé hors de l'écran ni coupé. Le titre est plafonné à x1,3
/// ([DisplayText], palier `title`), la mesure en tient compte.
class _Header extends StatelessWidget {
  const _Header();

  static const double _buttonsWidth = 44 * 2 + AppSpacing.sm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = l10n.characterListHeaderTitle;
    // Le style est passé directement à `DisplayText` (garde de plafonnement
    // de la police pixel) puis relu pour la mesure ci-dessous.
    final titleWidget = DisplayText(
      title,
      style: AppTypography.display(fontSize: 15, color: AppColors.textOnWood),
    );
    final style = titleWidget.style;
    const buttons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GroupsButton(),
        SizedBox(width: AppSpacing.sm),
        _ProfileButton(),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaler = MediaQuery.textScalerOf(context)
            .clamp(maxScaleFactor: DisplayTier.title.maxScaleFactor);
        var longestWord = 0.0;
        for (final word in title.split(RegExp(r'\s+'))) {
          if (word.isEmpty) continue;
          final painter = TextPainter(
            text: TextSpan(text: word, style: style),
            textDirection: Directionality.of(context),
            textScaler: scaler,
          )..layout();
          longestWord = math.max(longestWord, painter.width);
          painter.dispose();
        }
        final fitsBesideButtons =
            longestWord + AppSpacing.sm + _buttonsWidth <= constraints.maxWidth;
        if (fitsBesideButtons) {
          return Row(
            children: [
              // `Expanded` : le titre passe à la ligne au lieu de pousser
              // les boutons hors de l'écran.
              Expanded(child: titleWidget),
              const SizedBox(width: AppSpacing.sm),
              buttons,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            titleWidget,
            const SizedBox(height: AppSpacing.sm),
            const Align(alignment: Alignment.centerRight, child: buttons),
          ],
        );
      },
    );
  }
}

/// Barre de recherche + icône filtre, sous l'en-tête — voir
/// `docs/cahier-des-charges/11-fonctionnalites-a-ajouter.md` section 2 et la
/// maquette "Liste des personnages" (`09-maquettes-captures.md`).
///
/// Champ de recherche `TextField` nu (pas de `TextFormField`/validation,
/// aucun champ de ce dépôt n'a jamais besoin d'être validé pour une simple
/// recherche) : l'habillage (fond `parchment.card`, bordure `wood.light`)
/// vient entièrement de `AppTheme.light.inputDecorationTheme`, comme pour
/// tous les autres champs de ce dépôt — aucun style en dur ici.
class _SearchRow extends StatelessWidget {
  const _SearchRow({
    super.key,
    required this.controller,
    required this.filterActive,
    required this.onTapFilter,
    required this.selectionMode,
    required this.onTapSelectionMode,
  });

  final TextEditingController controller;

  /// `true` si au moins une classe ou un statut est actuellement filtré —
  /// affiche un point doré sur l'icône entonnoir (rappel visuel qu'un filtre
  /// est actif, même si la sheet n'est pas ouverte).
  final bool filterActive;

  final VoidCallback? onTapFilter;

  /// `true` pendant le mode sélection multiple : masque [_FilterButton] et
  /// [_SelectionModeButton] (pas de bouton "Annuler" ici, il vit dans
  /// `CharacterSelectionActionBar` en pied d'écran), le champ de recherche
  /// prend alors toute la largeur.
  final bool selectionMode;

  /// `null` désactive [_SelectionModeButton] (liste en chargement ou liste
  /// visible vide) — sans effet si [selectionMode] est déjà `true`.
  final VoidCallback? onTapSelectionMode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: AppTypography.body(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: l10n.characterListSearchHint,
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: l10n.characterListSearchClearTooltip,
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: controller.clear,
                    ),
            ),
          ),
        ),
        if (!selectionMode) ...[
          const SizedBox(width: AppSpacing.sm),
          _FilterButton(active: filterActive, onTap: onTapFilter),
          const SizedBox(width: AppSpacing.sm),
          _SelectionModeButton(onTap: onTapSelectionMode),
        ],
      ],
    );
  }
}

/// Bouton de filtre 44×44 de la barre de recherche.
///
/// Sans texte visible : son nom d'accessibilité vient du [Semantics] qui
/// l'enveloppe, fusionné avec l'action de tap de l'[InkWell] en un seul nœud
/// de rôle bouton ("Filtrer les personnages", valeur "Filtre actif" quand
/// [active], désactivé quand [onTap] est `null`). Pas de `Tooltip` : sur
/// mobile il n'apparaît qu'à l'appui long et n'apporte rien de plus que le
/// libellé sémantique (choix validé par direction-artistique).
class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: l10n.characterListFilterButtonLabel,
      value: active ? l10n.characterListFilterButtonActiveValue : null,
      child: Material(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: onTap,
          // Pas d'`alignment` sur ce `Container` : la `Stack` doit recevoir
          // des contraintes strictes et occuper tout l'intérieur du bouton
          // (40×40 une fois la bordure de 2 px déduite). Réduite à la taille
          // de l'icône (24×24), elle ferait se résoudre le `Positioned` de la
          // pastille contre l'icône au lieu du coin du bouton.
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: AppColors.woodLight,
                width: AppBorders.card,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.filter_list, color: AppColors.textSecondary),
                // Centre de la pastille en (34, 10) dans le repère 44×44 du
                // bouton, soit `top: 3, right: 3` dans l'intérieur 40×40 :
                // coin supérieur droit, tangente au pictogramme.
                if (active)
                  const Positioned(top: 3, right: 3, child: _FilterActiveDot()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pastille "filtre actif" : disque `gold-end` de 8 px cerclé d'un liseré
/// `wood.dark` de 1 px (diamètre hors tout 10 px), pour rester lisible sur
/// le fond `parchment.card` du bouton. Purement décorative : l'état est
/// porté par la valeur sémantique de [_FilterButton].
class _FilterActiveDot extends StatelessWidget {
  const _FilterActiveDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: AppColors.goldEnd,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.woodDark,
          width: AppBorders.cardEmphasisHalo,
        ),
      ),
    );
  }
}

/// Bouton d'entrée en mode sélection multiple, 44×44, calque exact de
/// [_FilterButton] (même fond/bordure/rayon) — icône `Icons.checklist` au
/// lieu de l'entonnoir, jamais de pastille d'état (contrairement à
/// [_FilterButton], ce bouton n'a pas d'état "actif" propre : une fois tapé,
/// il disparaît avec le reste de `_SearchRow` au profit du mode sélection).
class _SelectionModeButton extends StatelessWidget {
  const _SelectionModeButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: l10n.characterListSelectionModeButtonLabel,
      child: Material(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: AppColors.woodLight,
                width: AppBorders.card,
              ),
            ),
            child: const Icon(
              Icons.checklist,
              size: 24,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Icône groupes ronde en haut à droite (`Icons.groups_outlined`), à côté du
/// bouton profil — voir `docs/cahier-des-charges/12-partage-et-groupes.md`
/// section 2 : point d'entrée du système de groupe. Navigue TOUJOURS vers
/// l'écran "Groupes" (`/groups`, `GroupListScreen`), quel que soit le nombre
/// de groupes dont le joueur est déjà membre — cet écran liste les groupes
/// rejoints et propose toujours "Créer"/"Rejoindre", pour qu'un joueur déjà
/// membre d'un groupe puisse en rejoindre/créer un second sans y être
/// bloqué (l'ancien comportement naviguait directement dans l'unique groupe
/// existant dès que le joueur en avait exactement 1, sans jamais lui laisser
/// cette possibilité).
class _GroupsButton extends StatelessWidget {
  const _GroupsButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => context.push('/groups'),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.woodLight,
              width: AppBorders.card,
            ),
          ),
          child: const Icon(
            Icons.groups_outlined,
            color: AppColors.textOnWoodMuted,
            size: 22,
          ),
        ),
      ),
    );
  }
}

/// Icône profil ronde en haut à droite : navigue vers l'écran "Profil"
/// (`features/profile/presentation/profile_screen.dart`, route `/profile`)
/// — remplace l'ancien menu minimal réduit à "Se déconnecter" (pas d'écran
/// de profil complet à l'époque, voir l'historique git de ce fichier). Le
/// bouton "Se déconnecter" vit désormais sur cet écran, toujours via
/// `authRepositoryProvider.signOut()`.
class _ProfileButton extends StatelessWidget {
  const _ProfileButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => context.push('/profile'),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.woodLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_outline,
            color: AppColors.textOnWood,
            size: 22,
          ),
        ),
      ),
    );
  }
}

/// `ConsumerWidget` (plutôt que `StatelessWidget`, comportement historique)
/// : le clic long hors mode sélection ouvre `showCharacterCardActionSheet`,
/// qui a besoin d'un [WidgetRef] pour appeler `characterRepositoryProvider`
/// (archiver/marquer mort/supprimer) — voir sa documentation de classe.
class _CharacterSliverList extends ConsumerWidget {
  const _CharacterSliverList({
    required this.characters,
    required this.selectionMode,
    required this.selectedCharacterIds,
    required this.isDeletingSelection,
    required this.onToggleSelected,
  });

  final List<CharacterSummary> characters;
  final bool selectionMode;
  final Set<String> selectedCharacterIds;

  /// `true` pendant `_CharacterListScreenState._deleteSelectedCharacters`
  /// (dette technique D89, registre `docs/dette-technique.md`) : désactive
  /// le tap/clic long de bascule de sélection sur chaque carte tant qu'une
  /// suppression groupée est en cours, pour qu'un changement de sélection
  /// fait pendant l'attente réseau ne soit plus silencieusement écrasé par
  /// le `setState(() { _selectedCharacterIds = failedIds; })` final. Les
  /// boutons "Annuler"/"Supprimer" de `CharacterSelectionActionBar` sont
  /// déjà protégés indépendamment (`isDeleting`).
  final bool isDeletingSelection;
  final ValueChanged<String> onToggleSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverList.separated(
      itemCount: characters.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final character = characters[index];
        // En mode sélection, le clic long est identique au tap (bascule la
        // sélection) et n'ouvre jamais la sheet d'actions — spec de la
        // tâche, voir la documentation de classe de
        // `CharacterCard.onLongPress`. `null` pendant une suppression
        // groupée en cours ([isDeletingSelection]) plutôt que la bascule de
        // sélection habituelle — voir sa documentation.
        final onTap = selectionMode
            ? (isDeletingSelection
                  ? null
                  : () => onToggleSelected(character.id))
            : () => context.push(
                '/characters/${character.id}',
                extra: character.name,
              );
        return CharacterCard(
          character: character,
          onTap: onTap,
          onLongPress: selectionMode
              ? onTap
              : () => showCharacterCardActionSheet(
                  context,
                  ref,
                  character: character,
                ),
          selectionMode: selectionMode,
          selected: selectedCharacterIds.contains(character.id),
        );
      },
    );
  }
}

/// État "recherche sans résultat" — distinct de [_EmptyState] (liste
/// réellement vide côté serveur) : au moins un personnage existe, mais
/// aucun ne correspond à la recherche/au filtre de classe actuellement actif
/// (voir `character_list_screen.dart::build`). Copie exacte de
/// `docs/cahier-des-charges/16-textes-a-rediger.md` section 5 pour le cas
/// [query] non vide ; variante générique si seul un filtre de classe est
/// actif (aucune copie dédiée à ce sous-cas dans le cahier des charges, qui
/// ne documente que la recherche textuelle).
class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState({required this.query, required this.onReset});

  final String query;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 88,
              height: 88,
              child: CustomPaint(
                painter: const DashedBorderPainter(
                  color: AppColors.textOnWoodMuted,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.search, size: 40, color: AppColors.goldEnd),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DisplayText(
              query.isEmpty
                  ? l10n.characterListSearchEmptyTitleNoQuery
                  : l10n.characterListSearchEmptyTitleWithQuery(
                      query.toUpperCase(),
                    ),
              textAlign: TextAlign.center,
              style: AppTypography.display(
                fontSize: 11,
                color: AppColors.textOnWood,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              query.isEmpty
                  ? l10n.characterListSearchEmptyBodyNoQuery
                  : l10n.characterListSearchEmptyBodyWithQuery,
              textAlign: TextAlign.center,
              style: AppTypography.body(color: AppColors.textOnWoodMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: SecondaryButton(
                label: l10n.characterListSearchEmptyResetButton,
                onPressed: onReset,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// État vide (aucun personnage) — copie et icône alignées sur la maquette
/// `docs/cahier-des-charges/09-maquettes-captures.md`, section "État vide —
/// Liste de personnages" (absente du cahier des charges d'origine au moment
/// où cet écran a été introduit, ajoutée depuis).
///
/// Icône `Icons.explore_outlined` en `AppColors.accentTeal` (recettage
/// direction-artistique du 13/09, décision validée par le chef de projet) —
/// remplace l'ancien `Icons.shield_moon_outlined`/`AppColors.goldEnd`, moins
/// aligné avec le thème "carte/exploration" de la maquette. Voir aussi
/// [_SearchEmptyState], qui garde `Icons.search`/`AppColors.goldEnd` (non
/// concerné par ce changement).
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Hébergé dans un `SliverFillRemaining(hasScrollBody: false)` (voir
    // `_bodySlivers`) : centré dans l'espace restant quand tout rentre, et le
    // défilement unique de la liste prend le relais sinon (F06) — plus de
    // `SingleChildScrollView`/`LayoutBuilder` propre à cet état.
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 88,
              height: 88,
              child: CustomPaint(
                painter: const DashedBorderPainter(
                  color: AppColors.textOnWoodMuted,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.explore_outlined,
                    size: 40,
                    color: AppColors.accentTeal,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DisplayText(
              l10n.characterListEmptyTitle,
              textAlign: TextAlign.center,
              style: AppTypography.display(
                fontSize: 11,
                color: AppColors.textOnWood,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              // "ou rejoins l'histoire d'un ami" volontairement retiré : voir
              // le commentaire sur le masquage du bouton "Rejoindre une
              // histoire" plus haut dans ce fichier (`_buildFooter`).
              l10n.characterListEmptyBody,
              textAlign: TextAlign.center,
              style: AppTypography.body(color: AppColors.textOnWoodMuted),
            ),
          ],
        ),
      ),
    );
  }
}
