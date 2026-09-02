import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/wood_back_header.dart';
import '../domain/character_class_feature.dart';
import '../domain/character_detail.dart';
import '../domain/character_failure.dart';
import '../domain/character_inventory_item.dart';
import '../domain/character_spell_entry.dart';
import '../domain/character_spell_slot.dart';
import '../domain/currency_kind.dart';
import '../domain/hp_adjustment.dart';
import '../domain/inventory_catalog_item.dart';
import '../domain/proficiency_bonus.dart';
import '../domain/rest_type.dart';
import '../domain/reward_item_draft.dart';
import '../domain/saving_throw_calculator.dart';
import '../domain/write_outcome.dart';
import 'providers/character_detail_provider.dart';
import 'providers/character_providers.dart';
import 'widgets/add_reward_sheet.dart';
import 'widgets/add_xp_sheet.dart';
import 'widgets/character_ability_score_grid.dart';
import 'widgets/character_adventures_card.dart';
import 'widgets/character_appearance_card.dart';
import 'widgets/character_detail_tab_bar.dart';
import 'widgets/character_identity_card.dart';
import 'widgets/character_inventory_tab_body.dart';
import 'widgets/character_saving_throws_card.dart';
import 'widgets/character_skills_tab_body.dart';
import 'widgets/character_spells_tab_body.dart';
import 'widgets/character_story_tab_body.dart';
import 'widgets/character_vitals_card.dart';
import 'widgets/hp_adjustment_sheet.dart';
import 'widgets/portrait_upload_sheet.dart';
import 'widgets/rest_sheet.dart';

/// Fiche personnage, route `/characters/:id` — remplace
/// `CharacterDetailPlaceholderScreen`. Les 5 onglets (voir
/// `CharacterDetailTab`) ont désormais tous un vrai contenu (même approche
/// "un onglet à la fois" que l'assistant de création : "Personnage",
/// "Compétences", "Sorts", "Inventaire" puis "Histoire" livrés séparément).
class CharacterDetailScreen extends ConsumerStatefulWidget {
  const CharacterDetailScreen({required this.characterId, super.key});

  final String characterId;

  @override
  ConsumerState<CharacterDetailScreen> createState() =>
      _CharacterDetailScreenState();
}

class _CharacterDetailScreenState extends ConsumerState<CharacterDetailScreen> {
  CharacterDetailTab _tab = CharacterDetailTab.character;

  /// État PV optimiste local, en avance sur la dernière valeur confirmée par
  /// le serveur (`detail.currentHp`/`temporaryHp`) — `null` tant qu'aucune
  /// écriture PV n'est en cours/pas encore confirmée.
  ///
  /// Corrige un bug confirmé en revue QA (voir
  /// `test/features/characters/presentation/character_detail_hp_stepper_race_test.dart`) :
  /// sans cet état, deux taps rapides sur le stepper "+"/"-" du bandeau PV
  /// calculaient tous les deux leur nouvelle valeur à partir du même
  /// `detail` (l'état du dernier build), capturé dans la closure du premier
  /// tap — le second aller-retour réseau réécrivait alors la même valeur
  /// que le premier au lieu d'incrémenter à nouveau, perdant silencieusement
  /// un point de soin/dégât. [_effectiveDetail] fusionne cet état local par
  ///-dessus le dernier `detail` connu pour que tout calcul ultérieur
  /// (accumulation d'un second tap, mais aussi l'affichage du bandeau PV)
  /// reparte de la valeur réellement voulue par le joueur, pas de la valeur
  /// serveur potentiellement obsolète le temps d'un aller-retour réseau.
  HpState? _localHpState;

  /// Compteur incrémenté par tout repos réussi ([_applyRest], court ou
  /// long) — sert à détecter qu'un ajustement resté en vol (PV via
  /// [_applyHpState], emplacement de sort via [_castSpell], ou utilisation
  /// d'aptitude via [_useClassFeature]) a été dépassé par un repos démarré
  /// entre-temps : sans ce garde-fou, l'écriture tardive de l'ajustement
  /// obsolète écrasait silencieusement en base le résultat du repos une fois
  /// son propre appel réseau enfin résolu (perte de données confirmée en
  /// revue QA, voir
  /// `test/features/characters/presentation/character_detail_rest_stale_hp_test.dart`/
  /// `character_detail_rest_stale_spell_slot_test.dart`/
  /// `character_detail_rest_stale_feature_uses_test.dart`).
  ///
  /// Un seul compteur partagé plutôt qu'un par domaine (PV/emplacements de
  /// sorts/aptitudes) : un repos (même court, qui ne touche ni les PV ni les
  /// emplacements de sorts) reste un événement qui peut invalider *au moins
  /// une* de ces trois surcouches optimistes (`character_feature_uses` est
  /// réinitialisée par les deux types de repos, voir `_resetFeatureUses`
  /// côté `CharacterRepository.applyRest`) — un domaine non concerné par un
  /// repos donné se contente alors d'une réaffirmation sans effet (même
  /// valeur réécrite), jamais incorrecte.
  ///
  /// Volontairement distinct d'un compteur générique incrémenté par *tout*
  /// ajustement PV : deux taps rapides successifs sur le stepper
  /// (`character_detail_hp_stepper_race_test.dart`) sont un cas normal déjà
  /// géré par l'accumulateur [_localHpState], pas une raison de déclencher
  /// [_reassertCurrentHpState] — seul un repos change ces valeurs
  /// indépendamment de la valeur locale déjà affichée à ce moment-là.
  int _restGeneration = 0;

  /// `true` dès le début de l'appel réseau de [_castSpell] pour un sort
  /// niveau ≥ 1 (jamais pour un sort niveau 0, aucun appel réseau), `false`
  /// une fois résolu — désactive tout l'onglet "Sorts" le temps de cette
  /// fenêtre (voir `CharacterSpellsTabBody.actionsDisabled`).
  ///
  /// Ferme une course trouvée en revue de code : `CharacterRepository
  /// .castSpell` écrit une valeur *absolue* de `slots_used` (pas un
  /// incrément atomique côté serveur) — sans ce verrou, deux lancers
  /// rapprochés (même niveau ou non) pouvaient résoudre dans le désordre et
  /// laisser l'un écraser silencieusement le résultat de l'autre, perdant un
  /// emplacement consommé sans aucune erreur visible. Verrouiller tout
  /// l'onglet le temps d'un lancer (plutôt que suivre une clé par niveau) est
  /// le choix le plus simple qui reste correct dans tous les cas, même
  /// principe que [_isApplyingRest] pour le repos.
  bool _isCastingSpell = false;

  /// `true` dès le début de l'appel réseau de [_useClassFeature], `false`
  /// une fois résolu — même rationale et même verrouillage "toute la carte"
  /// que [_isCastingSpell], voir sa documentation (`CharacterRepository
  /// .useClassFeature` écrit lui aussi une valeur absolue de
  /// `uses_remaining`).
  bool _isUsingFeature = false;

