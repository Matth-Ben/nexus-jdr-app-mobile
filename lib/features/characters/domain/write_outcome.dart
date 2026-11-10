/// Résultat d'une écriture rendue hors-ligne-capable
/// (`CharacterRepository.updateHp`/`addXp`) : distingue une écriture
/// effectivement confirmée par le serveur d'une écriture seulement mise en
/// file d'attente locale, faute de connectivité au moment de l'appel — voir
/// `core/cache/pending_character_write_queue.dart`.
///
/// Permet à `presentation/character_detail_screen.dart` d'adapter son
/// message ([WriteOutcome.queued] affiche un `SnackBar` distinct, honnête
/// sur le fait que le changement n'est pas encore confirmé côté serveur) et
/// de ne pas déclencher d'effet de bord qui suppose une écriture déjà
/// confirmée (ex. l'ouverture automatique de l'écran de montée de niveau
/// après un franchissement de seuil d'XP, voir `_addXp`).
enum WriteOutcome {
  /// L'écriture a été confirmée par le serveur (chemin nominal, réseau
  /// disponible).
  synced,

  /// Aucune connectivité au moment de l'appel : l'écriture n'a même pas été
  /// tentée, elle a été mise en file (`PendingCharacterWriteQueue`) pour une
  /// prochaine synchro automatique dès le retour du réseau (voir
  /// `PendingCharacterWriteSyncer`).
  queued,

  /// Aucune connectivité au moment de l'appel et cette écriture n'est pas
  /// prise en charge par la file : **rien n'a été écrit**, ni sur le serveur
  /// ni dans la file. L'appelant doit afficher un message d'échec
  /// (`characterOfflineNotPersistedMessage`), jamais « sera synchronisé ».
  rejectedOffline,

  /// `applyRest` uniquement (D187) : un repos est déjà en attente de
  /// synchronisation pour ce personnage et la file n'en garde qu'un. **Rien
  /// n'a été écrit ni mis en file**, le repos en attente est intact.
  /// L'appelant doit le dire (`characterDetailRestAlreadyPendingMessage`) et
  /// annuler son affichage optimiste.
  restAlreadyPending,
}
