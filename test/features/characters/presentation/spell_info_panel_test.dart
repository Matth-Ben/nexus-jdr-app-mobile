// Tests de widget du panneau "Infos" d'un sort
// (`presentation/widgets/spell_info_panel.dart`) et de la sheet de choix de
// niveau d'emplacement que son bouton "Lancer" peut ouvrir
// (`presentation/widgets/spell_action_sheet.dart::castSpellFlow`) — même
// patron que `rest_sheet_test.dart` : le panneau est ouvert depuis un
// `Builder` minimal, `onCastSpell` est un simple callback synchrone
// enregistrant ses appels (toute la logique d'écriture réseau vit dans
// `character_detail_screen.dart`, hors périmètre de ce fichier).
//
// Remplace l'ancien `spell_action_sheet_test.dart` : le tap sur une ligne de
// sort de l'onglet "Sorts" ouvrait jusque-là une sheet intermédiaire
// "Infos"/"Lancer" (`showSpellActionSheet`) avant d'atteindre ce panneau —
// retirée (retour utilisateur : "Lancer" étant déjà accessible depuis
// "Infos", l'étape intermédiaire n'ajoutait qu'un aller-retour), le tap
// ouvre désormais directement ce panneau ([showSpellInfoPanel]).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/character_spell_slot.dart';
import 'package:personnages/features/characters/domain/spell_cast_block_reason.dart';
import 'package:personnages/features/characters/domain/spell_grant_source.dart';
import 'package:personnages/features/characters/presentation/widgets/spell_info_panel.dart';

const _cantrip = CharacterSpellEntry(
  id: 1,
  name: 'Lumière',
  level: 0,
  school: 'Évocation',
  status: 'connu',
);

const _fireball = CharacterSpellEntry(
  id: 2,
  name: 'Boule de feu',
  level: 3,
  school: 'Évocation',
  // 'préparé' (et non 'connu') : ces tests portent sur le flux de lancer, qui
  // exige désormais `SpellStatusFormatter.canCast` — voir
  // `spell_status_formatter_test.dart` pour les tests dédiés au statut lui-même.
  status: 'préparé',
  castingTime: '1 action',
  range: '45 mètres',
  components: {
    'verbal': true,
    'somatic': true,
    'material': true,
    'material_desc': 'du guano',
  },
  duration: 'Instantanée',
  concentration: false,
  description: 'Une sphère de feu explose.',
);

