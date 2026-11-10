/// Les 14 conditions D&D 5e (édition 2014) que la fiche peut marquer comme
/// actives (P6, décision de Matthias du 10/11/2026). L'épuisement est exclu.
///
/// Purement **informatif** : aucune condition ne modifie jamais un calcul de
/// l'app (CA, jets, vitesse...). Persisté dans `characters.conditions`
/// (`jsonb not null default '[]'`, tableau JSON de [storageKey]).
///
/// L'ordre de déclaration est l'ordre canonique de stockage ; l'ordre
/// d'affichage est, lui, alphabétique du libellé localisé (voir
/// `presentation/widgets/condition_texts.dart`), jamais celui de la clé.
enum ConditionType {
  blinded('blinded'),
  charmed('charmed'),
  deafened('deafened'),
  frightened('frightened'),
  grappled('grappled'),
  incapacitated('incapacitated'),
  invisible('invisible'),
  paralyzed('paralyzed'),
  petrified('petrified'),
  poisoned('poisoned'),
  prone('prone'),
  restrained('restrained'),
  stunned('stunned'),
  unconscious('unconscious');

  const ConditionType(this.storageKey);

  /// Clé serveur stable (anglais, minuscules) — ne jamais la traduire.
  final String storageKey;

  /// `null` pour une clé inconnue (ex. condition ajoutée par une version
  /// plus récente de l'app web).
  static ConditionType? fromStorageKey(String key) {
    for (final type in values) {
      if (type.storageKey == key) return type;
    }
    return null;
  }

  /// Lit la valeur brute de `characters.conditions` de façon **tolérante** :
  /// `null`, non-liste, éléments non-texte ou clés inconnues sont ignorés
  /// (jamais d'exception — une base ou un cache qui n'a pas la colonne donne
  /// simplement une liste vide). Résultat dédoublonné, en ordre canonique.
  static List<ConditionType> parse(Object? raw) {
    if (raw is! List) return const [];
    final found = <ConditionType>{};
    for (final element in raw) {
      if (element is! String) continue;
      final type = fromStorageKey(element);
      if (type != null) found.add(type);
    }
    return canonical(found);
  }

  /// Clés **non reconnues** de la valeur brute (texte, dédoublonnées, ordre
  /// d'apparition) : à réinjecter à l'écriture pour ne pas supprimer une
  /// condition stockée par une version plus récente de l'app.
  static List<String> unknownKeys(Object? raw) {
    if (raw is! List) return const [];
    final found = <String>[];
    for (final element in raw) {
      if (element is String &&
          fromStorageKey(element) == null &&
          !found.contains(element)) {
        found.add(element);
      }
    }
    return found;
  }

  /// [conditions] dédoublonnées, en ordre canonique (ordre de déclaration).
  static List<ConditionType> canonical(Iterable<ConditionType> conditions) {
    final set = conditions.toSet();
    return [
      for (final type in values)
        if (set.contains(type)) type,
    ];
  }

  /// Valeur JSON à écrire dans `characters.conditions` (remplacement complet
  /// du tableau).
  ///
  /// [unknownKeys] (clés non reconnues lues précédemment) sont conservées
  /// après les clés connues, sans doublon.
  static List<String> toStorage(
    Iterable<ConditionType> conditions, {
    Iterable<String> unknownKeys = const [],
  }) {
    final keys = [for (final type in canonical(conditions)) type.storageKey];
    for (final key in unknownKeys) {
      if (fromStorageKey(key) == null && !keys.contains(key)) keys.add(key);
    }
    return keys;
  }
}
