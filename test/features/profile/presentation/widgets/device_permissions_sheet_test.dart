// Tests de widget de la sheet "Gestion des autorisations appareil"
// (`presentation/widgets/device_permissions_sheet.dart`) — sheet 100%
// statique (aucun appel réseau/état de chargement) : affichage du texte
// explicatif, tap "Ouvrir les réglages" déclenche `AppSettings
// .openAppSettings()` (canal de méthode natif `com.spencerccf.app_settings/
// methods`, mocké ici — même principe que `export_data_sheet_test.dart` pour
// `share_plus`), et la sheet reste librement fermable (contrairement aux
// sheets réseau de ce dossier).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/core/widgets/sheet_header_bar.dart';
import 'package:personnages/features/profile/presentation/widgets/device_permissions_sheet.dart';

Future<List<MethodCall>> _pumpSheet(WidgetTester tester) async {
  final calls = <MethodCall>[];
  const channel = MethodChannel('com.spencerccf.app_settings/methods');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return null;
      });

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showDevicePermissionsSheet(context),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
  return calls;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('affiche le titre et le texte explicatif', (tester) async {
    await _pumpSheet(tester);

    expect(find.text('GESTION DES AUTORISATIONS APPAREIL'), findsOneWidget);
    expect(
      find.textContaining("l'appareil photo et la galerie"),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(PrimaryButton, 'OUVRIR LES RÉGLAGES'),
      findsOneWidget,
    );
  });

  testWidgets('"Ouvrir les réglages" appelle `AppSettings.openAppSettings`', (
    tester,
  ) async {
    final calls = await _pumpSheet(tester);

    await tester.tap(find.widgetWithText(PrimaryButton, 'OUVRIR LES RÉGLAGES'));
    await tester.pumpAndSettle();

    expect(calls, hasLength(1));
    expect(calls.single.method, 'openSettings');
  });

  testWidgets('librement fermable (X, sans état à protéger)', (tester) async {
    await _pumpSheet(tester);

    await tester.tapAt(const Offset(400, 10));
    await tester.pumpAndSettle();

    expect(find.text('GESTION DES AUTORISATIONS APPAREIL'), findsNothing);
  });

  for (final (description, systemPadding) in [
    ('sans marge système', FakeViewPadding.zero),
    (
      'avec marges système (barre d\'état, barre de navigation à 3 boutons)',
      const FakeViewPadding(top: 24, bottom: 48),
    ),
  ]) {
    testWidgets('texte agrandi à 200 % sur petit écran (320×568), '
        '$description : pas de débordement, "Ouvrir les réglages" reste '
        'atteignable par défilement et actionnable', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = systemPadding;
      tester.view.viewPadding = systemPadding;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final visibleBottom = 568 - systemPadding.bottom;

      // Tout débordement lèverait une exception, qui ferait échouer ce test.
      final calls = await _pumpSheet(tester);

      // La barre de tête a grandi avec son titre et reste entière à l'écran.
      final header = tester.getRect(find.byType(SheetHeaderBar));
      expect(header.height, greaterThan(56));
      expect(header.top, greaterThanOrEqualTo(0));

      // Le corps ne tient plus sous la barre : le bouton est d'abord hors de
      // l'écran (avec la police de test, plus large que Work Sans, le corps
      // dépasse nettement), puis ramené à l'écran par défilement.
      final button = find.widgetWithText(PrimaryButton, 'OUVRIR LES RÉGLAGES');
      expect(tester.getRect(button).bottom, greaterThan(visibleBottom));

      await tester.scrollUntilVisible(
        button,
        100,
        scrollable: find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();

      final visibleButton = tester.getRect(button);
      expect(visibleButton.top, greaterThanOrEqualTo(header.bottom));
      expect(visibleButton.bottom, lessThanOrEqualTo(visibleBottom));
      // La barre de tête ne défile pas avec le corps.
      expect(tester.getRect(find.byType(SheetHeaderBar)), header);

      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(calls, hasLength(1));
      expect(calls.single.method, 'openSettings');
    });
  }
}
