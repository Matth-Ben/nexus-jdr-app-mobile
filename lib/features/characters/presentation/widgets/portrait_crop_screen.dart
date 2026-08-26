import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/wood_back_header.dart';
import '../../domain/character_failure.dart';
import '../providers/character_detail_provider.dart';
import '../providers/character_providers.dart';

/// Écran de recadrage de portrait, poussé après le choix d'une image
/// (caméra/galerie/URL) par `portrait_upload_sheet.dart`. Plein écran (pas un
/// bottom sheet) : le pan/zoom de l'image ne cohabite pas bien avec un sheet
/// — voir la spec visuelle de la tâche qui a produit ce fichier.
///
/// Recadrage carré uniquement : le cadre 280×280 est lui-même la zone
/// manipulable (`InteractiveViewer` clippé à sa taille), plutôt qu'un plus
/// grand aperçu avec une "fenêtre" carrée découpée dedans — capturer
/// exactement ce viewport clippé via `RenderRepaintBoundary.toImage()`
/// donne directement une image déjà carrée, sans calcul manuel de rectangle
/// de recadrage face à la matrice de transformation de l'`InteractiveViewer`.
class PortraitCropScreen extends ConsumerStatefulWidget {
  const PortraitCropScreen({
    required this.characterId,
    required this.imageBytes,
    super.key,
  });

  final String characterId;
  final Uint8List imageBytes;

  @override
  ConsumerState<PortraitCropScreen> createState() => _PortraitCropScreenState();
}

class _PortraitCropScreenState extends ConsumerState<PortraitCropScreen> {
  static const double _frameSize = 280;

  final GlobalKey _boundaryKey = GlobalKey();

  bool _isUploading = false;
  String? _errorMessage;

  Future<void> _submit() async {
    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final boundary =
          _boundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final pixelRatio = MediaQuery.of(context).devicePixelRatio;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw const CharacterFailure(
          "Impossible de préparer l'image. Réessayez.",
        );
      }

      await ref
          .read(characterRepositoryProvider)
          .uploadPortrait(
            characterId: widget.characterId,
            bytes: byteData.buffer.asUint8List(),
          );
      ref.invalidate(characterDetailProvider(widget.characterId));

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on CharacterFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _errorMessage = failure.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _errorMessage = "Impossible d'envoyer le portrait. Réessayez.";
      });
    }
  }

  void _cancel() {
    if (_isUploading) return;
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  _AlertBanner(message: _errorMessage!),
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
    );
  }
}

/// "Bandeau d'alerte inline" du design système — même pattern déjà réutilisé
/// plusieurs fois dans l'assistant de création (`_AlertBanner`, privé à
/// chaque écran, non réutilisable tel quel — voir
/// `character_creation/presentation/summary_step_screen.dart`).
class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.alertBannerBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.accentBrick,
          width: AppBorders.card,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.accentBrick,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.body(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
