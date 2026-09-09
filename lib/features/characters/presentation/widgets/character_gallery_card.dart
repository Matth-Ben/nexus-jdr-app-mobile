import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/dashed_border_painter.dart';
import '../../domain/character_detail.dart';
import '../../domain/character_gallery_photo.dart';
import 'gallery_photo_upload_sheet.dart';
import 'gallery_photo_viewer_screen.dart';

/// Carte "Galerie" de l'onglet "Histoire" — voir
/// `docs/cahier-des-charges/11-fonctionnalites-a-ajouter.md`, section
/// "Onglet Histoire" : "Galerie de photos complémentaires (au-delà du
/// portrait principal)."
///
/// Toujours affichée, même sans aucune photo (contrairement à
/// `CharacterAdventuresCard`, qui se masque entièrement si vide) : la tuile
/// "+" reste le seul moyen de découvrir cette fonctionnalité, la masquer
/// tant qu'elle est vide la rendrait invisible.
///
/// `ConsumerWidget` auto-suffisant (ouvre elle-même la sheet d'ajout et la
/// visionneuse plein écran, qui portent chacune leur propre appel réseau) —
/// même principe que `CharacterAdventuresCard`.
class CharacterGalleryCard extends ConsumerWidget {
  const CharacterGalleryCard({
    required this.detail,
    this.actionsDisabled = false,
    super.key,
  });

  final CharacterDetail detail;

  /// `true` sur la vue de partage en lecture seule — voir la documentation
  /// de [CharacterStoryTabBody.actionsDisabled]. Désactive la tuile "+"
  /// (jamais rendue du tout, plutôt que grisée : rien à découvrir pour un
  /// lecteur anonyme) et le bouton "Retirer" de la visionneuse plein écran,
  /// jamais le tap d'ouverture d'une vignette (voir cette photo reste
  /// autorisé en lecture seule).
  final bool actionsDisabled;

  static const double _thumbnailSize = 72;

  /// `true` s'il y a quelque chose à afficher : au moins une photo, ou une
  /// tuile "+" pour en ajouter une (jamais en lecture seule, voir
  /// [actionsDisabled]) — à vérifier par l'appelant avant d'insérer cette
  /// carte (et son séparateur associé) dans la liste défilante de l'onglet
  /// "Histoire", même principe que `CharacterAdventuresCard.hasContent`.
  static bool hasVisibleContent(
    CharacterDetail detail, {
    required bool actionsDisabled,
  }) => !actionsDisabled || detail.galleryPhotos.isNotEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = detail.galleryPhotos;

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
            'GALERIE',
            style: AppTypography.display(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: _thumbnailSize,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length + (actionsDisabled ? 0 : 1),
              separatorBuilder: (context, index) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                if (index == photos.length) {
                  return _AddPhotoTile(
                    onTap: () => showAddGalleryPhotoSheet(
                      context,
                      ref: ref,
                      characterId: detail.id,
                    ),
                  );
                }
                final photo = photos[index];
                return _GalleryThumbnail(
                  photo: photo,
                  onTap: () => showGalleryPhotoViewer(
                    context,
                    ref: ref,
                    characterId: detail.id,
                    photo: photo,
                    actionsDisabled: actionsDisabled,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryThumbnail extends StatelessWidget {
  const _GalleryThumbnail({required this.photo, required this.onTap});

  final CharacterGalleryPhoto photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          width: CharacterGalleryCard._thumbnailSize,
          height: CharacterGalleryCard._thumbnailSize,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: AppColors.woodLight,
              width: AppBorders.card,
            ),
          ),
          child: Image.network(
            photo.url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const ColoredBox(
              color: AppColors.parchmentCardAlt,
              child: Icon(Icons.broken_image_outlined, color: AppColors.textMuted),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tuile "+" carrée en pointillés — même recette que `DashedAddTile`
/// (`core/widgets/`), mais carrée plutôt que pleine largeur (celle-ci
/// s'insère dans la rangée défilante de vignettes, pas en pied de liste).
class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        width: CharacterGalleryCard._thumbnailSize,
        height: CharacterGalleryCard._thumbnailSize,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: CustomPaint(
          painter: const DashedBorderPainter(color: AppColors.textMuted),
          child: const Center(
            child: Icon(Icons.add, size: 24, color: AppColors.textMuted),
          ),
        ),
      ),
    );
  }
}
