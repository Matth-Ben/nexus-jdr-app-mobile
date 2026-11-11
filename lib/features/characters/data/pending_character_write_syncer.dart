import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cache/pending_character_write_queue.dart';
import '../../../core/cache/reference_data_cache.dart';
import '../../../core/crash_reporting/crash_reporter.dart';
import '../../../core/rules/spell_status.dart';
import '../domain/currency_kind.dart';
import '../domain/offline_journal_writes.dart';
import '../domain/offline_state_writes.dart';
import '../domain/rest_type.dart';
import 'character_detail_cache.dart';
import 'character_repository.dart';

/// Une modification concurrente détectée au rejeu d'une écriture en file
/// (F19/D178) : le serveur ne porte plus la valeur qu'avait l'app quand
/// l'écriture a été mise en file. L'écriture a été **rejouée quand même**
/// ([queuedValue] est maintenant sur le serveur, [serverValue] est écrasée) —
/// signal destiné à l'alerte non bloquante (tranche T8).
class ServerValueConflict {
  const ServerValueConflict({
    required this.characterId,
    required this.kind,
    required this.serverValue,
    required this.queuedValue,
  });

  final String characterId;
  final PendingCharacterWriteKind kind;

  /// Valeur trouvée sur le serveur au moment du rejeu (avant écrasement).
  final Map<String, dynamic> serverValue;

  /// Valeur de la file, désormais écrite sur le serveur.
  final Map<String, dynamic> queuedValue;
}

/// Compte rendu d'une passe de [PendingCharacterWriteSyncer.syncWithReport].
class SyncReport {
  const SyncReport({
    this.synced = const {},
    this.abandonedCharacterIds = const {},
    this.conflicts = const [],
  });

  /// Personnages dont au moins une entrée a été écrite avec succès.
  final Set<String> synced;

  /// Personnages dont une entrée vient d'être abandonnée pendant cette passe
  /// (refus non rejouable répété, D34/D186).
  final Set<String> abandonedCharacterIds;

  /// Modifications concurrentes détectées (écriture rejouée malgré tout).
  final List<ServerValueConflict> conflicts;
}

/// Vide, best-effort, la file d'attente [PendingCharacterWrites]
/// (`core/cache/pending_character_write_queue.dart`) en écrivant directement
/// en base chaque entrée en attente — jamais via
/// `CharacterRepository.updateHp`/`addXp`/`castSpell`/
/// `setInnateSpellUsesSpent`/`useClassFeature`, qui referaient la
/// vérification de connectivité déjà acquise à ce stade par l'appelant (voir
/// `presentation/providers/character_write_sync_coordinator.dart`, seul
/// appelant de [sync]). Exception assumée : [PendingCharacterWriteKind.rest]
/// EST rejouée via [SupabaseCharacterRepository.applyRestOnline] (voir
/// [_restWriter]) — un repos touche trop de tables pour dupliquer sa
/// logique ici comme le sont les quelques lignes de `castSpell`/
/// `setInnateSpellUsesSpent`/`useClassFeature` (voir [_applyWrite]).
/// `applyRestOnline` ne vérifie lui-même aucune connectivité (il suppose
/// déjà être en ligne, comme son nom l'indique), donc ce principe reste
/// respecté : [sync] n'est appelé que lorsque le réseau est effectivement
/// revenu.
///
/// Volontairement séparée de `SupabaseCharacterRepository` (pas une méthode
/// de plus sur `CharacterRepository`) : cette synchro n'est jamais déclenchée
/// depuis un écran (qui dépend de l'abstraction `CharacterRepository` pour
/// pouvoir être testé avec un double), seulement depuis le coordinateur de
/// synchro — ajouter cette méthode à l'interface aurait forcé tous les
/// doubles de test de ce dépôt à l'implémenter pour rien. [_restWriter] est
/// la seule exception à cette séparation (voir sa documentation) : il s'agit
/// du type CONCRET `SupabaseCharacterRepository`, jamais de l'abstraction
/// `CharacterRepository`, justement pour ne rien ajouter à cette dernière.
///
/// Isolation par utilisateur : ne considère jamais que les entrées de
/// [ownerId] du joueur actuellement connecté (voir
/// `PendingCharacterWriteQueue.allForOwner`) — même garantie que le reste de
/// `SupabaseCharacterRepository`.
class PendingCharacterWriteSyncer {
  PendingCharacterWriteSyncer(
    this._client,
    this._pendingWrites,
    ReferenceDataCache cache,
    this._restWriter,
  ) : _detailCache = CharacterDetailCache(cache);

  final SupabaseClient _client;
  final PendingCharacterWriteQueue _pendingWrites;
  final CharacterDetailCache _detailCache;

