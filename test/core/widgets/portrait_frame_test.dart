// Tests de widget de `PortraitFrame`, garant du critère d'acceptation
// `docs/cahier-des-charges/04-fonctionnalites-app-mobile.md` section 2 :
// "Un personnage sans portrait affiche une image de substitution générique
// (silhouette/icône par défaut selon la classe, à défaut une icône neutre)."
//
// Sans `classThemeColor`, l'implémentation retient l'option "icône neutre"
// (motif pointillé) ; avec `classThemeColor` (recettage direction
// artistique du 13/09), un fond uni de cette couleur remplace ce motif —
// voir `lib/core/widgets/portrait_frame.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/widgets/dashed_border_painter.dart';
import 'package:personnages/core/widgets/portrait_frame.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('sans portraitUrl, affiche une icône de substitution neutre', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap(const PortraitFrame(portraitUrl: null)));

    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets(
    'avec un portraitUrl renseigné, construit une image réseau configurée '
    'sur cette URL',
    (WidgetTester tester) async {
      const url = 'https://example.com/portrait.jpg';

      await tester.pumpWidget(_wrap(const PortraitFrame(portraitUrl: url)));

      // `Image` reste dans l'arbre de widgets même si son chargement échoue
      // ensuite (bascule interne vers `errorBuilder`) : on vérifie donc sa
      // configuration (l'URL demandée), pas le rendu final. `flutter test`
      // ne fait aucune requête réseau réelle (toute requête HTTP renvoie
      // 400, voir l'avertissement affiché par le test runner) : le
      // fallback vers l'icône de substitution (`errorBuilder`) est donc
      // attendu ici et n'est volontairement pas vérifié par ce test, pour
      // ne pas dépendre du timing exact de la résolution de l'erreur
      // réseau simulée.
      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as NetworkImage).url, url);
    },
  );

  testWidgets(
    'avec un portraitUrl inaccessible (échec réseau/décodage), replie sur '
    'l\'icône de substitution plutôt que de laisser un espace vide ou de '
    'faire planter l\'écran',
    (WidgetTester tester) async {
      const url = 'https://example.com/portrait-introuvable.jpg';

      await tester.pumpWidget(_wrap(const PortraitFrame(portraitUrl: url)));
      // `flutter test` simule un échec réseau (statut 400) pour toute
      // requête HTTP : laisser le temps aux erreurs de se propager reproduit
      // donc fidèlement le cas "portrait non encore retéléchargé" décrit en
      // section 5 du cahier des charges (`04-fonctionnalites-app-mobile.md`,
      // "Le portrait reste accessible en cache local [...] sans bloquer
      // l'affichage si l'image n'a pas encore été retéléchargée").
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    },
  );

  testWidgets('respecte la taille personnalisée passée en paramètre', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const PortraitFrame(portraitUrl: null, size: 96)),
    );

    final renderSize = tester.getSize(find.byType(PortraitFrame));
    expect(renderSize, const Size(96, 96));
  });

  group('classThemeColor (recettage direction artistique du 13/09)', () {
    testWidgets('sans portraitUrl ni classThemeColor, garde le motif pointillé '
        'neutre inchangé (comportement par défaut)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(const PortraitFrame(portraitUrl: null)));

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint && widget.painter is DashedBorderPainter,
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'sans portraitUrl, avec classThemeColor renseigné, remplace le motif '
      'pointillé par un fond uni de cette couleur avec une silhouette '
      'claire par-dessus',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _wrap(
            const PortraitFrame(
              portraitUrl: null,
              classThemeColor: AppColors.accentTeal,
            ),
          ),
        );

        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is CustomPaint && widget.painter is DashedBorderPainter,
          ),
          findsNothing,
        );
        expect(find.byIcon(Icons.person_outline), findsOneWidget);

        // `Container` bâtit lui-même un `DecoratedBox` pour la bordure
        // "cadre de portrait" (bois) : on cible ici spécifiquement celui du
        // placeholder thématique (fond uni `classThemeColor`, sans bordure)
        // pour ne pas confondre les deux.
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is DecoratedBox &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).color ==
                    AppColors.accentTeal,
          ),
          findsOneWidget,
        );

        final icon = tester.widget<Icon>(find.byIcon(Icons.person_outline));
        expect(icon.color, AppColors.textOnWood);
      },
    );

    testWidgets(
      'avec un portraitUrl défini, classThemeColor est ignoré tant que '
      "l'image reste valide (pas de fond thématique visible par-dessus)",
      (WidgetTester tester) async {
        const url = 'https://example.com/portrait.jpg';

        await tester.pumpWidget(
          _wrap(
            const PortraitFrame(
              portraitUrl: url,
              classThemeColor: AppColors.accentTeal,
            ),
          ),
        );

        // Aucun `DecoratedBox` avec le fond `classThemeColor` : seul celui
        // de la bordure "cadre de portrait" (bois) construit par `Container`
        // reste présent.
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is DecoratedBox &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).color ==
                    AppColors.accentTeal,
          ),
          findsNothing,
        );
        expect(find.byType(Image), findsOneWidget);
      },
    );
  });
}
