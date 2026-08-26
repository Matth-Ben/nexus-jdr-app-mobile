import 'character_detail.dart';

/// Formatte les deux lignes de sous-titre de la carte d'identité de la fiche
/// personnage (`presentation/widgets/character_identity_card.dart`) — voir la
/// spec visuelle de la tâche qui a produit ce fichier.
abstract final class CharacterIdentityFormatter {
  /// "{Race}{ (Sous-race)} · {Classe} · Niveau {N}", ou
  /// "{ClasseA} {niveauA} / {ClasseB} {niveauB}" en cas de multiclassage
  /// (`classes.length > 1`) — l'ellipsis en cas de dépassement de largeur est
  /// géré par le widget appelant (`TextOverflow.ellipsis`), pas ici.
  ///
  /// Une race personnalisée (`raceCustomText` non vide) est affichée à la
  /// place du nom de race résolu — les deux ne sont jamais renseignés en
  /// même temps en pratique (`characters.race_id`/`race_custom_text` sont
  /// mutuellement exclusifs), mais [raceCustomText] est prioritaire si les
  /// deux étaient renseignés.
  static String subtitleLine1(CharacterDetail detail) {
    if (detail.classes.length > 1) {
      return detail.classes
          .map((row) => '${row.className} ${row.level}')
          .join(' / ');
    }

    final segments = <String>[
      ?_raceSegment(detail),
      if (detail.classes.isNotEmpty)
        '${detail.classes.first.className} · Niveau ${detail.totalLevel}',
    ];
    return segments.join(' · ');
  }

  /// "Historique : {nom} · {Alignement}", avec chaque segment omis s'il n'est
  /// pas résolu — `null` (ligne entièrement masquée) seulement si les deux
  /// sont absents à la fois.
  static String? subtitleLine2(CharacterDetail detail) {
    if (detail.backgroundName == null && detail.alignmentName == null) {
      return null;
    }
    final segments = <String>[
      if (detail.backgroundName case final background?)
        'Historique : $background',
      ?detail.alignmentName,
    ];
    return segments.join(' · ');
  }

  static String? _raceSegment(CharacterDetail detail) {
    final custom = detail.raceCustomText?.trim();
    if (custom != null && custom.isNotEmpty) {
      return custom;
    }
    final raceName = detail.raceName;
    if (raceName == null) return null;
    final subraceName = detail.subraceName;
    return subraceName != null ? '$raceName ($subraceName)' : raceName;
  }
}
