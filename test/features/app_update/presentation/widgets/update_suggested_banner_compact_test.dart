// D211 : forme compacte de `UpdateSuggestedBanner` (affichée pendant une alerte
// de synchro). Mesures aux trois échelles de police (x1,0 / x2,0 / x3,0) avec
// les vraies polices, une seule cible de tap, aucun bouton de fermeture,
// retour à la forme complète, reduce motion, sémantique, FR/EN.
//
// Le tap appelle `openAppStorePage` : sous `flutter test`, `canLaunchUrl` n'a
// pas de plugin, l'appel échoue proprement et affiche le snackbar d'erreur —
// c'est la preuve observable que l'action a bien été déclenchée.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:personnages/features/app_update/data/app_version_repository.dart';
import 'package:personnages/features/app_update/presentation/providers/app_version_providers.dart';
import 'package:personnages/features/app_update/presentation/widgets/update_suggested_banner.dart';
import 'package:personnages/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAppVersionRepository implements AppVersionRepository {
  _FakeAppVersionRepository({this.latest = '0.5.0'});

  final String latest;

  @override
  Future<AppVersionRow> fetchCurrentPlatformVersion() async =>
      AppVersionRow(minimumSupportedVersion: '0.1.0', latestVersion: latest);
}

void main() {
  setUpAll(() async {
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
    PackageInfo.setMockInitialValues(
      appName: 'Nexus JDR — Personnages',
      packageName: 'com.nexusjdr.personnages',
      version: '0.1.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  late ValueNotifier<bool> compact;

  Future<void> pumpBanner(
    WidgetTester tester, {
    double width = 320,
    double scale = 1,
    bool compactValue = true,
    bool disableAnimations = false,
    Locale locale = const Locale('fr'),
    String latest = '0.5.0',
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    compact = ValueNotifier(compactValue);
    addTearDown(compact.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appVersionRepositoryProvider.overrideWithValue(
            _FakeAppVersionRepository(latest: latest),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: disableAnimations,
            ),
            child: child!,
          ),
          home: Scaffold(
            body: Padding(
              // Marge latérale de l'écran liste (AppSpacing.lg = 22).
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Align(
                alignment: Alignment.topCenter,
                child: ValueListenableBuilder<bool>(
                  valueListenable: compact,
                  builder: (_, value, _) =>
                      UpdateSuggestedBanner(compact: value),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder action(String text) => find.text(text);

  RenderParagraph paragraph(WidgetTester tester, String text) =>
      tester.renderObject<RenderParagraph>(find.text(text));

  group('mesures par échelle (compact)', () {
    // (largeur, échelle, hauteur max de la barre avec marge basse, lignes max)
    const cases = <(double, double, double, int)>[
      (320, 1.0, 52, 1),
      (360, 1.0, 52, 1),
      (320, 2.0, 52, 1),
      (360, 2.0, 52, 1),
      (320, 3.0, 142, 2),
      (360, 3.0, 142, 2),
    ];
    for (final (width, scale, maxHeight, maxLines) in cases) {
      testWidgets('largeur ${width.toInt()} x$scale : <= $maxHeight px, '
          '<= $maxLines ligne(s), sans ✕, une seule cible >= 44, sans '
          'ellipse', (tester) async {
        await pumpBanner(tester, width: width, scale: scale);

        expect(tester.takeException(), isNull);
        final size = tester.getSize(find.byType(UpdateSuggestedBanner));
        expect(size.height, lessThanOrEqualTo(maxHeight));
        expect(find.byIcon(Icons.close), findsNothing);
        expect(find.byType(IconButton), findsNothing);

        // Un seul widget cible de tap, de 44 px de haut au moins.
        final inkWells = find.descendant(
          of: find.byType(UpdateSuggestedBanner),
          matching: find.byType(InkWell),
        );
        expect(inkWells, findsOneWidget);
        expect(tester.getSize(inkWells).height, greaterThanOrEqualTo(44));

        // Bouton : texte complet, sans ellipse, au plus [maxLines] lignes.
        expect(action('Mettre à jour'), findsOneWidget);
        final render = paragraph(tester, 'Mettre à jour');
        expect(render.overflow, isNot(TextOverflow.ellipsis));
        expect(render.didExceedMaxLines, isFalse);
        expect(
          render
              .getBoxesForSelection(
                const TextSelection(baseOffset: 0, extentOffset: 13),
              )
              .map((b) => b.top)
              .toSet()
              .length,
          lessThanOrEqualTo(maxLines),
        );

        // Aucune cible tronquée : la barre reste dans la largeur disponible.
        final rect = tester.getRect(inkWells);
        expect(rect.left, greaterThanOrEqualTo(22 - 0.5));
        expect(rect.right, lessThanOrEqualTo(width - 22 + 0.5));
      });
    }

    testWidgets('x1,0 : libellé court visible à côté de l\'icône', (
      tester,
    ) async {
      await pumpBanner(tester, scale: 1);
      expect(find.text('Nouvelle version'), findsOneWidget);
      expect(find.byIcon(Icons.file_download_outlined), findsOneWidget);
    });

    testWidgets('x2,0 sur 320 : libellé masqué, icône + bouton sur une ligne', (
      tester,
    ) async {
      await pumpBanner(tester, scale: 2);
      expect(find.text('Nouvelle version'), findsNothing);
      expect(find.byIcon(Icons.file_download_outlined), findsOneWidget);
      final icon = tester.getRect(find.byIcon(Icons.file_download_outlined));
      final text = tester.getRect(action('Mettre à jour'));
      expect(text.left, greaterThanOrEqualTo(icon.right));
      expect(text.top, lessThan(icon.bottom));
    });

    testWidgets('x3,0 sur 320 : icône masquée, texte sans coupure de mot', (
      tester,
    ) async {
      await pumpBanner(tester, scale: 3);
      expect(find.byIcon(Icons.file_download_outlined), findsNothing);
      // Au plus 2 lignes (vérifié ci-dessus) : une coupure lettre par lettre
      // en produirait davantage.
      expect(find.text('Mettre à jour'), findsOneWidget);
    });
  });

  group('transition et formes', () {
    testWidgets('alerte retirée : la forme complète revient (✕ 44x44)', (
      tester,
    ) async {
      await pumpBanner(tester);
      expect(find.byIcon(Icons.close), findsNothing);

      compact.value = false;
      await tester.pumpAndSettle();

      expect(find.text('Nouvelle version disponible'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(tester.getSize(find.byType(IconButton)), const Size(44, 44));
      expect(find.text('Nouvelle version'), findsNothing);
    });

    testWidgets('forme complète -> compact : ✕ disparaît, jamais de ✕ en '
        'compact', (tester) async {
      await pumpBanner(tester, compactValue: false);
      expect(find.byIcon(Icons.close), findsOneWidget);

      compact.value = true;
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.text('Nouvelle version disponible'), findsNothing);
    });

    testWidgets('animation normale : un seul pump laisse les deux formes en '
        'transition', (tester) async {
      await pumpBanner(tester);
      compact.value = false;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Fondu en cours : l'ancienne forme est encore là et la nouvelle aussi.
      expect(find.text('Nouvelle version'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('disableAnimations : changement immédiat (pump unique)', (
      tester,
    ) async {
      await pumpBanner(tester, disableAnimations: true);

      compact.value = false;
      await tester.pump();

      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.text('Nouvelle version'), findsNothing);
      expect(find.text('Nouvelle version disponible'), findsOneWidget);
    });

    testWidgets('rien à afficher (à jour) : aucune place, même en compact', (
      tester,
    ) async {
      await pumpBanner(tester, latest: '0.1.0');
      expect(tester.getSize(find.byType(UpdateSuggestedBanner)).height, 0);
      expect(find.text('Mettre à jour'), findsNothing);
    });

    testWidgets('version déjà refermée : rien, même en compact', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'app_update_banner_dismissed_version': '0.5.0',
      });
      await pumpBanner(tester);
      expect(tester.getSize(find.byType(UpdateSuggestedBanner)).height, 0);
    });
  });

  group('tap', () {
    // `openAppStorePage` passe par le canal `url_launcher` : on l'intercepte
    // (canLaunch -> false) pour observer l'appel et déclencher le snackbar.
    late List<MethodCall> launcherCalls;

    setUp(() => launcherCalls = []);

    void mockLauncher(WidgetTester tester) {
      const channel = MethodChannel('plugins.flutter.io/url_launcher');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        launcherCalls.add(call);
        return false;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
    }

    const openError =
        "Impossible d'ouvrir la fiche de l'application. Réessayez.";

    testWidgets('tap compact : appelle openAppStorePage, sans toucher à la '
        'fermeture mémorisée', (tester) async {
      mockLauncher(tester);
      await pumpBanner(tester);

      await tester.tap(find.byType(InkWell));
      await tester.pump();
      await tester.pump();
      expect(launcherCalls, hasLength(1));
      expect(launcherCalls.single.method, 'canLaunch');
      expect(find.text(openError), findsOneWidget);

      // La version n'est pas refermée : la forme complète revient.
      compact.value = false;
      await tester.pumpAndSettle();
      expect(find.text('Nouvelle version disponible'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_update_banner_dismissed_version'), isNull);
    });

    testWidgets('tap sur le libellé court = tap sur la barre entière', (
      tester,
    ) async {
      mockLauncher(tester);
      await pumpBanner(tester);
      await tester.tap(find.text('Nouvelle version'));
      await tester.pump();
      await tester.pump();
      expect(launcherCalls, hasLength(1));
      expect(find.text(openError), findsOneWidget);
    });
  });

  group('sémantique et langues', () {
    testWidgets('FR : un seul bouton sémantique, sans liveRegion', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpBanner(tester);

      final finder = find.bySemanticsLabel(
        'Nouvelle version disponible. Ouvrir la page de mise à jour.',
      );
      expect(finder, findsOneWidget);
      final node = tester.getSemantics(finder);
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.flagsCollection.isLiveRegion, isFalse);
      // Le texte visible et l'icône ne sont pas des nœuds distincts.
      expect(find.bySemanticsLabel('Mettre à jour'), findsNothing);
      handle.dispose();
    });

    testWidgets('EN : libellés anglais, aucun français', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpBanner(tester, locale: const Locale('en'));

      expect(find.text('New version'), findsOneWidget);
      expect(find.text('Update'), findsOneWidget);
      expect(find.text('Nouvelle version'), findsNothing);
      expect(
        find.bySemanticsLabel('New version available. Open the update page.'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('texte >= 11 px', (tester) async {
      await pumpBanner(tester);
      for (final text in ['Nouvelle version', 'Mettre à jour']) {
        expect(
          tester.widget<Text>(find.text(text)).style!.fontSize!,
          greaterThanOrEqualTo(11),
        );
      }
    });
  });
}
