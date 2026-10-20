// Tests de widget de la carte personnage (liste d'accueil) — variantes
// "archivé"/"mort", voir `docs/cahier-des-charges/`
// 11-fonctionnalites-a-ajouter.md section 2 et 10-design-system.md section 4
// ("Carte personnage", variantes "archivé"/"mort").

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/widgets/dashed_border_painter.dart';
import 'package:personnages/core/widgets/portrait_frame.dart';
import 'package:personnages/core/widgets/selection_checkbox.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';
import 'package:personnages/features/characters/presentation/widgets/character_card.dart';

const _baseSummary = CharacterSummary(
  id: '1',
  name: 'Halltesse Ambrelune',
  raceName: 'Elfe',
  className: 'Magicienne',
  level: 5,
  xp: 7000,
);

Future<void> _pump(
  WidgetTester tester,
  CharacterSummary character, {
  bool selectionMode = false,
  bool selected = false,
  VoidCallback? onTap,
  VoidCallback? onLongPress,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CharacterCard(
          character: character,
          selectionMode: selectionMode,
          selected: selected,
          onTap: onTap,
          onLongPress: onLongPress,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('personnage normal : ni badge, ni bordure pointillée', (
    tester,
  ) async {
    await _pump(tester, _baseSummary);

    expect(find.text('ARCHIVÉ'), findsNothing);
    expect(find.text('MORT'), findsNothing);
    expect(find.byIcon(Icons.mood_bad), findsNothing);
  });

  testWidgets('personnage archivé : badge "ARCHIVÉ" et bordure pointillée '
      '(DashedBorderPainter)', (tester) async {
    await _pump(
      tester,
      _baseSummary.copyWith(
        isArchived: true,
        // Portrait défini : sans lui, `PortraitFrame` peint elle-même un
        // second `DashedBorderPainter` pour son placeholder "sans portrait"
        // (`core/widgets/portrait_frame.dart`), ce qui ferait échouer le
        // `findsOneWidget` ci-dessous en comptant celui de la carte elle-même
        // ET celui du portrait vide.
        portraitUrl: 'https://example.com/halltesse.jpg',
      ),
    );

    expect(find.text('ARCHIVÉ'), findsOneWidget);
    expect(find.text('MORT'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint && widget.painter is DashedBorderPainter,
      ),
      findsOneWidget,
    );
  });

  testWidgets('personnage mort : badge "MORT", icône de substitution dédiée '
      'quand aucun portrait n\'est défini', (tester) async {
    await _pump(tester, _baseSummary.copyWith(isDead: true));

    expect(find.text('MORT'), findsOneWidget);
    expect(find.text('ARCHIVÉ'), findsNothing);
    expect(find.byIcon(Icons.mood_bad), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsNothing);
  });

  testWidgets(
    'personnage mort AVEC portrait : le portrait réel reste affiché, pas '
    'l\'icône de substitution',
    (tester) async {
      await _pump(
        tester,
        _baseSummary.copyWith(
          isDead: true,
          portraitUrl: 'https://example.com/halltesse.jpg',
        ),
      );

      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.mood_bad), findsNothing);
    },
  );

  testWidgets(
    'personnage à la fois archivé et mort : les deux badges sont affichés',
    (tester) async {
      await _pump(
        tester,
        _baseSummary.copyWith(isArchived: true, isDead: true),
      );

      expect(find.text('ARCHIVÉ'), findsOneWidget);
      expect(find.text('MORT'), findsOneWidget);
    },
  );

  testWidgets('le nom et le résumé restent toujours affichés, quelle que '
      'soit la variante', (tester) async {
    await _pump(tester, _baseSummary.copyWith(isArchived: true, isDead: true));

    expect(find.text('Halltesse Ambrelune'), findsOneWidget);
    expect(find.text('Elfe · Magicienne · Niv. 5'), findsOneWidget);
  });

  group('jauge XP (masquée pour un personnage mort/archivé, demande '
      'utilisateur : la progression XP n\'a plus de sens pour un '
      'personnage qui ne joue plus)', () {
    testWidgets('personnage normal : la jauge XP est affichée', (tester) async {
      await _pump(tester, _baseSummary);

      expect(find.text('XP'), findsOneWidget);
    });

    testWidgets('personnage archivé : la jauge XP est masquée', (tester) async {
      await _pump(tester, _baseSummary.copyWith(isArchived: true));

      expect(find.text('XP'), findsNothing);
    });

    testWidgets('personnage mort : la jauge XP est masquée', (tester) async {
      await _pump(tester, _baseSummary.copyWith(isDead: true));

      expect(find.text('XP'), findsNothing);
    });

    testWidgets('personnage à la fois mort et archivé : la jauge XP est '
        'masquée', (tester) async {
      await _pump(
        tester,
        _baseSummary.copyWith(isArchived: true, isDead: true),
      );

      expect(find.text('XP'), findsNothing);
    });
  });

  group('couleur thématique du portrait selon la classe (recettage '
      'direction artistique du 13/09)', () {
    Color? portraitClassThemeColor(WidgetTester tester) {
      final frame = tester.widget<PortraitFrame>(find.byType(PortraitFrame));
      return frame.classThemeColor;
    }

    testWidgets('Magicien : accentTeal', (tester) async {
      await _pump(tester, _baseSummary.copyWith(className: 'Magicien'));

      expect(portraitClassThemeColor(tester), AppColors.accentTeal);
    });

    testWidgets('Guerrier : accentBrick', (tester) async {
      await _pump(tester, _baseSummary.copyWith(className: 'Guerrier'));

      expect(portraitClassThemeColor(tester), AppColors.accentBrick);
    });

    testWidgets('Clerc : accentBlue', (tester) async {
      await _pump(tester, _baseSummary.copyWith(className: 'Clerc'));

      expect(portraitClassThemeColor(tester), AppColors.accentBlue);
    });

    testWidgets(
      "les autres classes (ex. Roublard, Barbare, Paladin) n'ont pas de "
      'couleur thématique : le fallback pointillé neutre existant reste '
      'inchangé',
      (tester) async {
        for (final className in ['Roublard', 'Barbare', 'Paladin']) {
          await _pump(tester, _baseSummary.copyWith(className: className));

          expect(portraitClassThemeColor(tester), isNull);
        }
      },
    );

    testWidgets(
      "un personnage sans classe résolue n'a pas de couleur thématique",
      (tester) async {
        await _pump(
          tester,
          CharacterSummary(
            id: _baseSummary.id,
            name: _baseSummary.name,
            level: _baseSummary.level,
            xp: _baseSummary.xp,
          ),
        );

        expect(portraitClassThemeColor(tester), isNull);
      },
    );
  });

  group('mode sélection multiple (character_list_screen.dart)', () {
    testWidgets(
      'selectionMode: false (par défaut) : aucune case à cocher affichée',
      (tester) async {
        await _pump(tester, _baseSummary);

        expect(find.byType(SelectionCheckbox), findsNothing);
      },
    );

    testWidgets(
      'selectionMode: true : affiche la case à cocher avant le portrait, '
      'reflétant [selected]',
      (tester) async {
        await _pump(tester, _baseSummary, selectionMode: true, selected: true);

        final checkbox = tester.widget<SelectionCheckbox>(
          find.byType(SelectionCheckbox),
        );
        expect(checkbox.checked, isTrue);

        final checkboxX = tester.getTopLeft(find.byType(SelectionCheckbox)).dx;
        final portraitX = tester.getTopLeft(find.byType(PortraitFrame)).dx;
        expect(
          checkboxX,
          lessThan(portraitX),
          reason: 'la case à cocher doit précéder le portrait',
        );
      },
    );

    testWidgets(
      'selectionMode: true, selected: false : case à cocher décochée',
      (tester) async {
        await _pump(tester, _baseSummary, selectionMode: true);

        final checkbox = tester.widget<SelectionCheckbox>(
          find.byType(SelectionCheckbox),
        );
        expect(checkbox.checked, isFalse);
      },
    );

    testWidgets(
      'selected: true sur une carte normale : bordure dorée (goldEnd) au '
      'lieu de wood.medium',
      (tester) async {
        await _pump(tester, _baseSummary, selectionMode: true, selected: true);

        final container = tester
            .widgetList<Container>(find.byType(Container))
            .firstWhere(
              (c) =>
                  c.decoration is BoxDecoration &&
                  (c.decoration! as BoxDecoration).boxShadow != null,
            );
        final decoration = container.decoration! as BoxDecoration;
        final border = decoration.border! as Border;
        expect(border.top.color, AppColors.goldEnd);
      },
    );

    testWidgets(
      'selected: true sur une carte morte : bordure dorée (goldEnd) au lieu '
      'de wood.dark, fond wood.dark inchangé',
      (tester) async {
        await _pump(
          tester,
          _baseSummary.copyWith(isDead: true),
          selectionMode: true,
          selected: true,
        );

        final container = tester
            .widgetList<Container>(find.byType(Container))
            .firstWhere(
              (c) =>
                  c.decoration is BoxDecoration &&
                  (c.decoration! as BoxDecoration).boxShadow != null,
            );
        final decoration = container.decoration! as BoxDecoration;
        expect(decoration.color, AppColors.woodDark);
        final border = decoration.border! as Border;
        expect(border.top.color, AppColors.goldEnd);
      },
    );

    testWidgets('selected: true sur une carte archivée (bordure pointillée) : '
        'DashedBorderPainter.color devient goldEnd', (tester) async {
      await _pump(
        tester,
        // Portrait défini : même raison que le test "personnage archivé"
        // plus haut dans ce fichier — sans lui, `PortraitFrame` peint
        // elle-même un second `DashedBorderPainter` pour son placeholder
        // "sans portrait", ce qui ferait échouer `tester.widget` (plusieurs
        // correspondances).
        _baseSummary.copyWith(
          isArchived: true,
          portraitUrl: 'https://example.com/halltesse.jpg',
        ),
        selectionMode: true,
        selected: true,
      );

      final painter =
          tester
                  .widget<CustomPaint>(
                    find.byWidgetPredicate(
                      (widget) =>
                          widget is CustomPaint &&
                          widget.painter is DashedBorderPainter,
                    ),
                  )
                  .painter!
              as DashedBorderPainter;
      expect(painter.color, AppColors.goldEnd);
    });

    testWidgets('selected: false : les bordures restent sur leurs couleurs '
        'habituelles (pas de régression)', (tester) async {
      await _pump(tester, _baseSummary, selectionMode: true);

      final container = tester
          .widgetList<Container>(find.byType(Container))
          .firstWhere(
            (c) =>
                c.decoration is BoxDecoration &&
                (c.decoration! as BoxDecoration).boxShadow != null,
          );
      final decoration = container.decoration! as BoxDecoration;
      final border = decoration.border! as Border;
      expect(border.top.color, AppColors.woodMedium);
    });

    testWidgets('Semantics(selected: ...) seulement en mode sélection', (
      tester,
    ) async {
      await _pump(tester, _baseSummary, selectionMode: true, selected: true);

      expect(
        find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.selected == true,
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'hors mode sélection, [selected] est sans effet sémantique (toujours '
      'false en pratique côté appelant)',
      (tester) async {
        await _pump(tester, _baseSummary);

        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics && widget.properties.selected != null,
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'onLongPress est appelé au clic long, indépendamment de onTap',
      (tester) async {
        var longPressed = false;
        await _pump(
          tester,
          _baseSummary,
          onTap: () {},
          onLongPress: () => longPressed = true,
        );

        await tester.longPress(find.byType(CharacterCard));
        expect(longPressed, isTrue);
      },
    );

    testWidgets(
      'en mode sélection, l\'appelant peut brancher onLongPress sur le '
      'même callback que onTap (bascule de sélection) — ce composant ne '
      'fait aucune distinction interne entre les deux',
      (tester) async {
        var toggleCount = 0;
        await _pump(
          tester,
          _baseSummary,
          selectionMode: true,
          onTap: () => toggleCount++,
          onLongPress: () => toggleCount++,
        );

        await tester.tap(find.byType(CharacterCard));
        await tester.longPress(find.byType(CharacterCard));

        expect(toggleCount, 2);
      },
    );
  });
}
