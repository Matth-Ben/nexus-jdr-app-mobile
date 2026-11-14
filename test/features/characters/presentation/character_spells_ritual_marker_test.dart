// Lot A « Rituels et chronos » : pastille « R » des sorts rituels dans
// l'onglet « Sorts » et ligne « Rituel » du panneau « Infos ». Informatifs :
// la pastille dépend du seul booléen `ritual`, aucune action n'est proposée.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/rules/spell_status.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/spell_grant_source.dart';
import 'package:personnages/features/characters/presentation/widgets/character_spells_tab_body.dart';
import 'package:personnages/features/characters/presentation/widgets/spell_info_panel.dart';
import 'package:personnages/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _rMarker = Key('spellRitualMarker');
const _cMarker = Key('spellConcentrationMarker');

const _ritual = CharacterSpellEntry(
  id: 1,
  name: 'Détection de la magie',
  level: 1,
  school: 'Divination',
  status: SpellStatus.prepared,
  castingTime: '1 action',
  ritual: true,
);
const _ritualConc = CharacterSpellEntry(
  id: 2,
  name: 'Vision',
  level: 1,
  school: 'Divination',
  status: SpellStatus.prepared,
  ritual: true,
  concentration: true,
  grantSource: SpellGrantSource.domain,
);
const _plain = CharacterSpellEntry(
  id: 3,
  name: 'Bouclier',
  level: 1,
  school: 'Abjuration',
  status: SpellStatus.prepared,
  castingTime: '1 réaction',
);

CharacterDetail _detail(List<CharacterSpellEntry> spells) => CharacterDetail(
  id: '1',
  name: 'Test',
  classes: const [
    CharacterDetailClassRow(
      classId: 3,
      className: 'Clerc',
      level: 5,
      isPrimary: true,
      savingThrowProficiencies: [],
      hitDie: 8,
    ),
  ],
  xp: 0,
  currentHp: 10,
  maxHp: 10,
  temporaryHp: 0,
  abilityScores: const {},
  spells: spells,
);

