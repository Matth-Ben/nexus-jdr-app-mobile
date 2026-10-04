import '../domain/lineage_choice_catalog.dart';
import '../domain/lineage_option.dart';

/// Mapping pur entre les lignes brutes `race_lineages`/`translations`/
/// `racial_innate_spells` et [LineageChoiceCatalog] — voir
/// `lineage_choice_repository.dart`.
///
/// Les règles de titre/sous-titre sont dérivées des COLONNES renvoyées par
/// la requête, jamais d'un identifiant de race en dur : [titleOf]/
/// [subtitleOf] ne savent même pas qu'il existe un Drakéide/Tieffelin/
/// Goliath, seulement que `damage_type` est renseigné ou non, et si la
/// lignée a des lignes `racial_innate_spells`. Concrètement, pour les 19
/// lignes `2024_lineage` sans sous-race existant à ce jour :
/// - `damage_type` non nul (Drakéide, 10 lignes) -> titre "Dragon
///   `<couleur minuscule>`" dérivé du nom brut ("... 2024 : `<Couleur>`"),
///   sous-titre "Souffle et résistance : `<Type>`" ;
/// - `damage_type` nul ET au moins une ligne `racial_innate_spells` liée
///   (Tieffelin, 3 lignes) -> titre = nom brut, sous-titre fixe sorts
///   innés ;
/// - sinon (Goliath, 6 lignes) -> titre = nom brut, aucun sous-titre
///   (`null` — ne JAMAIS inventer un effet non stocké en base).
abstract final class LineageChoiceRowMapper {
  /// Identifiants `race_lineages.id` des lignes [rows], en `String` (clés de
  /// `translations.entity_id`, `text`) — même principe que
  /// `SubclassChoiceRowMapper.collectSubclassIds`.
  static Set<String> collectLineageIds(List<Map<String, dynamic>> rows) => {
    for (final row in rows)
      if (row['id'] != null) row['id'].toString(),
  };

  /// Titre affiché : pour une ascendance draconique ([isDragonAncestry]),
  /// "Dragon `<couleur>`" dérivé du nom brut ("... 2024 : `<Couleur>`" ->
  /// "Dragon `<couleur minuscule>`", la couleur étant tout ce qui suit le
  /// dernier ':') ; sinon le nom brut tel quel (déjà suffisamment court,
  /// voir Tieffelin/Goliath).
  static String titleOf(String rawName, {required bool isDragonAncestry}) {
    if (!isDragonAncestry) return rawName;
    final separatorIndex = rawName.lastIndexOf(':');
    final color = separatorIndex == -1
        ? rawName
        : rawName.substring(separatorIndex + 1).trim();
    return 'Dragon ${color.toLowerCase()}';
  }

  /// Sous-titre affiché, `null` si aucune donnée mécanique ne justifie d'en
  /// afficher un — voir la doc de classe pour les 3 cas couverts.
  static String? subtitleOf({
    required String? damageType,
    required bool hasInnateSpells,
  }) {
    if (damageType != null && damageType.isNotEmpty) {
      return 'Souffle et résistance : ${_capitalize(damageType)}';
    }
    if (hasInnateSpells) {
      return 'Détermine les sorts innés acquis (niveaux 1, 3 et 5)';
    }
    return null;
  }

  static String _capitalize(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

  /// Construit le catalogue : une entrée par `race_id`, dans l'ordre des
  /// lignes [lineageRows] reçues (jamais retrié — consigne du chef de
  /// projet : les 10 couleurs de dragon restent dans l'ordre renvoyé par la
  /// requête, comme les autres écrans de ce type). Une ligne sans `id`/
  /// `race_id` exploitable est ignorée plutôt que de faire échouer tout le
  /// mapping.
  static LineageChoiceCatalog toCatalog({
    required List<Map<String, dynamic>> lineageRows,
    required Map<String, String> names,
    required Set<int> lineageIdsWithInnateSpells,
  }) {
    final byRaceId = <int, List<LineageOption>>{};
    for (final row in lineageRows) {
      final id = row['id'];
      final raceId = row['race_id'];
      if (id is! num || raceId is! num) continue;

      final lineageId = id.toInt();
      final damageType = row['damage_type'] as String?;
      final isDragonAncestry = damageType != null && damageType.isNotEmpty;
      final rawName = names[lineageId.toString()] ?? 'Lignée #$lineageId';

      byRaceId
          .putIfAbsent(raceId.toInt(), () => <LineageOption>[])
          .add(
            LineageOption(
              id: lineageId,
              name: titleOf(rawName, isDragonAncestry: isDragonAncestry),
              subtitle: subtitleOf(
                damageType: damageType,
                hasInnateSpells: lineageIdsWithInnateSpells.contains(lineageId),
              ),
            ),
          );
    }
    return LineageChoiceCatalog(optionsByRaceId: byRaceId);
  }
}
