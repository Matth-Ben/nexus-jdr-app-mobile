// P3a (vague 2 de l'onglet Sorts) : mention « Concentration requise » au
// lancer d'un sort à concentration (`character_detail_screen.dart`). Purement
// informatif : aucun état de concentration n'est suivi ni écrit. Le lancer en
// rituel n'existe pas dans l'app (aucun chemin de lancer dédié) : il n'y a donc
// rien à tester pour lui.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/rules/spell_status.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:personnages/features/characters/presentation/character_detail_screen.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/l10n/app_localizations.dart';

import '../../../support/fake_slot_repository.dart';

const _offlineMessage =
    'Hors ligne : sera synchronisé dès que la connexion revient.';

const _fly = CharacterSpellEntry(
  id: 21,
  name: 'Vol',
  level: 3,
  school: 'Transmutation',
  status: SpellStatus.prepared,
  concentration: true,
);
const _friends = CharacterSpellEntry(
  id: 22,
  name: 'Amis',
  level: 0,
  school: 'Enchantement',
  status: SpellStatus.known,
  concentration: true,
);
const _darkness = CharacterSpellEntry(
  id: 23,
  name: 'Ténèbres',
  level: 2,
  school: 'Évocation',
  status: SpellStatus.innate,
  concentration: true,
);
const _hex = CharacterSpellEntry(
  id: 24,
  name: 'Maléfice',
  level: 1,
  school: 'Enchantement',
  status: SpellStatus.prepared,
  concentration: true,
);

class _Repo extends FakeSlotRepository {
  _Repo(super.current);

  @override
  Future<WriteOutcome> setInnateSpellUsesSpent({
    required String characterId,
    required int spellId,
    required int usesSpent,
  }) async {
    return outcome;
  }
}

CharacterDetail _wizard() {
  final base = wizardDetail();
  return base.copyWith(spells: [...base.spells, _fly, _friends, _darkness]);
}

Future<_Repo> _pump(
  WidgetTester tester,
  CharacterDetail detail, {
  Locale locale = const Locale('fr'),
}) async {
  final repository = _Repo(detail);
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
  final confirm = find.widgetWithText(PrimaryButton, castLabel);
  if (tester.any(confirm)) {
    await tester.tap(confirm);
    await tester.pumpAndSettle();
  }
}

void main() {
  group('sort à emplacement (SnackBar de P9)', () {
    testWidgets('mention en ligne supplémentaire du MÊME SnackBar, ANNULER '
        'fonctionnel et unique', (tester) async {
      final repository = await _pump(tester, _wizard());

      await _cast(tester, 'Vol');

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Emplacement de niveau 3 utilisé'), findsOneWidget);
      expect(find.text('Concentration requise'), findsOneWidget);
      expect(find.text('ANNULER'), findsOneWidget);

      await tester.tap(find.text('ANNULER'));
      await tester.pumpAndSettle();
      // Une seule annulation : deux écritures (lancer puis +1 relatif).
      expect(repository.writes.map((w) => w.used), [1, 0]);
      expect(find.text('ANNULER'), findsNothing);
      expect(find.text('Concentration requise'), findsNothing);
    });

    testWidgets('annonce liveRegion incluant la mention', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _wizard());

      await _cast(tester, 'Vol');

      expect(
        find.bySemanticsLabel(
          RegExp(
            r'Emplacement de niveau 3 utilisé\. Concentration requise\. '
            r'Bouton Annuler\.',
          ),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('durée inchangée (6 s)', (tester) async {
      await _pump(tester, _wizard());
      await _cast(tester, 'Vol');
      expect(
        tester.widget<SnackBar>(find.byType(SnackBar)).duration,
        const Duration(seconds: 6),
      );
    });

    testWidgets('hors ligne : mention + « sera synchronisé » dans un seul '
        'SnackBar', (tester) async {
      final repository = await _pump(tester, _wizard());
      repository.outcome = WriteOutcome.queued;

      await _cast(tester, 'Vol');

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Concentration requise'), findsOneWidget);
      expect(find.text(_offlineMessage), findsOneWidget);
      expect(find.text('ANNULER'), findsOneWidget);
    });

    testWidgets('sans concentration : aucune mention', (tester) async {
      await _pump(tester, _wizard());

      await _cast(tester, 'Boule de feu');

      expect(find.text('Emplacement de niveau 3 utilisé'), findsOneWidget);
      expect(find.text('Concentration requise'), findsNothing);
    });

    testWidgets('anglais', (tester) async {
      await _pump(tester, _wizard(), locale: const Locale('en'));

      await _cast(tester, 'Vol', castLabel: 'CAST');

      expect(find.text('Level 3 slot used'), findsOneWidget);
      expect(find.text('Concentration required'), findsOneWidget);
    });

    testWidgets('un lancer suivant sans concentration remplace le SnackBar '
        'et sa mention', (tester) async {
      await _pump(tester, _wizard());
      await _cast(tester, 'Vol');
      expect(find.text('Concentration requise'), findsOneWidget);

      await _cast(tester, 'Boule de feu');

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Concentration requise'), findsNothing);
    });

    testWidgets('pacte : mention présente', (tester) async {
      final base = warlockDetail();
      await _pump(tester, base.copyWith(spells: const [_hex]));

      await _cast(tester, 'Maléfice');

      expect(find.text('Concentration requise'), findsOneWidget);
      expect(find.text('ANNULER'), findsOneWidget);
    });
  });

  group('lancer sans SnackBar d’emplacement', () {
    testWidgets('sort mineur à concentration : un SnackBar, sans ANNULER, '
        'aucune écriture', (tester) async {
      final repository = await _pump(tester, _wizard());

      await _cast(tester, 'Amis');

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Concentration requise'), findsOneWidget);
      expect(find.text('ANNULER'), findsNothing);
      expect(repository.writes, isEmpty);
    });

    testWidgets('sort inné à concentration', (tester) async {
      await _pump(tester, _wizard());

      await _cast(tester, 'Ténèbres');

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Concentration requise'), findsOneWidget);
      expect(find.text('ANNULER'), findsNothing);
    });

    testWidgets('sort inné hors ligne : mention + « sera synchronisé »', (
      tester,
    ) async {
      final repository = await _pump(tester, _wizard());
      repository.outcome = WriteOutcome.queued;

      await _cast(tester, 'Ténèbres');

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Concentration requise'), findsOneWidget);
      expect(find.text(_offlineMessage), findsOneWidget);
    });

    testWidgets('sort mineur sans concentration : aucune mention', (
      tester,
    ) async {
      await _pump(tester, _wizard());

      await _cast(tester, 'Lumière');

      expect(find.text('Concentration requise'), findsNothing);
    });

    testWidgets('remplacé par le lancer suivant (un seul SnackBar)', (
      tester,
    ) async {
      await _pump(tester, _wizard());
      await _cast(tester, 'Amis');

      await _cast(tester, 'Lumière');

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Concentration requise'), findsNothing);
    });
  });
}
