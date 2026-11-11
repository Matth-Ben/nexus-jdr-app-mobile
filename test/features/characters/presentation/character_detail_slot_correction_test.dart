// P9 : feuille « Corriger les emplacements »
// (`widgets/spell_slot_correction_sheet.dart`, ouverte depuis la carte
// Emplacements de l'onglet Sorts). Écran réel + dépôt en mémoire qui journalise
// les écritures absolues `castSpell` (kind de file `spell_slot`, aucun nouveau
// kind) ; le chemin hors ligne avec la vraie file drift est couvert par
// `character_detail_slot_correction_offline_test.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/character_spell_slot.dart';
import 'package:personnages/features/characters/presentation/character_detail_screen.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/features/characters/presentation/widgets/character_spells_section.dart';
import 'package:personnages/features/characters/presentation/widgets/character_spells_tab_body.dart';
import 'package:personnages/features/characters/presentation/widgets/spell_slot_correction_sheet.dart';
import 'package:personnages/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_slot_repository.dart';

Future<FakeSlotRepository> _pump(
  WidgetTester tester,
  CharacterDetail detail, {
  Locale locale = const Locale('fr'),
  Size size = const Size(800, 2400),
}) async {
  final repository = FakeSlotRepository(detail);
  tester.view.physicalSize = size;
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

Future<void> _openSheet(
  WidgetTester tester, {
  String label = 'Corriger',
}) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Finder _inSheet(Finder matching) => find.descendant(
  of: find.byType(SpellSlotCorrectionSheet),
  matching: matching,
);

/// Bouton « + » (rend un emplacement) / « − » (en consomme un) de la ligne du
/// niveau [level], repéré par son libellé d'accessibilité.
Finder _add(int level) => find.bySemanticsLabel(
  RegExp('Niveau $level : \\d restants sur \\d\\. Ajouter un emplacement'),
);
Finder _remove(int level) => find.bySemanticsLabel(
  RegExp('Niveau $level : \\d restants sur \\d\\. Retirer un emplacement'),
);

List<SpellSlotDots> _dotsInSheet(WidgetTester tester) => tester
    .widgetList<SpellSlotDots>(_inSheet(find.byType(SpellSlotDots)))
    .toList();

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('feuille de correction', () {
    testWidgets('une ligne par niveau, textes d\'aide, bouton Terminer', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, wizardDetail());
      await _openSheet(tester);

      expect(find.text('CORRIGER LES EMPLACEMENTS'), findsOneWidget);
      expect(
        find.text(
          'Pour une Récupération arcanique, une Perle de pouvoir ou la magie '
          'de pacte.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          "Les règles n'ont pas d'annulation : ceci corrige le suivi de vos "
          'emplacements.',
        ),
        findsOneWidget,
      );
      expect(_inSheet(find.text('Niveau 1')), findsOneWidget);
      expect(_inSheet(find.text('Niveau 2')), findsOneWidget);
      expect(_inSheet(find.text('Niveau 3')), findsOneWidget);
      expect(_inSheet(find.text('/4')), findsOneWidget);
      expect(_dotsInSheet(tester), hasLength(3));

      await tester.tap(find.text('TERMINER'));
      await tester.pumpAndSettle();
      expect(find.byType(SpellSlotCorrectionSheet), findsNothing);
      handle.dispose();
    });

    testWidgets('chaque appui écrit immédiatement une valeur absolue : un '
        'appui = une écriture, pastilles à jour', (tester) async {
      final handle = tester.ensureSemantics();
      final repository = await _pump(tester, wizardDetail());
      await _openSheet(tester);

      await tester.tap(_remove(1));
      await tester.pumpAndSettle();

      expect(repository.writes, [(level: 1, used: 1, isPact: false)]);
      expect(_dotsInSheet(tester).first.slot.remaining, 3);

      await tester.tap(_remove(1));
      await tester.pumpAndSettle();
      expect(repository.writes.last, (level: 1, used: 2, isPact: false));
      expect(repository.writes, hasLength(2));
      expect(_dotsInSheet(tester).first.slot.remaining, 2);

      await tester.tap(_add(1));
      await tester.pumpAndSettle();
      expect(repository.writes.last, (level: 1, used: 1, isPact: false));
      expect(repository.writes, hasLength(3));
      expect(_dotsInSheet(tester).first.slot.remaining, 3);
      // La carte derrière la feuille reflète aussi la valeur écrite.
      expect(
        find.bySemanticsLabel('Niveau 1 : 3 sur 4 emplacements disponibles'),
        findsWidgets,
      );
      handle.dispose();
    });

    testWidgets('bornes 0..total : « − » désactivé à 0 restant, « + » '
        'désactivé au total', (tester) async {
      final handle = tester.ensureSemantics();
      final repository = await _pump(tester, wizardDetail(level3Used: 2));
      await _openSheet(tester);

      // Niveau 3 : 0 restant sur 2 -> « − » sans effet, « + » actif.
      await tester.tap(_remove(3));
      await tester.pumpAndSettle();
      expect(repository.writes, isEmpty);
      // Niveau 1 : 4 restants sur 4 -> « + » sans effet.
      await tester.tap(_add(1));
      await tester.pumpAndSettle();
      expect(repository.writes, isEmpty);

      await tester.tap(_add(3));
      await tester.pumpAndSettle();
      expect(repository.writes, [(level: 3, used: 1, isPact: false)]);
      handle.dispose();
    });

    testWidgets('semantics des steppers : niveau, restants, action', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, wizardDetail(level3Used: 1));
      await _openSheet(tester);

      expect(
        find.bySemanticsLabel(
          'Niveau 3 : 1 restants sur 2. Ajouter un emplacement',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          'Niveau 3 : 1 restants sur 2. Retirer un emplacement',
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('multiclasse : une ligne par niveau de la table combinée, '
        'plus la ligne de pacte séparée', (tester) async {
      final handle = tester.ensureSemantics();
      final repository = await _pump(
        tester,
        wizardDetail().copyWith(
          spellSlots: const [
            CharacterSpellSlot(level: 1, total: 4, used: 0),
            CharacterSpellSlot(level: 2, total: 3, used: 0),
            CharacterSpellSlot(level: 3, total: 3, used: 0),
            CharacterSpellSlot(level: 4, total: 1, used: 0),
          ],
          pactSpellSlot: const CharacterSpellSlot(
            level: 1,
            total: 2,
            used: 0,
            isPact: true,
          ),
        ),
      );
      await _openSheet(tester);

      expect(_dotsInSheet(tester), hasLength(5));
      expect(_inSheet(find.text('Niveau 4')), findsOneWidget);
      expect(_inSheet(find.text('Pacte (niveau 1)')), findsOneWidget);

      // Le pacte est ajusté seul : aucune conversion avec les classiques.
      await tester.tap(
        find.bySemanticsLabel(
          RegExp(
            r'Pacte, niveau 1 : 2 restants sur 2\. Retirer un emplacement',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(repository.writes, [(level: 1, used: 1, isPact: true)]);
      expect(
        repository.current.spellSlots.every((slot) => slot.used == 0),
        isTrue,
      );
      handle.dispose();
    });

    testWidgets('Occultiste pur : pas de carte Emplacements, le bouton '
        '« Corriger » vit dans la carte « Magie de pacte », plafond = total du '
        'pacte', (tester) async {
      final handle = tester.ensureSemantics();
      final repository = await _pump(tester, warlockDetail());
      expect(find.text('EMPLACEMENTS DE SORTS'), findsNothing);
      expect(find.text('Corriger'), findsOneWidget);
      await _openSheet(tester);

      expect(_dotsInSheet(tester), hasLength(1));
      await tester.tap(
        find.bySemanticsLabel(
          RegExp(
            r'Pacte, niveau 2 : 2 restants sur 2\. Retirer un emplacement',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.bySemanticsLabel(
          RegExp(
            r'Pacte, niveau 2 : 1 restants sur 2\. Retirer un emplacement',
          ),
        ),
      );
      await tester.pumpAndSettle();
      // 0 restant : « − » désactivé, aucune troisième écriture.
      await tester.tap(
        find.bySemanticsLabel(
          RegExp(
            r'Pacte, niveau 2 : 0 restants sur 2\. Retirer un emplacement',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(repository.writes, [
        (level: 2, used: 1, isPact: true),
        (level: 2, used: 2, isPact: true),
      ]);
      handle.dispose();
    });

    testWidgets('échec de l\'écriture : message d\'erreur et valeur d\'avant '
        'rétablie', (tester) async {
      final repository = await _pump(tester, wizardDetail());
      await _openSheet(tester);
      repository.error = const CharacterFailure('Refusé.');

      await tester.tap(_remove(1));
      await tester.pumpAndSettle();

      expect(find.text('Refusé.'), findsOneWidget);
      expect(_dotsInSheet(tester).first.slot.remaining, 4);
    });

    testWidgets('en anglais', (tester) async {
      await _pump(tester, wizardDetail(), locale: const Locale('en'));
      await _openSheet(tester, label: 'Correct');

      expect(find.text('CORRECT SPELL SLOTS'), findsOneWidget);
      expect(
        find.text('For an Arcane Recovery, a Power Surge or Pact Magic.'),
        findsOneWidget,
      );
      expect(find.text('DONE'), findsOneWidget);
    });
  });

  group('point d\'entrée', () {
    Future<void> pumpTab(
      WidgetTester tester, {
      VoidCallback? onCorrectSlots,
      bool actionsDisabled = false,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: Scaffold(
              body: CharacterSpellsTabBody(
                detail: wizardDetail(),
                onCastSpell: (_, _) {},
                onTogglePrepared: (_) {},
                onCorrectSlots: onCorrectSlots,
                actionsDisabled: actionsDisabled,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('lecture seule (aucun callback) : pas de bouton « Corriger »', (
      tester,
    ) async {
      await pumpTab(tester);
      expect(find.text('Corriger'), findsNothing);
    });

    testWidgets('repos / écriture en cours : bouton désactivé', (tester) async {
      var opened = 0;
      await pumpTab(
        tester,
        onCorrectSlots: () => opened++,
        actionsDisabled: true,
      );

      expect(
        tester.widget<TextButton>(find.byType(TextButton).first).onPressed,
        isNull,
      );
      await tester.tap(find.text('Corriger'));
      expect(opened, 0);
    });

    testWidgets('actif : appelle le callback, cible d\'au moins 44×44', (
      tester,
    ) async {
      var opened = 0;
      await pumpTab(tester, onCorrectSlots: () => opened++);

      final size = tester.getSize(find.byType(TextButton).first);
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
      await tester.tap(find.text('Corriger'));
      expect(opened, 1);
    });

    testWidgets('feuille : steppers désactivés quand un repos est en cours', (
      tester,
    ) async {
      final repository = FakeSlotRepository(wizardDetail());
      final writes = <int>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            characterRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: Scaffold(
              body: SpellSlotCorrectionSheet(
                characterId: '1',
                effectiveOf: (detail) => detail,
                isBusy: () => true,
                onSetUsed: (slot, used) => writes.add(used),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.remove).first);
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();

      expect(writes, isEmpty);
    });
  });

  group('accessibilité', () {
    testWidgets('cibles d\'au moins 44×44 pour les steppers et « Terminer »', (
      tester,
    ) async {
      await _pump(tester, wizardDetail());
      await _openSheet(tester);

      for (final icon in [Icons.remove, Icons.add]) {
        final target = find
            .ancestor(
              of: _inSheet(find.byIcon(icon)).first,
              matching: find.byType(InkWell),
            )
            .first;
        final size = tester.getSize(target);
        expect(size.width, greaterThanOrEqualTo(44));
        expect(size.height, greaterThanOrEqualTo(44));
      }
      expect(tester.getSize(find.text('TERMINER')).height, greaterThan(0));
    });

    testWidgets('grande police x2,0 sur 360 dp : la feuille défile, aucun '
        'débordement, « Corriger » reste sur une ligne', (tester) async {
      await _pump(
        tester,
        wizardDetail().copyWith(
          spellSlots: const [
            CharacterSpellSlot(level: 1, total: 4, used: 0),
            CharacterSpellSlot(level: 2, total: 3, used: 0),
            CharacterSpellSlot(level: 3, total: 3, used: 0),
            CharacterSpellSlot(level: 4, total: 3, used: 0),
            CharacterSpellSlot(level: 5, total: 2, used: 0),
          ],
          pactSpellSlot: const CharacterSpellSlot(
            level: 2,
            total: 2,
            used: 0,
            isPact: true,
          ),
        ),
        size: const Size(360, 640),
      );
      // Mis après l'ouverture de l'onglet : l'onglet « PERSO » (carte PV/XP),
      // affiché d'abord, déborde déjà à x2,0 sur 360 dp (hors périmètre P9).
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // « Corriger » : un mot, donc une seule ligne (un mot coupé donnerait
      // une hauteur double).
      final correct = tester.getSize(find.text('Corriger'));
      expect(correct.height, lessThan(13 * 2.0 * 1.7));
      await _openSheet(tester);
      expect(tester.takeException(), isNull);

      // La feuille défile : on atteint la dernière ligne (pacte) et le bouton
      // « Terminer » reste accessible.
      await tester.scrollUntilVisible(
        _inSheet(find.text('Pacte (niveau 2)')),
        100,
        scrollable: _inSheet(find.byType(Scrollable)).first,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('TERMINER'), findsOneWidget);
      // Libellés de ligne courts : jamais coupés en plein mot.
      final level = tester.getSize(_inSheet(find.text('Niveau 5')));
      expect(level.height, lessThan(14 * 2.0 * 1.7));

      await tester.tap(find.text('TERMINER'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