  /// Fournit [SupabaseCharacterRepository.applyRestOnline], seule logique de
  /// réécriture pas directement dupliquée ici (voir la doc de classe) — une
  /// instance DISTINCTE de celle utilisée par l'écran (voir ses sites de
  /// construction, `character_providers.dart`), sans conséquence : même
  /// principe que l'ancien partage de [_pendingWrites] entre
  /// `SupabaseCharacterRepository._pendingWriteSyncer` et ce
  /// [PendingCharacterWriteSyncer] (aucun état mutable propre à
  /// `SupabaseCharacterRepository` en dehors de ce qui est déjà injecté et
  /// partagé — client Supabase, cache, file).
  final SupabaseCharacterRepository _restWriter;

  /// Tente d'écrire en base chaque entrée en attente du joueur actuellement
  /// connecté (aucune tentative si personne n'est connecté). Une entrée dont
  /// l'écriture échoue est laissée telle quelle pour une prochaine tentative
  /// — [sync] ne lève jamais d'exception, chaque échec individuel est
  /// silencieusement absorbé (best-effort, cohérent avec le reste du
  /// mécanisme de cache/synchro de ce dépôt), **sauf** un refus non rejouable
  /// répété au-delà du seuil (voir [_isNonRetryable] et D34 ci-dessous).
  ///
  /// Chaque entrée est relue juste avant son envoi (elle a pu être retirée
  /// ou remplacée depuis le relevé initial, voir le corps de la boucle).
  /// L'envoi lui-même est sérialisé par
  /// `PendingCharacterWriteQueue.runExclusive` avec toute écriture en ligne
  /// concurrente du même type/cible pour le même personnage
  /// (`SupabaseCharacterRepository.updateHp`/`addXp`/`castSpell`/
  /// `setInnateSpellUsesSpent`/`useClassFeature`/`applyRest`) — D33 du
  /// registre de dette technique : sans ce verrou, les deux chemins
  /// pouvaient envoyer au serveur, au même instant, un `PATCH` du même
  /// type/cible pour le même personnage, avec un ordre d'arrivée réseau non
  /// garanti.
  ///
  /// Une entrée dont l'écriture réussit :
  /// - est reportée dans le cache de la fiche
  ///   (`CharacterDetailCache.applyConfirmedColumns`), **seulement pour
  ///   `hp`/`xp`/`conditions`/`currency`** (voir [_cacheColumnsOf]) : la synchro passe
  ///   souvent fiche
  ///   fermée (démarrage de l'app, retour du réseau), personne ne relit alors
  ///   la fiche et le cache resterait sur l'état serveur d'avant. Les autres
  ///   kinds (D11) ne touchent jamais `characters` directement — rien à
  ///   patcher dans ce cache, voir la doc de classe de
  ///   `SupabaseCharacterRepository._recordConfirmedWrite` pour la même
  ///   limite assumée côté écriture en ligne ;
  /// - n'est retirée de la file que si elle y est encore telle qu'elle a été
  ///   lue (`PendingCharacterWriteQueue.removeIfUnchanged`) : une valeur
  ///   plus récente mise en file pendant l'écriture réseau reste en file
  ///   pour la prochaine synchro, au lieu d'être supprimée sans jamais avoir
  ///   été envoyée.
  ///
  /// Une entrée refusée par le serveur de façon **non rejouable**
  /// (contrainte en base, RLS — voir [_isNonRetryable]) incrémente son
  /// compteur d'échecs (`PendingCharacterWriteQueue.recordNonRetryableFailure`)
  /// au lieu d'être laissée en l'état : au-delà du seuil
  /// (`PendingCharacterWriteQueue.abandonAfterConsecutiveFailures`), elle est
  /// abandonnée (ne sera plus jamais retentée ni superposée à la fiche, voir
  /// `PendingCharacterWriteQueue.forCharacter`/`allForOwner`) — D34 du
  /// registre de dette technique : sans cela, une telle entrée restait
  /// indéfiniment en file, retentée sans jamais aboutir, sans jamais être
  /// signalée au joueur. Son message est consommé et affiché par
  /// `CharacterWriteSyncCoordinator` (`PendingCharacterWriteQueue
  /// .consumeAbandonedMessages`), pas par [sync] lui-même : [PendingCharacterWriteSyncer]
  /// ne connaît rien de l'UI. Un échec réseau transitoire (`SocketException`,
  /// délai dépassé, erreur serveur générique) n'incrémente jamais ce
  /// compteur et continue d'être retenté indéfiniment (D32).
  ///
  /// [PendingCharacterWriteKind.rest] (D11) : un repos touche potentiellement
  /// plusieurs tables par plusieurs requêtes successives
  /// ([SupabaseCharacterRepository.applyRestOnline]), sans vraie transaction
  /// (limite déjà documentée sur `CharacterRepository.applyRest`) — un échec
  /// non rejouable sur l'une d'elles classe donc l'ENTRÉE ENTIÈRE comme non
  /// rejouable même si une étape précédente a déjà réussi côté serveur ;
  /// rejouer l'entrée une prochaine fois (si elle ne l'est pas encore) peut
  /// donc réappliquer certaines étapes déjà faites. Ce risque existe déjà
  /// pour un repos en ligne direct (deux taps rapprochés), [applyRest] ne
  /// l'aggrave pas, voir sa documentation.
  ///
  /// Retourne l'ensemble des identifiants de personnage synchronisés avec
  /// succès, pour que l'appelant puisse invalider
  /// `characterDetailProvider(characterId)` pour chacun d'eux (voir
  /// `character_write_sync_coordinator.dart`) — [PendingCharacterWriteSyncer]
  /// lui-même ne connaît rien de Riverpod.
  ///
  /// [onlyKinds] (`null` par défaut, voie normale : tout synchroniser —
  /// seul appelant réel, `CharacterWriteSyncCoordinator`) restreint cette
  /// passe aux seuls kinds listés. Introduit pour corriger un deadlock
  /// (trouvé en revue QA) : `SupabaseCharacterRepository
  /// ._blockIfPendingHpOrXpWrites` (D35) appelle [sync] DEPUIS L'INTÉRIEUR
  /// d'une entrée `rest` (ou `hp`/`xp`) déjà en cours de rejeu par CET APPEL
  /// [sync] lui-même (`applyRestOnline`, appelé pour un repos long/avec
  /// `appliedGain > 0`, applique ce garde-fou en tout premier). Sans ce
  /// filtre, l'appel imbriqué retente `PendingCharacterWriteQueue
  /// .runExclusive` pour la MÊME clé `(characterId, rest, '')` déjà tenue
  /// par l'appel englobant — attente circulaire, deadlock permanent (la
  /// clé ne se libère jamais, bloquant aussi tout nouveau repos EN LIGNE
  /// pour ce personnage jusqu'au redémarrage de l'app). En restreignant
  /// l'appel imbriqué à `{hp, xp}` (seul besoin réel de D35, voir sa
  /// documentation), il ne retente jamais la clé `rest`/`spellSlot`/
  /// `innateSpell`/`classFeature` déjà tenue par l'appelant.
  Future<Set<String>> sync({Set<PendingCharacterWriteKind>? onlyKinds}) async =>
      (await syncWithReport(onlyKinds: onlyKinds)).synced;

