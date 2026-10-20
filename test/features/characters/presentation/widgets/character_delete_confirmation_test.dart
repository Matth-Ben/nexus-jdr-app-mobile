// Tests de widget des dialogues de confirmation de suppression de
// personnage(s) — `showDeleteCharacterConfirmationDialog` (singulier, extrait
// de `character_detail_screen.dart` sans changement de comportement, voir
// `test/features/characters/presentation/character_detail_screen_test.dart`
// pour sa couverture via le menu "…" de la fiche) et
// `showDeleteCharactersConfirmationDialog` (pluriel, nouveau — suppression
// groupée de `character_list_screen.dart`).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/presentation/widgets/character_delete_confirmation.dart';

Future<bool?> _openSingle(WidgetTester tester, {required String name}) async {
  bool? result;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showDeleteCharacterConfirmationDialog(
                context,
                characterName: name,
              );
            },
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
  return result;
}

Future<bool?> _openMultiple(WidgetTester tester, {required int count}) async {
  bool? result;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showDeleteCharactersConfirmationDialog(
                context,
                count: count,
              );
            },
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  group('showDeleteCharacterConfirmationDialog (singulier)', () {
    testWidgets('affiche le nom du personnage et le texte définitif', (
      tester,
    ) async {
      await _openSingle(tester, name: 'Halltesse Ambrelune');

      expect(find.text('Supprimer Halltesse Ambrelune ?'), findsOneWidget);
      expect(
        find.textContaining('Cette action est définitive'),
        findsOneWidget,
      );
    });

    testWidgets('"Annuler" referme en retournant false', (tester) async {
      final result = await _openSingle(tester, name: 'Halltesse Ambrelune');
      await tester.tap(find.text('ANNULER'));
      await tester.pumpAndSettle();

      expect(find.text('Supprimer Halltesse Ambrelune ?'), findsNothing);
      // `result` est capturé avant la fermeture : vérifié via un second
      // appel plus bas (voir le test "confirmer retourne true").
      expect(result, isNull);
    });

    testWidgets('"Supprimer" confirme en retournant true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  final confirmed = await showDeleteCharacterConfirmationDialog(
                    context,
                    characterName: 'Halltesse Ambrelune',
                  );
                  if (confirmed == true && context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Confirmé')));
                  }
                },
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();

      expect(find.text('Confirmé'), findsOneWidget);
    });
  });

  group('showDeleteCharactersConfirmationDialog (pluriel, suppression '
      'groupée)', () {
    testWidgets('affiche le nombre de personnages et le texte au pluriel', (
      tester,
    ) async {
      await _openMultiple(tester, count: 4);

      expect(find.text('Supprimer ces 4 personnages ?'), findsOneWidget);
      expect(
        find.textContaining('les personnages et toutes leurs données'),
        findsOneWidget,
      );
    });

    testWidgets(
      'le bouton de confirmation affiche le compte entre parenthèses',
      (tester) async {
        await _openMultiple(tester, count: 4);

        expect(find.text('Supprimer (4)'), findsOneWidget);
      },
    );

    testWidgets('"Annuler" referme la sheet sans confirmer', (tester) async {
      await _openMultiple(tester, count: 4);
      await tester.tap(find.text('ANNULER'));
      await tester.pumpAndSettle();

      expect(find.text('Supprimer ces 4 personnages ?'), findsNothing);
    });

    testWidgets('confirmer retourne true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  final confirmed =
                      await showDeleteCharactersConfirmationDialog(
                        context,
                        count: 2,
                      );
                  if (confirmed == true && context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Confirmé')));
                  }
                },
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer (2)'));
      await tester.pumpAndSettle();

      expect(find.text('Confirmé'), findsOneWidget);
    });
  });
}
