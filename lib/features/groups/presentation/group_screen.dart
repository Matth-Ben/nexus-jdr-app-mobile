import 'dart:async';

import '../../combat/presentation/providers/character_combat_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/connectivity_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/segmented_tab_bar.dart';
import '../../../core/widgets/wood_back_header.dart';
import '../../characters/domain/currency_kind.dart';
import '../../../l10n/app_localizations.dart';
import '../../characters/domain/custom_item_edit_rules.dart';
import '../../characters/presentation/widgets/add_item_flow.dart';
import '../../characters/presentation/widgets/custom_item_form_sheet.dart';
import '../../characters/presentation/widgets/item_action_sheet.dart';
import '../../combat/domain/combat_announcement.dart';
import '../../combat/domain/combat_permissions.dart';
import '../../combat/domain/combat_view_state.dart';
import '../../combat/presentation/providers/combat_providers.dart';
import '../../combat/presentation/combat_announcer.dart';
import '../../combat/presentation/widgets/combat_banner.dart';
import '../../combat/presentation/widgets/start_combat_section.dart';
import '../domain/group_detail.dart';
import '../domain/group_failure.dart';
import '../domain/group_member.dart';
import '../domain/group_treasure.dart';
import '../domain/group_treasure_item.dart';
import '../data/group_treasure_inventory_adapter.dart';
import 'group_character_reassignment_screen.dart';
import 'providers/group_providers.dart';
import 'widgets/claim_group_treasure_currency_sheet.dart';
import 'widgets/group_confirmation_dialog.dart';
import 'widgets/group_members_tab_body.dart';
import 'widgets/group_notes_tab_body.dart';
import 'widgets/group_tab_bar.dart';
import 'widgets/group_treasure_item_sheet.dart';
import 'widgets/group_treasure_tab_body.dart';
import 'group_failure_l10n.dart';

/// Écran "Groupe", route `/groups/:id` —
/// `docs/cahier-des-charges/12-partage-et-groupes.md` section 2.2, revu par
/// le recettage direction-artistique du 13/09 : `WoodBackHeader` (titre =
/// nom du groupe) suivi directement d'un [SegmentedTabBar]
/// Membres/Butin/Notes (ce dernier ajouté le 16/09/2026, demande
/// utilisateur hors cahier des charges — voir `group_notes_tab_body.dart`),
/// puis le corps parchemin scrollable de l'onglet actif. Le bandeau
/// d'identité (nom éditable, code d'invitation, régénération) qui vivait ici
/// auparavant est retiré : son contenu est repris par l'écran "Paramètres du
/// groupe" (tâche séparée), accessible depuis l'icône réglages du header côté
/// owner.
///
/// Toutes les écritures (exclure un membre, quitter, réclamer de la
/// monnaie/un objet, ajouter au butin) sont orchestrées ici — les sheets des
/// onglets Membres/Butin ne font que collecter l'action/l'entrée, même
/// architecture que `CharacterDetailScreen`. Exception : l'onglet Notes
/// (`GroupNotesTabBody`) est un `ConsumerWidget` auto-suffisant qui appelle
/// lui-même son repository, calque intentionnel de `CharacterJournalCard` et
/// du patron `character_journal_entries` déjà en place pour ce chantier —
/// voir sa doc de classe.
///
/// **Membre orphelin** (`GroupMember.isAwaitingCharacter`, voir la migration
/// web `20261016090000_group_members_orphan_character.sql`) : tant que le
/// joueur connecté n'a pas rattaché de nouveau personnage à sa ligne
/// `group_members` (son précédent personnage a été supprimé), `build`
/// remplace entièrement la construction normale des onglets par
/// `GroupCharacterReassignmentScreen` — voir sa doc de classe.
class GroupScreen extends ConsumerStatefulWidget {
  const GroupScreen({required this.groupId, super.key});

  final String groupId;

