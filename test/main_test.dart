// Tests de `AppBootstrap` (`lib/main.dart`) : affichage de [SplashScreen]
// pendant l'initialisation (Supabase/Firebase en production, substituée ici
// par un [Future] contrôlé) puis bascule automatique vers l'écran suivant
// une fois celle-ci résolue — voir la doc de classe d'`AppBootstrap`.
//
// `initialize`/`child` sont substitués ici pour ne jamais appeler
// `Supabase.initialize`/`Firebase.initializeApp` pour de vrai ni dépendre
// d'un `Supabase.instance.client` réel (voir `test/widget_test.dart`, qui
// pompe directement `NexusJdrApp` pour la même raison).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/splash/presentation/splash_screen.dart';
import 'package:personnages/main.dart';

void main() {
  testWidgets(
    'affiche SplashScreen pendant l\'initialisation, puis bascule sur '
    '`child` une fois celle-ci résolue',
    (tester) async {
      final completer = Completer<void>();

      await tester.pumpWidget(
        ProviderScope(
          child: AppBootstrap(
            initialize: () => completer.future,
            // `MaterialApp` propre (pas un simple `Scaffold` nu) : en
            // production `child` est `NexusJdrApp`, qui pose lui-même son
            // `MaterialApp.router` — `AppBootstrap` ne fournit de
            // `MaterialApp` que pour la phase [SplashScreen] (voir sa doc de
            // classe), pas pour `child`.
            child: const MaterialApp(
              home: Scaffold(body: Center(child: Text('App prête'))),
            ),
          ),
        ),
      );
      // Un seul `pump` (pas `pumpAndSettle`, qui ne terminerait jamais tant
      // que l'animation continue des 3 points de SplashScreen tourne) :
      // suffisant pour laisser le `FutureBuilder` construire son premier
      // état ("en attente").
      await tester.pump();

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('App prête'), findsNothing);

      completer.complete();
      // Un `pump` supplémentaire (toujours pas `pumpAndSettle`, même
      // rationale) pour laisser le `FutureBuilder` se reconstruire une fois
      // le `Future` résolu.
      await tester.pump();

      expect(find.byType(SplashScreen), findsNothing);
      expect(find.text('App prête'), findsOneWidget);
    },
  );

  testWidgets('n\'affiche `child` qu\'une fois, jamais avant la résolution de '
      '`initialize` (même si celle-ci échoue)', (tester) async {
    final completer = Completer<void>();

    await tester.pumpWidget(
      ProviderScope(
        child: AppBootstrap(
          initialize: () => completer.future,
          child: const MaterialApp(
            home: Scaffold(body: Center(child: Text('App prête'))),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('App prête'), findsNothing);

    completer.completeError(Exception('échec réseau simulé'));
    // `FutureBuilder` capture l'erreur dans le `snapshot` plutôt que de la
    // laisser remonter : `ConnectionState.done` est bien atteint (avec
    // `snapshot.hasError`), donc `child` s'affiche quand même — cohérent
    // avec `05-ux-navigation.md` ("l'app démarre quand même... plutôt que
    // de rester bloquée sur cet écran").
    await tester.pump();

    expect(find.text('App prête'), findsOneWidget);
  });
}
