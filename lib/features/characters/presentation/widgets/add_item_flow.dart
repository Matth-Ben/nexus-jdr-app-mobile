import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/accent_icon_badge.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/sheet_action_row.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../../../core/widgets/stepper_counter.dart';
import '../../../character_creation/domain/gold_amount_formatter.dart';
import '../../domain/character_failure.dart';
import '../../domain/inventory_catalog_item.dart';
import '../../domain/inventory_category_rules.dart';
import '../../domain/weight_formatter.dart';
import '../providers/character_providers.dart';

/// Choix de la sheet d'entrée "+ Ajouter un objet" (tuile en bas de l'onglet
/// "Inventaire", ou tuile "+ Ajouter un objet" de la sheet "Ajouter une
/// récompense") — voir [showAddItemEntrySheet]/[pickInventoryAddition].
enum AddItemEntryChoice { catalog, custom }

/// Résultat de [pickInventoryAddition] — soit un objet du catalogue
/// ([item] non nul), soit un objet personnalisé ([customName] non nul),
/// jamais les deux (voir [isCustom]).
class PickedInventoryAddition {
  const PickedInventoryAddition._({
    this.item,
    this.customName,
    required this.quantity,
  });

  factory PickedInventoryAddition.catalog(
    InventoryCatalogItem item,
    int quantity,
  ) => PickedInventoryAddition._(item: item, quantity: quantity);

  factory PickedInventoryAddition.custom(String customName, int quantity) =>
      PickedInventoryAddition._(customName: customName, quantity: quantity);

  final InventoryCatalogItem? item;
  final String? customName;
  final int quantity;

  bool get isCustom => item == null;

  /// Nom affiché (catalogue déjà résolu, ou saisie personnalisée) — pratique
  /// pour l'appelant (snackbar, liste "en cours" de la sheet récompense),
  /// évite de porter le `switch isCustom` à chaque site d'usage.
  String get displayName => item?.name ?? customName!;
}

/// Ouvre la sheet "+ Ajouter un objet" à 2 lignes ("Depuis le catalogue"/
/// "Objet personnalisé") — calque `showPortraitUploadSheet` (2 lignes au
/// lieu de 3/4, mêmes composants).
Future<AddItemEntryChoice?> showAddItemEntrySheet(BuildContext context) {
  return showModalBottomSheet<AddItemEntryChoice>(
    context: context,
    backgroundColor: AppColors.parchmentCard,
    builder: (sheetContext) => const _AddItemEntrySheetContent(),
  );
}

/// Orchestre le choix "Depuis le catalogue"/"Objet personnalisé" puis la
/// sélection elle-même (recherche+catalogue, ou nom+quantité) — utilisé à la
/// fois par l'onglet "Inventaire" (Flux 3, ajout direct en base par
/// l'appelant) et par la sheet "Ajouter une récompense" (Flux 7, "mode
/// collecte locale" : l'appelant ajoute le résultat à sa propre liste locale
/// plutôt que d'écrire en base immédiatement). Ce helper s'arrête à "quel
/// objet, quelle quantité" — jamais l'écriture réseau, laissée à l'appelant
/// dans les deux cas, même principe que le reste des sheets de ce dépôt
/// ("la sheet retourne l'action/le choix, l'appelant orchestre la suite").
Future<PickedInventoryAddition?> pickInventoryAddition(
  BuildContext context,
) async {
  final choice = await showAddItemEntrySheet(context);
  if (choice == null || !context.mounted) return null;

  switch (choice) {
    case AddItemEntryChoice.catalog:
      final picked = await showItemCatalogPickerSheet(context);
      if (picked == null) return null;
      return PickedInventoryAddition.catalog(picked.item, picked.quantity);
    case AddItemEntryChoice.custom:
      final picked = await showCustomItemPickerSheet(context);
      if (picked == null) return null;
      return PickedInventoryAddition.custom(picked.name, picked.quantity);
  }
}

