// Tests de widget de l'écran "Crédits & licences"
// (`presentation/profile_credits_screen.dart`) — bandeau bois "CRÉDITS &
// LICENCES" + retour, 3 sections `LegalSectionBlock` ("Contenu de jeu"/
// "Polices"/"Bibliothèques open source"), deux cadres d'attribution du SRD
// (5.1 puis 5.2, fond `parchmentCardAlt`, bordure `woodLight`) sous le
// paragraphe d'introduction de "Contenu de jeu", pied de page "Dernière mise
// à jour" (licence étape 1, décision 79, spec
// `docs/licence/spec-credits-nexus.md`).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/theme/app_spacing.dart';
import 'package:personnages/core/widgets/legal_section_block.dart';
import 'package:personnages/features/profile/presentation/profile_credits_screen.dart';
import 'package:personnages/l10n/app_localizations.dart';

import '../../../core/widgets/display_scale_helpers.dart';

// Déclarations d'attribution officielles de Wizards, recopiées mot pour mot
// du contrat DeepCore `docs/api-v1/contrat-bestiaire-catalogue.md` (SRD 5.1
// français l. 108-111, SRD 5.1 anglais l. 115-117, SRD 5.2 anglais
// l. 141-143), sans le `> ` de citation ni les sauts de ligne de mise en
// page. Jamais recopiées depuis les .arb : le test perdrait son sens.
const _srd51AttributionFr =
    'Ce travail comprend la documentation tirée du Document de Référence du '
    'Système 5.1 (« SRD 5.1 ») par Wizards of the Coast LLC et disponible à '
    "l'adresse "
    'https://dnd.wizards.com/fr/resources/systems-reference-document. Le SRD '
    '5.1 est distribué en vertu de la licence Creative Commons Attribution '
    "4.0 International disponible à l'adresse "
    'https://creativecommons.org/licenses/by/4.0/legalcode.fr.';
const _srd51AttributionEn =
    'This work includes material taken from the System Reference Document 5.1 '
    '(“SRD 5.1”) by Wizards of the Coast LLC and available at '
    'https://dnd.wizards.com/resources/systems-reference-document. The SRD '
    '5.1 is licensed under the Creative Commons Attribution 4.0 International '
    'License available at '
    'https://creativecommons.org/licenses/by/4.0/legalcode.';
const _srd52AttributionEn =
    'This work includes material from the System Reference Document 5.2 (“SRD '
    '5.2”) by Wizards of the Coast LLC, available at '
    'https://www.dndbeyond.com/srd. The SRD 5.2 is licensed under the '
    'Creative Commons Attribution 4.0 International License, available at '
    'https://creativecommons.org/licenses/by/4.0/legalcode.';

/// Cadres d'attribution : `DecoratedBox` au fond `parchmentCardAlt`.
final _attributionBoxes = find.byWidgetPredicate(
  (widget) =>
      widget is DecoratedBox &&
      widget.decoration is BoxDecoration &&
      (widget.decoration as BoxDecoration).color == AppColors.parchmentCardAlt,
);

/// Texte complet de chaque `RichText` affiché (ce que voit l'utilisateur).
List<String> _renderedTexts(WidgetTester tester) => [
  for (final element in find.byType(RichText).evaluate())
    (element.widget as RichText).text.toPlainText(),
];

