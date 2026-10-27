// Tests de `compressBugReportScreenshot` : sortie toujours JPEG, alpha
// aplati sur blanc, redimensionnement au plus grand côté, métadonnées
// retirées, erreurs « format non pris en charge » / « trop lourde ».

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:personnages/features/bug_report/data/bug_report_screenshot_compressor.dart';
import 'package:personnages/features/bug_report/domain/bug_report_screenshot.dart';

bool _isJpeg(Uint8List bytes) =>
    bytes.length > 3 &&
    bytes[0] == 0xFF &&
    bytes[1] == 0xD8 &&
    bytes[2] == 0xFF;

void main() {
  test('PNG avec alpha -> JPEG, pixels transparents aplatis sur blanc', () {
    final source = img.Image(width: 40, height: 60, numChannels: 4)
      ..clear(img.ColorRgba8(0, 0, 0, 0));
    final png = img.encodePng(source);

    final jpeg = compressBugReportScreenshot(png);

    expect(_isJpeg(jpeg), isTrue);
    final decoded = img.decodeJpg(jpeg)!;
    expect(decoded.width, 40);
    expect(decoded.height, 60);
    final pixel = decoded.getPixel(20, 30);
    expect(pixel.r, greaterThan(240));
    expect(pixel.g, greaterThan(240));
    expect(pixel.b, greaterThan(240));
  });

  test('plus grand côté ramené à maxDimension, proportions conservées', () {
    final tall = img.Image(width: 100, height: 400)
      ..clear(img.ColorRgb8(10, 120, 200));

    final jpeg = compressBugReportScreenshot(
      img.encodePng(tall),
      maxDimension: 200,
    );

    final decoded = img.decodeJpg(jpeg)!;
    expect(decoded.height, 200);
    expect(decoded.width, 50);
  });

  test('JPEG en entrée : ré-encodé sans métadonnées EXIF', () {
    final source = img.Image(width: 30, height: 30)
      ..clear(img.ColorRgb8(200, 50, 50));
    source.exif.imageIfd['Make'] = img.IfdValueAscii('Appareil de test');
    final withExif = img.encodeJpg(source);
    expect(img.decodeJpg(withExif)!.exif.isEmpty, isFalse);

    final jpeg = compressBugReportScreenshot(withExif);

    expect(_isJpeg(jpeg), isTrue);
    expect(img.decodeJpg(jpeg)!.exif.isEmpty, isTrue);
  });

  test('octets non décodables -> unsupportedFormat', () {
    expect(
      () => compressBugReportScreenshot(
        Uint8List.fromList(List<int>.generate(64, (i) => i)),
      ),
      throwsA(
        const BugReportScreenshotFailure(
          BugReportScreenshotFailureKind.unsupportedFormat,
        ),
      ),
    );
  });

  test('JPEG obtenu au-delà de maxBytes -> tooLarge', () {
    final source = img.Image(width: 64, height: 64)
      ..clear(img.ColorRgb8(1, 2, 3));

    expect(
      () => compressBugReportScreenshot(img.encodePng(source), maxBytes: 10),
      throwsA(
        const BugReportScreenshotFailure(
          BugReportScreenshotFailureKind.tooLarge,
        ),
      ),
    );
  });
}
