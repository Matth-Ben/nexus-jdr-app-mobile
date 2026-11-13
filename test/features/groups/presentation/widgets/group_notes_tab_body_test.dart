// Tests de widget de la liste "Notes" de l'écran "Groupe"
// (`presentation/widgets/group_notes_tab_body.dart`) — fractionnement en
// entrées multiples du 07/11/2026.
//
// `GroupNotesTabBody` porte elle-même les actions d'ajout/modification/
// suppression (voir sa documentation de classe) : le dépôt de test
// (`_FakeGroupRepository`) est injecté via `overrideWithValue`, même
// principe que `character_journal_card_test.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/groups/data/group_repository.dart';
import 'package:personnages/features/groups/domain/group_failure.dart';
import 'package:personnages/features/groups/domain/group_note_entry.dart';
import 'package:personnages/features/groups/presentation/providers/group_providers.dart';
import 'package:personnages/features/groups/presentation/widgets/group_notes_tab_body.dart';

/// Double minimal — seules les 3 méthodes d'écriture du carnet de notes
/// sont exercées par `GroupNotesTabBody`/sa sheet, le reste lève
/// `UnimplementedError` (jamais atteint par ces tests).
class _FakeGroupRepository implements GroupRepository {
  @override
  Future<List<String>> fetchGroupIdsForCharacter(String characterId) async =>
      const [];

  int addCallCount = 0;
  String? lastAddedTitle;
  String? lastAddedBody;
  Object? addError;

  int updateCallCount = 0;
  String? lastUpdatedEntryId;
  String? lastUpdatedTitle;
  String? lastUpdatedBody;
  Object? updateError;

  int deleteCallCount = 0;
  String? lastDeletedEntryId;
  Object? deleteError;

  @override
  Future<void> addGroupNoteEntry({
    required String groupId,
    String? title,
    required String body,
  }) async {
    addCallCount++;
    lastAddedTitle = title;
    lastAddedBody = body;
    if (addError != null) throw addError!;
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
    if (updateError != null) throw updateError!;
  }

  @override
  Future<void> deleteGroupNoteEntry(String entryId) async {
    deleteCallCount++;
    lastDeletedEntryId = entryId;
    if (deleteError != null) throw deleteError!;
  }

  @override
  Future<List<GroupNoteEntry>> fetchGroupNoteEntries(String groupId) async =>
      const [];

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Future<void> _pump(
  WidgetTester tester, {
  required List<GroupNoteEntry> entries,
  required _FakeGroupRepository repository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [groupRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        home: Scaffold(
          body: GroupNotesTabBody(groupId: 'group-1', entries: entries),
        ),
      ),
    ),
  );
}

