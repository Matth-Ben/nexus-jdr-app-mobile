// Tests de widget de la ligne PV / CA de `CharacterCard` (P18) : états de la
// spec (en jeu, 0 PV, mort, archivé, valeurs nulles de l'ancien cache),
// sémantique, 320 dp à ×2,0 sans exception ni troncature.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/zero_hp_indicator.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';
import 'package:personnages/features/characters/presentation/widgets/character_card.dart';
import 'package:personnages/l10n/app_localizations.dart';

Future<void> _loadFont(String family, String path) async {
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.sublistView(File(path).readAsBytesSync())));
  await loader.load();
}

Future<void> _pump(
  WidgetTester tester,
  CharacterSummary character, {
  Locale locale = const Locale('fr'),
  double textScale = 1,
  Size? size,
}) async {
  if (size != null) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(child: CharacterCard(character: character)),
      ),
    ),
  );
  await tester.pump();
}

const _base = CharacterSummary(
  id: '1',
  name: 'Halltesse Ambrelune',
  raceName: 'Elfe',
  className: 'Magicien',
  level: 5,
  xp: 7000,
  currentHp: 12,
  maxHp: 20,
  armorClass: 15,
);

Finder _hpIcon() => find.byIcon(Icons.favorite_border);
Finder _acIcon() => find.byIcon(Icons.shield_outlined);

