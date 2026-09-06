// Tests de widget de l'étape 1/3 "Code" du flux "Rejoindre un groupe".

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/groups/presentation/group_join_code_step_screen.dart';

GoRouter _buildTestRouter() {
  return GoRouter(
    initialLocation: '/groups/join',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Liste des personnages'))),
      ),
      GoRoute(
        path: '/groups/join',
        builder: (context, state) => GroupJoinCodeStepScreen(
          initialCode: state.uri.queryParameters['code'],
        ),
      ),
      GoRoute(
        path: '/groups/join/step-2',
        builder: (context, state) => Scaffold(
          body: Center(
            child: Text('Confirmation ${state.uri.queryParameters['code']}'),
          ),
        ),
      ),
    ],
  );
}

Widget _buildTestWidget() {
  return MaterialApp.router(routerConfig: _buildTestRouter());
}

bool _isPrimaryButtonEnabled(WidgetTester tester) {
  final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
  return button.onPressed != null;
}

void main() {
  testWidgets('affiche le titre d\'étape et "Étape 1 / 3"', (tester) async {
    await tester.pumpWidget(_buildTestWidget());

    expect(find.text('REJOINDRE'), findsOneWidget);
    expect(find.text('Code'), findsOneWidget);
    expect(find.text('Étape 1 / 3'), findsOneWidget);
  });

  testWidgets('sous-texte propre au groupe ("créateur du groupe")', (
    tester,
  ) async {
    await tester.pumpWidget(_buildTestWidget());

    expect(
      find.textContaining('Code fourni par le créateur du groupe'),
      findsOneWidget,
    );
  });

  testWidgets(
    '"Suivant" est désactivé tant que le code fait moins de 6 caractères',
    (tester) async {
      await tester.pumpWidget(_buildTestWidget());

      expect(_isPrimaryButtonEnabled(tester), isFalse);

      await tester.enterText(find.byType(TextField), 'AB3F');
      await tester.pump();

      expect(_isPrimaryButtonEnabled(tester), isFalse);
    },
  );

  testWidgets(
    '"Suivant" devient actif à partir de 6 caractères et pousse l\'étape '
    '2/3 avec le code saisi (en majuscules)',
    (tester) async {
      await tester.pumpWidget(_buildTestWidget());

      await tester.enterText(find.byType(TextField), 'ab3f7k');
      await tester.pump();

      expect(_isPrimaryButtonEnabled(tester), isTrue);

      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      expect(find.text('Confirmation AB3F7K'), findsOneWidget);
    },
  );

  testWidgets('le champ est pré-rempli via initialCode', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: GroupJoinCodeStepScreen(initialCode: 'ZZ9988')),
      ),
    );

    expect(find.text('ZZ9988'), findsOneWidget);
  });

  testWidgets(
    'le retour arrière ramène à la liste des personnages quand il n\'y a '
    'rien à dépiler',
    (tester) async {
      await tester.pumpWidget(_buildTestWidget());

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();

      expect(find.text('Liste des personnages'), findsOneWidget);
    },
  );
}
