import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../domain/bug_report_screenshot.dart';

/// Plus grand côté (en pixels) d'une capture après préparation — assez pour
/// rester lisible (une capture d'écran de téléphone de 1080 × 2400 devient
/// 922 × 2048), assez petit pour qu'un JPEG reste très en dessous de
/// [bugReportScreenshotMaxBytes].
const int bugReportScreenshotMaxDimension = 2048;

/// Qualité JPEG de la capture préparée.
const int bugReportScreenshotJpegQuality = 85;

/// Ré-encode [bytes] (n'importe quel format décodable par `package:image` :
/// JPEG, PNG, WebP, GIF...) en JPEG prêt à téléverser dans le bucket
/// `bug-report-screenshots` (contrat `report-bug` : `image/jpeg`).
///
/// Toujours ré-encodé, même quand [bytes] est déjà un JPEG : l'orientation
/// EXIF est appliquée aux pixels puis toutes les métadonnées sont retirées
/// (une photo de l'appareil photo peut porter une position GPS), et le
/// redimensionnement à [maxDimension] est garanti même si celui
/// d'`image_picker` (`maxWidth`/`maxHeight`) n'a pas pu s'appliquer côté
/// natif. La transparence éventuelle (capture PNG avec canal alpha) est
/// aplatie sur un fond blanc, le JPEG n'ayant pas de canal alpha.
///
/// Fonction pure et synchrone (coûteuse sur une grande image) : à exécuter
/// hors du fil d'interface (`Isolate.run`, voir
/// `bug_report_screenshot_picker.dart`).
///
/// Lève une [BugReportScreenshotFailure] :
/// - [BugReportScreenshotFailureKind.unsupportedFormat] si [bytes] n'est pas
///   une image décodable ;
/// - [BugReportScreenshotFailureKind.tooLarge] si le JPEG obtenu dépasse
///   encore [maxBytes].
Uint8List compressBugReportScreenshot(
  Uint8List bytes, {
  int maxBytes = bugReportScreenshotMaxBytes,
  int maxDimension = bugReportScreenshotMaxDimension,
  int quality = bugReportScreenshotJpegQuality,
}) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes);
  } on Object {
    decoded = null;
  }
  if (decoded == null || decoded.width <= 0 || decoded.height <= 0) {
    throw const BugReportScreenshotFailure(
      BugReportScreenshotFailureKind.unsupportedFormat,
    );
  }

  var image = img.bakeOrientation(decoded);
  final longestSide = math.max(image.width, image.height);
  if (longestSide > maxDimension) {
    image = image.width >= image.height
        ? img.copyResize(
            image,
            width: maxDimension,
            interpolation: img.Interpolation.average,
          )
        : img.copyResize(
            image,
            height: maxDimension,
            interpolation: img.Interpolation.average,
          );
  }

  // Fond blanc RVB 8 bits neuf : aplatit l'alpha et les palettes (GIF, PNG
  // indexé), et repart d'une image sans aucune métadonnée EXIF.
  final flattened = img.Image(width: image.width, height: image.height)
    ..clear(img.ColorRgb8(255, 255, 255));
  img.compositeImage(flattened, image);

  final jpeg = img.encodeJpg(flattened, quality: quality);
  if (jpeg.length > maxBytes) {
    throw const BugReportScreenshotFailure(
      BugReportScreenshotFailureKind.tooLarge,
    );
  }
  return jpeg;
}