  /// `true` dès le début de l'appel réseau de toute écriture de l'onglet
  /// "Inventaire" (Utiliser/Équiper/Retirer un objet, ajuster une monnaie,
  /// ajouter un objet du catalogue/personnalisé, ajouter une récompense),
  /// `false` seulement une fois la fiche effectivement rafraîchie depuis le
  /// serveur (voir [_refreshCharacterDetail], appelée par chacune de ces
  /// méthodes juste avant de rendre la main à leur `finally`) — désactive
  /// tout l'onglet le temps de cette fenêtre (voir
  /// `CharacterInventoryTabBody.actionsDisabled`), même principe que
  /// [_isCastingSpell]/[_isUsingFeature].
  ///
  /// **Volontairement pas de garde-fou [_restGeneration] ici** (à la
  /// différence de [_castSpell]/[_useClassFeature]) : vérifié contre
  /// `CharacterRepository.applyRest`, aucun repos (court ou long) ne touche
  /// `character_inventory` ni les colonnes `characters.currency_*` — un
  /// repos ne peut donc jamais entrer en course avec une écriture de cet
  /// onglet, contrairement aux emplacements de sorts/utilisations
  /// d'aptitudes qu'un repos réinitialise.
  ///
  /// Pas d'état optimiste local (contrairement à [_localSpellSlotsUsed]/
  /// [_localFeatureUsesRemaining]) : **attention**, contrairement à ce
  /// qu'affirmait une version précédente de ce commentaire, le verrou ne
  /// suffit *pas* à lui seul à empêcher tout second tap concurrent de
  /// réconcilier une donnée périmée — `characterDetailProvider` a
  /// `skipLoadingOnRefresh: true` (réglage par défaut de Riverpod), donc
  /// juste après un simple `ref.invalidate`, `detailAsync.when(data: ...)`
  /// continue de renvoyer l'ancienne valeur tant que le refetch qu'il
  /// déclenche n'a pas résolu. Relâcher [_isWritingInventory] dès la fin de
  /// l'appel d'écriture (sans attendre ce refetch) laissait donc une
  /// fenêtre, même brève, où un second tap immédiat repartait encore du
  /// `detail` désormais périmé — perdant silencieusement un décrément de
  /// quantité par exemple (bug confirmé en revue de code, voir
  /// `character_detail_inventory_actions_test.dart`, test "double-tap
  /// ... après résolution du 1er appel"). [_refreshCharacterDetail] attend
  /// désormais la résolution effective du refetch avant de rendre la main,
  /// ce qui ferme cette fenêtre sans avoir besoin d'un état optimiste local
  /// dédié : au plus un seul appel d'écriture de cet onglet est jamais en
  /// vol à la fois, refetch inclus.
  bool _isWritingInventory = false;

  /// Invalide [characterDetailProvider] puis attend que le refetch qu'il
  /// déclenche résolve avant de retourner, plutôt qu'un simple
  /// `ref.invalidate` "tire et oublie" — voir la documentation de
  /// [_isWritingInventory] pour la fenêtre de donnée périmée que ceci ferme.
  /// Utilisée par toutes les écritures de l'onglet "Inventaire" (voir leur
  /// `finally`, qui ne relâche [_isWritingInventory] qu'après cet appel).
  ///
  /// Une erreur du refetch lui-même est volontairement avalée ici plutôt que
  /// remontée à l'appelant : `characterDetailProvider` la porte de toute
  /// façon pour le prochain `build()` (voir `detailAsync.error`), pas la
  /// peine de la traiter une deuxième fois côté appelant — ce helper existe
  /// uniquement pour fermer la fenêtre de staleness décrite ci-dessus, pas
  /// pour décider quel message d'erreur afficher (déjà décidé par
  /// l'appelant, qui vient de réussir ou d'échouer sa propre écriture).
  Future<void> _refreshCharacterDetail() async {
    ref.invalidate(characterDetailProvider(widget.characterId));
    try {
      await ref.read(characterDetailProvider(widget.characterId).future);
    } catch (_) {
      // Voir la documentation ci-dessus : ignoré volontairement.
    }
  }

  /// `true` dès le début de [_applyRest] (avant son appel réseau), `false`
  /// une fois résolu (succès ou échec) — désactive le stepper PV et le
  /// bouton crayon "Ajuster PV" de `CharacterVitalsCard` le temps de cette
  /// fenêtre (voir `CharacterVitalsCard.hpActionsDisabled`).
  ///
  /// Ferme la course résiduelle confirmée en revue de code (l'autre sens de
  /// celle déjà couverte par [_restGeneration]) : sans ce verrou, un
  /// ajustement PV pouvait démarrer *pendant* qu'un repos long écrit encore
  /// en base et résoudre *avant* lui — [_restGeneration] ne détecte alors
  /// aucun conflit (il n'a pas encore changé au moment où cet ajustement
  /// capture sa valeur), et l'écriture `current_hp = max_hp` du repos,
  /// arrivée après coup, écrase silencieusement le dégât/soin que le joueur
  /// venait d'appliquer. Verrouiller les déclencheurs plutôt que de tenter
  /// de réconcilier après coup l'ordre de résolution réseau (impossible à
  /// garantir de façon fiable côté client) ferme cette fenêtre sans
  /// dépendre de cet ordre.
  bool _isApplyingRest = false;

  /// État optimiste local des emplacements de sorts consommés
  /// (`character_spell_slots.slots_used`), en avance sur la dernière valeur
  /// serveur connue — `{niveau: slots_used}`, seuls les niveaux ayant un
  /// lancer de sort en vol ou récemment résolu y figurent (jamais tous les
  /// niveaux). Même principe que [_localHpState], généralisé à plusieurs clés
  /// indépendantes : voir [_castSpell]/[_effectiveDetail].
  Map<int, int> _localSpellSlotsUsed = {};

  /// État optimiste local des utilisations restantes d'aptitudes de classe
  /// (`character_feature_uses.uses_remaining`) — `{class_feature_id:
  /// uses_remaining}`, même principe que [_localSpellSlotsUsed] mais pour
  /// [CharacterClassFeature.id]. Voir [_useClassFeature]/[_effectiveDetail].
  Map<int, int> _localFeatureUsesRemaining = {};

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  /// Fusionne [_localHpState]/[_localSpellSlotsUsed]/
  /// [_localFeatureUsesRemaining] (s'ils existent) par-dessus [detail] :
  /// `max_hp` vient toujours de la dernière donnée serveur connue (jamais
  /// modifié localement), seuls `current_hp`/`temporary_hp` et les entrées
  /// couvertes par ces deux maps peuvent être en avance.
  CharacterDetail _effectiveDetail(CharacterDetail detail) {
    var result = detail;

    final localHp = _localHpState;
    if (localHp != null) {
      result = result.copyWith(
        currentHp: localHp.currentHp,
        temporaryHp: localHp.temporaryHp,
      );
    }

    if (_localSpellSlotsUsed.isNotEmpty) {
      result = result.copyWith(
        spellSlots: [
          for (final slot in result.spellSlots)
            if (_localSpellSlotsUsed[slot.level] case final used?)
              CharacterSpellSlot(
                level: slot.level,
                total: slot.total,
                used: used,
              )
            else
              slot,
        ],
      );
    }

    if (_localFeatureUsesRemaining.isNotEmpty) {
      result = result.copyWith(
        classFeatures: [
          for (final feature in result.classFeatures)
            if (_localFeatureUsesRemaining[feature.id] case final remaining?)
              CharacterClassFeature(
                id: feature.id,
                name: feature.name,
                level: feature.level,
                usesMax: feature.usesMax,
                usesRemaining: remaining,
                restType: feature.restType,
                description: feature.description,
              )
            else
              feature,
        ],
      );
    }

    return result;
  }

