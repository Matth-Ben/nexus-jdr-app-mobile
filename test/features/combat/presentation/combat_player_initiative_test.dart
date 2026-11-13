// Écran Combat : saisie d'initiative par le joueur (sa seule ligne, d20, ligne
// absente, retiré, MJ absent, hors ligne, erreurs serveur).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/presentation/providers/character_detail_provider.dart';
import 'package:personnages/features/combat/domain/combat_enums.dart';
import 'package:personnages/features/combat/domain/combat_failure.dart';
import 'package:personnages/features/combat/domain/combat_snapshot.dart';

import '../../../support/combat_fixtures.dart';
import 'combat_test_harness.dart';

/// Fiche du joueur : Dextérité 16, soit un modificateur d'initiative de +3.
CharacterDetail _aria({int dex = 16}) => CharacterDetail(
  id: 'c-player',
  name: 'Aria',
  classes: const [],
  xp: 0,
  currentHp: 10,
  maxHp: 10,
  temporaryHp: 0,
  abilityScores: {'dex': dex},
  inventory: const [],
  spells: const [],
  classChoices: const [],
);

/// Lanceur de d20 factice : enregistre l'appel, renvoie [result].
class _Roller {
  int? result;
  final calls = <({String label, int modifier, String useLabel})>[];

  Future<int?> call(
    BuildContext context, {
    required String label,
    required int modifier,
    required String Function(int total) useResultLabel,
  }) async {
    calls.add((
      label: label,
      modifier: modifier,
      useLabel: useResultLabel(modifier + 10),
    ));
    return result;
  }
}

