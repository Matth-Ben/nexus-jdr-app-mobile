// Tests unitaires de `JoinRoutes` — voir sa documentation de classe pour le
// rationale (échappement correct de `code` via `Uri(...)` plutôt qu'une
// interpolation de chaîne, pour ne pas tronquer/injecter un caractère
// spécial d'URL comme `#`/`&` résolu brut depuis le deep link
// `/join/:code`).

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/join_story/presentation/join_routes.dart';

void main() {
  group('JoinRoutes.code', () {
    test('sans code initial : "/join" nu', () {
      expect(JoinRoutes.code(), '/join');
    });

    test('avec un code initial simple : query ?code=...', () {
      expect(JoinRoutes.code(initialCode: 'AB3F7K'), '/join?code=AB3F7K');
    });

    test('un code contenant "#"/"&" est correctement encodé, jamais '
        'interpolé brut', () {
      final route = JoinRoutes.code(initialCode: 'AB#F&K');

      expect(route, isNot(contains('#F&K')));
      expect(Uri.parse(route).queryParameters['code'], 'AB#F&K');
    });
  });

  group('JoinRoutes.confirmation', () {
    test('code simple : query ?code=...', () {
      expect(JoinRoutes.confirmation('AB3F7K'), '/join/step-2?code=AB3F7K');
    });

    test('un code contenant "#" ne tronque jamais la query (round-trip '
        'complet)', () {
      final route = JoinRoutes.confirmation('AB#F7K');

      expect(Uri.parse(route).queryParameters['code'], 'AB#F7K');
    });

    test('un code contenant "&" n\'injecte jamais de paramètre de query '
        'supplémentaire (round-trip complet)', () {
      final route = JoinRoutes.confirmation('AB&F7K');

      final uri = Uri.parse(route);
      expect(uri.queryParameters['code'], 'AB&F7K');
      expect(uri.queryParameters.length, 1);
    });
  });

  group('JoinRoutes.character', () {
    test('code simple : query ?code=...', () {
      expect(JoinRoutes.character('AB3F7K'), '/join/step-3?code=AB3F7K');
    });

    test('un code contenant un caractère spécial d\'URL est correctement '
        'échappé (round-trip complet)', () {
      final route = JoinRoutes.character('AB#F&K');

      expect(Uri.parse(route).queryParameters['code'], 'AB#F&K');
    });
  });
}
