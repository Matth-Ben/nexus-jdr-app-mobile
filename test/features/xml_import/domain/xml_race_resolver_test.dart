// Tests de la résolution race + sous-race du champ `<race>` d'un export XML
// (`lib/features/xml_import/domain/xml_race_resolver.dart`).

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/race_catalog.dart';
import 'package:personnages/features/character_creation/domain/race_option.dart';
import 'package:personnages/features/character_creation/domain/subrace_option.dart';
import 'package:personnages/features/xml_import/domain/xml_field_resolution.dart';
import 'package:personnages/features/xml_import/domain/xml_race_resolver.dart';

void main() {
  const elfe = RaceOption(
    id: 1,
    name: 'Elfe',
    abilityBonuses: {'dex': 2},
    traits: [],
    source: '',
  );
  const nain = RaceOption(
    id: 2,
    name: 'Nain',
    abilityBonuses: {'con': 2},
    traits: [],
    source: '',
  );
  const genasi = RaceOption(
    id: 3,
    name: 'Génasi',
    abilityBonuses: {'con': 2},
    traits: [],
    source: '',
  );
  const hautElfe = SubraceOption(
    id: 10,
    raceId: 1,
    name: 'Haut-elfe',
    abilityBonuses: {'int': 1},
    traits: [],
  );
  const drow = SubraceOption(
    id: 11,
    raceId: 1,
    name: 'Elfe noir (Drow)',
    abilityBonuses: {'cha': 1},
    traits: [],
  );
  const nainCollines = SubraceOption(
    id: 20,
    raceId: 2,
    name: 'Nain des collines',
    abilityBonuses: {'wis': 1},
    traits: [],
  );
  const genasiAir = SubraceOption(
    id: 30,
    raceId: 3,
    name: "Génasi de l'air",
    abilityBonuses: {'dex': 1},
    traits: [],
  );
  const catalog = RaceCatalog(
    races: [elfe, nain, genasi],
    subraces: [hautElfe, drow, nainCollines, genasiAir],
  );

  ({RaceOption? race, SubraceOption? subrace}) resolve(String raw) {
    final result = XmlRaceResolver.resolve(rawName: raw, catalog: catalog);
    return (
      race: switch (result.race) {
        XmlFieldResolutionRecognized<RaceOption>(:final value) => value,
        _ => null,
      },
      subrace: result.subrace,
    );
  }

  test('race seule', () {
    expect(resolve('Elfe'), (race: elfe, subrace: null));
    expect(resolve('nain'), (race: nain, subrace: null));
  });

  test('nom exact de sous-race (cas aidedd.org)', () {
    expect(resolve('Haut-elfe'), (race: elfe, subrace: hautElfe));
    expect(resolve('Nain des collines'), (race: nain, subrace: nainCollines));
    expect(resolve("Genasi de l'air"), (race: genasi, subrace: genasiAir));
  });

  test('alias de sous-race (parenthèses)', () {
    expect(resolve('Drow'), (race: elfe, subrace: drow));
    expect(resolve('Elfe noir'), (race: elfe, subrace: drow));
  });

  test('race et sous-race combinées', () {
    expect(resolve('Elfe (haut-elfe)'), (race: elfe, subrace: hautElfe));
    expect(resolve('Elfe, haut'), (race: elfe, subrace: hautElfe));
    expect(resolve('Elfe — Haut-elfe'), (race: elfe, subrace: hautElfe));
    expect(resolve('Nain — Nain des collines'), (
      race: nain,
      subrace: nainCollines,
    ));
  });

  test('mot étranger : pas de sous-race devinée, race non reconnue', () {
    expect(resolve('Elfe des mers lointaines'), (race: null, subrace: null));
    expect(resolve('Race Maison'), (race: null, subrace: null));
    expect(resolve(''), (race: null, subrace: null));
  });

  test('labelOf', () {
    expect(XmlRaceResolver.labelOf(elfe, null), 'Elfe');
    expect(XmlRaceResolver.labelOf(elfe, hautElfe), 'Elfe — Haut-elfe');
  });
}