void main() {
  late _FakeGroupRepository fakeRepository;

  setUp(() {
    fakeRepository = _FakeGroupRepository();
  });

  final entry1 = GroupNoteEntry(
    id: 'entry-1',
    body: 'Première séance, sans titre.',
    createdAt: DateTime(2026, 9, 1, 20, 0),
  );
  final entry2 = GroupNoteEntry(
    id: 'entry-2',
    title: 'Chapitre 2',
    body: 'Combat contre les gobelins de la mine.',
    createdAt: DateTime(2026, 9, 8, 20, 30),
  );

  testWidgets('liste vide : état vide + tuile "Ajouter une note" visible', (
    tester,
  ) async {
    await _pump(tester, entries: const [], repository: fakeRepository);

    expect(find.text('Aucune note pour l\'instant.'), findsOneWidget);
    expect(find.text('Ajouter une note'), findsOneWidget);
  });

  testWidgets('plusieurs entrées (avec et sans titre) : une ligne par entrée, '
      'séparées par un Divider', (tester) async {
    await _pump(tester, entries: [entry2, entry1], repository: fakeRepository);

    expect(find.text('Chapitre 2'), findsOneWidget);
    expect(find.text('Combat contre les gobelins de la mine.'), findsOneWidget);
    expect(find.text('8 septembre 2026 · 20:30'), findsOneWidget);
    expect(find.text('Première séance, sans titre.'), findsOneWidget);
    expect(find.text('1 septembre 2026 · 20:00'), findsOneWidget);
    expect(find.byType(Divider), findsOneWidget);
    expect(find.text('Ajouter une note'), findsOneWidget);
  });

  testWidgets('"Ajouter une note" ouvre la sheet ; titre + corps + Enregistrer '
      'appelle addGroupNoteEntry', (tester) async {
    await _pump(tester, entries: const [], repository: fakeRepository);

    await tester.tap(find.text('Ajouter une note'));
    await tester.pumpAndSettle();

    expect(find.text('AJOUTER UNE NOTE'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Chapitre 1');
    await tester.enterText(
      find.byType(TextFormField).last,
      'Butin trouvé : 50 po.',
    );
    await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
    await tester.pumpAndSettle();

    expect(fakeRepository.addCallCount, 1);
    expect(fakeRepository.lastAddedTitle, 'Chapitre 1');
    expect(fakeRepository.lastAddedBody, 'Butin trouvé : 50 po.');
    expect(find.text('Note ajoutée.'), findsOneWidget);
  });

  testWidgets(
    'tap sur une ligne ouvre "Modifier"/"Supprimer" ; "Modifier" préremplit '
    'titre+corps et appelle updateGroupNoteEntry',
    (tester) async {
      await _pump(tester, entries: [entry2], repository: fakeRepository);

      await tester.tap(find.text('Chapitre 2'));
      await tester.pumpAndSettle();

      expect(find.text('Modifier'), findsOneWidget);
      expect(find.text('Supprimer'), findsOneWidget);

      await tester.tap(find.text('Modifier'));
      await tester.pumpAndSettle();

      expect(find.text('MODIFIER LA NOTE'), findsOneWidget);
      final titleField = tester.widget<TextFormField>(
        find.byType(TextFormField).first,
      );
      expect(titleField.controller!.text, 'Chapitre 2');
      final bodyField = tester.widget<TextFormField>(
        find.byType(TextFormField).last,
      );
      expect(
        bodyField.controller!.text,
        'Combat contre les gobelins de la mine.',
      );

      await tester.enterText(
        find.byType(TextFormField).last,
        'Combat, corrigé.',
      );
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pumpAndSettle();

      expect(fakeRepository.updateCallCount, 1);
      expect(fakeRepository.lastUpdatedEntryId, 'entry-2');
      expect(fakeRepository.lastUpdatedTitle, 'Chapitre 2');
      expect(fakeRepository.lastUpdatedBody, 'Combat, corrigé.');
      expect(find.text('Note modifiée.'), findsOneWidget);
    },
  );

  testWidgets('"Supprimer" ouvre une confirmation ; confirmer appelle '
      'deleteGroupNoteEntry', (tester) async {
    await _pump(tester, entries: [entry1], repository: fakeRepository);

    await tester.tap(find.text('Première séance, sans titre.'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();

    expect(find.text('Supprimer cette note ?'), findsOneWidget);
    expect(find.text('Cette action est définitive.'), findsOneWidget);

    await tester.tap(find.text('Supprimer').last);
    await tester.pumpAndSettle();

    expect(fakeRepository.deleteCallCount, 1);
    expect(fakeRepository.lastDeletedEntryId, 'entry-1');
    expect(find.text('Note supprimée.'), findsOneWidget);
  });

  testWidgets(
    'échec de la suppression (GroupFailure) : SnackBar avec le message '
    'dédié, jamais "Note supprimée."',
    (tester) async {
      fakeRepository.deleteError = const GroupFailure(
        'Impossible de supprimer : session expirée.',
      );
      await _pump(tester, entries: [entry1], repository: fakeRepository);

      await tester.tap(find.text('Première séance, sans titre.'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer').last);
      await tester.pumpAndSettle();

      expect(
        find.text('Impossible de supprimer : session expirée.'),
        findsOneWidget,
      );
      expect(find.text('Note supprimée.'), findsNothing);
    },
  );

  testWidgets('"Annuler" dans la confirmation ne supprime rien', (
    tester,
  ) async {
    await _pump(tester, entries: [entry1], repository: fakeRepository);

    await tester.tap(find.text('Première séance, sans titre.'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ANNULER'));
    await tester.pumpAndSettle();

    expect(fakeRepository.deleteCallCount, 0);
  });
}