  Future<void> _applyHpState(CharacterDetail detail, HpState newState) async {
    final baseState = _hpStateOf(detail);
    if (newState.currentHp == baseState.currentHp &&
        newState.temporaryHp == baseState.temporaryHp) {
      return;
    }

    // Bascule optimiste immédiate (avant l'appel réseau) : c'est elle qui
    // permet à un second tap rapide de repartir de cette valeur plutôt que
    // du `detail` désormais obsolète capturé au premier tap.
    final previousLocal = _localHpState;
    // Capturé avant l'appel réseau : voir la documentation de
    // [_restGeneration] pour ce que compare ce jeton une fois l'appel
    // résolu.
    final myRestGeneration = _restGeneration;
    setState(() => _localHpState = newState);

    try {
      final outcome = await ref
          .read(characterRepositoryProvider)
          .updateHp(
            characterId: widget.characterId,
            currentHp: newState.currentHp,
            temporaryHp: newState.temporaryHp,
          );
      if (_restGeneration != myRestGeneration) {
        // Un repos long a démarré (et déjà écrit son propre résultat en
        // base) pendant que cet appel réseau était en vol : l'écriture
        // ci-dessus vient malgré tout de réussir, avec des valeurs
        // désormais obsolètes. Regagne la cohérence serveur en réaffirmant
        // l'état PV actuellement affiché (déjà mis à jour par le repos)
        // plutôt que de laisser cette écriture obsolète stand — voir
        // [_restGeneration].
        await _reassertCurrentHpState();
        return;
      }
      if (outcome == WriteOutcome.queued) {
        // Aucune écriture serveur à attendre (mode hors-ligne, voir
        // `CharacterRepository.updateHp`) : le joueur ne doit jamais croire
        // à tort que son changement est déjà confirmé — l'état optimiste
        // local reste affiché tel quel, mais rien à invalider/rafraîchir
        // depuis le serveur pour l'instant (voir
        // `character_write_sync_coordinator.dart`, qui invalidera la fiche
        // une fois la synchro effectivement réussie).
        _showSnackBar(_offlineQueuedMessage);
        return;
      }
      ref.invalidate(characterDetailProvider(widget.characterId));
      // L'état local optimiste n'est pas relâché ici : il reste affiché tel
      // quel jusqu'à ce que le rafraîchissement déclenché ci-dessus livre
      // effectivement une donnée serveur qui le confirme (voir le
      // `ref.listen` de `build()`) — le relâcher immédiatement provoquerait
      // un aller-retour visuel (retour bref à l'ancienne valeur le temps du
      // nouvel appel réseau) avant de remonter à la valeur déjà affichée.
    } on CharacterFailure catch (failure) {
      // L'écriture a échoué : cette tentative n'a jamais été persistée,
      // revient à l'état local d'avant pour ne pas laisser un futur tap
      // accumuler depuis une valeur fantôme jamais écrite en base — sauf si
      // un repos long a entre-temps déjà établi un nouvel état local plus
      // récent : le revert écraserait alors son résultat avec la valeur
      // pré-repos (même garde-fou que le chemin de succès ci-dessus).
      if (mounted && _restGeneration == myRestGeneration) {
        setState(() => _localHpState = previousLocal);
      }
      _showSnackBar(failure.message);
    } catch (_) {
      if (mounted && _restGeneration == myRestGeneration) {
        setState(() => _localHpState = previousLocal);
      }
      _showSnackBar('Impossible de mettre à jour les PV. Réessayez.');
    }
  }

  /// Réécrit en base l'état PV actuellement affiché (dernière valeur locale
  /// optimiste, ou dernière donnée serveur connue à défaut) — appelé
  /// uniquement quand un ajustement PV resté en vol vient de résoudre après
  /// qu'un repos long a déjà écrit son propre résultat en base (voir
  /// [_restGeneration], appelé depuis [_applyHpState]).
  ///
  /// Si cette réaffirmation échoue à son tour, le bug d'origine (PV
  /// incohérents en base) peut resurgir sans que rien ne le signale —
  /// contrairement à un simple "best effort" silencieux, affiche donc un
  /// `SnackBar` d'erreur (même convention que le reste de cet écran) et
  /// force un rafraîchissement depuis la vraie source de vérité serveur
  /// (`ref.invalidate`) : sans ce rafraîchissement, `_localHpState`
  /// resterait affiché tel quel alors qu'il ne correspond plus forcément à
  /// ce qui est réellement en base.
  Future<void> _reassertCurrentHpState() async {
    if (!mounted) return;
    // `AsyncValue.value` (riverpod 3.x) est déjà nullable ici — équivalent
    // de `valueOrNull` des versions précédentes du package, absent de
    // celle-ci.
    final latest = ref.read(characterDetailProvider(widget.characterId)).value;
    if (latest == null) return;
    final state = _hpStateOf(latest);
    // Verrouille aussi les déclencheurs pendant cette écriture (même
    // mécanisme que [_applyRest]) : sans ça, un nouveau repos long pourrait
    // démarrer pendant que cette réaffirmation est encore en vol, résoudre
    // avant elle, et se faire écraser à son tour par cette écriture
    // désormais obsolète — reproduction du bug d'origine un niveau plus
    // profond (trouvé en revue de code). Fermer cette fenêtre-ci suffit en
    // pratique : au-delà, il faudrait enchaîner plusieurs repos quasi
    // simultanés pendant qu'une réaffirmation est déjà en vol, ce que ce
    // verrou empêche justement de déclencher.
    setState(() => _isApplyingRest = true);
    try {
      await ref
          .read(characterRepositoryProvider)
          .updateHp(
            characterId: widget.characterId,
            currentHp: state.currentHp,
            temporaryHp: state.temporaryHp,
          );
    } on CharacterFailure catch (failure) {
      ref.invalidate(characterDetailProvider(widget.characterId));
      _showSnackBar(failure.message);
    } catch (_) {
      ref.invalidate(characterDetailProvider(widget.characterId));
      _showSnackBar('Impossible de synchroniser les PV. Réessayez.');
    } finally {
      if (mounted) setState(() => _isApplyingRest = false);
    }
  }

