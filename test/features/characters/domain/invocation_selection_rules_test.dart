import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/invocation_prerequisites.dart';
import 'package:personnages/features/characters/domain/invocation_selection_rules.dart';
import 'package:personnages/features/characters/domain/level_up_invocation_option.dart';
import 'package:personnages/features/characters/domain/warlock_pact.dart';

LevelUpInvocationOption _option(
  int id, [
  InvocationPrerequisites prerequisites = InvocationPrerequisites.none,
]) => LevelUpInvocationOption(
  id: id,
  name: 'Invocation $id',
  description: '',
  prerequisites: prerequisites,
);

void main() {
  final free = _option(1);
  final level5 = _option(2, const InvocationPrerequisites(level: 5));
  final blade = _option(
    3,
    const InvocationPrerequisites(pact: WarlockPact.blade),
  );
  final blast = _option(4, const InvocationPrerequisites(cantripSpellId: 42));
  final all = [free, level5, blade, blast];

  List<Object> ids(List<LevelUpInvocationOption> options) => [
    for (final option in options) option.id,
  ];

  group('InvocationSelectionRules.eligibleOptions', () {
    test('niveau 3, aucun pacte, aucun sort mineur : seule la libre', () {
      final eligible = InvocationSelectionRules.eligibleOptions(
        all,
        warlockLevel: 3,
        knownPact: null,
        knownCantripSpellIds: const {},
      );
      expect(ids(eligible), [1]);
    });

    test('pacte de la lame choisi dans la même montée de niveau', () {
      final eligible = InvocationSelectionRules.eligibleOptions(
        all,
        warlockLevel: 3,
        knownPact: WarlockPact.blade,
        knownCantripSpellIds: const {},
      );
      expect(ids(eligible), [1, 3]);
    });

    test('tous les prérequis satisfaits : tout est éligible', () {
      final eligible = InvocationSelectionRules.eligibleOptions(
        all,
        warlockLevel: 5,
        knownPact: WarlockPact.blade,
        knownCantripSpellIds: const {42},
      );
      expect(ids(eligible), [1, 2, 3, 4]);
    });
  });

  group('InvocationSelectionRules.effectiveQuota', () {
    test('plafonné par le nombre d invocations éligibles', () {
      expect(
        InvocationSelectionRules.effectiveQuota(
          all,
          delta: 2,
          warlockLevel: 3,
          knownPact: null,
          knownCantripSpellIds: const {},
        ),
        1,
      );
    });

    test('plafonné par le delta RAW quand assez d éligibles', () {
      expect(
        InvocationSelectionRules.effectiveQuota(
          all,
          delta: 2,
          warlockLevel: 5,
          knownPact: WarlockPact.blade,
          knownCantripSpellIds: const {42},
        ),
        2,
      );
    });

    test('0 si aucune invocation éligible', () {
      expect(
        InvocationSelectionRules.effectiveQuota(
          [level5, blade],
          delta: 2,
          warlockLevel: 3,
          knownPact: null,
          knownCantripSpellIds: const {},
        ),
        0,
      );
    });
  });

  group('InvocationSelectionRules.pruneSelection', () {
    test('retire les invocations devenues inéligibles (pacte changé)', () {
      final pruned = InvocationSelectionRules.pruneSelection(
        ['1', '3'],
        all,
        quota: 2,
        warlockLevel: 3,
        knownPact: WarlockPact.chain,
        knownCantripSpellIds: const {},
      );
      expect(pruned, ['1']);
    });

    test('conserve la sélection tant qu elle reste éligible', () {
      final pruned = InvocationSelectionRules.pruneSelection(
        ['3', '1'],
        all,
        quota: 2,
        warlockLevel: 3,
        knownPact: WarlockPact.blade,
        knownCantripSpellIds: const {},
      );
      expect(pruned, ['3', '1']);
    });

    test('retire un sort mineur qui n est plus connu', () {
      final pruned = InvocationSelectionRules.pruneSelection(
        ['4'],
        all,
        quota: 1,
        warlockLevel: 3,
        knownPact: null,
        knownCantripSpellIds: const {},
      );
      expect(pruned, isEmpty);
    });

    test('ignore les identifiants inconnus et tronque au quota', () {
      final pruned = InvocationSelectionRules.pruneSelection(
        ['999', '1', '3'],
        all,
        quota: 1,
        warlockLevel: 3,
        knownPact: WarlockPact.blade,
        knownCantripSpellIds: const {},
      );
      expect(pruned, ['1']);
    });
  });
}
