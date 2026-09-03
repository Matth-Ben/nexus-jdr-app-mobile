// Tests unitaires de `mapBugReportError` — voir sa documentation pour le
// rationale de l'extraction en fonction pure (même principe que
// `mapStoryInviteError`), testable sans réseau (`FunctionsHttpException` se
// construit directement).

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/bug_report/data/bug_report_error_mapper.dart';
import 'package:personnages/features/bug_report/domain/bug_report_failure.dart';
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
}
