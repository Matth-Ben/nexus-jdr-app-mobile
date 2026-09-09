import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/destructive_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../domain/character_gallery_photo.dart';
import '../providers/character_detail_provider.dart';
import '../providers/character_providers.dart';

/// Ouvre la photo [photo] en plein écran (tap sur une vignette de la carte
/// "Galerie", `character_gallery_card.dart`) — fond noir, zoom via
/// `InteractiveViewer`, croix de fermeture et bouton "Retirer" (avec
/// confirmation, même dialogue que
/// `portrait_upload_sheet.dart::showRemovePortraitConfirmationDialog`).
///
/// Prend [ref] en paramètre explicite pour la même raison que
/// `showPortraitUploadSheet` : la suppression opère sur le [BuildContext] de
/// l'écran appelant l'origine (la fiche personnage), jamais sur celui de
/// cette route plein écran une fois refermée.
Future<void> showGalleryPhotoViewer(
  BuildContext context, {
  required WidgetRef ref,
  required String characterId,
  required CharacterGalleryPhoto photo,
  bool actionsDisabled = false,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => _GalleryPhotoViewerScreen(
        ref: ref,
        characterId: characterId,
        photo: photo,
        actionsDisabled: actionsDisabled,
      ),
    ),
  );
}

class _GalleryPhotoViewerScreen extends StatefulWidget {
  const _GalleryPhotoViewerScreen({
    required this.ref,
    required this.characterId,
    required this.photo,
    required this.actionsDisabled,
  });

  final WidgetRef ref;
  final String characterId;
  final CharacterGalleryPhoto photo;

  /// `true` sur la vue de partage en lecture seule — masque le bouton
  /// "Retirer cette photo" (voir `CharacterGalleryCard.actionsDisabled`).
  final bool actionsDisabled;

  @override
  State<_GalleryPhotoViewerScreen> createState() =>
      _GalleryPhotoViewerScreenState();
}

class _GalleryPhotoViewerScreenState
    extends State<_GalleryPhotoViewerScreen> {
  bool _isRemoving = false;

  Future<void> _confirmAndRemove() async {
    final confirmed = await showRemoveGalleryPhotoConfirmationDialog(context);
    if (confirmed != true || !mounted) return;

    setState(() => _isRemoving = true);
    try {
      await widget.ref
          .read(characterRepositoryProvider)
          .removeGalleryPhoto(
            characterId: widget.characterId,
            photoId: widget.photo.id,
            url: widget.photo.url,
          );
      widget.ref.invalidate(characterDetailProvider(widget.characterId));
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Photo retirée.')));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isRemoving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de retirer cette photo. Réessayez.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  widget.photo.url,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 64,
                  ),
                ),
              ),
            ),
            Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.sm,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
            if (!widget.actionsDisabled)
              Positioned(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.lg,
                child: DestructiveButton(
                  label: 'Retirer cette photo',
                  onPressed: _isRemoving ? null : _confirmAndRemove,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Dialogue de confirmation "Retirer cette photo ?" — calque exact de
/// `portrait_upload_sheet.dart::showRemovePortraitConfirmationDialog`.
Future<bool?> showRemoveGalleryPhotoConfirmationDialog(BuildContext context) {
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
              'Retirer cette photo ?',
              style: AppTypography.body(
                fontSize: 16,
                fontWeight: FontWeight.w800,
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
                    label: 'Retirer',
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
