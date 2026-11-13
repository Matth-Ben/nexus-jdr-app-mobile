/// Cause d'un échec de combat — un cas par code stable renvoyé par les RPC
/// (`message` de l'erreur Postgres, voir la migration web
/// `20261114091000_group_combat_rpcs.sql`), plus [offline], [network] et
/// [unknown]. La traduction en texte localisé relève de la présentation.
enum CombatFailureKind {
  /// `not_authenticated` (28000).
  notAuthenticated('not_authenticated'),

  /// `group_not_found` (P0002) : groupe inconnu ou non accessible.
  groupNotFound('group_not_found'),

  /// `combat_not_found` (P0002) : « introuvable ou non accessible ».
  combatNotFound('combat_not_found'),

  /// `participant_not_found` (P0002).
  participantNotFound('participant_not_found'),

  /// `not_group_owner` (42501) : action réservée au MJ.
  notGroupOwner('not_group_owner'),

  /// `no_game_master` (P0001) : pas de MJ dans l'app pour ce groupe.
  noGameMaster('no_game_master'),

  /// `gm_absent` (P0001) : le MJ n'est plus dans le groupe (lecture seule).
  gmAbsent('gm_absent'),

  /// `combat_already_active` (P0001).
  combatAlreadyActive('combat_already_active'),

  /// `combat_not_active` (P0001) : combat déjà terminé.
  combatNotActive('combat_not_active'),

  /// `participant_removed` (P0001).
  participantRemoved('participant_removed'),

  /// `no_character` (P0001).
  noCharacter('no_character'),

  /// `npc_limit_per_call` (P0001) : plus de 20 PNJ par appel.
  npcLimitPerCall('npc_limit_per_call'),

  /// `npc_limit_per_combat` (P0001) : plus de 60 PNJ non retirés.
  npcLimitPerCombat('npc_limit_per_combat'),

  /// `invalid_initiative` (22023) : hors -20..60.
  invalidInitiative('invalid_initiative'),

  /// `invalid_name` (22023).
  invalidName('invalid_name'),

  /// `invalid_count` (22023).
  invalidCount('invalid_count'),

  /// `invalid_sort_order` (22023).
  invalidSortOrder('invalid_sort_order'),

  /// Purement local : aucun combat actif connu côté client au moment d'une
  /// action (à ne pas confondre avec une réponse serveur [combatNotFound]).
  noActiveCombat(null),

  /// Aucune connexion détectée : écriture refusée sans toucher le réseau
  /// (aucune file de synchro pour le combat).
  offline(null),

  /// Échec de transport (délai dépassé, socket...) après une tentative.
  network(null),

  /// Code serveur non reconnu : [CombatFailure.rawMessage] fait foi.
  unknown(null);

  const CombatFailureKind(this.serverCode);

  /// Code stable côté serveur, `null` pour les cas purement client.
  final String? serverCode;

  /// Résout un `message` d'erreur RPC. Un code inconnu donne [unknown].
  static CombatFailureKind fromServerCode(String? code) {
    if (code == null) return unknown;
    for (final kind in values) {
      if (kind.serverCode == code) return kind;
    }
    return unknown;
  }
}

/// Échec typé d'une opération de combat.
class CombatFailure implements Exception {
  const CombatFailure(this.kind, {this.rawMessage, this.sqlState});

  const CombatFailure.offline() : this(CombatFailureKind.offline);

  const CombatFailure.network() : this(CombatFailureKind.network);

  final CombatFailureKind kind;

  /// Message brut du serveur (utile seulement pour [CombatFailureKind.unknown]).
  final String? rawMessage;

  /// SQLSTATE renvoyé par le serveur, le cas échéant.
  final String? sqlState;

  /// `true` si l'échec vient de l'absence de réseau (lecture seule).
  bool get isConnectivity =>
      kind == CombatFailureKind.offline || kind == CombatFailureKind.network;

  @override
  String toString() =>
      'CombatFailure($kind${rawMessage == null ? '' : ': '
                '$rawMessage'})';

  @override
  bool operator ==(Object other) =>
      other is CombatFailure &&
      other.kind == kind &&
      other.rawMessage == rawMessage &&
      other.sqlState == sqlState;

  @override
  int get hashCode => Object.hash(kind, rawMessage, sqlState);
}