  /// Comme [sync] mais renvoie le compte rendu complet de la passe
  /// ([SyncReport]) : personnages synchronisés, personnages dont une entrée
  /// vient d'être **abandonnée** (D186 : leur fiche doit être invalidée, une
  /// entrée abandonnée n'est plus superposée) et modifications concurrentes
  /// détectées (F19/D178). Seul le coordinateur de synchro en a besoin.
  Future<SyncReport> syncWithReport({
    Set<PendingCharacterWriteKind>? onlyKinds,
  }) async {
    final ownerId = _client.auth.currentUser?.id;
    if (ownerId == null) {
      return const SyncReport();
    }

    final pending = await _pendingWrites.allForOwner(ownerId);
    final synced = <String>{};
    final abandoned = <String>{};
    final conflicts = <ServerValueConflict>[];

    for (final listed in pending) {
      if (onlyKinds != null && !onlyKinds.contains(listed.kind)) continue;
      try {
        await _pendingWrites.runExclusive(
          characterId: listed.characterId,
          kind: listed.kind,
          targetId: listed.targetId,
          action: () async {
            // [pending] est un relevé pris avant le premier envoi : pendant
            // les envois précédents de cette boucle, l'entrée a pu être
            // retirée (écriture en ligne plus récente du même type/cible) ou
            // remplacée (nouvelle mise en file). Elle est donc relue juste
            // avant son propre envoi : absente, on s'arrête là ; remplacée,
            // c'est la version relue qui part — et qui est ensuite retirée
            // si elle n'a pas rechangé. Envoyer le relevé d'origine
            // écraserait une valeur plus récente déjà confirmée par le
            // serveur.
            final write = await _currentVersionOf(listed);
            if (write == null) return;
            // P6b : un payload `conditions` structurellement irrécupérable
            // (pas une liste, ou une liste contenant autre chose que des
            // chaînes, y compris une liste mixte `["blinded", 1]`) ne doit
            // jamais être écrit : un tableau vide ou partiel effacerait des
            // conditions du serveur. La ligne est supprimée (pas d'alerte :
            // elle n'apporte rien au joueur) plutôt que laissée en file, sans
            // quoi elle bloquerait le compteur de synchro, la déconnexion et
            // la suppression de compte. Les autres lignes ne sont pas
            // affectées.
            if (write.kind == PendingCharacterWriteKind.conditions) {
              final raw = write.payload['conditions'];
              if (raw is! List || raw.any((key) => key is! String)) {
                await _pendingWrites.removeIfUnchanged(write);
                return;
              }
            }

            // T3 : un payload `currency` invalide (pas un objet, totaux
            // manquants, valeur non entière ou négative) n'est jamais rejoué
            // — même traitement que `conditions` ci-dessus : ligne
            // supprimée, rien d'écrit, autres lignes non affectées.
            if (write.kind == PendingCharacterWriteKind.currency &&
                validCurrencyTotals(write.payload['totals']) == null) {
              await _pendingWrites.removeIfUnchanged(write);
              return;
            }

            // T5a : un payload `spellState`/`inventoryState`/`characterFlags`
            // invalide (mauvais type, valeur hors bornes, identifiant de cible
            // vide ou illisible) n'est jamais rejoué : ligne supprimée, rien
            // d'écrit, autres lignes non affectées.
            if (!_isReplayableState(write)) {
              await _pendingWrites.removeIfUnchanged(write);
              return;
            }

            ServerValueConflict? conflict;
            try {
              conflict = await _detectConcurrentChange(write, ownerId: ownerId);
              await _applyWrite(write, ownerId: ownerId);
            } on PostgrestException catch (error) {
              if (_isNonRetryable(error)) {
                final justAbandoned = await _pendingWrites
                    .recordNonRetryableFailure(
                      write: write,
                      reason: _abandonMessage(write.kind),
                    );
                if (justAbandoned) abandoned.add(write.characterId);
              }
              rethrow;
            }
            // Cache d'abord, retrait ensuite (ordre inverse de celui de
            // `SupabaseCharacterRepository._recordConfirmedWrite`) : si
            // l'app est tuée entre les deux, l'entrée restée en file est
            // égale à la valeur serveur et sera simplement rejouée sans
            // effet.
            final cacheColumns = _cacheColumnsOf(write);
            if (cacheColumns != null) {
              await _detailCache.applyConfirmedColumns(
                ownerId: ownerId,
                characterId: write.characterId,
                columns: cacheColumns,
              );
            }
            // D185 : un emplacement de sort confirmé est reporté dans le
            // cache de la fiche, sans quoi une relecture qui retombe sur le
            // cache (réseau retombé) afficherait l'ancien compteur.
            if (write.kind == PendingCharacterWriteKind.spellSlot) {
              await _detailCache.applyConfirmedSpellSlot(
                ownerId: ownerId,
                characterId: write.characterId,
                slotLevel: (write.payload['slotLevel'] as num).toInt(),
                slotsUsed: (write.payload['slotsUsed'] as num).toInt(),
                isPactSlot: write.payload['isPactSlot'] == true,
              );
            }
            await _recordStateInCache(write, ownerId: ownerId);
            await _pendingWrites.removeIfUnchanged(write);
            synced.add(write.characterId);
            if (conflict != null) conflicts.add(conflict);
          },
        );
      } catch (error, stackTrace) {
        // Laisse l'entrée pour la prochaine tentative — voir la doc de
        // [sync]. Si elle vient d'être abandonnée par
        // `recordNonRetryableFailure` (D34), elle a aussi cessé d'être
        // retentée : ce `catch` ne fait alors que taire l'exception sans
        // plus d'effet, [consumeAbandonedMessages] ayant déjà la main dessus.
        //
        // Remonté à Crashlytics (dette D13) malgré le repli silencieux
        // ci-dessus : ce `catch` couvre aussi bien un échec réseau
        // transitoire attendu (jamais distingué ici d'une régression
        // inattendue de `_detailCache.applyConfirmedColumns`/
        // `_pendingWrites.removeIfUnchanged` *après* une écriture serveur
        // déjà réussie, qui laisserait le cache local ou la file désynchronisés
        // du serveur sans jamais être signalé) — non-fatal, jamais bloquant.
        reportNonFatal(error, stackTrace);
      }
    }

    return SyncReport(
      synced: synced,
      abandonedCharacterIds: abandoned,
      conflicts: conflicts,
    );
  }

