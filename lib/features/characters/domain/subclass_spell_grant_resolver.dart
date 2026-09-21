import 'spell_grant_source.dart';

/// Une ligne de `subclass_spells` : [spellId] est accordé par [subclassId]
/// dès que la classe concernée atteint [classLevel].
class SubclassSpellGrant {
  const SubclassSpellGrant({
    required this.subclassId,
    required this.spellId,
    required this.classLevel,
  });

  final int subclassId;
  final int spellId;

  /// Niveau de CLASSE (pas le niveau total du personnage) à partir duquel le
  /// sort est accordé.
  final int classLevel;
}

/// Sous-classe choisie par le personnage, avec le niveau de la classe à
/// laquelle elle appartient (`character_classes.level` de la ligne qui porte
/// ce `subclass_id`) — en multiclassage, jamais le niveau total.
class SubclassProgress {
  const SubclassProgress({
    required this.subclassId,
    required this.classLevel,
    required this.source,
  });

  final int subclassId;
  final int classLevel;
  final SpellGrantSource source;
}

/// Calcule les sorts "toujours préparés" d'un personnage à partir de sa/ses
/// sous-classe(s) et de `subclass_spells` — dérivation à la lecture, aucune
/// écriture dans `character_spells` (décision d'architecture du chef de
/// projet : rétroactif pour les personnages existants, cohérent avec la
/// montée de niveau et l'import).
abstract final class SubclassSpellGrantResolver {
  /// `{spell_id: origine}` des sorts accordés : pour chaque [progress], les
  /// [grants] de sa sous-classe dont `classLevel <= progress.classLevel`. Un
  /// même sort accordé par deux sous-classes (multiclassage) garde la
  /// première origine rencontrée. Vide si aucune sous-classe ou aucun
  /// sort accordé.
  static Map<int, SpellGrantSource> resolve({
    required List<SubclassProgress> progress,
    required List<SubclassSpellGrant> grants,
  }) {
    final result = <int, SpellGrantSource>{};
    for (final entry in progress) {
      for (final grant in grants) {
        if (grant.subclassId != entry.subclassId) continue;
        if (grant.classLevel > entry.classLevel) continue;
        result.putIfAbsent(grant.spellId, () => entry.source);
      }
    }
    return result;
  }
}
