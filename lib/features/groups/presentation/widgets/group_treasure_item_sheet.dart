import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/connectivity_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/destructive_button.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../characters/domain/character_inventory_item.dart';
import '../../../characters/presentation/widgets/item_info_panel.dart';
import '../../data/group_treasure_inventory_adapter.dart';
import '../../domain/group_treasure_item.dart';

/// Action choisie dans la fiche d'un objet du butin ; l'écran Groupe
/// (`group_screen.dart`) exécute la suite (convention du dépôt).
enum GroupTreasureItemAction { claim, edit, remove }

/// Ouvre la fiche d'un objet du butin de groupe (décision 91,
/// `docs/spec-butin-groupe.md` §2) : gabarit du panneau « Infos » de
/// l'inventaire (`heightFactor` 0.88, [SheetHeaderBar], contenu défilant, pied
/// fixe) avec son corps partagé ([ItemInfoBody], `withoutCharacter`),
/// précédé de « Provenance » et « Quantité ».
///
/// Pied : « S'attribuer » (désactivé sans personnage, avec une légende),
/// puis « Modifier » et « Retirer du butin ». [isBusy] et l'absence de
/// connexion désactivent les trois (hors connexion : légende dédiée). La
/// connexion est **surveillée en direct** ([connectivityStatusProvider]) : les
/// actions se réactivent dès le retour du réseau, sans rouvrir la fiche.
///
/// [loadDetails] : relecture de la description et des détails d'un objet du
/// catalogue (par `item_id`) ; pendant le chargement, un indicateur remplace
/// la description (actions actives) ; en cas d'erreur, un message et
/// « Réessayer ». `null` pour un objet personnalisé (tout est dans l'entrée).
Future<GroupTreasureItemAction?> showGroupTreasureItemSheet(
  BuildContext context, {
  required GroupTreasureItem item,
  required bool canClaim,
  required bool isBusy,
  Future<CharacterInventoryItem> Function()? loadDetails,
}) {
  return showModalBottomSheet<GroupTreasureItemAction>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => GroupTreasureItemSheet(
      item: item,
      canClaim: canClaim,
      isBusy: isBusy,
      loadDetails: loadDetails,
    ),
  );
}

class GroupTreasureItemSheet extends ConsumerStatefulWidget {
  const GroupTreasureItemSheet({
    required this.item,
    required this.canClaim,
    required this.isBusy,
    this.loadDetails,
    super.key,
  });

  final GroupTreasureItem item;
  final bool canClaim;
  final bool isBusy;
  final Future<CharacterInventoryItem> Function()? loadDetails;

  @override
  ConsumerState<GroupTreasureItemSheet> createState() =>
      _GroupTreasureItemSheetState();
}

class _GroupTreasureItemSheetState
    extends ConsumerState<GroupTreasureItemSheet> {
  late CharacterInventoryItem _item =
      GroupTreasureInventoryAdapter.toInventoryItem(widget.item);
  late bool _loading = widget.loadDetails != null;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    if (widget.loadDetails != null) _load();
  }

  Future<void> _load() async {
    final load = widget.loadDetails;
    if (load == null) return;
    if (!_loading || _loadFailed) {
      setState(() {
        _loading = true;
        _loadFailed = false;
      });
    }
    try {
      final details = await load();
      if (!mounted) return;
      setState(() {
        _item = details;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  Widget? _descriptionOverride(AppLocalizations l10n) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.woodMedium),
        ),
      );
    }
    if (!_loadFailed) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.groupTreasureDetailsLoadError,
          style: AppTypography.body(fontSize: 14, height: 1.4),
        ),
        TextButton(
          key: const Key('groupTreasureItemDetailsRetry'),
          style: TextButton.styleFrom(
            minimumSize: const Size(44, 44),
            foregroundColor: AppColors.textSecondary,
          ),
          onPressed: _load,
          child: Text(l10n.addItemFlowCatalogOfflineRetryButton),
        ),
      ],
    );
  }

  Widget _caption(String text) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xs),
    child: Text(
      text,
      style: AppTypography.body(fontSize: 12, color: AppColors.textSecondary),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final item = widget.item;
    final offline = ref.watch(connectivityStatusProvider).isKnownOffline;
    final actionsEnabled = !widget.isBusy && !offline;
    final stacked = MediaQuery.textScalerOf(context).scale(14) / 14 >= 1.5;
    void pop(GroupTreasureItemAction action) =>
        Navigator.of(context).pop(action);

    final edit = SecondaryButton(
      key: const Key('groupTreasureItemEditButton'),
      label: l10n.itemActionSheetEditLabel,
      icon: Icons.edit,
      surface: SecondaryButtonSurface.parchment,
      onPressed: actionsEnabled
          ? () => pop(GroupTreasureItemAction.edit)
          : null,
    );
    final remove = DestructiveButton(
      key: const Key('groupTreasureItemRemoveButton'),
      label: l10n.groupTreasureRemoveButton,
      icon: Icons.delete_outline,
      onPressed: actionsEnabled
          ? () => pop(GroupTreasureItemAction.remove)
          : null,
    );

    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.88,
        child: Container(
          decoration: const BoxDecoration(color: AppColors.parchmentBg),
          child: Column(
            children: [
              SheetHeaderBar(title: item.displayName.toUpperCase()),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: ItemInfoBody(
                    item: _item,
                    withoutCharacter: true,
                    // Lien « Fixer un prix » (spec du prix d'un objet
                    // modifiable, §1.3) : rejoue exactement l'action
                    // « Modifier » du pied de cette fiche (même routage
                    // catalogue/personnalisé côté `group_screen.dart
                    // ::_editTreasureItem`).
                    onEditPrice: actionsEnabled
                        ? () => pop(GroupTreasureItemAction.edit)
                        : null,
                    priceSetLinkLabel: l10n.groupTreasureItemPriceSetLink,
                    leadingRows: [
                      (
                        label: l10n.groupTreasureItemSourceLabel,
                        value: item.isCustom
                            ? l10n.addItemFlowCustomEntryLabel
                            : l10n.groupTreasureItemSourceCatalog,
                      ),
                      (
                        label: l10n.groupTreasureItemQuantityLabel,
                        value: l10n.groupTreasureItemQuantityValue(
                          item.quantity,
                        ),
                      ),
                    ],
                    descriptionOverride: _descriptionOverride(l10n),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PrimaryButton(
                      key: const Key('groupTreasureItemClaimButton'),
                      label: l10n.groupTreasureClaimButton,
                      onPressed: widget.canClaim && actionsEnabled
                          ? () => pop(GroupTreasureItemAction.claim)
                          : null,
                    ),
                    if (!widget.canClaim)
                      _caption(l10n.groupTreasureClaimNoCharacterCaption),
                    const SizedBox(height: AppSpacing.sm),
                    if (stacked) ...[
                      edit,
                      const SizedBox(height: AppSpacing.sm),
                      remove,
                    ] else
                      Row(
                        children: [
                          Expanded(child: edit),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: remove),
                        ],
                      ),
                    if (offline)
                      Semantics(
                        liveRegion: true,
                        child: _caption(l10n.groupTreasureOfflineBanner),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
