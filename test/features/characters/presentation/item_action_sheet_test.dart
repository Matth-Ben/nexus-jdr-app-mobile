// Tests de widget de la sheet "Actions d'objet"
// (`presentation/widgets/item_action_sheet.dart`) et du panneau "Infos"
// qu'elle peut ouvrir — même patron que `spell_action_sheet_test.dart` : la
// sheet est ouverte depuis un `Builder` minimal, les callbacks sont de
// simples closures enregistrant leurs appels (toute la logique d'écriture
// réseau vit dans `character_detail_screen.dart`, hors périmètre de ce
// fichier).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
import 'package:personnages/features/characters/domain/weapon_slot.dart';
import 'package:personnages/features/characters/presentation/widgets/item_action_sheet.dart';
import 'package:personnages/features/characters/presentation/widgets/item_info_panel.dart';
import 'package:personnages/l10n/app_localizations.dart';
import 'package:personnages/l10n/app_localizations_en.dart';
import 'package:personnages/l10n/app_localizations_fr.dart';

const _customItem = CharacterInventoryItem(
  id: 'inv-custom',
  name: 'Petit sac de sable',
  quantity: 1,
  equipped: false,
);

const _sword = CharacterInventoryItem(
  id: 'inv-sword',
  itemId: 1,
  name: 'Épée longue',
  category: 'arme',
  quantity: 1,
  equipped: false,
  unitWeight: 1.5,
  costAmount: 15,
  description: 'Une lame affûtée.',
  weaponProperties: CharacterInventoryWeaponProperties(
    damageDice: '1d8',
    damageType: 'tranchant',
    properties: ['polyvalente(1d10)'],
    rangeNormal: null,
    rangeMax: null,
  ),
);

const _swordEquipped = CharacterInventoryItem(
  id: 'inv-sword-2',
  itemId: 6,
  name: 'Épée courte',
  category: 'arme',
  quantity: 1,
  equipped: true,
  weaponSlot: WeaponSlot.principal,
);

const _armor = CharacterInventoryItem(
  id: 'inv-armor',
  itemId: 2,
  name: 'Chemise de mailles',
  category: 'armure',
  quantity: 1,
  equipped: true,
  armorProperties: CharacterInventoryArmorProperties(
    acBase: 13,
    acDexBonus: 'max_2',
    strengthRequirement: null,
    stealthDisadvantage: false,
  ),
);

const _potion = CharacterInventoryItem(
  id: 'inv-potion',
  itemId: 3,
  name: 'Potion de soins',
  category: 'equipement_general',
  quantity: 3,
  equipped: false,
  consumable: true,
);

const _magicItem = CharacterInventoryItem(
  id: 'inv-magic',
  itemId: 4,
  name: 'Amulette de vitalité',
  category: 'objet_magique',
  quantity: 1,
  equipped: false,
  rarity: 'rare',
  requiresAttunement: true,
);

