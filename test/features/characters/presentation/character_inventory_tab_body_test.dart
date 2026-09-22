// Tests de widget de l'onglet "Inventaire" de la fiche personnage — voir
// `docs/cahier-des-charges/09-maquettes-captures.md`, section "Onglet
// Inventaire".
//
// `CharacterInventoryTabBody` n'a pas de dépendance Riverpod/réseau (l'état
// interne du filtre par catégorie mis à part) : les sheets qu'il ouvre le
// sont aussi, à l'exception de la sheet "Depuis le catalogue"
// (`add_item_flow.dart`, qui a besoin de `inventoryCatalogProvider`) —
// volontairement pas exercée ici (elle a son test dédié), ce fichier se
// limite au chemin "Objet personnalisé" pour rester sans `ProviderScope`,
// même approche que `character_skills_tab_body_test.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/dashed_border_painter.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/characters/domain/inventory_catalog_item.dart';
import 'package:personnages/features/characters/domain/weapon_slot.dart';
import 'package:personnages/features/characters/presentation/widgets/character_inventory_item_card.dart';
import 'package:personnages/features/characters/presentation/widgets/character_inventory_tab_body.dart';

/// `find` sur un `CustomPaint` peint par [DashedBorderPainter] — plus fiable
/// qu'un `find.byType(CustomPaint)` seul (d'autres `CustomPaint` internes à
/// Flutter peuvent apparaître dans l'arbre) pour vérifier qu'un badge/une
/// tuile est bien rendu en pointillés, pas seulement son texte.
Finder _dashedBorderFinder() => find.byWidgetPredicate(
  (widget) => widget is CustomPaint && widget.painter is DashedBorderPainter,
);

CharacterDetail _detail({
  int currencyGp = 0,
  int currencyPp = 0,
  int currencyEp = 0,
  int currencySp = 0,
  int currencyCp = 0,
  List<CharacterInventoryItem> inventory = const [],
  Map<String, int> abilityScores = const {},
}) {
  return CharacterDetail(
    id: '1',
    name: 'Test',
    classes: const [],
    xp: 0,
    currentHp: 10,
    maxHp: 10,
    temporaryHp: 0,
    abilityScores: abilityScores,
    currencyGp: currencyGp,
    currencyPp: currencyPp,
    currencyEp: currencyEp,
    currencySp: currencySp,
    currencyCp: currencyCp,
    inventory: inventory,
  );
}

class _Recorder {
  final List<CharacterInventoryItem> useCalls = [];
  final List<CharacterInventoryItem> toggleCalls = [];
  final List<CharacterInventoryItem> toggleAttunedCalls = [];
  final List<CharacterInventoryItem> removeCalls = [];
  final List<(CurrencyKind, int)> adjustCurrencyCalls = [];
  final List<(InventoryCatalogItem, int)> addItemCalls = [];
  final List<(String, int)> addCustomItemCalls = [];
  final List<(CharacterInventoryItem, WeaponSlot)> equipWeaponCalls = [];
}

Future<_Recorder> _pump(
  WidgetTester tester,
  CharacterDetail detail, {
  bool actionsDisabled = false,
}) async {
  final recorder = _Recorder();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CharacterInventoryTabBody(
          detail: detail,
          actionsDisabled: actionsDisabled,
          onUseItem: recorder.useCalls.add,
          onToggleItemEquipped: recorder.toggleCalls.add,
          onToggleItemAttuned: recorder.toggleAttunedCalls.add,
          onRemoveItem: recorder.removeCalls.add,
          onAdjustCurrency: (currency, amount) =>
              recorder.adjustCurrencyCalls.add((currency, amount)),
          onAddInventoryItem: (item, quantity) =>
              recorder.addItemCalls.add((item, quantity)),
          onAddCustomInventoryItem: (name, quantity) =>
              recorder.addCustomItemCalls.add((name, quantity)),
          onEquipWeaponToSlot: (item, slot) =>
              recorder.equipWeaponCalls.add((item, slot)),
        ),
      ),
    ),
  );
  return recorder;
}