  /// Détection de modification concurrente (F19/D178, même compte sur deux
  /// appareils) pour une écriture de PV en file : compare la valeur serveur
  /// connue **à la mise en file** (`baseCurrentHp`/`baseTemporaryHp` du
  /// payload, voir `SupabaseCharacterRepository.updateHp`) à la valeur
  /// serveur **actuelle**. Si elles diffèrent, l'écriture est rejouée quand
  /// même (décision de Matthias du 10/11/2026 : alerte non bloquante, jamais
  /// de blocage) et le signal [ServerValueConflict] est renvoyé pour que
  /// l'appelant le fasse remonter.
  ///
  /// `null` (aucun signal) si : autre kind que `hp`, pas de base connue (fiche
  /// jamais mise en cache), serveur inchangé, ou serveur déjà égal à la valeur
  /// en file (écriture déjà appliquée, réponse perdue : rejeu idempotent, pas
  /// un conflit). Lecture réseau : une erreur remonte comme celle de
  /// l'écriture qui la suit (même traitement de rejeu/abandon).
  Future<ServerValueConflict?> _detectConcurrentChange(
    PendingCharacterWrite write, {
    required String ownerId,
  }) async {
    if (write.kind == PendingCharacterWriteKind.currency) {
      return _detectCurrencyChange(write, ownerId: ownerId);
    }
    if (write.kind != PendingCharacterWriteKind.hp) return null;
    final baseCurrent = write.payload['baseCurrentHp'];
    final baseTemporary = write.payload['baseTemporaryHp'];
    if (baseCurrent is! num || baseTemporary is! num) return null;

    final row = await _client
        .from('characters')
        .select('current_hp, temporary_hp')
        .eq('id', write.characterId)
        .eq('owner_id', ownerId)
        .maybeSingle();
    if (row == null) return null;
    final serverCurrent = (row['current_hp'] as num?)?.toInt();
    final serverTemporary = (row['temporary_hp'] as num?)?.toInt();
    if (serverCurrent == null || serverTemporary == null) return null;

    final queuedCurrent = (write.payload['currentHp'] as num).toInt();
    final queuedTemporary = (write.payload['temporaryHp'] as num).toInt();
    final alreadyApplied =
        serverCurrent == queuedCurrent && serverTemporary == queuedTemporary;
    final unchanged =
        serverCurrent == baseCurrent.toInt() &&
        serverTemporary == baseTemporary.toInt();
    if (alreadyApplied || unchanged) return null;

    return ServerValueConflict(
      characterId: write.characterId,
      kind: write.kind,
      serverValue: {'currentHp': serverCurrent, 'temporaryHp': serverTemporary},
      queuedValue: {'currentHp': queuedCurrent, 'temporaryHp': queuedTemporary},
    );
  }