  @override
  ConsumerState<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends ConsumerState<GroupScreen> {
  GroupTab _tab = GroupTab.members;
  bool _isWritingTreasure = false;
  bool _leaveInFlight = false;

  /// Membres dont l'exclusion est en cours (D232) : transmis à l'onglet
  /// Membres, qui désactive leur commande « Exclure » et montre un
  /// indicateur. Un ensemble, pas un seul membre : exclure un second membre
  /// pendant la première exclusion ne doit pas réactiver le premier bouton
  /// (relecture QA de la PR #306, sinon second `removeMember` en double).
  final Set<String> _removingUserIds = {};

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// Point d'entrée de test de la garde (le propriétaire n'a aucun lien de
  /// départ visible : la garde défensive n'est sinon pas atteignable).
  @visibleForTesting
  Future<void> confirmLeaveGroupForTest(GroupDetail detail) =>
      _confirmLeaveGroup(detail);

  Future<void> _confirmLeaveGroup(GroupDetail detail) async {
    // Garde du propriétaire : jamais de départ pendant un combat actif. Le
    // serveur est l'autorité (DeepCore refuse la suppression de la ligne du
    // propriétaire avec `combat_active`, migration `20261119090000`, traduit
    // dans `_confirmLeaveGroupDialog`) ; cette garde cliente évite seulement
    // un dialogue inutile : on refetch le combat avant de décider (un état
    // `loading`/`error`/périmé ne doit jamais laisser passer un combat
    // connu). Hors ligne, `refresh()` avale l'erreur et laisse l'état
    // périmé : un combat actif déjà connu bloque ; sans état connu
    // (`loading`/`none`) le départ passe, mais `leaveGroup` échouerait de
    // toute façon hors ligne.
    if (_leaveInFlight) return;
    _leaveInFlight = true;
    try {
      if (detail.isOwner) {
        await ref.read(combatProvider(widget.groupId).notifier).refresh();
        if (!mounted) return;
        if (isLeaveBlockedByCombat(
          isOwner: true,
          hasActiveCombat: ref
              .read(combatProvider(widget.groupId))
              .hasActiveCombat,
        )) {
          _showSnackBar(AppLocalizations.of(context)!.combatLeaveBlocked);
          return;
        }
      }
      await _confirmLeaveGroupDialog(detail);
    } finally {
      _leaveInFlight = false;
    }
  }

  Future<void> _confirmLeaveGroupDialog(GroupDetail detail) async {
    final confirmed = await showGroupConfirmationDialog(
      context,
      title: 'Quitter « ${detail.name} » ?',
      message:
          "Tu perds l'accès au butin commun et au suivi de tes coéquipiers. "
          'Ton personnage garde toutes ses données.',
      confirmLabel: 'Quitter',
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(groupRepositoryProvider).leaveGroup(widget.groupId);
      ref.invalidate(characterGroupIdsProvider);
      if (!mounted) return;
      context.go('/');
      _showSnackBar('Tu as quitté le groupe.');
    } on GroupFailure catch (failure) {
      if (!mounted) return;
      if (failure.code == GroupErrorCode.combatActive) {
        // Refus serveur (état local périmé) : on relit le combat pour que le
        // bandeau « Combat en cours » apparaisse.
        unawaited(ref.read(combatProvider(widget.groupId).notifier).refresh());
      }
      _showSnackBar(
        failure.localized(
          context,
          combatActiveMessage: AppLocalizations.of(context)?.combatLeaveBlocked,
        ),
      );
    } catch (_) {
      _showSnackBar('Impossible de quitter le groupe. Réessayez.');
    }
  }

  Future<void> _confirmRemoveMember(GroupMember member) async {
    // Exclusion déjà en cours pour ce membre : jamais un second appel.
    if (_removingUserIds.contains(member.userId)) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showGroupConfirmationDialog(
      context,
      title: l10n.groupMemberRemoveConfirmTitle(member.name),
      message: _removeMemberMessage(l10n, member),
      confirmLabel: l10n.groupMemberRemoveConfirmAction,
      cancelLabel: l10n.groupMemberRemoveCancel,
    );
    if (confirmed != true || !mounted) return;
    if (_removingUserIds.contains(member.userId)) return;

    setState(() => _removingUserIds.add(member.userId));
    try {
      await ref
          .read(groupRepositoryProvider)
          .removeMember(groupId: widget.groupId, userId: member.userId);
      if (!mounted) return;
      _showSnackBar(
        AppLocalizations.of(context)!.groupMemberRemovedSuccess(member.name),
      );
      // Le membre reste « en cours » jusqu'à la relecture du groupe : sinon
      // l'ancien détail, encore affiché, réactiverait son « Exclure ».
      final detail = groupDetailProvider(widget.groupId);
      ref.invalidate(detail);
      try {
        await ref.read(detail.future);
      } catch (_) {
        // L'exclusion a réussi ; l'échec de la relecture s'affiche dans
        // l'état d'erreur de l'écran (bouton « Réessayer »).
      }
    } on GroupFailure catch (failure) {
      if (!mounted) return;
      _showSnackBar(failure.localized(context));
    } catch (_) {
      if (!mounted) return;
      _showSnackBar(
        AppLocalizations.of(context)!.groupMemberRemoveGenericError,
      );
    } finally {
      // Ce membre seulement : les autres exclusions en cours le restent.
      if (mounted) {
        setState(() => _removingUserIds.remove(member.userId));
      } else {
        _removingUserIds.remove(member.userId);
      }
    }
  }

  /// Texte de confirmation distinct selon la nature du membre — jamais le
  /// même texte pour un MJ volontaire (sans personnage par choix) et un
  /// membre orphelin (`GroupMember.isAwaitingCharacter`, personnage supprimé
  /// entre-temps) : les deux ont `characterId == null`, mais la situation
  /// n'est pas la même (voir la doc de classe de `GroupMember`).
  String _removeMemberMessage(AppLocalizations l10n, GroupMember member) {
    if (member.isGameMaster) {
      return l10n.groupMemberRemoveConfirmBodyGameMaster;
    }
    if (member.isAwaitingCharacter) {
      return l10n.groupMemberRemoveConfirmBodyAwaitingCharacter;
    }
    return l10n.groupMemberRemoveConfirmBodyCharacter;
  }

  int _treasureAmountOf(GroupTreasure treasure, CurrencyKind currency) =>
      switch (currency) {
        CurrencyKind.platinum => treasure.currencyPp,
        CurrencyKind.gold => treasure.currencyGp,
        CurrencyKind.electrum => treasure.currencyEp,
        CurrencyKind.silver => treasure.currencySp,
        CurrencyKind.copper => treasure.currencyCp,
      };

  bool get _isTreasureOffline =>
      ref.read(connectivityStatusProvider).value == false;

  void _refreshTreasure() =>
      ref.invalidate(groupTreasureProvider(widget.groupId));

  /// `true` si l'appareil est connecté au moment d'écrire (pas de file hors
  /// ligne pour le butin, données partagées : décision de Matthias du
  /// 26/11/2026). Une erreur du canal de plateforme vaut « connecté » (le
  /// serveur reste l'autorité), comme le bandeau de synchro.
  Future<bool> _hasConnection() async {
    try {
      return await ref.read(connectivityCheckerProvider).hasConnection();
    } catch (_) {
      return true;
    }
  }

  /// Exécute une écriture du butin : verrou [_isWritingTreasure], refus hors
  /// connexion, message de succès ou d'échec, puis rechargement. Un objet
  /// modifié, attribué ou retiré entre-temps par un autre membre
  /// ([GroupErrorCode.treasureStale]) : rien n'a été écrit, message dédié et
  /// rechargement (décision 91).
  Future<void> _runTreasureWrite(
    Future<void> Function() write, {
    required String successMessage,
    String? fallbackErrorMessage,
  }) async {
    if (_isWritingTreasure) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isWritingTreasure = true);
    try {
      if (!await _hasConnection()) {
        _showSnackBar(l10n.groupTreasureOfflineError);
        return;
      }
      await write();
      _refreshTreasure();
      _showSnackBar(successMessage);
    } on GroupFailure catch (failure) {
      if (failure.code == GroupErrorCode.treasureStale) _refreshTreasure();
      _showSnackBar(
        failure.code == GroupErrorCode.network
            ? l10n.groupTreasureOfflineError
            : failure.localizedWith(l10n),
      );
    } catch (_) {
      _showSnackBar(fallbackErrorMessage ?? l10n.groupTreasureWriteError);
    } finally {
      if (mounted) setState(() => _isWritingTreasure = false);
    }
  }