const _dagger = CharacterInventoryItem(
  id: 'inv-1',
  itemId: 1,
  name: 'Dague',
  category: 'arme',
  quantity: 2,
  equipped: false,
  totalWeight: 1,
);

const _potion = CharacterInventoryItem(
  id: 'inv-2',
  itemId: 2,
  name: 'Potion de soins',
  category: 'equipement_general',
  quantity: 3,
  equipped: false,
  consumable: true,
);

const _customItem = CharacterInventoryItem(
  id: 'inv-3',
  name: 'Petit sac de sable',
  quantity: 1,
  equipped: false,
);

const _ring = CharacterInventoryItem(
  id: 'inv-4',
  itemId: 4,
  name: 'Anneau de protection',
  category: 'objet_magique',
  quantity: 1,
  equipped: false,
  requiresAttunement: true,
);

const _plateArmor = CharacterInventoryItem(
  id: 'inv-5',
  itemId: 5,
  name: 'Armure de plates',
  category: 'armure',
  quantity: 1,
  equipped: false,
);

const _rope = CharacterInventoryItem(
  id: 'inv-6',
  itemId: 6,
  name: 'Corde',
  category: 'equipement_general',
  quantity: 1,
  equipped: false,
);

void main() {
  testWidgets('affiche la rangée de monnaie/poids (or/argent/cuivre '
      'toujours visibles)', (tester) async {
    await _pump(tester, _detail(currencyGp: 42, currencySp: 6, currencyCp: 14));

    expect(find.text('42'), findsOneWidget);
    expect(find.text('PO'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('PA'), findsOneWidget);
    expect(find.text('14'), findsOneWidget);
    expect(find.text('PC'), findsOneWidget);
    // Poids total à 0 (aucun objet) : la box "KG" reste affichée.
    expect(find.text('KG'), findsOneWidget);
  });

  testWidgets('la box PP n\'apparaît que si la platine est non nulle', (
    tester,
  ) async {
    await _pump(tester, _detail(currencyGp: 10));
    expect(find.text('PP'), findsNothing);

    await _pump(tester, _detail(currencyGp: 10, currencyPp: 3));
    expect(find.text('PP'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('affiche un objet du catalogue avec sa catégorie et sa '
      'quantité', (tester) async {
    await _pump(tester, _detail(inventory: const [_dagger]));

    expect(find.text('Dague'), findsOneWidget);
    expect(find.text('Arme · x2'), findsOneWidget);
    expect(find.text('1 kg'), findsOneWidget);
  });

  testWidgets('un objet équipé affiche le badge ÉQUIPÉ plutôt que son poids', (
    tester,
  ) async {
    await _pump(
      tester,
      _detail(
        inventory: const [
          CharacterInventoryItem(
            id: 'inv-1',
            itemId: 2,
            name: 'Grimoire',
            category: 'objet_magique',
            quantity: 1,
            equipped: true,
            totalWeight: 3,
          ),
        ],
      ),
    );

    expect(find.text('ÉQUIPÉ'), findsOneWidget);
    expect(find.text('3 kg'), findsNothing);
  });

  testWidgets(
    'un objet personnalisé (sans item_id) affiche son nom libre et le '
    'libellé "Objet personnalisé", sans poids (inconnu côté schéma)',
    (tester) async {
      await _pump(tester, _detail(inventory: const [_customItem]));

      expect(find.text('Petit sac de sable'), findsOneWidget);
      expect(find.text('Objet personnalisé · x1'), findsOneWidget);
    },
  );

  testWidgets('un objet personnalisé rend bien un badge en pointillés '
      '(CustomPaint/DashedBorderPainter), pas seulement le libellé "Objet '
      'personnalisé"', (tester) async {
    // Repère : sans objet personnalisé, seule la tuile "Ajouter un objet"
    // (en bas de liste) est peinte en pointillés.
    await _pump(tester, _detail());
    expect(_dashedBorderFinder(), findsOneWidget);

    await _pump(tester, _detail(inventory: const [_customItem]));

    // Un deuxième `CustomPaint`/`DashedBorderPainter` apparaît : le badge
    // de catégorie de l'objet personnalisé, en plus de la tuile
    // "Ajouter un objet".
    expect(_dashedBorderFinder(), findsNWidgets(2));
  });

  testWidgets(
    'un objet du catalogue dont items.weight est nul en base n\'affiche '
    'aucun texte de poids ("kg")',
    (tester) async {
      await _pump(
        tester,
        _detail(
          inventory: const [
            CharacterInventoryItem(
              id: 'inv-1',
              itemId: 3,
              name: 'Objet sans poids connu',
              category: 'equipement_general',
              quantity: 1,
              equipped: false,
              totalWeight: null,
            ),
          ],
        ),
      );

      expect(find.text('Objet sans poids connu'), findsOneWidget);
      // Recherche restreinte à la carte de l'objet : la jauge "CHARGE"
      // affiche elle aussi un texte "... kg" (capacité de transport),
      // indépendant du poids (inconnu) de cet objet précis.
      expect(
        find.descendant(
          of: find.byType(CharacterInventoryItemCard),
          matching: find.textContaining('kg'),
        ),
        findsNothing,
      );
      expect(find.text('ÉQUIPÉ'), findsNothing);
    },
  );

  testWidgets('inventaire vide : état "INVENTAIRE VIDE", bouton "Objet" '
      'et stat boxes restent visibles', (tester) async {
    await _pump(tester, _detail(currencyGp: 5));

    expect(find.text('INVENTAIRE VIDE'), findsOneWidget);
    expect(find.text('Objet'), findsOneWidget);
    expect(find.text('PO'), findsOneWidget);
  });

  group('carte objet cliquable -> sheet d\'actions', () {
    testWidgets('un objet personnalisé n\'a que "Infos" et "Retirer"', (
      tester,
    ) async {
      await _pump(tester, _detail(inventory: const [_customItem]));

      await tester.tap(find.text('Petit sac de sable'));
      await tester.pumpAndSettle();

      expect(find.text('Infos'), findsOneWidget);
      expect(find.text('Utiliser'), findsNothing);
      expect(find.text('Équiper'), findsNothing);
      expect(find.text('Retirer'), findsOneWidget);
    });

    testWidgets('"Utiliser" (objet consommable) appelle onUseItem', (
      tester,
    ) async {
      final recorder = await _pump(tester, _detail(inventory: const [_potion]));

      await tester.tap(find.text('Potion de soins'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Utiliser'));
      await tester.pumpAndSettle();

      expect(recorder.useCalls, [_potion]);
    });

    testWidgets(
      '"Équiper" (arme non équipée) ouvre la sheet de choix de set puis '
      'appelle onEquipWeaponToSlot',
      (tester) async {
        final recorder = await _pump(
          tester,
          _detail(inventory: const [_dagger]),
        );

        await tester.tap(find.text('Dague'));
        await tester.pumpAndSettle();
        expect(find.text('Équiper'), findsOneWidget);

        await tester.tap(find.text('Équiper'));
        await tester.pumpAndSettle();

        expect(find.text('CHOISIR UN SET'), findsOneWidget);
        await tester.tap(find.text('Set principal'));
        await tester.pumpAndSettle();

        expect(recorder.equipWeaponCalls, [(_dagger, WeaponSlot.principal)]);
        expect(recorder.toggleCalls, isEmpty);
      },
    );

    testWidgets(
      '"Retirer" ouvre une confirmation, "Retirer" du dialogue appelle '
      'onRemoveItem',
      (tester) async {
        final recorder = await _pump(
          tester,
          _detail(inventory: const [_dagger]),
        );

        await tester.tap(find.text('Dague'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Retirer'));
        await tester.pumpAndSettle();

        expect(find.text('Retirer Dague ?'), findsOneWidget);
        expect(recorder.removeCalls, isEmpty);

        await tester.tap(find.text('Retirer'));
        await tester.pumpAndSettle();

        expect(recorder.removeCalls, [_dagger]);
      },
    );

    testWidgets('actionsDisabled: le tap sur une carte n\'ouvre rien', (
      tester,
    ) async {
      await _pump(
        tester,
        _detail(inventory: const [_dagger]),
        actionsDisabled: true,
      );

      await tester.tap(find.text('Dague'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Infos'), findsNothing);
    });
  });

  group('stat box de monnaie cliquable -> sheet d\'ajustement', () {
    testWidgets('tap sur la box PO ouvre la sheet, "Appliquer" appelle '
        'onAdjustCurrency avec le nouveau montant absolu', (tester) async {
      final recorder = await _pump(tester, _detail(currencyGp: 10));

      await tester.tap(find.text('PO'));
      await tester.pumpAndSettle();

      expect(find.text("Ajuster les pièces d'or"), findsOneWidget);

      final incrementButton = find.byWidgetPredicate(
        (widget) => widget is Icon && widget.semanticLabel == 'Augmenter',
      );
      await tester.tap(incrementButton);
      await tester.tap(incrementButton);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PrimaryButton, 'APPLIQUER'));
      await tester.pumpAndSettle();

      expect(recorder.adjustCurrencyCalls, [(CurrencyKind.gold, 12)]);
    });

    testWidgets('actionsDisabled: le tap sur une stat box n\'ouvre rien', (
      tester,
    ) async {
      await _pump(tester, _detail(currencyGp: 10), actionsDisabled: true);

      await tester.tap(find.text('PO'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text("Ajuster les pièces d'or"), findsNothing);
    });
  });

  group('"Objet" -> flux "Objet personnalisé"', () {
    testWidgets('ouvre la sheet à 2 choix, "Objet personnalisé" -> saisie -> '
        'onAddCustomInventoryItem', (tester) async {
      final recorder = await _pump(tester, _detail());

      await tester.tap(find.text('Objet'));
      await tester.pumpAndSettle();

      expect(find.text('Depuis le catalogue'), findsOneWidget);
      expect(find.text('Objet personnalisé'), findsOneWidget);

      await tester.tap(find.text('Objet personnalisé'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'Amulette de famille');
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'AJOUTER'));
      await tester.pumpAndSettle();

      expect(recorder.addCustomItemCalls, [('Amulette de famille', 1)]);
    });

    testWidgets('actionsDisabled: le tap sur la tuile n\'ouvre rien', (
      tester,
    ) async {
      await _pump(tester, _detail(), actionsDisabled: true);

      await tester.tap(find.text('Objet'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Depuis le catalogue'), findsNothing);
    });
  });

  group('bouton "Récompense" du pied de liste (recettage '
      'direction-artistique du 13/09)', () {
    testWidgets('appelle onAddReward, absent quand onAddReward est null', (
      tester,
    ) async {
      var rewardTapCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CharacterInventoryTabBody(
              detail: _detail(),
              onUseItem: (_) {},
              onToggleItemEquipped: (_) {},
              onToggleItemAttuned: (_) {},
              onRemoveItem: (_) {},
              onAdjustCurrency: (_, _) {},
              onAddInventoryItem: (_, _) {},
              onAddCustomInventoryItem: (_, _) {},
              onEquipWeaponToSlot: (_, _) {},
              onAddReward: () => rewardTapCount++,
            ),
          ),
        ),
      );

      expect(find.text('RÉCOMPENSE'), findsOneWidget);
      await tester.tap(find.text('RÉCOMPENSE'));
      await tester.pumpAndSettle();

      expect(rewardTapCount, 1);
    });

    testWidgets(
      'onAddReward null (ex. vue de partage) : le bouton reste affiché mais '
      'désactivé',
      (tester) async {
        await _pump(tester, _detail());

        // `onAddReward` non fourni par [_pump] (`null` par défaut) : le
        // bouton "Récompense" reste rendu (parité visuelle avec "Objet"),
        // simplement inerte.
        expect(find.text('RÉCOMPENSE'), findsOneWidget);
        await tester.tap(find.text('RÉCOMPENSE'), warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(find.text('AJOUTER UNE RÉCOMPENSE'), findsNothing);
      },
    );
  });

  group(
    'filtre "Tout"/"Armes"/"Armures"/"Consomm."/"Divers" (docs/cahier-des-'
    'charges/11-fonctionnalites-a-ajouter.md section 3) — bouton qui ouvre '
    'la sheet de sélection (recettage : remplace l\'ancienne bascule '
    'segmentée à 5 segments, dont les libellés cassaient sur petit écran)',
    () {
      // Ouvre la sheet via le bouton "Filtre : {label actif}", puis tape
      // l'option [label] (libellé exact, pas majuscule — [SelectableOptionTile]
      // ne transforme pas la casse, contrairement à l'ancienne bascule
      // segmentée).
      Future<void> selectFilter(WidgetTester tester, String label) async {
        await tester.tap(find.textContaining('Filtre : '));
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }

      testWidgets('le bouton de filtre est absent d\'un inventaire vide', (
        tester,
      ) async {
        await _pump(tester, _detail());

        expect(find.textContaining('Filtre : '), findsNothing);
      });

      testWidgets(
        '"Tout" (par défaut) affiche tous les objets, quelle que soit leur '
        'catégorie',
        (tester) async {
          await _pump(
            tester,
            _detail(inventory: const [_dagger, _potion, _customItem]),
          );

          expect(find.text('Filtre : Tout'), findsOneWidget);
          expect(find.text('Dague'), findsOneWidget);
          expect(find.text('Potion de soins'), findsOneWidget);
          expect(find.text('Petit sac de sable'), findsOneWidget);
        },
      );

      testWidgets('"Armes" ne garde que les objets de catégorie "arme"', (
        tester,
      ) async {
        await _pump(
          tester,
          _detail(inventory: const [_dagger, _potion, _customItem]),
        );

        await selectFilter(tester, 'Armes');

        expect(find.text('Filtre : Armes'), findsOneWidget);
        expect(find.text('Dague'), findsOneWidget);
        expect(find.text('Potion de soins'), findsNothing);
        expect(find.text('Petit sac de sable'), findsNothing);
      });

      testWidgets('"Consomm." ne garde que les objets consommables, quelle que '
          'soit leur catégorie', (tester) async {
        await _pump(
          tester,
          _detail(inventory: const [_dagger, _potion, _customItem]),
        );

        await selectFilter(tester, 'Consomm.');

        expect(find.text('Potion de soins'), findsOneWidget);
        expect(find.text('Dague'), findsNothing);
        expect(find.text('Petit sac de sable'), findsNothing);
      });

      testWidgets('"Armures" ne garde que les objets de catégorie "armure"', (
        tester,
      ) async {
        await _pump(
          tester,
          _detail(inventory: const [_dagger, _plateArmor, _customItem]),
        );

        await selectFilter(tester, 'Armures');

        expect(find.text('Armure de plates'), findsOneWidget);
        expect(find.text('Dague'), findsNothing);
        expect(find.text('Petit sac de sable'), findsNothing);
      });

      testWidgets(
        '"Divers" ne garde que les objets hors arme/armure/consommable '
        '(y compris les objets personnalisés)',
        (tester) async {
          await _pump(
            tester,
            _detail(
              inventory: const [
                _dagger,
                _plateArmor,
                _potion,
                _rope,
                _customItem,
              ],
            ),
          );

          await selectFilter(tester, 'Divers');

          expect(find.text('Corde'), findsOneWidget);
          expect(find.text('Petit sac de sable'), findsOneWidget);
          expect(find.text('Dague'), findsNothing);
          expect(find.text('Armure de plates'), findsNothing);
          expect(find.text('Potion de soins'), findsNothing);
        },
      );

      testWidgets(
        'aucun objet de la catégorie filtrée : affiche un message dédié, '
        'pas l\'état "INVENTAIRE VIDE" (l\'inventaire n\'est pas vide)',
        (tester) async {
          await _pump(tester, _detail(inventory: const [_customItem]));

          await selectFilter(tester, 'Armes');

          expect(
            find.text('Aucun objet dans cette catégorie.'),
            findsOneWidget,
          );
          expect(find.text('INVENTAIRE VIDE'), findsNothing);
        },
      );

      testWidgets(
        'le bouton de filtre ne lève aucune exception sur une largeur d\'écran '
        'étroite (360 — Android bas de gamme courant), contrairement à '
        'l\'ancienne bascule à 5 segments',
        (tester) async {
          final originalSize = tester.view.physicalSize;
          final originalRatio = tester.view.devicePixelRatio;
          tester.view.physicalSize = const Size(360, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(() {
            tester.view.physicalSize = originalSize;
            tester.view.devicePixelRatio = originalRatio;
          });

          await _pump(
            tester,
            _detail(inventory: const [_dagger, _potion, _customItem]),
          );

          expect(tester.takeException(), isNull);
          expect(find.text('Filtre : Tout'), findsOneWidget);
        },
      );

      testWidgets('revenir sur "Tout" restaure la liste complète', (
        tester,
      ) async {
        await _pump(
          tester,
          _detail(inventory: const [_dagger, _potion, _customItem]),
        );

        await selectFilter(tester, 'Armes');
        expect(find.text('Potion de soins'), findsNothing);

        await selectFilter(tester, 'Tout');

        expect(find.text('Dague'), findsOneWidget);
        expect(find.text('Potion de soins'), findsOneWidget);
        expect(find.text('Petit sac de sable'), findsOneWidget);
      });

      testWidgets(
        'fermer la sheet sans choisir (tap en dehors) laisse le filtre actif '
        'inchangé',
        (tester) async {
          await _pump(
            tester,
            _detail(inventory: const [_dagger, _potion, _customItem]),
          );

          await selectFilter(tester, 'Armes');
          expect(find.text('Filtre : Armes'), findsOneWidget);

          await tester.tap(find.textContaining('Filtre : '));
          await tester.pumpAndSettle();
          // Ferme en tapant en dehors de la sheet plutôt qu'une de ses options.
          await tester.tapAt(const Offset(20, 20));
          await tester.pumpAndSettle();

          expect(find.text('Filtre : Armes'), findsOneWidget);
          expect(find.text('Dague'), findsOneWidget);
          expect(find.text('Potion de soins'), findsNothing);
        },
      );

      testWidgets('le bouton "Objet" reste visible et fonctionnel '
          'même quand le filtre actif ne montre aucun objet', (tester) async {
        final recorder = await _pump(
          tester,
          _detail(inventory: const [_customItem]),
        );

        await selectFilter(tester, 'Armes');
        expect(find.text('Objet'), findsOneWidget);

        await tester.tap(find.text('Objet'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Objet personnalisé'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField), 'Corde');
        await tester.pump();
        await tester.tap(find.widgetWithText(PrimaryButton, 'AJOUTER'));
        await tester.pumpAndSettle();

        expect(recorder.addCustomItemCalls, [('Corde', 1)]);
      });
    },
  );

  group('harmonisation (docs/cahier-des-charges/'
      '11-fonctionnalites-a-ajouter.md section 3)', () {
    testWidgets('"Harmoniser cet objet" appelle onToggleItemAttuned', (
      tester,
    ) async {
      final recorder = await _pump(tester, _detail(inventory: const [_ring]));

      await tester.tap(find.text('Anneau de protection'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Harmoniser cet objet'));
      await tester.pumpAndSettle();

      expect(recorder.toggleAttunedCalls, [_ring]);
    });

    testWidgets(
      'plafond de 3 objets déjà harmonisés : "Harmoniser cet objet" est '
      'désactivée avec le libellé "Limite (3) atteinte", aucun appel au tap',
      (tester) async {
        CharacterInventoryItem attunedItem(String id, String name) =>
            CharacterInventoryItem(
              id: id,
              itemId: int.parse(id.split('-').last),
              name: name,
              category: 'objet_magique',
              quantity: 1,
              equipped: false,
              requiresAttunement: true,
              isAttuned: true,
            );

        final recorder = await _pump(
          tester,
          _detail(
            inventory: [
              attunedItem('inv-10', 'Amulette A'),
              attunedItem('inv-11', 'Amulette B'),
              attunedItem('inv-12', 'Amulette C'),
              _ring,
            ],
          ),
        );

        await tester.tap(find.text('Anneau de protection'));
        await tester.pumpAndSettle();

        expect(find.text('Limite (3) atteinte'), findsOneWidget);

        await tester.tap(
          find.text('Harmoniser cet objet'),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        expect(recorder.toggleAttunedCalls, isEmpty);
      },
    );

    testWidgets(
      'un objet déjà harmonisé reste bascule-able ("Ne plus harmoniser") '
      'même au plafond',
      (tester) async {
        CharacterInventoryItem attunedItem(String id, String name) =>
            CharacterInventoryItem(
              id: id,
              itemId: int.parse(id.split('-').last),
              name: name,
              category: 'objet_magique',
              quantity: 1,
              equipped: false,
              requiresAttunement: true,
              isAttuned: true,
            );

        final recorder = await _pump(
          tester,
          _detail(
            inventory: [
              attunedItem('inv-10', 'Amulette A'),
              attunedItem('inv-11', 'Amulette B'),
              attunedItem('inv-12', 'Amulette C'),
            ],
          ),
        );

        await tester.tap(find.text('Amulette A'));
        await tester.pumpAndSettle();
        expect(find.text('Limite (3) atteinte'), findsNothing);

        await tester.tap(find.text('Ne plus harmoniser'));
        await tester.pumpAndSettle();

        expect(recorder.toggleAttunedCalls, hasLength(1));
        expect(recorder.toggleAttunedCalls.single.id, 'inv-10');
      },
    );

    testWidgets(
      'un objet ne nécessitant pas d\'harmonisation n\'a pas cette action '
      'dans la sheet',
      (tester) async {
        await _pump(tester, _detail(inventory: const [_dagger]));

        await tester.tap(find.text('Dague'));
        await tester.pumpAndSettle();

        expect(find.text('Harmoniser cet objet'), findsNothing);
      },
    );
  });

  group('capacité de transport (docs/cahier-des-charges/'
      '11-fonctionnalites-a-ajouter.md section 3)', () {
    testWidgets(
      'jauge "CHARGE" toujours affichée, même inventaire vide (capacité = '
      'Force x 7,5 kg, Force par défaut 10 -> 75 kg)',
      (tester) async {
        await _pump(tester, _detail());

        expect(find.text('CHARGE'), findsOneWidget);
        expect(find.text('0 / 75 kg'), findsOneWidget);
      },
    );

    testWidgets('capacité dérivée du score de Force réel (16 -> 120 kg)', (
      tester,
    ) async {
      await _pump(tester, _detail(abilityScores: const {'str': 16}));

      expect(find.text('0 / 120 kg'), findsOneWidget);
    });

    testWidgets(
      'poids total supérieur à la capacité : alerte "Surchargé" affichée',
      (tester) async {
        await _pump(
          tester,
          _detail(
            abilityScores: const {'str': 8},
            inventory: const [
              CharacterInventoryItem(
                id: 'inv-1',
                itemId: 1,
                name: 'Enclume',
                category: 'equipement_general',
                quantity: 1,
                equipped: false,
                totalWeight: 100,
              ),
            ],
          ),
        );

        expect(find.text('0 / 60 kg'), findsNothing);
        expect(find.text('100 / 60 kg'), findsOneWidget);
        expect(
          find.text('Surchargé — poids supérieur à la capacité de transport.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('poids sous la capacité : aucune alerte "Surchargé"', (
      tester,
    ) async {
      await _pump(tester, _detail(inventory: const [_dagger]));

      expect(
        find.text('Surchargé — poids supérieur à la capacité de transport.'),
        findsNothing,
      );
    });
  });
}
