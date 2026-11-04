// Tests de widget du lancer d'un sort via la magie de pacte de l'Occultiste
// depuis la fiche (`character_detail_screen.dart::_castPactSpell`) — gap
// comblé par `qa-testeur` : `characterDetailCastPactSpellSuccessMessage`
// n'avait jusqu'ici aucun test, ni en français ni en anglais (confirmé par
// `git log -S`). Ce fichier couvre seulement ce message de succès ; la
// course avec un repos sur ce même flux est déjà couverte par
// `character_detail_rest_stale_pact_slot_test.dart`, et la sélection de
// l'emplacement de pacte dans la sheet de choix par `spell_info_panel_test
// .dart` — aucun des deux n'exerce ce message.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/rules/spell_status.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/character_spell_slot.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:personnages/features/characters/presentation/character_detail_screen.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/l10n/app_localizations.dart';

/// Occultiste "pur" : aucun emplacement classique, seulement le pool de
/// pacte (voir `SpellSlotProgression.slotsForLevel` pour cette classe) —
/// unique emplacement éligible pour le sort ci-dessous, donc `castSpellFlow`
/// appelle directement `onCastSpell` sans ouvrir de sheet de choix.
const _detail = CharacterDetail(
  id: '1',
  name: 'Test',
  classes: [
    CharacterDetailClassRow(
      classId: 1,
      hitDie: 8,
      className: 'Occultiste',
      level: 3,
      isPrimary: true,
      savingThrowProficiencies: [],
    ),
  ],
  xp: 0,
  currentHp: 18,
  maxHp: 24,
  temporaryHp: 0,
  abilityScores: {},
  spells: [
    CharacterSpellEntry(
      id: 1,
      name: 'Rayon de givre',
      level: 1,
      school: 'Évocation',
      status: SpellStatus.prepared,
    ),
  ],
  spellSlots: [],
  pactSpellSlot: CharacterSpellSlot(level: 2, total: 2, used: 0, isPact: true),
);

/// Seules les méthodes utiles à ces tests sont implémentées ; toute autre
/// échoue bruyamment via `noSuchMethod`.
class _FakeRepository implements CharacterRepository {
  _FakeRepository(this.current);

  CharacterDetail current;
  int castSpellCallCount = 0;
  bool? lastIsPactSlot;

  @override
  Future<CharacterDetail> fetchCharacterDetail(String characterId) async =>
      current;

  @override
  Future<WriteOutcome> castSpell({
    required String characterId,
    required int slotLevel,
    required int slotsUsed,
    bool isPactSlot = false,
  }) async {
    castSpellCallCount++;
    lastIsPactSlot = isPactSlot;
    current = current.copyWith(
      pactSpellSlot: CharacterSpellSlot(
        level: slotLevel,
        total: 2,
        used: slotsUsed,
        isPact: true,
      ),
    );
    return WriteOutcome.synced;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

Future<_FakeRepository> _pumpDetail(
  WidgetTester tester, {
  Locale locale = const Locale('fr'),
}) async {
  final repository = _FakeRepository(_detail);
  await tester.binding.setSurfaceSize(const Size(800, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [characterRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(
        // `CharacterDetailScreen` lit `AppLocalizations.of(context)!` dès
        // son premier `build()` (chantier "traduction de l'app" Phase B) :
        // sans ces delegates, l'appel renverrait `null` et le `!`
        // planterait. `fr` par défaut, `en` passé explicitement par le
        // groupe "locale anglaise" plus bas.
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
  return repository;
}

/// Ouvre l'onglet "Sorts"/"Spells", le panneau "Infos" du sort et tape
/// "Lancer"/"Cast" : unique emplacement éligible (le pool de pacte), donc
/// lancé directement sans sheet de choix intermédiaire.
Future<void> _castPactSpell(
  WidgetTester tester, {
  String tabLabel = 'SORTS',
  String castLabel = 'LANCER',
}) async {
  await tester.tap(find.text(tabLabel));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Rayon de givre'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(PrimaryButton, castLabel));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lancer avec le seul emplacement de pacte disponible : message '
      '« lancé (emplacement de pacte niveau N) » affiché', (tester) async {
    final repository = await _pumpDetail(tester);

    await _castPactSpell(tester);

    expect(repository.castSpellCallCount, 1);
    expect(repository.lastIsPactSlot, isTrue);
    expect(
      find.text('Rayon de givre lancé (emplacement de pacte niveau 2).'),
      findsOneWidget,
    );
  });

  group('locale anglaise', () {
    testWidgets(
      'lancer : message "cast (level N pact slot)" affiché en anglais',
      (tester) async {
        final repository = await _pumpDetail(
          tester,
          locale: const Locale('en'),
        );

        await _castPactSpell(tester, tabLabel: 'SPELLS', castLabel: 'CAST');

        expect(repository.castSpellCallCount, 1);
        expect(repository.lastIsPactSlot, isTrue);
        expect(
          find.text('Rayon de givre cast (level 2 pact slot).'),
          findsOneWidget,
        );
      },
    );
  });
}
