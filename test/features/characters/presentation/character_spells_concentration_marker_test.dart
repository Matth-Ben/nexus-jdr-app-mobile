// P3a : marqueur « C » des sorts à concentration dans l'onglet « Sorts » et
// encadré d'aide du panneau « Infos ». Informatif : le marqueur dépend du seul
// booléen `concentration` (jamais du texte de la durée).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/rules/spell_status.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/spell_grant_source.dart';
import 'package:personnages/features/characters/presentation/widgets/character_spells_tab_body.dart';
import 'package:personnages/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _marker = Key('spellConcentrationMarker');
const _hint = Key('spellConcentrationHint');

const _frHint =
    'Dégâts subis : jet de Constitution, DD 10 ou moitié des dégâts '
    '(le plus haut). Un jet par source.';
const _enHint =
    'When damaged: Constitution save, DC 10 or half the damage (higher). '
    'One save per source.';

// Durée « concentration » mais booléen faux : pas de marqueur.
const _dispel = CharacterSpellEntry(
  id: 1,
  name: 'Alarme',
  level: 1,
  school: 'Abjuration',
  status: SpellStatus.prepared,
  duration: "Jusqu'à dissipation",
  concentration: false,
);
// Durée « instantanée » mais booléen vrai : marqueur (le champ fait foi).
const _blessing = CharacterSpellEntry(
  id: 2,
  name: 'Bénédiction',
  level: 1,
  school: 'Enchantement',
  status: SpellStatus.prepared,
  duration: 'Instantanée',
  concentration: true,
);
const _grantedConc = CharacterSpellEntry(
  id: 3,
  name: 'Sanctuaire',
  level: 1,
  school: 'Abjuration',
  status: SpellStatus.prepared,
  concentration: true,
  grantSource: SpellGrantSource.domain,
);
const _plain = CharacterSpellEntry(
  id: 4,
  name: 'Bouclier',
  level: 1,
  school: 'Abjuration',
  status: SpellStatus.prepared,
);

CharacterDetail _detail(List<CharacterSpellEntry> spells) => CharacterDetail(
  id: '1',
  name: 'Test',
  classes: const [
    CharacterDetailClassRow(
      classId: 1,
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

  group('marqueur « C » dans la ligne', () {
    testWidgets('affiché pour concentration == true, jamais selon la durée', (
      tester,
    ) async {
      await _pump(tester, [_dispel, _blessing, _plain]);

      // Un seul marqueur : celui de « Bénédiction » (durée instantanée).
      expect(find.byKey(_marker), findsOneWidget);
      final markerRect = tester.getRect(find.byKey(_marker));
      final blessingRect = tester.getRect(find.text('Bénédiction'));
      expect(
        (markerRect.center.dy - blessingRect.center.dy).abs(),
        lessThan(8),
      );
      expect(
        find.descendant(of: find.byKey(_marker), matching: find.text('C')),
        findsOneWidget,
      );
    });

    testWidgets('libellé accessible « Concentration », pas de zone de tap '
        'propre', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, [_blessing]);

      expect(find.bySemanticsLabel(RegExp('Concentration')), findsOneWidget);
      expect(
        find.ancestor(of: find.byKey(_marker), matching: find.byType(InkWell)),
        findsOneWidget, // seul l'InkWell de la ligne entière
      );
      expect(
        find.descendant(
          of: find.byKey(_marker),
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );
      handle.dispose();
    });

    testWidgets('ordre : après le nom, avant la pastille d\'octroi', (
      tester,
    ) async {
      await _pump(tester, [_grantedConc]);

      final name = tester.getRect(find.text('Sanctuaire'));
      final marker = tester.getRect(find.byKey(_marker));
      final grant = tester.getRect(find.text('DOMAINE'));
      expect(marker.left, greaterThan(name.left));
      expect(marker.right, lessThanOrEqualTo(grant.left));
    });

    testWidgets('x2,0 sur 360 dp : seconde ligne, aucune exception, mot '
        'entier, polices pixel >= 11 px', (tester) async {
      await _pump(
        tester,
        [_grantedConc, _blessing, _plain],
        scale: 2,
        size: const Size(360, 1800),
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(_marker), findsNWidgets(2));
      final name = tester.getRect(find.text('Bénédiction'));
      final markers = tester.widgetList(find.byKey(_marker)).length;
      expect(markers, 2);
      // Le marqueur de « Bénédiction » passe sous le nom.
      final blessingMarker = tester.getRect(find.byKey(_marker).at(1));
      expect(blessingMarker.top, greaterThanOrEqualTo(name.bottom - 1));
      // « C » tient sur une seule ligne et dans l'écran.
      expect(blessingMarker.right, lessThanOrEqualTo(360));
      for (final richText in tester.widgetList<RichText>(
        find.byType(RichText),
      )) {
        final style = richText.text.style;
        if (style?.fontFamily?.contains('PressStart2P') ?? false) {
          expect(style!.fontSize, greaterThanOrEqualTo(11));
        }
      }
      // Pastille d'octroi non coupée en plein mot (une seule ligne).
      final short = tester.getSize(find.text('C').first).height;
      expect(tester.getSize(find.text('DOMAINE')).height, short);
    });
  });

  group('encadré du panneau « Infos »', () {
    Future<void> open(
      WidgetTester tester,
      CharacterSpellEntry spell, {
      Locale locale = const Locale('fr'),
    }) async {
      await _pump(tester, [spell], locale: locale);
      await tester.tap(find.text(spell.name));
      await tester.pumpAndSettle();
    }

    testWidgets('présent pour un sort à concentration (texte FR exact)', (
      tester,
    ) async {
      await open(tester, _blessing);
      expect(find.byKey(_hint), findsOneWidget);
      expect(find.text(_frHint), findsOneWidget);
    });

    testWidgets('texte EN exact', (tester) async {
      await open(tester, _blessing, locale: const Locale('en'));
      expect(find.text(_enHint), findsOneWidget);
    });

    testWidgets('absent pour un sort sans concentration, même « jusqu\'à '
        'dissipation »', (tester) async {
      await open(tester, _dispel);
      expect(find.byKey(_hint), findsNothing);
      expect(find.text(_frHint), findsNothing);
    });
  });
}