void main() {
  setUpAll(loadCombatFonts);

  /// Joueur : Aria (c-player) sans initiative, deux gobelins, Brun.
  List<Override> dexOverrides() => [
    characterDetailProvider('c-player').overrideWith((ref) async => _aria()),
  ];

  Future<CombatHarness> open(
    WidgetTester tester, {
    bool ariaHasInitiative = false,
    bool ariaRow = true,
    ParticipantStatus ariaStatus = ParticipantStatus.active,
    bool masterAbsent = false,
    _Roller? roller,
  }) async {
    final h = CombatHarness(
      detail: fakeGroupDetail(asPlayer: true, masterAbsent: masterAbsent),
      extraOverrides: dexOverrides(),
      rollOpener: roller?.call,
    );
    final roster = combatRoster();
    h.repo.snapshot = fakeSnapshot(
      participants: [
        for (final p in roster)
          if (p.id != 'aria')
            p
          else if (ariaRow)
            p.copyWith(
              initiative: ariaHasInitiative ? 18 : null,
              status: ariaStatus,
            ),
      ],
    );
    await h.pumpScreen(tester);
    return h;
  }

  Finder field() => find.byKey(const Key('combatInitiativeField'));

  group('sa seule ligne', () {
    testWidgets('kebab uniquement sur sa propre ligne, jamais sur les autres', (
      tester,
    ) async {
      await open(tester, ariaHasInitiative: true);
      expect(find.byKey(const Key('combatRowMenu-aria')), findsOneWidget);
      expect(find.byKey(const Key('combatRowMenu-gob1')), findsNothing);
      expect(find.byKey(const Key('combatRowMenu-gob2')), findsNothing);
      expect(find.byKey(const Key('combatRowMenu-brun')), findsNothing);
    });

    testWidgets('« Renseigner » seulement sur sa ligne (pas sur celle de '
        'Brun, sans initiative)', (tester) async {
      await open(tester);
      // Brun et Aria sont sans initiative : un seul « Renseigner », le sien.
      expect(find.text('Renseigner'), findsOneWidget);
      await tester.tap(find.text('Renseigner'));
      await tester.pumpAndSettle();
      expect(find.text('Initiative de Aria'), findsOneWidget);
    });

    testWidgets('le menu propose « Modifier mon initiative » (pas Retirer)', (
      tester,
    ) async {
      final h = await open(tester, ariaHasInitiative: true);
      await tester.tap(find.byKey(const Key('combatRowMenu-aria')));
      await tester.pumpAndSettle();
      expect(find.text('Modifier mon initiative'), findsOneWidget);
      expect(find.text('Retirer du combat'), findsNothing);
      expect(find.text('Éditer l\'initiative'), findsNothing);
      await tester.tap(find.text('Modifier mon initiative'));
      await tester.pumpAndSettle();
      // Valeur actuelle préremplie, puis corrigée et envoyée par la RPC joueur.
      expect(tester.widget<TextField>(field()).controller!.text, '18');
      await tester.enterText(field(), '12');
      await tester.pump();
      await tester.tap(find.text('ENREGISTRER'));
      await tester.pumpAndSettle();
      expect(h.repo.calls, ['mine:combat-1:12']);
    });

    testWidgets('« Enregistrer » désactivé hors -20..60, erreur affichée', (
      tester,
    ) async {
      final h = await open(tester);
      await tester.tap(find.text('Renseigner'));
      await tester.pumpAndSettle();
      PrimaryButton save() => tester.widget<PrimaryButton>(
        find.widgetWithText(PrimaryButton, 'ENREGISTRER'),
      );
      expect(save().onPressed, isNull);
      await tester.enterText(field(), '61');
      await tester.pump();
      expect(find.text('Entre -20 et 60'), findsOneWidget);
      expect(save().onPressed, isNull);
      await tester.enterText(field(), '-20');
      await tester.pump();
      expect(save().onPressed, isNotNull);
      await tester.tap(find.text('ENREGISTRER'));
      await tester.pumpAndSettle();
      expect(h.repo.calls, ['mine:combat-1:-20']);
    });

    testWidgets('le tap sur la ligne d\'un autre ne fait rien', (tester) async {
      final h = await open(tester, ariaHasInitiative: true);
      await tester.tap(find.text('Gobelin 1'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Initiative de'), findsNothing);
      expect(h.repo.calls, isEmpty);
    });
  });

  group('jet de d20', () {
    testWidgets('aide Dextérité, résultat repris, modifiable, annonce et '
        'focus', (tester) async {
      final roller = _Roller()..result = 17;
      final h = await open(tester, roller: roller);
      await tester.tap(find.text('Renseigner'));
      await tester.pumpAndSettle();
      expect(find.text('Dextérité : +3 → d20 + 3'), findsOneWidget);

      await tester.tap(find.text('Lancer un d20'.toUpperCase()));
      await tester.pumpAndSettle();
      expect(roller.calls.single.modifier, 3);
      expect(roller.calls.single.label, 'Initiative');
      expect(roller.calls.single.useLabel, 'Utiliser 13');
      expect(tester.widget<TextField>(field()).controller!.text, '17');
      expect(h.announcements, contains('Résultat repris : 17'));
      expect(tester.widget<TextField>(field()).focusNode!.hasFocus, isTrue);

      // Le champ reste modifiable (vrai dé lancé à la table).
      await tester.enterText(field(), '19');
      await tester.pump();
      await tester.tap(find.text('ENREGISTRER'));
      await tester.pumpAndSettle();
      expect(h.repo.calls, ['mine:combat-1:19']);
    });

    testWidgets('lanceur fermé sans résultat : le champ est inchangé', (
      tester,
    ) async {
      final roller = _Roller();
      final h = await open(tester, roller: roller);
      await tester.tap(find.text('Renseigner'));
      await tester.pumpAndSettle();
      await tester.enterText(field(), '8');
      await tester.pump();
      await tester.tap(find.text('LANCER UN D20'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field()).controller!.text, '8');
      expect(h.announcements, isEmpty);
    });

    testWidgets('modificateur négatif : aide avec le moins typographique', (
      tester,
    ) async {
      final h = CombatHarness(
        detail: fakeGroupDetail(asPlayer: true),
        extraOverrides: [
          characterDetailProvider('c-player')
              .overrideWith((ref) async => _aria(dex: 6)),
        ],
      );
      h.repo.snapshot = _ariaWithoutInitiative();
      await h.pumpScreen(tester);
      await tester.tap(find.text('Renseigner'));
      await tester.pumpAndSettle();
      expect(find.text('Dextérité : −2 → d20 − 2'), findsOneWidget);
    });

    testWidgets('MJ : d20 + 0 et aucune aide Dextérité', (tester) async {
      final roller = _Roller()..result = 11;
      final h = CombatHarness(rollOpener: roller.call);
      h.repo.snapshot = fakeSnapshot(participants: combatRoster());
      await h.pumpScreen(tester);
      await tester.tap(find.byKey(const Key('combatRowMenu-gob1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Éditer l\'initiative'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('combatDexHelp')), findsNothing);
      await tester.tap(find.text('LANCER UN D20'));
      await tester.pumpAndSettle();
      expect(roller.calls.single.modifier, 0);
      expect(tester.widget<TextField>(field()).controller!.text, '11');
      await tester.tap(find.text('ENREGISTRER'));
      await tester.pumpAndSettle();
      expect(h.repo.calls, ['set:gob1:11']);
    });

    testWidgets('fiche indisponible : pas de lanceur plutôt qu\'un '
        'modificateur faux', (tester) async {
      final h = CombatHarness(
        detail: fakeGroupDetail(asPlayer: true),
        extraOverrides: [
          characterDetailProvider('c-player')
              .overrideWith((ref) async => throw StateError('hors ligne')),
        ],
      );
      h.repo.snapshot = _ariaWithoutInitiative();
      await h.pumpScreen(tester);
      await tester.tap(find.text('Renseigner'));
      await tester.pumpAndSettle();
      expect(find.text('LANCER UN D20'), findsNothing);
      expect(find.byKey(const Key('combatDexHelp')), findsNothing);
      // La saisie manuelle reste possible.
      await tester.enterText(field(), '9');
      await tester.pump();
      await tester.tap(find.text('ENREGISTRER'));
      await tester.pumpAndSettle();
      expect(h.repo.calls, ['mine:combat-1:9']);
    });
  });

  group('ligne absente', () {
    testWidgets('« Renseigner mon initiative » depuis l\'écran, appel RPC', (
      tester,
    ) async {
      final h = await open(tester, ariaRow: false);
      expect(find.byKey(const Key('combatRowMenu-aria')), findsNothing);
      await tester.tap(find.byKey(const Key('combatFillMine')));
      await tester.pumpAndSettle();
      expect(find.text('Initiative de Aria'), findsOneWidget);
      await tester.enterText(field(), '14');
      await tester.pump();
      await tester.tap(find.text('ENREGISTRER'));
      await tester.pumpAndSettle();
      expect(h.repo.calls, ['mine:combat-1:14']);
    });

    testWidgets('pas d\'offre quand la ligne existe', (tester) async {
      await open(tester);
      expect(find.byKey(const Key('combatFillMine')), findsNothing);
    });

    testWidgets('le MJ ne voit jamais « Renseigner mon initiative »', (
      tester,
    ) async {
      final h = CombatHarness();
      h.repo.snapshot = fakeSnapshot(participants: combatRoster());
      await h.pumpScreen(tester);
      expect(find.byKey(const Key('combatFillMine')), findsNothing);
    });
  });

  group('retiré, MJ absent, hors ligne', () {
    testWidgets('joueur retiré : message clair, aucune action de saisie', (
      tester,
    ) async {
      await open(tester, ariaStatus: ParticipantStatus.removed);
      expect(
        find.text(
          "Le MJ t'a retiré de ce combat. Tu ne peux pas le rejoindre à nouveau.",
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('combatFillMine')), findsNothing);
      expect(find.byKey(const Key('combatRowMenu-aria')), findsNothing);
      expect(find.text('Renseigner'), findsNothing);
    });

    testWidgets('MJ absent : kebab désactivé avec l\'explication, aucun '
        'appel', (tester) async {
      final h = await open(tester, ariaHasInitiative: true, masterAbsent: true);
      final kebab = tester.widget<IconButton>(
        find.byKey(const Key('combatRowMenu-aria')),
      );
      expect(kebab.onPressed, isNull);
      expect(
        find.byTooltip('Le MJ n\'est plus dans le groupe : lecture seule.'),
        findsWidgets,
      );
      expect(h.repo.calls, isEmpty);
    });

    testWidgets('MJ absent, ligne absente : l\'offre est désactivée', (
      tester,
    ) async {
      await open(tester, ariaRow: false, masterAbsent: true);
      final button = tester.widget<PrimaryButton>(
        find.byKey(const Key('combatFillMine')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('hors ligne : « Renseigner » et kebab désactivés, jamais '
        'd\'écriture', (tester) async {
      final h = await open(tester);
      h.connectivity.goOffline();
      await tester.pumpAndSettle();
      final fill = tester.widget<InkWell>(
        find
            .descendant(
              of: find.ancestor(
                of: find.text('Renseigner'),
                matching: find.byType(Tooltip),
              ),
              matching: find.byType(InkWell),
            )
            .first,
      );
      expect(fill.onTap, isNull);
      expect(find.byTooltip('Indisponible hors ligne'), findsWidgets);
      expect(h.repo.calls, isEmpty);
    });

    testWidgets('hors ligne : kebab de sa ligne désactivé', (tester) async {
      final h = await open(tester, ariaHasInitiative: true);
      h.connectivity.goOffline();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('combatRowMenu-aria')))
            .onPressed,
        isNull,
      );
      expect(h.repo.calls, isEmpty);
    });
  });

  group('erreurs serveur localisées', () {
    Future<void> save(WidgetTester tester, CombatFailure failure) async {
      final h = await open(tester);
      h.repo.writeFailure = failure;
      await tester.tap(find.text('Renseigner'));
      await tester.pumpAndSettle();
      await tester.enterText(field(), '10');
      await tester.pump();
      await tester.tap(find.text('ENREGISTRER'));
      await tester.pumpAndSettle();
    }

    testWidgets('participant_removed : « Le MJ t\'a retiré »', (tester) async {
      await save(
        tester,
        const CombatFailure(CombatFailureKind.participantRemoved),
      );
      expect(
        find.text(
          "Le MJ t'a retiré de ce combat. Tu ne peux pas le rejoindre à nouveau.",
        ),
        findsOneWidget,
      );
    });

    testWidgets('gm_absent : l\'UI explique la lecture seule', (tester) async {
      await save(tester, const CombatFailure(CombatFailureKind.gmAbsent));
      expect(
        find.text("Le MJ n'est plus dans le groupe : lecture seule."),
        findsWidgets,
      );
    });

    testWidgets('combat_not_active', (tester) async {
      await save(
        tester,
        const CombatFailure(CombatFailureKind.combatNotActive),
      );
      expect(find.text('Ce combat est déjà terminé.'), findsOneWidget);
    });

    testWidgets('no_character', (tester) async {
      await save(tester, const CombatFailure(CombatFailureKind.noCharacter));
      expect(
        find.text(
          'Choisis un personnage dans ce groupe pour renseigner ton initiative.',
        ),
        findsOneWidget,
      );
    });
  });

  testWidgets('anglais : libellés de la saisie du joueur', (tester) async {
    final h = CombatHarness(
      detail: fakeGroupDetail(asPlayer: true),
      extraOverrides: dexOverrides(),
    )..locale = const Locale('en');
    h.repo.snapshot = fakeSnapshot(
      participants: [
        for (final p in combatRoster())
          if (p.id != 'aria') p,
      ],
    );
    await h.pumpScreen(tester);
    expect(find.byKey(const Key('combatFillMine')), findsOneWidget);
    expect(find.text('ENTER MY INITIATIVE'), findsOneWidget);
    await tester.tap(find.byKey(const Key('combatFillMine')));
    await tester.pumpAndSettle();
    expect(find.text('Dexterity: +3 → d20 + 3'), findsOneWidget);
    expect(find.text('ROLL A D20'), findsOneWidget);
  });
}

CombatSnapshot _ariaWithoutInitiative() => fakeSnapshot(
  participants: [
    for (final p in combatRoster())
      if (p.id == 'aria') p.copyWith(initiative: null) else p,
  ],
);
