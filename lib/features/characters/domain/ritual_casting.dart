import '../../../core/rules/character_class.dart';
import '../../../core/rules/spell_status.dart';
import 'character_detail_class_row.dart';
import 'character_spell_entry.dart';
import 'spell_grant_source.dart';

/// Motif pour lequel un sort ne peut pas être lancé en rituel.
enum RitualIneligibility {
  /// Le sort n'est pas un rituel (`spells.ritual` faux ou inconnu).
  notRitual,

  /// Le sort n'est accessible que par une route innée (trait racial) : un
  /// sort inné ne se lance pas en rituel.
  innateOnly,

  /// Toutes les classes qui portent ce sort n'ont pas le lancer de rituel
  /// (Ensorceleur, Paladin, Rôdeur, Barbare, Moine, Guerrier, Roublard).
  classNoRitual,

  /// Clerc, Druide, Artificier : le sort n'est ni préparé ni toujours
  /// préparé (domaine, cercle...).
  notPrepared,

  /// L'origine du sort n'est rattachée à aucune classe du personnage qui
  /// puisse le connaître (donnée ancienne ou origine introuvable).
  notKnown,

  /// Occultiste : aucun rituel dans cette version (décision produit). La règle
  /// stricte passe par l'invocation « Livre des secrets antiques » et un
  /// livre des rituels, non modélisés ; le Pacte du grimoire ne donne que
  /// trois sorts mineurs. Quel que soit le pacte choisi.
  warlockNotModeled,
}

/// Résultat de [RitualCasting.evaluate].
class RitualEligibility {
  const RitualEligibility.eligible(this.viaClass)
    : reason = null,
      assert(viaClass != null, 'une classe porteuse est requise');

  const RitualEligibility.ineligible(RitualIneligibility this.reason)
    : viaClass = null;

  /// Motif de refus, `null` si le lancer en rituel est possible.
  final RitualIneligibility? reason;

  /// Classe par laquelle le rituel est possible, `null` si inéligible.
  final CharacterClass? viaClass;

  bool get isEligible => reason == null;

  @override
  bool operator ==(Object other) =>
      other is RitualEligibility &&
      other.reason == reason &&
      other.viaClass == viaClass;

  @override
  int get hashCode => Object.hash(reason, viaClass);

  @override
  String toString() => isEligible
      ? 'RitualEligibility.eligible($viaClass)'
      : 'RitualEligibility.ineligible($reason)';
}

/// Éligibilité au lancer en rituel (D&D 5e, règles 2014) — domaine pur,
/// indépendant du chrono et du combat. Prépare l'action « Lancer en rituel »
/// (lot C) ; n'en crée aucune.
///
/// Règle : le sort doit être un rituel (`spells.ritual`) et pas une route
/// innée seule. Puis, PAR classe porteuse du sort (multiclassage : classes de
/// `sourceClassIds`, jamais un jugement global) :
/// - Magicien : tout sort connu (son livre), même non préparé ;
/// - Clerc, Druide, Artificier : sort préparé ou toujours préparé (domaine,
///   cercle...) ;
/// - Barde : sort connu ;
/// - Occultiste : jamais dans cette version, quel que soit son pacte
///   ([RitualIneligibility.warlockNotModeled]) ;
/// - Ensorceleur, Paladin, Rôdeur, Barbare, Moine, Guerrier, Roublard (et
///   leurs sous-classes) : jamais.
///
/// Un sort est éligible dès qu'UNE classe porteuse l'autorise. Sinon le motif
/// retenu est le plus instructif (voir [_priority]) : un Clerc voit
/// « non préparé » plutôt que « classe sans rituel » issu d'une autre classe.
///
/// Hors périmètre (tracé en dette) : dons « Rituels magiques », Livre des
/// ombres et Livre des secrets antiques (Occultiste).
abstract final class RitualCasting {
  /// Éligibilité de [spell] pour un personnage de classes [classes].
  static RitualEligibility evaluate({
    required CharacterSpellEntry spell,
    required List<CharacterDetailClassRow> classes,
  }) {
    if (!spell.ritual) {
      return const RitualEligibility.ineligible(RitualIneligibility.notRitual);
    }
    // Statut 'inné' = aucune ligne ordinaire : route innée seule (une ligne
    // ordinaire concurrente l'emporte dans `parseStatuses`, voir D43).
    if (spell.status == SpellStatus.innate && spell.grantSource == null) {
      return const RitualEligibility.ineligible(RitualIneligibility.innateOnly);
    }

    final carriers = _carriers(spell, classes);
    if (carriers.isEmpty) {
      return const RitualEligibility.ineligible(RitualIneligibility.notKnown);
    }

    RitualIneligibility? best;
    for (final carrier in carriers) {
      final verdict = _verdictFor(carrier, spell);
      if (verdict == null) return RitualEligibility.eligible(carrier);
      if (best == null || _priority(verdict) > _priority(best)) best = verdict;
    }
    return RitualEligibility.ineligible(best!);
  }

