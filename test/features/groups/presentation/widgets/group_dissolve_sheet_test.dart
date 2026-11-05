// Tests de widget de `showGroupDissolveSheet` — sheet "Dissoudre le groupe"
// de la section "ZONE DANGEREUSE" de `group_settings_screen.dart`, voir sa
// doc de classe. `group_settings_screen_test.dart` vérifie seulement que le
// bouton "Dissoudre le groupe" ouvre bien cette sheet (titre "DISSOUDRE LE
// GROUPE") ; ce fichier couvre le contenu complet de la sheet (étapes
// avertissement/confirmation, appel réseau, erreurs, traduction — chantier
// "traduction de l'app" Phase B, lot "Groups — écran principal").

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/widgets/destructive_button.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/groups/data/group_repository.dart';
import 'package:personnages/features/groups/domain/created_group.dart';
import 'package:personnages/features/groups/domain/group_detail.dart';
import 'package:personnages/features/groups/domain/group_note.dart';
import 'package:personnages/features/groups/domain/group_preview.dart';
import 'package:personnages/features/groups/domain/group_summary.dart';
import 'package:personnages/features/groups/domain/group_treasure.dart';
import 'package:personnages/features/groups/domain/group_treasure_item.dart';
import 'package:personnages/features/groups/domain/joined_group.dart';
import 'package:personnages/features/groups/presentation/providers/group_providers.dart';
import 'package:personnages/features/groups/presentation/widgets/group_dissolve_sheet.dart';
import 'package:personnages/l10n/app_localizations.dart';

class _FakeGroupRepository implements GroupRepository {
  bool dissolveCalled = false;
  Object? dissolveError;
  Completer<void>? dissolveCompleter;

  @override
  Future<void> dissolveGroup(String groupId) async {
    dissolveCalled = true;
    if (dissolveCompleter != null) return dissolveCompleter!.future;
    if (dissolveError != null) throw dissolveError!;
  }

  @override
  Future<List<GroupSummary>> fetchMyGroups() => throw UnimplementedError();

  @override
  Future<CreatedGroup> createGroup({
    required String name,
    String? characterId,
  }) => throw UnimplementedError();

  @override
  Future<GroupPreview> previewGroupInvite(String code) =>
      throw UnimplementedError();

  @override
  Future<JoinedGroup> joinGroup({required String code, String? characterId}) =>
      throw UnimplementedError();

  @override
  Future<GroupDetail> fetchGroupDetail(String groupId) =>
      throw UnimplementedError();

  @override
  Future<void> renameGroup({required String groupId, required String name}) =>
      throw UnimplementedError();

  @override
  Future<String> regenerateInviteCode(String groupId) =>
      throw UnimplementedError();

  @override
  Future<void> leaveGroup(String groupId) => throw UnimplementedError();

  @override
  Future<void> removeMember({
    required String groupId,
    required String userId,
  }) => throw UnimplementedError();

  @override
  Future<void> setGroupCharacter({
    required String groupId,
    required String characterId,
  }) => throw UnimplementedError();

  @override
  Future<GroupTreasure> fetchGroupTreasure(String groupId) =>
      throw UnimplementedError();

  @override
  Future<void> addToTreasure({
    required String groupId,
    required Map<CurrencyKind, int> newCurrencyTotals,
    required List<GroupTreasureItem> newItems,
  }) => throw UnimplementedError();

  @override
  Future<bool> claimTreasureCurrency({
    required String groupId,
    required String characterId,
    required CurrencyKind currency,
    required int amount,
  }) => throw UnimplementedError();

  @override
  Future<void> claimTreasureItem({
    required String groupId,
    required String characterId,
    required GroupTreasureItem item,
    required int quantity,
  }) => throw UnimplementedError();

  @override
  GroupRealtimeSubscription subscribeToMemberUpdates({
    required List<String> characterIds,
    required void Function() onChanged,
  }) => throw UnimplementedError();

  @override
  Future<GroupNote> fetchGroupNote({
    required String groupId,
    required String characterId,
  }) => throw UnimplementedError();

  @override
  Future<void> saveGroupNote({
    required String groupId,
    required String characterId,
    required String body,
  }) => throw UnimplementedError();
}

