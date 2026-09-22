/// Origine d'un sort "toujours préparé" accordé automatiquement par une
/// sous-classe (table `subclass_spells`, dérivé à la lecture — jamais écrit
/// dans `character_spells`, voir [SubclassSpellGrantResolver]).
enum SpellGrantSource {
  /// Sorts de domaine du Clerc.
  domain('Domaine'),

  /// Sorts de serment du Paladin.
  oath('Serment'),

  /// Toute autre classe qui accorderait un jour des sorts via une
  /// sous-classe (repli générique, aucune classe concernée à ce jour).
  subclass('Sous-classe');

  const SpellGrantSource(this.label);

  /// Libellé affiché (badge de la ligne de sort, sous-titre, panneau
  /// "Infos").
  final String label;

  /// Origine pour [className] (nom de classe FR déjà traduit) — `Clerc` ->
  /// [domain], `Paladin` -> [oath], toute autre classe -> [subclass].
  static SpellGrantSource forClassName(String className) {
    switch (className) {
      case 'Clerc':
        return SpellGrantSource.domain;
      case 'Paladin':
        return SpellGrantSource.oath;
      default:
        return SpellGrantSource.subclass;
    }
  }
}
