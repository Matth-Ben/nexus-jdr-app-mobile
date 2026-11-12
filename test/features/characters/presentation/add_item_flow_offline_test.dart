// T5b-2 (F20) : la feuille « Depuis le catalogue » reste utilisable quand le
// catalogue n'a jamais été chargé et que l'appareil est hors ligne (message
// dédié + objet personnalisé), et le catalogue est rechargé automatiquement au
// retour du réseau.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/inventory_catalog_item.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/features/characters/presentation/widgets/add_item_flow.dart';
import 'package:personnages/l10n/app_localizations.dart';

import '../../../support/fake_connectivity_checker.dart';

const _dagger = InventoryCatalogItem(
  id: 1,
  name: 'Dague',
  category: 'arme',
  costAmount: 2,
);

/// Catalogue indisponible (erreur réseau dédiée) tant que [available] est faux.
class _CatalogRepository implements CharacterRepository {
  bool available = false;
  int fetchCalls = 0;

  @override
  Future<List<InventoryCatalogItem>> fetchInventoryCatalog() async {
    fetchCalls++;
    if (!available) throw mapUnknownCatalogError();
    return const [_dagger];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

CharacterFailure mapUnknownCatalogError() => const CharacterFailure(
  'Impossible de contacter le serveur.',
  code: CharacterErrorCode.network,
);

void main() {
  late _CatalogRepository repository;
  late FakeConnectivityChecker connectivity;

  setUp(() {
    repository = _CatalogRepository();
    connectivity = FakeConnectivityChecker(connected: false);
  });

  tearDown(() => connectivity.close());

  Future<void> pump(
    WidgetTester tester, {
    required void Function(BuildContext context) onOpen,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          characterRepositoryProvider.overrideWithValue(repository),
          connectivityCheckerProvider.overrideWithValue(connectivity),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => onOpen(context),
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
    await tester.tap(find.text('Depuis le catalogue'));
    await tester.pumpAndSettle();
  }

  const offlineMessage = 'Le catalogue d\'objets n\'est pas encore disponible';

  testWidgets('catalogue jamais chargé + hors ligne : message dédié, bouton '
      'objet personnalisé, pas de liste', (tester) async {
    await pump(tester, onOpen: pickInventoryAddition);

    expect(find.textContaining(offlineMessage), findsOneWidget);
    expect(find.text('AJOUTER UN OBJET PERSONNALISÉ'), findsOneWidget);
    expect(find.text('RÉESSAYER'), findsOneWidget);
    expect(find.text('Dague'), findsNothing);
  });

  testWidgets('« Ajouter un objet personnalisé » : ouvre la saisie '
      'personnalisée et retourne un objet personnalisé', (tester) async {
    PickedInventoryAddition? result;
    await pump(
      tester,
      onOpen: (context) async => result = await pickInventoryAddition(context),
    );

    await tester.tap(find.text('AJOUTER UN OBJET PERSONNALISÉ'));
    await tester.pumpAndSettle();
    expect(find.textContaining(offlineMessage), findsNothing);
    // Formulaire en deux temps : étape 1 (type d'objet) puis nom.
    await tester.tap(find.byKey(const Key('customItemKindOther')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('customItemNameField')),
      'Amulette',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(PrimaryButton, 'AJOUTER'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.isCustom, isTrue);
    expect(result!.customName, 'Amulette');
  });

  testWidgets('variante multiple (butin) : même issue, objet personnalisé '
      'seul', (tester) async {
    List<PickedInventoryAddition>? result;
    await pump(
      tester,
      // Butin de groupe : forme simple (aucune colonne enrichie).
      onOpen: (context) async =>
          result = await pickInventoryAdditions(context, enriched: false),
    );

    await tester.tap(find.text('AJOUTER UN OBJET PERSONNALISÉ'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('customItemNameField')),
      'Amulette',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(PrimaryButton, 'AJOUTER'));
    await tester.pumpAndSettle();

    expect(result!.map((p) => p.customName), ['Amulette']);
  });

  testWidgets('retour du réseau : le catalogue est rechargé automatiquement', (
    tester,
  ) async {
    await pump(tester, onOpen: pickInventoryAddition);
    expect(repository.fetchCalls, 1);
    expect(find.textContaining(offlineMessage), findsOneWidget);

    repository.available = true;
    connectivity.goOnline();
    await tester.pumpAndSettle();

    expect(repository.fetchCalls, 2);
    expect(find.textContaining(offlineMessage), findsNothing);
    expect(find.text('Dague'), findsOneWidget);
  });

  testWidgets('« Réessayer » recharge le catalogue', (tester) async {
    await pump(tester, onOpen: pickInventoryAddition);

    repository.available = true;
    await tester.tap(find.text('RÉESSAYER'));
    await tester.pumpAndSettle();

    expect(repository.fetchCalls, 2);
    expect(find.text('Dague'), findsOneWidget);
  });

  testWidgets('catalogue chargé en ligne : un retour du réseau ne le recharge '
      'pas', (tester) async {
    repository.available = true;
    connectivity.connected = true;
    await pump(tester, onOpen: pickInventoryAddition);
    expect(repository.fetchCalls, 1);

    connectivity.emitRestored();
    await tester.pumpAndSettle();

    expect(repository.fetchCalls, 1);
    expect(find.text('Dague'), findsOneWidget);
  });

  testWidgets('catalogue servi hors ligne (cache périmé) : rechargé au retour '
      'du réseau', (tester) async {
    repository.available = true;
    await pump(tester, onOpen: pickInventoryAddition);
    expect(repository.fetchCalls, 1);
    expect(find.text('Dague'), findsOneWidget);

    connectivity.goOnline();
    await tester.pumpAndSettle();

    expect(repository.fetchCalls, 2);
  });
}
