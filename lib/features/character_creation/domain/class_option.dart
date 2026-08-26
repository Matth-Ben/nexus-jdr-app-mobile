import 'package:freezed_annotation/freezed_annotation.dart';

part 'class_option.freezed.dart';

/// Une classe sélectionnable à l'étape 2/9 de l'assistant de création
/// (`classes`, voir `docs/cahier-des-charges/02-modele-donnees.md`).
///
/// Contrairement à [RaceOption], pas de logique de formatage dédiée
/// (`RaceSummaryFormatter`) : [description] est déjà une phrase complète
/// résolue depuis `translations` (`field_name='description'`), il suffit de
/// lui accoler le dé de vie — voir [summaryLine].
@freezed
abstract class ClassOption with _$ClassOption {
  const ClassOption._();

  const factory ClassOption({
    required int id,
    required String name,
    required String description,
    required int hitDie,
  }) = _ClassOption;

  /// Ligne de résumé affichée sous le nom ("Lanceur de sorts érudit · dé de
  /// vie d6", maquette `03_étape_2_classe.png`), en omettant la description
  /// si elle n'a pas pu être résolue (pas de ' · ' orphelin en tête) — même
  /// pattern que `_summaryLine` de `character_card.dart`.
  String get summaryLine {
    final segments = [
      if (description.isNotEmpty) description,
      'dé de vie d$hitDie',
    ];
    return segments.join(' · ');
  }
}