void main() {
  List<CharacterSpellEntry> castCalls = [];
  List<int?> castLevels = [];
  List<CharacterSpellSlot?> castSlots = [];
  List<CharacterSpellEntry> preparedToggleCalls = [];

  Future<void> pumpPanel(
    WidgetTester tester, {
    required CharacterSpellEntry spell,
    required List<CharacterSpellSlot> spellSlots,
    CharacterSpellSlot? pactSlot,
  }) async {
    castCalls = [];
    castLevels = [];
    castSlots = [];
    preparedToggleCalls = [];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showSpellInfoPanel(
                  context,
                  spell: spell,
                  spellSlots: spellSlots,
                  pactSlot: pactSlot,
                  onCastSpell: (castSpell, slot) {
                    castCalls.add(castSpell);
                    castLevels.add(slot?.level);
                    castSlots.add(slot);
                  },
                  onTogglePrepared: preparedToggleCalls.add,
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

  testWidgets(
    'tap direct : affiche immédiatement le détail technique complet et la '
    'description, sans sheet "Infos"/"Lancer" intermédiaire',
    (tester) async {
      await pumpPanel(
        tester,
        spell: _fireball,
        spellSlots: const [CharacterSpellSlot(level: 3, total: 2, used: 0)],
      );

      expect(find.text('BOULE DE FEU'), findsOneWidget);
      expect(find.text('Évocation · Niveau 3'), findsOneWidget);
      expect(find.text("Temps d'incantation"), findsOneWidget);
      expect(find.text('1 action'), findsOneWidget);
      expect(find.text('Portée'), findsOneWidget);
      expect(find.text('45 mètres'), findsOneWidget);
      expect(find.text('Composantes'), findsOneWidget);
      expect(find.text('V, S, M — du guano'), findsOneWidget);
      expect(find.text('Durée'), findsOneWidget);
      expect(find.text('Instantanée'), findsOneWidget);
      expect(find.text('Concentration'), findsOneWidget);
      expect(find.text('Non'), findsOneWidget);
      expect(find.text('DESCRIPTION'), findsOneWidget);
      expect(find.text('Une sphère de feu explose.'), findsOneWidget);
      // Ni "Infos" ni sheet intermédiaire : un seul bouton d'action, "Lancer".
      expect(find.text('Infos'), findsNothing);
      expect(find.widgetWithText(PrimaryButton, 'LANCER'), findsOneWidget);
    },
  );

  testWidgets('un cantrip : "Lancer" exécute directement sans sheet de choix, '
      'slotLevel null', (tester) async {
    await pumpPanel(tester, spell: _cantrip, spellSlots: const []);

    expect(find.text('LUMIÈRE'), findsOneWidget);
    await tester.tap(find.widgetWithText(PrimaryButton, 'LANCER'));
    await tester.pumpAndSettle();

    expect(castCalls, [_cantrip]);
    expect(castLevels, [null]);
    // Le panneau est refermé.
    expect(find.text('LUMIÈRE'), findsNothing);
  });

  testWidgets(
    'un seul niveau éligible : "Lancer" exécute directement ce niveau, sans '
    'sheet de choix',
    (tester) async {
      await pumpPanel(
        tester,
        spell: _fireball,
        spellSlots: const [CharacterSpellSlot(level: 3, total: 2, used: 0)],
      );

      await tester.tap(find.widgetWithText(PrimaryButton, 'LANCER'));
      await tester.pumpAndSettle();

      expect(castCalls, [_fireball]);
      expect(castLevels, [3]);
      expect(
        find.textContaining("Choisissez le niveau d'emplacement"),
        findsNothing,
      );
    },
  );

  testWidgets(
    'plusieurs niveaux éligibles : "Lancer" ouvre une sheet de choix, un '
    'niveau épuisé reste listé mais non sélectionnable',
    (tester) async {
      await pumpPanel(
        tester,
        spell: _fireball,
        spellSlots: const [
          CharacterSpellSlot(level: 3, total: 2, used: 2), // épuisé
          CharacterSpellSlot(level: 4, total: 1, used: 0),
        ],
      );

      await tester.tap(find.widgetWithText(PrimaryButton, 'LANCER'));
      await tester.pumpAndSettle();

      expect(find.text('Lancer Boule de feu'), findsOneWidget);
      expect(find.text('Niveau 3'), findsOneWidget);
      expect(find.text('Niveau 4'), findsOneWidget);
      expect(find.text('Épuisé'), findsOneWidget);

      // Le niveau épuisé (3) ne doit rien déclencher au tap.
      await tester.tap(find.text('Niveau 3'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Confirme avec la présélection par défaut (niveau 4, seul disponible).
      final confirmButton = tester.widget<PrimaryButton>(
        find.widgetWithText(PrimaryButton, 'LANCER'),
      );
      expect(confirmButton.onPressed, isNotNull);
      await tester.tap(find.widgetWithText(PrimaryButton, 'LANCER'));
      await tester.pumpAndSettle();

      expect(castCalls, [_fireball]);
      expect(castLevels, [4]);
    },
  );

  testWidgets(
    'un emplacement de pacte ET un emplacement classique au même niveau '
    'numérique : les 2 options sont listées et sélectionnables '
    'indépendamment (identité d\'objet, pas comparaison de niveau)',
    (tester) async {
      await pumpPanel(
        tester,
        spell: _fireball,
        spellSlots: const [CharacterSpellSlot(level: 3, total: 1, used: 0)],
        pactSlot: const CharacterSpellSlot(
          level: 3,
          total: 1,
          used: 0,
          isPact: true,
        ),
      );

      await tester.tap(find.widgetWithText(PrimaryButton, 'LANCER'));
      await tester.pumpAndSettle();

      // Deux options distinctes affichées malgré le même niveau numérique.
      expect(find.text('Niveau 3'), findsOneWidget);
      expect(find.text('Niveau 3 (pacte)'), findsOneWidget);

      // Sélectionne explicitement l'option de pacte.
      await tester.tap(find.text('Niveau 3 (pacte)'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PrimaryButton, 'LANCER'));
      await tester.pumpAndSettle();

      expect(castCalls, [_fireball]);
      expect(castSlots, hasLength(1));
      expect(castSlots.single!.isPact, isTrue);
      expect(castSlots.single!.level, 3);
    },
  );

  testWidgets('même cas, mais l\'option classique (non pacte) est choisie', (
    tester,
  ) async {
    await pumpPanel(
      tester,
      spell: _fireball,
      spellSlots: const [CharacterSpellSlot(level: 3, total: 1, used: 0)],
      pactSlot: const CharacterSpellSlot(
        level: 3,
        total: 1,
        used: 0,
        isPact: true,
      ),
    );

    await tester.tap(find.widgetWithText(PrimaryButton, 'LANCER'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Niveau 3'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PrimaryButton, 'LANCER'));
    await tester.pumpAndSettle();

    expect(castCalls, [_fireball]);
    expect(castSlots, hasLength(1));
    expect(castSlots.single!.isPact, isFalse);
    expect(castSlots.single!.level, 3);
  });

  group('distinction connu/préparé (SpellStatusFormatter)', () {
    const knownSpell = CharacterSpellEntry(
      id: 3,
      name: 'Toile d\'araignée',
      level: 2,
      school: 'Conjuration',
      status: 'connu',
    );

    const preparedSpell = CharacterSpellEntry(
      id: 4,
      name: 'Immobilisation de personne',
      level: 2,
      school: 'Enchantement',
      status: 'préparé',
    );

    testWidgets(
      'taper "Préparer ce sort" appelle onTogglePrepared avec le sort et '
      'referme le panneau, sans lancer castSpell',
      (tester) async {
        await pumpPanel(
          tester,
          spell: knownSpell,
          spellSlots: const [CharacterSpellSlot(level: 2, total: 2, used: 0)],
        );

        await tester.tap(find.text('Préparer ce sort'));
        await tester.pumpAndSettle();

        expect(preparedToggleCalls, [knownSpell]);
        expect(castCalls, isEmpty);
        expect(find.text('TOILE D\'ARAIGNÉE'), findsNothing);
      },
    );

    testWidgets(
      'un sort niveau >= 1 \'préparé\' : "Lancer" est actif et le lien '
      'affiche "Ne plus préparer"',
      (tester) async {
        await pumpPanel(
          tester,
          spell: preparedSpell,
          spellSlots: const [CharacterSpellSlot(level: 2, total: 2, used: 0)],
        );

        final button = tester.widget<PrimaryButton>(
          find.widgetWithText(PrimaryButton, 'LANCER'),
        );
        expect(button.onPressed, isNotNull);
        expect(find.text('Ne plus préparer'), findsOneWidget);
        expect(find.text('Préparer ce sort'), findsNothing);
      },
    );

    testWidgets(
      'taper "Ne plus préparer" appelle onTogglePrepared avec le sort',
      (tester) async {
        await pumpPanel(
          tester,
          spell: preparedSpell,
          spellSlots: const [CharacterSpellSlot(level: 2, total: 2, used: 0)],
        );

        await tester.tap(find.text('Ne plus préparer'));
        await tester.pumpAndSettle();

        expect(preparedToggleCalls, [preparedSpell]);
      },
    );

    testWidgets('un cantrip (niveau 0) : aucun lien de bascule de préparation '
        '(canTogglePrepared toujours faux)', (tester) async {
      await pumpPanel(tester, spell: _cantrip, spellSlots: const []);

      expect(find.text('Préparer ce sort'), findsNothing);
      expect(find.text('Ne plus préparer'), findsNothing);
    });
  });

  void useScreen(WidgetTester tester, Size size, double textScale) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);
  }

  Finder castButton() => find.widgetWithText(PrimaryButton, 'LANCER');

  // Les combinaisons d'emplacements (niveau inférieur/supérieur, pacte
  // épuisé...) et l'équivalence avec l'ancienne règle d'activation sont
  // couvertes par `domain/spell_cast_block_reason_test.dart` : ce groupe ne
  // prouve que le câblage du panneau (raison -> bouton + ligne) et sa mise en
  // page.
  group('raison affichée sous "Lancer" désactivé (SpellCastBlockReason)', () {
    final unpreparedMessage = SpellCastBlockReason.unprepared.message;
    final noSlotMessage = SpellCastBlockReason.noSlotAvailable.message;

    // Toute ligne de raison, pas seulement celle attendue.
    Finder reasonLine() => find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          SpellCastBlockReason.values.any(
            (reason) => reason.message == widget.data,
          ),
    );

    bool castEnabled(WidgetTester tester) =>
        tester.widget<PrimaryButton>(castButton()).onPressed != null;

    void expectCastable(WidgetTester tester) {
      expect(castEnabled(tester), isTrue, reason: '"Lancer" doit être actif');
      expect(reasonLine(), findsNothing);
    }

    void expectBlocked(WidgetTester tester, String message) {
      expect(
        castEnabled(tester),
        isFalse,
        reason: '"Lancer" doit être désactivé',
      );
      // Une seule ligne, et c'est la bonne.
      expect(reasonLine(), findsOneWidget);
      expect(find.text(message), findsOneWidget);
    }

    const knownSpell = CharacterSpellEntry(
      id: 10,
      name: 'Maléfice',
      level: 1,
      school: 'Enchantement',
      status: 'connu',
    );

    const innateSpell = CharacterSpellEntry(
      id: 11,
      name: 'Ténèbres',
      level: 2,
      school: 'Évocation',
      status: 'inné',
    );

    const grantedSpell = CharacterSpellEntry(
      id: 12,
      name: 'Arme spirituelle',
      level: 2,
      school: 'Évocation',
      status: 'préparé',
      grantSource: SpellGrantSource.domain,
      isPersisted: false,
      storedStatus: 'connu',
    );

    testWidgets('sort lançable : bouton actif et aucune ligne', (tester) async {
      await pumpPanel(
        tester,
        spell: _fireball,
        spellSlots: const [CharacterSpellSlot(level: 3, total: 2, used: 0)],
      );

      expectCastable(tester);
    });

    testWidgets('sort non préparé : désactivé, raison "non préparé" centrée '
        'sous le bouton, lien "Préparer ce sort", et taper le bouton ne lance '
        'rien', (tester) async {
      await pumpPanel(
        tester,
        spell: knownSpell,
        spellSlots: const [CharacterSpellSlot(level: 1, total: 2, used: 0)],
      );

      expectBlocked(tester, unpreparedMessage);
      expect(find.text('Préparer ce sort'), findsOneWidget);
      expect(find.text('Ne plus préparer'), findsNothing);
      expect(
        tester.widget<Text>(find.text(unpreparedMessage)).textAlign,
        TextAlign.center,
      );
      expect(
        tester.getRect(find.text(unpreparedMessage)).top,
        greaterThan(tester.getRect(castButton()).bottom),
      );

      await tester.tap(castButton(), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(castCalls, isEmpty);
      expect(find.text('MALÉFICE'), findsOneWidget);
    });

    testWidgets('sort préparé, plus d\'emplacement : désactivé, raison "plus '
        'd\'emplacement", rien n\'est lancé et le panneau reste ouvert', (
      tester,
    ) async {
      await pumpPanel(
        tester,
        spell: _fireball,
        spellSlots: const [CharacterSpellSlot(level: 3, total: 2, used: 2)],
      );

      expectBlocked(tester, noSlotMessage);

      await tester.tap(castButton(), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(castCalls, isEmpty);
      // Le panneau reste ouvert.
      expect(find.text('BOULE DE FEU'), findsOneWidget);
    });

    testWidgets('non préparé ET plus d\'emplacement : une seule ligne, "non '
        'préparé"', (tester) async {
      await pumpPanel(
        tester,
        spell: knownSpell,
        spellSlots: const [CharacterSpellSlot(level: 1, total: 2, used: 2)],
      );

      expectBlocked(tester, unpreparedMessage);
    });

    testWidgets('sort mineur \'connu\', tous les emplacements épuisés '
        '(classique et pacte) : actif, aucune ligne, lancé sans consommer '
        'd\'emplacement', (tester) async {
      await pumpPanel(
        tester,
        spell: _cantrip,
        spellSlots: const [CharacterSpellSlot(level: 1, total: 2, used: 2)],
        pactSlot: const CharacterSpellSlot(
          level: 1,
          total: 1,
          used: 1,
          isPact: true,
        ),
      );

      expectCastable(tester);

      await tester.tap(castButton());
      await tester.pumpAndSettle();
      expect(castCalls, [_cantrip]);
      expect(castSlots, [null]);
    });

    testWidgets('sort inné avec emplacement : actif, aucune ligne', (
      tester,
    ) async {
      await pumpPanel(
        tester,
        spell: innateSpell,
        spellSlots: const [CharacterSpellSlot(level: 2, total: 1, used: 0)],
      );

      expectCastable(tester);
    });

    testWidgets('sort inné sans emplacement : raison "plus d\'emplacement" '
        '(jamais "non préparé")', (tester) async {
      await pumpPanel(tester, spell: innateSpell, spellSlots: const []);

      expectBlocked(tester, noSlotMessage);
    });

    testWidgets('sort accordé par une sous-classe avec emplacement : actif, '
        'aucune ligne', (tester) async {
      await pumpPanel(
        tester,
        spell: grantedSpell,
        spellSlots: const [CharacterSpellSlot(level: 2, total: 3, used: 2)],
      );

      expectCastable(tester);
      expect(find.textContaining('Toujours préparé'), findsOneWidget);
    });

    testWidgets('sort accordé par une sous-classe, emplacements épuisés : '
        'raison "plus d\'emplacement" (jamais "non préparé", même si la ligne '
        'stockée vaut \'connu\')', (tester) async {
      await pumpPanel(
        tester,
        spell: grantedSpell,
        spellSlots: const [CharacterSpellSlot(level: 2, total: 3, used: 3)],
      );

      expectBlocked(tester, noSlotMessage);
    });

    // Câblage de `pactSlot` : il compte dans la raison (sinon "plus
    // d'emplacement") et c'est bien lui que "Lancer" consomme.
    testWidgets('magie de pacte : seul un emplacement de pacte disponible '
        '(aucun emplacement classique) : actif, aucune ligne, et "Lancer" '
        'consomme le pacte', (tester) async {
      await pumpPanel(
        tester,
        spell: _fireball,
        spellSlots: const [],
        pactSlot: const CharacterSpellSlot(
          level: 3,
          total: 2,
          used: 1,
          isPact: true,
        ),
      );

      expectCastable(tester);

      await tester.tap(castButton());
      await tester.pumpAndSettle();
      expect(castCalls, [_fireball]);
      expect(castSlots.single!.isPact, isTrue);
    });

    // Mise en page à forte échelle de texte (réglage d'accessibilité) : le
    // pied est fixe, la ligne de raison y est donc plafonnée à l'échelle 2.0
    // pour ne pas réduire la zone défilante à néant.
    const layoutMatrix = <(Size, double)>[
      (Size(320, 568), 1.0),
      (Size(320, 568), 2.0),
      (Size(320, 568), 2.5),
      (Size(320, 568), 3.0),
      (Size(360, 640), 3.0),
      (Size(390, 844), 3.0),
    ];
    for (final (size, textScale) in layoutMatrix) {
      for (final reason in SpellCastBlockReason.values) {
        final unprepared = reason == SpellCastBlockReason.unprepared;
        testWidgets('écran ${size.width.toInt()}x${size.height.toInt()}, '
            'échelle $textScale, raison ${reason.name} : aucun débordement, '
            'ligne entièrement visible sous le bouton, zone défilante '
            '>= 44 px${unprepared ? ', "Préparer ce sort" atteignable' : ''}', (
          tester,
        ) async {
          useScreen(tester, size, textScale);
          await pumpPanel(
            tester,
            spell: unprepared ? knownSpell : _fireball,
            spellSlots: const [],
          );

          expect(
            tester.takeException(),
            isNull,
            reason:
                'débordement de mise en page à l\'ouverture du panneau : '
                'message de SpellCastBlockReason.${reason.name} trop long ?',
          );
          expectBlocked(tester, reason.message);
          final line = tester.getRect(find.text(reason.message));
          expect(
            line.left,
            greaterThanOrEqualTo(0),
            reason: 'la ligne de raison dépasse du bord gauche de l\'écran',
          );
          expect(
            line.right,
            lessThanOrEqualTo(size.width),
            reason: 'la ligne de raison dépasse du bord droit de l\'écran',
          );
          expect(
            line.top,
            greaterThanOrEqualTo(tester.getRect(castButton()).bottom),
            reason: 'la ligne de raison chevauche le bouton "Lancer"',
          );
          expect(
            line.bottom,
            lessThanOrEqualTo(size.height),
            reason:
                'le bas de la ligne de raison sort de l\'écran : message de '
                'SpellCastBlockReason.${reason.name} trop long pour le pied ?',
          );
          expect(
            tester.getSize(find.byType(SingleChildScrollView)).height,
            greaterThanOrEqualTo(44),
            reason:
                'zone défilante de moins de 44 px : le pied fixe (bouton + '
                'ligne de raison) prend presque toute la hauteur, message de '
                'SpellCastBlockReason.${reason.name} trop long ?',
          );

          if (unprepared) {
            await tester.ensureVisible(find.text('Préparer ce sort'));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Préparer ce sort'));
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason:
                  'débordement de mise en page après le défilement : message '
                  'de SpellCastBlockReason.${reason.name} trop long ?',
            );
            expect(
              preparedToggleCalls,
              [knownSpell],
              reason:
                  '"Préparer ce sort" inatteignable, masqué par le pied fixe : '
                  'message de SpellCastBlockReason.${reason.name} trop long ?',
            );
          }
        });
      }
    }

    testWidgets('la ligne de raison suit l\'échelle de texte jusqu\'à 2.0 puis '
        'ne grandit plus, alors que le libellé du bouton continue de la '
        'suivre', (tester) async {
      useScreen(tester, const Size(390, 844), 1);
      await pumpPanel(tester, spell: _fireball, spellSlots: const []);

      Future<(double, double)> heightsAt(double textScale) async {
        tester.platformDispatcher.textScaleFactorTestValue = textScale;
        await tester.pumpAndSettle();
        return (
          tester.getSize(find.text(noSlotMessage)).height,
          tester.getSize(find.text('LANCER')).height,
        );
      }

      final (lineAt1, labelAt1) = await heightsAt(1);
      final (lineAt2, labelAt2) = await heightsAt(2);
      final (lineAt3, labelAt3) = await heightsAt(3);

      expect(lineAt2, greaterThan(lineAt1));
      expect(lineAt3, lineAt2);
      // Plafond à 2.0 exactement, pas plus bas : 12 px -> 24 px effectifs à
      // l'échelle système 3.0.
      expect(
        MediaQuery.textScalerOf(tester.element(find.text(noSlotMessage)))
            .scale(12),
        24,
      );
      expect(labelAt2, greaterThan(labelAt1));
      expect(labelAt3, greaterThan(labelAt2));
    });

    testWidgets('petit écran 320x568, échelle 2.0, description très longue : '
        'la raison reste dans le pied fixe (visible sans défilement) et la '
        'description défile jusqu\'au bout au-dessus du pied', (tester) async {
      useScreen(tester, const Size(320, 568), 2);
      final spell = CharacterSpellEntry(
        id: 13,
        name: 'Souhait',
        level: 9,
        school: 'Invocation',
        status: 'connu',
        description:
            '${List.filled(60, 'Texte de description.').join(' ')} FIN.',
      );
      await pumpPanel(tester, spell: spell, spellSlots: const []);
      expect(tester.takeException(), isNull);

      expectBlocked(tester, unpreparedMessage);
      final button = tester.getRect(castButton());
      final line = tester.getRect(find.text(unpreparedMessage));
      final scrollArea = tester.getRect(find.byType(SingleChildScrollView));
      expect(scrollArea.bottom, lessThanOrEqualTo(button.top));
      expect(line.top, greaterThanOrEqualTo(button.bottom));
      expect(line.bottom, lessThanOrEqualTo(568));

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -100000),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final description = tester.getRect(find.text(spell.description));
      expect(description.bottom, lessThanOrEqualTo(scrollArea.bottom));
      expect(description.bottom, greaterThan(scrollArea.top));
    });
  });

  // Correction `Flexible` du lien "Préparer ce sort"/"Ne plus préparer" : le
  // libellé agrandi se replie au lieu de faire déborder la ligne, et le lien
  // reste actionnable. Vérifications comportementales seulement (pas de
  // position au pixel), plus la zone tactile minimale du design system (§7).
  group('lien de bascule de préparation sur petit écran', () {
    const knownSpell = CharacterSpellEntry(
      id: 20,
      name: 'Maléfice',
      level: 1,
      school: 'Enchantement',
      status: 'connu',
    );
    const preparedSpell = CharacterSpellEntry(
      id: 21,
      name: 'Bénédiction',
      level: 1,
      school: 'Enchantement',
      status: 'préparé',
    );
    const slots = [CharacterSpellSlot(level: 1, total: 2, used: 0)];

    String labelOf(CharacterSpellEntry spell) =>
        spell.status == 'connu' ? 'Préparer ce sort' : 'Ne plus préparer';

    Finder linkOf(String label) =>
        find.ancestor(of: find.text(label), matching: find.byType(InkWell));

    for (final spell in const [knownSpell, preparedSpell]) {
      testWidgets('320x568, échelle 1.0, "${labelOf(spell)}" : zone tactile '
          '>= 44 px, actionnable sur toute sa largeur (pas seulement sur le '
          'libellé)', (tester) async {
        useScreen(tester, const Size(320, 568), 1);
        await pumpPanel(tester, spell: spell, spellSlots: slots);
        expect(tester.takeException(), isNull);

        final link = tester.getRect(linkOf(labelOf(spell)));
        expect(link.height, greaterThanOrEqualTo(44));

        await tester.tapAt(link.centerRight - const Offset(4, 0));
        await tester.pumpAndSettle();
        expect(preparedToggleCalls, [spell]);
        expect(castCalls, isEmpty);
      });
    }

    for (final textScale in [1.3, 2.0]) {
      for (final spell in const [knownSpell, preparedSpell]) {
        for (final spellSlots in const [slots, <CharacterSpellSlot>[]]) {
          testWidgets('320x568, échelle $textScale, "${labelOf(spell)}", '
              '${spellSlots.isEmpty ? 'sans' : 'avec'} emplacement : aucun '
              'débordement, zone tactile >= 44 px, lien atteignable et '
              'actionnable', (tester) async {
            useScreen(tester, const Size(320, 568), textScale);
            await pumpPanel(tester, spell: spell, spellSlots: spellSlots);
            expect(tester.takeException(), isNull);

            final label = labelOf(spell);
            expect(
              tester.getSize(linkOf(label)).height,
              greaterThanOrEqualTo(44),
            );

            await tester.ensureVisible(find.text(label));
            await tester.pumpAndSettle();
            await tester.tap(find.text(label));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(preparedToggleCalls, [spell]);
            expect(castCalls, isEmpty);
          });
        }
      }
    }
  });

  // Sort d'une classe à sorts connus (Barde, Ensorceleur, Occultiste,
  // Rôdeur) : `requiresPreparation` faux, dérivé à la lecture de la fiche.
  group('sort qui ne se prépare pas (classe à sorts connus)', () {
    const knownSpell = CharacterSpellEntry(
      id: 9,
      name: 'Charme-personne',
      level: 1,
      school: 'Enchantement',
      status: 'connu',
      requiresPreparation: false,
    );
    const storedPrepared = CharacterSpellEntry(
      id: 10,
      name: 'Héroïsme',
      level: 1,
      school: 'Enchantement',
      status: 'préparé',
      requiresPreparation: false,
    );

    testWidgets('"connu" avec un emplacement : "Lancer" actif, ni lien '
        '"Préparer ce sort" ni ligne de raison', (tester) async {
      await pumpPanel(
        tester,
        spell: knownSpell,
        spellSlots: const [CharacterSpellSlot(level: 1, total: 2, used: 0)],
      );

      expect(find.text('Préparer ce sort'), findsNothing);
      expect(find.text('Ne plus préparer'), findsNothing);
      expect(find.text(SpellCastBlockReason.unprepared.message), findsNothing);
      expect(
        find.text(SpellCastBlockReason.noSlotAvailable.message),
        findsNothing,
      );

      await tester.tap(find.widgetWithText(PrimaryButton, 'LANCER'));
      await tester.pumpAndSettle();

      expect(castCalls, [knownSpell]);
      expect(castLevels, [1]);
      expect(preparedToggleCalls, isEmpty);
    });

    testWidgets('"connu" sans emplacement : "Lancer" inactif, raison "plus '
        'd\'emplacement" et jamais "non préparé"', (tester) async {
      await pumpPanel(
        tester,
        spell: knownSpell,
        spellSlots: const [CharacterSpellSlot(level: 1, total: 2, used: 2)],
      );

      expect(
        tester
            .widget<PrimaryButton>(find.widgetWithText(PrimaryButton, 'LANCER'))
            .onPressed,
        isNull,
      );
      expect(
        find.text(SpellCastBlockReason.noSlotAvailable.message),
        findsOneWidget,
      );
      expect(find.text(SpellCastBlockReason.unprepared.message), findsNothing);
      expect(find.text('Préparer ce sort'), findsNothing);
    });

    testWidgets('déjà "préparé" en base : aucune bascule "Ne plus préparer", '
        '"Lancer" actif', (tester) async {
      await pumpPanel(
        tester,
        spell: storedPrepared,
        spellSlots: const [CharacterSpellSlot(level: 1, total: 2, used: 0)],
      );

      expect(find.text('Ne plus préparer'), findsNothing);
      expect(find.text('Préparer ce sort'), findsNothing);
      expect(
        tester
            .widget<PrimaryButton>(find.widgetWithText(PrimaryButton, 'LANCER'))
            .onPressed,
        isNotNull,
      );
    });
  });
}
