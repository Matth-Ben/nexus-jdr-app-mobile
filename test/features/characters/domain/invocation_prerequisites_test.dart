import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/invocation_prerequisites.dart';
import 'package:personnages/features/characters/domain/level_up_invocation_option.dart';
import 'package:personnages/features/characters/domain/warlock_pact.dart';

const _eldritchBlast = 42;

bool _can(
  InvocationPrerequisites prerequisites, {
  int level = 3,
  WarlockPact? pact,
  Set<int> cantrips = const {},
}) => prerequisites.canSelect(
  warlockLevel: level,
  knownPact: pact,
  knownCantripSpellIds: cantrips,
);

void main() {
  group('InvocationPrerequisites.fromJson', () {
    test('lit level, pact et cantrip_spell_id', () {
      final prerequisites = InvocationPrerequisites.fromJson({
        'text': 'Pacte de la lame, niveau 5',
        'level': 5,
        'pact': 'lame',
        'cantrip_spell_id': _eldritchBlast,
      });
      expect(prerequisites.level, 5);
      expect(prerequisites.pact, WarlockPact.blade);
      expect(prerequisites.cantripSpellId, _eldritchBlast);
      expect(prerequisites.isEmpty, isFalse);
    });

    test('accepte les 3 pactes', () {
      expect(
        InvocationPrerequisites.fromJson({'pact': 'chaine'}).pact,
        WarlockPact.chain,
      );
      expect(
        InvocationPrerequisites.fromJson({'pact': 'lame'}).pact,
        WarlockPact.blade,
      );
      expect(
        InvocationPrerequisites.fromJson({'pact': 'grimoire'}).pact,
        WarlockPact.tome,
      );
    });

    test('clés absentes -> aucune contrainte', () {
      expect(
        InvocationPrerequisites.fromJson({'text': 'Niveau 5'}).isEmpty,
        isTrue,
      );
      expect(InvocationPrerequisites.fromJson(const {}).isEmpty, isTrue);
    });

    test('null ou type inattendu -> aucune contrainte', () {
      expect(InvocationPrerequisites.fromJson(null).isEmpty, isTrue);
      expect(InvocationPrerequisites.fromJson('lame').isEmpty, isTrue);
      expect(InvocationPrerequisites.fromJson(<int>[1]).isEmpty, isTrue);
    });

    test(
      'clés invalides ignorées (mauvais type, pacte inconnu, niveau <= 0)',
      () {
        final prerequisites = InvocationPrerequisites.fromJson({
          'level': 'douze',
          'pact': 'epee',
          'cantrip_spell_id': '42',
        });
        expect(prerequisites.isEmpty, isTrue);
        expect(InvocationPrerequisites.fromJson({'level': 0}).isEmpty, isTrue);
        expect(InvocationPrerequisites.fromJson({'pact': 3}).isEmpty, isTrue);
      },
    );

    test('accepte un niveau ou un id décimal (jsonb numérique)', () {
      final prerequisites = InvocationPrerequisites.fromJson({
        'level': 5.0,
        'cantrip_spell_id': 42.0,
      });
      expect(prerequisites.level, 5);
      expect(prerequisites.cantripSpellId, 42);
    });
  });

  group('InvocationPrerequisites.canSelect', () {
    test('sans contrainte : toujours éligible', () {
      expect(_can(InvocationPrerequisites.none, level: 2), isTrue);
    });

    test('niveau : éligible à égalité, inéligible en dessous', () {
      const prerequisites = InvocationPrerequisites(level: 5);
      expect(_can(prerequisites, level: 4), isFalse);
      expect(_can(prerequisites, level: 5), isTrue);
      expect(_can(prerequisites, level: 12), isTrue);
    });

    test('pacte : exige exactement le pacte requis', () {
      const prerequisites = InvocationPrerequisites(pact: WarlockPact.blade);
      expect(_can(prerequisites), isFalse);
      expect(_can(prerequisites, pact: WarlockPact.chain), isFalse);
      expect(_can(prerequisites, pact: WarlockPact.blade), isTrue);
    });

    test('sort mineur : exige le sort mineur connu', () {
      const prerequisites = InvocationPrerequisites(
        cantripSpellId: _eldritchBlast,
      );
      expect(_can(prerequisites), isFalse);
      expect(_can(prerequisites, cantrips: {1, 2}), isFalse);
      expect(_can(prerequisites, cantrips: {1, _eldritchBlast}), isTrue);
    });

    test('combinaison : tous les prérequis doivent être satisfaits', () {
      const prerequisites = InvocationPrerequisites(
        level: 5,
        pact: WarlockPact.tome,
        cantripSpellId: _eldritchBlast,
      );
      expect(
        _can(
          prerequisites,
          level: 5,
          pact: WarlockPact.tome,
          cantrips: {_eldritchBlast},
        ),
        isTrue,
      );
      expect(
        _can(
          prerequisites,
          level: 4,
          pact: WarlockPact.tome,
          cantrips: {_eldritchBlast},
        ),
        isFalse,
      );
      expect(
        _can(prerequisites, pact: WarlockPact.tome, cantrips: {1}),
        isFalse,
      );
      expect(_can(prerequisites, cantrips: {_eldritchBlast}), isFalse);
    });

    test('unmet liste chaque prérequis manquant, dans l ordre', () {
      const prerequisites = InvocationPrerequisites(
        level: 12,
        pact: WarlockPact.blade,
        cantripSpellId: _eldritchBlast,
      );
      expect(
        prerequisites.unmet(
          warlockLevel: 5,
          knownPact: null,
          knownCantripSpellIds: const {},
        ),
        [
          InvocationPrerequisiteFailure.level,
          InvocationPrerequisiteFailure.pact,
          InvocationPrerequisiteFailure.cantrip,
        ],
      );
    });
  });

  group('LevelUpInvocationOption.eligibilityFor', () {
    LevelUpInvocationOption option(
      InvocationPrerequisites prerequisites, {
      String? cantripName,
    }) => LevelUpInvocationOption(
      id: 1,
      name: 'Test',
      description: '',
      prerequisites: prerequisites,
      cantripName: cantripName,
    );

    InvocationEligibility eligibility(
      LevelUpInvocationOption option, {
      int level = 3,
      WarlockPact? pact,
      Set<int> cantrips = const {},
    }) => option.eligibilityFor(
      warlockLevel: level,
      knownPact: pact,
      knownCantripSpellIds: cantrips,
    );

    test('éligible : pas de raison', () {
      final result = eligibility(option(InvocationPrerequisites.none));
      expect(result.isEligible, isTrue);
      expect(result.reasonLabel, isNull);
    });

    test('raison niveau', () {
      final result = eligibility(
        option(const InvocationPrerequisites(level: 12)),
      );
      expect(result.isEligible, isFalse);
      expect(result.reasons, ['Niveau 12 requis']);
    });

    test('raison pacte', () {
      final result = eligibility(
        option(const InvocationPrerequisites(pact: WarlockPact.blade)),
      );
      expect(result.reasons, ['Pacte de la lame requis']);
    });

    test('raison sort mineur avec nom', () {
      final result = eligibility(
        option(
          const InvocationPrerequisites(cantripSpellId: _eldritchBlast),
          cantripName: 'Décharge occulte',
        ),
      );
      expect(result.reasons, ['Sort mineur Décharge occulte requis']);
    });

    test('raison sort mineur sans nom résolu : libellé générique', () {
      final result = eligibility(
        option(const InvocationPrerequisites(cantripSpellId: _eldritchBlast)),
      );
      expect(result.reasons, ['Sort mineur requis']);
    });

    test('plusieurs raisons jointes', () {
      final result = eligibility(
        option(const InvocationPrerequisites(level: 5, pact: WarlockPact.tome)),
      );
      expect(result.reasons, ['Niveau 5 requis', 'Pacte du grimoire requis']);
      expect(result.reasonLabel, 'Niveau 5 requis · Pacte du grimoire requis');
    });
  });
}