  /// Exécute le lancer de [spell] au niveau d'emplacement [slotLevel] (voir
  /// `spell_action_sheet.dart::castSpellFlow` pour le calcul de ce niveau —
  /// `null` pour un sort niveau 0, rien à persister) : suit EXACTEMENT le
  /// même patron optimiste que [_applyHpState] (décrément immédiat de la
  /// pastille du niveau concerné, appel repository, `ref.invalidate` au
  /// succès), voir la spec de la tâche qui l'a introduit.
  ///
  /// [detail] doit déjà être la valeur *effective* (voir [_effectiveDetail]),
  /// pas la dernière donnée serveur brute — même règle que
  /// [_hpStateOf]/[_applyHpState] : un second lancer rapide sur le même
  /// niveau doit repartir de la valeur déjà décrémentée par le premier, pas
  /// d'une valeur serveur obsolète.
  ///
  /// Course concurrente avec un repos long (voir [_restGeneration]) : un
  /// repos long réinitialise aussi les emplacements de sorts, donc un lancer
  /// resté en vol peut voir son écriture (déjà résolue avec une valeur
  /// devenue obsolète) écraser silencieusement le résultat du repos une fois
  /// celui-ci déjà appliqué en base — même bug de fond que celui déjà corrigé
  /// sur [_applyHpState]/[_applyRest], fermé ici avec le même jeton plutôt
  /// qu'une nouvelle mécanique : en cas de mismatch,
  /// [_reassertSpellSlotState] réécrit l'état actuellement affiché (déjà à
  /// jour côté repos) par-dessus l'écriture obsolète.
  Future<void> _castSpell(
    CharacterDetail detail,
    CharacterSpellEntry spell,
    int? slotLevel,
  ) async {
    if (slotLevel == null) {
      // Sort niveau 0 : rien à persister (spec de la tâche).
      _showSnackBar('${spell.name} lancé.');
      return;
    }

    CharacterSpellSlot? slot;
    for (final candidate in detail.spellSlots) {
      if (candidate.level == slotLevel) {
        slot = candidate;
        break;
      }
    }
    // Ne devrait pas arriver : "Lancer" est désactivé en amont si aucun
    // niveau éligible n'a d'emplacement disponible (voir
    // `SpellCastEligibility`).
    if (slot == null) return;

    final newUsed = slot.used + 1;
    final previousOverride = _localSpellSlotsUsed[slotLevel];
    final myRestGeneration = _restGeneration;
    setState(() {
      _localSpellSlotsUsed = {..._localSpellSlotsUsed, slotLevel: newUsed};
      _isCastingSpell = true;
    });

    try {
      final outcome = await ref
          .read(characterRepositoryProvider)
          .castSpell(
            characterId: widget.characterId,
            slotLevel: slotLevel,
            slotsUsed: newUsed,
          );
      if (_restGeneration != myRestGeneration) {
        await _reassertSpellSlotState(slotLevel);
        return;
      }
      if (outcome == WriteOutcome.queued) {
        // Voir la documentation de `CharacterRepository.castSpell` : cette
        // écriture n'est jamais mise en file, contrairement à `updateHp`/
        // `addXp` — rien ne sera synchronisé plus tard, donc traité comme un
        // échec du point de vue de l'état local (revert) avec un message
        // honnête distinct de [_offlineQueuedMessage] (décision chef de
        // projet, revue QA/code).
        if (mounted && _restGeneration == myRestGeneration) {
          setState(
            () => _localSpellSlotsUsed = _withRevertedOverride(
              _localSpellSlotsUsed,
              slotLevel,
              previousOverride,
            ),
          );
        }
        _showSnackBar(_offlineNotPersistedMessage);
        return;
      }
      ref.invalidate(characterDetailProvider(widget.characterId));
      _showSnackBar('${spell.name} lancé (emplacement niveau $slotLevel).');
    } on CharacterFailure catch (failure) {
      if (mounted && _restGeneration == myRestGeneration) {
        setState(
          () => _localSpellSlotsUsed = _withRevertedOverride(
            _localSpellSlotsUsed,
            slotLevel,
            previousOverride,
          ),
        );
      }
      _showSnackBar(failure.message);
    } catch (_) {
      if (mounted && _restGeneration == myRestGeneration) {
        setState(
          () => _localSpellSlotsUsed = _withRevertedOverride(
            _localSpellSlotsUsed,
            slotLevel,
            previousOverride,
          ),
        );
      }
      _showSnackBar('Impossible de lancer ce sort. Réessayez.');
    } finally {
      if (mounted) setState(() => _isCastingSpell = false);
    }
  }

  /// Réécrit en base `character_spell_slots.slots_used` du niveau
  /// [slotLevel] avec l'état actuellement affiché (dernière valeur locale
  /// optimiste, ou dernière donnée serveur connue à défaut) — appelé
  /// uniquement quand un lancer de sort resté en vol vient de résoudre après
  /// qu'un repos long a déjà écrit son propre résultat en base (voir
  /// [_restGeneration], appelé depuis [_castSpell]). Même principe que
  /// [_reassertCurrentHpState] pour les PV.
  Future<void> _reassertSpellSlotState(int slotLevel) async {
    if (!mounted) return;
    final latest = ref.read(characterDetailProvider(widget.characterId)).value;
    if (latest == null) return;
    final effective = _effectiveDetail(latest);
    CharacterSpellSlot? slot;
    for (final candidate in effective.spellSlots) {
      if (candidate.level == slotLevel) {
        slot = candidate;
        break;
      }
    }
    if (slot == null) return;

    setState(() => _isApplyingRest = true);
    try {
      await ref
          .read(characterRepositoryProvider)
          .castSpell(
            characterId: widget.characterId,
            slotLevel: slotLevel,
            slotsUsed: slot.used,
          );
    } on CharacterFailure catch (failure) {
      ref.invalidate(characterDetailProvider(widget.characterId));
      _showSnackBar(failure.message);
    } catch (_) {
      ref.invalidate(characterDetailProvider(widget.characterId));
      _showSnackBar(
        'Impossible de synchroniser les emplacements de sorts. Réessayez.',
      );
    } finally {
      if (mounted) setState(() => _isApplyingRest = false);
    }
  }

  /// Exécute l'utilisation de [feature] (aptitude de classe à usage limité) :
  /// même patron optimiste que [_castSpell]/[_applyHpState] (décrément
  /// immédiat, appel repository, `ref.invalidate` au succès, verrou
  /// [_isUsingFeature] le temps de l'appel). Pas de sheet de choix
  /// intermédiaire (un seul coût possible, contrairement au lancer de sort) :
  /// [feature] est déjà le choix retenu.
  ///
  /// [detail] doit déjà être la valeur *effective* (voir [_effectiveDetail]),
  /// même règle que [_castSpell].
  ///
  /// Course concurrente avec un repos (voir [_restGeneration]) : un repos
  /// (court ou long) réinitialise `character_feature_uses.uses_remaining`
  /// (voir `CharacterRepository.applyRest`/`_resetFeatureUses`), donc une
  /// utilisation restée en vol peut voir son écriture (déjà résolue avec une
  /// valeur devenue obsolète) écraser silencieusement le résultat du repos
  /// une fois celui-ci déjà appliqué en base — même bug de fond que
  /// [_castSpell], fermé ici avec le même jeton plutôt qu'une nouvelle
  /// mécanique (trouvé par un test de mutation en revue QA).
  Future<void> _useClassFeature(
    CharacterDetail detail,
    CharacterClassFeature feature,
  ) async {
    CharacterClassFeature? current;
    for (final candidate in detail.classFeatures) {
      if (candidate.id == feature.id) {
        current = candidate;
        break;
      }
    }
    current ??= feature;
    final remaining = current.usesRemaining ?? current.usesMax;
    // Ne devrait pas arriver : "Utiliser" est désactivé en amont si
    // `remaining <= 0` (voir la sheet d'actions d'aptitude).
    if (remaining == null || remaining <= 0) return;

    final newRemaining = remaining - 1;
    final previousOverride = _localFeatureUsesRemaining[feature.id];
    final myRestGeneration = _restGeneration;
    setState(() {
      _localFeatureUsesRemaining = {
        ..._localFeatureUsesRemaining,
        feature.id: newRemaining,
      };
      _isUsingFeature = true;
    });

    try {
      final outcome = await ref
          .read(characterRepositoryProvider)
          .useClassFeature(
            characterId: widget.characterId,
            classFeatureId: feature.id,
            usesRemaining: newRemaining,
          );
      if (_restGeneration != myRestGeneration) {
        await _reassertFeatureUsesState(feature.id);
        return;
      }
      if (outcome == WriteOutcome.queued) {
        // Voir la documentation de `CharacterRepository.useClassFeature` et
        // le commentaire équivalent de [_castSpell] : jamais mise en file,
        // traité comme un échec côté état local, message distinct de
        // [_offlineQueuedMessage].
        if (mounted && _restGeneration == myRestGeneration) {
          setState(
            () => _localFeatureUsesRemaining = _withRevertedOverride(
              _localFeatureUsesRemaining,
              feature.id,
              previousOverride,
            ),
          );
        }
        _showSnackBar(_offlineNotPersistedMessage);
        return;
      }
      ref.invalidate(characterDetailProvider(widget.characterId));
      _showSnackBar('${feature.name} utilisée.');
    } on CharacterFailure catch (failure) {
      if (mounted && _restGeneration == myRestGeneration) {
        setState(
          () => _localFeatureUsesRemaining = _withRevertedOverride(
            _localFeatureUsesRemaining,
            feature.id,
            previousOverride,
          ),
        );
      }
      _showSnackBar(failure.message);
    } catch (_) {
      if (mounted && _restGeneration == myRestGeneration) {
        setState(
          () => _localFeatureUsesRemaining = _withRevertedOverride(
            _localFeatureUsesRemaining,
            feature.id,
            previousOverride,
          ),
        );
      }
      _showSnackBar("Impossible d'utiliser cette aptitude. Réessayez.");
    } finally {
      if (mounted) setState(() => _isUsingFeature = false);
    }
  }

