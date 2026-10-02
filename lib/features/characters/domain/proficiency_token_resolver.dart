import 'armor_proficiency_category.dart';
import 'druid_non_metallic_equipment.dart';
import 'pact_weapon_rules.dart';
import 'proficiency_catalog.dart';
import 'proficiency_token_detail.dart';
import 'weapon_proficiency_category_rules.dart';

/// Espace de tokens dont relève un token brut de maîtrise (`classes
/// .weapon_proficiencies`/`classes.armor_proficiencies`) — distingue les deux
/// vocabulaires (ex. `'courantes'` n'a aucun sens pour une armure) côté appel
/// de `ProficiencyTokenResolver`/`showProficiencyDetailPanel`.
enum ProficiencyTokenKind { weapon, armor }

/// Résout un token brut de maîtrise (voir la doc de classe de
/// `CharacterWeaponProficienciesCard`) en ce qu'il recouvre concrètement
/// dans le catalogue — logique pure, aucun accès réseau (voir
/// `ProficiencyCatalogRepository` pour le chargement du catalogue).
///
/// Deux formes de token, pour les deux vocabulaires :
/// - [resolveWeapon] : `'courantes'`/`'martiales'` (classification RAW, voir
///   `WeaponProficiencyCategoryRules`) ou un nom déjà spécifique (ex.
///   `'dagues'`, recherché par nom normalisé/singularisé dans [weapons]).
/// - [resolveArmor] : `'légère'`/`'intermédiaire'`/`'lourde'`/`'boucliers'`
///   (dérivé de `ac_dex_bonus`, voir `ArmorProficiencyCategoryRules`) ou les
///   deux variantes "non métallique(s)" du Druide (voir
///   `DruidNonMetallicEquipment`) ; un nom déjà spécifique retombe sur le
///   même mécanisme de recherche par nom que [resolveWeapon] (défensif : le
///   vocabulaire `classes.armor_proficiencies` fourni par le chef de projet
///   ne contient aucun exemple de ce cas, contrairement aux armes).
abstract final class ProficiencyTokenResolver {
  static ProficiencyTokenDetail resolveWeapon({
    required String token,
    required List<ProficiencyCatalogWeapon> weapons,
  }) {
    final normalized = PactWeaponRules.normalize(token);
    switch (normalized) {
      case 'courantes':
        return ProficiencyTokenDetail(
          weapons: _sortedWeapons(
            weapons.where(
              (w) => WeaponProficiencyCategoryRules.isCommon(w.name),
            ),
          ),
        );
      case 'martiales':
        return ProficiencyTokenDetail(
          weapons: _sortedWeapons(
            weapons.where(
              (w) => WeaponProficiencyCategoryRules.isMartial(w.name),
            ),
          ),
        );
      default:
        return ProficiencyTokenDetail(
          weapons: _sortedWeapons(
            weapons.where((w) => _matchesSpecificName(w.name, token)),
          ),
        );
    }
  }

  static ProficiencyTokenDetail resolveArmor({
    required String token,
    required List<ProficiencyCatalogArmor> armors,
    required List<ProficiencyCatalogArmor> shields,
  }) {
    final normalized = PactWeaponRules.normalize(token);
    switch (normalized) {
      case 'legere':
        return ProficiencyTokenDetail(
          armors: _byCategory(armors, ArmorProficiencyCategory.legere),
        );
      case 'intermediaire':
        return ProficiencyTokenDetail(
          armors: _byCategory(armors, ArmorProficiencyCategory.intermediaire),
        );
      case 'lourde':
        return ProficiencyTokenDetail(
          armors: _byCategory(armors, ArmorProficiencyCategory.lourde),
        );
      case 'boucliers':
        return ProficiencyTokenDetail(armors: _sortedArmors(shields));
      case 'intermediaire (non metallique)':
        return ProficiencyTokenDetail(
          armors: _sortedArmors(
            _byCategory(armors, ArmorProficiencyCategory.intermediaire).where(
              (a) => DruidNonMetallicEquipment.isNonMetallicArmor(a.name),
            ),
          ),
        );
      case 'boucliers (non metalliques)':
        return ProficiencyTokenDetail(
          armors: _sortedArmors(
            shields.where(
              (s) => DruidNonMetallicEquipment.isNonMetallicShield(s.name),
            ),
          ),
        );
      default:
        return ProficiencyTokenDetail(
          armors: _sortedArmors([
            ...armors.where((a) => _matchesSpecificName(a.name, token)),
            ...shields.where((s) => _matchesSpecificName(s.name, token)),
          ]),
        );
    }
  }

  static List<ProficiencyCatalogArmor> _byCategory(
    List<ProficiencyCatalogArmor> armors,
    ArmorProficiencyCategory category,
  ) => _sortedArmors(
    armors.where(
      (a) =>
          ArmorProficiencyCategoryRules.categoryFor(a.acDexBonus) == category,
    ),
  );

  static List<ProficiencyCatalogWeapon> _sortedWeapons(
    Iterable<ProficiencyCatalogWeapon> weapons,
  ) {
    final sorted = weapons.toList();
    sorted.sort(
      (a, b) =>
          PactWeaponRules.normalize(a.name)
              .compareTo(PactWeaponRules.normalize(b.name)),
    );
    return sorted;
  }

  static List<ProficiencyCatalogArmor> _sortedArmors(
    Iterable<ProficiencyCatalogArmor> armors,
  ) {
    final sorted = armors.toList();
    sorted.sort(
      (a, b) =>
          PactWeaponRules.normalize(a.name)
              .compareTo(PactWeaponRules.normalize(b.name)),
    );
    return sorted;
  }

  /// Comparaison insensible à la casse/accents ET au singulier/pluriel,
  /// mot par mot — gère le pluriel régulier (« s » terminal, ex. le token
  /// `'dagues'` matche l'objet de catalogue `'Dague'`, `'épées courtes'`
  /// matche `'Épée courte'`) ET le pluriel en « -x » des noms français en
  /// « -eu »/« -eau »/« -ou » (ex. le token `'épieux'` — vu tel quel dans
  /// `classes.weapon_proficiencies` du Druide — matche `'Épieu'`). Couvre
  /// le vocabulaire RAW fourni par le chef de projet ; ne prétend pas gérer
  /// la pluralisation française générale (une irrégularité totalement
  /// différente, ex. 'cheval'/'chevaux', n'a pas de sens pour un nom
  /// d'arme/armure du catalogue actuel).
  static bool _matchesSpecificName(String catalogName, String token) {
    final normalizedCatalog = PactWeaponRules.normalize(catalogName);
    final normalizedToken = PactWeaponRules.normalize(token);
    if (normalizedCatalog == normalizedToken) return true;
    return _singularized(normalizedCatalog) == _singularized(normalizedToken);
  }

  static String _singularized(String normalized) =>
      normalized.split(' ').map(_singularizedWord).join(' ');

  static String _singularizedWord(String word) {
    if (word.length <= 1) return word;
    if (word.endsWith('x')) return word.substring(0, word.length - 1);
    if (word.endsWith('s')) return word.substring(0, word.length - 1);
    return word;
  }
}
