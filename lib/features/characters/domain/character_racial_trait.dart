import 'package:freezed_annotation/freezed_annotation.dart';

part 'character_racial_trait.freezed.dart';

/// Trait racial individuel déjà résolu pour la fiche personnage — onglet
/// "Aptitudes", carte "TRAITS RACIAUX"
/// (`presentation/widgets/character_racial_traits_card.dart`), voir
/// [CharacterDetail.racialTraits] (`domain/character_detail.dart`).
///
/// Source : `races.traits`/`subraces.traits` (jsonb, liste de `{name,
/// description}`, voir `docs/cahier-des-charges/02-modele-donnees.md`) —
/// même forme brute que `RaceTrait`
/// (`character_creation/domain/race_trait.dart`), dupliquée ici plutôt que
/// réutilisée pour ne jamais coupler les deux fonctionnalités entre elles —
/// voir le commentaire de classe de `RaceRowMapper`
/// (`character_creation/data/race_row_mapper.dart`) pour le rationale
/// détaillé de cette duplication systématique dans ce dépôt (même principe
/// que `CharacterSkillRowMapper`/`CharacterInventoryRowMapper`/...).
@freezed
abstract class CharacterRacialTrait with _$CharacterRacialTrait {
  const factory CharacterRacialTrait({
    required String name,
    required String description,
  }) = _CharacterRacialTrait;
}
