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
import '../../character_creation/presentation/providers/character_creation_draft_provider.dart';
import '../../character_creation/presentation/providers/character_creation_return_route_provider.dart';
import '../../groups/domain/group_summary.dart';
import '../../groups/presentation/providers/group_providers.dart';
import '../../groups/presentation/widgets/group_entry_sheet.dart';
import '../domain/character_failure.dart';
import '../domain/character_list_filter.dart';
import '../domain/character_summary.dart';
import 'providers/character_providers.dart';
import 'widgets/character_card.dart';
import 'widgets/character_class_filter_sheet.dart';

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
    });
  }

  Future<void> _openClassFilterSheet(List<CharacterSummary> characters) async {
    final result = await showCharacterClassFilterSheet(
      context,
      availableClassNames: CharacterListFilter.distinctClassNames(characters),
      selectedClassNames: _selectedClassNames,
    );
    if (result == null || !mounted) return;
    setState(() => _selectedClassNames = result);
  }

  /// Appelé par le [RouteObserver] quand une route poussée par-dessus cet
  /// écran est dépilée et que celui-ci redevient visible — voir la
  /// documentation de classe de [CharacterListScreen].
  @override
  void didPopNext() {
    ref.invalidate(charactersProvider);
  }

  @override
  Widget build(BuildContext context) {
    final charactersAsync = ref.watch(charactersProvider);

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
                  _SearchRow(
                    controller: _searchController,
                    filterActive: _selectedClassNames.isNotEmpty,
                    // `null` (chargement/erreur) : bouton filtre sans effet,
                    // rien à filtrer tant que la liste n'a pas résolu.
                    onTapFilter: charactersAsync.value == null
                        ? null
                        : () => _openClassFilterSheet(charactersAsync.value!),
                  ),
                ],
              ),
            ),
            Expanded(
              child: charactersAsync.when(
                data: (characters) {
                  final visible = CharacterListFilter.apply(
                    characters: characters,
                    query: _searchController.text,
                    classNames: _selectedClassNames,
                  );
                  if (characters.isNotEmpty && visible.isEmpty) {
                    return _SearchEmptyState(
                      query: _searchController.text.trim(),
                      onReset: _resetSearch,
                    );
                  }
                  return _CharacterList(characters: visible);
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.goldEnd),
                ),
                error: (error, stackTrace) => _ErrorState(
                  message: error is CharacterFailure
                      ? error.message
                      : 'Impossible de charger vos personnages. Réessayez.',
                  onRetry: () => ref.invalidate(charactersProvider),
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
              child: Column(
                children: [
                  Row(
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
                  const SizedBox(height: AppSpacing.sm),
                  _JoinStoryButton(onPressed: () => _startJoinStory(context)),
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
    // Filet de sécurité : efface toute route de retour laissée par une
    // session "Rejoindre une histoire" abandonnée avant l'étape 9 (voir la
    // documentation de classe de `CharacterCreationReturnRouteController`) —
    // une création normale lancée depuis cet écran doit toujours atterrir
    // sur `/` une fois terminée, jamais reprendre un retour paramétré d'une
    // tentative précédente.
    ref.read(characterCreationReturnRouteControllerProvider.notifier).set(null);
    context.push('/characters/new');
  }

  /// Démarre le flux "Rejoindre une histoire" (`features/join_story/`) —
  /// voir `docs/cahier-des-charges/04-fonctionnalites-app-mobile.md`
  /// section 7.1.
  void _startJoinStory(BuildContext context) {
    context.push('/join');
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

/// Bouton "Rejoindre une histoire" pleine largeur, bordure pointillée (voir
/// maquette `docs/cahier-des-charges/09-maquettes-captures.md`, section
/// "Liste des personnages") — distinct des boutons `PrimaryButton`/
/// `SecondaryButton` du design système (aucun n'a de variante pointillée),
/// scopé à cet écran tant qu'aucun autre écran n'a besoin du même style.
class _JoinStoryButton extends StatelessWidget {
  const _JoinStoryButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const DashedBorderPainter(color: AppColors.woodLight),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onPressed,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.login, size: 16, color: AppColors.textOnWood),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'REJOINDRE UNE HISTOIRE',
                  style: AppTypography.display(
                    fontSize: 11,
                    color: AppColors.textOnWood,
                  ),
                ),
              ],
            ),
          ),
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
            _ProfileButton(),
            SizedBox(width: AppSpacing.sm),
            _GroupsButton(),
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
  });

  final TextEditingController controller;

  /// `true` si au moins une classe est actuellement filtrée — affiche un
  /// point doré sur l'icône entonnoir (rappel visuel qu'un filtre est actif,
  /// même si la sheet n'est pas ouverte).
  final bool filterActive;

  final VoidCallback? onTapFilter;

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
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textMuted,
              ),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Effacer',
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.textMuted,
                      ),
                      onPressed: controller.clear,
                    ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _FilterButton(active: filterActive, onTap: onTapFilter),
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.parchmentCard,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: AppColors.woodLight,
              width: AppBorders.card,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.filter_list, color: AppColors.textSecondary),
              if (active)
                const Positioned(
                  top: 6,
                  right: 6,
                  child: _FilterActiveDot(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterActiveDot extends StatelessWidget {
  const _FilterActiveDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.goldEnd,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Icône groupes ronde en haut à droite (`Icons.groups_outlined`), à côté du
/// bouton profil — voir `docs/cahier-des-charges/12-partage-et-groupes.md`
/// section 2 : point d'entrée du système de groupe, comportement au tap
/// selon le nombre de groupes dont le joueur est membre (un joueur peut être
/// membre de plusieurs groupes simultanément, avec des personnages
/// différents) :
/// - 0 groupe -> sheet "GROUPE" ([showGroupEntrySheet]) ;
/// - 1 groupe -> navigue directement vers l'écran "Groupe" de ce groupe ;
/// - 2+ groupes -> sheet listant les groupes ([showGroupListSheet]) avant
///   navigation.
///
/// `ConsumerStatefulWidget` (plutôt qu'un simple tap synchrone comme
/// `_ProfileButton`) : la décision ci-dessus dépend d'un appel réseau
/// (`myGroupsProvider`), qui n'a pas vocation à être précalculé en
/// permanence en arrière-plan pour un bouton qui peut ne jamais être
/// pressé — l'état [_isLoading] affiche un petit indicateur à la place de
/// l'icône le temps de cet appel.
class _GroupsButton extends ConsumerStatefulWidget {
  const _GroupsButton();

  @override
  ConsumerState<_GroupsButton> createState() => _GroupsButtonState();
}

class _GroupsButtonState extends ConsumerState<_GroupsButton> {
  bool _isLoading = false;

  Future<void> _handleTap() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    // [_isLoading] ne couvre volontairement QUE l'appel réseau
    // (`myGroupsProvider`), jamais l'ouverture d'une sheet ensuite : une
    // sheet peut rester ouverte indéfiniment tant que le joueur n'a pas agi
    // (aucun bug en soi), mais le petit spinner de ce bouton (voir [build])
    // est un indicateur *indéterminé* — le laisser actif pendant qu'une
    // sheet reste ouverte empêcherait à tort tout `pumpAndSettle` de se
    // terminer dans les tests, et n'aurait de toute façon aucun sens
    // visuel une fois la sheet affichée.
    final List<GroupSummary> groups;
    try {
      groups = await ref.read(myGroupsProvider.future);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de charger vos groupes. Réessayez.'),
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (groups.isEmpty) {
      final action = await showGroupEntrySheet(context);
      if (action == null || !mounted) return;
      switch (action) {
        case GroupEntryAction.create:
          context.push('/groups/new');
        case GroupEntryAction.join:
          context.push('/groups/join');
      }
    } else if (groups.length == 1) {
      context.push('/groups/${groups.first.id}');
    } else {
      final selectedId = await showGroupListSheet(context, groups);
      if (selectedId == null || !mounted) return;
      context.push('/groups/$selectedId');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _handleTap,
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
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textOnWood,
                  ),
                )
              : const Icon(
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

class _CharacterList extends StatelessWidget {
  const _CharacterList({required this.characters});

  final List<CharacterSummary> characters;

  @override
  Widget build(BuildContext context) {
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
        return CharacterCard(
          character: character,
          onTap: () => context.push(
            '/characters/${character.id}',
            extra: character.name,
          ),
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
            Container(
              width: 88,
              height: 88,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                  BorderSide(color: AppColors.textOnWoodMuted, width: 1.5),
                ),
              ),
              child: const Icon(
                Icons.search,
                size: 40,
                color: AppColors.goldEnd,
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
              child: SecondaryButton(label: 'Réinitialiser', onPressed: onReset),
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
            Container(
              width: 88,
              height: 88,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                  BorderSide(color: AppColors.textOnWoodMuted, width: 1.5),
                ),
              ),
              child: const Icon(
                Icons.shield_moon_outlined,
                size: 40,
                color: AppColors.goldEnd,
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
              "Crée ton premier personnage, importe-le depuis aidedd.org, "
              "ou rejoins l'histoire d'un ami pour commencer l'aventure.",
              textAlign: TextAlign.center,
              style: AppTypography.body(color: AppColors.textOnWoodMuted),
            ),
          ],
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
              style: AppTypography.body(color: AppColors.textOnWood),
            ),
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(label: 'Réessayer', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
