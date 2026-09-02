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
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/scene_scaffold.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../character_creation/presentation/providers/character_creation_draft_provider.dart';
import '../../character_creation/presentation/providers/character_creation_return_route_provider.dart';
import '../domain/character_failure.dart';
import '../domain/character_summary.dart';
import 'providers/character_providers.dart';
import 'widgets/character_card.dart';

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
    super.dispose();
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
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: _Header(),
            ),
            Expanded(
              child: charactersAsync.when(
                data: (characters) => _CharacterList(characters: characters),
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
                  PrimaryButton(
                    label: '+ Créer',
                    onPressed: () => _startCreation(context, ref),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          label: 'Importer XML',
                          onPressed: () => _startXmlImport(context),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Tooltip(
                          // Bouton compact ("Rejoindre" seul) : le libellé
                          // complet reste disponible pour les lecteurs
                          // d'écran (et en tooltip visuel à l'appui long) —
                          // voir la spec de la tâche.
                          message: 'Rejoindre une histoire',
                          child: SecondaryButton(
                            label: 'Rejoindre',
                            onPressed: () => _startJoinStory(context),
                          ),
                        ),
                      ),
                    ],
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

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        _ProfileButton(
          onSignOut: () => ref.read(authRepositoryProvider).signOut(),
        ),
      ],
    );
  }
}

/// Icône profil ronde en haut à droite : ouvre un menu minimal ne proposant
/// pour l'instant que "Se déconnecter" (pas d'écran de profil complet, hors
/// périmètre de cet écran — voir la consigne de la tâche qui l'a produit).
class _ProfileButton extends StatelessWidget {
  const _ProfileButton({required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _openMenu(context),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.woodMedium,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.woodLight,
              width: AppBorders.card,
            ),
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

  void _openMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.parchmentCard,
      builder: (context) {
        return SafeArea(
          child: ListTile(
            leading: const Icon(Icons.logout, color: AppColors.accentBrick),
            title: Text(
              'Se déconnecter',
              style: AppTypography.body(
                fontWeight: FontWeight.w700,
                color: AppColors.accentBrick,
              ),
            ),
            onTap: () {
              Navigator.of(context).pop();
              onSignOut();
            },
          ),
        );
      },
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

/// État vide (aucun personnage) : non couvert par la maquette
/// `01_liste_personnages.png`, à valider par la direction artistique — voir
/// le rapport de la tâche qui a introduit cet écran.
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
            const Icon(
              Icons.shield_moon_outlined,
              size: 56,
              color: AppColors.goldEnd,
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
              'Créez votre premier personnage pour commencer '
              'l\'aventure.',
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
