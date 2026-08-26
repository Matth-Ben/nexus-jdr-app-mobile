import 'package:freezed_annotation/freezed_annotation.dart';

part 'skill_option.freezed.dart';

/// Une compétence D&D 5e (`skills`, voir
/// `docs/cahier-des-charges/02-modele-donnees.md`), résolue à l'étape 9/9
/// "Récapitulatif" de l'assistant de création pour convertir les noms de
/// compétences déjà choisis (`CharacterCreationDraft.classSkillChoices`,
/// `BackgroundOption.skillProficiencies`) en `skill_id` réels avant écriture
/// dans `character_skill_proficiencies`.
///
/// [abilityId] ('str'/'dex'/'con'/'int'/'wis'/'cha', colonne réelle
/// `skills.ability_id`) n'est lu ici que par fidélité à la ligne brute — cet
/// écran n'affiche jamais l'abréviation de caractéristique associée à une
/// compétence (contrairement à `SkillAbilityMapping`, la constante
/// applicative déjà utilisée à l'étape 5/9 pour ce même besoin d'affichage,
/// jamais réutilisée ici : voir `data/skill_row_mapper.dart` pour le
/// rationale de cette résolution par requête plutôt que par constante).
@freezed
abstract class SkillOption with _$SkillOption {
  const factory SkillOption({
    required int id,
    required String name,
    required String abilityId,
  }) = _SkillOption;
}