Future<void> _pump(
  WidgetTester tester,
  List<CharacterSpellEntry> spells, {
  double scale = 1,
  Size size = const Size(390, 1600),
  Locale locale = const Locale('fr'),
  bool actionsDisabled = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: CharacterSpellsTabBody(
            detail: _detail(spells),
            onCastSpell: (_, _) {},
            onTogglePrepared: (_) {},
            actionsDisabled: actionsDisabled,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _loadFont(String family, String path) async {
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.sublistView(File(path).readAsBytesSync())));
  await loader.load();
}

void main() {
  setUpAll(() async {
    await _loadFont('WorkSans', 'assets/fonts/WorkSans-VariableFont_wght.ttf');
    await _loadFont('PressStart2P', 'assets/fonts/PressStart2P-Regular.ttf');
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('pastille « R » dans la ligne', () {
    testWidgets('présente seulement pour un sort rituel, avec l\'icône', (
      tester,
    ) async {
      await _pump(tester, [_ritual, _plain]);

      expect(find.byKey(_rMarker), findsOneWidget);
      expect(
        find.descendant(of: find.byKey(_rMarker), matching: find.text('R')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(_rMarker),
          matching: find.byIcon(Icons.auto_stories),
        ),
        findsOneWidget,
      );
      final marker = tester.getRect(find.byKey(_rMarker));
      final name = tester.getRect(find.text('Détection de la magie'));
      expect((marker.center.dy - name.center.dy).abs(), lessThan(8));
    });

    testWidgets('aucune pastille pour un sort non rituel', (tester) async {
      await _pump(tester, [_plain]);
      expect(find.byKey(_rMarker), findsNothing);
    });

    testWidgets('ordre : nom, puis C, puis R, puis pastille d\'octroi', (
      tester,
    ) async {
      await _pump(tester, [_ritualConc]);

      final name = tester.getRect(find.text('Vision'));
      final c = tester.getRect(find.byKey(_cMarker));
      final r = tester.getRect(find.byKey(_rMarker));
      final grant = tester.getRect(find.text('DOMAINE'));
      // C + R + octroi + préparation : trois pastilles, donc seconde ligne.
      expect(c.top, greaterThanOrEqualTo(name.bottom - 1));
      expect(r.top, c.top);
      expect(c.right, lessThanOrEqualTo(r.left));
      expect(r.left, greaterThanOrEqualTo(c.right));
      expect(r.right, lessThanOrEqualTo(grant.left));
    });

    testWidgets('sémantique « Rituel » (FR) et « Ritual » (EN)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, [_ritual]);
      expect(find.bySemanticsLabel(RegExp('Rituel')), findsOneWidget);
      // Le nom du sort ne contient pas « Rituel » : seul le marqueur porte ce libellé.
      await _pump(tester, [_ritual], locale: const Locale('en'));
      expect(find.bySemanticsLabel(RegExp('Ritual')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('aucun tap propre : seul l\'InkWell de la ligne', (
      tester,
    ) async {
      await _pump(tester, [_ritual]);
      expect(
        find.descendant(
          of: find.byKey(_rMarker),
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );
    });

    for (final scale in [1.0, 1.25]) {
      testWidgets('x$scale sur 320 dp : rituel + C + octroi + préparation sur '
          'une ligne, nom non écrasé', (tester) async {
        const spell = CharacterSpellEntry(
          id: 9,
          name: 'Vision lointaine',
          level: 2,
          school: 'Divination',
          status: SpellStatus.prepared,
          ritual: true,
          concentration: true,
          grantSource: SpellGrantSource.domain,
        );
        await _pump(tester, [spell], scale: scale, size: const Size(320, 1600));

        expect(tester.takeException(), isNull);
        expect(find.byKey(_rMarker), findsOneWidget);
        expect(find.byKey(_cMarker), findsOneWidget);
        expect(find.text('DOMAINE'), findsOneWidget);
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text('Vision lointaine'),
        );
        expect(paragraph.didExceedMaxLines, isFalse);
        final name = tester.getRect(find.text('Vision lointaine'));
        // Le nom reste lisible (pas réduit à une fraction de sa largeur).
        expect(name.width, greaterThan(60));
        for (final key in [_rMarker, _cMarker]) {
          final r = tester.getRect(find.byKey(key));
          expect(r.right, lessThanOrEqualTo(320));
        }
      });
    }

    for (final scale in [1.3, 2.0, 3.0]) {
      testWidgets('x$scale sur 320 dp : seconde ligne, sans overflow ni '
          'ellipse', (tester) async {
        await _pump(
          tester,
          [_ritual, _ritualConc, _plain],
          scale: scale,
          size: const Size(320, 3000),
        );

        expect(tester.takeException(), isNull);
        expect(find.byKey(_rMarker), findsNWidgets(2));
        final name = tester.getRect(find.text('Détection de la magie'));
        final marker = tester.getRect(find.byKey(_rMarker).first);
        // La pastille passe sous le nom, dans l'écran.
        expect(marker.top, greaterThanOrEqualTo(name.bottom - 1));
        expect(marker.right, lessThanOrEqualTo(320));
        // « R » tient sur une seule ligne (pas coupé).
        final rText = find.descendant(
          of: find.byKey(_rMarker).first,
          matching: find.text('R'),
        );
        expect(tester.getSize(rText).height, lessThan(40));
        // Aucun texte ellipsé : le nom n'excède pas ses lignes.
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text('Détection de la magie'),
        );
        expect(paragraph.didExceedMaxLines, isFalse);
        for (final richText in tester.widgetList<RichText>(
          find.byType(RichText),
        )) {
          final style = richText.text.style;
          if (style?.fontFamily?.contains('PressStart2P') ?? false) {
            expect(style!.fontSize, greaterThanOrEqualTo(11));
          }
        }
      });
    }
  });

  group('ligne « Rituel » du panneau « Infos »', () {
    Future<void> open(
      WidgetTester tester,
      CharacterSpellEntry spell, {
      Locale locale = const Locale('fr'),
      bool actionsDisabled = false,
    }) async {
      await _pump(
        tester,
        [spell],
        locale: locale,
        actionsDisabled: actionsDisabled,
      );
      await tester.tap(find.text(spell.name));
      await tester.pumpAndSettle();
    }

    testWidgets('présente pour un rituel (FR), castingTime inchangé', (
      tester,
    ) async {
      await open(tester, _ritual);
      expect(find.text('Rituel'), findsOneWidget);
      expect(find.text("Oui · +10 min d'incantation"), findsOneWidget);
      // Le temps d'incantation reste celui de la base.
      expect(find.text('1 action'), findsOneWidget);
      expect(find.textContaining('11 min'), findsNothing);
    });

    testWidgets('valeur en gras, couleur textPrimary (pas accentTeal)', (
      tester,
    ) async {
      await open(tester, _ritual);
      final text = tester.widget<Text>(
        find.text("Oui · +10 min d'incantation"),
      );
      expect(text.style?.fontWeight, FontWeight.w700);
      expect(text.style?.color, isNot(const Color(0xFF2F7F86)));
      final concentration = tester.widget<Text>(find.text('Non').first);
      expect(text.style?.color, isNot(concentration.style?.color));
    });

    testWidgets('EN', (tester) async {
      await open(tester, _ritual, locale: const Locale('en'));
      expect(find.text('Ritual'), findsOneWidget);
      expect(find.text('Yes · +10 min casting time'), findsOneWidget);
    });

    testWidgets('absente pour un sort non rituel', (tester) async {
      await open(tester, _plain);
      expect(find.text('Rituel'), findsNothing);
      expect(find.textContaining('+10 min'), findsNothing);
    });

    testWidgets('visible en lecture seule, sans bouton ni action de rituel', (
      tester,
    ) async {
      await open(tester, _ritual, actionsDisabled: true);
      expect(find.text('Rituel'), findsOneWidget);
      expect(find.text("Oui · +10 min d'incantation"), findsOneWidget);
      expect(find.textContaining('rituel'), findsNothing);
    });

    testWidgets('aucun bouton « Lancer en rituel » même avec actions', (
      tester,
    ) async {
      await open(tester, _ritual);
      expect(find.textContaining('Lancer en rituel'), findsNothing);
    });

    testWidgets('showSpellInfoPanel readOnly : ligne présente', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showSpellInfoPanel(
                context,
                spell: _ritual,
                spellSlots: const [],
                readOnly: true,
                onCastSpell: (_, _) {},
                onTogglePrepared: (_) {},
              ),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      expect(find.text('Rituel'), findsOneWidget);
    });
  });
}
