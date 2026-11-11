// V2-5 : un tiers-lanceur non géré (Chevalier occulte, Escroc arcanique) ne
// doit pas lire « Ce personnage ne lance pas de sorts. ».

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_spell_slot.dart';
import 'package:personnages/features/characters/presentation/widgets/character_spells_section.dart';
import 'package:personnages/features/characters/presentation/widgets/character_spells_tab_body.dart';
import 'package:personnages/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _frNonCaster = 'Ce personnage ne lance pas de sorts.';
const _frUnsupported =
    "Les sorts de ce personnage ne sont pas gérés par l'app.";
const _enNonCaster = "This character doesn't cast spells.";
const _enUnsupported = "This character's spells aren't supported in the app.";

CharacterDetail _detail(
  String className, {
  String? subclass,
  List<CharacterSpellSlot> slots = const [],
}) => CharacterDetail(
  id: '1',
  name: 'Test',
  classes: [
    CharacterDetailClassRow(
      classId: 1,
      className: className,
      subclassName: subclass,
      level: 3,
      isPrimary: true,
      savingThrowProficiencies: const [],
      hitDie: 8,
    ),
  ],
  xp: 0,
  currentHp: 10,
  maxHp: 10,
  temporaryHp: 0,
  abilityScores: const {},
  spellSlots: slots,
);

Future<void> _pump(
  WidgetTester tester,
  CharacterDetail detail, {
  String locale = 'fr',
}) async {
  tester.view.physicalSize = const Size(320, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale(locale),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: CharacterSpellsTabBody(
            detail: detail,
            onCastSpell: (_, _) {},
            onTogglePrepared: (_) {},
            onUseFeature: (_) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final locale in const ['fr', 'en']) {
    final nonCaster = locale == 'fr' ? _frNonCaster : _enNonCaster;
    final unsupported = locale == 'fr' ? _frUnsupported : _enUnsupported;

    group('onglet Sorts ($locale, 320 dp, texte x2)', () {
      testWidgets('Chevalier occulte : message honnête', (tester) async {
        await _pump(
          tester,
          _detail('Guerrier', subclass: 'Chevalier occulte'),
          locale: locale,
        );
        expect(find.text(unsupported), findsOneWidget);
        expect(find.text(nonCaster), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Escroc arcanique : message honnête', (tester) async {
        await _pump(
          tester,
          _detail('Roublard', subclass: 'Escroc arcanique'),
          locale: locale,
        );
        expect(find.text(unsupported), findsOneWidget);
        expect(find.text(nonCaster), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Chevalier occulte AVEC emplacements : onglet normal, aucun '
          'des deux messages', (tester) async {
        await _pump(
          tester,
          _detail(
            'Guerrier',
            subclass: 'Chevalier occulte',
            slots: const [CharacterSpellSlot(level: 1, total: 2, used: 0)],
          ),
          locale: locale,
        );
        expect(find.text(unsupported), findsNothing);
        expect(find.text(nonCaster), findsNothing);
        expect(find.byType(SpellSlotDots), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Barbare : message non-lanceur inchangé', (tester) async {
        await _pump(tester, _detail('Barbare'), locale: locale);
        expect(find.text(nonCaster), findsOneWidget);
        expect(find.text(unsupported), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Guerrier Champion : message non-lanceur inchangé', (
        tester,
      ) async {
        await _pump(
          tester,
          _detail('Guerrier', subclass: 'Champion'),
          locale: locale,
        );
        expect(find.text(nonCaster), findsOneWidget);
        expect(find.text(unsupported), findsNothing);
      });

      testWidgets('lanceur géré (Magicien) : onglet normal, aucun des deux '
          'messages', (tester) async {
        await _pump(
          tester,
          _detail(
            'Magicien',
            slots: const [CharacterSpellSlot(level: 1, total: 2, used: 0)],
          ),
          locale: locale,
        );
        expect(find.text(nonCaster), findsNothing);
        expect(find.text(unsupported), findsNothing);
      });
    });
  }
}
