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
import '../domain/saving_throw_calculator.dart';
import 'providers/character_detail_provider.dart';
import 'providers/character_providers.dart';
import 'widgets/character_ability_score_grid.dart';
import 'widgets/character_detail_tab_bar.dart';
import 'widgets/character_identity_card.dart';
import 'widgets/character_saving_throws_card.dart';
import 'widgets/character_skills_tab_body.dart';
import 'widgets/character_vitals_card.dart';
import 'widgets/hp_adjustment_sheet.dart';
import 'widgets/portrait_upload_sheet.dart';

/// Fiche personnage, route `/characters/:id` — remplace
/// `CharacterDetailPlaceholderScreen`. 4 onglets à terme (voir
/// `CharacterDetailTab`) ; les onglets "Personnage" et "Compétences" ont un
/// vrai contenu, les 2 autres restent des placeholders (même approche "un
/// onglet à la fois" que l'assistant de création).
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
    setState(() => _localHpState = newState);

    try {
      await ref
          .read(characterRepositoryProvider)
          .updateHp(
            characterId: widget.characterId,
            currentHp: newState.currentHp,
            temporaryHp: newState.temporaryHp,
          );
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
      // accumuler depuis une valeur fantôme jamais écrite en base.
      if (mounted) setState(() => _localHpState = previousLocal);
      _showSnackBar(failure.message);
    } catch (_) {
      if (mounted) setState(() => _localHpState = previousLocal);
      _showSnackBar('Impossible de mettre à jour les PV. Réessayez.');
    }
  }

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
          WoodBackHeader(title: 'FICHE', onBack: _goBack),
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
    if (_tab != CharacterDetailTab.character) {
      return _PlaceholderTabBody(tab: _tab);
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
        ),
        const SizedBox(height: AppSpacing.md),
        CharacterAbilityScoreGrid(abilityScores: detail.abilityScores),
        const SizedBox(height: AppSpacing.md),
        CharacterSavingThrowsCard(results: savingThrows),
      ],
    );
  }
}

/// Contenu placeholder des 2 onglets pas encore implémentés — voir la
/// documentation de classe de [CharacterDetailScreen].
class _PlaceholderTabBody extends StatelessWidget {
  const _PlaceholderTabBody({required this.tab});

  final CharacterDetailTab tab;

  static const Map<CharacterDetailTab, String> _sectionLabels = {
    CharacterDetailTab.inventory: 'Inventaire',
    CharacterDetailTab.story: 'Histoire',
  };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tab.icon, size: 48, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text(
              '${_sectionLabels[tab] ?? tab.label} — à venir',
              style: AppTypography.body(fontSize: 16),
            ),
          ],
        ),
      ),
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
