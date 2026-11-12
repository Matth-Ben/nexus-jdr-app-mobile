// Maîtrise d'armure (P10) d'une armure/d'un bouclier PERSONNALISÉ (P7, PR 3) :
// évalué seulement si le type et la catégorie sont renseignés, sinon unknown.

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/armor_proficiency_rules.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
import 'package:personnages/features/characters/domain/custom_armor_properties.dart';
import 'package:personnages/features/characters/domain/custom_item_enrichment.dart';

CharacterInventoryItem _custom({
  required String kind,
  int? acBase = 12,
  String? category,
}) => CharacterInventoryItem(
  id: 'custom',
  name: 'Maison',
  quantity: 1,
  equipped: true,
  customKind: kind,
  customAcBase: acBase,
  customArmorCategory: category,
  armorProperties: customArmorPropertiesOf(
    kind: kind,
    acBase: acBase,
    armorCategory: category,
  ),
);

ArmorProficiencyProfile _profile(List<String> tokens) =>
    ArmorProficiencyProfile(
      tokens: tokens,
      classes: const [
        ArmorProficiencyClassLevel(className: 'Guerrier', level: 1),
      ],
    );

void main() {
  const y = ArmorProficiency.proficient;
  const n = ArmorProficiency.notProficient;
  const u = ArmorProficiency.unknown;

  final light = _custom(
    kind: CustomItemKinds.armor,
    category: CustomArmorCategories.light,
  );
  final medium = _custom(
    kind: CustomItemKinds.armor,
    category: CustomArmorCategories.medium,
  );
  final heavy = _custom(
    kind: CustomItemKinds.armor,
    category: CustomArmorCategories.heavy,
  );
  final shield = _custom(kind: CustomItemKinds.shield, acBase: 2);

  List<ArmorProficiency> row(ArmorProficiencyProfile profile) => [
    ArmorProficiencyRules.evaluate(light, profile),
    ArmorProficiencyRules.evaluate(medium, profile),
    ArmorProficiencyRules.evaluate(heavy, profile),
    ArmorProficiencyRules.evaluate(shield, profile),
  ];

  test('catégorie renseignée : verdict selon les maîtrises de classe', () {
    expect(row(_profile(['légère'])), [y, n, n, n]);
    expect(row(_profile(['intermédiaire'])), [n, y, n, n]);
    expect(row(_profile(['lourde'])), [n, n, y, n]);
    expect(row(_profile(['boucliers'])), [n, n, n, y]);
    expect(row(_profile(['légère', 'intermédiaire', 'lourde', 'boucliers'])), [
      y,
      y,
      y,
      y,
    ]);
  });

  test('même résultat qu\'une armure du catalogue de même catégorie', () {
    CharacterInventoryItem catalog(String dex, {String category = 'armure'}) =>
        CharacterInventoryItem(
          id: 'c',
          itemId: 1,
          name: 'Catalogue',
          category: category,
          quantity: 1,
          equipped: true,
          armorProperties: CharacterInventoryArmorProperties(
            acBase: 12,
            acDexBonus: dex,
            stealthDisadvantage: false,
          ),
        );
    final profile = _profile(['intermédiaire']);
    expect([
      ArmorProficiencyRules.evaluate(catalog('illimite'), profile),
      ArmorProficiencyRules.evaluate(catalog('max_2'), profile),
      ArmorProficiencyRules.evaluate(catalog('aucun'), profile),
      ArmorProficiencyRules.evaluate(
        catalog('aucun', category: 'bouclier'),
        profile,
      ),
    ], row(profile));
  });

  test('armure sans catégorie ou sans CA : unknown, jamais deviné', () {
    final noCategory = _custom(kind: CustomItemKinds.armor);
    final noAc = _custom(
      kind: CustomItemKinds.armor,
      acBase: null,
      category: CustomArmorCategories.heavy,
    );
    final profile = _profile(const []);
    expect(ArmorProficiencyRules.evaluate(noCategory, profile), u);
    expect(ArmorProficiencyRules.evaluate(noAc, profile), u);
    expect(ArmorProficiencyRules.isNotProficient(noCategory, profile), isFalse);
  });

  test('arme ou objet « autre » personnalisé : unknown', () {
    final profile = _profile(const []);
    for (final kind in [CustomItemKinds.weapon, CustomItemKinds.other]) {
      expect(
        ArmorProficiencyRules.evaluate(
          _custom(kind: kind, category: CustomArmorCategories.heavy),
          profile,
        ),
        u,
        reason: kind,
      );
    }
  });

  test('profil non évaluable : unknown même avec une catégorie', () {
    expect(
      ArmorProficiencyRules.evaluate(
        heavy,
        const ArmorProficiencyProfile(canEvaluate: false),
      ),
      u,
    );
  });

  test('isNotProficient et isShield', () {
    final profile = _profile(['légère']);
    expect(ArmorProficiencyRules.isNotProficient(heavy, profile), isTrue);
    expect(ArmorProficiencyRules.isNotProficient(light, profile), isFalse);
    expect(ArmorProficiencyRules.isNotProficient(shield, profile), isTrue);
    expect(ArmorProficiencyRules.isShield(shield), isTrue);
    expect(ArmorProficiencyRules.isShield(heavy), isFalse);
  });

  test('un bouclier personnalisé est maîtrisé par le jeton « boucliers » '
      'même sans catégorie d\'armure', () {
    expect(ArmorProficiencyRules.evaluate(shield, _profile(['boucliers'])), y);
    expect(ArmorProficiencyRules.evaluate(shield, _profile(['lourde'])), n);
  });
}
