import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/numeric_amount_stepper.dart';

class _Host extends StatefulWidget {
  const _Host({this.max = 100, this.initial = 0, this.onValue});

  final int max;
  final int initial;
  final ValueChanged<int>? onValue;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late int value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: NumericAmountStepper(
            value: value,
            max: widget.max,
            decrementLabel: 'Diminuer',
            incrementLabel: 'Augmenter',
            onChanged: (v) {
              widget.onValue?.call(v);
              setState(() => value = v);
            },
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('saisie au clavier : 27 -> valeur 27', (tester) async {
    int? last;
    await tester.pumpWidget(_Host(onValue: (v) => last = v));
    await tester.enterText(find.byType(TextField), '27');
    expect(last, 27);
  });

  testWidgets('saisie écrêtée à max', (tester) async {
    int? last;
    await tester.pumpWidget(_Host(max: 50, onValue: (v) => last = v));
    await tester.enterText(find.byType(TextField), '99');
    await tester.pump();
    expect(last, 50);
    expect(find.text('50'), findsOneWidget);
  });

  testWidgets('chiffres seulement : lettres et espaces filtrés', (
    tester,
  ) async {
    int? last;
    await tester.pumpWidget(_Host(max: 9999, onValue: (v) => last = v));
    await tester.enterText(find.byType(TextField), '1 2a3');
    expect(last, 123);
  });

  testWidgets('champ vidé = 0', (tester) async {
    int? last;
    await tester.pumpWidget(_Host(initial: 12, onValue: (v) => last = v));
    await tester.enterText(find.byType(TextField), '');
    expect(last, 0);
  });

  testWidgets('tap sur + / - : un pas de 1, sans dépasser les bornes', (
    tester,
  ) async {
    int? last;
    await tester.pumpWidget(_Host(max: 1, onValue: (v) => last = v));
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(last, 1);
    // À max : "+" inerte.
    last = null;
    await tester.tap(find.byIcon(Icons.add), warnIfMissed: false);
    await tester.pump();
    expect(last, isNull);
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();
    expect(last, 0);
    last = null;
    await tester.tap(find.byIcon(Icons.remove), warnIfMissed: false);
    await tester.pump();
    expect(last, isNull);
  });

  testWidgets('appui long sur + : répétition accélérée, arrêt au '
      'relâchement', (tester) async {
    int? last;
    await tester.pumpWidget(_Host(max: 9999, onValue: (v) => last = v));
    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.add)),
    );
    await tester.pump(const Duration(milliseconds: 600)); // long press
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(last, greaterThan(30)); // accéléré : bien plus que 1 par tick
    await gesture.up();
    await tester.pump();
    final atRelease = last;
    await tester.pump(const Duration(seconds: 3));
    expect(last, atRelease);
  });

  testWidgets('appui long sur - ne descend pas sous 0', (tester) async {
    int? last;
    await tester.pumpWidget(
      _Host(initial: 3, max: 9999, onValue: (v) => last = v),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.remove)),
    );
    await tester.pump(const Duration(milliseconds: 600));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await gesture.up();
    await tester.pump();
    expect(last, 0);
  });

  testWidgets('démontage pendant un appui long : aucun Timer en attente', (
    tester,
  ) async {
    await tester.pumpWidget(const _Host(max: 9999));
    await tester.startGesture(tester.getCenter(find.byIcon(Icons.add)));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    // Le framework échoue en fin de test s'il reste un Timer actif.
  });

  testWidgets('cibles tactiles >= 44 px', (tester) async {
    await tester.pumpWidget(const _Host());
    final size = tester.getSize(
      find
          .ancestor(
            of: find.byIcon(Icons.add),
            matching: find.byType(GestureDetector),
          )
          .first,
    );
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
  });
}
