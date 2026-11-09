// F21 (`docs/retours-utilisateurs.md`) : le splash ne doit jamais déborder,
// même avec une police système fortement agrandie sur un petit écran.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/splash/presentation/splash_screen.dart';

void main() {
  const surfaces = <Size>[
    Size(360, 640),
    Size(320, 568),
    Size(480, 800),
    Size(320, 533),
    Size(240, 400),
  ];
  const scales = <double>[1.3, 2.0];

  for (final surface in surfaces) {
    for (final scale in scales) {
      testWidgets(
        '${surface.width.toInt()}x${surface.height.toInt()} police x$scale : '
        'aucun débordement',
        (tester) async {
          await tester.binding.setSurfaceSize(surface);
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: const SplashScreen(),
            ),
          );

          expect(tester.takeException(), isNull);
          expect(find.text('NEXUS JDR'), findsOneWidget);
          expect(find.text('Préparation de la taverne…'), findsOneWidget);
        },
      );
    }
  }
}
