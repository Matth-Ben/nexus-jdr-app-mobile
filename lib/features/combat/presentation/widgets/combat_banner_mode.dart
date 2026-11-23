/// Mode du bandeau (`docs/combat-grimoire-ui.md` §2, §5).
enum CombatBannerMode {
  /// « Combat en cours · round N ».
  standard,

  /// « Combat en préparation » : ordre pas encore dévoilé.
  preparing,

  /// « À toi de jouer · round N » : fond `turn-fill`, bordure emphasis + halo
  /// (sans pulsation).
  yourTurn,
}

/// Rappel d'initiative du bandeau en préparation.
enum CombatBannerInitiativeHint {
  none,

  /// Demandée, pas encore envoyée : « Envoie ton initiative ».
  send,

  /// Envoyée : « Initiative envoyée ».
  sent,
}