  /// Détection F19/D178 pour une écriture `currency`, **monnaie par monnaie** :
  /// une monnaie est en conflit si le serveur n'a ni la valeur en file (déjà
  /// appliquée, réponse perdue : pas un conflit) ni la base mémorisée au
  /// premier enfilage (inchangé). Monnaie sans base connue : pas de
  /// détection. L'écriture part dans tous les cas.
  Future<ServerValueConflict?> _detectCurrencyChange(
    PendingCharacterWrite write, {
    required String ownerId,
  }) async {
    final totals = validCurrencyTotals(write.payload['totals']);
    if (totals == null) return null;
    final rawBases = write.payload['bases'];
    final bases = rawBases is Map
        ? {
            for (final entry in rawBases.entries)
              if (entry.key is String && entry.value is num)
                entry.key as String: (entry.value as num).toInt(),
          }
        : const <String, int>{};
    if (bases.isEmpty) return null;

    final row = await _client
        .from('characters')
        .select(totals.keys.join(', '))
        .eq('id', write.characterId)
        .eq('owner_id', ownerId)
        .maybeSingle();
    if (row == null) return null;

    final serverValue = <String, dynamic>{};
    final queuedValue = <String, dynamic>{};
    for (final entry in totals.entries) {
      final base = bases[entry.key];
      final server = (row[entry.key] as num?)?.toInt();
      if (base == null || server == null) continue;
      if (server == entry.value || server == base) continue;
      serverValue[entry.key] = server;
      queuedValue[entry.key] = entry.value;
    }
    if (serverValue.isEmpty) return null;
    return ServerValueConflict(
      characterId: write.characterId,
      kind: write.kind,
      serverValue: serverValue,
      queuedValue: queuedValue,
    );
  }