void main() {
  setUpAll(() async {
    await _loadFont('WorkSans', 'assets/fonts/WorkSans-VariableFont_wght.ttf');
    await _loadFont('PressStart2P', 'assets/fonts/PressStart2P-Regular.ttf');
  });

  group('en jeu', () {
    testWidgets('PV > 0 : « PV 12/20 » et « CA 15 », sans indicateur à 0 PV', (
      tester,
    ) async {
      await _pump(tester, _base);
      expect(find.text('PV 12/20'), findsOneWidget);
      expect(find.text('CA 15'), findsOneWidget);
      expect(find.byType(ZeroHpIndicator), findsNothing);
      expect(_hpIcon(), findsOneWidget);
      expect(_acIcon(), findsOneWidget);
    });

    testWidgets('en anglais : « HP 12/20 » et « AC 15 »', (tester) async {
      await _pump(tester, _base, locale: const Locale('en'));
      expect(find.text('HP 12/20'), findsOneWidget);
      expect(find.text('AC 15'), findsOneWidget);
    });

    testWidgets(
      '0 PV (pas mort) : indicateur « À 0 PV » + CA, jamais « 0/20 »',
      (tester) async {
        await _pump(tester, _base.copyWith(currentHp: 0));
        expect(find.byType(ZeroHpIndicator), findsOneWidget);
        expect(find.text('À 0 PV'), findsOneWidget);
        expect(find.text('CA 15'), findsOneWidget);
        expect(find.textContaining('0/20'), findsNothing);
        expect(find.text('Inconscient'), findsNothing);
      },
    );

    testWidgets('la ligne est entre le résumé et la jauge XP', (tester) async {
      await _pump(tester, _base);
      final summaryY = tester
          .getTopLeft(find.text('Elfe · Magicien · Niv. 5'))
          .dy;
      final vitalsY = tester.getTopLeft(find.text('PV 12/20')).dy;
      final xpY = tester.getTopLeft(find.text('XP')).dy;
      expect(vitalsY, greaterThan(summaryY));
      expect(xpY, greaterThan(vitalsY));
    });
  });

  group('mort ou archivé : ligne masquée', () {
    testWidgets('mort', (tester) async {
      await _pump(tester, _base.copyWith(isDead: true));
      expect(find.text('PV 12/20'), findsNothing);
      expect(find.text('CA 15'), findsNothing);
      expect(_hpIcon(), findsNothing);
      expect(_acIcon(), findsNothing);
    });

    testWidgets('mort à 0 PV : pas d\'indicateur', (tester) async {
      await _pump(tester, _base.copyWith(isDead: true, currentHp: 0));
      expect(find.byType(ZeroHpIndicator), findsNothing);
    });

    testWidgets('archivé', (tester) async {
      await _pump(tester, _base.copyWith(isArchived: true));
      expect(find.text('PV 12/20'), findsNothing);
      expect(find.text('CA 15'), findsNothing);
      expect(find.text('ARCHIVÉ'), findsOneWidget);
    });
  });

  group('valeurs nulles (ancien cache)', () {
    testWidgets('trois nulles : aucune ligne, jamais « 0/0 »', (tester) async {
      await _pump(
        tester,
        const CharacterSummary(id: '1', name: 'Vieux cache', level: 1, xp: 0),
      );
      expect(_hpIcon(), findsNothing);
      expect(_acIcon(), findsNothing);
      expect(find.textContaining('0/0'), findsNothing);
      expect(find.textContaining('PV'), findsNothing);
      expect(find.textContaining('CA'), findsNothing);
    });

    testWidgets('PV seuls : pas de CA', (tester) async {
      await _pump(tester, _base.copyWith(armorClass: null));
      expect(find.text('PV 12/20'), findsOneWidget);
      expect(_acIcon(), findsNothing);
    });

    testWidgets('CA seule : pas de PV', (tester) async {
      await _pump(tester, _base.copyWith(currentHp: null, maxHp: null));
      expect(find.text('CA 15'), findsOneWidget);
      expect(_hpIcon(), findsNothing);
      expect(find.byType(ZeroHpIndicator), findsNothing);
    });

    testWidgets('PV max seul (courant nul) : jamais de « PV x/y » partiel', (
      tester,
    ) async {
      await _pump(tester, _base.copyWith(currentHp: null));
      expect(_hpIcon(), findsNothing);
      expect(find.textContaining('PV'), findsNothing);
    });
  });

  group('sémantique', () {
    // La carte est un `InkWell` : ses descendants sont fusionnés en un seul
    // nœud, dont le libellé concatène celui de chaque élément.
    Finder label(String text) => find.bySemanticsLabel(RegExp(text));

    testWidgets('un libellé par élément, texte visible exclu', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _base);
      expect(label('Points de vie : 12 sur 20'), findsOneWidget);
      expect(label("Classe d'armure : 15"), findsOneWidget);
      expect(label(r'PV 12/20'), findsNothing);
      handle.dispose();
    });

    testWidgets('0 PV : « À 0 points de vie sur 20 »', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _base.copyWith(currentHp: 0));
      expect(label('À 0 points de vie sur 20'), findsOneWidget);
      expect(label('Points de vie : 0 sur 20'), findsNothing);
      handle.dispose();
    });

    testWidgets('en anglais', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _base, locale: const Locale('en'));
      expect(label('Hit points: 12 of 20'), findsOneWidget);
      expect(label('Armor class: 15'), findsOneWidget);
      handle.dispose();
    });
  });

  group('320 dp, police ×2,0', () {
    for (final locale in const [Locale('fr'), Locale('en')]) {
      for (final hp in [12, 0]) {
        testWidgets('${locale.languageCode}, PV $hp : ni exception ni '
            'troncature', (tester) async {
          await _pump(
            tester,
            _base.copyWith(currentHp: hp, maxHp: 120, armorClass: 18),
            locale: locale,
            textScale: 2,
            size: const Size(320, 900),
          );
          expect(tester.takeException(), isNull);
          final texts = tester.widgetList<Text>(
            find.descendant(
              of: find.byType(CharacterCard),
              matching: find.byType(Text),
            ),
          );
          for (final text in texts) {
            expect(text.overflow, isNull, reason: text.data);
            expect(text.maxLines, isNull, reason: text.data);
          }
          // Chaque élément reste entièrement dans la largeur de l'écran.
          final ac = locale.languageCode == 'fr' ? 'CA 18' : 'AC 18';
          expect(find.text(ac), findsOneWidget);
          final right = tester.getTopRight(find.text(ac)).dx;
          expect(right, lessThanOrEqualTo(320));
          if (hp > 0) {
            final label = locale.languageCode == 'fr'
                ? 'PV 12/120'
                : 'HP 12/120';
            expect(
              tester.getTopRight(find.text(label)).dx,
              lessThanOrEqualTo(320),
            );
          }
        });
      }
    }
  });
}
