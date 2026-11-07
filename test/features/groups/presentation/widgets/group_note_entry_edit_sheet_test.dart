// Tests de widget de la sheet "Ajouter une note"/"Modifier la note"
// (`presentation/widgets/group_note_entry_edit_sheet.dart`) — pattern
// autoportant calqué sur
// `character_journal_entry_edit_sheet_test.dart` : bandeau d'erreur inline
// (échec réseau/générique) avec texte saisi préservé, `closeEnabled`
// désactivé pendant la sauvegarde. Le cas "mode ajout, tap Enregistrer,
// succès" est déjà exercé de bout en bout par
// `group_notes_tab_body_test.dart` — ce fichier se concentre sur les
// chemins d'échec/validation propres à la sheet elle-même, et sur le champ
// titre optionnel.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/core/widgets/secondary_button.dart';
import 'package:personnages/core/widgets/sheet_header_bar.dart';
import 'package:personnages/features/groups/data/group_repository.dart';
import 'package:personnages/features/groups/domain/group_failure.dart';
import 'package:personnages/features/groups/domain/group_note_entry.dart';
import 'package:personnages/features/groups/presentation/providers/group_providers.dart';
import 'package:personnages/features/groups/presentation/widgets/group_note_entry_edit_sheet.dart';

class _FakeGroupRepository implements GroupRepository {
  final Completer<void> gate = Completer<void>();
  bool gateAdd = false;

  int addCallCount = 0;
  String? lastAddedTitle;
  String? lastAddedBody;
  Object? addError;

  int updateCallCount = 0;
  String? lastUpdatedEntryId;
  String? lastUpdatedTitle;
  String? lastUpdatedBody;
  Object? updateError;

  @override
  Future<void> addGroupNoteEntry({
    required String groupId,
    String? title,
    required String body,
  }) async {
    addCallCount++;
    lastAddedTitle = title;
    lastAddedBody = body;
    if (gateAdd) await gate.future;
    final error = addError;
    if (error != null) throw error;
  }

  @override
  Future<void> updateGroupNoteEntry({
    required String entryId,
    String? title,
    required String body,
  }) async {
    updateCallCount++;
    lastUpdatedEntryId = entryId;
    lastUpdatedTitle = title;
    lastUpdatedBody = body;
    final error = updateError;
    if (error != null) throw error;
  }

  @override
  Future<void> deleteGroupNoteEntry(String entryId) =>
      throw UnimplementedError();