  /// Exécute réellement [write] en ligne — dispatch par [PendingCharacterWrite
  /// .kind]. `hp`/`xp` restent un simple `UPDATE` de `characters` (inchangé) ;
  /// `spellSlot`/`innateSpell`/`classFeature` (D11) réimplémentent ici, en
  /// quelques lignes, exactement le même `UPDATE`/`upsert` que la méthode en
  /// ligne correspondante de `SupabaseCharacterRepository` (dupliqué à
  /// dessein, voir la doc de classe) ; `rest` délègue à [_restWriter]
  /// (`applyRestOnline`, trop volumineux pour être dupliqué).
  Future<void> _applyWrite(
    PendingCharacterWrite write, {
    required String ownerId,
  }) async {
    switch (write.kind) {
      case PendingCharacterWriteKind.hp:
      case PendingCharacterWriteKind.xp:
        await _client
            .from('characters')
            .update(_cacheColumnsOf(write)!)
            .eq('id', write.characterId)
            .eq('owner_id', ownerId);
      case PendingCharacterWriteKind.spellSlot:
        final isPactSlot = write.payload['isPactSlot'] == true;
        final slotLevel = (write.payload['slotLevel'] as num).toInt();
        final slotsUsed = (write.payload['slotsUsed'] as num).toInt();
        await _client
            .from(isPactSlot ? 'character_pact_slots' : 'character_spell_slots')
            .update({'slots_used': slotsUsed})
            .eq('character_id', write.characterId)
            .eq('slot_level', slotLevel);
      case PendingCharacterWriteKind.innateSpell:
        final spellId = (write.payload['spellId'] as num).toInt();
        final usesSpent = (write.payload['usesSpent'] as num).toInt();
        await _client
            .from('character_spells')
            .update({'innate_uses_spent': usesSpent})
            .eq('character_id', write.characterId)
            .eq('spell_id', spellId)
            .eq('status', SpellStatus.innate.value);
      case PendingCharacterWriteKind.classFeature:
        final classFeatureId = (write.payload['classFeatureId'] as num).toInt();
        final usesRemaining = (write.payload['usesRemaining'] as num).toInt();
        await _client.from('character_feature_uses').upsert({
          'character_id': write.characterId,
          'class_feature_id': classFeatureId,
          'uses_remaining': usesRemaining,
        }, onConflict: 'character_id,class_feature_id');
      case PendingCharacterWriteKind.conditions:
        // P6b : remplacement complet du tableau (valeur absolue, donc rejeu
        // idempotent), filtré id ET owner_id. Zéro ligne affectée = refus
        // silencieux de la RLS ou personnage disparu : non rejouable, classé
        // comme un refus 42501 (abandon après le seuil, alerte persistée).
        final updated = await _client
            .from('characters')
            .update(_cacheColumnsOf(write)!)
            .eq('id', write.characterId)
            .eq('owner_id', ownerId)
            .select('id');
        if (updated.isEmpty) {
          throw const PostgrestException(
            message: 'Aucune ligne affectée (conditions).',
            code: '42501',
          );
        }
      case PendingCharacterWriteKind.currency:
        // T3 : totaux absolus (rejeu idempotent), filtré id ET owner_id. Zéro
        // ligne = refus silencieux de la RLS ou personnage disparu : non
        // rejouable (42501), comme `conditions`.
        final updated = await _client
            .from('characters')
            .update(_cacheColumnsOf(write)!)
            .eq('id', write.characterId)
            .eq('owner_id', ownerId)
            .select('id');
        if (updated.isEmpty) {
          throw const PostgrestException(
            message: 'Aucune ligne affectée (currency).',
            code: '42501',
          );
        }
      case PendingCharacterWriteKind.spellState:
        // T5a : état absolu d'un sort (rejeu idempotent), filtré par sort ET
        // par personnage (la RLS reste la garantie d'isolation). Zéro ligne =
        // refus non rejouable (42501), levé par `applySpellStateOnline`. La
        // limite de préparation n'est pas revérifiée au rejeu.
        await _restWriter.applySpellStateOnline(
          characterId: write.characterId,
          spellId: parseSpellTargetId(write.targetId)!,
          patch: parseSpellStatePayload(write.payload)!,
        );
      case PendingCharacterWriteKind.inventoryState:
        await _restWriter.applyInventoryStateOnline(
          characterId: write.characterId,
          inventoryId: write.targetId,
          patch: parseInventoryStatePayload(write.payload)!,
        );
      case PendingCharacterWriteKind.characterFlags:
        // T5a : colonnes absolues de `characters`, filtrées id ET owner_id ;
        // zéro ligne = refus non rejouable (42501).
        final updated = await _client
            .from('characters')
            .update(_cacheColumnsOf(write)!)
            .eq('id', write.characterId)
            .eq('owner_id', ownerId)
            .select('id');
        if (updated.isEmpty) {
          throw const PostgrestException(
            message: 'Aucune ligne affectée (characters).',
            code: '42501',
          );
        }
      case PendingCharacterWriteKind.journalEntry:
        // T4 : ajout (`INSERT` avec l'id client, idempotent : `23505` = déjà
        // là), modification (zéro ligne = 42501, non rejouable) ou suppression
        // (zéro ligne = déjà supprimée = succès), filtrées par `character_id`.
        await _restWriter.applyJournalWriteOnline(
          characterId: write.characterId,
          entryId: write.targetId,
          write: parseJournalPayload(write.payload)!,
        );
      case PendingCharacterWriteKind.rest:
        final type = RestType.values.byName(write.payload['type'] as String);
        final className = write.payload['className'] as String? ?? '';
        final hitDiceSpentByClassId = _decodeClassIdCountMap(
          write.payload['hitDiceSpentByClassId'],
        );
        final appliedGain =
            (write.payload['appliedGain'] as num?)?.toInt() ?? 0;
        final hitDiceRecoveredByClassId = _decodeClassIdCountMap(
          write.payload['hitDiceRecoveredByClassId'],
        );
        await _restWriter.applyRestOnline(
          ownerId: ownerId,
          characterId: write.characterId,
          type: type,
          className: className,
          hitDiceSpentByClassId: hitDiceSpentByClassId,
          appliedGain: appliedGain,
          hitDiceRecoveredByClassId: hitDiceRecoveredByClassId,
        );
    }
  }

