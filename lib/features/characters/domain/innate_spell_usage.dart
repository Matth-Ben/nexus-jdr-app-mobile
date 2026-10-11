import 'character_spell_entry.dart';
import 'class_feature_usage_formatter.dart';

/// Règles d'usage d'un sort inné « à charge » : tout sort au statut 'inné'
/// de niveau >= 1 (racial, ou venu d'un import XML) se lance sans
/// emplacement de sort, [usesPerLongRest] fois par repos long. Le compteur
/// stocké ([CharacterSpellEntry.innateUsesSpent]) est le nombre d'usages
/// DÉPENSÉS depuis le dernier repos long ; la fréquence, elle, n'est pas en
/// base : c'est la constante ci-dessous.
///
/// Un sort mineur inné (niveau 0) reste à volonté : aucune de ces règles ne
/// s'y applique.
abstract final class InnateSpellUsage {
  /// Nombre de lancers sans emplacement par repos long.
  static const int usesPerLongRest = 1;

  /// `true` pour un sort inné à charge : [CharacterSpellEntry.hasInnateRoute]
  /// ET niveau >= 1.
  ///
  /// Testé sur [CharacterSpellEntry.hasInnateRoute], PAS sur
  /// [CharacterSpellEntry.status] (D43 du registre de dette technique,
  /// `docs/dette-technique.md`) : un sort à la fois inné (trait racial) et
  /// connu/préparé (classe) a `status` égal au statut ordinaire (voir
  /// `data/character_spell_row_mapper.dart::parseStatuses`, qui fait
  /// toujours gagner la ligne ordinaire pour cette facette-là), mais garde
  /// malgré tout sa route innée gratuite, indépendante — `hasInnateRoute`
  /// reste vrai dans ce cas, contrairement à `status == SpellStatus.innate`
  /// avant ce correctif, qui aurait fait disparaître cette route dès qu'une
  /// ligne ordinaire du même sort existait.
  ///
  /// Un sort accordé par une sous-classe est toujours présenté 'préparé'
  /// (voir [CharacterSpellEntry.grantSource]) : même s'il a aussi une ligne
  /// 'inné' en base, il suit le circuit ordinaire (emplacement), jamais
  /// celui-ci — exclu explicitement ici (D44, hors périmètre de D43, pas
  /// implémenté : seule cette exclusion est nécessaire pour ne pas le
  /// casser).
  static bool isLimited(CharacterSpellEntry spell) =>
      spell.grantSource == null && spell.hasInnateRoute && spell.level >= 1;

  /// Usages restants avant le prochain repos long, jamais négatif (ni
  /// supérieur à [usesPerLongRest] : une valeur stockée aberrante est
  /// bornée).
  static int usesRemaining(CharacterSpellEntry spell) =>
      (usesPerLongRest - spell.innateUsesSpent).clamp(0, usesPerLongRest);

  /// `true` s'il reste au moins un usage — à n'interroger que pour un sort
  /// [isLimited].
  static bool hasUseAvailable(CharacterSpellEntry spell) =>
      usesRemaining(spell) > 0;

  /// Compteur « 1 / 1 · repos long » (ligne « Utilisations » du panneau
  /// « Infos ») — même format que les aptitudes de classe.
  static String usageLabel(CharacterSpellEntry spell) =>
      ClassFeatureUsageFormatter.formatCounts(
        remaining: usesRemaining(spell),
        usesMax: usesPerLongRest,
        restType: 'repos_long',
      );
}