void main() {
  List<CharacterInventoryItem> useCalls = [];
  List<CharacterInventoryItem> toggleCalls = [];
  List<CharacterInventoryItem> toggleAttunedCalls = [];
  List<CharacterInventoryItem> removeCalls = [];
  List<(CharacterInventoryItem, WeaponSlot)> equipWeaponCalls = [];

  Future<void> pumpSheet(
    WidgetTester tester, {
    required CharacterInventoryItem item,
    int attunedCount = 0,
    List<CharacterInventoryItem> equippedWeapons = const [],
    int? weaponAttackBonus,
    int? weaponDamageModifier,
    Locale locale = const Locale('fr'),
  }) async {
    useCalls = [];
    toggleCalls = [];
    toggleAttunedCalls = [];
    removeCalls = [];
    equipWeaponCalls = [];
    await tester.pumpWidget(
      MaterialApp(
        // `weapon_slot_picker_sheet.dart` (sheet "Choisir un set", ouverte
        // par "Équiper"/"Changer de set" depuis `item_action_sheet.dart`) lit
        // `AppLocalizations.of(context)!` (chantier "traduction de l'app"
        // Phase B, lot "Characters — classe/race/maîtrises") : sans ces
        // delegates, l'appel renverrait `null` et le `!` planterait —
        // ricochet trouvé en lançant la suite complète.
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showItemActionSheet(
                  context,
                  item: item,
                  onUseItem: useCalls.add,
                  onToggleEquipped: toggleCalls.add,
                  onToggleAttuned: toggleAttunedCalls.add,
                  onRemoveItem: removeCalls.add,
                  attunedCount: attunedCount,
                  equippedWeapons: equippedWeapons,
                  onEquipWeaponToSlot: (item, slot) =>
                      equipWeaponCalls.add((item, slot)),
                  weaponAttackBonus: weaponAttackBonus,
                  weaponDamageModifier: weaponDamageModifier,
                ),
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
  }

  group('sheet d\'actions', () {
    testWidgets('un objet personnalisé n\'a que "Infos" et "Retirer"', (
      tester,
    ) async {
      await pumpSheet(tester, item: _customItem);

      expect(find.text('Petit sac de sable'), findsOneWidget);
      expect(find.text('Objet personnalisé · x1'), findsOneWidget);
      expect(find.text('Infos'), findsOneWidget);
      expect(find.text('Utiliser'), findsNothing);
      expect(find.text('Équiper'), findsNothing);
      expect(find.text('Déséquiper'), findsNothing);
      expect(find.text('Retirer'), findsOneWidget);
    });

    testWidgets(
      'une arme non équipée : "Équiper" (pas "Utiliser", pas consommable) '
      'ouvre la sheet de choix de set puis appelle onEquipWeaponToSlot',
      (tester) async {
        await pumpSheet(tester, item: _sword);

        expect(find.text('Équiper'), findsOneWidget);
        expect(find.text('Utiliser'), findsNothing);
        expect(find.text('Déséquiper'), findsNothing);

        await tester.tap(find.text('Équiper'));
        await tester.pumpAndSettle();

        expect(find.text('CHOISIR UN SET'), findsOneWidget);
        await tester.tap(find.text('Set principal'));
        await tester.pumpAndSettle();

        expect(equipWeaponCalls, [(_sword, WeaponSlot.principal)]);
        expect(toggleCalls, isEmpty);
      },
    );

    testWidgets(
      'une arme déjà équipée : libellé "Changer de set" (choix de set) + '
      '"Déséquiper" séparée (bascule directe)',
      (tester) async {
        await pumpSheet(
          tester,
          item: _swordEquipped,
          equippedWeapons: [_swordEquipped],
        );

        expect(find.text('Changer de set'), findsOneWidget);
        expect(find.text('Déséquiper'), findsOneWidget);
        expect(find.text('Équiper'), findsNothing);

        await tester.tap(find.text('Déséquiper'));
        await tester.pumpAndSettle();

        expect(toggleCalls, [_swordEquipped]);
        expect(equipWeaponCalls, isEmpty);
      },
    );

    testWidgets(
      'une arme déjà équipée : "Changer de set" ouvre la sheet, un set '
      'occupé affiche le nom de l\'arme qui l\'occupe',
      (tester) async {
        const other = CharacterInventoryItem(
          id: 'inv-sword-3',
          itemId: 7,
          name: 'Hachette',
          category: 'arme',
          quantity: 1,
          equipped: true,
          weaponSlot: WeaponSlot.secondary,
        );
        await pumpSheet(
          tester,
          item: _swordEquipped,
          equippedWeapons: [_swordEquipped, other],
        );

        await tester.tap(find.text('Changer de set'));
        await tester.pumpAndSettle();

        expect(find.text('Hachette'), findsOneWidget);

        await tester.tap(find.text('Set secondaire'));
        await tester.pumpAndSettle();

        expect(equipWeaponCalls, [(_swordEquipped, WeaponSlot.secondary)]);
      },
    );

    testWidgets('une armure déjà équipée : libellé "Déséquiper"', (
      tester,
    ) async {
      await pumpSheet(tester, item: _armor);

      expect(find.text('Déséquiper'), findsOneWidget);
      expect(find.text('Équiper'), findsNothing);

      await tester.tap(find.text('Déséquiper'));
      await tester.pumpAndSettle();

      expect(toggleCalls, [_armor]);
    });

    testWidgets(
      'un objet consommable : "Utiliser" (pas "Équiper"/"Déséquiper", '
      'catégorie non équipable)',
      (tester) async {
        await pumpSheet(tester, item: _potion);

        expect(find.text('Utiliser'), findsOneWidget);
        expect(find.text('Équiper'), findsNothing);

        await tester.tap(find.text('Utiliser'));
        await tester.pumpAndSettle();

        expect(useCalls, [_potion]);
      },
    );

    testWidgets(
      '"Retirer" ouvre le dialogue de confirmation ; "Annuler" ne déclenche '
      'rien',
      (tester) async {
        await pumpSheet(tester, item: _sword);

        await tester.tap(find.text('Retirer'));
        await tester.pumpAndSettle();

        expect(find.text('Retirer Épée longue ?'), findsOneWidget);
        expect(find.text('Cette action est définitive.'), findsOneWidget);

        await tester.tap(find.text('ANNULER'));
        await tester.pumpAndSettle();

        expect(removeCalls, isEmpty);
      },
    );

    testWidgets('"Retirer" confirmé appelle onRemoveItem', (tester) async {
      await pumpSheet(tester, item: _sword);

      await tester.tap(find.text('Retirer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retirer'));
      await tester.pumpAndSettle();

      expect(removeCalls, [_sword]);
    });

    testWidgets(
      'un objet requérant harmonisation : "Harmoniser cet objet" appelle '
      'onToggleAttuned',
      (tester) async {
        await pumpSheet(tester, item: _magicItem);

        expect(find.text('Harmoniser cet objet'), findsOneWidget);

        await tester.tap(find.text('Harmoniser cet objet'));
        await tester.pumpAndSettle();

        expect(toggleAttunedCalls, [_magicItem]);
      },
    );

    testWidgets('un objet déjà harmonisé : libellé "Ne plus harmoniser"', (
      tester,
    ) async {
      const attuned = CharacterInventoryItem(
        id: 'inv-magic-attuned',
        itemId: 5,
        name: 'Bague harmonisée',
        category: 'objet_magique',
        quantity: 1,
        equipped: false,
        requiresAttunement: true,
        isAttuned: true,
      );
      await pumpSheet(tester, item: attuned);

      expect(find.text('Ne plus harmoniser'), findsOneWidget);
      expect(find.text('Harmoniser cet objet'), findsNothing);

      await tester.tap(find.text('Ne plus harmoniser'));
      await tester.pumpAndSettle();

      expect(toggleAttunedCalls, [attuned]);
    });

    testWidgets(
      'plafond de 3 objets harmonisés atteint : "Harmoniser cet objet" est '
      'désactivée, libellé de fin "Limite (3) atteinte", tap sans effet',
      (tester) async {
        await pumpSheet(tester, item: _magicItem, attunedCount: 3);

        expect(find.text('Limite (3) atteinte'), findsOneWidget);

        await tester.tap(
          find.text('Harmoniser cet objet'),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        expect(toggleAttunedCalls, isEmpty);
      },
    );

    testWidgets(
      'un objet ne requérant pas d\'harmonisation : action absente de la '
      'sheet',
      (tester) async {
        await pumpSheet(tester, item: _sword);

        expect(find.text('Harmoniser cet objet'), findsNothing);
        expect(find.text('Ne plus harmoniser'), findsNothing);
      },
    );
  });

  group('panneau "Infos"', () {
    testWidgets('une arme non équipée : poids unitaire, coût, dégâts, '
        'propriétés, description, AUCUN bouton en pied (choisir un set ne '
        'peut pas se représenter par un simple bouton bascule)', (
      tester,
    ) async {
      await pumpSheet(tester, item: _sword);

      await tester.tap(find.text('Infos'));
      await tester.pumpAndSettle();

      expect(find.text('ÉPÉE LONGUE'), findsOneWidget);
      expect(find.text('Poids unitaire'), findsOneWidget);
      expect(find.text('1,5 kg'), findsOneWidget);
      expect(find.text('Coût'), findsOneWidget);
      expect(find.text('15 po'), findsOneWidget);
      expect(find.text('Dégâts'), findsOneWidget);
      expect(find.text('1d8 tranchant'), findsOneWidget);
      expect(find.text('Propriétés'), findsOneWidget);
      expect(find.text('polyvalente(1d10)'), findsOneWidget);
      // Pas de portée (arme de corps à corps, rangeNormal nul).
      expect(find.text('Portée'), findsNothing);
      // Non équipée -> aucune ligne "Set".
      expect(find.text('Set'), findsNothing);
      expect(find.text('DESCRIPTION'), findsOneWidget);
      expect(find.text('Une lame affûtée.'), findsOneWidget);

      expect(find.byType(PrimaryButton), findsNothing);
    });

    testWidgets(
      'une arme équipée assignée à un set : ligne "Set" en lecture seule, '
      'toujours aucun bouton en pied',
      (tester) async {
        await pumpSheet(tester, item: _swordEquipped);

        await tester.tap(find.text('Infos'));
        await tester.pumpAndSettle();

        expect(find.text('Set'), findsOneWidget);
        expect(find.text('Set principal'), findsOneWidget);
        expect(find.byType(PrimaryButton), findsNothing);
      },
    );

    testWidgets('une armure : CA de base, bonus Dex, désavantage discrétion, '
        'force requise omise si nulle', (tester) async {
      await pumpSheet(tester, item: _armor);

      await tester.tap(find.text('Infos'));
      await tester.pumpAndSettle();

      expect(find.text('CA de base'), findsOneWidget);
      expect(find.text('13'), findsOneWidget);
      expect(find.text('Bonus Dex'), findsOneWidget);
      expect(find.text('+2 max'), findsOneWidget);
      expect(find.text('Force requise'), findsNothing);
      expect(find.text('Désavantage discrétion'), findsOneWidget);
      expect(find.text('Non'), findsOneWidget);

      // Déjà équipée -> le footer propose "Déséquiper".
      expect(find.widgetWithText(PrimaryButton, 'DÉSÉQUIPER'), findsOneWidget);
    });

    testWidgets('un objet magique : rareté affichée, jamais en doré (texte '
        'textPrimary), lien "Harmoniser cet objet" (requiert harmonisation)', (
      tester,
    ) async {
      await pumpSheet(tester, item: _magicItem);

      await tester.tap(find.text('Infos'));
      await tester.pumpAndSettle();

      expect(find.text('Rareté'), findsOneWidget);
      expect(find.text('Rare'), findsOneWidget);
      expect(find.text('Harmoniser cet objet'), findsOneWidget);
      // Ni consommable ni équipable -> aucun bouton en pied.
      expect(find.byType(PrimaryButton), findsNothing);

      await tester.tap(find.text('Harmoniser cet objet'));
      await tester.pumpAndSettle();

      expect(toggleAttunedCalls, [_magicItem]);
      // Le panneau se referme (même principe que la bascule
      // "Préparer ce sort" de l'onglet Sorts).
      expect(find.text('AMULETTE DE VITALITÉ'), findsNothing);
    });

    testWidgets(
      'plafond de 3 objets harmonisés atteint : le lien du panneau est '
      'désactivé (grisé), légende affichée',
      (tester) async {
        await pumpSheet(tester, item: _magicItem, attunedCount: 3);

        await tester.tap(find.text('Infos'));
        await tester.pumpAndSettle();

        expect(
          find.text('Limite de 3 objets harmonisés atteinte.'),
          findsOneWidget,
        );

        await tester.tap(
          find.text('Harmoniser cet objet'),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        expect(toggleAttunedCalls, isEmpty);
      },
    );

    testWidgets('description absente affiche un texte de repli', (
      tester,
    ) async {
      await pumpSheet(tester, item: _customItem);

      await tester.tap(find.text('Infos'));
      await tester.pumpAndSettle();

      expect(find.text('Aucune description disponible.'), findsOneWidget);
      // Objet personnalisé : ni poids ni coût connus, aucune ligne affichée
      // avant la description.
      expect(find.text('Poids unitaire'), findsNothing);
      expect(find.text('Coût'), findsNothing);
    });

    testWidgets(
      "un objet consommable : le bouton 'Utiliser' du panneau délègue à "
      'onUseItem',
      (tester) async {
        await pumpSheet(tester, item: _potion);

        await tester.tap(find.text('Infos'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(PrimaryButton, 'UTILISER'));
        await tester.pumpAndSettle();

        expect(useCalls, [_potion]);
      },
    );

    testWidgets(
      'weaponAttackBonus/weaponDamageModifier : ligne "Attaque" et dégâts '
      'avec le modificateur intégré ("1d8+3 tranchant")',
      (tester) async {
        await pumpSheet(
          tester,
          item: _sword,
          weaponAttackBonus: 5,
          weaponDamageModifier: 3,
        );

        await tester.tap(find.text('Infos'));
        await tester.pumpAndSettle();

        expect(find.text('Attaque'), findsOneWidget);
        expect(find.text('+5'), findsOneWidget);
        expect(find.text('Dégâts'), findsOneWidget);
        expect(find.text('1d8+3 tranchant'), findsOneWidget);
      },
    );

    testWidgets('weaponAttackBonus/weaponDamageModifier absents : pas de ligne '
        '"Attaque", dégâts sans modificateur ("1d8 tranchant")', (
      tester,
    ) async {
      await pumpSheet(tester, item: _sword);

      await tester.tap(find.text('Infos'));
      await tester.pumpAndSettle();

      expect(find.text('Attaque'), findsNothing);
      expect(find.text('1d8 tranchant'), findsOneWidget);
    });

    testWidgets(
      'readOnly: true (ex. tap depuis la carte "ARMES ÉQUIPÉES") : ni le '
      'lien d\'harmonisation ni le bouton en pied ne sont rendus',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => showItemInfoPanel(
                      context,
                      item: _magicItem,
                      onUseItem: (_) {},
                      onToggleEquipped: (_) {},
                      onToggleAttuned: (_) {},
                      attunedCount: 0,
                      readOnly: true,
                    ),
                    child: const Text('Ouvrir'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Ouvrir'));
        await tester.pumpAndSettle();

        expect(find.text('AMULETTE DE VITALITÉ'), findsOneWidget);
        expect(find.text('Rareté'), findsOneWidget);
        expect(find.text('Harmoniser cet objet'), findsNothing);
        expect(find.byType(PrimaryButton), findsNothing);
      },
    );
  });

  group('locale anglaise', () {
    // Même rationale que les autres lots du chantier "traduction de l'app"
    // Phase B : vérifie qu'un texte anglais s'affiche réellement.
    testWidgets(
      'sheet d\'actions : Info/Use/Equip/Remove et sous-titre en anglais',
      (tester) async {
        await pumpSheet(tester, item: _sword, locale: const Locale('en'));

        expect(find.text('Info'), findsOneWidget);
        expect(find.text('Equip'), findsOneWidget);
        expect(find.text('Remove'), findsOneWidget);

        await tester.tap(find.text('Remove'));
        await tester.pumpAndSettle();

        expect(find.text('Remove Épée longue?'), findsOneWidget);
        expect(find.text('This action is permanent.'), findsOneWidget);
        expect(find.text('CANCEL'), findsOneWidget);
      },
    );

    testWidgets(
      'sheet d\'actions : arme équipée -> "Change set"/"Unequip" en anglais',
      (tester) async {
        await pumpSheet(
          tester,
          item: _swordEquipped,
          equippedWeapons: [_swordEquipped],
          locale: const Locale('en'),
        );

        expect(find.text('Change set'), findsOneWidget);
        expect(find.text('Unequip'), findsOneWidget);
      },
    );

    testWidgets('sheet d\'actions : objet consommable -> "Use" en anglais', (
      tester,
    ) async {
      await pumpSheet(tester, item: _potion, locale: const Locale('en'));

      expect(find.text('Use'), findsOneWidget);
    });

    testWidgets(
      'sheet d\'actions : harmonisation -> "Attune to this item"/"Limit '
      '({cap}) reached" en anglais',
      (tester) async {
        await pumpSheet(
          tester,
          item: _magicItem,
          attunedCount: 3,
          locale: const Locale('en'),
        );

        expect(find.text('Limit (3) reached'), findsOneWidget);
      },
    );

    testWidgets(
      'panneau "Infos" : libellés poids/coût/dégâts/propriétés en anglais',
      (tester) async {
        await pumpSheet(tester, item: _sword, locale: const Locale('en'));
        await tester.tap(find.text('Info'));
        await tester.pumpAndSettle();

        expect(find.text('Unit weight'), findsOneWidget);
        expect(find.text('Cost'), findsOneWidget);
        expect(find.text('Damage'), findsOneWidget);
        expect(find.text('Properties'), findsOneWidget);
        expect(find.text('DESCRIPTION'), findsOneWidget);
      },
    );

    testWidgets(
      'panneau "Infos" d\'une armure : CA/bonus Dex/désavantage discrétion '
      'et bouton "Unequip" en anglais',
      (tester) async {
        await pumpSheet(tester, item: _armor, locale: const Locale('en'));
        await tester.tap(find.text('Info'));
        await tester.pumpAndSettle();

        expect(find.text('Base AC'), findsOneWidget);
        expect(find.text('Dex bonus'), findsOneWidget);
        expect(find.text('Stealth disadvantage'), findsOneWidget);
        expect(find.text('No'), findsOneWidget);
        expect(find.widgetWithText(PrimaryButton, 'UNEQUIP'), findsOneWidget);
      },
    );

    testWidgets(
      'panneau "Infos" d\'un objet magique : rareté, lien d\'harmonisation '
      'et légende de plafond en anglais',
      (tester) async {
        await pumpSheet(
          tester,
          item: _magicItem,
          attunedCount: 3,
          locale: const Locale('en'),
        );
        await tester.tap(find.text('Info'));
        await tester.pumpAndSettle();

        expect(find.text('Rarity'), findsOneWidget);
        expect(find.text('Rare'), findsOneWidget);
        expect(find.text('Attune to this item'), findsOneWidget);
        // Forme plurielle (`attunementCap` vaut toujours 3 en pratique dans
        // l'app — voir `CharacterDetail.attunementCap`).
        expect(find.text('Limit of 3 attuned items reached.'), findsOneWidget);
      },
    );

    testWidgets('panneau "Infos" : description de repli en anglais', (
      tester,
    ) async {
      await pumpSheet(tester, item: _customItem, locale: const Locale('en'));
      await tester.tap(find.text('Info'));
      await tester.pumpAndSettle();

      expect(find.text('No description available.'), findsOneWidget);
    });

    testWidgets('panneau "Infos" d\'un consommable : bouton "Use" en anglais', (
      tester,
    ) async {
      await pumpSheet(tester, item: _potion, locale: const Locale('en'));
      await tester.tap(find.text('Info'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(PrimaryButton, 'USE'), findsOneWidget);
    });

    test('légende de plafond d\'harmonisation : forme singulière (cap=1, non '
        'atteignable en pratique — attunementCap vaut toujours 3 — mais '
        'vérifiée directement pour couvrir la forme ICU plural manquante)', () {
      final fr = AppLocalizationsFr();
      final en = AppLocalizationsEn();

      expect(
        fr.itemInfoPanelAttunementCapReachedCaption(1),
        'Limite de 1 objet harmonisé atteinte.',
      );
      expect(
        en.itemInfoPanelAttunementCapReachedCaption(1),
        'Limit of 1 attuned item reached.',
      );
      // Forme plurielle, pour mémoire (déjà couverte par un vrai widget
      // ci-dessus avec la valeur réelle de `attunementCap`, 3).
      expect(
        fr.itemInfoPanelAttunementCapReachedCaption(3),
        'Limite de 3 objets harmonisés atteinte.',
      );
      expect(
        en.itemInfoPanelAttunementCapReachedCaption(3),
        'Limit of 3 attuned items reached.',
      );
    });
  });
}
