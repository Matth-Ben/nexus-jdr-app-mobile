// P9 (vague 2 de l'onglet Sorts) : SnackBar « Annuler » après un lancer qui
// consomme un emplacement (`character_detail_screen.dart::_showSlotUsedSnackBar`
// / `_undoSlotUse`). Écran réel + dépôt en mémoire qui journalise les
// écritures absolues `castSpell` (même méthode que le lancer, kind de file
// `spell_slot`) ; le chemin hors ligne avec la vraie file drift est couvert
// par `character_detail_slot_correction_offline_test.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/character_spell_slot.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:personnages/features/characters/presentation/character_detail_screen.dart';
import 'package:personnages/features/characters/presentation/providers/character_detail_provider.dart';
import 'package:personnages/features/characters/presentation/widgets/spell_slot_used_snack_bar.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/l10n/app_localizations.dart';

import '../../../support/fake_slot_repository.dart';

const _offlineMessage =
    'Hors ligne : sera synchronisé dès que la connexion revient.';

Future<FakeSlotRepository> _pump(
  WidgetTester tester,
  CharacterDetail detail, {
  Locale locale = const Locale('fr'),
}) async {
  final repository = FakeSlotRepository(detail);
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [characterRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        routerConfig: GoRouter(
          initialLocation: '/characters/1',
          routes: [
            GoRoute(
              path: '/characters/:id',
              builder: (context, state) => CharacterDetailScreen(
                characterId: state.pathParameters['id']!,
              ),
            ),
            GoRoute(
              path: '/other',
              builder: (context, state) =>
                  const Scaffold(body: Text('Autre écran')),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(locale.languageCode == 'en' ? 'SPELLS' : 'SORTS'));
  await tester.pumpAndSettle();
  return repository;
}

Future<void> _cast(
  WidgetTester tester,
  String name, {
  String castLabel = 'LANCER',
}) async {
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(PrimaryButton, castLabel));
  await tester.pumpAndSettle();
}

Future<void> _undo(WidgetTester tester, {String label = 'ANNULER'}) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void _invalidate(WidgetTester tester) {
  ProviderScope.containerOf(tester.element(find.byType(CharacterDetailScreen)))
      .invalidate(characterDetailProvider('1'));
}

String _slotLabel(int level, int remaining, int total) =>
    'Niveau $level : $remaining sur $total emplacements disponibles';

void main() {
  group('affichage du SnackBar', () {
    testWidgets('sort de niveau >= 1 : texte exact, action ANNULER, un seul '
        'SnackBar', (tester) async {
      await _pump(tester, wizardDetail());

      await _cast(tester, 'Boule de feu');

      expect(find.text('Emplacement de niveau 3 utilisé'), findsOneWidget);
      expect(find.text('ANNULER'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
      // Fusion : plus de second message de succès « lancé (emplacement ... ».
      expect(find.textContaining('lancé'), findsNothing);
    });

    testWidgets('anglais : « Level 3 slot used » / « UNDO »', (tester) async {
      await _pump(tester, wizardDetail(), locale: const Locale('en'));

      await _cast(tester, 'Boule de feu', castLabel: 'CAST');

      expect(find.text('Level 3 slot used'), findsOneWidget);
      expect(find.text('UNDO'), findsOneWidget);
    });

    testWidgets('sort mineur : aucun SnackBar d\'annulation, aucune écriture', (
      tester,
    ) async {
      final repository = await _pump(tester, wizardDetail());

      await _cast(tester, 'Lumière');

      expect(repository.writes, isEmpty);
      expect(find.text('ANNULER'), findsNothing);
      expect(find.textContaining('Emplacement de niveau'), findsNothing);
    });

    testWidgets('un second lancer remplace le SnackBar du premier (message '
        'hors ligne fusionné puis remplacé), un seul ANNULER', (tester) async {
      final repository = await _pump(tester, wizardDetail());
      repository.outcome = WriteOutcome.queued;
      await _cast(tester, 'Boule de feu');
      expect(find.text(_offlineMessage), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);

      repository.outcome = WriteOutcome.synced;
      await _cast(tester, 'Contresort');

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('ANNULER'), findsOneWidget);
      expect(find.text(_offlineMessage), findsNothing);
      // Seul le DERNIER lancer est annulable : un seul retour d'emplacement.
      await _undo(tester);
      expect(repository.writes.map((w) => w.used), [1, 2, 1]);
    });

    testWidgets('un sort mineur lancé ensuite retire l\'ANNULER du lancer '
        'précédent', (tester) async {
      await _pump(tester, wizardDetail());
      await _cast(tester, 'Boule de feu');
      expect(find.text('ANNULER'), findsOneWidget);

      await _cast(tester, 'Lumière');

      expect(find.text('ANNULER'), findsNothing);
    });

    testWidgets('hors ligne : un seul SnackBar, message de lancer + « sera '
        'synchronisé » fusionnés', (tester) async {
      final repository = await _pump(tester, wizardDetail());
      repository.outcome = WriteOutcome.queued;

      await _cast(tester, 'Boule de feu');

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Emplacement de niveau 3 utilisé'), findsOneWidget);
      expect(find.text(_offlineMessage), findsOneWidget);
      expect(find.text('ANNULER'), findsOneWidget);
    });

    testWidgets('échec du lancer : message d\'erreur, pas de SnackBar '
        'd\'annulation', (tester) async {
      final repository = await _pump(tester, wizardDetail());
      repository.error = const CharacterFailure('Refusé.');

      await _cast(tester, 'Boule de feu');

      expect(find.text('Refusé.'), findsOneWidget);
      expect(find.text('ANNULER'), findsNothing);
    });

    testWidgets('durée : 6 s par défaut, 10 s avec les services '
        'd\'accessibilité', (tester) async {
      await _pump(tester, wizardDetail());
      await _cast(tester, 'Boule de feu');
      expect(
        tester.widget<SnackBar>(find.byType(SnackBar)).duration,
        const Duration(seconds: 6),
      );

      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(accessibleNavigation: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpAndSettle();
      await _cast(tester, 'Contresort');

      expect(
        tester.widget<SnackBar>(find.byType(SnackBar)).duration,
        const Duration(seconds: 10),
      );
    });

    testWidgets('le SnackBar disparaît seul après sa durée', (tester) async {
      await _pump(tester, wizardDetail());
      await _cast(tester, 'Boule de feu');

      await tester.pump(const Duration(seconds: 7));
      await tester.pumpAndSettle();

      expect(find.text('ANNULER'), findsNothing);
    });

    testWidgets('accessibilité : annonce liveRegion et bouton d\'au moins '
        '44 px', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, wizardDetail());
      await _cast(tester, 'Boule de feu');

      expect(
        find.bySemanticsLabel(
          RegExp(r'Emplacement de niveau 3 utilisé\. Bouton Annuler\.'),
        ),
        findsOneWidget,
      );
      final button = find.descendant(
        of: find.byType(SnackBar),
        matching: find.byType(InkWell),
      );
      expect(tester.getSize(button).height, greaterThanOrEqualTo(44));
      expect(tester.getSize(button).width, greaterThanOrEqualTo(44));
      handle.dispose();
    });
  });

  group('annuler', () {
    testWidgets('rend UN emplacement : écriture absolue used - 1', (
      tester,
    ) async {
      final repository = await _pump(tester, wizardDetail(level3Used: 1));
      await _cast(tester, 'Boule de feu');

      await _undo(tester);

      expect(repository.writes, [
        (level: 3, used: 2, isPact: false),
        (level: 3, used: 1, isPact: false),
      ]);
      expect(find.text('ANNULER'), findsNothing);
    });

    testWidgets('+1 relatif : une valeur changée entre-temps (repos sur un '
        'autre appareil) n\'est pas écrasée par un retour à la valeur '
        'figée', (tester) async {
      final handle = tester.ensureSemantics();
      final repository = await _pump(tester, wizardDetail(level3Used: 1));
      await _cast(tester, 'Boule de feu'); // used 1 -> 2
      // Un repos fait ailleurs remet le niveau 3 à 0 ; la fiche est relue.
      repository.current = repository.current.copyWith(
        spellSlots: [
          for (final slot in repository.current.spellSlots)
            CharacterSpellSlot(level: slot.level, total: slot.total, used: 0),
        ],
      );
      _invalidate(tester);
      await tester.pump();
      await tester.pumpAndSettle();

      await _undo(tester);

      // Borné à 0 : jamais -1, jamais un retour à « 2 - 1 = 1 » figé.
      expect(repository.writes.map((w) => w.used), [2]);
      expect(find.bySemanticsLabel(_slotLabel(3, 2, 2)), findsWidgets);
      handle.dispose();
    });

    testWidgets('+1 relatif après une correction manuelle intermédiaire', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final repository = await _pump(tester, wizardDetail(level3Used: 1));
      await _cast(tester, 'Boule de feu'); // used 2
      // Correction : +1 (rend un emplacement) -> used 1.
      await tester.tap(find.text('Corriger'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.bySemanticsLabel(
          RegExp(r'Niveau 3 : 0 restants sur 2\. Ajouter un emplacement'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('TERMINER'));
      await tester.pumpAndSettle();
      expect(repository.writes.last.used, 1);

      await _undo(tester);

      // 1 - 1 = 0 (et non 2 - 1 = 1).
      expect(repository.writes.last.used, 0);
      expect(repository.writes.length, 3);
      handle.dispose();
    });

    testWidgets('borné à 0 : déjà à 0 après correction, ANNULER n\'écrit '
        'jamais -1', (tester) async {
      final handle = tester.ensureSemantics();
      final repository = await _pump(tester, wizardDetail(level3Used: 1));
      await _cast(tester, 'Boule de feu'); // used 2
      await tester.tap(find.text('Corriger'));
      await tester.pumpAndSettle();
      Finder plus() => find.bySemanticsLabel(
        RegExp(r'Niveau 3 : \d restants sur 2\. Ajouter un emplacement'),
      );
      await tester.tap(plus());
      await tester.pumpAndSettle();
      await tester.tap(plus());
      await tester.pumpAndSettle();
      await tester.tap(find.text('TERMINER'));
      await tester.pumpAndSettle();
      expect(repository.writes.last.used, 0);
      final before = repository.writes.length;

      await _undo(tester);

      expect(repository.writes.length, before);
      expect(repository.writes.every((w) => w.used >= 0), isTrue);
      handle.dispose();
    });

    testWidgets('fermé par un repos', (tester) async {
      final repository = await _pump(tester, wizardDetail());
      await _cast(tester, 'Boule de feu');
      expect(find.text('ANNULER'), findsOneWidget);

      await tester.tap(find.text('PERSO'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('REPOS'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('APPLIQUER'));
      await tester.pumpAndSettle();

      expect(repository.restCount, 1);
      expect(find.text('ANNULER'), findsNothing);
      expect(find.textContaining('Emplacement de niveau'), findsNothing);
    });

    testWidgets('hors ligne : l\'annulation s\'enfile après le lancer, la '
        'valeur absolue finale est celle de l\'annulation', (tester) async {
      final repository = await _pump(tester, wizardDetail(level3Used: 1));
      repository.outcome = WriteOutcome.queued;
      await _cast(tester, 'Boule de feu');

      await _undo(tester);

      expect(repository.writes.map((w) => w.used), [2, 1]);
      // Aucun message d'erreur ni second SnackBar.
      expect(find.byType(SnackBar), findsNothing);
      await tester.tap(find.text('PERSO'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SORTS'));
      await tester.pumpAndSettle();
      final handle = tester.ensureSemantics();
      expect(find.bySemanticsLabel(_slotLabel(3, 1, 2)), findsWidgets);
      handle.dispose();
    });

    testWidgets('échec de l\'écriture d\'annulation : message d\'erreur et '
        'valeur d\'avant conservée', (tester) async {
      final handle = tester.ensureSemantics();
      final repository = await _pump(tester, wizardDetail(level3Used: 1));
      await _cast(tester, 'Boule de feu'); // used 2
      repository.error = const CharacterFailure('Refusé.');

      await _undo(tester);

      expect(find.text('Refusé.'), findsOneWidget);
      expect(find.bySemanticsLabel(_slotLabel(3, 0, 2)), findsWidgets);
      handle.dispose();
    });

    testWidgets('magie de pacte : message dédié, retour d\'un emplacement '
        'de pacte', (tester) async {
      final repository = await _pump(tester, warlockDetail());

      await _cast(tester, 'Rayon de givre');

      expect(find.text('Emplacement de pacte utilisé'), findsOneWidget);
      await _undo(tester);
      expect(repository.writes, [
        (level: 2, used: 1, isPact: true),
        (level: 2, used: 0, isPact: true),
      ]);
    });

    testWidgets('magie de pacte en anglais', (tester) async {
      await _pump(tester, warlockDetail(), locale: const Locale('en'));

      await _cast(tester, 'Rayon de givre', castLabel: 'CAST');

      expect(find.text('Pact slot used'), findsOneWidget);
    });
  });

  group('garde-fous du SnackBar', () {
    testWidgets('double appui sur ANNULER (aussi pendant la '
        'fermeture animée) : un seul emplacement rendu', (tester) async {
      final repository = await _pump(tester, wizardDetail());
      await _cast(tester, 'Boule de feu'); // used 1
      await _cast(tester, 'Contresort'); // used 2

      await tester.tap(find.text('ANNULER'));
      await tester.pump(const Duration(milliseconds: 30));
      // Le bouton est encore dans l'arbre, le SnackBar en cours de fermeture.
      await tester.tap(find.text('ANNULER'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(repository.writes.map((w) => w.used), [1, 2, 1]);
    });

    testWidgets('deux appuis dans la même image : un seul emplacement rendu', (
      tester,
    ) async {
      final repository = await _pump(tester, wizardDetail());
      await _cast(tester, 'Boule de feu');
      await _cast(tester, 'Contresort');

      await tester.tap(find.text('ANNULER'));
      await tester.tap(find.text('ANNULER'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(repository.writes.map((w) => w.used), [1, 2, 1]);
    });

    testWidgets('sortie de la fiche : aucun SnackBar orphelin, aucune '
        'écriture, aucune exception', (tester) async {
      final repository = await _pump(tester, wizardDetail());
      await _cast(tester, 'Boule de feu');
      expect(find.text('ANNULER'), findsOneWidget);
      final writesBefore = repository.writes.length;

      GoRouter.of(tester.element(find.byType(CharacterDetailScreen)))
          .go('/other');
      await tester.pumpAndSettle();

      expect(find.text('Autre écran'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.text('ANNULER'), findsNothing);
      expect(repository.writes, hasLength(writesBefore));
      expect(tester.takeException(), isNull);
    });

    testWidgets('showSpellSlotUsedSnackBar remplace lui-même le SnackBar '
        'affiché (un seul visible après deux appels)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  for (final label in ['Premier', 'Second'])
                    TextButton(
                      onPressed: () => showSpellSlotUsedSnackBar(
                        context,
                        message: label,
                        undoLabel: 'Annuler',
                        announcement: label,
                        onUndo: () {},
                      ),
                      child: Text('Afficher $label'),
                    ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Afficher Premier'));
      await tester.pump();
      await tester.tap(find.text('Afficher Second'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Premier'), findsNothing);
      expect(find.text('Second'), findsOneWidget);
    });
  });
}
