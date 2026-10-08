import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/crash_reporting/crash_reporter.dart';

void main() {
  test('reportNonFatal ne lève jamais, meme sans Firebase initialise (etat de tout `flutter test`)', () async {
    expect(
      () => reportNonFatal(Exception('boom'), StackTrace.current, reason: 'test'),
      returnsNormally,
    );
    // Laisse le temps a la micro-tache interne (Future(() => ...)) de
    // s'executer et d'echouer silencieusement avant la fin du test, pour
    // verifier qu'aucune erreur non geree ne remonte a la zone du test
    // (ce qui ferait echouer flutter test avec "Unhandled exception").
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
}
