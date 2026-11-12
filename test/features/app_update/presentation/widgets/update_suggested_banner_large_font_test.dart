// F21 (`docs/retours-utilisateurs.md`) : empilement du lien « Mettre à jour »
// décidé par la largeur disponible (message + lien tiennent-ils sur une ligne
// côte à côte ?), et cible tactile du lien d'au moins 44 px dans les deux
// modes (section 7 "Accessibilité" du design system).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:personnages/l10n/app_localizations.dart';
import 'package:personnages/features/app_update/data/app_version_repository.dart';
import 'package:personnages/features/app_update/presentation/providers/app_version_providers.dart';
import 'package:personnages/features/app_update/presentation/widgets/update_suggested_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAppVersionRepository implements AppVersionRepository {
  @override
  Future<AppVersionRow> fetchCurrentPlatformVersion() async =>
      const AppVersionRow(
        minimumSupportedVersion: '0.1.0',
        latestVersion: '0.5.0',
      );
}

void main() {
  setUpAll(() async {
    // Police réelle (Work Sans) : la police de test (1 em par caractère) fausse
    // la mesure de largeur dont dépend la décision d'empilement.
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

  Future<void> pumpBanner(
    WidgetTester tester, {
    required double width,
    required double scale,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appVersionRepositoryProvider.overrideWithValue(
            _FakeAppVersionRepository(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          // Marge latérale de l'écran liste (AppSpacing.lg = 22).
          home: const Scaffold(
            body: Padding(
              padding: EdgeInsets.symmetric(horizontal: 22),
              child: UpdateSuggestedBanner(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Vrai si le lien est sous le message (empilé), faux s'il est à sa droite.
  bool isStacked(WidgetTester tester) {
    final message = tester.getRect(find.text('Nouvelle version disponible'));
    final link = tester.getRect(find.text('Mettre à jour'));
    return link.top >= message.bottom - 0.5;
  }

  // Résultat attendu par (largeur, échelle) : true = empilé.
  const expectations = <(double, double, bool)>[
    (320, 1.0, true),
    (360, 1.0, true),
    (412, 1.0, false),
    (320, 1.3, true),
    (360, 1.3, true),
    (412, 1.3, true),
    (320, 2.0, true),
    (360, 2.0, true),
    (412, 2.0, true),
  ];

  for (final (width, scale, expected) in expectations) {
    testWidgets(
      'largeur ${width.toInt()} police x$scale : '
      '${expected ? 'empilé' : 'côte à côte'}, sans exception, lien >= 44 px',
      (tester) async {
        await pumpBanner(tester, width: width, scale: scale);

        expect(tester.takeException(), isNull);
        expect(isStacked(tester), expected);
        final inkWell = find.ancestor(
          of: find.text('Mettre à jour'),
          matching: find.byType(InkWell),
        );
        expect(tester.getSize(inkWell).height, greaterThanOrEqualTo(44));
      },
    );
  }

  testWidgets('lien : cible tactile >= 44 px de haut à police normale', (
    tester,
  ) async {
    await pumpBanner(tester, width: 412, scale: 1);
    expect(isStacked(tester), isFalse);

    final inkWell = find.ancestor(
      of: find.text('Mettre à jour'),
      matching: find.byType(InkWell),
    );
    expect(tester.getSize(inkWell).height, greaterThanOrEqualTo(44));
  });

  testWidgets('lien : cible tactile >= 44 px de haut en mode empilé', (
    tester,
  ) async {
    await pumpBanner(tester, width: 360, scale: 2);

    final inkWell = find.ancestor(
      of: find.text('Mettre à jour'),
      matching: find.byType(InkWell),
    );
    expect(tester.getSize(inkWell).height, greaterThanOrEqualTo(44));
  });
}
