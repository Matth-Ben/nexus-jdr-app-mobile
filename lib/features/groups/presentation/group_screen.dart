import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/segmented_tab_bar.dart';
import '../../../core/widgets/wood_back_header.dart';
import '../../characters/domain/currency_kind.dart';
import '../../characters/domain/reward_item_draft.dart';
import '../domain/group_detail.dart';
import '../domain/group_failure.dart';
import '../domain/group_member.dart';
import '../domain/group_treasure.dart';
import '../domain/group_treasure_item.dart';
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
      if (!mounted) return;
      context.go('/');
      _showSnackBar('Tu as quitté le groupe.');
    } on GroupFailure catch (failure) {
      _showSnackBar(failure.message);
    } catch (_) {
      _showSnackBar('Impossible de quitter le groupe. Réessayez.');
    }
  }

  Future<void> _confirmRemoveMember(GroupMember member) async {
    final confirmed = await showGroupConfirmationDialog(
      context,
      title: 'Exclure ${member.name} du groupe ?',
      message:
          'Son personnage garde toutes ses données, mais quitte '
          'immédiatement le groupe.',
      confirmLabel: 'Exclure',
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(groupRepositoryProvider)
          .removeMember(
            groupId: widget.groupId,
            characterId: member.characterId,
          );
      ref.invalidate(groupDetailProvider(widget.groupId));
      if (!mounted) return;
      _showSnackBar('${member.name} a été exclu du groupe.');
    } on GroupFailure catch (failure) {
      _showSnackBar(failure.message);
    } catch (_) {
      _showSnackBar("Impossible d'exclure ce membre. Réessayez.");
    }
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
      _showSnackBar('Monnaie récupérée.');
    } else if (failed.length == amounts.length) {
      _showSnackBar('Un autre membre vient de modifier le butin. Réessaie.');
    } else {
      final labels = failed.map((currency) => currency.unitLabel).join(', ');
      _showSnackBar(
        'Butin modifié entretemps : $labels non récupérées, le reste a été '
        'ajouté à ton inventaire.',
      );
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
      _showSnackBar('Objet ajouté à ton inventaire.');
    } on GroupFailure catch (failure) {
      _showSnackBar(failure.message);
    } catch (_) {
      _showSnackBar('Impossible de réclamer cet objet. Réessayez.');
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
      _showSnackBar('Butin mis à jour.');
    } on GroupFailure catch (failure) {
      _showSnackBar(failure.message);
    } catch (_) {
      _showSnackBar('Impossible de mettre à jour le butin. Réessayez.');
    } finally {
      if (mounted) setState(() => _isWritingTreasure = false);
    }
  }

  Future<void> _saveNote(String characterId, String body) async {
    if (_isSavingNote) return;
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
      _showSnackBar('Notes enregistrées.');
    } on GroupFailure catch (failure) {
      _showSnackBar(failure.message);
    } catch (_) {
      _showSnackBar('Impossible d\'enregistrer tes notes. Réessayez.');
    } finally {
      if (mounted) setState(() => _isSavingNote = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Abonnement Realtime silencieux aux membres du groupe — voir
    // `groupMembersRealtimeWatcherProvider` : souscrit tant que cet écran
    // est monté, désabonné proprement à sa fermeture.
    ref.watch(groupMembersRealtimeWatcherProvider(widget.groupId));
    final detailAsync = ref.watch(groupDetailProvider(widget.groupId));
    final detail = detailAsync.value;

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
          Expanded(
            child: detailAsync.when(
              data: (data) => _buildTabBody(data),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.woodMedium),
              ),
              error: (error, stackTrace) => _ErrorState(
                message: error is GroupFailure
                    ? error.message
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
        onLeaveGroup: () => _confirmLeaveGroup(detail),
      ),
      GroupTab.treasure => _buildTreasureTab(detail),
      GroupTab.notes => _buildNotesTab(detail),
    };
  }

  Widget _buildTreasureTab(GroupDetail detail) {
    final treasureAsync = ref.watch(groupTreasureProvider(widget.groupId));
    return treasureAsync.when(
      data: (treasure) => GroupTreasureTabBody(
        treasure: treasure,
        isBusy: _isWritingTreasure,
        onClaimCurrency: () => _openClaimCurrencySheet(detail, treasure),
        onClaimItem: (item) => _openClaimItemSheet(detail, item),
        onAddToTreasure: () => _openAddToTreasureSheet(treasure),
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.woodMedium),
      ),
      error: (error, stackTrace) => _ErrorState(
        message: error is GroupFailure
            ? error.message
            : 'Impossible de charger le butin commun. Réessayez.',
        onRetry: () => ref.invalidate(groupTreasureProvider(widget.groupId)),
      ),
    );
  }

  Widget _buildNotesTab(GroupDetail detail) {
    final characterId = detail.currentMember?.characterId;
    if (characterId == null) return const SizedBox.shrink();

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
            ? error.message
            : 'Impossible de charger tes notes. Réessayez.',
        onRetry: () => ref.invalidate(
          groupNoteProvider(groupId: widget.groupId, characterId: characterId),
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
