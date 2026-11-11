// Filtres de l'onglet « Sorts » (P4) : bouton, feuille, puces récapitulatives,
// état « aucun résultat », réinitialisation, accessibilité. Aucun favori ni
// filtre rituel (décisions du 11/11/2026).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/rules/spell_status.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/character_spell_slot.dart';
import 'package:personnages/features/characters/presentation/widgets/character_spells_tab_body.dart';
import 'package:personnages/features/characters/presentation/widgets/character_spells_section.dart';
import 'package:personnages/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

CharacterSpellEntry _spell(
  int id,
  String name,
  int level,
  String school, {
  bool concentration = false,
  SpellStatus status = SpellStatus.prepared,
}) => CharacterSpellEntry(
  id: id,
  name: name,
  level: level,
  school: school,
  status: status,
  concentration: concentration,
);

final _spells = [
  _spell(1, 'Lumière', 0, 'Évocation', status: SpellStatus.known),
  _spell(2, 'Bouclier', 1, 'Abjuration'),
  _spell(3, 'Bénédiction', 1, 'Enchantement', concentration: true),
  _spell(4, 'Boule de feu', 3, 'Evocation'),
  _spell(5, 'Vol', 3, 'Transmutation', concentration: true),
  _spell(6, 'Mystère', 2, '', status: SpellStatus.known),
];

CharacterDetail _detail({String id = '1', List<CharacterSpellEntry>? spells}) =>
    CharacterDetail(
      id: id,
      name: 'Test',
      classes: const [
        CharacterDetailClassRow(
          classId: 1,
          className: 'Magicien',
          level: 5,
          isPrimary: true,
          savingThrowProficiencies: [],
          hitDie: 6,
        ),
      ],
      xp: 0,
      currentHp: 10,
      maxHp: 10,
      temporaryHp: 0,
      abilityScores: const {},
      spells: spells ?? _spells,
      spellSlots: const [
        CharacterSpellSlot(level: 1, total: 4, used: 1),
        CharacterSpellSlot(level: 3, total: 2, used: 0),
      ],
    );

Widget _app({
  required CharacterDetail detail,
  double scale = 1,
  Locale locale = const Locale('fr'),
  SpellCountAnnouncer? announcer,
}) {
  return ProviderScope(
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
          detail: detail,
          onCastSpell: (_, _) {},
          onTogglePrepared: (_) {},
          announcer: announcer,
        ),
      ),
    ),
  );
}

Future<void> _pump(
  WidgetTester tester,
  CharacterDetail detail, {
  double scale = 1,
  Locale locale = const Locale('fr'),
  SpellCountAnnouncer? announcer,
  Size size = const Size(390, 1600),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    _app(detail: detail, scale: scale, locale: locale, announcer: announcer),
  );
  await tester.pumpAndSettle();
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('spellFilterButton')));
  await tester.tap(find.byKey(const Key('spellFilterButton')));
  await tester.pumpAndSettle();
}

Future<void> _tapOption(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey('spellFilterOption-$key'));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Applique via le bouton primaire de la feuille (dernier `PrimaryButton`).
Future<void> _applySheet(WidgetTester tester) async {
  final apply = find.textContaining(RegExp('^APPLIQUER|^APPLY'));
  await tester.ensureVisible(apply);
  await tester.tap(apply);
  await tester.pumpAndSettle();
}

Future<void> _filter(
  WidgetTester tester, {
  List<String> options = const [],
}) async {
  await _openSheet(tester);
  for (final option in options) {
    await _tapOption(tester, option);
  }
  await _applySheet(tester);
}

void _expectVisible(List<String> names) {
  for (final spell in _spells) {
    expect(
      find.text(spell.name),
      names.contains(spell.name) ? findsOneWidget : findsNothing,
      reason: spell.name,
    );
  }
}

Future<void> _loadFont(String family, String path) async {
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.sublistView(File(path).readAsBytesSync())));
  await loader.load();
}

