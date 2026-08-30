import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/scene_scaffold.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../character_creation/presentation/providers/character_creation_draft_provider.dart';
import '../domain/character_failure.dart';
import '../domain/character_summary.dart';
import 'providers/character_providers.dart';
import 'widgets/character_card.dart';

/// Écran d'accueil listant les personnages du joueur connecté
/// (`docs/cahier-des-charges/04-fonctionnalites-app-mobile.md` section 2,
/// maquette `01_liste_personnages.png`).
class CharacterListScreen extends ConsumerWidget {
  const CharacterListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              child: Row(
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
    context.push('/characters/new');
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
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xml'],
        withData: true,
      );
    } catch (_) {
      if (!context.mounted) return;
      _showImportError(context);
      return;
    }

    // `result == null` : sélection annulée par l'utilisateur, rien à faire.
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
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
