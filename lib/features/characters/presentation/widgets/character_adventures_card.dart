import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/destructive_button.dart';
import '../../../../core/widgets/portrait_frame.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../domain/character_adventure.dart';
import '../../domain/character_detail.dart';
import '../providers/character_detail_provider.dart';
import '../providers/character_providers.dart';

/// Carte "Aventures" de l'onglet "Personnage" — voir
/// `docs/cahier-des-charges/04-fonctionnalites-app-mobile.md` section 7.2 et
/// `05-ux-navigation.md`. Une ligne par histoire rattachée
/// (`CharacterDetail.adventures`), séparées par un `Divider`.
///
/// Même gabarit que `CharacterAppearanceCard` (`parchment.card`, bordure 2px
/// `wood.light`, `radius.md`, titre en majuscules) — voir sa documentation
/// de classe pour le rationale de ne pas factoriser ce gabarit en composant
/// partagé (`core/widgets`) à ce stade.
///
/// `ConsumerWidget` (plutôt qu'un simple `StatelessWidget` + callback
/// remonté à l'écran appelant) : contrairement à `CharacterAppearanceCard`
/// (purement affichage), cette carte porte elle-même l'action "Quitter
/// l'histoire" de bout en bout (confirmation, appel réseau, invalidation,
/// `SnackBar`) — même principe d'auto-suffisance que
/// `showPortraitUploadSheet` (`widgets/portrait_upload_sheet.dart`), qui
/// prend déjà `WidgetRef` en paramètre explicite pour la même raison.
class CharacterAdventuresCard extends ConsumerWidget {
  const CharacterAdventuresCard({required this.detail, super.key});

  final CharacterDetail detail;

  /// `true` si au moins une histoire est rattachée — à vérifier par
  /// l'appelant avant d'insérer cette carte (et son séparateur associé)
  /// dans la liste défilante de l'onglet "Personnage", même principe que
  /// `CharacterAppearanceCard.hasContent`.
  static bool hasContent(CharacterDetail detail) =>
      detail.adventures.isNotEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adventures = detail.adventures;
    if (adventures.isEmpty) {
      // Ne devrait pas arriver en pratique : l'appelant est censé avoir déjà
      // vérifié [hasContent] — filet de sécurité plutôt qu'une carte
      // parchemin vide affichée, même principe que `CharacterAppearanceCard`.
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.woodLight, width: AppBorders.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AVENTURES',
            style: AppTypography.display(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < adventures.length; i++) ...[
            if (i > 0)
              // `AppColors.gaugeTrack` (même valeur `0xFFE0D2AB` déjà
              // dupliquée en dur ailleurs dans ce dépôt pour ce même usage
              // de séparateur, ex. `portrait_upload_sheet.dart::_SheetDivider` —
              // revue de code : préférer le token nommé ici plutôt que de
              // reconduire la duplication en dur une fois de plus).
              const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.gaugeTrack,
              ),
            _AdventureRow(
              adventure: adventures[i],
              onLeave: () => _confirmAndLeave(context, ref, adventures[i]),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmAndLeave(
    BuildContext context,
    WidgetRef ref,
    CharacterAdventure adventure,
  ) async {
    final confirmed = await showLeaveAdventureConfirmationDialog(
      context,
      storyTitle: adventure.storyTitle,
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(characterRepositoryProvider)
          .leaveStory(characterCampaignId: adventure.characterCampaignId);
      ref.invalidate(characterDetailProvider(detail.id));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tu as quitté ${adventure.storyTitle}.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de quitter cette histoire. Réessayez.'),
        ),
      );
    }
  }
}

/// Une ligne = portrait de substitution + nom de l'histoire + "Quitter" —
/// **pas de "MJ : {nom}"**, volontairement : voir la documentation de classe
/// de [CharacterAdventure] pour la décision produit actée (même rationale
/// que `StoryPreview` de l'étape 2/4 "Confirmation" du flux "Rejoindre une
/// histoire").
class _AdventureRow extends StatelessWidget {
  const _AdventureRow({required this.adventure, required this.onLeave});

  final CharacterAdventure adventure;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          PortraitFrame(
            portraitUrl: adventure.storyCoverUrl,
            size: 40,
            fallbackIcon: Icons.auto_stories,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              adventure.storyTitle,
              style: AppTypography.body(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              tooltip: 'Quitter l\'histoire',
              onPressed: onLeave,
              icon: const Icon(Icons.logout, color: AppColors.accentBrick),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialogue de confirmation "Quitter « {nom} » ?" — calque exact de
/// `showRemovePortraitConfirmationDialog`
/// (`widgets/portrait_upload_sheet.dart`), voir la spec visuelle de la
/// tâche. Retourne `true` si le joueur confirme, `false`/`null` sinon.
Future<bool?> showLeaveAdventureConfirmationDialog(
  BuildContext context, {
  required String storyTitle,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: AppColors.parchmentCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(
          color: AppColors.woodLight,
          width: AppBorders.card,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quitter « $storyTitle » ?',
              style: AppTypography.body(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Ton personnage garde toutes ses données. Seul le lien avec '
              'cette histoire disparaît.',
              style: AppTypography.body(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Annuler',
                    surface: SecondaryButtonSurface.parchment,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: DestructiveButton(
                    label: 'Quitter',
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
