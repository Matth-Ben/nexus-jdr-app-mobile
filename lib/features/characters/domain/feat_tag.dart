/// Étiquette informative d'un don proposé au choix (P13) : « Épopée » ou
/// « Campagne ». Purement indicative : elle ne grise, ne masque ni ne
/// restreint aucun don (décision de Matthias, 12/11/2026).
enum FeatTag {
  /// `feats.category = 'epic_boon'` (faveurs épiques).
  epic,

  /// `feats.category = 'legacy'` ET `feats.source` dans [campaignSources]
  /// (dons de suppléments de campagne : Fizban, Géants, Planescape,
  /// Dragonlance).
  campaign;

  /// Sources (`feats.source`) des suppléments de campagne.
  static const campaignSources = {'FToD', 'BGG', 'PSAiM', 'DSotDQ'};

  /// Étiquette d'un don d'après ses colonnes `category`/`source` (toutes deux
  /// nullables, et absentes d'un ancien payload ou d'une base antérieure à la
  /// migration) : `null` (aucune pastille) pour toute autre valeur, y compris
  /// inconnue.
  static FeatTag? fromColumns({Object? category, Object? source}) {
    if (category == 'epic_boon') return FeatTag.epic;
    if (category == 'legacy' && campaignSources.contains(source)) {
      return FeatTag.campaign;
    }
    return null;
  }
}
