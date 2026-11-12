// Le système de favoris de sorts a été retiré de l'app mobile (décision du
// 11/11/2026) : aucune étoile, aucune section ni aucun libellé « favori » sur
// l'onglet Sorts, quelle que soit la taille de police.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/rules/spell_status.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/presentation/widgets/character_spells_tab_body.dart';
import 'package:personnages/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('onglet Sorts sans favori à x$scale', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
              body: CharacterSpellsTabBody(
                detail: const CharacterDetail(
                  id: '1',
                  name: 'Test',
                  classes: [
                    CharacterDetailClassRow(
                      classId: 1,
                      className: 'Magicien',
                      level: 1,
                      isPrimary: true,
                      savingThrowProficiencies: [],
                      hitDie: 6,
                    ),
                  ],
                  xp: 0,
                  currentHp: 10,
                  maxHp: 10,
                  temporaryHp: 0,
                  abilityScores: {},
                  spells: [
                    CharacterSpellEntry(
                      id: 1,
                      name: 'Bouclier',
                      level: 1,
                      school: 'Abjuration',
                      status: SpellStatus.prepared,
                    ),
                  ],
                ),
                onCastSpell: (_, _) {},
                onTogglePrepared: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Bouclier'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsNothing);
      expect(find.byIcon(Icons.star_border), findsNothing);
      expect(find.byIcon(Icons.star_rounded), findsNothing);
      expect(
        find.textContaining(RegExp('favori', caseSensitive: false)),
        findsNothing,
      );
    });
  }
}