  /// Réécrit en base `character_feature_uses.uses_remaining` de [featureId]
  /// avec l'état actuellement affiché (dernière valeur locale optimiste, ou
  /// dernière donnée serveur connue à défaut) — appelé uniquement quand une
  /// utilisation d'aptitude restée en vol vient de résoudre après qu'un
  /// repos a déjà écrit son propre résultat en base (voir [_restGeneration],
  /// appelé depuis [_useClassFeature]). Même principe que
  /// [_reassertSpellSlotState]/[_reassertCurrentHpState].
  Future<void> _reassertFeatureUsesState(int featureId) async {
    if (!mounted) return;
    final latest = ref.read(characterDetailProvider(widget.characterId)).value;
    if (latest == null) return;
    final effective = _effectiveDetail(latest);
    CharacterClassFeature? feature;
    for (final candidate in effective.classFeatures) {
      if (candidate.id == featureId) {
        feature = candidate;
        break;
      }
    }
    if (feature == null) return;
    final remaining = feature.usesRemaining ?? feature.usesMax;
    if (remaining == null) return;

    setState(() => _isApplyingRest = true);
    try {
      await ref
          .read(characterRepositoryProvider)
          .useClassFeature(
            characterId: widget.characterId,
            classFeatureId: featureId,
            usesRemaining: remaining,
          );
    } on CharacterFailure catch (failure) {
      ref.invalidate(characterDetailProvider(widget.characterId));
      _showSnackBar(failure.message);
    } catch (_) {
      ref.invalidate(characterDetailProvider(widget.characterId));
      _showSnackBar(
        "Impossible de synchroniser les aptitudes de classe. Réessayez.",
      );
    } finally {
      if (mounted) setState(() => _isApplyingRest = false);
    }
  }

  /// Action "Utiliser" un objet consommable (sheet d'actions d'objet,
  /// `item_action_sheet.dart`) : décrémente [item.quantity] de 1, ou
  /// supprime la ligne côté serveur si la nouvelle quantité atteint 0
  /// (décision UX tranchée par le chef de projet — voir
  /// `CharacterRepository.useInventoryItem`). Verrouille tout l'onglet le
  /// temps de l'appel réseau, refetch inclus (voir [_isWritingInventory]).
  Future<void> _useInventoryItem(CharacterInventoryItem item) async {
    final newQuantity = item.quantity - 1;
    setState(() => _isWritingInventory = true);
    try {
      final outcome = await ref
          .read(characterRepositoryProvider)
          .useInventoryItem(
            characterId: widget.characterId,
            inventoryId: item.id,
            newQuantity: newQuantity,
          );
      if (outcome == WriteOutcome.queued) {
        _showSnackBar(_offlineNotPersistedMessage);
        return;
      }
      await _refreshCharacterDetail();
      _showSnackBar(
        newQuantity <= 0
            ? '${item.name} utilisé — retiré de l\'inventaire.'
            : '${item.name} utilisé.',
      );
    } on CharacterFailure catch (failure) {
      _showSnackBar(failure.message);
    } catch (_) {
      _showSnackBar("Impossible d'utiliser cet objet. Réessayez.");
    } finally {
      if (mounted) setState(() => _isWritingInventory = false);
    }
  }

  /// Action "Équiper"/"Déséquiper" (sheet d'actions d'objet) : bascule
  /// [item.equipped], aucune confirmation. Ne touche à aucun champ de
  /// classe d'armure (n'existe nulle part dans [CharacterDetail], voir la
  /// spec de la tâche).
  Future<void> _toggleInventoryItemEquipped(CharacterInventoryItem item) async {
    final newEquipped = !item.equipped;
    setState(() => _isWritingInventory = true);
    try {
      final outcome = await ref
          .read(characterRepositoryProvider)
          .setInventoryItemEquipped(
            characterId: widget.characterId,
            inventoryId: item.id,
            equipped: newEquipped,
          );
      if (outcome == WriteOutcome.queued) {
        _showSnackBar(_offlineNotPersistedMessage);
        return;
      }
      await _refreshCharacterDetail();
      _showSnackBar(
        newEquipped ? '${item.name} équipé.' : '${item.name} déséquipé.',
      );
    } on CharacterFailure catch (failure) {
      _showSnackBar(failure.message);
    } catch (_) {
      _showSnackBar('Impossible de mettre à jour cet objet. Réessayez.');
    } finally {
      if (mounted) setState(() => _isWritingInventory = false);
    }
  }

  /// Action "Retirer" (déjà confirmée par le dialogue de la sheet d'actions
  /// d'objet, voir `item_action_sheet.dart::removeItemFlow`).
  Future<void> _removeInventoryItem(CharacterInventoryItem item) async {
    setState(() => _isWritingInventory = true);
    try {
      final outcome = await ref
          .read(characterRepositoryProvider)
          .removeInventoryItem(
            characterId: widget.characterId,
            inventoryId: item.id,
          );
      if (outcome == WriteOutcome.queued) {
        _showSnackBar(_offlineNotPersistedMessage);
        return;
      }
      await _refreshCharacterDetail();
      _showSnackBar('${item.name} retiré de l\'inventaire.');
    } on CharacterFailure catch (failure) {
      _showSnackBar(failure.message);
    } catch (_) {
      _showSnackBar('Impossible de retirer cet objet. Réessayez.');
    } finally {
      if (mounted) setState(() => _isWritingInventory = false);
    }
  }

  /// Ajustement de monnaie (stat box de tête d'onglet,
  /// `currency_adjustment_sheet.dart`) : [newAmount] est déjà le nouveau
  /// montant absolu, calculé par la sheet elle-même.
  Future<void> _adjustCurrency(CurrencyKind currency, int newAmount) async {
    setState(() => _isWritingInventory = true);
    try {
      final outcome = await ref
          .read(characterRepositoryProvider)
          .adjustCurrency(
            characterId: widget.characterId,
            currency: currency,
            newAmount: newAmount,
          );
      if (outcome == WriteOutcome.queued) {
        _showSnackBar(_offlineNotPersistedMessage);
        return;
      }
      await _refreshCharacterDetail();
    } on CharacterFailure catch (failure) {
      _showSnackBar(failure.message);
    } catch (_) {
      _showSnackBar("Impossible d'ajuster la monnaie. Réessayez.");
    } finally {
      if (mounted) setState(() => _isWritingInventory = false);
    }
  }

  /// Ajout d'un objet du catalogue (sheet "Depuis le catalogue",
  /// `add_item_flow.dart`).
  Future<void> _addInventoryItem(InventoryCatalogItem item, int quantity) async {
    setState(() => _isWritingInventory = true);
    try {
      final outcome = await ref
          .read(characterRepositoryProvider)
          .addInventoryItem(
            characterId: widget.characterId,
            itemId: item.id,
            quantity: quantity,
          );
      if (outcome == WriteOutcome.queued) {
        _showSnackBar(_offlineNotPersistedMessage);
        return;
      }
      await _refreshCharacterDetail();
      _showSnackBar('${item.name} ajouté à l\'inventaire.');
    } on CharacterFailure catch (failure) {
      _showSnackBar(failure.message);
    } catch (_) {
      _showSnackBar("Impossible d'ajouter cet objet. Réessayez.");
    } finally {
      if (mounted) setState(() => _isWritingInventory = false);
    }
  }

