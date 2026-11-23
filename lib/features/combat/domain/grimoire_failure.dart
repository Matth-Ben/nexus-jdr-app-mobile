/// Cause d'un échec d'appel aux fonctions `api_v1` du combat mené depuis
/// Grimoire (`group_live_channels`, `send_to_group_leader`) : un cas par code
/// stable du contrat DeepCore (`docs/api-v1/contrat-temps-reel-combat.md` §6),
/// plus [offline] et [other]. La traduction relève de la présentation.
enum GrimoireFailureKind {
  /// `rate_limited` (P0001) : plus de 20 messages en 60 s ;
  /// [GrimoireFailure.retryAfterSeconds] = secondes à attendre.
  rateLimited('rate_limited'),

  /// `no_character` (P0001) : initiative d'un membre sans personnage.
  noCharacter('no_character'),

  /// `group_not_found` (P0002) : groupe inconnu, ou plus membre (exclu,
  /// parti) : ne plus s'abonner ni réessayer.
  groupNotFound('group_not_found'),

  /// `not_member` (P0002) : meneur sans ligne de membre.
  notMember('not_member'),

  /// Purement local : aucune connexion, rien n'est envoyé.
  offline(null),

  /// Tout autre cas (transport, code inconnu, réponse illisible).
  other(null);

  const GrimoireFailureKind(this.serverCode);

  /// Code stable côté serveur, `null` pour les cas purement client.
  final String? serverCode;

  /// Résout un `message` d'erreur. Un code inconnu donne [other].
  static GrimoireFailureKind fromServerCode(String? code) {
    if (code == null) return other;
    for (final kind in values) {
      if (kind.serverCode == code) return kind;
    }
    return other;
  }
}

/// Échec typé d'un appel du combat mené depuis Grimoire.
class GrimoireFailure implements Exception {
  const GrimoireFailure(this.kind, {this.retryAfterSeconds, this.rawMessage});

  const GrimoireFailure.offline() : this(GrimoireFailureKind.offline);

  final GrimoireFailureKind kind;

  /// [GrimoireFailureKind.rateLimited] seulement : secondes à attendre
  /// (`details` de l'erreur), `null` si illisible.
  final int? retryAfterSeconds;

  /// Message brut (diagnostic seulement, jamais affiché).
  final String? rawMessage;

  @override
  String toString() =>
      'GrimoireFailure($kind${rawMessage == null ? '' : ': $rawMessage'})';

  @override
  bool operator ==(Object other) =>
      other is GrimoireFailure &&
      other.kind == kind &&
      other.retryAfterSeconds == retryAfterSeconds &&
      other.rawMessage == rawMessage;

  @override
  int get hashCode => Object.hash(kind, retryAfterSeconds, rawMessage);
}
