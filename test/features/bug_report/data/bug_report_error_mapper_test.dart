// Tests unitaires de `mapBugReportError` — voir sa documentation pour le
// rationale de l'extraction en fonction pure (même principe que
// `mapStoryInviteError`), testable sans réseau (`FunctionsHttpException` se
// construit directement).

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/bug_report/data/bug_report_error_mapper.dart';
import 'package:personnages/features/bug_report/domain/bug_report_failure.dart';
import 'package:personnages/features/bug_report/domain/bug_report_screenshot.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('mapBugReportError', () {
    test('FunctionsHttpException avec un `message` exploitable -> '
        'BugReportFailure porte ce message', () {
      final failure = mapBugReportError(
        const FunctionsHttpException(
          status: 400,
          details: {'error': 'invalid_body', 'message': 'Titre requis.'},
        ),
      );

      expect(failure, isA<BugReportFailure>());
      expect(failure.message, 'Titre requis.');
    });

    test('FunctionsHttpException sans corps JSON exploitable -> message '
        'générique, sans lever d\'exception', () {
      final failure = mapBugReportError(
        const FunctionsHttpException(status: 500, details: 'texte brut'),
      );

      expect(failure.message, genericBugReportErrorMessage);
    });

    test(
      'FunctionsHttpException avec un `message` vide -> message générique',
      () {
        final failure = mapBugReportError(
          const FunctionsHttpException(
            status: 401,
            details: {'error': 'unauthorized', 'message': ''},
          ),
        );

        expect(failure.message, genericBugReportErrorMessage);
      },
    );

    test('FunctionsFetchException (pas de réponse reçue, ex. hors ligne) -> '
        'message générique', () {
      final failure = mapBugReportError(
        const FunctionsFetchException(details: 'network unreachable'),
      );

      expect(failure.message, genericBugReportErrorMessage);
    });

    test('toute autre exception inattendue -> message générique', () {
      final failure = mapBugReportError(StateError('boom'));

      expect(failure.message, genericBugReportErrorMessage);
    });
  });

  group('mapBugReportError — catégorie', () {
    test('screenshot_not_found -> screenshotUpload', () {
      final failure = mapBugReportError(
        const FunctionsHttpException(
          status: 400,
          details: {'error': 'screenshot_not_found', 'message': 'Absente.'},
        ),
      );

      expect(failure.kind, BugReportFailureKind.screenshotUpload);
      expect(failure.message, 'Absente.');
    });

    test('screenshot_not_found sans message -> message de diagnostic par '
        'défaut', () {
      final failure = mapBugReportError(
        const FunctionsHttpException(
          status: 400,
          details: {'error': 'screenshot_not_found'},
        ),
      );

      expect(failure.kind, BugReportFailureKind.screenshotUpload);
      expect(failure.message, screenshotUploadBugReportErrorMessage);
    });

    for (final code in ['invalid_body', 'unauthorized', 'internal_error']) {
      test('$code -> generic', () {
        final failure = mapBugReportError(
          FunctionsHttpException(status: 400, details: {'error': code}),
        );

        expect(failure.kind, BugReportFailureKind.generic);
      });
    }

    test('exception réseau -> generic', () {
      expect(
        mapBugReportError(const FunctionsFetchException(details: 'x')).kind,
        BugReportFailureKind.generic,
      );
    });
  });

  group('mapBugReportScreenshotUploadError', () {
    test('StorageException -> screenshotUpload, message conservé', () {
      final failure = mapBugReportScreenshotUploadError(
        const StorageException('RLS refusée', statusCode: '403'),
      );

      expect(failure.kind, BugReportFailureKind.screenshotUpload);
      expect(failure.message, 'RLS refusée');
    });

    test('toute autre exception -> screenshotUpload, message par défaut', () {
      final failure = mapBugReportScreenshotUploadError(StateError('boom'));

      expect(failure.kind, BugReportFailureKind.screenshotUpload);
      expect(failure.message, screenshotUploadBugReportErrorMessage);
    });
  });

  group('mapBugReportScreenshotPickError', () {
    for (final code in [
      'photo_access_denied',
      'photo_access_restricted',
      'camera_access_denied',
      'camera_access_restricted',
    ]) {
      test('$code -> accessDenied', () {
        expect(
          mapBugReportScreenshotPickError(PlatformException(code: code)),
          const BugReportScreenshotFailure(
            BugReportScreenshotFailureKind.accessDenied,
          ),
        );
      });
    }

    test('invalid_image -> unsupportedFormat', () {
      expect(
        mapBugReportScreenshotPickError(
          PlatformException(code: 'invalid_image'),
        ),
        const BugReportScreenshotFailure(
          BugReportScreenshotFailureKind.unsupportedFormat,
        ),
      );
    });

    test('autre code (no_available_camera) ou autre exception -> null '
        '(traité comme une annulation)', () {
      expect(
        mapBugReportScreenshotPickError(
          PlatformException(code: 'no_available_camera'),
        ),
        isNull,
      );
      expect(mapBugReportScreenshotPickError(StateError('boom')), isNull);
    });
  });
}
