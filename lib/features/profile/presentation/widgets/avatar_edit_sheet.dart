import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/destructive_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/sheet_action_row.dart';
import '../../../auth/domain/auth_failure.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import 'avatar_crop_screen.dart';

enum _AvatarEditAction { camera, gallery, remove }

/// Ouvre le bottom sheet "changer l'avatar" (ligne "Avatar" de
/// `profile_edit_screen.dart`) et orchestre ensuite le flux choisi — calqué
/// sur `features/characters/presentation/widgets/portrait_upload_sheet.dart`
/// (voir sa documentation pour le rationale du couple sheet de choix +
/// écran de recadrage plein écran), avec deux écarts assumés (spec
/// direction-artistique de la tâche) :
/// - pas d'option "Utiliser une URL" (un avatar personnel est très
///   majoritairement une vraie photo, contrairement au portrait de
///   personnage) ;
/// - passe par `AuthRepository` (`user_metadata['avatar_url']`), pas
///   `CharacterRepository`.
///
/// Prend [ref] en paramètre explicite (plutôt que de faire de son contenu un
/// `ConsumerWidget`) pour que toute la suite du flux (choix de source,
/// confirmation de suppression, écran de recadrage) opère sur le
/// [BuildContext] de l'écran appelant, jamais sur celui — éphémère — du
/// bottom sheet lui-même une fois refermé.
Future<void> showAvatarEditSheet(
  BuildContext context, {
  required WidgetRef ref,
  required String? avatarUrl,
}) async {
  final action = await showModalBottomSheet<_AvatarEditAction>(
    context: context,
    backgroundColor: AppColors.parchmentCard,
    builder: (sheetContext) =>
        _AvatarEditSheetContent(hasAvatar: avatarUrl != null),
  );
  if (action == null || !context.mounted) return;

  switch (action) {
    case _AvatarEditAction.camera:
      await _pickAndCrop(context, ImageSource.camera);
    case _AvatarEditAction.gallery:
      await _pickAndCrop(context, ImageSource.gallery);
    case _AvatarEditAction.remove:
      await _confirmAndRemove(context, ref);
  }
}

Future<void> _pickAndCrop(BuildContext context, ImageSource source) async {
  XFile? file;
  try {
    file = await ImagePicker().pickImage(source: source, imageQuality: 95);
  } catch (_) {
    file = null;
  }
  if (file == null || !context.mounted) return;

  final bytes = await file.readAsBytes();
  if (!context.mounted) return;
  await _pushCropScreen(context, bytes);
}

Future<void> _pushCropScreen(BuildContext context, Uint8List bytes) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => AvatarCropScreen(imageBytes: bytes)),
  );
}

Future<void> _confirmAndRemove(BuildContext context, WidgetRef ref) async {
  final confirmed = await showRemoveAvatarConfirmationDialog(context);
  if (confirmed != true || !context.mounted) return;

  try {
    await ref.read(authRepositoryProvider).removeAvatar();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Photo retirée.')));
  } on AuthFailure catch (failure) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(failure.message)));
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Impossible de mettre à jour l'avatar. Réessayez."),
      ),
    );
  }
}

class _AvatarEditSheetContent extends StatelessWidget {
  const _AvatarEditSheetContent({required this.hasAvatar});

  final bool hasAvatar;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetActionRow(
            icon: Icons.photo_camera_outlined,
            label: 'Prendre une photo',
            onTap: () => Navigator.of(context).pop(_AvatarEditAction.camera),
          ),
          const SheetActionDivider(),
          SheetActionRow(
            icon: Icons.image_outlined,
            label: 'Choisir dans la galerie',
            onTap: () => Navigator.of(context).pop(_AvatarEditAction.gallery),
          ),
          if (hasAvatar) ...[
            const SheetActionDivider(),
            SheetActionRow(
              icon: Icons.delete_outline,
              label: 'Retirer la photo',
              color: AppColors.accentBrick,
              onTap: () => Navigator.of(context).pop(_AvatarEditAction.remove),
            ),
          ],
        ],
      ),
    );
  }
}

/// Dialogue de confirmation "Retirer la photo ?" — retourne `true` si le
/// joueur confirme, `false`/`null` sinon. Copie de
/// `portrait_upload_sheet.dart::showRemovePortraitConfirmationDialog` (même
/// `Dialog`, mêmes tokens, `DestructiveButton`), texte adapté à l'avatar.
Future<bool?> showRemoveAvatarConfirmationDialog(BuildContext context) {
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
              'Retirer la photo ?',
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
