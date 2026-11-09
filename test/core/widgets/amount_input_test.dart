import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/amount_input.dart';

void main() {
  group('parseAmountInput', () {
    test('vide ou non numérique donne 0', () {
      expect(parseAmountInput('', max: 100), 0);
      expect(parseAmountInput('abc', max: 100), 0);
    });

    test('entier simple', () {
      expect(parseAmountInput('27', max: 100), 27);
    });

    test('borné à max', () {
      expect(parseAmountInput('250', max: 100), 100);
      expect(parseAmountInput('99999999999999999999999', max: 100), 100);
    });

    test('collage tolérant : espaces, séparateurs et unités ignorés', () {
      expect(parseAmountInput('1 234', max: 9999), 1234);
      expect(parseAmountInput('12 PO', max: 9999), 12);
      expect(parseAmountInput('-5', max: 9999), 5);
    });
  });

  group('répétition accélérée', () {
    test('le pas augmente avec les ticks', () {
      expect(amountRepeatStep(0), 1);
      expect(amountRepeatStep(9), 1);
      expect(amountRepeatStep(10), 5);
      expect(amountRepeatStep(24), 5);
      expect(amountRepeatStep(25), 10);
    });

    test('le délai diminue puis plafonne à 60 ms', () {
      expect(amountRepeatDelay(0), const Duration(milliseconds: 300));
      expect(
        amountRepeatDelay(5).inMilliseconds,
        lessThan(amountRepeatDelay(0).inMilliseconds),
      );
      expect(amountRepeatDelay(100), const Duration(milliseconds: 60));
    });

    // Horloge fake du binding de test : `tester.pump(duration)` avance le
    // temps et déclenche les Timer.
    testWidgets('AmountRepeater : ticks à intervalle décroissant, stop '
        'annule le Timer', (tester) async {
      final repeater = AmountRepeater();
      final steps = <int>[];
      repeater.start(steps.add);
      expect(repeater.isRunning, isTrue);

      await tester.pump(const Duration(milliseconds: 300));
      expect(steps, [1]);
      await tester.pump(amountRepeatDelay(1));
      expect(steps, [1, 1]);

      repeater.stop();
      expect(repeater.isRunning, isFalse);
      await tester.pump(const Duration(seconds: 5));
      expect(steps.length, 2);
    });

    testWidgets('dispose annule le Timer en cours', (tester) async {
      final repeater = AmountRepeater()..start((_) {});
      repeater.dispose();
      expect(repeater.isRunning, isFalse);
      // Un Timer restant ferait échouer le test en fin d'exécution.
    });

    testWidgets('le pas passe à 5 puis 10 sur un appui long soutenu', (
      tester,
    ) async {
      final repeater = AmountRepeater();
      final steps = <int>[];
      repeater.start(steps.add);
      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      repeater.stop();
      expect(steps.first, 1);
      expect(steps, contains(5));
      expect(steps.last, 10);
    });
  });
}
