// Tests du chemin de téléversement d'une capture de signalement — contrat
// `report-bug` : `<auth.uid() en minuscules>/<fichier>`, un seul niveau de
// dossier, nom 1-128 caractères `[A-Za-z0-9._-]` sans `.` en tête.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/bug_report/data/bug_report_screenshot_path.dart';

final RegExp _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);
final RegExp _contractFileName = RegExp(
  r'^[A-Za-z0-9_-][A-Za-z0-9._-]{0,127}$',
);

void main() {
  group('buildBugReportScreenshotPath', () {
    test('préfixe = uid en minuscules, un seul niveau de dossier, .jpg', () {
      final path = buildBugReportScreenshotPath(
        userId: 'AB12CD34-EF56-4A78-9B0C-DEF012345678',
        fileId: '3f2a9c1e-7b4d-4e8f-9a01-23456789abcd',
      );

      expect(
        path,
        'ab12cd34-ef56-4a78-9b0c-def012345678/'
        '3f2a9c1e-7b4d-4e8f-9a01-23456789abcd.jpg',
      );
      expect(path.startsWith('/'), isFalse);
      expect(path.contains(bugReportScreenshotBucket), isFalse);
      expect('/'.allMatches(path), hasLength(1));
    });

    test('nom de fichier conforme au contrat avec un id généré', () {
      for (var seed = 0; seed < 50; seed++) {
        final path = buildBugReportScreenshotPath(
          userId: 'user-id',
          fileId: generateBugReportScreenshotId(Random(seed)),
        );
        final fileName = path.split('/').last;
        expect(fileName, matches(_contractFileName));
      }
    });
  });

  group('generateBugReportScreenshotId', () {
    test('UUID v4 en minuscules (version et variante RFC)', () {
      for (var seed = 0; seed < 200; seed++) {
        expect(generateBugReportScreenshotId(Random(seed)), matches(_uuidV4));
      }
    });

    test('aléatoire sécurisé par défaut : deux appels diffèrent', () {
      expect(
        generateBugReportScreenshotId(),
        isNot(generateBugReportScreenshotId()),
      );
      expect(generateBugReportScreenshotId(), matches(_uuidV4));
    });
  });
}
