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
import 'package:flutter/rendering.dart';
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

  testWidgets('aucun niveau éligible disponible : "Lancer" est désactivé', (
    tester,
  ) async {
    await pumpPanel(
      tester,
      spell: _fireball,
      spellSlots: const [CharacterSpellSlot(level: 3, total: 2, used: 2)],
    );

    final button = tester.widget<PrimaryButton>(
      find.widgetWithText(PrimaryButton, 'LANCER'),
    );
    expect(button.onPressed, isNull);

    expect(castCalls, isEmpty);
    // Le panneau reste ouvert.
    expect(find.text('BOULE DE FEU'), findsOneWidget);
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

    testWidgets('un sort niveau >= 1 \'connu\' (non préparé) : "Lancer" est '
        'désactivé et le lien affiche "Préparer ce sort"', (tester) async {
      await pumpPanel(
        tester,
        spell: knownSpell,
        spellSlots: const [CharacterSpellSlot(level: 2, total: 2, used: 0)],
      );

      final button = tester.widget<PrimaryButton>(
        find.widgetWithText(PrimaryButton, 'LANCER'),
      );
      expect(button.onPressed, isNull);
      expect(find.text('Préparer ce sort'), findsOneWidget);
      expect(find.text('Ne plus préparer'), findsNothing);
    });

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

  group('raison affichée sous "Lancer" désactivé (SpellCastBlockReason)', () {
    const unpreparedMessage =
        'Sort non préparé : préparez-le pour pouvoir le lancer.';
    const noSlotMessage =
        "Plus d'emplacement de sort disponible pour ce niveau ou un niveau "
        'supérieur.';

    const knownFireball = CharacterSpellEntry(
      id: 5,
      name: 'Boule de feu',
      level: 3,
      school: 'Évocation',
      status: 'connu',
    );

    testWidgets('sort lançable : aucune ligne sous le bouton', (tester) async {
      await pumpPanel(
        tester,
        spell: _fireball,
        spellSlots: const [CharacterSpellSlot(level: 3, total: 2, used: 0)],
      );

      expect(find.text(unpreparedMessage), findsNothing);
      expect(find.text(noSlotMessage), findsNothing);
    });

    testWidgets('sort non préparé : message "non préparé", centré sous le '
        'bouton', (tester) async {
      await pumpPanel(
        tester,
        spell: knownFireball,
        spellSlots: const [CharacterSpellSlot(level: 3, total: 2, used: 0)],
      );

      expect(find.text(unpreparedMessage), findsOneWidget);
      expect(find.text(noSlotMessage), findsNothing);
      expect(
        tester.widget<Text>(find.text(unpreparedMessage)).textAlign,
        TextAlign.center,
      );
      expect(
        tester.getTopLeft(find.text(unpreparedMessage)).dy,
        greaterThan(
          tester.getBottomLeft(find.widgetWithText(PrimaryButton, 'LANCER')).dy,
        ),
      );
    });

    testWidgets('plus d\'emplacement : message "plus d\'emplacement"', (
      tester,
    ) async {
      await pumpPanel(
        tester,
        spell: _fireball,
        spellSlots: const [CharacterSpellSlot(level: 3, total: 2, used: 2)],
      );

      expect(find.text(noSlotMessage), findsOneWidget);
      expect(find.text(unpreparedMessage), findsNothing);
    });

    testWidgets('emplacement classique épuisé mais emplacement de pacte '
        'disponible : sort lançable, aucune ligne', (tester) async {
      await pumpPanel(
        tester,
        spell: _fireball,
        spellSlots: const [CharacterSpellSlot(level: 3, total: 2, used: 2)],
        pactSlot: const CharacterSpellSlot(
          level: 3,
          total: 1,
          used: 0,
          isPact: true,
        ),
      );

      expect(find.text(noSlotMessage), findsNothing);
      final button = tester.widget<PrimaryButton>(
        find.widgetWithText(PrimaryButton, 'LANCER'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('non préparé ET plus d\'emplacement : seule la raison "non '
        'préparé" est affichée', (tester) async {
      await pumpPanel(
        tester,
        spell: knownFireball,
        spellSlots: const [CharacterSpellSlot(level: 3, total: 2, used: 2)],
      );

      expect(find.text(unpreparedMessage), findsOneWidget);
      expect(find.text(noSlotMessage), findsNothing);
    });

    testWidgets('sort mineur (niveau 0) : jamais de ligne, même sans aucun '
        'emplacement', (tester) async {
      await pumpPanel(tester, spell: _cantrip, spellSlots: const []);

      expect(find.text(unpreparedMessage), findsNothing);
      expect(find.text(noSlotMessage), findsNothing);
    });

    testWidgets('petite largeur (320 px) : le message passe à la ligne sans '
        'débordement', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpPanel(
        tester,
        spell: _fireball,
        spellSlots: const [CharacterSpellSlot(level: 3, total: 2, used: 2)],
      );

      expect(find.text(noSlotMessage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  // Ajouts QA : critères 1, 5 et 6 de la demande (activation de "Lancer"
  // strictement inchangée) + petit écran. Les messages sont lus depuis
  // l'enum pour détecter TOUTE ligne de raison, pas seulement l'attendue.
  group('raison sous "Lancer" — non-régression et cas limites (QA)', () {
    final unpreparedMessage = SpellCastBlockReason.unprepared.message;
    final noSlotMessage = SpellCastBlockReason.noSlotAvailable.message;

    Finder reasonLine() => find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          SpellCastBlockReason.values.any(
            (reason) => reason.message == widget.data,
          ),
    );

    bool castEnabled(WidgetTester tester) =>
        tester
            .widget<PrimaryButton>(find.widgetWithText(PrimaryButton, 'LANCER'))
            .onPressed !=
        null;

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

    const innateSpell = CharacterSpellEntry(
      id: 10,
      name: 'Ténèbres',
      level: 2,
      school: 'Évocation',
      status: 'inné',
    );

    const grantedSpell = CharacterSpellEntry(
      id: 11,
      name: 'Arme spirituelle',
      level: 2,
      school: 'Évocation',
      status: 'préparé',
      grantSource: SpellGrantSource.domain,
      isPersisted: false,
      storedStatus: 'connu',
    );

    const knownLevel1 = CharacterSpellEntry(
      id: 12,
      name: 'Maléfice',
      level: 1,
      school: 'Enchantement',
      status: 'connu',
    );

    const preparedLevel1 = CharacterSpellEntry(
      id: 13,
      name: 'Armure d\'Agathys',
      level: 1,
      school: 'Abjuration',
      status: 'préparé',
    );

    testWidgets('sort lançable : bouton actif ET aucune ligne', (tester) async {
      await pumpPanel(
        tester,
        spell: _fireball,
        spellSlots: const [CharacterSpellSlot(level: 3, total: 2, used: 0)],
      );

      expectCastable(tester);
    });

    testWidgets('sort mineur \'connu\', personnage sans aucun emplacement : '
        'bouton actif et aucune ligne', (tester) async {
      await pumpPanel(tester, spell: _cantrip, spellSlots: const []);

      expectCastable(tester);
    });

    // Test séparé du précédent (et non un second `pumpPanel` dans le même
    // test) : le premier panneau resterait ouvert par-dessus le bouton
    // "Ouvrir", et les assertions porteraient encore sur lui.
    testWidgets('sort mineur \'connu\', tous les emplacements épuisés '
        '(classique et pacte) : bouton actif, aucune ligne, et "Lancer" '
        'lance sans consommer d\'emplacement', (tester) async {
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

      await tester.tap(find.widgetWithText(PrimaryButton, 'LANCER'));
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

    testWidgets('sort inné sans emplacement : désactivé, raison "plus '
        'd\'emplacement" (jamais "non préparé")', (tester) async {
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
        'désactivé, raison "plus d\'emplacement" (jamais "non préparé", '
        'même si la ligne stockée vaut \'connu\')', (tester) async {
      await pumpPanel(
        tester,
        spell: grantedSpell,
        spellSlots: const [CharacterSpellSlot(level: 2, total: 3, used: 3)],
      );

      expectBlocked(tester, noSlotMessage);
    });

    testWidgets('Occultiste, seul un emplacement de pacte disponible (aucun '
        'emplacement classique) : actif, aucune ligne, et "Lancer" consomme '
        'bien l\'emplacement de pacte', (tester) async {
      await pumpPanel(
        tester,
        spell: preparedLevel1,
        spellSlots: const [],
        pactSlot: const CharacterSpellSlot(
          level: 2,
          total: 2,
          used: 1,
          isPact: true,
        ),
      );

      expectCastable(tester);

      await tester.tap(find.widgetWithText(PrimaryButton, 'LANCER'));
      await tester.pumpAndSettle();

      expect(castCalls, [preparedLevel1]);
      expect(castSlots.single!.isPact, isTrue);
      expect(castSlots.single!.level, 2);
    });

    testWidgets('Occultiste, emplacement de pacte épuisé : désactivé, raison '
        '"plus d\'emplacement"', (tester) async {
      await pumpPanel(
        tester,
        spell: preparedLevel1,
        spellSlots: const [],
        pactSlot: const CharacterSpellSlot(
          level: 2,
          total: 2,
          used: 2,
          isPact: true,
        ),
      );

      expectBlocked(tester, noSlotMessage);
    });

    testWidgets('Occultiste, emplacement de pacte de niveau inférieur au '
        'sort : désactivé, raison "plus d\'emplacement"', (tester) async {
      await pumpPanel(
        tester,
        spell: _fireball,
        spellSlots: const [],
        pactSlot: const CharacterSpellSlot(
          level: 2,
          total: 2,
          used: 0,
          isPact: true,
        ),
      );

      expectBlocked(tester, noSlotMessage);
    });

    testWidgets('Occultiste, sort non préparé avec emplacement de pacte '
        'disponible : désactivé, raison "non préparé"', (tester) async {
      await pumpPanel(
        tester,
        spell: knownLevel1,
        spellSlots: const [],
        pactSlot: const CharacterSpellSlot(
          level: 2,
          total: 2,
          used: 0,
          isPact: true,
        ),
      );

      expectBlocked(tester, unpreparedMessage);
    });

    testWidgets('niveau du sort épuisé mais emplacement de niveau supérieur '
        'disponible : actif, aucune ligne', (tester) async {
      await pumpPanel(
        tester,
        spell: _fireball,
        spellSlots: const [
          CharacterSpellSlot(level: 1, total: 4, used: 4),
          CharacterSpellSlot(level: 3, total: 2, used: 2),
          CharacterSpellSlot(level: 5, total: 1, used: 0),
        ],
      );

      expectCastable(tester);
    });

    testWidgets('seuls des emplacements de niveau inférieur sont disponibles : '
        'désactivé, raison "plus d\'emplacement"', (tester) async {
      await pumpPanel(
        tester,
        spell: _fireball,
        spellSlots: const [
          CharacterSpellSlot(level: 1, total: 4, used: 0),
          CharacterSpellSlot(level: 2, total: 3, used: 0),
        ],
      );

      expectBlocked(tester, noSlotMessage);
    });

    testWidgets('personnage sans aucun emplacement, sort préparé : désactivé, '
        'raison "plus d\'emplacement", et taper le bouton ne lance rien', (
      tester,
    ) async {
      await pumpPanel(tester, spell: _fireball, spellSlots: const []);

      expectBlocked(tester, noSlotMessage);

      await tester.tap(
        find.widgetWithText(PrimaryButton, 'LANCER'),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(castCalls, isEmpty);
      expect(find.text('BOULE DE FEU'), findsOneWidget);
    });

    testWidgets('personnage sans aucun emplacement, sort non préparé : une '
        'seule ligne, "non préparé", et taper le bouton ne lance rien', (
      tester,
    ) async {
      await pumpPanel(tester, spell: knownLevel1, spellSlots: const []);

      expectBlocked(tester, unpreparedMessage);
      expect(find.text(noSlotMessage), findsNothing);

      await tester.tap(
        find.widgetWithText(PrimaryButton, 'LANCER'),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(castCalls, isEmpty);
      expect(find.text('MALÉFICE'), findsOneWidget);
    });

    testWidgets('la ligne de raison reste dans le pied fixe : visible sans '
        'défilement même avec une description très longue', (tester) async {
      await pumpPanel(
        tester,
        spell: CharacterSpellEntry(
          id: 14,
          name: 'Souhait',
          level: 9,
          school: 'Invocation',
          status: 'connu',
          description: List.filled(200, 'Texte de description.').join(' '),
        ),
        spellSlots: const [],
      );

      expectBlocked(tester, unpreparedMessage);
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      final line = tester.getRect(find.text(unpreparedMessage));
      expect(line.bottom, lessThanOrEqualTo(screen.height));
      expect(
        line.top,
        greaterThanOrEqualTo(
          tester.getRect(find.widgetWithText(PrimaryButton, 'LANCER')).bottom,
        ),
      );
    });

    for (final textScale in [1.0, 1.3, 2.0]) {
      for (final reason in SpellCastBlockReason.values) {
        testWidgets('petit écran 320x568, échelle de texte $textScale, raison '
            '${reason.name} : aucun débordement, ligne entièrement visible '
            'sous le bouton', (tester) async {
          tester.view.physicalSize = const Size(320, 568);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = textScale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearAllTestValues);

          await pumpPanel(
            tester,
            spell: reason == SpellCastBlockReason.unprepared
                ? knownLevel1
                : _fireball,
            spellSlots: const [],
          );

          expect(tester.takeException(), isNull);
          expectBlocked(tester, reason.message);
          final line = tester.getRect(find.text(reason.message));
          final button = tester.getRect(
            find.widgetWithText(PrimaryButton, 'LANCER'),
          );
          expect(line.left, greaterThanOrEqualTo(0));
          expect(line.right, lessThanOrEqualTo(320));
          expect(line.top, greaterThanOrEqualTo(button.bottom));
          expect(line.bottom, lessThanOrEqualTo(568));
        });
      }
    }
  });

  // Ajouts QA (second passage) : correction `Flexible` du lien
  // "Préparer ce sort"/"Ne plus préparer" — rendu inchangé à l'échelle 1.0,
  // repli à la ligne sans débordement et lien toujours actionnable à
  // l'échelle agrandie ; zone défilante préservée quand le pied grandit.
  group('lien de bascule de préparation — correction Flexible (QA)', () {
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

    void useScreen(WidgetTester tester, Size size, double textScale) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);
    }

    for (final size in const [Size(320, 568), Size(800, 600)]) {
      for (final spell in const [knownSpell, preparedSpell]) {
        testWidgets('échelle 1.0, écran ${size.width.toInt()}x'
            '${size.height.toInt()}, "${labelOf(spell)}" : libellé sur une '
            'seule ligne à sa largeur intrinsèque, icône à 4 px à gauche et '
            'centrée, zone tactile 44 px sur toute la largeur', (tester) async {
          useScreen(tester, size, 1);
          await pumpPanel(tester, spell: spell, spellSlots: slots);
          expect(tester.takeException(), isNull);

          final label = labelOf(spell);
          final text = tester.getRect(find.text(label));
          final link = tester.getRect(linkOf(label));
          final icon = tester.getRect(
            find.descendant(of: linkOf(label), matching: find.byType(Icon)),
          );
          final scrollArea = tester.getRect(find.byType(SingleChildScrollView));

          // Largeur intrinsèque du paragraphe réellement rendu : `Flexible`
          // (fit loose) ne doit ni étirer ni contraindre le libellé tant
          // qu'il tient sur une ligne.
          final paragraph = tester.renderObject<RenderParagraph>(
            find.text(label),
          );
          expect(
            text.width,
            moreOrLessEquals(paragraph.getMaxIntrinsicWidth(double.infinity)),
          );
          expect(
            text.height,
            moreOrLessEquals(paragraph.getMinIntrinsicHeight(double.infinity)),
          );

          // Alignement : icône collée à gauche, libellé 4 px après, les
          // deux centrés verticalement dans la zone tactile.
          expect(icon.left, link.left);
          expect(icon.size, const Size(14, 14));
          expect(text.left, icon.right + 4);
          expect(icon.center.dy, moreOrLessEquals(link.center.dy));
          expect(text.center.dy, moreOrLessEquals(link.center.dy));

          // Zone tactile : 44 px de haut, toute la largeur du contenu
          // (marges latérales symétriques), pas réduite au libellé.
          expect(link.height, 44);
          expect(link.left, greaterThan(scrollArea.left));
          expect(
            link.left - scrollArea.left,
            moreOrLessEquals(scrollArea.right - link.right),
          );
          expect(text.right, lessThan(link.right));

          // Un tap à l'extrémité droite de la zone (loin du libellé)
          // déclenche bien la bascule.
          await tester.tapAt(link.centerRight - const Offset(4, 0));
          await tester.pumpAndSettle();
          expect(preparedToggleCalls, [spell]);
          expect(castCalls, isEmpty);
        });
      }
    }

    for (final textScale in [1.3, 2.0]) {
      for (final spell in const [knownSpell, preparedSpell]) {
        for (final spellSlots in const [slots, <CharacterSpellSlot>[]]) {
          testWidgets('petit écran 320x568, échelle $textScale, '
              '"${labelOf(spell)}", ${spellSlots.isEmpty ? 'avec' : 'sans'} '
              'ligne de raison possible : le libellé se replie dans la zone '
              'tactile sans débordement et reste actionnable', (tester) async {
            useScreen(tester, const Size(320, 568), textScale);
            await pumpPanel(tester, spell: spell, spellSlots: spellSlots);
            expect(tester.takeException(), isNull);

            final label = labelOf(spell);
            final text = tester.getRect(find.text(label));
            final link = tester.getRect(linkOf(label));

            // Le libellé agrandi ne tient plus sur une ligne à côté de
            // l'icône (garde-fou : l'échelle de test est réellement
            // appliquée) et il est replié sur plusieurs lignes.
            final paragraph = tester.renderObject<RenderParagraph>(
              find.text(label),
            );
            final icon = tester.getRect(
              find.descendant(of: linkOf(label), matching: find.byType(Icon)),
            );
            expect(
              paragraph.getMaxIntrinsicWidth(double.infinity),
              greaterThan(link.right - icon.right - 4),
            );
            expect(
              text.height,
              greaterThan(paragraph.getMinIntrinsicHeight(double.infinity)),
            );
            expect(text.left, icon.right + 4);

            // Contenu dans la zone tactile, elle-même dans l'écran.
            expect(text.left, greaterThanOrEqualTo(link.left));
            expect(text.right, lessThanOrEqualTo(link.right));
            expect(text.top, greaterThanOrEqualTo(link.top));
            expect(text.bottom, lessThanOrEqualTo(link.bottom));
            expect(link.height, greaterThanOrEqualTo(44));
            expect(link.left, greaterThanOrEqualTo(0));
            expect(link.right, lessThanOrEqualTo(320));

            // La zone défilante garde une hauteur utile malgré le pied
            // agrandi, et le lien y reste atteignable puis actionnable.
            expect(
              tester.getSize(find.byType(SingleChildScrollView)).height,
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

    testWidgets('petit écran 320x568, échelle 2.0, description très longue et '
        'sort bloqué : aucun débordement, pied (bouton + raison) entièrement '
        'à l\'écran, description défilable jusqu\'au bout', (tester) async {
      useScreen(tester, const Size(320, 568), 2);
      final spell = CharacterSpellEntry(
        id: 22,
        name: 'Souhait',
        level: 9,
        school: 'Invocation',
        status: 'connu',
        castingTime: '1 action',
        range: 'Personnelle',
        duration: 'Instantanée',
        description:
            '${List.filled(60, 'Texte de description.').join(' ')} FIN.',
      );
      await pumpPanel(tester, spell: spell, spellSlots: const []);
      expect(tester.takeException(), isNull);

      final message = SpellCastBlockReason.unprepared.message;
      final button = tester.getRect(
        find.widgetWithText(PrimaryButton, 'LANCER'),
      );
      final line = tester.getRect(find.text(message));
      final scrollArea = tester.getRect(find.byType(SingleChildScrollView));
      expect(scrollArea.bottom, lessThanOrEqualTo(button.top));
      expect(line.top, greaterThanOrEqualTo(button.bottom));
      expect(line.bottom, lessThanOrEqualTo(568));
      expect(line.left, greaterThanOrEqualTo(0));
      expect(line.right, lessThanOrEqualTo(320));

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -100000),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // La fin de la description est amenée dans la zone visible, au-dessus
      // du pied.
      final description = tester.getRect(find.text(spell.description));
      expect(description.bottom, lessThanOrEqualTo(scrollArea.bottom));
      expect(description.bottom, greaterThan(scrollArea.top));
    });
  });
}
