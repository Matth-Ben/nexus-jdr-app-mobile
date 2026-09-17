import 'package:freezed_annotation/freezed_annotation.dart';

part 'spell_option.freezed.dart';

/// Un sort sélectionnable à l'étape 6/9 "Sorts" de l'assistant de création
/// (`spells`, voir `docs/cahier-des-charges/02-modele-donnees.md`).
///
/// Ne porte volontairement que les champs affichés par la maquette réelle de
/// cette étape (carte de sort sobre, une seule ligne de méta "École ·
/// casting_time") : ni `range`/`duration`/`components`/`concentration`/
/// `ritual`/`source`, qui existent bien sur `spells` mais n'ont aucun usage à
/// cet écran — même principe que [LanguageOption.type] (gardé) mais ici les
/// colonnes non affichées ne sont même pas lues, pour ne pas faire porter à
/// ce modèle un usage futur hypothétique (fiche personnage/grimoire, pas
/// encore implémentés) qui redéfinira probablement son propre modèle dédié le
/// moment venu.
@freezed
abstract class SpellOption with _$SpellOption {
  const SpellOption._();

  const factory SpellOption({
    required int id,
    required String name,

    /// 0 = sort mineur ("cantrip"), 1 = sort de niveau 1 (seuls niveaux
    /// utilisés par cette étape, `spells.level` va jusqu'à 9 mais le contenu
    /// peuplé ne couvre que le socle MVP niveau 1-3/4 — voir le commentaire
    /// de classe de `data/character_creation_repository.dart`).
    required int level,

    /// École de magie (`spells.school`, ex. "Évocation") — première moitié de
    /// la ligne de méta affichée sous le nom du sort.
    required String school,

    /// Temps d'incantation (`spells.casting_time`, valeur brute telle que
    /// stockée en base, ex. "1 action" — pas de reformatage "action" comme
    /// une première lecture de la maquette aurait pu le suggérer, la colonne
    /// réelle inclut toujours la quantité) — seconde moitié de la ligne de
    /// méta.
    required String castingTime,

    /// `spells.is_incomplete` — `true` pour une entrée placeholder créée par
    /// l'import XML aidedd.org quand l'utilisateur choisit "Garder comme
    /// élément personnalisé" pour un sort non catalogué (voir
    /// `features/xml_import/data/xml_import_placeholder_catalog_repository.dart`,
    /// toujours `level: 0` pour ces entrées, voir sa documentation). Signale
    /// qu'il manque des informations à compléter plus tard côté contenu —
    /// `false` pour tout sort peuplé normalement par l'équipe
    /// `dev-backend-supabase`.
    @Default(false) bool isIncomplete,
  }) = _SpellOption;

  /// Ligne de méta affichée sous le nom du sort ("Évocation · 1 action").
  String get metaLine => '$school · $castingTime';
}