  /// Ajout d'un objet personnalisé (sheet "Objet personnalisé").
  Future<void> _addCustomInventoryItem(String customName, int quantity) async {
    setState(() => _isWritingInventory = true);
    try {
      final outcome = await ref
          .read(characterRepositoryProvider)
          .addCustomInventoryItem(
            characterId: widget.characterId,
            customName: customName,
            quantity: quantity,
          );
      if (outcome == WriteOutcome.queued) {
        _showSnackBar(_offlineNotPersistedMessage);
        return;
      }
      await _refreshCharacterDetail();
      _showSnackBar('$customName ajouté à l\'inventaire.');
    } on CharacterFailure catch (failure) {
      _showSnackBar(failure.message);
    } catch (_) {
      _showSnackBar("Impossible d'ajouter cet objet. Réessayez.");
    } finally {
      if (mounted) setState(() => _isWritingInventory = false);
    }
  }

  /// Ajoute une récompense (`add_reward_sheet.dart`) : [currencyDeltas] sont
  /// des montants à *ajouter* (pas des valeurs absolues, contrairement à
  /// [_adjustCurrency]) — recalculés ici en valeurs absolues à partir de
  /// [detail] (dernière fiche connue au moment de l'ouverture de la sheet)
  /// avant l'appel repository, même principe que [_addXp] (delta calculé
  /// côté appelant, jamais côté repository).
  ///
  /// `CharacterRepository.addReward` enchaîne deux requêtes (UPDATE
  /// `characters` pour la monnaie, puis INSERT batché `character_inventory`
  /// pour les objets) : si la première réussit et la seconde échoue,
  /// l'exception qui remonte ici correspond à un échec *partiel* — la
  /// monnaie a déjà été persistée en base. Sans rafraîchir [detail] sur ce
  /// chemin d'échec (bug confirmé en revue de code), un retry immédiat avec
  /// les mêmes valeurs recalculait [newCurrencyTotals] depuis ce [detail]
  /// désormais périmé et ajoutait la monnaie une seconde fois en base —
  /// perte de cohérence silencieuse. [_refreshCharacterDetail] est donc
  /// appelée aussi bien au succès qu'à l'échec, pour que tout retry reparte
  /// d'un état serveur frais plutôt que du [detail] qui a causé le
  /// double-ajout (voir
  /// `character_detail_inventory_actions_test.dart`, test "retry après
  /// échec partiel").
  Future<void> _addReward(
    CharacterDetail detail,
    Map<CurrencyKind, int> currencyDeltas,
    List<RewardItemDraft> items,
  ) async {
    final newCurrencyTotals = <CurrencyKind, int>{
      for (final entry in currencyDeltas.entries)
        entry.key: _currentCurrencyAmount(detail, entry.key) + entry.value,
    };

    setState(() => _isWritingInventory = true);
    try {
      final outcome = await ref
          .read(characterRepositoryProvider)
          .addReward(
            characterId: widget.characterId,
            newCurrencyTotals: newCurrencyTotals,
            items: items,
          );
      if (outcome == WriteOutcome.queued) {
        _showSnackBar(_offlineNotPersistedMessage);
        return;
      }
      await _refreshCharacterDetail();
      _showSnackBar('Récompense ajoutée.');
    } on CharacterFailure catch (failure) {
      await _refreshCharacterDetail();
      _showSnackBar(failure.message);
    } catch (_) {
      await _refreshCharacterDetail();
      _showSnackBar("Impossible d'ajouter la récompense. Réessayez.");
    } finally {
      if (mounted) setState(() => _isWritingInventory = false);
    }
  }

  int _currentCurrencyAmount(CharacterDetail detail, CurrencyKind currency) =>
      switch (currency) {
        CurrencyKind.platinum => detail.currencyPp,
        CurrencyKind.gold => detail.currencyGp,
        CurrencyKind.electrum => detail.currencyEp,
        CurrencyKind.silver => detail.currencySp,
        CurrencyKind.copper => detail.currencyCp,
      };

  /// Retourne [current] avec [key] remise à [previousValue] (ou retirée si
  /// `null`) — factorisé pour [_castSpell]/[_useClassFeature] (même logique
  /// de revert que le catch de [_applyHpState], généralisée à une map).
  Map<int, int> _withRevertedOverride(
    Map<int, int> current,
    int key,
    int? previousValue,
  ) {
    final updated = Map<int, int>.from(current);
    if (previousValue == null) {
      updated.remove(key);
    } else {
      updated[key] = previousValue;
    }
    return updated;
  }

