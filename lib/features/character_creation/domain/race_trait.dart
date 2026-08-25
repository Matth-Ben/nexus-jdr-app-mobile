import 'package:freezed_annotation/freezed_annotation.dart';

part 'race_trait.freezed.dart';

/// Trait racial individuel (`races.traits`/`subraces.traits`, jsonb liste de
/// `{name, description}` — voir `docs/cahier-des-charges/02-modele-donnees.md`).
@freezed
abstract class RaceTrait with _$RaceTrait {
  const factory RaceTrait({required String name, required String description}) =
      _RaceTrait;
}