GoRouter _buildTestRouter() {
  return GoRouter(
    initialLocation: '/groups/group-1/settings',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Liste des personnages'))),
      ),
      GoRoute(
        path: '/groups/:id/settings',
        builder: (context, state) => Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showGroupDissolveSheet(
                  context,
                  groupId: state.pathParameters['id']!,
                  groupName: "Les Lames de l'Aube",
                ),
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

Widget _buildTestWidget(
  _FakeGroupRepository repository, {
  Locale locale = const Locale('fr'),
}) {
  return ProviderScope(
    overrides: [groupRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      routerConfig: _buildTestRouter(),
    ),
  );
}

void main() {
  late _FakeGroupRepository fakeRepository;

  setUp(() {
    fakeRepository = _FakeGroupRepository();
  });

  testWidgets('étape avertissement : message + Annuler/Continuer', (
    tester,
  ) async {
    await tester.pumpWidget(_buildTestWidget(fakeRepository));
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('DISSOUDRE LE GROUPE'), findsOneWidget);
    expect(
      find.textContaining('Cette action est irréversible'),
      findsOneWidget,
    );
    expect(find.text('ANNULER'), findsOneWidget);
    expect(find.text('Continuer'), findsOneWidget);
  });

  testWidgets('Annuler à l\'étape avertissement ferme la sheet', (
    tester,
  ) async {
    await tester.pumpWidget(_buildTestWidget(fakeRepository));
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ANNULER'));
    await tester.pumpAndSettle();

    expect(find.text('DISSOUDRE LE GROUPE'), findsNothing);
  });

  testWidgets(
    'Continuer passe à l\'étape de confirmation, bouton désactivé tant que '
    'le nom ne correspond pas',
    (tester) async {
      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      expect(
        find.text('RETAPE LE NOM DU GROUPE POUR CONFIRMER'),
        findsOneWidget,
      );
      final confirmButton = tester.widget<DestructiveButton>(
        find.widgetWithText(DestructiveButton, 'Dissoudre définitivement'),
      );
      expect(confirmButton.onPressed, isNull);

      await tester.enterText(find.byType(TextFormField), 'autre chose');
      await tester.pump();

      final stillDisabled = tester.widget<DestructiveButton>(
        find.widgetWithText(DestructiveButton, 'Dissoudre définitivement'),
      );
      expect(stillDisabled.onPressed, isNull);

      // Comparaison insensible casse/espaces (spec de la tâche).
      await tester.enterText(
        find.byType(TextFormField),
        "  les LAMES de l'aube  ",
      );
      await tester.pump();

      final enabled = tester.widget<DestructiveButton>(
        find.widgetWithText(DestructiveButton, 'Dissoudre définitivement'),
      );
      expect(enabled.onPressed, isNotNull);
    },
  );

  testWidgets(
    'confirmer dissout le groupe puis navigue vers / avec un SnackBar',
    (tester) async {
      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), "Les Lames de l'Aube");
      await tester.pump();
      await tester.tap(find.text('Dissoudre définitivement'));
      await tester.pumpAndSettle();

      expect(fakeRepository.dissolveCalled, isTrue);
      expect(find.text('Liste des personnages'), findsOneWidget);
      expect(find.text('Groupe dissous.'), findsOneWidget);
    },
  );

  testWidgets(
    'échec du réseau : bandeau d\'erreur générique, reste sur la sheet',
    (tester) async {
      fakeRepository.dissolveError = Exception('boom');

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), "Les Lames de l'Aube");
      await tester.pump();
      await tester.tap(find.text('Dissoudre définitivement'));
      await tester.pumpAndSettle();

      expect(
        find.text('Impossible de dissoudre le groupe. Réessayez.'),
        findsOneWidget,
      );
      expect(find.text('DISSOUDRE LE GROUPE'), findsOneWidget);
    },
  );

  testWidgets(
    'bouton "Dissoudre définitivement" affiche "Dissolution en cours…" '
    'pendant l\'appel réseau',
    (tester) async {
      final completer = Completer<void>();
      fakeRepository.dissolveCompleter = completer;

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), "Les Lames de l'Aube");
      await tester.pump();
      await tester.tap(find.text('Dissoudre définitivement'));
      await tester.pump();

      expect(find.text('Dissolution en cours…'), findsOneWidget);

      completer.complete();
      await tester.pumpAndSettle();
    },
  );

  group('traduction anglaise', () {
    testWidgets('titre, message, boutons en anglais', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(fakeRepository, locale: const Locale('en')),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      expect(find.text('DISSOLVE THE GROUP'), findsOneWidget);
      expect(
        find.textContaining('This action is irreversible'),
        findsOneWidget,
      );
      expect(find.text('CANCEL'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets(
      'confirmer en anglais appelle dissolveGroup et affiche le SnackBar '
      'traduit',
      (tester) async {
        await tester.pumpWidget(
          _buildTestWidget(fakeRepository, locale: const Locale('en')),
        );
        await tester.tap(find.text('Ouvrir'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        expect(find.text('RETYPE THE GROUP NAME TO CONFIRM'), findsOneWidget);

        await tester.enterText(
          find.byType(TextFormField),
          "Les Lames de l'Aube",
        );
        await tester.pump();
        await tester.tap(find.text('Dissolve permanently'));
        await tester.pumpAndSettle();

        expect(fakeRepository.dissolveCalled, isTrue);
        expect(find.text('Group dissolved.'), findsOneWidget);
      },
    );

    testWidgets('échec générique en anglais', (tester) async {
      fakeRepository.dissolveError = Exception('boom');

      await tester.pumpWidget(
        _buildTestWidget(fakeRepository, locale: const Locale('en')),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), "Les Lames de l'Aube");
      await tester.pump();
      await tester.tap(find.text('Dissolve permanently'));
      await tester.pumpAndSettle();

      expect(
        find.text('Unable to dissolve the group. Try again.'),
        findsOneWidget,
      );
    });
  });
}
