// Localisation du flux de mise à jour (bandeau suggéré, écran bloquant,
// SnackBar d'échec d'ouverture du store) : chaque texte suit la langue de
// l'app (FR et EN), plus une garde contre tout littéral français réintroduit
// dans `presentation/` (D141).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:personnages/features/app_update/data/app_version_repository.dart';
import 'package:personnages/features/app_update/presentation/force_update_screen.dart';
import 'package:personnages/features/app_update/presentation/providers/app_version_providers.dart';
import 'package:personnages/features/app_update/presentation/widgets/update_suggested_banner.dart';
import 'package:personnages/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAppVersionRepository implements AppVersionRepository {
  @override
  Future<AppVersionRow> fetchCurrentPlatformVersion() async =>
      const AppVersionRow(
        minimumSupportedVersion: '0.1.0',
        latestVersion: '0.5.0',
      );
}

Widget _app(Locale locale, Widget home) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: locale,
  home: home,
);

void main() {
  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'Nexus JDR — Personnages',
      packageName: 'com.nexusjdr.personnages',
      version: '0.1.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpBanner(WidgetTester tester, Locale locale) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appVersionRepositoryProvider.overrideWithValue(
            _FakeAppVersionRepository(),
          ),
        ],
        child: _app(locale, const Scaffold(body: UpdateSuggestedBanner())),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('bandeau de mise à jour suggérée', () {
    testWidgets('EN : message, lien et info-bulle en anglais', (tester) async {
      await pumpBanner(tester, const Locale('en'));

      expect(find.text('A new version is available'), findsOneWidget);
      expect(find.text('Update'), findsOneWidget);
      expect(find.byTooltip('Dismiss'), findsOneWidget);
      expect(find.text('Nouvelle version disponible'), findsNothing);
      expect(find.text('Mettre à jour'), findsNothing);
      expect(find.byTooltip('Fermer'), findsNothing);
    });

    testWidgets('FR : message, lien et info-bulle en français', (tester) async {
      await pumpBanner(tester, const Locale('fr'));

      expect(find.text('Nouvelle version disponible'), findsOneWidget);
      expect(find.text('Mettre à jour'), findsOneWidget);
      expect(find.byTooltip('Fermer'), findsOneWidget);
    });
  });

  group('écran de mise à jour obligatoire', () {
    Future<void> pumpScreen(WidgetTester tester, Locale locale) =>
        tester.pumpWidget(
          _app(
            locale,
            const ForceUpdateScreen(
              installedVersion: '0.1.0',
              minimumVersion: '0.3.0',
            ),
          ),
        );

    testWidgets('EN : aucun texte français', (tester) async {
      await pumpScreen(tester, const Locale('en'));

      expect(find.text('UPDATE'), findsOneWidget);
      expect(find.text('REQUIRED'), findsOneWidget);
      expect(find.textContaining('no longer supported'), findsOneWidget);
      expect(find.text('↓ UPDATE'), findsOneWidget);
      expect(
        find.text('Installed version: 0.1.0 · minimum required: 0.3.0'),
        findsOneWidget,
      );
      expect(find.textContaining('MISE À JOUR'), findsNothing);
      expect(find.textContaining('REQUISE'), findsNothing);
      expect(find.textContaining('prise en charge'), findsNothing);
      expect(find.textContaining('Version installée'), findsNothing);
    });

    testWidgets('FR : textes français', (tester) async {
      await pumpScreen(tester, const Locale('fr'));

      expect(find.text('MISE À JOUR'), findsOneWidget);
      expect(find.text('REQUISE'), findsOneWidget);
      expect(find.textContaining("n'est plus prise en charge"), findsOneWidget);
      expect(find.text('↓ METTRE À JOUR'), findsOneWidget);
      expect(
        find.text('Version installée : 0.1.0 · minimum requis : 0.3.0'),
        findsOneWidget,
      );
    });

    for (final (locale, expected) in [
      (const Locale('en'), "Couldn't open the app's store page. Try again."),
      (
        const Locale('fr'),
        "Impossible d'ouvrir la fiche de l'application. Réessayez.",
      ),
    ]) {
      testWidgets(
        'SnackBar d\'échec d\'ouverture du store (${locale.languageCode})',
        (tester) async {
          // Canal `url_launcher` mocké : `canLaunchUrl` répond `false`, donc
          // `openAppStorePage` affiche le message d'échec.
          const channel = MethodChannel('plugins.flutter.io/url_launcher');
          final messenger = tester.binding.defaultBinaryMessenger;
          messenger.setMockMethodCallHandler(channel, (call) async => false);
          addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
          await pumpScreen(tester, locale);
          await tester.tap(find.textContaining('↓'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));

          expect(find.text(expected), findsOneWidget);
        },
      );
    }
  });

  test('garde : aucun littéral français dans lib/features/app_update/'
      'presentation', () {
    final accented = RegExp('[àâçéèêëîïôùûœÀÂÇÉÈÊËÎÏÔÙÛŒ]');
    final frenchWords = RegExp(
      r"\b(Mettre|Nouvelle|version disponible|Fermer|Réessay|Impossible|"
      r'Mets|Cette|personnages)\b',
    );
    final offenders = <String>[];
    for (final entity in Directory(
      'lib/features/app_update/presentation',
    ).listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('.g.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.startsWith('//')) continue;
        // Seuls les littéraux de chaîne comptent.
        final literals = [
          RegExp(r"'(?:[^'\\]|\\.)*'"),
          RegExp(r'"[^"]*"'),
        ].expand((re) => re.allMatches(line)).map((m) => m.group(0)!);
        for (final literal in literals) {
          if (literal.contains('package:') || literal.startsWith("'../")) {
            continue;
          }
          if (accented.hasMatch(literal) || frenchWords.hasMatch(literal)) {
            offenders.add('${entity.path}:${i + 1}: $literal');
          }
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
