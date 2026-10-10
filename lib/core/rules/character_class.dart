/// Clé stable d'une classe de personnage D&D 5e — remplace la pratique
/// historique de ce dépôt qui identifiait une classe par son libellé
/// français traduit (`translations.field_name = 'name'`, `locale = 'fr'`,
/// voir `character_repository.dart::_locale`). Un texte traduisible n'est
/// pas une clé stable par construction : dette D04 (`docs/dette-technique.md`),
/// tranchée par Matthias le 09/10/2026.
///
/// Mappée 1:1 sur `public.classes.id` (dépôt web,
/// `generated always as identity`) — confirmé par `dev-backend-supabase` le
/// 10/10/2026 en lecture directe sur la base de prod : cet `id` n'est jamais
/// réassigné, jamais réordonné, et aucune classe n'a jamais été
/// supprimée/réinsérée depuis le seed initial. C'est donc la clé stable à
/// utiliser, pas une nouvelle colonne.
///
/// Liste exacte et complète du catalogue `classes` à ce jour (13 lignes) :
/// 1 Barbare, 2 Barde, 3 Clerc, 4 Druide, 5 Guerrier, 6 Moine, 7 Paladin,
/// 8 Rôdeur, 9 Roublard, 10 Occultiste, 11 Magicien, 12 Ensorceleur,
/// 13 Artificier.
///
/// [frenchName] reste nécessaire malgré tout : c'est la seule donnée que
/// `CharacterRepository` reçoit du serveur pour nommer une classe
/// aujourd'hui (`translations`, locale FR figée, hors périmètre de ce
/// chantier). Centraliser la correspondance id <-> libellé FR ici, en un
/// seul endroit, est tout l'objet de cet enum : une erreur de frappe ou un
/// futur renommage ne peut plus diverger entre plusieurs fichiers (c'était
/// le cas avant ce chantier, voir `spellcasting_class_names.dart`,
/// `spellcasting_rules.dart`, `spell_slot_progression.dart`,
/// `prepared_spells_limit.dart`, `prepared_caster_spell_list.dart`,
/// `multiclass_prerequisites.dart`).
enum CharacterClass {
  barbarian(1, 'Barbare'),
  bard(2, 'Barde'),
  cleric(3, 'Clerc'),
  druid(4, 'Druide'),
  fighter(5, 'Guerrier'),
  monk(6, 'Moine'),
  paladin(7, 'Paladin'),
  ranger(8, 'Rôdeur'),
  rogue(9, 'Roublard'),
  warlock(10, 'Occultiste'),
  wizard(11, 'Magicien'),
  sorcerer(12, 'Ensorceleur'),
  artificer(13, 'Artificier');

  const CharacterClass(this.id, this.frenchName);

  /// `classes.id` côté Supabase — la clé stable, voir la documentation de
  /// classe.
  final int id;

  /// Libellé français traduit (`translations`), seule langue peuplée pour
  /// les 12 classes du socle à ce jour — l'Artificier a en plus une
  /// traduction `en` (voir `docs/dette-technique.md`, D04), mais ce dépôt ne
  /// lit encore que la locale FR.
  final String frenchName;

  /// Résout [id] (`classes.id`, reçu côté Supabase comme `Object`/`num`, ou
  /// parfois stringifié) vers sa [CharacterClass] — `null` si inconnu (classe
  /// future non encore ajoutée à cet enum, ou valeur inexploitable).
  static CharacterClass? fromId(Object? id) {
    final intId = switch (id) {
      final num value => value.toInt(),
      final String value => int.tryParse(value),
      _ => null,
    };
    if (intId == null) return null;
    for (final value in values) {
      if (value.id == intId) return value;
    }
    return null;
  }

  /// Résout [frenchName] vers sa [CharacterClass] — `null` si inconnu (nom
  /// non reconnu, repli « Classe #id » d'une traduction non résolue, ou
  /// future classe non encore ajoutée à cet enum). Jamais d'égalité
  /// insensible à la casse/aux accents : le libellé vient de `translations`,
  /// toujours écrit à l'identique.
  static CharacterClass? fromFrenchName(String? frenchName) {
    if (frenchName == null) return null;
    for (final value in values) {
      if (value.frenchName == frenchName) return value;
    }
    return null;
  }
}
