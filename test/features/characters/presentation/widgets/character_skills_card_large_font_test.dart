// F21 (`docs/retours-utilisateurs.md`) : l'en-tête de la carte "LES 18
// COMPÉTENCES" (titre + légende) ne doit pas déborder avec une police
// agrandie sur un écran étroit.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/skill_bonus_calculator.dart';
import 'package:personnages/features/characters/presentation/widgets/character_skills_card.dart';
import 'package:personnages/l10n/app_localizations.dart';

void main() {
  const surfaces = <Size>[Size(360, 640), Size(320, 568), Size(320, 533)];
  const scales = <double>[1.3, 2.0];

  for (final surface in surfaces) {
    for (final scale in scales) {
      testWidgets(
        '${surface.width.toInt()}x${surface.height.toInt()} police x$scale : '
        'aucun débordement',
        (tester) async {
          tester.view.physicalSize = surface;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('fr'),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: const Scaffold(
                body: SingleChildScrollView(
                  child: CharacterSkillsCard(
                    results: [
                      SkillBonusResult(
                        skillId: 1,
                        name: 'Acrobaties',
                        abilityId: 'dex',
                        proficiency: 'competente',
                        bonus: 12,
                      ),
                      SkillBonusResult(
                        skillId: 2,
                        name: 'Escamotage',
                        abilityId: 'dex',
                        proficiency: 'aucune',
                        bonus: -1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );

          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  group('alignement du bonus (largeur minimale suivant l échelle)', () {
    setUpAll(() async {
      // Police réelle (Work Sans) : la police de test fausse les largeurs.
      final loader = FontLoader('WorkSans')
        ..addFont(
          Future.value(
            ByteData.sublistView(
              File('assets/fonts/WorkSans-VariableFont_wght.ttf')
                  .readAsBytesSync(),
            ),
          ),
        );
      await loader.load();
    });

    for (final scale in <double>[1.0, 1.3, 2.0]) {
      testWidgets('x$scale : "+2" et "+10" alignés (même largeur de colonne)', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(480, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const Scaffold(
              body: SingleChildScrollView(
                child: CharacterSkillsCard(
                  results: [
                    SkillBonusResult(
                      skillId: 1,
                      name: 'Acrobaties',
                      abilityId: 'dex',
                      proficiency: 'competente',
                      bonus: 10,
                    ),
                    SkillBonusResult(
                      skillId: 2,
                      name: 'Escamotage',
                      abilityId: 'dex',
                      proficiency: 'aucune',
                      bonus: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        final big = tester.getRect(find.text('+10'));
        final small = tester.getRect(find.text('+2'));
        // Colonne alignée : mêmes bords gauche et droit, quelle que soit la
        // largeur du texte.
        expect(small.left, moreOrLessEquals(big.left, epsilon: 0.5));
        expect(small.right, moreOrLessEquals(big.right, epsilon: 0.5));
      });
    }
  });
}