class _AddItemEntrySheetContent extends StatelessWidget {
  const _AddItemEntrySheetContent();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetActionRow(
            icon: Icons.search,
            label: 'Depuis le catalogue',
            onTap: () => Navigator.of(context).pop(AddItemEntryChoice.catalog),
          ),
          const SheetActionDivider(),
          SheetActionRow(
            icon: Icons.edit_note,
            label: 'Objet personnalisé',
            onTap: () => Navigator.of(context).pop(AddItemEntryChoice.custom),
          ),
        ],
      ),
    );
  }
}

/// Résultat de [showItemCatalogPickerSheet] — objet choisi + quantité déjà
/// saisie via la sheet légère "Ajouter {nom}" (voir
/// `_ItemQuantitySheetContent`).
class CatalogPickResult {
  const CatalogPickResult(this.item, this.quantity);
  final InventoryCatalogItem item;
  final int quantity;
}

/// Sheet plein panneau "Depuis le catalogue" : recherche + liste groupée par
/// catégorie (calque `equipment_step_screen.dart::_shopSection`), tap sur
/// une ligne -> sheet légère de quantité -> ferme les 2 sheets, retourne le
/// résultat final.
Future<CatalogPickResult?> showItemCatalogPickerSheet(BuildContext context) {
  return showModalBottomSheet<CatalogPickResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => const _ItemCatalogPickerContent(),
  );
}

class _ItemCatalogPickerContent extends ConsumerStatefulWidget {
  const _ItemCatalogPickerContent();

  @override
  ConsumerState<_ItemCatalogPickerContent> createState() =>
      _ItemCatalogPickerContentState();
}

class _ItemCatalogPickerContentState
    extends ConsumerState<_ItemCatalogPickerContent> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _pickItem(InventoryCatalogItem item) async {
    final quantity = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.parchmentCard,
      isScrollControlled: true,
      builder: (sheetContext) => _ItemQuantitySheetContent(item: item),
    );
    if (quantity == null || !mounted) return;
    Navigator.of(context).pop(CatalogPickResult(item, quantity));
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(inventoryCatalogProvider);

    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.9,
        child: Container(
          decoration: const BoxDecoration(color: AppColors.parchmentBg),
          child: Column(
            children: [
              const SheetHeaderBar(title: 'AJOUTER UN OBJET'),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: TextFormField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Rechercher un objet...',
                    prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
                  ),
                ),
              ),
              Expanded(
                child: catalogAsync.when(
                  data: _buildList,
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.woodMedium,
                    ),
                  ),
                  error: (error, stackTrace) => _CatalogErrorState(
                    message: error is CharacterFailure
                        ? error.message
                        : "Impossible de charger le catalogue d'objets. "
                              'Réessayez.',
                    onRetry: () => ref.invalidate(inventoryCatalogProvider),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<InventoryCatalogItem> items) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? items
        : items
              .where((item) => item.name.toLowerCase().contains(query))
              .toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'Aucun objet trouvé.',
          style: AppTypography.body(color: AppColors.textMuted),
        ),
      );
    }

    final widgets = <Widget>[];
    for (final category in InventoryCategoryRules.categoryOrder) {
      final categoryItems =
          filtered.where((item) => item.category == category).toList()
            ..sort((a, b) => a.name.compareTo(b.name));
      if (categoryItems.isEmpty) continue;

      if (widgets.isNotEmpty) {
        widgets.add(const SizedBox(height: AppSpacing.md));
      }
      widgets.add(
        _CatalogSectionHeader(
          title: InventoryCategoryRules.labelFor(category).toUpperCase(),
        ),
      );
      widgets.add(const SizedBox(height: AppSpacing.sm));
      for (var i = 0; i < categoryItems.length; i++) {
        if (i > 0) widgets.add(const SizedBox(height: AppSpacing.xs));
        widgets.add(
          _CatalogItemRow(
            item: categoryItems[i],
            onTap: () => _pickItem(categoryItems[i]),
          ),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: widgets,
    );
  }
}

class _CatalogSectionHeader extends StatelessWidget {
  const _CatalogSectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.body(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: AppColors.textSecondary,
      ),
    );
  }
}

