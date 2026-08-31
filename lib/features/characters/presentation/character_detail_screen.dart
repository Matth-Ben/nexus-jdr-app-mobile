import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/wood_back_header.dart';
import '../domain/character_detail.dart';
import '../domain/character_failure.dart';
import '../domain/hp_adjustment.dart';
import '../domain/proficiency_bonus.dart';
import '../domain/rest_type.dart';
import '../domain/saving_throw_calculator.dart';
import '../domain/write_outcome.dart';
import 'providers/character_detail_provider.dart';
import 'providers/character_providers.dart';
import 'widgets/add_xp_sheet.dart';
import 'widgets/character_ability_score_grid.dart';
import 'widgets/character_adventures_card.dart';
import 'widgets/character_appearance_card.dart';
import 'widgets/character_detail_tab_bar.dart';
import 'widgets/character_identity_card.dart';
import 'widgets/character_inventory_tab_body.dart';
import 'widgets/character_saving_throws_card.dart';
import 'widgets/character_skills_tab_body.dart';
import 'widgets/character_story_tab_body.dart';
import 'widgets/character_vitals_card.dart';
import 'widgets/hp_adjustment_sheet.dart';
import 'widgets/portrait_upload_sheet.dart';
import 'widgets/rest_sheet.dart';

/// Fiche personnage, route `/characters/:id` — remplace
/// `CharacterDetailPlaceholderScreen`. Les 4 onglets (voir
/// `CharacterDetailTab`) ont désormais tous un vrai contenu (même approche
/// "un onglet à la fois" que l'assistant de création : "Personnage",
/// "Compétences", "Inventaire" puis "Histoire" livrés séparément).
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

  /// Compteur incrémenté uniquement par un repos long réussi ([_applyRest])
  /// — sert à détecter qu'un ajustement PV resté en vol ([_applyHpState],
  /// ex. le stepper "+"/"-" ou `HpAdjustmentSheet`) a été dépassé par un
  /// repos long démarré entre-temps : sans ce garde-fou, l'écriture tardive
  /// de l'ajustement obsolète écrasait silencieusement en base le résultat
  /// du repos une fois son propre appel réseau enfin résolu (perte de
  /// données confirmée en revue QA, voir
  /// `test/features/characters/presentation/character_detail_rest_stale_hp_test.dart`).
  ///
  /// Volontairement distinct d'un compteur générique incrémenté par *tout*
  /// ajustement PV : deux taps rapides successifs sur le stepper
  /// (`character_detail_hp_stepper_race_test.dart`) sont un cas normal déjà
  /// géré par l'accumulateur [_localHpState], pas une raison de déclencher
  /// [_reassertCurrentHpState] — seul un repos long change les PV
  /// indépendamment de la valeur locale déjà affichée à ce moment-là.
  int _restGeneration = 0;

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

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  /// Fusionne [_localHpState] (s'il existe) par-dessus [detail] : `max_hp`
  /// vient toujours de la dernière donnée serveur connue (jamais modifié
  /// localement), seuls `current_hp`/`temporary_hp` peuvent être en avance.
  CharacterDetail _effectiveDetail(CharacterDetail detail) {
    final local = _localHpState;
    if (local == null) return detail;
    return detail.copyWith(
      currentHp: local.currentHp,
      temporaryHp: local.temporaryHp,
    );
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
    // Capturé avant l'appel réseau : `_restGeneration` peut ne pas encore
    // avoir été avancé par cette tentative précise au moment de la capture
    // (seul un repos long l'avance, voir ci-dessous) — comparé plus bas pour
    // détecter si une tentative de repos plus récente l'a entre-temps
    // dépassée, même principe que la garde symétrique posée sur
    // [_applyHpState].
    int? myRestGeneration;
    if (type == RestType.long) {
      _restGeneration++;
      myRestGeneration = _restGeneration;
      setState(
        () => _localHpState = HpState(
          currentHp: detail.maxHp,
          maxHp: detail.maxHp,
          temporaryHp: 0,
        ),
      );
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
        setState(() => _localHpState = previousLocal);
      }
      _showSnackBar(failure.message);
    } catch (_) {
      if (type == RestType.long &&
          mounted &&
          _restGeneration == myRestGeneration) {
        setState(() => _localHpState = previousLocal);
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
      final local = _localHpState;
      if (local == null) return;
      next.whenData((detail) {
        if (detail.currentHp == local.currentHp &&
            detail.temporaryHp == local.temporaryHp) {
          setState(() => _localHpState = null);
        }
      });
    });

    final detailAsync = ref.watch(characterDetailProvider(widget.characterId));

    return Scaffold(
      body: Column(
        children: [
          WoodBackHeader(title: _tab.headerTitle, onBack: _goBack),
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
    if (_tab == CharacterDetailTab.skills) {
      return CharacterSkillsTabBody(detail: detail);
    }
    if (_tab == CharacterDetailTab.inventory) {
      return CharacterInventoryTabBody(detail: detail);
    }
    if (_tab == CharacterDetailTab.story) {
      return CharacterStoryTabBody(detail: detail);
    }
    return _CharacterTabBody(
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
    );
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
