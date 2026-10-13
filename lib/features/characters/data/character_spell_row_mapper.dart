import '../../../core/rules/spell_status.dart';
import '../domain/character_detail_class_row.dart';
import '../domain/character_spell_entry.dart';
import '../domain/prepared_spells_limit.dart';
import '../domain/spell_grant_source.dart';

/// Fonctions de mapping pures entre les lignes brutes renvoyées par
/// PostgREST (`character_spells`, `spells`, `translations`) et
/// [CharacterSpellEntry], pour la section "SORTS" de l'onglet Compétences.
///
/// Voir le commentaire de classe de `CharacterSkillRowMapper` pour le
/// rationale de duplication avec `character_creation/data/spell_row_mapper.dart`
/// (`SpellRowMapper`).
abstract final class CharacterSpellRowMapper {
  /// Identifiants de sorts (`character_spells.spell_id`) du personnage,
  /// dédupliqués — sert à la fois à interroger `spells.id` (`.inFilter`) et,
  /// une fois stringifiés, `translations.entity_id`.
  static Set<int> collectSpellIds(List<Map<String, dynamic>> rows) {
    final ids = <int>{};
    for (final row in rows) {
      final spellId = row['spell_id'];
      if (spellId is num) {
        ids.add(spellId.toInt());
      }
    }
    return ids;
  }

  /// `{spell_id: status}` depuis les lignes brutes `character_spells`
  /// embarquées sous `characters`. Une ligne sans `spell_id`/`status`
  /// exploitable est ignorée.
  ///
  /// Lignes en double pour un même sort (aucune contrainte d'unicité en
  /// base, et le `select` n'a pas d'ordre garanti) : résolues par priorité
  /// fixe (`'préparé' > 'connu' > 'inné'`), jamais par ordre de lecture —
  /// voir [_statusRank]. Un même sort avec deux lignes de rangs différents
  /// retient donc toujours le rang le plus haut, quel que soit l'ordre des
  /// lignes :
  /// - une ligne ordinaire ('connu', 'préparé'...) l'emporte TOUJOURS sur une
  ///   ligne 'inné' pour LE STATUT AFFICHÉ (status) de l'entrée : le sort
  ///   suit son circuit ordinaire (emplacement/préparation) pour cette
  ///   facette-là — sans cette règle, l'ordre des lignes déciderait quel
  ///   statut gagne. Ça ne fait PAS disparaître la route innée : D43 du
  ///   registre de dette technique (`docs/dette-technique.md`, décision du
  ///   09/10/2026) tranche que les deux routes RAW (gratuite par repos long
  ///   ET emplacement/préparation) restent accordées indépendamment — voir
  ///   [parseInnateSpellIds]/[CharacterSpellEntry.hasInnateRoute], qui
  ///   portent cette seconde facette séparément de ce que cette fonction
  ///   retourne ici.
  /// - entre deux lignes ordinaires de statuts différents ('connu' et
  ///   'préparé' — ex. doublon créé par la course de `setSpellPrepared` sans
  ///   contrainte unique, voir D42/D10), 'préparé' l'emporte toujours :
  ///   silencieusement « dépréparer » un sort que le joueur a explicitement
  ///   préparé serait une règle fausse plus gênante qu'un ordre de lecture
  ///   qui déciderait au hasard (avant ce correctif : « la dernière ligne lue
  ///   l'emporte »).
  static Map<int, SpellStatus> parseStatuses(List<Map<String, dynamic>> rows) {
    final statuses = <int, SpellStatus>{};
    for (final row in rows) {
      final spellId = row['spell_id'];
      final rawStatus = row['status'] as String?;
      if (spellId is! num || rawStatus == null) continue;
      final status = SpellStatus.fromValue(rawStatus);
      final id = spellId.toInt();
      final known = statuses[id];
      if (known == null || _statusRank(status) >= _statusRank(known)) {
        statuses[id] = status;
      }
    }
    return statuses;
  }

  /// Rang de priorité d'un statut `character_spells.status` pour départager
  /// deux lignes en double du même sort dans [parseStatuses]. Toute valeur
  /// inattendue (ne devrait pas arriver, contrainte `CHECK` côté base, voir
  /// [SpellStatus.fromValue]) a le même rang que [SpellStatus.known] : ni
  /// favorisée ni pénalisée face aux deux statuts valides.
  static int _statusRank(SpellStatus status) => switch (status) {
    SpellStatus.prepared => 2,
    SpellStatus.innate => 0,
    SpellStatus.known => 1,
  };