  /// Décode une entrée `hitDiceSpentByClassId`/`hitDiceRecoveredByClassId`
  /// du payload JSON d'un repos en file (`Map<String, dynamic>` décodé par
  /// `jsonDecode`, voir `PendingCharacterWriteQueue.payload`) vers le
  /// `Map<String, int>` attendu par [SupabaseCharacterRepository.applyRestOnline] —
  /// `{}` si [raw] est `null` (repos mis en file avant l'ajout de ces deux
  /// clés, ou simplement vide).
  Map<String, int> _decodeClassIdCountMap(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final entry in raw.entries)
        entry.key as String: (entry.value as num).toInt(),
    };
  }

  /// Codes d'erreur Postgres/PostgREST qui ne seront jamais résolus en
  /// rejouant le même `PATCH` : violation de contrainte (groupes SQLSTATE
  /// `22` « data exception » et `23` « integrity constraint violation », ex.
  /// `23503` clé étrangère disparue si le personnage a été supprimé entre
  /// temps) ou refus RLS (`42501`, ex. accès retiré ou transféré depuis la
  /// mise en file). Tout le reste (erreur 5xx générique, délai dépassé,
  /// `SocketException` — pas une [PostgrestException]) est considéré
  /// transitoire : voir la doc de [sync] et D34 du registre de dette
  /// technique.
  ///
  /// Limite connue pour [PendingCharacterWriteKind.rest] (D11) : `applyRest`
  /// peut aussi lever une [CharacterFailure] explicite (« Personnage
  /// introuvable »), jamais une [PostgrestException] — ce cas n'est donc
  /// jamais classé non rejouable ici et continue d'être retenté
  /// indéfiniment, contrairement à ce que D34 voudrait. Accepté comme limite
  /// de cette extension (cas rare : personnage supprimé entre la mise en
  /// file et la synchronisation) plutôt que généraliser [_isNonRetryable] à
  /// [CharacterFailure] pour ce seul cas — à reprendre si ça devient gênant
  /// en pratique (voir `docs/dette-technique.md`).
  bool _isNonRetryable(PostgrestException error) {
    final code = error.code;
    if (code == null) return false;
    return code == '42501' || code.startsWith('23') || code.startsWith('22');
  }

  /// Message affiché au joueur (voir `CharacterWriteSyncCoordinator`) quand
  /// une entrée [kind] est abandonnée — D34.
  String _abandonMessage(PendingCharacterWriteKind kind) {
    final label = switch (kind) {
      PendingCharacterWriteKind.hp => 'vos PV',
      PendingCharacterWriteKind.xp => 'votre XP',
      PendingCharacterWriteKind.spellSlot => 'un lancer de sort',
      PendingCharacterWriteKind.innateSpell => 'un lancer de sort inné',
      PendingCharacterWriteKind.classFeature =>
        'une utilisation d\'aptitude de classe',
      PendingCharacterWriteKind.rest => 'un repos',
      PendingCharacterWriteKind.conditions => 'vos conditions',
      PendingCharacterWriteKind.currency => 'vos monnaies',
      PendingCharacterWriteKind.spellState => 'vos réglages de sorts',
      PendingCharacterWriteKind.inventoryState => "vos réglages d'inventaire",
      PendingCharacterWriteKind.characterFlags => 'vos réglages de personnage',
      PendingCharacterWriteKind.journalEntry => 'votre journal',
    };
    return 'Un ajustement de $label resté en attente a été refusé par le '
        'serveur et a été abandonné (personnage supprimé, accès retiré, ou '
        'autre changement incompatible). Rouvrez la fiche pour vérifier la '
        'valeur actuelle.';
  }

  /// Version actuellement en file de l'entrée [listed] (même compte, même
  /// personnage, même type ET même cible — voir [PendingCharacterWrite
  /// .targetId], D11), ou `null` si elle n'y est plus.
  Future<PendingCharacterWrite?> _currentVersionOf(
    PendingCharacterWrite listed,
  ) async {
    final current = await _pendingWrites.forCharacter(
      ownerId: listed.ownerId,
      characterId: listed.characterId,
    );
    for (final write in current) {
      if (write.kind == listed.kind && write.targetId == listed.targetId) {
        return write;
      }
    }
    return null;
  }

  /// Colonnes de `characters` écrites pour [write] — à la fois le corps de
  /// l'`UPDATE` envoyé au serveur pour `hp`/`xp` (voir [_applyWrite]) et ce
  /// qui est reporté dans le cache de la fiche une fois cet `UPDATE` réussi.
  /// `null` pour tout autre kind (D11) : ces écritures ne touchent jamais
  /// `characters` directement, voir la doc de classe de
  /// `SupabaseCharacterRepository._recordConfirmedWrite` pour la même limite
  /// assumée côté écriture en ligne.
  Map<String, dynamic>? _cacheColumnsOf(PendingCharacterWrite write) {
    switch (write.kind) {
      case PendingCharacterWriteKind.hp:
        return {
          'current_hp': (write.payload['currentHp'] as num).toInt(),
          'temporary_hp': (write.payload['temporaryHp'] as num).toInt(),
        };
      case PendingCharacterWriteKind.xp:
        return {'xp': (write.payload['newXp'] as num).toInt()};
      case PendingCharacterWriteKind.conditions:
        final raw = write.payload['conditions'];
        return {
          'conditions': [
            if (raw is List)
              for (final key in raw)
                if (key is String) key,
          ],
        };
      case PendingCharacterWriteKind.currency:
        return {...?validCurrencyTotals(write.payload['totals'])};
      case PendingCharacterWriteKind.characterFlags:
        return parseCharacterFlagsPayload(write.payload)?.toColumns();
      case PendingCharacterWriteKind.spellState:
      case PendingCharacterWriteKind.inventoryState:
      case PendingCharacterWriteKind.journalEntry:
      case PendingCharacterWriteKind.spellSlot:
      case PendingCharacterWriteKind.innateSpell:
      case PendingCharacterWriteKind.classFeature:
      case PendingCharacterWriteKind.rest:
        return null;
    }
  }

  /// `false` si [write] est un réglage d'état (T5a) ou une écriture de journal
  /// (T4) au payload ou à la cible invalide : il ne doit jamais être rejoué. Toujours `true` pour les
  /// autres kinds (validés ailleurs).
  bool _isReplayableState(PendingCharacterWrite write) {
    switch (write.kind) {
      case PendingCharacterWriteKind.spellState:
        return parseSpellTargetId(write.targetId) != null &&
            parseSpellStatePayload(write.payload) != null;
      case PendingCharacterWriteKind.inventoryState:
        return isValidInventoryTargetId(write.targetId) &&
            parseInventoryStatePayload(write.payload) != null;
      case PendingCharacterWriteKind.characterFlags:
        return parseCharacterFlagsPayload(write.payload) != null;
      case PendingCharacterWriteKind.journalEntry:
        return isValidJournalTargetId(write.targetId) &&
            parseJournalPayload(write.payload) != null;
      case PendingCharacterWriteKind.hp:
      case PendingCharacterWriteKind.xp:
      case PendingCharacterWriteKind.spellSlot:
      case PendingCharacterWriteKind.innateSpell:
      case PendingCharacterWriteKind.classFeature:
      case PendingCharacterWriteKind.rest:
      case PendingCharacterWriteKind.conditions:
      case PendingCharacterWriteKind.currency:
        return true;
    }
  }

  /// Reporte dans le cache de la fiche l'état d'un sort/objet confirmé par le
  /// rejeu (T5a) — les réglages de `characters` passent par
  /// [_cacheColumnsOf].
  Future<void> _recordStateInCache(
    PendingCharacterWrite write, {
    required String ownerId,
  }) async {
    switch (write.kind) {
      case PendingCharacterWriteKind.spellState:
        await _detailCache.applyConfirmedSpellState(
          ownerId: ownerId,
          characterId: write.characterId,
          spellId: parseSpellTargetId(write.targetId)!,
          patch: parseSpellStatePayload(write.payload)!,
        );
      case PendingCharacterWriteKind.inventoryState:
        await _detailCache.applyConfirmedInventoryState(
          ownerId: ownerId,
          characterId: write.characterId,
          inventoryId: write.targetId,
          patch: parseInventoryStatePayload(write.payload)!,
        );
      case PendingCharacterWriteKind.journalEntry:
        await _detailCache.applyConfirmedJournalEntry(
          ownerId: ownerId,
          characterId: write.characterId,
          entryId: write.targetId,
          write: parseJournalPayload(write.payload)!,
        );
      case PendingCharacterWriteKind.hp:
      case PendingCharacterWriteKind.xp:
      case PendingCharacterWriteKind.spellSlot:
      case PendingCharacterWriteKind.innateSpell:
      case PendingCharacterWriteKind.classFeature:
      case PendingCharacterWriteKind.rest:
      case PendingCharacterWriteKind.conditions:
      case PendingCharacterWriteKind.currency:
      case PendingCharacterWriteKind.characterFlags:
        break;
    }
  }
}
