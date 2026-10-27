// Tests QA de `ImagePickerBugReportScreenshotPicker`
// (`data/bug_report_screenshot_picker.dart`) : traduction des erreurs du
// sélecteur natif (accès refusé, image illisible, autre erreur = annulation),
// paramètres transmis à `image_picker`, et préparation réelle dans un isolat
// (`prepare`, chemin emprunté en production, jamais couvert par les tests
// de widget qui utilisent un double).

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:personnages/features/bug_report/data/bug_report_screenshot_compressor.dart';
import 'package:personnages/features/bug_report/data/bug_report_screenshot_picker.dart';
import 'package:personnages/features/bug_report/domain/bug_report_screenshot.dart';

class _FakeImagePicker extends ImagePicker {
  XFile? result;
  Object? error;

  ImageSource? lastSource;
  double? lastMaxWidth;
  double? lastMaxHeight;
  int? lastImageQuality;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    lastSource = source;
    lastMaxWidth = maxWidth;
    lastMaxHeight = maxHeight;
    lastImageQuality = imageQuality;
    final e = error;
    if (e != null) throw e;
    return result;
  }
}

void main() {
  group('pick', () {
    test('galerie/appareil photo transmis avec 2048 px max et qualité 85, '
        'octets bruts retournés tels quels', () async {
      final fake = _FakeImagePicker()
        ..result = XFile.fromData(Uint8List.fromList([9, 8, 7]));
      final picker = ImagePickerBugReportScreenshotPicker(fake);

      final bytes = await picker.pick(BugReportScreenshotSource.gallery);
      expect(bytes, [9, 8, 7]);
      expect(fake.lastSource, ImageSource.gallery);
      expect(fake.lastMaxWidth, bugReportScreenshotMaxDimension.toDouble());
      expect(fake.lastMaxHeight, bugReportScreenshotMaxDimension.toDouble());
      expect(fake.lastImageQuality, bugReportScreenshotJpegQuality);

      await picker.pick(BugReportScreenshotSource.camera);
      expect(fake.lastSource, ImageSource.camera);
    });

    test('annulation (aucun fichier) -> null', () async {
      final picker = ImagePickerBugReportScreenshotPicker(_FakeImagePicker());

      expect(await picker.pick(BugReportScreenshotSource.gallery), isNull);
    });

    for (final code in const [
      'photo_access_denied',
      'photo_access_restricted',
      'camera_access_denied',
      'camera_access_restricted',
    ]) {
      test('PlatformException $code -> accessDenied', () async {
        final fake = _FakeImagePicker()..error = PlatformException(code: code);

        await expectLater(
          ImagePickerBugReportScreenshotPicker(fake)
              .pick(BugReportScreenshotSource.camera),
          throwsA(
            const BugReportScreenshotFailure(
              BugReportScreenshotFailureKind.accessDenied,
            ),
          ),
        );
      });
    }

    test('PlatformException invalid_image -> unsupportedFormat', () async {
      final fake = _FakeImagePicker()
        ..error = PlatformException(code: 'invalid_image');

      await expectLater(
        ImagePickerBugReportScreenshotPicker(fake)
            .pick(BugReportScreenshotSource.gallery),
        throwsA(
          const BugReportScreenshotFailure(
            BugReportScreenshotFailureKind.unsupportedFormat,
          ),
        ),
      );
    });

    test('autre erreur (no_available_camera, exception quelconque) -> '
        'traitée comme une annulation', () async {
      final fake = _FakeImagePicker()
        ..error = PlatformException(code: 'no_available_camera');
      final picker = ImagePickerBugReportScreenshotPicker(fake);
      expect(await picker.pick(BugReportScreenshotSource.camera), isNull);

      fake.error = StateError('boom');
      expect(await picker.pick(BugReportScreenshotSource.gallery), isNull);
    });
  });

  group('prepare (isolat réel)', () {
    final picker = ImagePickerBugReportScreenshotPicker(_FakeImagePicker());

    test('PNG valide -> JPEG sans canal alpha', () async {
      final png = img.encodePng(
        img.Image(width: 30, height: 50, numChannels: 4)
          ..clear(img.ColorRgba8(0, 0, 0, 0)),
      );

      final jpeg = await picker.prepare(png);

      expect(jpeg.sublist(0, 3), [0xFF, 0xD8, 0xFF]);
      final decoded = img.decodeJpg(jpeg)!;
      expect(decoded.width, 30);
      expect(decoded.height, 50);
      expect(decoded.numChannels, 3);
    });

    test('octets illisibles -> BugReportScreenshotFailure unsupportedFormat '
        '(relayée depuis l\'isolat)', () async {
      await expectLater(
        picker.prepare(Uint8List.fromList(List<int>.filled(128, 7))),
        throwsA(
          const BugReportScreenshotFailure(
            BugReportScreenshotFailureKind.unsupportedFormat,
          ),
        ),
      );
    });

    test('JPEG tronqué (image corrompue) -> jamais une exception autre '
        'qu\'une BugReportScreenshotFailure', () async {
      final full = img.encodeJpg(
        img.Image(width: 64, height: 64)..clear(img.ColorRgb8(10, 20, 30)),
      );
      final truncated = Uint8List.sublistView(full, 0, full.length ~/ 3);

      try {
        final jpeg = await picker.prepare(truncated);
        expect(jpeg.sublist(0, 3), [0xFF, 0xD8, 0xFF]);
      } on BugReportScreenshotFailure catch (failure) {
        expect(failure.kind, BugReportScreenshotFailureKind.unsupportedFormat);
      }
    });

    test('octets vides -> unsupportedFormat', () async {
      await expectLater(
        picker.prepare(Uint8List(0)),
        throwsA(
          const BugReportScreenshotFailure(
            BugReportScreenshotFailureKind.unsupportedFormat,
          ),
        ),
      );
    });
  });
}
