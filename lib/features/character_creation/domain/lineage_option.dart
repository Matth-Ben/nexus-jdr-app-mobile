import 'package:freezed_annotation/freezed_annotation.dart';

part 'lineage_option.freezed.dart';

/// Une ascendance/lignée proposée à l'étape 1/9 "Race", pour les races 2024
/// qui en ont un choix explicite sans passer par une sous-race (Drakéide,
/// Tieffelin, Goliath à ce jour — déterminé par les données, voir
/// [LineageChoiceCatalog], jamais une liste de races en dur).
///
/// [name]/[subtitle] sont déjà le titre/sous-titre affichés tels quels (voir
/// `data/lineage_choice_row_mapper.dart` pour les règles exactes de
/// construction depuis `race_lineages`) — même principe que
/// `SubclassChoiceOption.name`/`.description`.
@freezed
abstract class LineageOption with _$LineageOption {
  const factory LineageOption({
    /// `race_lineages.id` — devient `characters.lineage_id` à la création
    /// (voir `data/character_creation_repository.dart::createCharacter`).
    required int id,
    required String name,

    /// `null` si aucune donnée mécanique stockée en base ne justifie
    /// d'afficher un sous-titre (ex. Goliath : `damage_type` et
    /// `racial_innate_spells` tous deux absents — ne JAMAIS inventer un
    /// effet non stocké).
    String? subtitle,
  }) = _LineageOption;
}
