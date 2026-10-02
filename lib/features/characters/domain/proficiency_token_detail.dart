import 'package:freezed_annotation/freezed_annotation.dart';

import 'proficiency_catalog.dart';

part 'proficiency_token_detail.freezed.dart';

/// Résultat de `ProficiencyTokenResolver` pour un token de maîtrise donné :
/// soit une liste d'armes ([weapons]), soit une liste d'armures/boucliers
/// ([armors] — un token d'armure n'alimente jamais [weapons] et
/// inversement), soit les deux vides (état "liste vide" du panneau "Infos",
/// voir `proficiency_detail_panel.dart`).
@freezed
abstract class ProficiencyTokenDetail with _$ProficiencyTokenDetail {
  const factory ProficiencyTokenDetail({
    @Default(<ProficiencyCatalogWeapon>[])
    List<ProficiencyCatalogWeapon> weapons,
    @Default(<ProficiencyCatalogArmor>[]) List<ProficiencyCatalogArmor> armors,
  }) = _ProficiencyTokenDetail;
}