Future<void> _pumpScreen(
  WidgetTester tester, {
  Locale locale = const Locale('fr'),
}) async {
  await tester.pumpWidget(
    MaterialApp.router(
      // `ProfileCreditsScreen` lit `AppLocalizations.of(context)!` (chantier
      // "traduction de l'app" Phase B) — sans ces delegates, l'appel
      // renverrait `null` et le `!` planterait. `locale` fixé en dur (jamais
      // `null`, qui suivrait la langue réelle, non garantie, de
      // l'environnement `flutter test`) — `fr` par défaut, `en` passé
      // explicitement par les tests du groupe "locale anglaise" ci-dessous.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => context.push('/profile/help/credits'),
                  child: const Text('Ouvrir'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/profile/help/credits',
            builder: (context, state) => const ProfileCreditsScreen(),
          ),
        ],
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('affiche le bandeau bois "CRÉDITS & LICENCES"', (tester) async {
    await _pumpScreen(tester);

    expect(find.text('CRÉDITS & LICENCES'), findsOneWidget);
  });

  testWidgets('affiche les 3 sections "Contenu de jeu"/"Polices"/'
      '"Bibliothèques open source"', (tester) async {
    await _pumpScreen(tester);

    expect(find.text('Contenu de jeu'), findsOneWidget);
    expect(find.text('Polices'), findsOneWidget);
    expect(find.text('Bibliothèques open source'), findsOneWidget);
    expect(find.byType(LegalSectionBlock), findsNWidgets(3));
  });

  testWidgets('affiche le contenu exact validé (marques Wizards of the Coast, '
      'liste des bibliothèques, phrase de clôture)', (tester) async {
    await _pumpScreen(tester);

    // Texte PROVISOIRE (arbitrage 3.4 de la spec), à valider par Matthias.
    expect(
      find.text(
        'Donjons & Dragons et D&D sont des marques de Wizards of the Coast '
        "LLC. Nexus JDR n'est ni affilié à Wizards of the Coast, ni approuvé "
        'par cette société.',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('Flutter · Riverpod · Supabase Flutter'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Ainsi que les autres bibliothèques listées dans le fichier '
        "pubspec.yaml du projet, chacune sous sa licence open source "
        "d'origine.",
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'affiche la section "Polices" (SIL OFL, polices embarquées, plus de '
    'mention de google_fonts dans la liste des bibliothèques)',
    (tester) async {
      await _pumpScreen(tester);

      expect(find.textContaining('Press Start 2P'), findsOneWidget);
      expect(find.textContaining('SIL Open Font License'), findsOneWidget);
      expect(find.textContaining('github.com/google/fonts'), findsOneWidget);
      expect(find.textContaining('google_fonts'), findsNothing);
    },
  );

  testWidgets('affiche deux cadres d\'attribution (SRD 5.1 puis SRD 5.2, fond '
      'parchmentCardAlt, bordure woodLight, même largeur), sans cadre '
      'SRD 5.2.1, entre l\'introduction et le paragraphe hors SRD', (
    tester,
  ) async {
    await _pumpScreen(tester);

    expect(_attributionBoxes, findsNWidgets(2));
    for (final element in _attributionBoxes.evaluate()) {
      final decoration =
          (element.widget as DecoratedBox).decoration as BoxDecoration;
      expect(decoration.border?.top.color, AppColors.woodLight);
      expect(decoration.border?.top.width, AppBorders.cardEmphasisHalo);
      expect(decoration.borderRadius, BorderRadius.circular(AppRadius.md));
    }
    final firstBox = tester.getRect(_attributionBoxes.at(0));
    final secondBox = tester.getRect(_attributionBoxes.at(1));
    expect(firstBox.width, secondBox.width);
    expect(firstBox.bottom, lessThan(secondBox.top));

    // Libellés : SRD 5.1 dans le premier cadre, SRD 5.2 dans le second.
    expect(
      find.descendant(
        of: _attributionBoxes.at(0),
        matching: find.text('SRD 5.1 (règles 2014)'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: _attributionBoxes.at(1),
        matching: find.text('SRD 5.2 (règles 2024, déclaration en anglais)'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('5.2.1'), findsNothing);

    // Ordre : introduction, cadres, contenu hors SRD, phrase de marque.
    final intro = tester.getRect(
      find.textContaining('Une partie du contenu de règles utilisé'),
    );
    final nonSrd = tester.getRect(
      find.textContaining('ne fait pas partie du SRD'),
    );
    final brand = tester.getRect(
      find.textContaining('sont des marques de Wizards'),
    );
    expect(intro.bottom, lessThan(firstBox.top));
    expect(secondBox.bottom, lessThan(nonSrd.top));
    expect(nonSrd.bottom, lessThan(brand.top));
  });

  testWidgets('chaque cadre affiche sa ligne « Modifié » (préfixe en gras, '
      'textSecondary, jamais textMuted)', (tester) async {
    await _pumpScreen(tester);

    final modifiedLines = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.textSpan != null &&
          widget.textSpan!.toPlainText().startsWith('Modifié\u00a0: '),
    );
    expect(modifiedLines, findsNWidgets(2));
    expect(
      find.text(
        'Modifié\u00a0: textes repris en tout ou en partie du SRD 5.1 '
        'français, ou traduits du SRD 5.1 anglais (traduction non officielle) '
        'et parfois résumés ; certains noms diffèrent de la traduction '
        'officielle ; poids et distances exprimés en kilogrammes et en '
        'mètres ; contenu réparti en champs et présentation adaptée à '
        "l'application.",
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        "Modifié\u00a0: traduit de l'anglais en français (traduction non "
        'officielle), parfois résumé ; distances et poids convertis en mètres '
        'et en kilogrammes ; contenu réparti en champs et présentation '
        "adaptée à l'application.",
      ),
      findsOneWidget,
    );
    final modifiedSpan =
        tester.widget<Text>(modifiedLines.first).textSpan! as TextSpan;
    final prefix = modifiedSpan.children!.first as TextSpan;
    expect(prefix.style?.fontWeight, FontWeight.w700);
    expect(prefix.style?.color, AppColors.textSecondary);

    // Aucun texte des cadres en `textMuted` (contraste insuffisant sur
    // `parchmentCardAlt`), style racine résolu compris.
    void expectNeverMuted(InlineSpan span) {
      expect(span.style?.color, isNot(AppColors.textMuted));
      if (span is TextSpan) {
        for (final child in span.children ?? const <InlineSpan>[]) {
          expectNeverMuted(child);
        }
      }
    }

    for (var i = 0; i < 2; i++) {
      final texts = find.descendant(
        of: _attributionBoxes.at(i),
        matching: find.byType(RichText),
      );
      expect(texts, findsNWidgets(3));
      for (final element in texts.evaluate()) {
        expectNeverMuted((element.widget as RichText).text);
      }
    }
  });

  testWidgets('affiche le paragraphe sur le contenu hors SRD (texte '
      'PROVISOIRE) au style des paragraphes de LegalSectionBlock', (
    tester,
  ) async {
    await _pumpScreen(tester);

    const nonSrd =
        'Une partie du contenu de jeu de Nexus JDR ne fait pas partie du SRD '
        '(notamment de nombreux sorts, sous-classes, dons, historiques, races '
        "et options de classe). Ce contenu n'est pas couvert par la licence "
        'Creative Commons Attribution 4.0 citée ci-dessus.';
    expect(find.text(nonSrd), findsOneWidget);
    final style = tester.widget<Text>(find.text(nonSrd)).style;
    expect(style?.fontSize, 13);
    expect(style?.color, AppColors.textPrimary);
  });

  for (final locale in const [Locale('fr'), Locale('en')]) {
    testWidgets(
      'aucune mention d\'Open5e à l\'écran (${locale.languageCode})',
      (tester) async {
        await _pumpScreen(tester, locale: locale);

        final texts = _renderedTexts(tester);
        expect(texts, isNotEmpty);
        for (final text in texts) {
          expect(text.toLowerCase(), isNot(contains('open5e')));
        }
      },
    );
  }

  test('aucune mention d\'Open5e dans les .arb (insensible à la casse)', () {
    final arbFiles = Directory('lib/l10n')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.arb'))
        .toList();
    expect(arbFiles, hasLength(greaterThanOrEqualTo(2)));
    for (final file in arbFiles) {
      expect(
        file.readAsStringSync().toLowerCase(),
        isNot(contains('open5e')),
        reason: file.path,
      );
    }
  });

  testWidgets('affiche le pied de page "Dernière mise à jour"', (tester) async {
    await _pumpScreen(tester);

    await tester.ensureVisible(
      find.text('Dernière mise à jour : 25 novembre 2026'),
    );
    final footer = tester.widget<Text>(
      find.text('Dernière mise à jour : 25 novembre 2026'),
    );
    expect(footer.style?.fontSize, 11);
    expect(footer.style?.color, AppColors.textMuted);
  });

  group('déclarations d\'attribution officielles, mot pour mot', () {
    testWidgets('en français : SRD 5.1 français, SRD 5.2 anglais marqué '
        '`locale: en`', (tester) async {
      await _pumpScreen(tester);

      expect(find.text(_srd51AttributionFr), findsOneWidget);
      expect(find.text(_srd52AttributionEn), findsOneWidget);
      expect(find.text(_srd51AttributionEn), findsNothing);

      final srd51 =
          tester.widget<Text>(find.text(_srd51AttributionFr)).textSpan!
              as TextSpan;
      expect(srd51.locale, isNull);
      final srd52 =
          tester.widget<Text>(find.text(_srd52AttributionEn)).textSpan!
              as TextSpan;
      expect(srd52.locale, const Locale('en'));
      final style = tester.widget<Text>(find.text(_srd52AttributionEn)).style;
      expect(style?.fontSize, 12);
      expect(style?.color, AppColors.textSecondary);

      // Chacune dans son cadre.
      expect(
        find.descendant(
          of: _attributionBoxes.at(0),
          matching: find.text(_srd51AttributionFr),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _attributionBoxes.at(1),
          matching: find.text(_srd52AttributionEn),
        ),
        findsOneWidget,
      );
    });

    testWidgets('en anglais : SRD 5.1 anglais, SRD 5.2 anglais', (
      tester,
    ) async {
      await _pumpScreen(tester, locale: const Locale('en'));

      expect(find.text(_srd51AttributionEn), findsOneWidget);
      expect(find.text(_srd52AttributionEn), findsOneWidget);
      expect(find.text(_srd51AttributionFr), findsNothing);
      expect(
        find.descendant(
          of: _attributionBoxes.at(0),
          matching: find.text(_srd51AttributionEn),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _attributionBoxes.at(1),
          matching: find.text(_srd52AttributionEn),
        ),
        findsOneWidget,
      );
    });

    testWidgets('les adresses ne sont pas cliquables mais le texte se '
        'sélectionne (SelectionArea)', (tester) async {
      await _pumpScreen(tester);

      expect(find.byType(SelectionArea), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SelectionArea),
          matching: find.text(_srd51AttributionFr),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _attributionBoxes.first,
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );
      final srd51 =
          tester.widget<Text>(find.text(_srd51AttributionFr)).textSpan!
              as TextSpan;
      expect(srd51.recognizer, isNull);
    });
  });

  // Spec §1 « Textes longs » : aucun débordement à 320 dp de large avec une
  // taille de police système x2,0 (portrait seulement), texte légal jamais
  // tronqué (ni `maxLines` ni ellipse).
  group('grande police : x2,0 sur 320 dp', () {
    for (final locale in const [Locale('fr'), Locale('en')]) {
      testWidgets('locale ${locale.languageCode}', (tester) async {
        await useScaledView(tester, scale: 2, width: 320);
        await _pumpScreen(tester, locale: locale);

        expect(tester.takeException(), isNull);
        expect(_attributionBoxes, findsNWidgets(2));
        for (var i = 0; i < 2; i++) {
          final rect = tester.getRect(_attributionBoxes.at(i));
          expect(rect.left, greaterThanOrEqualTo(AppSpacing.lg));
          expect(rect.right, lessThanOrEqualTo(320 - AppSpacing.lg));
        }
        // Corps de l'écran (sous le bandeau bois, dont le titre en police
        // pixel a son propre plafond) : agrandi x2,0, jamais tronqué.
        final bodyTexts = find.descendant(
          of: find.byType(SelectionArea),
          matching: find.byType(RichText),
        );
        expect(bodyTexts, findsAtLeastNWidgets(10));
        for (final element in bodyTexts.evaluate()) {
          final paragraph = element.renderObject! as RenderParagraph;
          final text = paragraph.text.toPlainText();
          expect(paragraph.textScaler.scale(10), 20, reason: text);
          expect(paragraph.didExceedMaxLines, isFalse, reason: text);
          expect(paragraph.size.width, lessThanOrEqualTo(320), reason: text);
        }

        // Défilement jusqu'au pied de page sans erreur de rendu.
        final footer = find.text(
          locale.languageCode == 'fr'
              ? 'Dernière mise à jour : 25 novembre 2026'
              : 'Last updated: November 25, 2026',
        );
        await tester.ensureVisible(footer);
        await tester.pumpAndSettle();
        expect(footer, findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('le bandeau bois propose un retour fonctionnel', (tester) async {
    await _pumpScreen(tester);
    expect(find.text('Ouvrir'), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();

    expect(find.text('Ouvrir'), findsOneWidget);
  });

  group('locale anglaise', () {
    // Même rationale que `login_screen_test.dart` (chantier "traduction de
    // l'app" Phase B) : vérifie qu'un texte anglais s'affiche réellement en
    // locale `en`, pas seulement que l'écran ne plante pas.
    testWidgets('affiche le bandeau bois et les titres de section en anglais', (
      tester,
    ) async {
      await _pumpScreen(tester, locale: const Locale('en'));

      expect(find.text('CREDITS & LICENSES'), findsOneWidget);
      expect(find.text('Game content'), findsOneWidget);
      expect(find.text('Fonts'), findsOneWidget);
      expect(find.text('Open source libraries'), findsOneWidget);
    });

    testWidgets('affiche la date de dernière mise à jour en anglais', (
      tester,
    ) async {
      await _pumpScreen(tester, locale: const Locale('en'));

      await tester.ensureVisible(find.text('Last updated: November 25, 2026'));
      expect(find.text('Last updated: November 25, 2026'), findsOneWidget);
    });
  });
}