  /// Retourne [current] privée des entrées pour lesquelles [isConfirmed]
  /// (`(key, value) -> bool`) répond vrai — voir le `ref.listen` de [build]
  /// (relâche [_localSpellSlotsUsed]/[_localFeatureUsesRemaining] une fois la
  /// donnée serveur alignée, même principe que [_localHpState]).
  Map<int, int> _confirmedEntriesRemoved(
    Map<int, int> current,
    bool Function(int key, int value) isConfirmed,
  ) {
    final result = <int, int>{};
    for (final entry in current.entries) {
      if (!isConfirmed(entry.key, entry.value)) {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  /// Ajoute [amount] XP (déjà saisi par le joueur dans `AddXpSheet`) à
  /// `detail.xp`, écrit le nouveau total en base
  /// (`CharacterRepository.addXp`), puis pousse immédiatement le flux de
  /// montée de niveau si le seuil du niveau suivant est franchi — spec
  /// visuelle section 1c : "une fois l'XP écrite en base, si le seuil est
  /// franchi, pousser immédiatement l'écran scène du flux sur la pile de
  /// navigation (pas juste revenir sur la fiche)".
  Future<void> _addXp(CharacterDetail detail, int amount) async {
    final newXp = detail.xp + amount;
    try {
      final outcome = await ref
          .read(characterRepositoryProvider)
          .addXp(characterId: widget.characterId, newXp: newXp);
      if (!mounted) return;

      if (outcome == WriteOutcome.queued) {
        // Mode hors-ligne (voir `CharacterRepository.addXp`) : l'XP n'est
        // pas encore confirmée côté serveur — ne jamais pousser
        // automatiquement l'écran de montée de niveau ici, il a lui-même
        // besoin du réseau (`fetchLevelUpLevelData`). Le déclenchement
        // attendra une prochaine interaction manuelle une fois reconnecté.
        _showSnackBar(_offlineQueuedMessage);
        return;
      }

      ref.invalidate(characterDetailProvider(widget.characterId));

      final threshold = detail.nextLevelXpThreshold;
      if (threshold != null && newXp >= threshold) {
        _openLevelUp(detail.totalLevel + 1);
      }
    } on CharacterFailure catch (failure) {
      _showSnackBar(failure.message);
    } catch (_) {
      _showSnackBar("Impossible d'ajouter l'XP. Réessayez.");
    }
  }

  /// Applique un repos (`RestSheet`) : écrit l'effet en base
  /// (`CharacterRepository.applyRest`), rafraîchit la fiche, puis affiche
  /// une confirmation — spec visuelle section 4 : contrairement à
  /// `_applyHpState`/`_addXp`, une confirmation explicite est nécessaire ici
  /// car l'effet n'est pas toujours visible sur la fiche (repos court,
  /// notamment).
  ///
  /// [className] (`CharacterRepository.applyRest`) est résolu ici depuis la
  /// classe primaire de [detail] — chaîne vide si le personnage n'a aucune
  /// classe, auquel cas `SpellSlotProgression.slotsForLevel` ne trouve
  /// aucune correspondance et ne recalcule simplement aucun emplacement de
  /// sort (comportement voulu, même repli que pour une classe non
  /// lanceuse).
  ///
  /// Pour un repos long, dont le résultat sur les PV est connu à l'avance
  /// (`current_hp = max_hp`, `temporary_hp = 0`), bascule optimiste
  /// immédiate — même principe que [_applyHpState] — et fait avancer
  /// [_restGeneration] : marque comme obsolète tout ajustement PV encore en
  /// vol (voir la documentation de [_restGeneration]).
  ///
  /// Fait aussi passer [_isApplyingRest] à `true` le temps de l'appel réseau
  /// (`finally`, succès ou échec) : verrouille les actions PV de
  /// `CharacterVitalsCard` pendant toute la durée de ce repos, voir sa
  /// documentation pour le sens de course que ce verrou ferme (celui que
  /// [_restGeneration] seul ne couvre pas).
  Future<void> _applyRest(CharacterDetail detail, RestType type) async {
    final previousLocal = _localHpState;
    // Un repos (court ou long) recharge des aptitudes rechargeables, et un
    // repos long réinitialise en plus les emplacements de sorts : purge
    // toute surcouche optimiste locale correspondante *avant* l'appel réseau,
    // pour ne jamais laisser une valeur devenue obsolète masquer la donnée
    // fraîchement resynchronisée une fois `ref.invalidate` résolu (sans
    // cette purge, un lancer de sort/une utilisation d'aptitude encore
    // affiché localement resterait visible tel quel malgré le repos). Revert
    // vers ces valeurs pré-repos si l'appel échoue (voir le `catch`
    // ci-dessous), même principe que [previousLocal].
    final previousSpellSlotsOverride = _localSpellSlotsUsed;
    final previousFeatureUsesOverride = _localFeatureUsesRemaining;
    // Avancé pour TOUT repos (court ou long), capturé avant l'appel réseau —
    // voir la documentation de [_restGeneration] : un repos court réinitialise
    // aussi `character_feature_uses`, ce jeton doit donc détecter les deux
    // types, pas seulement le repos long (correctif revue QA/code — un repos
    // court n'avançait auparavant pas ce jeton, laissant passer la course sur
    // [_useClassFeature]).
    _restGeneration++;
    final myRestGeneration = _restGeneration;
    if (type == RestType.long) {
      setState(() {
        _localHpState = HpState(
          currentHp: detail.maxHp,
          maxHp: detail.maxHp,
          temporaryHp: 0,
        );
        _localSpellSlotsUsed = {};
        _localFeatureUsesRemaining = {};
      });
    } else {
      setState(() => _localFeatureUsesRemaining = {});
    }
    setState(() => _isApplyingRest = true);

    try {
      await ref
          .read(characterRepositoryProvider)
          .applyRest(
            characterId: widget.characterId,
            type: type,
            className: detail.primaryClass?.className ?? '',
          );
      ref.invalidate(characterDetailProvider(widget.characterId));
      if (!mounted) return;
      _showSnackBar(
        type == RestType.long
            ? 'Repos long effectué. PV restaurés au maximum.'
            : 'Repos court effectué.',
      );
    } on CharacterFailure catch (failure) {
      if (type == RestType.long &&
          mounted &&
          _restGeneration == myRestGeneration) {
        setState(() {
          _localHpState = previousLocal;
          _localSpellSlotsUsed = previousSpellSlotsOverride;
        });
      }
      if (mounted && _restGeneration == myRestGeneration) {
        setState(
          () => _localFeatureUsesRemaining = previousFeatureUsesOverride,
        );
      }
      _showSnackBar(failure.message);
    } catch (_) {
      if (type == RestType.long &&
          mounted &&
          _restGeneration == myRestGeneration) {
        setState(() {
          _localHpState = previousLocal;
          _localSpellSlotsUsed = previousSpellSlotsOverride;
        });
      }
      if (mounted && _restGeneration == myRestGeneration) {
        setState(
          () => _localFeatureUsesRemaining = previousFeatureUsesOverride,
        );
      }
      _showSnackBar("Impossible d'effectuer le repos. Réessayez.");
    } finally {
      if (mounted) setState(() => _isApplyingRest = false);
    }
  }

  /// Ouvre le flux "Montée de niveau" ciblant [targetLevel] — déclenchement
  /// manuel (lien/bandeau du bandeau XP) ou automatique (seuil franchi via
  /// [_addXp]), voir `level_up_screen.dart`.
  void _openLevelUp(int targetLevel) {
    context.push(
      '/characters/${widget.characterId}/level-up?level=$targetLevel',
    );
  }

  /// Message affiché quand `updateHp`/`addXp` retourne [WriteOutcome.queued]
  /// (mode hors-ligne) — voir `_applyHpState`/`_addXp`. Même registre que le
  /// reste des messages de cet écran (ex. "Impossible d'ajouter l'XP.
  /// Réessayez."), honnête sur le fait que le changement n'est pas encore
  /// confirmé côté serveur.
  static const _offlineQueuedMessage =
      'Hors ligne : sera synchronisé dès que la connexion revient.';

  /// Message affiché quand `castSpell`/`useClassFeature` retourne
  /// [WriteOutcome.queued] (mode hors-ligne) — voir `_castSpell`/
  /// `_useClassFeature`. Distinct de [_offlineQueuedMessage] à dessein
  /// (décision chef de projet, revue QA) : contrairement à `updateHp`/
  /// `addXp`, ces deux écritures ne sont **jamais** mises en file
  /// (`PendingCharacterWriteQueue` reste scopée à `hp`/`xp`) — rien ne sera
  /// synchronisé automatiquement au retour du réseau, donc pas de promesse
  /// de synchronisation ici. L'état optimiste local est aussi annulé dans ce
  /// cas (revert), contrairement à [_offlineQueuedMessage] : laisser
  /// affichée une pastille/un compteur décrémenté serait trompeur puisque
  /// rien ne sera jamais synchronisé.
  static const _offlineNotPersistedMessage =
      "Hors ligne : cette action n'a pas pu être enregistrée. Réessayez une "
      'fois reconnecté.';

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  HpState _hpStateOf(CharacterDetail detail) {
    final effective = _effectiveDetail(detail);
    return HpState(
      currentHp: effective.currentHp,
      maxHp: effective.maxHp,
      temporaryHp: effective.temporaryHp,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Relâche l'état optimiste local dès que la donnée serveur fraîchement
    // rechargée le confirme exactement — jusque-là, `_effectiveDetail`
    // continue d'afficher/de faire autorité sur la valeur locale plutôt que
    // sur une valeur serveur potentiellement encore en retard d'un aller-
    // retour réseau (voir la documentation de [_localHpState]).
    ref.listen(characterDetailProvider(widget.characterId), (previous, next) {
      next.whenData((detail) {
        var shouldSetState = false;

        final local = _localHpState;
        if (local != null &&
            detail.currentHp == local.currentHp &&
            detail.temporaryHp == local.temporaryHp) {
          _localHpState = null;
          shouldSetState = true;
        }

        // Même principe que ci-dessus, généralisé aux maps
        // [_localSpellSlotsUsed]/[_localFeatureUsesRemaining] : ne relâche
        // que les entrées que [detail] confirme désormais exactement, jamais
        // toute la map d'un coup (un autre lancer/une autre utilisation peut
        // encore être en vol pour une autre clé).
        if (_localSpellSlotsUsed.isNotEmpty) {
          final remaining = _confirmedEntriesRemoved(
            _localSpellSlotsUsed,
            (level, used) => detail.spellSlots.any(
              (slot) => slot.level == level && slot.used == used,
            ),
          );
          if (remaining.length != _localSpellSlotsUsed.length) {
            _localSpellSlotsUsed = remaining;
            shouldSetState = true;
          }
        }

        if (_localFeatureUsesRemaining.isNotEmpty) {
          final remaining = _confirmedEntriesRemoved(
            _localFeatureUsesRemaining,
            (featureId, usesRemaining) => detail.classFeatures.any(
              (feature) =>
                  feature.id == featureId &&
                  feature.usesRemaining == usesRemaining,
            ),
          );
          if (remaining.length != _localFeatureUsesRemaining.length) {
            _localFeatureUsesRemaining = remaining;
            shouldSetState = true;
          }
        }

        if (shouldSetState) setState(() {});
      });
    });

    final detailAsync = ref.watch(characterDetailProvider(widget.characterId));
    // `AsyncValue.value` (riverpod 3.x) est déjà nullable — voir la
    // documentation de [_reassertCurrentHpState]. Utilisé ici pour activer
    // le bouton `trailing` "Ajouter une récompense" du bandeau bois
    // uniquement quand une fiche est effectivement chargée (jamais pendant
    // le chargement/une erreur).
    final currentDetail = detailAsync.value;

    return Scaffold(
      body: Column(
        children: [
          WoodBackHeader(
            title: _tab.headerTitle,
            onBack: _goBack,
            trailing: _tab == CharacterDetailTab.inventory && currentDetail != null
                ? SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      tooltip: 'Ajouter une récompense',
                      onPressed: _isWritingInventory
                          ? null
                          : () => showAddRewardSheet(
                              context,
                              onApply: (deltas, items) =>
                                  _addReward(currentDetail, deltas, items),
                            ),
                      icon: const Icon(
                        Icons.card_giftcard,
                        color: AppColors.textOnWood,
                      ),
                    ),
                  )
                : null,
          ),
          Expanded(
            child: detailAsync.when(
              data: (detail) => _buildTabBody(detail),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.woodMedium),
              ),
              error: (error, stackTrace) => _ErrorState(
                message: error is CharacterFailure
                    ? error.message
                    : 'Impossible de charger ce personnage. Réessayez.',
                onRetry: () =>
                    ref.invalidate(characterDetailProvider(widget.characterId)),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: detailAsync.maybeWhen(
        data: (_) => CharacterDetailTabBar(
          current: _tab,
          onSelect: (tab) => setState(() => _tab = tab),
        ),
        orElse: () => null,
      ),
    );
  }

  Widget _buildTabBody(CharacterDetail detail) {
    return switch (_tab) {
      CharacterDetailTab.skills => CharacterSkillsTabBody(
        detail: _effectiveDetail(detail),
        onUseFeature: (feature) =>
            _useClassFeature(_effectiveDetail(detail), feature),
        actionsDisabled: _isApplyingRest || _isUsingFeature,
      ),
      CharacterDetailTab.spells => CharacterSpellsTabBody(
        detail: _effectiveDetail(detail),
        onCastSpell: (spell, slotLevel) =>
            _castSpell(_effectiveDetail(detail), spell, slotLevel),
        actionsDisabled: _isApplyingRest || _isCastingSpell,
      ),
      CharacterDetailTab.inventory => CharacterInventoryTabBody(
        detail: detail,
        onUseItem: _useInventoryItem,
        onToggleItemEquipped: _toggleInventoryItemEquipped,
        onRemoveItem: _removeInventoryItem,
        onAdjustCurrency: _adjustCurrency,
        onAddInventoryItem: _addInventoryItem,
        onAddCustomInventoryItem: _addCustomInventoryItem,
        actionsDisabled: _isWritingInventory,
      ),
      CharacterDetailTab.story => CharacterStoryTabBody(detail: detail),
      CharacterDetailTab.character => _CharacterTabBody(
        detail: detail,
        vitalsDetail: _effectiveDetail(detail),
        onTapPortrait: () => showPortraitUploadSheet(
          context,
          ref: ref,
          characterId: widget.characterId,
          portraitUrl: detail.portraitUrl,
        ),
        onTapAdjustHp: () => showHpAdjustmentSheet(
          context,
          state: _hpStateOf(detail),
          onApply: (newState) => _applyHpState(detail, newState),
        ),
        onQuickHeal: () => _applyHpState(
          detail,
          HpAdjustmentCalculator.applyHeal(_hpStateOf(detail), 1),
        ),
        onQuickDamage: () => _applyHpState(
          detail,
          HpAdjustmentCalculator.applyDamage(_hpStateOf(detail), 1),
        ),
        onTapAddXp: () => showAddXpSheet(
          context,
          currentXp: detail.xp,
          nextLevelXpThreshold: detail.nextLevelXpThreshold,
          onApply: (amount) => _addXp(detail, amount),
        ),
        onTapLevelUp: () => _openLevelUp(detail.totalLevel + 1),
        onTapRest: () {
          final effective = _effectiveDetail(detail);
          showRestSheet(
            context,
            currentHp: effective.currentHp,
            maxHp: effective.maxHp,
            onApply: (type) => _applyRest(detail, type),
          );
        },
        hpActionsDisabled: _isApplyingRest,
      ),
    };
  }
}

class _CharacterTabBody extends StatelessWidget {
  const _CharacterTabBody({
    required this.detail,
    required this.vitalsDetail,
    required this.onTapPortrait,
    required this.onTapAdjustHp,
    required this.onQuickHeal,
    required this.onQuickDamage,
    required this.onTapAddXp,
    required this.onTapLevelUp,
    required this.onTapRest,
    required this.hpActionsDisabled,
  });

  final CharacterDetail detail;

  /// [detail] avec l'état PV optimiste local déjà fusionné (voir
  /// `_CharacterDetailScreenState._effectiveDetail`) — distinct de [detail]
  /// pour que seul le bandeau PV/XP (`CharacterVitalsCard`) réagisse
  /// immédiatement à un tap de stepper, sans recalculer inutilement les
  /// autres cartes (identité, caractéristiques, jets de sauvegarde), qui ne
  /// dépendent pas des PV.
  final CharacterDetail vitalsDetail;

  final VoidCallback onTapPortrait;
  final VoidCallback onTapAdjustHp;
  final VoidCallback onQuickHeal;
  final VoidCallback onQuickDamage;
  final VoidCallback onTapAddXp;
  final VoidCallback onTapLevelUp;
  final VoidCallback onTapRest;

  /// Voir `_CharacterDetailScreenState._isApplyingRest`.
  final bool hpActionsDisabled;

  @override
  Widget build(BuildContext context) {
    final proficiencyBonus = ProficiencyBonusRules.forTotalLevel(
      detail.totalLevel,
    );
    final savingThrows = SavingThrowCalculator.computeAll(
      abilityScores: detail.abilityScores,
      proficientAbilities: detail.primarySavingThrowProficiencies,
      proficiencyBonus: proficiencyBonus,
    );

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        CharacterIdentityCard(detail: detail, onTapPortrait: onTapPortrait),
        const SizedBox(height: AppSpacing.md),
        CharacterVitalsCard(
          detail: vitalsDetail,
          onTapAdjustHp: onTapAdjustHp,
          onQuickHeal: onQuickHeal,
          onQuickDamage: onQuickDamage,
          onTapAddXp: onTapAddXp,
          onTapLevelUp: onTapLevelUp,
          onTapRest: onTapRest,
          hpActionsDisabled: hpActionsDisabled,
        ),
        const SizedBox(height: AppSpacing.md),
        CharacterAbilityScoreGrid(abilityScores: detail.abilityScores),
        const SizedBox(height: AppSpacing.md),
        CharacterSavingThrowsCard(results: savingThrows),
        if (CharacterAppearanceCard.hasContent(detail)) ...[
          const SizedBox(height: AppSpacing.md),
          CharacterAppearanceCard(detail: detail),
        ],
        if (CharacterAdventuresCard.hasContent(detail)) ...[
          const SizedBox(height: AppSpacing.md),
          CharacterAdventuresCard(detail: detail),
        ],
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.accentBrick,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.body(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(label: 'Réessayer', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
