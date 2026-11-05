import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/segmented_tab_bar.dart';
import '../../../core/widgets/wood_back_header.dart';
import '../../../l10n/app_localizations.dart';
import '../../characters/domain/currency_kind.dart';
import '../../characters/domain/reward_item_draft.dart';
import '../domain/group_detail.dart';
import '../domain/group_failure.dart';
import '../domain/group_member.dart';
import '../domain/group_treasure.dart';
import '../domain/group_treasure_item.dart';
import 'group_character_reassignment_screen.dart';
import 'group_failure_presenter.dart';
import 'providers/group_providers.dart';
import 'widgets/add_to_group_treasure_sheet.dart';
import 'widgets/claim_group_treasure_currency_sheet.dart';
import 'widgets/claim_group_treasure_item_sheet.dart';
import 'widgets/group_confirmation_dialog.dart';
import 'widgets/group_members_tab_body.dart';
import 'widgets/group_notes_tab_body.dart';
import 'widgets/group_tab_bar.dart';
import 'widgets/group_treasure_tab_body.dart';

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
/// monnaie/un objet, ajouter au butin) sont orchestrées ici — les sheets/
/// onglets ne font que collecter l'action/l'entrée, même architecture que
/// `CharacterDetailScreen`.
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
  bool _isSavingNote = false;

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

  Future<void> _confirmLeaveGroup(GroupDetail detail) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showGroupConfirmationDialog(
      context,
      title: l10n.groupScreenLeaveConfirmTitle(detail.name),
      message: l10n.groupScreenLeaveConfirmMessage,
      confirmLabel: l10n.groupScreenLeaveConfirmButtonLabel,
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(groupRepositoryProvider).leaveGroup(widget.groupId);
      if (!mounted) return;
      context.go('/');
      _showSnackBar(l10n.groupScreenLeftGroupSnackbar);
    } on GroupFailure catch (failure) {
      _showSnackBar(resolveGroupFailureMessage(l10n, failure));
    } catch (_) {
      _showSnackBar(l10n.groupScreenLeaveGroupGenericErrorMessage);
    }
  }

  Future<void> _confirmRemoveMember(GroupMember member) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showGroupConfirmationDialog(
      context,
      title: l10n.groupScreenRemoveMemberConfirmTitle(member.name),
      message: _removeMemberMessage(l10n, member),
      confirmLabel: l10n.groupScreenRemoveMemberConfirmButtonLabel,
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(groupRepositoryProvider)
          .removeMember(groupId: widget.groupId, userId: member.userId);
      ref.invalidate(groupDetailProvider(widget.groupId));
      if (!mounted) return;
      _showSnackBar(l10n.groupScreenMemberRemovedSnackbar(member.name));
    } on GroupFailure catch (failure) {
      _showSnackBar(resolveGroupFailureMessage(l10n, failure));
    } catch (_) {
      _showSnackBar(l10n.groupScreenRemoveMemberGenericErrorMessage);
    }
  }

  /// Texte de confirmation distinct selon la nature du membre — jamais le
  /// même texte pour un MJ volontaire (sans personnage par choix) et un
  /// membre orphelin (`GroupMember.isAwaitingCharacter`, personnage supprimé
  /// entre-temps) : les deux ont `characterId == null`, mais la situation
  /// n'est pas la même (voir la doc de classe de `GroupMember`).
  String _removeMemberMessage(AppLocalizations l10n, GroupMember member) {
    if (member.isGameMaster) {
      return l10n.groupScreenRemoveMemberGameMasterMessage;
    }
    if (member.isAwaitingCharacter) {
      return l10n.groupScreenRemoveMemberOrphanMessage;
    }
    return l10n.groupScreenRemoveMemberDefaultMessage;
  }

  int _treasureAmountOf(GroupTreasure treasure, CurrencyKind currency) =>
      switch (currency) {
        CurrencyKind.platinum => treasure.currencyPp,
        CurrencyKind.gold => treasure.currencyGp,
        CurrencyKind.electrum => treasure.currencyEp,
        CurrencyKind.silver => treasure.currencySp,
        CurrencyKind.copper => treasure.currencyCp,
      };

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

    ref.invalidate(groupTreasureProvider(widget.groupId));
    if (!mounted) return;
    setState(() => _isWritingTreasure = false);

    if (failed.isEmpty) {
      _showSnackBar(l10n.groupScreenCurrencyClaimedSnackbar);
    } else if (failed.length == amounts.length) {
      _showSnackBar(l10n.groupScreenTreasureConflictAllFailedSnackbar);
    } else {
      final labels = failed.map((currency) => currency.unitLabel).join(', ');
      _showSnackBar(l10n.groupScreenTreasureConflictPartialSnackbar(labels));
    }
  }

  Future<void> _openClaimItemSheet(
    GroupDetail detail,
    GroupTreasureItem item,
  ) async {
    final characterId = detail.currentMember?.characterId;
    if (characterId == null) return;
    final quantity = await showClaimGroupTreasureItemSheet(context, item: item);
    if (quantity == null || quantity <= 0 || !mounted) return;
    await _claimItem(characterId, item, quantity);
  }

  Future<void> _claimItem(
    String characterId,
    GroupTreasureItem item,
    int quantity,
  ) async {
    if (_isWritingTreasure) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isWritingTreasure = true);
    try {
      await ref
          .read(groupRepositoryProvider)
          .claimTreasureItem(
            groupId: widget.groupId,
            characterId: characterId,
            item: item,
            quantity: quantity,
          );
      ref.invalidate(groupTreasureProvider(widget.groupId));
      if (!mounted) return;
      _showSnackBar(l10n.groupScreenItemClaimedSnackbar);
    } on GroupFailure catch (failure) {
      _showSnackBar(resolveGroupFailureMessage(l10n, failure));
    } catch (_) {
      _showSnackBar(l10n.groupScreenClaimItemGenericErrorMessage);
    } finally {
      if (mounted) setState(() => _isWritingTreasure = false);
    }
  }

  Future<void> _openAddToTreasureSheet(GroupTreasure treasure) {
    return showAddToGroupTreasureSheet(
      context,
      onApply: (deltas, items) => _addToTreasure(treasure, deltas, items),
    );
  }

  Future<void> _addToTreasure(
    GroupTreasure treasure,
    Map<CurrencyKind, int> deltas,
    List<RewardItemDraft> items,
  ) async {
    if (_isWritingTreasure) return;
    final l10n = AppLocalizations.of(context)!;

    final newTotals = <CurrencyKind, int>{
      for (final entry in deltas.entries)
        entry.key: _treasureAmountOf(treasure, entry.key) + entry.value,
    };

    final newItems = List<GroupTreasureItem>.from(treasure.items);
    for (final draft in items) {
      final candidate = GroupTreasureItem(
        itemId: draft.itemId,
        customName: draft.customName,
        displayName: draft.displayName,
        quantity: draft.quantity,
      );
      final index = newItems.indexWhere(
        (existing) => existing.matches(candidate),
      );
      if (index == -1) {
        newItems.add(candidate);
      } else {
        newItems[index] = newItems[index].copyWith(
          quantity: newItems[index].quantity + candidate.quantity,
        );
      }
    }

    setState(() => _isWritingTreasure = true);
    try {
      await ref
          .read(groupRepositoryProvider)
          .addToTreasure(
            groupId: widget.groupId,
            newCurrencyTotals: newTotals,
            newItems: newItems,
          );
      ref.invalidate(groupTreasureProvider(widget.groupId));
      if (!mounted) return;
      _showSnackBar(l10n.groupScreenTreasureUpdatedSnackbar);
    } on GroupFailure catch (failure) {
      _showSnackBar(resolveGroupFailureMessage(l10n, failure));
    } catch (_) {
      _showSnackBar(l10n.groupScreenUpdateTreasureGenericErrorMessage);
    } finally {
      if (mounted) setState(() => _isWritingTreasure = false);
    }
  }

  Future<void> _saveNote(String characterId, String body) async {
    if (_isSavingNote) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSavingNote = true);
    try {
      await ref
          .read(groupRepositoryProvider)
          .saveGroupNote(
            groupId: widget.groupId,
            characterId: characterId,
            body: body,
          );
      ref.invalidate(
        groupNoteProvider(groupId: widget.groupId, characterId: characterId),
      );
      if (!mounted) return;
      _showSnackBar(l10n.groupScreenNoteSavedSnackbar);
    } on GroupFailure catch (failure) {
      _showSnackBar(resolveGroupFailureMessage(l10n, failure));
    } catch (_) {
      _showSnackBar(l10n.groupScreenSaveNoteGenericErrorMessage);
    } finally {
      if (mounted) setState(() => _isSavingNote = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Abonnement Realtime silencieux aux membres du groupe — voir
    // `groupMembersRealtimeWatcherProvider` : souscrit tant que cet écran
    // est monté, désabonné proprement à sa fermeture.
    ref.watch(groupMembersRealtimeWatcherProvider(widget.groupId));
    final detailAsync = ref.watch(groupDetailProvider(widget.groupId));
    final detail = detailAsync.value;

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
            title: detail?.name.toUpperCase() ?? l10n.groupScreenDefaultTitle,
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
                  SegmentedTabBarOption(value: tab, label: tab.label(l10n)),
              ],
              value: _tab,
              onChanged: (tab) => setState(() => _tab = tab),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          Expanded(
            child: detailAsync.when(
              data: (data) => _buildTabBody(data),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.woodMedium),
              ),
              error: (error, stackTrace) => _ErrorState(
                message: error is GroupFailure
                    ? resolveGroupFailureMessage(l10n, error)
                    : l10n.groupScreenLoadErrorMessage,
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
        onLeaveGroup: () => _confirmLeaveGroup(detail),
      ),
      GroupTab.treasure => _buildTreasureTab(detail),
      GroupTab.notes => _buildNotesTab(detail),
    };
  }

  Widget _buildTreasureTab(GroupDetail detail) {
    final l10n = AppLocalizations.of(context)!;
    final treasureAsync = ref.watch(groupTreasureProvider(widget.groupId));
    return treasureAsync.when(
      data: (treasure) => GroupTreasureTabBody(
        treasure: treasure,
        isBusy: _isWritingTreasure,
        // Un MJ sans personnage peut gérer le butin commun mais ne peut pas
        // s'en attribuer une part (aucun inventaire personnel à créditer) —
        // voir `GroupTreasureTabBody.canClaim`.
        canClaim: detail.currentMember?.characterId != null,
        onClaimCurrency: () => _openClaimCurrencySheet(detail, treasure),
        onClaimItem: (item) => _openClaimItemSheet(detail, item),
        onAddToTreasure: () => _openAddToTreasureSheet(treasure),
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.woodMedium),
      ),
      error: (error, stackTrace) => _ErrorState(
        message: error is GroupFailure
            ? resolveGroupFailureMessage(l10n, error)
            : l10n.groupScreenTreasureLoadErrorMessage,
        onRetry: () => ref.invalidate(groupTreasureProvider(widget.groupId)),
      ),
    );
  }

  Widget _buildNotesTab(GroupDetail detail) {
    final l10n = AppLocalizations.of(context)!;
    final characterId = detail.currentMember?.characterId;
    // Le carnet de notes est propre à un personnage — un MJ sans personnage
    // (voir `GroupMember.isGameMaster`) n'en a pas ici (`group_notes` est
    // indexé par `character_id`, jamais applicable à sa propre ligne). Voir
    // `_NoNotesForGameMasterState` pour l'état désactivé explicite affiché à
    // la place, ciblé uniquement sur SA PROPRE vue (jamais celle d'un autre
    // membre, qui n'est jamais représentée par cet onglet).
    if (characterId == null) return const _NoNotesForGameMasterState();

    final noteAsync = ref.watch(
      groupNoteProvider(groupId: widget.groupId, characterId: characterId),
    );
    return noteAsync.when(
      data: (note) => GroupNotesTabBody(
        initialBody: note.body,
        isSaving: _isSavingNote,
        onSave: (body) => _saveNote(characterId, body),
        onDictationError: _showSnackBar,
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.woodMedium),
      ),
      error: (error, stackTrace) => _ErrorState(
        message: error is GroupFailure
            ? resolveGroupFailureMessage(l10n, error)
            : l10n.groupScreenNoteLoadErrorMessage,
        onRetry: () => ref.invalidate(
          groupNoteProvider(groupId: widget.groupId, characterId: characterId),
        ),
      ),
    );
  }
}

/// État désactivé explicite de l'onglet "Notes" pour un MJ sans personnage
/// (voir `_GroupScreenState._buildNotesTab`) — même gabarit que
/// `group_treasure_tab_body.dart::_EmptyTreasureItemsState` (icône centrée
/// 56px `text.muted`, texte centré `text.muted`, pas de bouton).
class _NoNotesForGameMasterState extends StatelessWidget {
  const _NoNotesForGameMasterState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_note, size: 56, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.groupScreenNoNotesForGameMasterMessage,
              textAlign: TextAlign.center,
              style: AppTypography.body(color: AppColors.textMuted),
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
    final l10n = AppLocalizations.of(context)!;
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
              label: l10n.groupScreenRetryButtonLabel,
              surface: SecondaryButtonSurface.parchment,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
