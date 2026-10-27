// Tests du formatage du poids d'une capture (« 840 Ko » / « 1,2 Mo »).

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/bug_report/domain/bug_report_screenshot.dart';

void main() {
  group('formatBugReportScreenshotSize', () {
    test('sous 1 Mo : en Ko arrondis, au moins 1 Ko', () {
      expect(formatBugReportScreenshotSize(0), '1 Ko');
      expect(formatBugReportScreenshotSize(300), '1 Ko');
      expect(formatBugReportScreenshotSize(840 * 1024), '840 Ko');
      expect(formatBugReportScreenshotSize(1000 * 1024 + 300), '1000 Ko');
    });

    test('à partir de 1 Mo : une décimale, virgule française', () {
      expect(formatBugReportScreenshotSize(1024 * 1024), '1,0 Mo');
      expect(
        formatBugReportScreenshotSize((1.2 * 1024 * 1024).round()),
        '1,2 Mo',
      );
      expect(
        formatBugReportScreenshotSize(bugReportScreenshotMaxBytes),
        '5,0 Mo',
      );
    });

    test("juste sous 1 Mo mais arrondi à 1024 Ko : affiché en Mo", () {
      expect(formatBugReportScreenshotSize(1024 * 1024 - 100), '1,0 Mo');
    });
  });

  test('limite = file_size_limit du bucket (5 242 880 octets)', () {
    expect(bugReportScreenshotMaxBytes, 5242880);
  });
}
