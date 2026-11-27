/// Étiquette « Campagne » d'un groupe (étape 4 de Grimoire) : titre et résumé
/// public que Grimoire copie sur `groups.story_title`/
/// `groups.story_summary_public` (migration DeepCore `20261119120000`).
/// `null` (ou colonne absente de la réponse) : aucune campagne associée.
///
/// Règles d'affichage communes à l'écran Groupe (carte « Campagne ») et à
/// l'aperçu d'invitation (titre seul, décision n° 33 du 19/11/2026) :
/// - le texte est rogné de ses blancs de début et de fin ;
/// - un titre identique au nom du groupe (après rognage, casse ignorée) n'est
///   pas affiché (décision n° 36) ;
/// - un résumé n'est jamais affiché sans titre.
abstract final class GroupCampaignLabel {
  /// Blancs rognés : même liste que les contraintes CHECK de DeepCore
  /// (`v_blank` de la migration `20261119120000`). `String.trim` de Dart ne
  /// retire ni U+200B ni U+2060.
  static const String _blank =
      r'[\t\n\v\f\r \u0085\u00a0\u1680\u2000-\u200b\u2028\u2029\u202f'
      r'\u205f\u2060\u3000\ufeff]';

  static final RegExp _edgeBlanks = RegExp('^$_blank+|$_blank+\$');

  static final RegExp _blankRuns = RegExp('$_blank+');

  static final RegExp _carriageReturns = RegExp(r'\r\n?');

  /// [raw] rogné, ou `null` s'il est absent ou ne contient que des blancs.
  static String? clean(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.replaceAll(_edgeBlanks, '');
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Titre à afficher pour le groupe [groupName] : `null` sans campagne, ou
  /// quand le titre répète le nom du groupe (décision n° 36). Comparaison
  /// sans tenir compte de la casse ni de la forme des blancs (toute suite de
  /// blancs de [_blank] vaut une espace : « Les  Lames » égale « Les
  /// Lames ») ; le titre affiché, lui, est inchangé. Pas de normalisation
  /// Unicode (NFC) : elle demanderait une dépendance de plus.
  static String? displayedTitle({
    required String? storyTitle,
    required String groupName,
  }) {
    final title = clean(storyTitle);
    if (title == null) return null;
    final name = clean(groupName) ?? '';
    return _comparable(title) == _comparable(name) ? null : title;
  }

  /// Forme de comparaison : suites de blancs ramenées à une espace, casse
  /// ignorée.
  static String _comparable(String text) =>
      text.replaceAll(_blankRuns, ' ').toLowerCase();

  /// Résumé à afficher : `null` s'il est vide ou s'il n'y a pas de titre
  /// (même identique au nom du groupe, le titre reste requis). Les retours à
  /// la ligne sont gardés, normalisés en `\n`.
  static String? displayedSummary({
    required String? storyTitle,
    required String? storySummary,
  }) {
    if (clean(storyTitle) == null) return null;
    return clean(storySummary)?.replaceAll(_carriageReturns, '\n');
  }
}
