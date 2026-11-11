import '../../../core/utils/uuid_v4.dart';

/// Écritures du journal de campagne (`character_journal_entries`) rendues
/// hors-ligne-capables (T4, P15). Une ligne de file `journalEntry` porte
/// l'**état voulu d'une entrée** (`targetId` = UUID de l'entrée, généré côté
/// client à l'ajout), « dernière valeur gagnante » :
///
/// - ajout, pas encore synchronisé : `{"body": "...", "createdAt": ISO 8601}` ;
/// - modification d'une entrée déjà côté serveur : `{"body": "..."}` ;
/// - suppression d'une entrée déjà côté serveur : `{"deleted": true}`.
///
/// La présence de `createdAt` distingue l'ajout de la modification. Ce fichier
/// porte le format, sa **validation stricte** et la **fusion** de deux
/// écritures successives : un payload qui ne passe pas [parseJournalPayload]
/// n'est JAMAIS rejoué ni superposé (la ligne est supprimée de la file par le
/// synchroniseur), sinon il bloquerait le compteur de synchro, la déconnexion
/// et la suppression de compte.
abstract final class JournalPayloadKeys {
  static const body = 'body';
  static const createdAt = 'createdAt';
  static const deleted = 'deleted';
}

enum JournalWriteOp { add, update, delete }

/// Une écriture de journal : texte (ajout/modification) et date de création
/// (ajout seulement).
class JournalWrite {
  const JournalWrite.add({required String this.body, required this.createdAt})
    : op = JournalWriteOp.add;

  const JournalWrite.update({required String this.body})
    : op = JournalWriteOp.update,
      createdAt = null;

  const JournalWrite.delete()
    : op = JournalWriteOp.delete,
      body = null,
      createdAt = null;

  final JournalWriteOp op;

  /// Texte de l'entrée (`null` pour une suppression).
  final String? body;

  /// Date de création choisie par le client (ajout uniquement).
  final DateTime? createdAt;

  Map<String, dynamic> toPayload() => switch (op) {
    JournalWriteOp.add => {
      JournalPayloadKeys.body: body,
      JournalPayloadKeys.createdAt: createdAt!.toUtc().toIso8601String(),
    },
    JournalWriteOp.update => {JournalPayloadKeys.body: body},
    JournalWriteOp.delete => {JournalPayloadKeys.deleted: true},
  };
}

/// Un texte de journal valide est non vide une fois les espaces retirés
/// (la feuille de saisie impose déjà cette règle).
bool isValidJournalBody(Object? body) =>
    body is String && body.trim().isNotEmpty;

/// Un `targetId` de file `journalEntry` doit être un UUID.
bool isValidJournalTargetId(String targetId) => isUuid(targetId);

/// Analyse stricte d'un payload `journalEntry` ; `null` s'il est invalide
/// (pas un objet, `deleted` autre que `true`, texte absent/vide/non texte,
/// `createdAt` présent mais pas une date lisible). Les clés inconnues sont
/// ignorées.
JournalWrite? parseJournalPayload(Object? raw) {
  if (raw is! Map) return null;
  if (raw.containsKey(JournalPayloadKeys.deleted)) {
    return raw[JournalPayloadKeys.deleted] == true
        ? const JournalWrite.delete()
        : null;
  }
  final body = raw[JournalPayloadKeys.body];
  if (!isValidJournalBody(body)) return null;
  if (!raw.containsKey(JournalPayloadKeys.createdAt)) {
    return JournalWrite.update(body: body as String);
  }
  final createdAtRaw = raw[JournalPayloadKeys.createdAt];
  if (createdAtRaw is! String) return null;
  final createdAt = DateTime.tryParse(createdAtRaw);
  if (createdAt == null) return null;
  return JournalWrite.add(body: body as String, createdAt: createdAt);
}

/// Résultat de la fusion d'une écriture demandée avec celle déjà en file pour
/// la même entrée.
class JournalWritePlan {
  const JournalWritePlan._(this.write, {this.cancelsPendingAdd = false});

  /// Écriture effective (à mettre en file hors ligne, à envoyer en ligne).
  final JournalWrite? write;

  /// `true` : la suppression annule un ajout jamais synchronisé — hors ligne,
  /// la ligne de file est simplement retirée (rien à écrire sur le serveur).
  final bool cancelsPendingAdd;

  /// `true` : l'entrée est déjà supprimée dans la file, elle ne peut plus être
  /// modifiée.
  bool get isRejected => write == null;
}

/// Fusionne [requested] avec [pending] (l'écriture déjà en file pour cette
/// entrée, `null` si aucune ou illisible) :
///
/// - modification d'un ajout en attente : reste un **ajout** au nouveau texte,
///   avec la date de création d'origine ;
/// - modification d'une modification : la dernière gagne ;
/// - suppression d'un ajout en attente : annule l'ajout ([JournalWritePlan
///   .cancelsPendingAdd]) ;
/// - suppression sinon : tombstone ;
/// - modification d'une entrée déjà supprimée en file : refusée ;
/// - ajout : toujours tel quel (UUID neuf).
JournalWritePlan planJournalWrite({
  required JournalWrite? pending,
  required JournalWrite requested,
}) {
  switch (requested.op) {
    case JournalWriteOp.add:
      return JournalWritePlan._(requested);
    case JournalWriteOp.update:
      if (pending?.op == JournalWriteOp.delete) {
        return const JournalWritePlan._(null);
      }
      if (pending?.op == JournalWriteOp.add) {
        return JournalWritePlan._(
          JournalWrite.add(
            body: requested.body!,
            createdAt: pending!.createdAt!,
          ),
        );
      }
      return JournalWritePlan._(requested);
    case JournalWriteOp.delete:
      return JournalWritePlan._(
        requested,
        cancelsPendingAdd: pending?.op == JournalWriteOp.add,
      );
  }
}