  Future<void> _openClaimCurrencySheet(
    GroupDetail detail,
    GroupTreasure treasure,
  ) {
    final characterId = detail.currentMember?.characterId;
    if (characterId == null) return Future<void>.value();
    return showClaimGroupTreasureCurrencySheet(
      context,
      treasure: treasure,
      onApply: (amounts) => _claimCurrency(characterId, amounts),
    );
  }

  /// Réclame chaque dénomination non nulle via
  /// `claim_group_treasure_currency` (une décrémentation atomique par appel,
  /// voir `GroupRepository.claimTreasureCurrency`) — gère le cas partiel
  /// (certaines dénominations réussissent, d'autres non parce qu'un autre
  /// membre a modifié le butin entre-temps) avec un message récapitulatif
  /// honnête, plutôt qu'un simple succès/échec binaire.
  Future<void> _claimCurrency(
    String characterId,
    Map<CurrencyKind, int> amounts,
  ) async {
    if (amounts.isEmpty || _isWritingTreasure) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isWritingTreasure = true);
    if (!await _hasConnection()) {
      if (mounted) setState(() => _isWritingTreasure = false);
      _showSnackBar(l10n.groupTreasureOfflineError);
      return;
    }

    final failed = <CurrencyKind>[];
    for (final entry in amounts.entries) {
      try {
        final claimed = await ref
            .read(groupRepositoryProvider)
            .claimTreasureCurrency(
              groupId: widget.groupId,
              characterId: characterId,
              currency: entry.key,
              amount: entry.value,
            );
        if (!claimed) failed.add(entry.key);
      } catch (_) {
        failed.add(entry.key);
      }
    }