  /// Identifiants de sorts portant AU MOINS une ligne `character_spells` au
  /// statut 'inné', indépendamment de ce que [parseStatuses] retient comme
  /// statut affiché pour ce même sort (D43 du registre de dette technique,
  /// `docs/dette-technique.md`) : un sort à la fois inné (trait racial) et
  /// connu/préparé (classe) a deux lignes distinctes en base (coexistence
  /// permise depuis D10, deux index uniques partiels distincts) ; une fois
  /// que [parseStatuses] a fait gagner la ligne ordinaire (toujours
  /// prioritaire, voir sa doc), le statut affiché ne permet plus à lui seul
  /// de savoir que la route innée existe ENCORE, en plus, séparément.
  ///
  /// Sert à alimenter [CharacterSpellEntry.hasInnateRoute], qui gouverne
  /// l'action de lancer gratuite et son compteur
  /// (`domain/innate_spell_usage.dart::InnateSpellUsage.isLimited`) —
  /// indépendamment de [parseStatuses] : les deux routes ne se consomment
  /// jamais l'une l'autre.
  static Set<int> parseInnateSpellIds(List<Map<String, dynamic>> rows) {
    final ids = <int>{};
    for (final row in rows) {
      final spellId = row['spell_id'];
      if (spellId is num && row['status'] == SpellStatus.innate.value) {
        ids.add(spellId.toInt());
      }
    }
    return ids;
  }

  /// `{spell_id: is_favorite}` — même principe que [parseStatuses]. Une
  /// ligne sans `spell_id`/`is_favorite` exploitable est ignorée (repli sur
  /// `false` dans [toCharacterSpellEntries]).
  static Map<int, bool> parseFavorites(List<Map<String, dynamic>> rows) {
    final favorites = <int, bool>{};
    for (final row in rows) {
      final spellId = row['spell_id'];
      final isFavorite = row['is_favorite'];
      if (spellId is num && isFavorite is bool) {
        favorites[spellId.toInt()] = isFavorite;
      }
    }
    return favorites;
  }

  /// `{spell_id: {source_class_id, ...}}` — classes d'origine connues de
  /// chaque sort (`character_spells.source_class_id`). Un ensemble, pas une
  /// valeur : un même sort peut avoir plusieurs lignes (aucune contrainte
  /// d'unicité en base), d'origines différentes ; toutes sont gardées et
  /// c'est `PreparedSpellsLimit.spellRequiresPreparation` qui tranche. Une
  /// origine nulle ou absente (cache antérieur à la lecture de cette
  /// colonne) n'ajoute rien : le sort est alors d'origine inconnue.
  static Map<int, Set<int>> parseSourceClassIds(
    List<Map<String, dynamic>> rows,
  ) {
    final sources = <int, Set<int>>{};
    for (final row in rows) {
      final spellId = row['spell_id'];
      final sourceClassId = row['source_class_id'];
      if (spellId is num && sourceClassId is num) {
        sources
            .putIfAbsent(spellId.toInt(), () => {})
            .add(sourceClassId.toInt());
      }
    }
    return sources;
  }

  /// `{spell_id: innate_uses_spent}` — usages innés dépensés depuis le
  /// dernier repos long (`character_spells.innate_uses_spent`), lus sur les
  /// seules lignes au statut 'inné'.
  ///
  /// Lignes en double pour un même sort (aucune contrainte d'unicité en
  /// base) : la valeur la plus HAUTE des lignes 'inné' est retenue.
  /// L'écriture (`CharacterRepository.setInnateSpellUsesSpent`) met à jour
  /// toutes les lignes 'inné' du sort d'un coup, elles portent donc
  /// normalement la même valeur ; si elles divergent, retenir le maximum
  /// évite d'offrir un lancer gratuit de trop (jamais l'inverse). Une ligne
  /// ordinaire ('connu'/'préparé') du même sort est ignorée : son compteur
  /// n'est jamais écrit et vaut toujours 0, il masquerait l'usage dépensé.
  ///
  /// Si le sort a aussi une ligne ordinaire, [parseStatuses] le présente
  /// avec le statut ordinaire : la valeur retournée ici est tout de même
  /// exploitée (D43) via [CharacterSpellEntry.hasInnateRoute]/
  /// [parseInnateSpellIds], qui portent l'existence de la route innée
  /// séparément de `status`.
  ///
  /// Clé absente (payload mis en cache avant la lecture de cette colonne)
  /// ou valeur inexploitable : rien n'est ajouté, le sort retombe sur 0
  /// (usage disponible) dans [toCharacterSpellEntries].
  static Map<int, int> parseInnateUsesSpent(List<Map<String, dynamic>> rows) {
    final spent = <int, int>{};
    for (final row in rows) {
      final spellId = row['spell_id'];
      final value = row['innate_uses_spent'];
      if (spellId is! num ||
          value is! num ||
          row['status'] != SpellStatus.innate.value) {
        continue;
      }
      final id = spellId.toInt();
      final uses = value.toInt() < 0 ? 0 : value.toInt();
      final known = spent[id];
      if (known == null || uses > known) spent[id] = uses;
    }
    return spent;
  }

