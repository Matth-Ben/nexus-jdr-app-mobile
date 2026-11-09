// Tests de non-régression de `SpellSlotDots` (widget partagé : fiche, feuille
// de lancer, préparation des sorts) — pastilles pleines/vides, pacte,
// emplacements dépensés.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/features/characters/domain/character_spell_slot.dart';
import 'package:personnages/features/characters/presentation/widgets/character_spells_section.dart';
import 'package:personnages/l10n/app_localizations.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: Scaffold(body: child),
    ),
  );
}

Finder _dots() => find.descendant(
  of: find.byType(SpellSlotDots),
  matching: find.byType(Container),
);

int _filledWith(WidgetTester tester, Color color) => tester
    .widgetList<Container>(_dots())
    .where((c) => (c.decoration! as BoxDecoration).color == color)
    .length;

void main() {
  testWidgets('une pastille par emplacement, pleines = restants', (
    tester,
  ) async {
    await _pump(
      tester,
      const SpellSlotDots(
        slot: CharacterSpellSlot(level: 1, total: 4, used: 1),
      ),
    );

    expect(_dots(), findsNWidgets(4));
    expect(_filledWith(tester, AppColors.goldEnd), 3);
  });

  testWidgets('tout dépensé : pastilles toutes vides, étiquette 0 restants', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      const SpellSlotDots(
        slot: CharacterSpellSlot(level: 2, total: 2, used: 2),
      ),
    );

    expect(_dots(), findsNWidgets(2));
    expect(_filledWith(tester, AppColors.goldEnd), 0);
    expect(
      find.bySemanticsLabel('Emplacements de sorts : 0 restants sur 2'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('pacte : couleur de remplissage fournie et étiquette de '
      'pacte', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      const SpellSlotDots(
        slot: CharacterSpellSlot(level: 3, total: 2, used: 0, isPact: true),
        filledColor: AppColors.accentTeal,
      ),
    );

    expect(
      find.bySemanticsLabel(
        'Emplacements de pacte : 2 restants sur 2 (niveau 3)',
      ),
      findsOneWidget,
    );
    expect(_filledWith(tester, AppColors.accentTeal), 2);
    handle.dispose();
  });
}