    _refreshTreasure();
    if (!mounted) return;
    setState(() => _isWritingTreasure = false);

    if (failed.isEmpty) {
      _showSnackBar(l10n.groupTreasureCurrencyClaimedSnack);
    } else if (failed.length == amounts.length) {
      _showSnackBar(l10n.groupTreasureCurrencyClaimFailed);
    } else {
      final labels = failed.map((currency) => currency.unitLabel).join(', ');
      _showSnackBar(l10n.groupTreasureCurrencyClaimPartial(labels));
    }
  }

  /// Fiche d'un objet du butin (décision 91) : la fiche renvoie l'action
  /// choisie, cet écran exécute la suite.
  Future<void> _openTreasureItem(
    GroupDetail detail,
    GroupTreasureItem item,
  ) async {
    final repository = ref.read(groupRepositoryProvider);
    final action = await showGroupTreasureItemSheet(
      context,
      item: item,
      canClaim: detail.currentMember?.characterId != null,
      isBusy: _isWritingTreasure,
      isOffline: _isTreasureOffline,
      loadDetails: item.isCustom
          ? null
          : () => repository.fetchTreasureItemDetails(item),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case GroupTreasureItemAction.claim:
        await _openClaimItemSheet(detail, item);
      case GroupTreasureItemAction.edit:
        await _editTreasureItem(item);
      case GroupTreasureItemAction.remove:
        await _confirmRemoveTreasureItem(item);
    }
  }

  Future<void> _openClaimItemSheet(
    GroupDetail detail,
    GroupTreasureItem item,
  ) async {
    final characterId = detail.currentMember?.characterId;
    if (characterId == null) return;
    final l10n = AppLocalizations.of(context)!;
    final quantity = await showItemQuantitySheet(
      context,
      title: l10n.groupTreasureClaimSheetTitle(item.displayName),
      buttonLabel: l10n.groupTreasureClaimButton,
      max: item.quantity,
    );
    if (quantity == null || quantity <= 0 || !mounted) return;
    await _runTreasureWrite(
      () => ref
          .read(groupRepositoryProvider)
          .claimTreasureItem(
            groupId: widget.groupId,
            characterId: characterId,
            item: item,
            quantity: quantity,
          ),
      successMessage: l10n.groupTreasureClaimedItemSnack,
      fallbackErrorMessage: l10n.groupTreasureClaimItemError,
    );
  }

  /// « Modifier » : objet personnalisé -> formulaire en deux temps de
  /// l'inventaire pré-rempli (tous les champs, quantité comprise) ; objet du
  /// catalogue -> seulement sa quantité (description et détails en lecture
  /// seule). Quantité minimale 1 : on retire par « Retirer du butin ».
  Future<void> _editTreasureItem(GroupTreasureItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final GroupTreasureItem updated;
    if (item.isCustom) {
      final result = await showCustomItemFormSheet(
        context,
        initial: customItemInitialValuesOf(
          GroupTreasureInventoryAdapter.toInventoryItem(item),
        ),
        editQuantity: true,
      );
      if (result == null || !mounted) return;
      updated = GroupTreasureItem.custom(
        name: result.name,
        quantity: result.quantity,
        description: result.description,
        damageDice: result.damageDice,
        damageType: result.damageType,
        properties: result.properties,
        enrichment: result.enrichment,
        extra: item.extra,
      );
    } else {
      final quantity = await showItemQuantitySheet(
        context,
        title: l10n.groupTreasureQuantitySheetTitle(item.displayName),
        buttonLabel: l10n.customItemSaveButton,
        initialValue: item.quantity,
      );
      if (quantity == null || quantity == item.quantity || !mounted) return;
      updated = item.copyWith(quantity: quantity);
    }
    await _runTreasureWrite(
      () => ref
          .read(groupRepositoryProvider)
          .updateTreasureItem(
            groupId: widget.groupId,
            expected: item,
            updated: updated,
          ),
      successMessage: l10n.groupTreasureUpdatedSnack,
    );
  }

  Future<void> _confirmRemoveTreasureItem(GroupTreasureItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showRemoveInventoryItemConfirmationDialog(
      context,
      itemName: item.displayName,
      title: l10n.groupTreasureRemoveConfirmTitle(item.displayName),
      body: l10n.groupTreasureRemoveConfirmBody(item.quantity),
    );
    if (confirmed != true || !mounted) return;
    await _runTreasureWrite(
      () => ref
          .read(groupRepositoryProvider)
          .removeTreasureItem(groupId: widget.groupId, expected: item),
      successMessage: l10n.groupTreasureRemovedSnack(item.displayName),
    );
  }

  /// Tuile « Objet » : même parcours que l'inventaire (catalogue en
  /// sélection multiple, ou objet personnalisé en deux temps), sans
  /// « Harmoniser maintenant » (aucun personnage, `attunedCount` nul).
  Future<void> _addTreasureItems() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await pickInventoryAdditions(context);
    if (picked.isEmpty || !mounted) return;
    final items = [
      for (final addition in picked)
        if (addition.item case final catalogItem?)
          GroupTreasureItem.catalog(
            itemId: catalogItem.id,
            displayName: catalogItem.name,
            quantity: addition.quantity,
            category: catalogItem.category,
            weight: catalogItem.weight,
          )
        else
          GroupTreasureItem.custom(
            name: addition.customName!,
            quantity: addition.quantity,
            description: addition.customDescription,
            damageDice: addition.customDamageDice,
            damageType: addition.customDamageType,
            properties: addition.customProperties,
            enrichment: addition.customEnrichment,
          ),
    ];
    await _runTreasureWrite(
      () => ref
          .read(groupRepositoryProvider)
          .addTreasureItems(groupId: widget.groupId, items: items),
      successMessage: l10n.groupTreasureSavedSnack,
    );
  }

  /// Tuile de monnaie (ajout, ajustement, retrait) : nouveau solde absolu,
  /// écrit seulement si le solde vu n'a pas changé entre-temps.
  Future<void> _adjustTreasureCurrency(
    GroupTreasure treasure,
    CurrencyKind currency,
    int newAmount,
  ) {
    final current = _treasureAmountOf(treasure, currency);
    if (newAmount == current || newAmount < 0) return Future<void>.value();
    return _setTreasureCurrency({currency: current}, {currency: newAmount});
  }

  /// Conversion de pièces : nouveaux soldes absolus des deux pièces.
  Future<void> _convertTreasureCurrency(
    GroupTreasure treasure,
    Map<CurrencyKind, int> totals,
  ) {
    if (totals.isEmpty) return Future<void>.value();
    return _setTreasureCurrency({
      for (final currency in totals.keys)
        currency: _treasureAmountOf(treasure, currency),
    }, totals);
  }

  Future<void> _setTreasureCurrency(
    Map<CurrencyKind, int> expected,
    Map<CurrencyKind, int> newTotals,
  ) {
    return _runTreasureWrite(
      () => ref
          .read(groupRepositoryProvider)
          .setTreasureCurrency(
            groupId: widget.groupId,
            expected: expected,
            newTotals: newTotals,
          ),
      successMessage: AppLocalizations.of(context)!.groupTreasureSavedSnack,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Abonnement Realtime silencieux aux membres du groupe — voir
    // `groupMembersRealtimeWatcherProvider` : souscrit tant que cet écran
    // est monté, désabonné proprement à sa fermeture.
    ref.watch(groupMembersRealtimeWatcherProvider(widget.groupId));
    final detailAsync = ref.watch(groupDetailProvider(widget.groupId));
    final detail = detailAsync.value;

    // Fin du combat vue depuis l'écran Groupe (le bandeau disparaît) : une
    // seule annonce polie. L'écran Combat annonce lui-même la fin quand il
    // est au premier plan.
    ref.listen<CombatViewState>(combatProvider(widget.groupId), (
      previous,
      next,
    ) {
      if (previous == null || !mounted) return;
      if (ModalRoute.of(context)?.isCurrent != true) return;
      final announcement = combatAnnouncementFor(
        previous: previous,
        next: next,
      );
      if (announcement?.kind == CombatAnnouncementKind.ended) {
        defaultCombatAnnouncer(
          context,
          AppLocalizations.of(context)!.combatAnnounceEnded,
        );
      }
    });

    // Interception "membre orphelin" (voir `GroupMember.isAwaitingCharacter`)
    // : le joueur connecté doit rattacher un nouveau personnage avant de
    // pouvoir suivre ce groupe normalement — remplace entièrement la
    // construction habituelle des onglets Membres/Butin/Notes tant que ce
    // n'est pas fait, plutôt qu'une route séparée (ce widget consomme déjà
    // `groupDetailProvider`, inutile de le re-résoudre ailleurs).
    if (detail?.currentMember?.isAwaitingCharacter == true) {
      return GroupCharacterReassignmentScreen(groupId: widget.groupId);
    }

    return Scaffold(
      backgroundColor: AppColors.parchmentBg,
      body: Column(
        children: [
          WoodBackHeader(
            title: detail?.name.toUpperCase() ?? 'GROUPE',
            onBack: _goBack,
            trailing: detail == null
                ? null
                : SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      onPressed: detail.isOwner
                          ? () => context.push(
                              '/groups/${widget.groupId}/settings',
                            )
                          : () => _confirmLeaveGroup(detail),
                      icon: Icon(
                        detail.isOwner ? Icons.settings_outlined : Icons.logout,
                        color: AppColors.textOnWood,
                      ),
                    ),
                  ),
          ),
          detailAsync.maybeWhen(
            data: (_) => SegmentedTabBar<GroupTab>(
              options: [
                for (final tab in GroupTab.values)
                  SegmentedTabBarOption(value: tab, label: tab.label),
              ],
              value: _tab,
              onChanged: (tab) => setState(() => _tab = tab),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          // Bandeau « Combat en cours » : sous les onglets, hors zone
          // défilante, visible sur les trois onglets.
          if (detail != null)
            CombatGroupBanner(
              groupId: widget.groupId,
              masterAbsent: isCombatMasterAbsent(detail),
              identity: (
                userId: detail.currentUserId,
                characterId: detail.currentMember?.characterId,
              ),
              onTap: () => context.push('/groups/${widget.groupId}/combat'),
            ),
          Expanded(
            child: detailAsync.when(
              data: (data) => _buildTabBody(data),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.woodMedium),
              ),
              error: (error, stackTrace) => _ErrorState(
                message: error is GroupFailure
                    ? error.localized(context)
                    : 'Impossible de charger ce groupe. Réessayez.',
                onRetry: () =>
                    ref.invalidate(groupDetailProvider(widget.groupId)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBody(GroupDetail detail) {
    return switch (_tab) {
      GroupTab.members => GroupMembersTabBody(
        detail: detail,
        onRemoveMember: _confirmRemoveMember,
        removingUserIds: Set.unmodifiable(_removingUserIds),
        onLeaveGroup: () => _confirmLeaveGroup(detail),
        combatSection: StartCombatSection(
          detail: detail,
          onOpenCombat: () => context.push('/groups/${widget.groupId}/combat'),
          onOpenSettings: () =>
              context.push('/groups/${widget.groupId}/settings'),
        ),
      ),
      GroupTab.treasure => _buildTreasureTab(detail),
      GroupTab.notes => _buildNotesTab(detail),
    };
  }

  Widget _buildTreasureTab(GroupDetail detail) {
    final treasureAsync = ref.watch(groupTreasureProvider(widget.groupId));
    // Hors connexion : écritures du butin désactivées (pas de file hors
    // ligne, données partagées). Une erreur du flux vaut « en ligne ».
    final offline = ref.watch(connectivityStatusProvider).value == false;
    return treasureAsync.when(
      data: (treasure) => GroupTreasureTabBody(
        treasure: treasure,
        isBusy: _isWritingTreasure,
        isOffline: offline,
        // Un MJ sans personnage peut gérer le butin commun mais ne peut pas
        // s'en attribuer une part (aucun inventaire personnel à créditer) —
        // voir `GroupTreasureTabBody.canClaim`.
        canClaim: detail.currentMember?.characterId != null,
        onClaimCurrency: () => _openClaimCurrencySheet(detail, treasure),
        onOpenItem: (item) => _openTreasureItem(detail, item),
        onAddItems: _addTreasureItems,
        onAdjustCurrency: (currency, newAmount) =>
            _adjustTreasureCurrency(treasure, currency, newAmount),
        onConvertCurrency: (totals) =>
            _convertTreasureCurrency(treasure, totals),
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.woodMedium),
      ),
      error: (error, stackTrace) => _ErrorState(
        message: error is GroupFailure
            ? error.localized(context)
            : AppLocalizations.of(context)!.groupTreasureLoadError,
        onRetry: () => ref.invalidate(groupTreasureProvider(widget.groupId)),
      ),
    );
  }

  Widget _buildNotesTab(GroupDetail detail) {
    // Fractionné en plusieurs entrées datées (07/11/2026) — `GroupNotesTabBody`
    // porte elle-même les écritures (ajout/modification/suppression), voir sa
    // doc de classe ; cet écran ne fait plus que résoudre/invalider la liste.
    // Plus besoin de résoudre `detail.currentMember?.characterId` ici : la
    // RLS de `group_journal_entries` filtre déjà par `auth.uid() = user_id`
    // (un MJ sans personnage, voir `GroupMember.isGameMaster`, a son propre
    // carnet comme n'importe quel membre, décision du comité de revue
    // F02(a), `docs/retours-utilisateurs.md` — inchangée par ce
    // fractionnement).
    final entriesAsync = ref.watch(groupNoteEntriesProvider(widget.groupId));
    return entriesAsync.when(
      data: (entries) =>
          GroupNotesTabBody(groupId: widget.groupId, entries: entries),
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.woodMedium),
      ),
      error: (error, stackTrace) => _ErrorState(
        message: error is GroupFailure
            ? error.localized(context)
            : 'Impossible de charger tes notes. Réessayez.',
        onRetry: () => ref.invalidate(groupNoteEntriesProvider(widget.groupId)),
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
            SecondaryButton(
              label: 'Réessayer',
              surface: SecondaryButtonSurface.parchment,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
