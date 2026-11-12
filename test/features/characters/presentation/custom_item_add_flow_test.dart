// P7 PR 2 : routage de « Objet personnalisé » dans `pickInventoryAddition` /
// `pickInventoryAdditions` — formulaire enrichi par défaut, forme simple
// (`enriched: false`) pour la récompense et le butin de groupe.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/characters/domain/custom_item_enrichment.dart';
import 'package:personnages/features/characters/domain/inventory_catalog_item.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/features/characters/presentation/widgets/add_item_flow.dart';
import 'package:personnages/l10n/app_localizations.dart';
import 'package:personnages/features/characters/data/character_repository.dart';

class _Repo implements CharacterRepository {
  @override
  Future<List<InventoryCatalogItem>> fetchInventoryCatalog() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

PickedInventoryAddition? _single;
List<PickedInventoryAddition>? _multi;

Future<void> _open(
  WidgetTester tester,
  Future<void> Function(BuildContext context) onOpen,
) async {
  _single = null;
  _multi = null;
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [characterRepositoryProvider.overrideWithValue(_Repo())],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => onOpen(context),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Objet personnalisé'));
  await tester.pumpAndSettle();
}

Future<void> _addNamed(WidgetTester tester, String name) async {
  await tester.enterText(find.byKey(const Key('customItemNameField')), name);
  await tester.pump();
  await tester.tap(find.widgetWithText(PrimaryButton, 'AJOUTER'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('par défaut : formulaire enrichi, résultat porteur de '
      'l\'enrichissement (arme)', (tester) async {
    await _open(tester, (context) async {
      _single = await pickInventoryAddition(context, attunedCount: 1);
    });

    expect(find.text('TYPE D\'OBJET'), findsOneWidget);
    await tester.tap(find.byKey(const Key('customItemKindWeapon')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('customItemDamageTypeField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Feu').last);
    await tester.pumpAndSettle();
    await _addNamed(tester, 'Épée flamboyante');

    final result = _single!;
    expect(result.isCustom, isTrue);
    expect(result.customName, 'Épée flamboyante');
    expect(result.customDamageDice, '1d6');
    expect(result.customDamageType, 'feu');
    expect(result.customEnrichment!.kind, CustomItemKinds.weapon);
  });

  testWidgets('attunedCount transmis au formulaire (plafond atteint : '
      '« Harmoniser maintenant » désactivé)', (tester) async {
    await _open(tester, (context) async {
      _single = await pickInventoryAddition(context, attunedCount: 3);
    });
    await tester.tap(find.byKey(const Key('customItemKindOther')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('advancedSectionHeader')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('customItemRequiresAttunementSwitch')),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Vous avez déjà 3 objets harmonisés'),
      findsOneWidget,
    );
  });

  testWidgets('enriched: false : ancienne feuille « Objet simple / Arme », '
      'aucun enrichissement', (tester) async {
    await _open(tester, (context) async {
      _single = await pickInventoryAddition(context, enriched: false);
    });

    expect(find.text('TYPE D\'OBJET'), findsOneWidget);
    expect(find.text('OBJET SIMPLE'), findsOneWidget);
    expect(find.byKey(const Key('customItemKindWeapon')), findsNothing);
    await _addNamed(tester, 'Corde');

    expect(_single!.customName, 'Corde');
    expect(_single!.customEnrichment, isNull);
  });

  testWidgets('pickInventoryAdditions : enrichi par défaut, forme simple '
      'pour le butin (enriched: false)', (tester) async {
    await _open(tester, (context) async {
      _multi = await pickInventoryAdditions(context);
    });
    expect(find.byKey(const Key('customItemKindOther')), findsOneWidget);
    await tester.tap(find.byKey(const Key('customItemKindOther')));
    await tester.pumpAndSettle();
    await _addNamed(tester, 'Anneau');
    expect(_multi!.single.customEnrichment!.kind, CustomItemKinds.other);

    await _open(tester, (context) async {
      _multi = await pickInventoryAdditions(context, enriched: false);
    });
    expect(find.text('OBJET SIMPLE'), findsOneWidget);
    await _addNamed(tester, 'Anneau');
    expect(_multi!.single.customName, 'Anneau');
    expect(_multi!.single.customEnrichment, isNull);
  });
}
