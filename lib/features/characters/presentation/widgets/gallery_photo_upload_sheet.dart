import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/sheet_action_row.dart';
import '../../data/portrait_url_fetcher.dart';
import '../providers/character_detail_provider.dart';
import '../providers/character_providers.dart';

enum _AddPhotoAction { camera, gallery, url }

/// Ouvre le bottom sheet "Ajouter une photo" (tuile "+" de la carte
/// "Galerie" de l'onglet "Histoire", `character_gallery_card.dart`) et
/// orchestre ensuite le flux choisi jusqu'à l'appel réseau — même
/// architecture que `portrait_upload_sheet.dart::showPortraitUploadSheet`
/// (choix de source → octets → upload), sans l'étape de recadrage
/// (`PortraitCropScreen`) : la galerie accepte des photos de toute
/// proportion, contrairement au portrait carré — voir la spec de la tâche
/// "Galerie de photos", `docs/cahier-des-charges/`
/// 11-fonctionnalites-a-ajouter.md section "Onglet Histoire".
///
/// Prend [ref] en paramètre explicite pour la même raison que
/// [showPortraitUploadSheet] : l'appel réseau (`addGalleryPhoto`) opère sur
/// le [BuildContext] de l'écran appelant, jamais celui — éphémère — du
/// bottom sheet lui-même une fois refermé.
Future<void> showAddGalleryPhotoSheet(
  BuildContext context, {
  required WidgetRef ref,
  required String characterId,
}) async {
  final action = await showModalBottomSheet<_AddPhotoAction>(
    context: context,
    backgroundColor: AppColors.parchmentCard,
    builder: (sheetContext) => const _AddPhotoSheetContent(),
  );
  if (action == null || !context.mounted) return;

  Uint8List? bytes;
  switch (action) {
    case _AddPhotoAction.camera:
      bytes = await _pick(ImageSource.camera);
    case _AddPhotoAction.gallery:
      bytes = await _pick(ImageSource.gallery);
    case _AddPhotoAction.url:
      if (!context.mounted) return;
      bytes = await showGalleryPhotoUrlDialog(context);
  }
  if (bytes == null || !context.mounted) return;

  try {
    await ref
        .read(characterRepositoryProvider)
        .addGalleryPhoto(characterId: characterId, bytes: bytes);
    ref.invalidate(characterDetailProvider(characterId));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Photo ajoutée.')));
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Impossible d'ajouter cette photo. Réessayez."),
      ),
    );
  }
}

Future<Uint8List?> _pick(ImageSource source) async {
  XFile? file;
  try {
    file = await ImagePicker().pickImage(source: source, imageQuality: 95);
  } catch (_) {
    file = null;
  }
  return file?.readAsBytes();
}

class _AddPhotoSheetContent extends StatelessWidget {
  const _AddPhotoSheetContent();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetActionRow(
            icon: Icons.photo_camera_outlined,
            label: 'Prendre une photo',
            onTap: () => Navigator.of(context).pop(_AddPhotoAction.camera),
          ),
          const SheetActionDivider(),
          SheetActionRow(
            icon: Icons.image_outlined,
            label: 'Choisir dans la galerie',
            onTap: () => Navigator.of(context).pop(_AddPhotoAction.gallery),
          ),
          const SheetActionDivider(),
          SheetActionRow(
            icon: Icons.link,
            label: 'Utiliser une URL',
            onTap: () => Navigator.of(context).pop(_AddPhotoAction.url),
          ),
        ],
      ),
    );
  }
}

/// Dialogue "Utiliser une URL" — calque de
/// `portrait_upload_sheet.dart::_PortraitUrlDialog` (même validation via
/// `fetchPortraitBytesFromUrl`, générique malgré son nom — voir sa
/// documentation de classe), dupliqué pour son propre titre ("URL de la
/// photo" plutôt que "URL du portrait").
Future<Uint8List?> showGalleryPhotoUrlDialog(BuildContext context) {
  return showDialog<Uint8List>(
    context: context,
    builder: (context) => const _GalleryPhotoUrlDialog(),
  );
}

class _GalleryPhotoUrlDialog extends StatefulWidget {
  const _GalleryPhotoUrlDialog();

  @override
  State<_GalleryPhotoUrlDialog> createState() =>
      _GalleryPhotoUrlDialogState();
}

class _GalleryPhotoUrlDialogState extends State<_GalleryPhotoUrlDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final url = _controller.text.trim();
    if (url.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final bytes = await fetchPortraitBytesFromUrl(url);
      if (!mounted) return;
      Navigator.of(context).pop(bytes);
    } on PortraitUrlFetchFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = failure.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = 'Impossible de charger cette image.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
              'URL de la photo',
              style: AppTypography.body(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _controller,
              enabled: !_isLoading,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'https://...',
                errorText: _errorText,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Annuler',
                    surface: SecondaryButtonSurface.parchment,
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: PrimaryButton(
                    label: 'Suivant',
                    isLoading: _isLoading,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