  @override
  Future<List<GroupNoteEntry>> fetchGroupNoteEntries(String groupId) async =>
      const [];

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Future<_FakeGroupRepository> _pumpSheet(WidgetTester tester) async {
  final repository = _FakeGroupRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [groupRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () =>
                    showGroupNoteEntryEditSheet(context, groupId: 'group-1'),
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets('mode ajout : titre "AJOUTER UNE NOTE", champs vides', (
    tester,
  ) async {
    await _pumpSheet(tester);

    expect(find.text('AJOUTER UNE NOTE'), findsOneWidget);
    final fields = tester.widgetList<TextFormField>(
      find.byType(TextFormField),
    );
    for (final field in fields) {
      expect(field.controller!.text, isEmpty);
    }
  });

  testWidgets(
    'titre renseigné + corps renseigné : addGroupNoteEntry reçoit les deux',
    (tester) async {
      final repository = await _pumpSheet(tester);

      await tester.enterText(find.byType(TextFormField).first, 'Chapitre 1');
      await tester.enterText(
        find.byType(TextFormField).last,
        'Note de séance.',
      );
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pumpAndSettle();

      expect(repository.addCallCount, 1);
      expect(repository.lastAddedTitle, 'Chapitre 1');
      expect(repository.lastAddedBody, 'Note de séance.');
    },
  );

  testWidgets(
    'titre vide (optionnel) : addGroupNoteEntry reçoit title null',
    (tester) async {
      final repository = await _pumpSheet(tester);

      await tester.enterText(
        find.byType(TextFormField).last,
        'Note sans titre.',
      );
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pumpAndSettle();

      expect(repository.addCallCount, 1);
      expect(repository.lastAddedTitle, isNull);
      expect(repository.lastAddedBody, 'Note sans titre.');
    },
  );

  testWidgets('corps vide : Enregistrer ne fait rien (aucun appel, sheet '
      'reste ouverte)', (tester) async {
    final repository = await _pumpSheet(tester);

    await tester.enterText(find.byType(TextFormField).first, 'Un titre.');
    await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
    await tester.pumpAndSettle();

    expect(repository.addCallCount, 0);
    expect(find.text('AJOUTER UNE NOTE'), findsOneWidget);
  });

  testWidgets(
    'pendant la sauvegarde : bouton "Enregistrer" en isLoading, "Annuler" '
    'et le X du SheetHeaderBar désactivés',
    (tester) async {
      final repository = await _pumpSheet(tester);
      repository.gateAdd = true;

      await tester.enterText(find.byType(TextFormField).last, 'Note.');
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pump();

      final primaryButton = tester.widget<PrimaryButton>(
        find.byType(PrimaryButton),
      );
      expect(primaryButton.isLoading, isTrue);

      final secondaryButton = tester.widget<SecondaryButton>(
        find.widgetWithText(SecondaryButton, 'ANNULER'),
      );
      expect(secondaryButton.onPressed, isNull);

      final header = tester.widget<SheetHeaderBar>(find.byType(SheetHeaderBar));
      expect(header.closeEnabled, isFalse);

      repository.gate.complete();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'GroupFailure : bandeau d\'alerte inline affiche failure.message, '
    'sheet reste ouverte, texte saisi préservé',
    (tester) async {
      final repository = await _pumpSheet(tester);
      repository.addError = const GroupFailure('Erreur serveur.');

      await tester.enterText(find.byType(TextFormField).last, 'Note en cours.');
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pumpAndSettle();

      expect(find.text('Erreur serveur.'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).last)
            .controller!
            .text,
        'Note en cours.',
      );
    },
  );

  testWidgets(
    'échec inattendu (pas une GroupFailure) : bandeau générique',
    (tester) async {
      final repository = await _pumpSheet(tester);
      repository.addError = Exception('boom');

      await tester.enterText(find.byType(TextFormField).last, 'Note.');
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pumpAndSettle();

      expect(
        find.text('Impossible d\'enregistrer cette note. Réessayez.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('"Annuler" ferme la sheet sans appeler addGroupNoteEntry', (
    tester,
  ) async {
    final repository = await _pumpSheet(tester);

    await tester.tap(find.widgetWithText(SecondaryButton, 'ANNULER'));
    await tester.pumpAndSettle();

    expect(repository.addCallCount, 0);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets(
    'mode édition (entry non nul) : titre "MODIFIER LA NOTE", champs '
    'préremplis, appelle updateGroupNoteEntry',
    (tester) async {
      final repository = _FakeGroupRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => showGroupNoteEntryEditSheet(
                      context,
                      groupId: 'group-1',
                      entry: GroupNoteEntry(
                        id: 'entry-1',
                        title: 'Chapitre 1',
                        body: 'Note existante.',
                        createdAt: DateTime(2026, 9, 1),
                      ),
                    ),
                    child: const Text('Ouvrir'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      expect(find.text('MODIFIER LA NOTE'), findsOneWidget);
      expect(find.text('Chapitre 1'), findsOneWidget);
      expect(find.text('Note existante.'), findsOneWidget);

      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pumpAndSettle();

      expect(repository.updateCallCount, 1);
      expect(repository.lastUpdatedEntryId, 'entry-1');
      expect(repository.lastUpdatedTitle, 'Chapitre 1');
      expect(repository.lastUpdatedBody, 'Note existante.');
    },
  );
}
