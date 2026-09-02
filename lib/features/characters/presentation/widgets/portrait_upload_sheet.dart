import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/destructive_button.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/sheet_action_row.dart';
import '../../data/portrait_url_fetcher.dart';
import '../providers/character_detail_provider.dart';
import '../providers/character_providers.dart';
import 'portrait_crop_screen.dart';

enum _PortraitUploadAction { camera, gallery, url, remove }

/// Ouvre le bottom sheet "changer le portrait" (tap sur le cadre de portrait
/// de la fiche personnage, `character_identity_card.dart`) et orchestre
/// ensuite le flux choisi — voir la spec visuelle de la tâche qui a produit
/// ce fichier pour le détail des 4 lignes possibles.
///
/// Prend [ref] en paramètre explicite (plutôt que de faire de son contenu un
/// `ConsumerWidget`) pour que toute la suite du flux (choix de source,
/// dialogue URL, confirmation de suppression, écran de recadrage) opère sur
/// le [BuildContext] de l'écran appelant, jamais sur celui — éphémère — du
/// bottom sheet lui-même une fois refermé.
Future<void> showPortraitUploadSheet(
  BuildContext context, {
  required WidgetRef ref,
  required String characterId,
  required String? portraitUrl,
}) async {
  final action = await showModalBottomSheet<_PortraitUploadAction>(
    context: context,
    backgroundColor: AppColors.parchmentCard,
    builder: (sheetContext) =>
        _PortraitUploadSheetContent(hasPortrait: portraitUrl != null),
  );
  if (action == null || !context.mounted) return;

  switch (action) {
    case _PortraitUploadAction.camera:
      await _pickAndCrop(context, characterId, ImageSource.camera);
    case _PortraitUploadAction.gallery:
      await _pickAndCrop(context, characterId, ImageSource.gallery);
    case _PortraitUploadAction.url:
      final bytes = await showPortraitUrlDialog(context);
      if (bytes == null || !context.mounted) return;
      await _pushCropScreen(context, characterId, bytes);
    case _PortraitUploadAction.remove:
      await _confirmAndRemove(context, ref, characterId, portraitUrl!);
  }
}

Future<void> _pickAndCrop(
  BuildContext context,
  String characterId,
  ImageSource source,
) async {
  XFile? file;
  try {
    file = await ImagePicker().pickImage(source: source, imageQuality: 95);
  } catch (_) {
    file = null;
  }
  if (file == null || !context.mounted) return;

  final bytes = await file.readAsBytes();
  if (!context.mounted) return;
  await _pushCropScreen(context, characterId, bytes);
}

Future<void> _pushCropScreen(
  BuildContext context,
  String characterId,
  Uint8List bytes,
) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) =>
          PortraitCropScreen(characterId: characterId, imageBytes: bytes),
    ),
  );
}

Future<void> _confirmAndRemove(
  BuildContext context,
  WidgetRef ref,
  String characterId,
  String portraitUrl,
) async {
  final confirmed = await showRemovePortraitConfirmationDialog(context);
  if (confirmed != true || !context.mounted) return;

  try {
    await ref
        .read(characterRepositoryProvider)
        .removePortrait(characterId: characterId, portraitUrl: portraitUrl);
    ref.invalidate(characterDetailProvider(characterId));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Portrait retiré.')));
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Impossible de retirer le portrait. Réessayez.'),
      ),
    );
  }
}

class _PortraitUploadSheetContent extends StatelessWidget {
  const _PortraitUploadSheetContent({required this.hasPortrait});

  final bool hasPortrait;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetActionRow(
            icon: Icons.photo_camera_outlined,
            label: 'Prendre une photo',
            onTap: () =>
                Navigator.of(context).pop(_PortraitUploadAction.camera),
          ),
          const SheetActionDivider(),
          SheetActionRow(
            icon: Icons.image_outlined,
            label: 'Choisir dans la galerie',
            onTap: () =>
                Navigator.of(context).pop(_PortraitUploadAction.gallery),
          ),
          const SheetActionDivider(),
          SheetActionRow(
            icon: Icons.link,
            label: 'Utiliser une URL',
            onTap: () => Navigator.of(context).pop(_PortraitUploadAction.url),
          ),
          if (hasPortrait) ...[
            const SheetActionDivider(),
            SheetActionRow(
              icon: Icons.delete_outline,
              label: 'Retirer le portrait',
              color: AppColors.accentBrick,
              onTap: () =>
                  Navigator.of(context).pop(_PortraitUploadAction.remove),
            ),
          ],
        ],
      ),
    );
  }
}

/// Dialogue "Utiliser une URL" : retourne les octets déjà téléchargés et
/// validés (voir `data/portrait_url_fetcher.dart`) sur succès, `null` si le
/// joueur annule.
Future<Uint8List?> showPortraitUrlDialog(BuildContext context) {
  return showDialog<Uint8List>(
    context: context,
    builder: (context) => const _PortraitUrlDialog(),
  );
}

class _PortraitUrlDialog extends StatefulWidget {
  const _PortraitUrlDialog();

  @override
  State<_PortraitUrlDialog> createState() => _PortraitUrlDialogState();
}

class _PortraitUrlDialogState extends State<_PortraitUrlDialog> {
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
              'URL du portrait',
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

/// Dialogue de confirmation "Retirer le portrait ?" — retourne `true` si le
/// joueur confirme, `false`/`null` sinon.
Future<bool?> showRemovePortraitConfirmationDialog(BuildContext context) {
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
              'Retirer le portrait ?',
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
