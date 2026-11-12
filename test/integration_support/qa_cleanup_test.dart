import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/support/qa_cleanup.dart';

void main() {
  group('requireQaCharacterName', () {
    test('accepte un nom préfixé QA-', () {
      expect(requireQaCharacterName('QA-x'), 'QA-x');
      expect(requireQaCharacterName('QA-Test-Barde-123'), 'QA-Test-Barde-123');
    });

    test('refuse un nom sans préfixe QA- (StateError)', () {
      expect(() => requireQaCharacterName('Magnus'), throwsStateError);
      expect(() => requireQaCharacterName(''), throwsStateError);
      expect(() => requireQaCharacterName('qa-x'), throwsStateError);
      expect(() => requireQaCharacterName('Test-QA-x'), throwsStateError);
    });

    test('registerQaCharacterCleanup refuse un nom réel avant tout '
        'enregistrement', () {
      expect(() => registerQaCharacterCleanup('Magnus'), throwsStateError);
    });
  });
}
