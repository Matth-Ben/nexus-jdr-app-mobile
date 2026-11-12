import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/feat_tag_badge.dart';
import 'package:personnages/core/widgets/selectable_option_tile.dart';
import 'package:personnages/features/characters/domain/feat_tag.dart';
import 'package:personnages/l10n/app_localizations.dart';

Future<void> _loadFont(String family, String path) async {
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.sublistView(File(path).readAsBytesSync())));
  await loader.load();
}

const _longTitle = "Agent de l'ordre planaire";

Future<void> _pump(
  WidgetTester tester, {
  FeatTag? tag,
  Locale locale = const Locale('fr'),
  double scale = 1,
  double width = 390,
  String title = 'Don du dragon chromatique',
  VoidCallback? onTap,
}) async {
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: SelectableOptionTile(
            title: title,
            subtitle: 'Prérequis : niveau 4 ou plus',
            selected: false,
            onTap: onTap ?? () {},
            onInfo: () {},
            titleBadge: tag == null ? null : FeatTagBadge(tag: tag),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await _loadFont('WorkSans', 'assets/fonts/WorkSans-VariableFont_wght.ttf');
    await _loadFont('PressStart2P', 'assets/fonts/PressStart2P-Regular.ttf');
  });

  testWidgets('Épopée : pastille FR', (tester) async {
    await _pump(tester, tag: FeatTag.epic);
    expect(find.text('Épopée'), findsOneWidget);
    expect(find.text('Campagne'), findsNothing);
  });

  testWidgets('Campagne : pastille FR', (tester) async {
    await _pump(tester, tag: FeatTag.campaign);
    expect(find.text('Campagne'), findsOneWidget);
    expect(find.text('Épopée'), findsNothing);
  });

  testWidgets('pastilles EN', (tester) async {
    await _pump(tester, tag: FeatTag.epic, locale: const Locale('en'));
    expect(find.text('Epic'), findsOneWidget);
    await _pump(tester, tag: FeatTag.campaign, locale: const Locale('en'));
    expect(find.text('Campaign'), findsOneWidget);
  });

  testWidgets('sans étiquette : aucune pastille', (tester) async {
    await _pump(tester);
    expect(find.byType(FeatTagBadge), findsNothing);
    expect(find.text('Épopée'), findsNothing);
    expect(find.text('Campagne'), findsNothing);
  });

  testWidgets('pastille non interactive : la tuile reste cliquable et '
      'jamais grisée', (tester) async {
    var taps = 0;
    await _pump(tester, tag: FeatTag.epic, onTap: () => taps++);
    await tester.tap(find.text('Épopée'));
    expect(taps, 1, reason: 'toucher la pastille sélectionne le don');
    final opacity = tester.widget<Opacity>(
      find.descendant(
        of: find.byType(SelectableOptionTile),
        matching: find.byType(Opacity),
      ),
    );
    expect(opacity.opacity, 1);
  });

  testWidgets('sémantique de la ligne : nom et étiquette', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, tag: FeatTag.campaign);
    final label = tester.getSemantics(find.byType(InkWell).first).label;
    expect(label, contains('Don du dragon chromatique'));
    expect(label, contains('Campagne'));
    handle.dispose();
  });

  for (final scale in [2.0, 3.0]) {
    testWidgets('x$scale sur 320 dp : aucun débordement, pastille sous le '
        'nom', (tester) async {
      for (final tag in FeatTag.values) {
        await _pump(
          tester,
          tag: tag,
          scale: scale,
          width: 320,
          title: _longTitle,
        );
        expect(tester.takeException(), isNull);
        final badge = tester.getRect(find.byType(FeatTagBadge));
        expect(badge.right, lessThanOrEqualTo(320));
        final title = tester.getRect(find.text(_longTitle));
        expect(badge.top, greaterThanOrEqualTo(title.bottom - 0.5));
      }
    });
  }
}
