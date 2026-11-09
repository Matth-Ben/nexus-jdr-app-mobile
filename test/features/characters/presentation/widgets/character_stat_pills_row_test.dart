// Tests de widget de la rangée "VIT. / CA / INIT. / INSP."
// (`CharacterStatPillsRow`), focalisés sur l'ajustement manuel de CA
// (`armorClassBonus`) — voir la doc de classe de
// `CharacterDetail.armorClassBonus`. Le reste du comportement de ce widget
// (vitesse non résolue, inspiration active/inactive, tap initiative) est
// déjà couvert par `character_detail_screen_test.dart`, groupe "Vitesse /
// Classe d'Armure / Inspiration".

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/presentation/widgets/character_stat_pills_row.dart';
import 'package:personnages/l10n/app_localizations.dart';

Future<void> _pump(
  WidgetTester tester, {
  required int armorClass,
  required int armorClassBonus,
  VoidCallback? onTapArmorClass,
  Locale locale = const Locale('fr'),
  int speed = 30,
}) {
  return tester.pumpWidget(
    MaterialApp(
      // `CharacterStatPillsRow` lit `AppLocalizations.of(context)!` (chantier
      // "traduction de l'app" Phase B, lot "Characters — fiche
      // (identité/statistiques)") : sans ces delegates, l'appel renverrait
      // `null` et le `!` planterait. `fr` par défaut, `en` passé
      // explicitement par le groupe "locale anglaise" plus bas.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Scaffold(
        body: CharacterStatPillsRow(
          speed: speed,
          armorClass: armorClass,
          armorClassBonus: armorClassBonus,
          // Modificateur d'initiative volontairement à 0 (`+0`) : ne
          // collide jamais avec les suffixes "+N"/"−N" testés ci-dessous
          // pour la tuile "CA" (`SignedModifierFormatter.format` appose
          // toujours un signe, y compris sur l'initiative).
          initiative: 0,
          inspiration: false,
          onTapArmorClass: onTapArmorClass,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'armorClassBonus == 0 : affiche la CA brute sans aucun suffixe signé '
    '(rendu identique à avant cet ajustement)',
    (tester) async {
      await _pump(tester, armorClass: 15, armorClassBonus: 0);

      expect(find.text('15'), findsOneWidget);
      // Seule l'initiative (+0) porte un signe ici : aucun second "+0" ne
      // doit apparaître pour la tuile "CA" (bonus nul -> pas de suffixe).
      expect(find.text('+0'), findsOneWidget);
    },
  );

  testWidgets(
    'armorClassBonus positif : affiche la CA totale (armorClass + bonus) '
    'et le suffixe "+N"',
    (tester) async {
      await _pump(tester, armorClass: 15, armorClassBonus: 2);

      // CA totale affichée comme valeur principale.
      expect(find.text('17'), findsOneWidget);
      // CA brute (15, sans le bonus) ne doit plus apparaître seule.
      expect(find.text('15'), findsNothing);
      expect(find.text('+2'), findsOneWidget);
    },
  );

  testWidgets(
    'armorClassBonus négatif : affiche la CA totale déjà réduite et le '
    'suffixe signe moins "−N" (signe Unicode, pas le trait d\'union ASCII)',
    (tester) async {
      await _pump(tester, armorClass: 15, armorClassBonus: -3);

      expect(find.text('12'), findsOneWidget);
      expect(find.text('−3'), findsOneWidget);
      expect(find.text('-3'), findsNothing);
    },
  );

  testWidgets('tap sur la tuile "CA" appelle onTapArmorClass', (tester) async {
    var tapped = false;
    await _pump(
      tester,
      armorClass: 15,
      armorClassBonus: 1,
      onTapArmorClass: () => tapped = true,
    );

    await tester.tap(find.text('CA'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets(
    'onTapArmorClass == null (vue en lecture seule) : la tuile "CA" reste '
    'affichée sans effet de tap',
    (tester) async {
      await _pump(tester, armorClass: 15, armorClassBonus: 1);

      expect(find.text('CA'), findsOneWidget);
      // Pas d'assertion sur le tap : l'absence de callback ne doit
      // simplement pas lever d'exception.
      await tester.tap(find.text('CA'));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('vitesse de 25 pieds -> "7,5 m" en français (virgule décimale)', (
    tester,
  ) async {
    await _pump(tester, armorClass: 12, armorClassBonus: 0, speed: 25);
    expect(find.text('7,5 m'), findsOneWidget);
  });

  testWidgets('vitesse de 25 pieds -> "7.5 m" en anglais', (tester) async {
    await _pump(
      tester,
      armorClass: 12,
      armorClassBonus: 0,
      speed: 25,
      locale: const Locale('en'),
    );
    expect(find.text('7.5 m'), findsOneWidget);
  });

  group('locale anglaise', () {
    // Même rationale que `character_card_test.dart` (chantier "traduction
    // de l'app" Phase B) : vérifie qu'un texte anglais s'affiche réellement.
    testWidgets(
      'libellés des 4 tuiles ("SPD."/"AC"/"INIT."/"INSP.") en anglais',
      (tester) async {
        await _pump(
          tester,
          armorClass: 15,
          armorClassBonus: 0,
          locale: const Locale('en'),
        );

        expect(find.text('SPD.'), findsOneWidget);
        expect(find.text('AC'), findsOneWidget);
        expect(find.text('INIT.'), findsOneWidget);
        expect(find.text('INSP.'), findsOneWidget);
        // Vitesse stockée en pieds (30), affichée en mètres (9) dans les deux
        // langues (voir `SpeedConverter`).
        expect(find.text('9 m'), findsOneWidget);
      },
    );
  });
}