  /// Construit les [CharacterSpellEntry] à partir des lignes brutes `spells`
  /// (id, level, school, casting_time, range, components, duration,
  /// concentration) déjà filtrées sur les sorts du personnage, des noms déjà
  /// résolus (`names`), des descriptions déjà résolues (`descriptions` —
  /// `spells` n'a pas de colonne `description` directe, elle vit dans
  /// `translations` comme le nom, voir `data/character_repository.dart`) et
  /// des statuts déjà résolus (`statuses`, voir [parseStatuses]). Un sort
  /// sans statut résolu (sort accordé — voir [grants] — ou sort de la liste
  /// de classe d'un lanceur à préparation jamais préparé) retombe sur
  /// 'connu', et n'est pas marqué [CharacterSpellEntry.isPersisted].
  ///
  /// [grants] : `{spell_id: origine}` des sorts accordés par une sous-classe
  /// (voir `SubclassSpellGrantResolver.resolve`) ; `spellRows` doit
  /// contenir ces sorts même sans ligne `character_spells`.
  ///
  /// [innateUsesSpent] : voir [parseInnateUsesSpent].
  ///
  /// [innateSpellIds] : voir [parseInnateSpellIds] — [CharacterSpellEntry
  /// .hasInnateRoute] de chaque sort. Par défaut vide : un appelant qui ne le
  /// renseigne pas retombe sur le repli par défaut du constructeur de
  /// [CharacterSpellEntry] (`status == SpellStatus.innate`), PAS sur
  /// « jamais de route innée » — seul ce mappeur a besoin de le renseigner
  /// explicitement (voir la doc de [CharacterSpellEntry.hasInnateRoute]).
  ///
  /// [classes] (les classes du personnage) et [sourceClassIds] (voir
  /// [parseSourceClassIds]) servent à dériver
  /// [CharacterSpellEntry.requiresPreparation]. [classes] est obligatoire :
  /// sans les classes, tout sort retombe sur « à préparer », et un Barde ne
  /// pourrait plus lancer ses sorts.
  static List<CharacterSpellEntry> toCharacterSpellEntries(
    List<Map<String, dynamic>> spellRows, {
    required Map<String, String> names,
    required Map<String, String> descriptions,
    required Map<int, SpellStatus> statuses,
    required List<CharacterDetailClassRow> classes,
    Map<int, Set<int>> sourceClassIds = const {},
    Map<int, bool> favorites = const {},
    Map<int, SpellGrantSource> grants = const {},
    Map<int, int> innateUsesSpent = const {},
    Set<int> innateSpellIds = const {},
  }) {
    final result = <CharacterSpellEntry>[];
    for (final row in spellRows) {
      final id = (row['id'] as num).toInt();
      final components = row['components'];
      // Sort accordé par une sous-classe (`grants`, voir
      // `SubclassSpellGrantResolver`) : toujours 'préparé', une seule entrée
      // même s'il a aussi une ligne `character_spells` (`statuses`), qui
      // n'existe alors plus que pour porter son éventuel favori.
      final grant = grants[id];
      result.add(
        CharacterSpellEntry(
          id: id,
          name: names[id.toString()] ?? 'Sort #$id',
          level: (row['level'] as num?)?.toInt() ?? 0,
          school: row['school'] as String? ?? '',
          status: grant != null
              ? SpellStatus.prepared
              : statuses[id] ?? SpellStatus.known,
          storedStatus: grant != null ? statuses[id] : null,
          castingTime: row['casting_time'] as String? ?? '',
          range: row['range'] as String? ?? '',
          components: components is Map<String, dynamic>
              ? components
              : const {},
          duration: row['duration'] as String? ?? '',
          concentration: row['concentration'] == true,
          description: descriptions[id.toString()] ?? '',
          isFavorite: favorites[id] ?? false,
          grantSource: grant,
          isPersisted: statuses.containsKey(id),
          requiresPreparation: PreparedSpellsLimit.spellRequiresPreparation(
            classes: classes,
            sourceClassIds: sourceClassIds[id] ?? const {},
          ),
          innateUsesSpent: innateUsesSpent[id] ?? 0,
          // Détection explicite (D43), indépendante de `status` ci-dessus :
          // voir la doc de [parseInnateSpellIds] et de
          // [CharacterSpellEntry.hasInnateRoute]. `InnateSpellUsage.isLimited`
          // exclut lui-même le cas `grant != null` (D44, hors périmètre ici) :
          // pas besoin de le refaire ici.
          //
          // `null` (jamais `false`) quand [id] n'est pas dans [innateSpellIds]
          // : laisse le constructeur de [CharacterSpellEntry] appliquer son
          // propre repli (`status == SpellStatus.innate`) plutôt que
          // d'écraser ce repli par une valeur figée — sans ce détour, un
          // appelant qui omettrait [innateSpellIds] (paramètre optionnel,
          // défaut `const {}`) verrait `hasInnateRoute` toujours à `false`,
          // y compris pour un sort réellement 'inné' (repli par défaut cassé).
          hasInnateRoute: innateSpellIds.contains(id) ? true : null,
        ),
      );
    }
    return result;
  }
}
