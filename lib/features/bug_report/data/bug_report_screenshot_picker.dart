import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/bug_report_screenshot.dart';
import 'bug_report_error_mapper.dart';
import 'bug_report_screenshot_compressor.dart';

/// Choix et préparation de la capture d'écran jointe à un signalement
/// (`report_bug_sheet.dart`) — abstraction pour que les tests de widget
/// fournissent un double sans jamais ouvrir le vrai sélecteur natif, même
/// principe que `BugReportRepository`.
///
/// Deux étapes séparées pour que l'écran n'affiche l'état « Préparation de
/// l'image… » qu'une fois une image effectivement choisie (jamais pendant
/// que le sélecteur natif est ouvert, ni après une annulation).
abstract class BugReportScreenshotPicker {
  /// Ouvre le sélecteur natif ([source]) et retourne les octets bruts de
  /// l'image choisie, ou `null` si le joueur annule. Lève une
  /// [BugReportScreenshotFailure] si l'accès est refusé
  /// ([BugReportScreenshotFailureKind.accessDenied]) ou si le système
  /// signale une image illisible
  /// ([BugReportScreenshotFailureKind.unsupportedFormat]).
  Future<Uint8List?> pick(BugReportScreenshotSource source);

  /// Prépare [bytes] pour l'envoi (JPEG compressé, voir
  /// [compressBugReportScreenshot]) — lève une [BugReportScreenshotFailure]
  /// ([BugReportScreenshotFailureKind.tooLarge]/`unsupportedFormat`).
  Future<Uint8List> prepare(Uint8List bytes);
}

class ImagePickerBugReportScreenshotPicker
    implements BugReportScreenshotPicker {
  ImagePickerBugReportScreenshotPicker([ImagePicker? imagePicker])
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  @override
  Future<Uint8List?> pick(BugReportScreenshotSource source) async {
    XFile? file;
    try {
      // Premier redimensionnement/compression côté natif (rapide) :
      // `compressBugReportScreenshot` garantit ensuite le JPEG et la taille
      // finale, `image_picker` laissant par exemple une capture PNG en PNG.
      file = await _imagePicker.pickImage(
        source: switch (source) {
          BugReportScreenshotSource.gallery => ImageSource.gallery,
          BugReportScreenshotSource.camera => ImageSource.camera,
        },
        maxWidth: bugReportScreenshotMaxDimension.toDouble(),
        maxHeight: bugReportScreenshotMaxDimension.toDouble(),
        imageQuality: bugReportScreenshotJpegQuality,
      );
    } catch (error) {
      final failure = mapBugReportScreenshotPickError(error);
      if (failure != null) throw failure;
      // Toute autre erreur du sélecteur (ex. aucun appareil photo
      // disponible) : traitée comme une annulation, même comportement que
      // les autres flux de choix d'image de l'app.
      debugPrint('BugReportScreenshotPicker.pick: erreur ignorée: $error');
      return null;
    }
    return file?.readAsBytes();
  }

  @override
  Future<Uint8List> prepare(Uint8List bytes) async {
    // L'échec est rapporté en valeur de retour plutôt que levé dans
    // l'isolat : seule la catégorie traverse la frontière, sans dépendre de
    // la façon dont `Isolate.run` relaie une exception.
    // Toute autre exception inattendue du décodage/encodage est assimilée à
    // une image illisible.
    final (
      jpeg,
      failureKind,
    ) = await Isolate.run<(Uint8List?, BugReportScreenshotFailureKind?)>(() {
      try {
        return (compressBugReportScreenshot(bytes), null);
      } on BugReportScreenshotFailure catch (failure) {
        return (null, failure.kind);
      } on Object {
        return (null, BugReportScreenshotFailureKind.unsupportedFormat);
      }
    });
    if (failureKind != null) throw BugReportScreenshotFailure(failureKind);
    return jpeg!;
  }
}
