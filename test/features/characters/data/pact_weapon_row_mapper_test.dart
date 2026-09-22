import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/data/pact_weapon_row_mapper.dart';

Map<String, dynamic> _item(
  int id, {
  String category = 'arme',
  Object? weapon,
}) => {'id': id, 'category': category, 'weapon_properties': weapon};

Map<String, dynamic> _weapon(
  String? dice,
  String? type, [
  List<String> properties = const [],
]) => {'damage_dice': dice, 'damage_type': type, 'properties': properties};

void main() {
  const names = {
    '1': 'Épée longue',
    '2': 'Arc court',
    '3': 'Dague',
    '4': 'Filet',
    '5': 'Armure',
  };

  test('toEligibleOptions filtre, mappe et trie', () {
    final options = PactWeaponRowMapper.toEligibleOptions([
      _item(1, weapon: _weapon('1d8', 'tranchant', ['polyvalente(1d10)'])),
      _item(
        2,
        weapon: _weapon('1d6', 'perforant', [
          'munitions(24/96)',
          'à deux mains',
        ]),
      ),
      _item(3, weapon: _weapon('1d4', 'perforant', ['finesse', 'légère'])),
      _item(4, weapon: _weapon(null, null)),
      _item(5, category: 'armure'),
    ], names: names);

    expect(options.map((o) => o.name), ['Dague', 'Épée longue']);
    expect(options.first.damageLabel, '1d4 perforant');
    expect(options.first.properties, ['finesse', 'légère']);
  });

  test('weapon_properties en liste à un élément est accepté', () {
    final option = PactWeaponRowMapper.toOption(
      _item(3, weapon: [_weapon('1d4', 'perforant')]),
      names: names,
    );
    expect(option!.damageDice, '1d4');
  });

  test('nom absent : libellé générique ; id absent : null', () {
    expect(
      PactWeaponRowMapper.toOption(_item(99), names: names)!.name,
      'Arme #99',
    );
    expect(
      PactWeaponRowMapper.toOption({'category': 'arme'}, names: names),
      isNull,
    );
  });

  test('collectIds normalise en String', () {
    expect(PactWeaponRowMapper.collectIds([_item(1), _item(2)]), {'1', '2'});
  });
}