  /// Classes du personnage qui portent [spell].
  static Set<CharacterClass> _carriers(
    CharacterSpellEntry spell,
    List<CharacterDetailClassRow> classes,
  ) {
    final rows = <CharacterClass, CharacterDetailClassRow>{};
    for (final row in classes) {
      final resolved =
          CharacterClass.fromId(row.classId) ??
          CharacterClass.fromFrenchName(row.className);
      if (resolved != null) rows[resolved] = row;
    }
    final carriers = <CharacterClass>{};
    for (final entry in rows.entries) {
      if (spell.sourceClassIds.contains(entry.key.id)) carriers.add(entry.key);
    }
    // Sort accordé : domaine -> Clerc, serment -> Paladin. Une autre
    // sous-classe ne désigne aucune classe ici (faux positif en
    // multiclassage) : seule `sourceClassIds` fait foi.
    switch (spell.grantSource) {
      case SpellGrantSource.domain:
        if (rows.containsKey(CharacterClass.cleric)) {
          carriers.add(CharacterClass.cleric);
        }
      case SpellGrantSource.oath:
        if (rows.containsKey(CharacterClass.paladin)) {
          carriers.add(CharacterClass.paladin);
        }
      case SpellGrantSource.subclass:
      case null:
        break;
    }
    // Origine inconnue (ligne ancienne sans `source_class_id`) : seul un
    // personnage à classe unique permet de conclure.
    if (carriers.isEmpty &&
        spell.sourceClassIds.isEmpty &&
        (spell.grantSource == null ||
            spell.grantSource == SpellGrantSource.subclass) &&
        rows.length == 1) {
      carriers.add(rows.keys.single);
    }
    return carriers;
  }

  /// `null` si [carrier] autorise le rituel, le motif de refus sinon.
  static RitualIneligibility? _verdictFor(
    CharacterClass carrier,
    CharacterSpellEntry spell,
  ) {
    switch (carrier) {
      case CharacterClass.wizard:
      case CharacterClass.bard:
        return null;
      case CharacterClass.cleric:
      case CharacterClass.druid:
      case CharacterClass.artificer:
        final prepared =
            spell.status == SpellStatus.prepared || spell.isAlwaysPrepared;
        return prepared ? null : RitualIneligibility.notPrepared;
      case CharacterClass.warlock:
        return RitualIneligibility.warlockNotModeled;
      case CharacterClass.sorcerer:
      case CharacterClass.paladin:
      case CharacterClass.ranger:
      case CharacterClass.barbarian:
      case CharacterClass.monk:
      case CharacterClass.fighter:
      case CharacterClass.rogue:
        return RitualIneligibility.classNoRitual;
    }
  }

  static int _priority(RitualIneligibility reason) => switch (reason) {
    RitualIneligibility.notPrepared => 4,
    RitualIneligibility.warlockNotModeled => 3,
    RitualIneligibility.notKnown => 2,
    RitualIneligibility.classNoRitual => 1,
    RitualIneligibility.notRitual || RitualIneligibility.innateOnly => 0,
  };
}
