import 'package:freezed_annotation/freezed_annotation.dart';

part 'tool_option.freezed.dart';

/// Un outil/instrument sélectionnable à l'étape 5/9 "Compétences et outils"
/// de l'assistant de création (`tools`, voir
/// `docs/cahier-des-charges/02-modele-donnees.md`).
///
/// [category] est une colonne réelle de `tools` ('outils_artisan'/
/// 'instrument'/'jeu'/'autre', vérifié contre
/// `supabase/migrations/20260825090500_seed_reference_core_data.sql` du dépôt
/// web) — utilisée pour filtrer les candidats d'un [ClassToolChoice] par
/// catégorie côté `presentation/skills_and_tools_step_screen.dart`.
@freezed
abstract class ToolOption with _$ToolOption {
  const factory ToolOption({
    required int id,
    required String name,
    required String category,
  }) = _ToolOption;
}
