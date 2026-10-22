import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_observer_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/dashed_border_painter.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/scene_scaffold.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../app_update/presentation/widgets/update_suggested_banner.dart';
import '../../character_creation/presentation/providers/character_creation_draft_provider.dart';
import '../../character_creation/presentation/providers/character_edit_session_provider.dart';
import '../../character_creation/presentation/providers/character_creation_return_route_provider.dart';
import '../domain/character_failure.dart';
import '../domain/character_list_filter.dart';
import '../domain/character_status_filter.dart';
import '../domain/character_summary.dart';
import '../domain/write_outcome.dart';
import 'providers/character_providers.dart';
import 'widgets/character_card.dart';
import 'widgets/character_card_action_sheet.dart';
import 'widgets/character_delete_confirmation.dart';
import 'widgets/character_list_filter_sheet.dart';
import 'widgets/character_selection_action_bar.dart';
import 'widgets/character_write_feedback.dart';
import 'widgets/connection_error_state.dart';

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
  Set<String> _selectedClassNames = {};
  Set<CharacterStatusFilter> _selectedStatuses = {};

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
    );
    if (result == null || !mounted) return;
    setState(() {
      _selectedClassNames = result.classNames;
      _selectedStatuses = result.statuses;
    });
  }

  /// Appelé par le [RouteObserver] quand une route poussée par-dessus cet
  /// écran est dépilée et que celui-ci redevient visible — voir la
  /// documentation de classe de [CharacterListScreen].
  @override
  void didPopNext() {
    ref.invalidate(charactersProvider);
  }

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
        if (outcome == WriteOutcome.queued) {
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
            ? offlineNotPersistedMessage
            : 'Impossible de supprimer les personnages sélectionnés. '
                  'Réessayez.',
      );
      return;
    }

    _showSnackBar(_partialDeleteMessage(succeededCount, failedIds.length));
  }

  /// "X personnage(s) supprimé(s), Y n'a/n'ont pas pu être supprimé(s)."
  /// (spec de la tâche) — accords au singulier/pluriel plutôt qu'un gabarit
  /// littéral "(s)", cohérent avec le reste de la copie de cet écran (voir
  /// `CharacterSelectionActionBar._selectionCountLabel`, même principe à
  /// trois formes).
  String _partialDeleteMessage(int succeededCount, int failedCount) {
    final succeededLabel = succeededCount == 1
        ? '1 personnage supprimé'
        : '$succeededCount personnages supprimés';
    final failedLabel = failedCount == 1
        ? "1 personnage n'a pas pu être supprimé"
        : "$failedCount personnages n'ont pas pu être supprimés";
    return '$succeededLabel, $failedLabel.';
  }

  @override
  Widget build(BuildContext context) {
    final charactersAsync = ref.watch(charactersProvider);

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
    final visible = characters == null
        ? null
        : CharacterListFilter.apply(
            characters: characters,
            query: _searchController.text,
            classNames: _selectedClassNames,
            statuses: _selectedStatuses,
          );

    return SceneScaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Column(
                children: [
                  const _Header(),
                  const SizedBox(height: AppSpacing.sm),
                  // Bandeau "Mise à jour suggérée" (recettage
                  // direction-artistique du 13/09/2026) — inséré
                  // inconditionnellement : le widget se réduit lui-même à
                  // `SizedBox.shrink()` tant qu'aucune mise à jour n'est
                  // suggérée ou que sa version a déjà été refermée, voir sa
                  // documentation de classe.
                  const UpdateSuggestedBanner(),
                  _SearchRow(
                    controller: _searchController,
                    filterActive:
                        _selectedClassNames.isNotEmpty ||
                        _selectedStatuses.isNotEmpty,
                    // `null` (chargement) : bouton filtre sans effet, rien à
                    // filtrer tant que la liste n'a pas résolu.
                    onTapFilter: characters == null
                        ? null
                        : () => _openFilterSheet(characters),
                    selectionMode: _selectionMode,
                    // Désactivé tant que la liste charge ou que la liste
                    // visible est vide (spec de la tâche) : rien à
                    // sélectionner dans les deux cas.
                    onTapSelectionMode: (visible == null || visible.isEmpty)
                        ? null
                        : _enterSelectionMode,
                  ),
                ],
              ),
            ),
            Expanded(
              // `maybeWhen` plutôt que `when` : l'erreur est déjà interceptée
              // plus haut par le retour anticipé sur `charactersAsync.hasError`
              // — seuls `data`/`loading` restent possibles ici.
              child: charactersAsync.maybeWhen(
                data: (_) {
                  if (characters!.isNotEmpty && visible!.isEmpty) {
                    return _SearchEmptyState(
                      query: _searchController.text.trim(),
                      onReset: _resetSearch,
                    );
                  }
                  return _CharacterList(
                    characters: visible!,
                    selectionMode: _selectionMode,
                    selectedCharacterIds: _selectedCharacterIds,
                    isDeletingSelection: _isDeletingSelection,
                    onToggleSelected: _toggleCharacterSelected,
                  );
                },
                orElse: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.goldEnd),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: _selectionMode
                  ? CharacterSelectionActionBar(
                      selectedCount: _selectedCharacterIds.length,
                      isDeleting: _isDeletingSelection,
                      onCancel: _exitSelectionMode,
                      onDelete: _selectedCharacterIds.isEmpty
                          ? null
                          : () => _deleteSelectedCharacters(characters ?? []),
                    )
                  // Le bouton "Rejoindre une histoire" (`_JoinStoryButton`,
                  // flux `features/join_story/`) est volontairement masqué
                  // ici : cette fonctionnalité est mise de côté le temps de
                  // terminer le reste du recettage direction-artistique
                  // (section non encore traitée). Le flux et ses routes
                  // (`/join`, `/join/step-2`, `/join/step-3`, `/join/:code`)
                  // restent en place dans le code, simplement plus
                  // atteignables depuis l'UI — aucune configuration native
                  // de deep link n'est de toute façon encore branchée pour
                  // `/join/:code` (voir `app_router.dart`), donc ce retrait
                  // masque bien intégralement la fonctionnalité pour
                  // l'instant.
                  : Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            label: '+ Créer',
                            onPressed: () => _startCreation(context, ref),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: SecondaryButton(
                            label: 'Importer XML',
                            onPressed: () => _startXmlImport(context),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Impossible de lire ce fichier. Vérifiez qu'il s'agit bien d'un "
          'export XML aidedd.org.',
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'TES AVENTURIERS',
          style: AppTypography.display(
            fontSize: 15,
            color: AppColors.textOnWood,
          ),
        ),
        const Row(
          children: [
            _GroupsButton(),
            SizedBox(width: AppSpacing.sm),
            _ProfileButton(),
          ],
        ),
      ],
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
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: AppTypography.body(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Rechercher un personnage',
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Effacer',
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
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: 'Filtrer les personnages',
      value: active ? 'Filtre actif' : null,
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
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: 'Sélectionner plusieurs personnages',
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
class _CharacterList extends ConsumerWidget {
  const _CharacterList({
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
    if (characters.isEmpty) {
      return const _EmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
            Text(
              query.isEmpty
                  ? 'AUCUN RÉSULTAT'
                  : 'AUCUN RÉSULTAT POUR « ${query.toUpperCase()} »',
              textAlign: TextAlign.center,
              style: AppTypography.display(
                fontSize: 11,
                color: AppColors.textOnWood,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              query.isEmpty
                  ? "Aucun personnage ne correspond à ce filtre. Réinitialise "
                        'pour retrouver tous tes personnages.'
                  : "Vérifie l'orthographe, ou réinitialise la recherche pour "
                        'retrouver tous tes personnages.',
              textAlign: TextAlign.center,
              style: AppTypography.body(color: AppColors.textOnWoodMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: SecondaryButton(
                label: 'Réinitialiser',
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
            Text(
              'AUCUN AVENTURIER POUR L\'INSTANT',
              textAlign: TextAlign.center,
              style: AppTypography.display(
                fontSize: 11,
                color: AppColors.textOnWood,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              // "ou rejoins l'histoire d'un ami" volontairement retiré :
              // voir le commentaire sur le masquage du bouton "Rejoindre
              // une histoire" plus haut dans ce fichier (`build`).
              'Crée ton premier personnage, ou importe-le depuis aidedd.org, '
              'pour commencer l\'aventure.',
              textAlign: TextAlign.center,
              style: AppTypography.body(color: AppColors.textOnWoodMuted),
            ),
          ],
        ),
      ),
    );
  }
}
