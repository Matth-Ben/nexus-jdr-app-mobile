import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';

/// Écran plein écran "Connexion impossible" — recettage direction
/// artistique du 13/09/2026 (`docs/cahier-des-charges/09-maquettes-captures.md`,
/// section "Erreur — Connexion impossible"), copie exacte de
/// `docs/cahier-des-charges/16-textes-a-rediger.md` section 4 : "Connexion
/// impossible. Vérifie ta connexion internet et réessaie. Tes personnages
/// restent disponibles hors ligne — les modifications se synchroniseront
/// automatiquement dès le retour du réseau."
///
/// Remplace l'échec du chargement initial de la liste de personnages
/// (`character_list_screen.dart`, branche `error:` de
/// `charactersProvider`) : contrairement à l'ancien `_ErrorState` générique
/// qu'il remplace, cet écran affiche toujours cette même copie statique
/// plutôt que le message dynamique de la [CharacterFailure] éventuellement
/// levée — c'est la spec de la tâche (maquette dédiée à l'échec réseau, pas
/// un message d'erreur technique).
///
/// Niveau "parchemin" (`Scaffold` par défaut, pas `SceneScaffold` — voir
/// `docs/cahier-des-charges/10-design-system.md` section 6), avec son propre
/// bandeau bois "CONNEXION" en tête plutôt que l'en-tête "TES AVENTURIERS"/
/// barre de recherche habituels de `character_list_screen.dart`, qui n'ont
/// aucun sens tant qu'aucune donnée n'a pu être chargée.
///
/// **Écart assumé vis-à-vis de la maquette — pas de flèche retour** : la
/// maquette montre un bandeau "‹ CONNEXION" avec une flèche retour
/// (`WoodBackHeader`, motif déjà utilisé par `group_join_screen.dart`/
/// `character_detail_screen.dart`). Mais `CharacterListScreen` est l'écran
/// d'accueil (route `/`, jamais empilé par-dessus un autre écran — voir
/// `core/router/app_router.dart`) : il n'y a donc rien de cohérent vers quoi
/// revenir (`context.pop()` échouerait, `context.go('/')` ne ferait que
/// recharger le même écran). Ce widget reprend donc le même habillage visuel
/// que `WoodBackHeader` (bandeau `wood.medium`, titre `font.display`) mais
/// sans bouton retour, plutôt que de réutiliser `WoodBackHeader` avec un
/// `onBack` trompeur.
class ConnectionErrorState extends StatelessWidget {
  const ConnectionErrorState({required this.onRetry, super.key});

  /// Relance `charactersProvider` (voir `character_list_screen.dart::build`).
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const _Banner(),
          Expanded(
            child: SafeArea(
              top: false,
              child: Center(
                child: SingleChildScrollView(
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
                            BorderSide(
                              color: AppColors.accentBrick,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: const Icon(
                          Icons.wifi_off,
                          size: 40,
                          color: AppColors.accentBrick,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Connexion impossible',
                        textAlign: TextAlign.center,
                        style: AppTypography.body(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Vérifie ta connexion internet et réessaie. Tes '
                        'personnages restent disponibles hors ligne — les '
                        'modifications se synchroniseront automatiquement '
                        'dès le retour du réseau.',
                        textAlign: TextAlign.center,
                        style: AppTypography.body(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(
                          label: 'Réessayer',
                          onPressed: onRetry,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const _ContinueOfflineLink(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bandeau bois "CONNEXION" — même habillage visuel que `WoodBackHeader`
/// (`core/widgets/wood_back_header.dart`), sans bouton retour. Voir la
/// documentation de classe de [ConnectionErrorState] pour le rationale de
/// cet écart.
class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.woodMedium,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + AppSpacing.xs,
          ),
          child: Text(
            'CONNEXION',
            style: AppTypography.display(
              fontSize: 11,
              color: AppColors.textOnWood,
            ),
          ),
        ),
      ),
    );
  }
}

/// Lien "Continuer hors ligne" de la maquette — **volontairement désactivé,
/// sans aucun `onTap`** : `character_repository.dart::fetchCharacters()` n'a
/// aujourd'hui aucun fallback vers un cache local (`drift`), c'est une dette
/// déjà connue et assumée, dépendante de la Phase 4 (synchro "Histoires",
/// voir `docs/cahier-des-charges/06-roadmap.md`). Tant que ce fallback
/// n'existe pas, ce lien n'aurait littéralement rien à faire s'il était
/// activé — plutôt que d'inventer un comportement de repli, ou de l'omettre
/// silencieusement (ce qui s'écarterait de la maquette déjà validée par la
/// direction artistique), il reste affiché mais visuellement neutre (couleur
/// atténuée, pas de soulignement/`InkWell`) avec un [Tooltip] expliquant
/// pourquoi, affiché au survol/appui long.
class _ContinueOfflineLink extends StatelessWidget {
  const _ContinueOfflineLink();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          'Bientôt disponible : la lecture hors ligne de tes personnages '
          "arrive avec une prochaine mise à jour. Pour l'instant, une "
          'connexion est nécessaire pour charger tes personnages.',
      child: Text(
        'Continuer hors ligne',
        style: AppTypography.body(fontSize: 13, color: AppColors.textMuted),
      ),
    );
  }
}
