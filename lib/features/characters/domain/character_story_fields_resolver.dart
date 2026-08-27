import 'character_detail.dart';
import 'character_story_field.dart';

/// Résout les 9 champs texte de l'onglet "Histoire" (`CharacterDetail`) en
/// lignes de cartes prêtes à afficher, pour
/// `presentation/widgets/character_story_tab_body.dart`.
///
/// Ordre canonique des 9 champs (décision du chef de projet, même ordre que
/// l'étape 8/9 de l'assistant de création,
/// `character_creation/presentation/appearance_and_backstory_step_screen.dart`) :
/// apparence physique, traits de personnalité, idéaux, liens, défauts,
/// histoire personnelle, alliés, particularités, trésor.
///
/// Écart assumé par rapport à cet ordre strictement séquentiel, pour
/// respecter la maquette (`docs/cahier-des-charges/09-maquettes-captures.md`,
/// section "Onglet Histoire") : "Idéaux" et "Défauts" sont regroupés sur une
/// même ligne à 2 colonnes, ce qui déplace visuellement "Défauts" avant
/// "Liens" (au lieu d'après, comme le voudrait l'ordre strictement
/// séquentiel 1..9). Seul l'agencement visuel de cet écran est concerné :
/// l'ordre "1..9" ci-dessus reste la référence pour toute autre lecture des
/// 9 champs (ex. l'assistant de création).
abstract final class CharacterStoryFieldsResolver {
  /// Une ligne par élément de la liste retournée : une ligne à 1 champ est
  /// affichée pleine largeur, une ligne à 2 champs (Idéaux/Défauts) à 2
  /// colonnes. Un champ vide (une fois `trim`) est retiré de sa ligne ; une
  /// ligne qui n'a plus aucun champ visible (ex. Idéaux et Défauts tous les
  /// deux vides) est retirée entièrement. Liste vide si les 9 champs sont
  /// vides : à l'appelant d'afficher un état vide dans ce cas plutôt qu'un
  /// onglet blanc (voir `character_story_tab_body.dart::_EmptyStoryState`).
  static List<List<CharacterStoryField>> resolveRows(CharacterDetail detail) {
    final rows = <List<CharacterStoryField>>[
      [
        CharacterStoryField(
          label: 'APPARENCE PHYSIQUE',
          text: detail.appearanceText,
        ),
      ],
      [
        CharacterStoryField(
          label: 'TRAITS DE PERSONNALITÉ',
          text: detail.traitsText,
        ),
      ],
      [
        CharacterStoryField(label: 'IDÉAUX', text: detail.idealsText),
        CharacterStoryField(label: 'DÉFAUTS', text: detail.flawsText),
      ],
      [CharacterStoryField(label: 'LIENS', text: detail.bondsText)],
      [
        CharacterStoryField(
          label: 'HISTOIRE PERSONNELLE',
          text: detail.backstoryText,
        ),
      ],
      [CharacterStoryField(label: 'ALLIÉS', text: detail.alliesText)],
      [CharacterStoryField(label: 'PARTICULARITÉS', text: detail.featuresText)],
      [CharacterStoryField(label: 'TRÉSOR', text: detail.treasureText)],
    ];

    final visibleRows = <List<CharacterStoryField>>[];
    for (final row in rows) {
      final visibleFields = _visibleFieldsOf(row);
      if (visibleFields.isNotEmpty) {
        visibleRows.add(visibleFields);
      }
    }
    return visibleRows;
  }

  static List<CharacterStoryField> _visibleFieldsOf(
    List<CharacterStoryField> row,
  ) {
    return row.where((field) => field.text.trim().isNotEmpty).toList();
  }
}