/// Une ligne de la liste du catalogue — `AccentIconBadge` recette de
/// `CharacterInventoryItemCard._CategoryBadge` (couleur/icône fixes par
/// catégorie via `InventoryCategoryRules`), **pas** le badge cyclé de
/// `equipment_step_screen.dart`/la création de personnage (spec de la
/// tâche).
class _CatalogItemRow extends StatelessWidget {
  const _CatalogItemRow({required this.item, required this.onTap});

  final InventoryCatalogItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final weight = item.weight;
    final subtitle = weight != null
        ? '${GoldAmountFormatter.format(item.costAmount)} po · '
              '${WeightFormatter.format(weight)} kg'
        : '${GoldAmountFormatter.format(item.costAmount)} po';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                AccentIconBadge(
                  icon: InventoryCategoryRules.iconFor(item.category),
                  color: InventoryCategoryRules.colorFor(item.category),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogErrorState extends StatelessWidget {
  const _CatalogErrorState({required this.message, required this.onRetry});

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

/// Sheet légère "Ajouter {nom}" (`StepperCounter` défaut 1, min 1) — pousse
/// par [_ItemCatalogPickerContentState._pickItem].
class _ItemQuantitySheetContent extends StatefulWidget {
  const _ItemQuantitySheetContent({required this.item});

  final InventoryCatalogItem item;

  @override
  State<_ItemQuantitySheetContent> createState() =>
      _ItemQuantitySheetContentState();
}

class _ItemQuantitySheetContentState extends State<_ItemQuantitySheetContent> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ajouter ${widget.item.name}',
              style: AppTypography.body(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: StepperCounter(
                value: _quantity,
                onIncrement: () => setState(() => _quantity++),
                onDecrement: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Ajouter',
              onPressed: () => Navigator.of(context).pop(_quantity),
            ),
          ],
        ),
      ),
    );
  }
}

/// Résultat de [showCustomItemPickerSheet] — nom saisi + quantité.
class CustomItemPickResult {
  const CustomItemPickResult(this.name, this.quantity);
  final String name;
  final int quantity;
}

/// Sheet "Objet personnalisé" — calque `add_xp_sheet.dart` : champ "Nom de
/// l'objet" (requis), `StepperCounter` "Quantité" (défaut 1), bouton
/// "Ajouter" désactivé si le nom est vide. Pas de champ poids/coût/catégorie
/// (n'existent pas pour un objet personnalisé, voir la spec de la tâche).
Future<CustomItemPickResult?> showCustomItemPickerSheet(BuildContext context) {
  return showModalBottomSheet<CustomItemPickResult>(
    context: context,
    backgroundColor: AppColors.parchmentCard,
    isScrollControlled: true,
    builder: (context) => const _CustomItemPickerContent(),
  );
}

class _CustomItemPickerContent extends StatefulWidget {
  const _CustomItemPickerContent();

  @override
  State<_CustomItemPickerContent> createState() =>
      _CustomItemPickerContentState();
}

class _CustomItemPickerContentState extends State<_CustomItemPickerContent> {
  final TextEditingController _nameController = TextEditingController();
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_handleChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_handleChanged);
    _nameController.dispose();
    super.dispose();
  }

  void _handleChanged() {
    if (mounted) setState(() {});
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(CustomItemPickResult(name, _quantity));
  }

  @override
  Widget build(BuildContext context) {
    final name = _nameController.text.trim();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Objet personnalisé',
              style: AppTypography.body(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              "NOM DE L'OBJET",
              style: AppTypography.body(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Ex. Amulette de famille',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'QUANTITÉ',
              style: AppTypography.body(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            StepperCounter(
              value: _quantity,
              onIncrement: () => setState(() => _quantity++),
              onDecrement: _quantity > 1
                  ? () => setState(() => _quantity--)
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Annuler',
                    surface: SecondaryButtonSurface.parchment,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: PrimaryButton(
                    label: 'Ajouter',
                    onPressed: name.isNotEmpty ? _submit : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