void main() {
  // Polices réelles : la police de test (chaque glyphe large d'un em) fausserait
  // les largeurs de mots, donc la vérification « aucun mot coupé ».
  setUpAll(() async {
    await _loadFont('WorkSans', 'assets/fonts/WorkSans-VariableFont_wght.ttf');
    await _loadFont('PressStart2P', 'assets/fonts/PressStart2P-Regular.ttf');
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('combinaison des critères', () {
    testWidgets('OU entre niveaux, ET entre niveau et école', (tester) async {
      await _pump(tester, _detail());
      await _filter(tester, options: ['level-1', 'level-3']);
      _expectVisible(['Bouclier', 'Bénédiction', 'Boule de feu', 'Vol']);

      await _filter(tester, options: ['school-evocation']);
      _expectVisible(['Boule de feu']);
    });

    testWidgets('école comparée sur la clé normalisée (FR et EN stockés)', (
      tester,
    ) async {
      await _pump(tester, _detail());
      await _filter(tester, options: ['school-evocation']);
      // « Évocation » (FR) et « Evocation » (EN) correspondent.
      _expectVisible(['Lumière', 'Boule de feu']);
    });

    testWidgets('OU entre écoles', (tester) async {
      await _pump(tester, _detail());
      await _filter(
        tester,
        options: ['school-abjuration', 'school-transmutation'],
      );
      _expectVisible(['Bouclier', 'Vol']);
    });

    testWidgets('concentration : Avec / Sans / Tous', (tester) async {
      await _pump(tester, _detail());
      await _filter(tester, options: ['concentration-concentration']);
      _expectVisible(['Bénédiction', 'Vol']);

      await _filter(tester, options: ['concentration-noConcentration']);
      _expectVisible(['Lumière', 'Bouclier', 'Boule de feu', 'Mystère']);

      await _filter(tester, options: ['concentration-all']);
      _expectVisible(_spells.map((s) => s.name).toList());
      expect(find.byKey(const Key('spellFilterClearAll')), findsNothing);
    });

    testWidgets('un sort sans école disparaît dès qu\'une école est filtrée', (
      tester,
    ) async {
      await _pump(tester, _detail());
      await _filter(tester, options: ['school-abjuration']);
      expect(find.text('Mystère'), findsNothing);
    });

    testWidgets('cumul avec la recherche', (tester) async {
      await _pump(tester, _detail());
      await _filter(tester, options: ['level-1', 'level-3']);
      await tester.enterText(find.byType(TextField), 'bo');
      await tester.pumpAndSettle();
      _expectVisible(['Bouclier', 'Boule de feu']);

      await tester.enterText(find.byType(TextField), 'vol');
      await tester.pumpAndSettle();
      _expectVisible(['Vol']);
    });

    testWidgets('cumul avec le filtre de préparation existant', (tester) async {
      SharedPreferences.setMockInitialValues({
        'spell_preparation_filter_preference': 'unprepared',
      });
      await _pump(tester, _detail());
      // « Non préparés » : Mystère (connu, niveau 2) ; Lumière est un sort
      // mineur (jamais « à préparer »).
      expect(find.text('Mystère'), findsOneWidget);

      await _filter(tester, options: ['level-1']);
      // ET avec le niveau 1 : plus rien, sans toucher au filtre de préparation.
      expect(find.text('Mystère'), findsNothing);
      expect(find.text('Aucun sort ne correspond à ces filtres.'), findsOne);
    });

    testWidgets('la carte Emplacements n\'est jamais filtrée', (tester) async {
      await _pump(tester, _detail());
      expect(find.byType(SpellSlotDots), findsNWidgets(2));
      await _filter(tester, options: ['level-3', 'school-evocation']);
      expect(find.byType(SpellSlotDots), findsNWidgets(2));
      expect(find.text('EMPLACEMENTS DE SORTS'), findsOneWidget);

      // Même sans aucun sort affiché.
      await _filter(tester, options: ['school-abjuration']);
      expect(find.byType(SpellSlotDots), findsNWidgets(2));
    });

    testWidgets('un bloc de niveau sans sort visible est masqué', (
      tester,
    ) async {
      await _pump(tester, _detail());
      // Avant : « Niveau 1 » = carte Emplacements + bloc du niveau 1.
      expect(find.text('Niveau 1'), findsNWidgets(2));
      await _filter(tester, options: ['level-3']);
      // Après : seule la ligne de la carte Emplacements reste ; le bloc du
      // niveau 1 a disparu (et « Sorts mineurs » aussi).
      expect(find.text('Niveau 1'), findsOneWidget);
      expect(find.text('Sorts mineurs'), findsNothing);
      expect(find.text('Niveau 3'), findsWidgets);
    });
  });

  group('feuille de filtres', () {
    testWidgets('seuls les niveaux et écoles présents sont proposés', (
      tester,
    ) async {
      final spells = [
        _spell(1, 'Bouclier', 1, 'Abjuration'),
        _spell(2, 'Boule de feu', 3, 'Evocation'),
      ];
      await _pump(tester, _detail(spells: spells));
      await _openSheet(tester);

      for (final level in [1, 3]) {
        expect(
          find.byKey(ValueKey('spellFilterOption-level-$level')),
          findsOneWidget,
        );
      }
      for (final level in [0, 2, 4, 5, 6, 7, 8, 9]) {
        expect(
          find.byKey(ValueKey('spellFilterOption-level-$level')),
          findsNothing,
        );
      }
      expect(
        find.byKey(const ValueKey('spellFilterOption-school-abjuration')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spellFilterOption-school-evocation')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spellFilterOption-school-necromancy')),
        findsNothing,
      );
      // Concentration : toujours les trois états.
      expect(find.text('Tous'), findsOneWidget);
      expect(find.text('Sans concentration'), findsOneWidget);
    });

    testWidgets('aucun filtre rituel ni favori', (tester) async {
      await _pump(tester, _detail());
      await _openSheet(tester);
      expect(
        find.textContaining(RegExp('rituel|favori', caseSensitive: false)),
        findsNothing,
      );
      expect(find.byIcon(Icons.star), findsNothing);
      expect(find.byIcon(Icons.star_border), findsNothing);
    });

    testWidgets('un tap de puce ne ferme pas la feuille ; compteur Appliquer', (
      tester,
    ) async {
      await _pump(tester, _detail());
      await _openSheet(tester);
      expect(find.text('APPLIQUER'), findsOneWidget);

      await _tapOption(tester, 'level-1');
      await _tapOption(tester, 'school-evocation');
      expect(find.text('FILTRER LES SORTS'), findsOneWidget);
      expect(find.text('APPLIQUER (2)'), findsOneWidget);
      // La sélection est signalée par une coche, pas par la couleur seule.
      expect(find.byIcon(Icons.check), findsNWidgets(2 + 1));
    });

    testWidgets('fermer sans appliquer ne change rien', (tester) async {
      await _pump(tester, _detail());
      await _openSheet(tester);
      await _tapOption(tester, 'level-1');
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      _expectVisible(_spells.map((s) => s.name).toList());
      expect(find.byKey(const Key('spellFilterClearAll')), findsNothing);
    });

    testWidgets('« Réinitialiser » désactivé sans filtre, remet tout à zéro', (
      tester,
    ) async {
      await _pump(tester, _detail());
      await _openSheet(tester);
      Opacity resetOpacity() => tester.widget<Opacity>(
        find
            .ancestor(
              of: find.text('RÉINITIALISER'),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(resetOpacity().opacity, lessThan(1));

      await _tapOption(tester, 'level-1');
      await _tapOption(tester, 'concentration-concentration');
      expect(resetOpacity().opacity, 1);
      await tester.tap(find.text('RÉINITIALISER'));
      await tester.pumpAndSettle();
      expect(find.text('APPLIQUER'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget); // « Tous » seul.
    });

    testWidgets('anglais : libellés EN, « Cantrips », École conjuration', (
      tester,
    ) async {
      final spells = [
        _spell(1, 'Light', 0, 'Evocation'),
        _spell(2, 'Find Familiar', 1, 'Invocation'),
      ];
      await _pump(tester, _detail(spells: spells), locale: const Locale('en'));
      await _openSheet(tester);
      expect(find.text('FILTER SPELLS'), findsOneWidget);
      expect(find.text('Cantrips'), findsOneWidget);
      expect(find.text('Level 1'), findsWidgets);
      expect(find.text('Evocation'), findsOneWidget);
      expect(find.text('Conjuration'), findsOneWidget);
      expect(find.text('No concentration'), findsOneWidget);
    });
  });

  group('état actif', () {
    testWidgets('compteur et puces cohérents, ✕ retire un critère', (
      tester,
    ) async {
      await _pump(tester, _detail());
      expect(find.byKey(const Key('spellFilterCountBadge')), findsNothing);
      expect(find.byKey(const Key('spellFilterClearAll')), findsNothing);

      await _filter(
        tester,
        options: [
          'level-3',
          'school-evocation',
          'concentration-noConcentration',
        ],
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('spellFilterCountBadge')),
          matching: find.text('3'),
        ),
        findsOneWidget,
      );
      for (final key in ['level-3', 'school-evocation', 'concentration']) {
        expect(find.byKey(ValueKey('spellActiveFilter-$key')), findsOneWidget);
      }
      _expectVisible(['Boule de feu']);

      await tester.tap(find.byKey(const ValueKey('spellActiveFilter-level-3')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('spellActiveFilter-level-3')),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('spellFilterCountBadge')),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
      // Évocation ET sans concentration : Lumière + Boule de feu.
      _expectVisible(['Lumière', 'Boule de feu']);
    });

    testWidgets('« Tout effacer » remet tout à zéro', (tester) async {
      await _pump(tester, _detail());
      await _filter(tester, options: ['level-1', 'school-abjuration']);
      await tester.tap(find.byKey(const Key('spellFilterClearAll')));
      await tester.pumpAndSettle();
      _expectVisible(_spells.map((s) => s.name).toList());
      expect(find.byKey(const Key('spellFilterClearAll')), findsNothing);
      expect(find.byKey(const Key('spellFilterCountBadge')), findsNothing);
    });

    testWidgets('la feuille rouverte reflète le filtre actif', (tester) async {
      await _pump(tester, _detail());
      await _filter(tester, options: ['level-1']);
      await _openSheet(tester);
      expect(find.text('APPLIQUER (1)'), findsOneWidget);
    });
  });

  group('aucun résultat', () {
    testWidgets(
      'filtres actifs : message dédié + « Réinitialiser les filtres »',
      (tester) async {
        await _pump(tester, _detail());
        await _filter(tester, options: ['school-abjuration', 'level-3']);
        expect(find.text('Aucun sort ne correspond à ces filtres.'), findsOne);
        expect(find.byType(SpellSlotDots), findsNWidgets(2));

        await tester.tap(find.text('RÉINITIALISER LES FILTRES'));
        await tester.pumpAndSettle();
        _expectVisible(_spells.map((s) => s.name).toList());
        expect(
          find.text('Aucun sort ne correspond à ces filtres.'),
          findsNothing,
        );
      },
    );

    testWidgets('recherche seule : comportement historique inchangé', (
      tester,
    ) async {
      await _pump(tester, _detail());
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('Aucun sort pour « zzz ».'), findsOneWidget);
      expect(find.text('RÉINITIALISER LES FILTRES'), findsNothing);
      expect(
        find.text('Aucun sort ne correspond à ces filtres.'),
        findsNothing,
      );
      // Le ✕ de la recherche reste.
      expect(find.byTooltip('Effacer'), findsOneWidget);
    });

    testWidgets('anglais', (tester) async {
      await _pump(tester, _detail(), locale: const Locale('en'));
      await _filter(tester, options: ['school-abjuration', 'level-3']);
      expect(find.text('No spell matches these filters.'), findsOneWidget);
      expect(find.text('RESET FILTERS'), findsOneWidget);
    });
  });

  group('portée du filtre', () {
    testWidgets('réinitialisé quand la fiche change de personnage', (
      tester,
    ) async {
      await _pump(tester, _detail(id: '1'));
      await _filter(tester, options: ['level-3']);
      _expectVisible(['Boule de feu', 'Vol']);

      await tester.pumpWidget(_app(detail: _detail(id: '2')));
      await tester.pumpAndSettle();
      _expectVisible(_spells.map((s) => s.name).toList());
      expect(find.byKey(const Key('spellFilterClearAll')), findsNothing);
    });

    testWidgets('conservé quand la même fiche est mise à jour', (tester) async {
      await _pump(tester, _detail(id: '1'));
      await _filter(tester, options: ['level-3']);
      await tester.pumpWidget(_app(detail: _detail(id: '1')));
      await tester.pumpAndSettle();
      _expectVisible(['Boule de feu', 'Vol']);
    });

    testWidgets('pas de persistance entre deux montages de l\'onglet', (
      tester,
    ) async {
      await _pump(tester, _detail());
      await _filter(tester, options: ['level-3']);
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, _detail());
      _expectVisible(_spells.map((s) => s.name).toList());
      expect(find.byKey(const Key('spellFilterClearAll')), findsNothing);
    });
  });

  group('accessibilité', () {
    testWidgets('Semantics du bouton, des puces et des ✕', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _detail());
      expect(find.bySemanticsLabel('Filtres'), findsOneWidget);

      await _openSheet(tester);
      await _tapOption(tester, 'level-1');
      expect(find.bySemanticsLabel('Niveau 1, sélectionné'), findsOneWidget);
      expect(find.bySemanticsLabel('Niveau 3'), findsOneWidget);
      await _applySheet(tester);

      expect(find.bySemanticsLabel('Filtres, 1 actif'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Retirer le filtre Niveau 1'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('annonce le nombre de sorts affichés après un changement', (
      tester,
    ) async {
      final announced = <String>[];
      await _pump(
        tester,
        _detail(),
        announcer: (_, text) => announced.add(text),
      );
      expect(announced, isEmpty);

      await _filter(tester, options: ['level-3']);
      expect(announced, ['2 sorts affichés']);

      await _filter(tester, options: ['school-abjuration']);
      expect(announced.last, 'Aucun sort affiché');

      await tester.tap(find.byKey(const Key('spellFilterClearAll')));
      await tester.pumpAndSettle();
      expect(announced.last, '6 sorts affichés');
    });

    testWidgets('cibles tactiles d\'au moins 44 dp', (tester) async {
      await _pump(tester, _detail());
      final button = tester.getSize(find.byKey(const Key('spellFilterButton')));
      expect(button.width, greaterThanOrEqualTo(48));
      expect(button.height, greaterThanOrEqualTo(48));

      await _filter(tester, options: ['level-1']);
      final chip = find.byKey(const ValueKey('spellActiveFilter-level-1'));
      expect(tester.getSize(chip).height, greaterThanOrEqualTo(44));
      final clear = find.byKey(const Key('spellFilterClearAll'));
      expect(tester.getSize(clear).height, greaterThanOrEqualTo(44));
      await _openSheet(tester);
      for (final key in [
        'level-0',
        'level-1',
        'school-abjuration',
        'concentration-all',
      ]) {
        final size = tester.getSize(
          find.byKey(ValueKey('spellFilterOption-$key')),
        );
        expect(size.height, greaterThanOrEqualTo(44), reason: key);
        expect(size.width, greaterThanOrEqualTo(44), reason: key);
      }
    });

    test('contraste du chiffre de la pastille au moins AA (4,5:1)', () {
      double luminance(Color c) => c.computeLuminance();
      final light = luminance(AppColors.parchmentCard);
      final dark = luminance(AppColors.accentTeal);
      expect((light + 0.05) / (dark + 0.05), greaterThanOrEqualTo(4.5));
    });

    testWidgets('x2,0 sur 360 dp : aucune exception, aucun mot coupé', (
      tester,
    ) async {
      final spells = [
        _spell(1, 'Un', 0, 'Abjuration'),
        _spell(2, 'Deux', 1, 'Invocation'),
        _spell(3, 'Trois', 2, 'Divination'),
        _spell(4, 'Quatre', 3, 'Enchantement'),
        _spell(5, 'Cinq', 4, 'Évocation'),
        _spell(6, 'Six', 5, 'Illusion'),
        _spell(7, 'Sept', 6, 'Nécromancie'),
        _spell(8, 'Huit', 7, 'Transmutation'),
      ];
      await _pump(
        tester,
        _detail(spells: spells),
        scale: 2,
        size: const Size(360, 1800),
      );
      // Le bouton passe sous le champ, pleine largeur.
      final fieldBottom = tester.getBottomLeft(find.byType(TextField)).dy;
      final buttonTop = tester
          .getTopLeft(find.byKey(const Key('spellFilterButton')))
          .dy;
      expect(buttonTop, greaterThanOrEqualTo(fieldBottom));

      await _openSheet(tester);
      for (final school in [
        'abjuration',
        'conjuration',
        'divination',
        'enchantment',
        'evocation',
        'illusion',
        'necromancy',
        'transmutation',
      ]) {
        await _tapOption(tester, 'school-$school');
      }
      for (final level in [0, 1, 2, 3, 4, 5, 6, 7]) {
        await _tapOption(tester, 'level-$level');
      }
      // Sur une seule ligne : hauteur voisine de celle d'un mot court.
      final short = tester.getSize(find.text('Illusion')).height;
      for (final word in ['Transmutation', 'Nécromancie', 'Enchantement']) {
        expect(tester.getSize(find.text(word)).height, short, reason: word);
      }
      expect(tester.takeException(), isNull);

      await _applySheet(tester);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('spellFilterClearAll')), findsOneWidget);
    });

    testWidgets('polices pixel jamais sous 11 px (onglet, feuille, états)', (
      tester,
    ) async {
      await _pump(tester, _detail());
      void check() {
        for (final richText in tester.widgetList<RichText>(
          find.byType(RichText),
        )) {
          final style = richText.text.style;
          if (style?.fontFamily?.contains('PressStart2P') ?? false) {
            expect(style!.fontSize, greaterThanOrEqualTo(11));
          }
        }
      }

      check();
      await _openSheet(tester);
      check();
      await _tapOption(tester, 'school-abjuration');
      await _tapOption(tester, 'level-3');
      await _applySheet(tester);
      check(); // état « aucun résultat »
    });
  });
}
