import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/connectivity_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/alert_banner.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/wood_back_header.dart';
import '../../../auth/domain/auth_failure.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Écran de recadrage d'avatar de profil, poussé après le choix d'une image
/// (caméra/galerie) par `avatar_edit_sheet.dart`. Copie volontaire de
/// `features/characters/presentation/widgets/portrait_crop_screen.dart`
/// (même mécanique `InteractiveViewer` + `RepaintBoundary.toImage()`, même
/// cadre carré 280×280, mêmes boutons "Annuler"/"Valider") plutôt qu'une
/// généralisation commune : l'original est étroitement couplé à
/// `characterId`/`CharacterRepository`/`characterDetailProvider` — voir la
/// spec direction-artistique de la tâche "Modifier le profil (avatar/mot de
/// passe/email)" pour ce choix explicite.
///
/// Contrairement à l'original, vérifie la connectivité *avant* de tenter la
/// capture/l'upload (spec de la tâche, section "États transverses") :
/// `AuthRepository.updateAvatar` n'a pas de file d'attente hors-ligne, voir
/// sa documentation.
class AvatarCropScreen extends ConsumerStatefulWidget {
  const AvatarCropScreen({required this.imageBytes, super.key});

  final Uint8List imageBytes;

  @override
  ConsumerState<AvatarCropScreen> createState() => _AvatarCropScreenState();
}

class _AvatarCropScreenState extends ConsumerState<AvatarCropScreen> {
  static const double _frameSize = 280;

  final GlobalKey _boundaryKey = GlobalKey();

  bool _isUploading = false;
  String? _errorMessage;

  Future<void> _submit() async {
    // Capturé avant tout `await` (vérification de connectivité incluse) :
    // évite d'utiliser `context`/`MediaQuery.of(context)` après un gap
    // asynchrone (`use_build_context_synchronously`).
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    // Vérifié *avant* toute tentative réseau — voir la documentation de
    // classe : `AuthRepository.updateAvatar` n'a aucune file d'attente
    // hors-ligne vers laquelle se replier.
    if (!await ref.read(connectivityCheckerProvider).hasConnection()) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _errorMessage = _offlineMessage;
      });
      return;
    }
    if (!mounted) return;

    try {
      final boundary =
          _boundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw const AuthFailure("Impossible de préparer l'image. Réessayez.");
      }

      await ref
          .read(authRepositoryProvider)
          .updateAvatar(bytes: byteData.buffer.asUint8List());

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _errorMessage = failure.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _errorMessage = _genericErrorMessage;
      });
    }
  }

  void _cancel() {
    if (_isUploading) return;
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    // Même rationale que les 3 sheets sœurs
    // (`change_password_sheet.dart`/`change_email_sheet.dart`/
    // `edit_display_name_sheet.dart`) : seul garde-fou qui couvre le geste
    // retour Android, chemin entièrement distinct du bouton retour visible
    // (`WoodBackHeader`/`_cancel`, déjà gardé par `_isUploading`).
    return PopScope(
      canPop: !_isUploading,
      child: Scaffold(
        body: Column(
          children: [
            WoodBackHeader(title: 'RECADRAGE', onBack: _cancel),
            Expanded(
              child: ColoredBox(
                color: AppColors.woodDark.withValues(alpha: 0.55),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: _frameSize,
                        height: _frameSize,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.woodLight,
                            width: 3,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.woodDark,
                              blurRadius: 0,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ClipRect(
                          child: RepaintBoundary(
                            key: _boundaryKey,
                            child: InteractiveViewer(
                              minScale: 1,
                              maxScale: 4,
                              child: Image.memory(
                                widget.imageBytes,
                                width: _frameSize,
                                height: _frameSize,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Pincez pour zoomer, glissez pour cadrer.',
                        style: AppTypography.body(
                          fontSize: 12,
                          color: AppColors.textOnWoodMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  if (_errorMessage != null) ...[
                    AlertBanner(message: _errorMessage!),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          label: 'Annuler',
                          surface: SecondaryButtonSurface.parchment,
                          onPressed: _isUploading ? null : _cancel,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: PrimaryButton(
                          label: 'Valider',
                          isLoading: _isUploading,
                          onPressed: _submit,
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
}

/// Voir [_offlineMessage] : même texte que
/// `edit_display_name_sheet.dart`/`report_bug_sheet.dart`.
const String _offlineMessage =
    "Hors ligne : cette action n'a pas pu être enregistrée. Réessayez une "
    'fois reconnecté.';

const String _genericErrorMessage =
    "Impossible de mettre à jour l'avatar. Réessayez.";
