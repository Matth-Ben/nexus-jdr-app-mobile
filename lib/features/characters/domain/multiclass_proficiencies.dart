/// Maîtrises accordées par le multiclassage RAW 5e (moins qu'un départ
/// normal dans la classe, voir le *Manuel des joueurs*).
///
/// [multiclassProficienciesFor] fournit des PHRASES complètes affichées UNE
/// FOIS au moment du multiclassage, dans l'étape "Aptitudes" de la montée de
/// niveau (`presentation/level_up_screen.dart`, bloc "Maîtrises de
/// multiclassage", spec direction-artistique section 3) — jamais persistées
/// ni reflétées ailleurs.
///
/// [multiclassArmorProficiencyTokensFor]/[multiclassWeaponProficiencyTokensFor]
/// fournissent au contraire des TOKENS nus (même vocabulaire que
/// `classes.armor_proficiencies`/`weapon_proficiencies`), utilisés pour
/// l'affichage permanent des cartes "MAÎTRISES D'ARMURES"/"MAÎTRISES
/// D'ARMES" de l'onglet "Compétences" (`data/character_detail_row_mapper.dart`,
/// `mergeArmorProficiencyNames`/`mergeWeaponProficiencyNames`) : ces deux
/// jeux de fonctions encodent la même règle RAW mais sous deux formes
/// distinctes, gardées séparées plutôt que dérivées l'une de l'autre pour ne
/// pas risquer de régression sur l'affichage ponctuel déjà en place.
///
/// Données fournies par le chef de projet, autoritaires : encodées telles
/// quelles ci-dessous, non re-vérifiées ici — même convention de clé (nom de
/// classe en français) que `domain/multiclass_prerequisites.dart`.
abstract final class MulticlassProficiencies {
  static const Map<String, List<String>> _proficienciesByClassName = {
    'Barbare': [
      'Maîtrise des boucliers',
      'Maîtrise des armes courantes et de guerre',
    ],
    'Barde': [
      'Maîtrise des armures légères',
      "Maîtrise d'une compétence au choix",
      "Maîtrise d'un instrument de musique au choix",
    ],
    'Clerc': [
      'Maîtrise des armures légères et intermédiaires',
      'Maîtrise des boucliers',
    ],
    'Druide': [
      'Maîtrise des armures légères et intermédiaires',
      'Maîtrise des boucliers',
    ],
    'Guerrier': [
      'Maîtrise des armures légères et intermédiaires',
      'Maîtrise des boucliers',
      'Maîtrise des armes courantes et de guerre',
    ],
    'Moine': ['Maîtrise des armes courantes', 'Maîtrise des épées courtes'],
    'Paladin': [
      'Maîtrise des armures légères et intermédiaires',
      'Maîtrise des boucliers',
      'Maîtrise des armes courantes et de guerre',
    ],
    'Rôdeur': [
      'Maîtrise des armures légères et intermédiaires',
      'Maîtrise des boucliers',
      'Maîtrise des armes courantes et de guerre',
      "Maîtrise d'une compétence au choix (liste du Rôdeur)",
    ],
    'Roublard': [
      'Maîtrise des armures légères',
      "Maîtrise d'une compétence au choix (liste du Roublard)",
      "Maîtrise des outils de voleur",
    ],
    // Aucune maîtrise de multiclassage (Ensorceleur/Magicien).
    'Ensorceleur': [],
    'Occultiste': [
      'Maîtrise des armures légères',
      'Maîtrise des armes courantes',
    ],
    'Magicien': [],
  };

  /// Libellés français à afficher tels quels (`GainRow.subtitle`), une entrée
  /// par ligne de maîtrise accordée par le multiclassage dans [className].
  /// Liste vide si [className] est absente de la table (classe sans aucune
  /// maîtrise de multiclassage, ou classe imprévue — traité identiquement,
  /// jamais d'exception).
  static List<String> multiclassProficienciesFor(String className) =>
      _proficienciesByClassName[className] ?? const [];

  /// Tokens d'armures accordés par le multiclassage dans [className] —
  /// utilisés pour fusionner les maîtrises d'armures de toutes les classes
  /// d'un personnage en une liste dédupliquée
  /// (`data/character_detail_row_mapper.dart`,
  /// `mergeArmorProficiencyNames`), carte "MAÎTRISES D'ARMURES" de l'onglet
  /// "Compétences" — contrairement à [multiclassProficienciesFor], jamais
  /// utilisées pour l'affichage ponctuel de l'étape "Aptitudes" de la montée
  /// de niveau.
  ///
  /// Chaque token doit matcher EXACTEMENT (dédup par égalité de chaîne) le
  /// token stocké pour cette classe dans `classes.armor_proficiencies` —
  /// **pas un vocabulaire uniforme entre classes** : le Druide en particulier
  /// stocke `'intermédiaire (non métallique)'`/`'boucliers (non
  /// métalliques)'` (vérifié en base), pas les tokens bruts `'intermédiaire'`/
  /// `'boucliers'` utilisés par les autres classes — reflet fidèle de la
  /// restriction RAW ("les druides ne portent pas d'armure ni de bouclier en
  /// métal"), qui s'applique aussi à un Druide multiclassé. Si un futur
  /// personnage cumule un Druide secondaire et une autre classe donnant le
  /// token brut `'intermédiaire'`/`'boucliers'`, les deux chips coexisteront
  /// sans fusionner (comportement voulu : ce sont deux maîtrises RAW
  /// distinctes, l'une restreinte au non-métallique, l'autre non).
  ///
  /// Volontairement plus restreint que `classes.armor_proficiencies` de la
  /// classe elle-même (RAW 5e : le multiclassage ne donne jamais l'armure
  /// lourde, ni les maîtrises complètes d'un départ normal dans la classe).
  static const Map<String, List<String>> _multiclassArmorTokensByClassName = {
    'Barbare': ['boucliers'],
    'Barde': ['légère'],
    'Clerc': ['légère', 'intermédiaire', 'boucliers'],
    'Druide': [
      'légère',
      'intermédiaire (non métallique)',
      'boucliers (non métalliques)',
    ],
    'Guerrier': ['légère', 'intermédiaire', 'boucliers'],
    'Moine': [],
    'Paladin': ['légère', 'intermédiaire', 'boucliers'],
    'Rôdeur': ['légère', 'intermédiaire', 'boucliers'],
    'Roublard': ['légère'],
    'Ensorceleur': [],
    'Occultiste': ['légère'],
    'Magicien': [],
  };

  /// Même principe que [_multiclassArmorTokensByClassName], pour
  /// `classes.weapon_proficiencies`.
  static const Map<String, List<String>> _multiclassWeaponTokensByClassName = {
    'Barbare': ['courantes', 'martiales'],
    'Barde': [],
    'Clerc': [],
    'Druide': [],
    'Guerrier': ['courantes', 'martiales'],
    'Moine': ['courantes', 'épées courtes'],
    'Paladin': ['courantes', 'martiales'],
    'Rôdeur': ['courantes', 'martiales'],
    'Roublard': [],
    'Ensorceleur': [],
    'Occultiste': ['courantes'],
    'Magicien': [],
  };

  /// Liste vide si [className] est absente de la table, même convention que
  /// [multiclassProficienciesFor].
  static List<String> multiclassArmorProficiencyTokensFor(String className) =>
      _multiclassArmorTokensByClassName[className] ?? const [];

  /// Même principe que [multiclassArmorProficiencyTokensFor], pour les
  /// maîtrises d'armes.
  static List<String> multiclassWeaponProficiencyTokensFor(String className) =>
      _multiclassWeaponTokensByClassName[className] ?? const [];
}
