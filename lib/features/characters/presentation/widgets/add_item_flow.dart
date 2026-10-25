import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/french_text_normalizer.dart';
import '../../../../core/widgets/accent_icon_badge.dart';
import '../../../../core/widgets/error_retry_state.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/segmented_toggle.dart';
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
///
/// [customDescription]/[customDamageDice]/[customDamageType]/
/// [customProperties] : saisis uniquement pour un objet personnalisé (voir
/// `_CustomItemPickerContent`), toujours `null`/vide pour un objet du
/// catalogue (sa description/ses propriétés d'arme sont déjà en base,
/// résolues à la lecture — voir `CharacterInventoryRowMapper`, jamais à
/// répéter ici). [customDamageDice]/[customDamageType] sont tous les deux
/// non nuls pour un objet personnalisé "Arme", tous les deux nuls pour un
/// "Objet simple" (jamais l'un sans l'autre, imposé par le bouton "Ajouter"
/// de la sheet).
class PickedInventoryAddition {
  const PickedInventoryAddition._({
    this.item,
    this.customName,
    required this.quantity,
    this.customDescription,
    this.customDamageDice,
    this.customDamageType,
    this.customProperties = const [],
  });

  factory PickedInventoryAddition.catalog(
    InventoryCatalogItem item,
    int quantity,
  ) => PickedInventoryAddition._(item: item, quantity: quantity);

  factory PickedInventoryAddition.custom(
    String customName,
    int quantity, {
    String? description,
    String? damageDice,
    String? damageType,
    List<String> properties = const [],
  }) => PickedInventoryAddition._(
    customName: customName,
    quantity: quantity,
    customDescription: description,
    customDamageDice: damageDice,
    customDamageType: damageType,
    customProperties: properties,
  );

  final InventoryCatalogItem? item;
  final String? customName;
  final int quantity;
  final String? customDescription;
  final String? customDamageDice;
  final String? customDamageType;
  final List<String> customProperties;

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
      return PickedInventoryAddition.custom(
        picked.name,
        picked.quantity,
        description: picked.description,
        damageDice: picked.damageDice,
        damageType: picked.damageType,
        properties: picked.properties,
      );
  }
}

/// Variante « plusieurs objets » de [pickInventoryAddition] (demande
/// utilisateur, 2026-09-27 : sélectionner plusieurs objets du catalogue
/// avant de les ajouter au butin du groupe, plutôt qu'un par un). « Depuis
/// le catalogue » ouvre le catalogue en sélection multiple ; « Objet
/// personnalisé » reste unitaire (une saisie de nom). Liste vide si annulé.
Future<List<PickedInventoryAddition>> pickInventoryAdditions(
  BuildContext context,
) async {
  final choice = await showAddItemEntrySheet(context);
  if (choice == null || !context.mounted) return const [];

  switch (choice) {
    case AddItemEntryChoice.catalog:
      final picked = await showItemCatalogMultiPickerSheet(context);
      return [
        for (final result in picked)
          PickedInventoryAddition.catalog(result.item, result.quantity),
      ];
    case AddItemEntryChoice.custom:
      final picked = await showCustomItemPickerSheet(context);
      if (picked == null) return const [];
      return [
        PickedInventoryAddition.custom(
          picked.name,
          picked.quantity,
          description: picked.description,
          damageDice: picked.damageDice,
          damageType: picked.damageType,
          properties: picked.properties,
        ),
      ];
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

/// Catalogue en sélection multiple : toucher une ligne la coche (quantité
/// 1, ajustable sur la ligne), « Ajouter (N) » renvoie toute la sélection.
/// Liste vide si la sheet est fermée sans valider.
Future<List<CatalogPickResult>> showItemCatalogMultiPickerSheet(
  BuildContext context,
) async {
  final result = await showModalBottomSheet<List<CatalogPickResult>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) =>
        const _ItemCatalogPickerContent(multiSelect: true),
  );
  return result ?? const [];
}

class _ItemCatalogPickerContent extends ConsumerStatefulWidget {
  const _ItemCatalogPickerContent({this.multiSelect = false});

  /// `true` : sélection multiple (voir [showItemCatalogMultiPickerSheet]).
  final bool multiSelect;

  @override
  ConsumerState<_ItemCatalogPickerContent> createState() =>
      _ItemCatalogPickerContentState();
}

class _ItemCatalogPickerContentState
    extends ConsumerState<_ItemCatalogPickerContent> {
  final TextEditingController _searchController = TextEditingController();

  /// Mode multiple : objets cochés -> quantité, dans l'ordre de sélection.
  final Map<int, CatalogPickResult> _selected = {};

  void _toggle(InventoryCatalogItem item) {
    setState(() {
      if (_selected.remove(item.id) == null) {
        _selected[item.id] = CatalogPickResult(item, 1);
      }
    });
  }

  void _setQuantity(InventoryCatalogItem item, int quantity) {
    setState(() => _selected[item.id] = CatalogPickResult(item, quantity));
  }

  int get _selectedCount => _selected.length;

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
              SheetHeaderBar(
                title: widget.multiSelect
                    ? 'AJOUTER DES OBJETS'
                    : 'AJOUTER UN OBJET',
              ),
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
                  error: (error, stackTrace) => ErrorRetryState(
                    message: error is CharacterFailure
                        ? error.message
                        : "Impossible de charger le catalogue d'objets. "
                              'Réessayez.',
                    onRetry: () => ref.invalidate(inventoryCatalogProvider),
                  ),
                ),
              ),
              if (widget.multiSelect)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: PrimaryButton(
                    label: _selectedCount == 0
                        ? 'Ajouter'
                        : 'Ajouter ($_selectedCount)',
                    onPressed: _selectedCount == 0
                        ? null
                        : () =>
                              Navigator.of(context)
                                  .pop(_selected.values.toList()),
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
            ..sort((a, b) => FrenchTextNormalizer.compare(a.name, b.name));
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
        final item = categoryItems[i];
        final selection = _selected[item.id];
        widgets.add(
          _CatalogItemRow(
            item: item,
            onTap: widget.multiSelect
                ? () => _toggle(item)
                : () => _pickItem(item),
            selected: selection != null,
            trailing: !widget.multiSelect
                ? null
                : selection == null
                ? const Icon(
                    Icons.add_circle_outline,
                    color: AppColors.textMuted,
                  )
                : StepperCounter(
                    value: selection.quantity,
                    onIncrement: () =>
                        _setQuantity(item, selection.quantity + 1),
                    // À 1, « − » retire l'objet de la sélection.
                    onDecrement: () => selection.quantity > 1
                        ? _setQuantity(item, selection.quantity - 1)
                        : _toggle(item),
                  ),
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
  const _CatalogItemRow({
    required this.item,
    required this.onTap,
    this.selected = false,
    this.trailing,
  });

  final InventoryCatalogItem item;
  final VoidCallback onTap;

  /// Mode multiple : ligne cochée (fond mis en avant).
  final bool selected;

  /// Mode multiple : icône « ajouter » ou sélecteur de quantité.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final weight = item.weight;
    final subtitle = weight != null
        ? '${GoldAmountFormatter.format(item.costAmount)} po · '
              '${WeightFormatter.format(weight)} kg'
        : '${GoldAmountFormatter.format(item.costAmount)} po';

    return Material(
      color: selected ? AppColors.parchmentCard : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
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
                if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  trailing!,
                ],
              ],
            ),
          ),
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

/// Types de dégâts d'une arme personnalisée — mêmes valeurs (minuscules) que
/// `weapon_properties.damage_type` côté catalogue, voir
/// `CharacterInventoryWeaponProperties.damageType`. Libellés capitalisés à
/// l'affichage (spec visuelle), valeur stockée telle quelle.
const Map<String, String> _customDamageTypeLabels = {
  'tranchant': 'Tranchant',
  'perforant': 'Perforant',
  'contondant': 'Contondant',
};

/// Faces de dé proposées pour le dé de dégâts d'une arme personnalisée —
/// spec visuelle de la tâche.
const List<int> _customDiceSidesOptions = [4, 6, 8, 10, 12, 20];

/// Résultat de [showCustomItemPickerSheet] — nom + quantité (inchangés),
/// et les champs optionnels ajoutés par la tâche "objet personnalisé
/// enrichi" : [description] (texte libre), et si [isWeapon] : [damageDice]
/// (déjà construit au format "NdM", ex. "1d8") + [damageType] (toujours
/// renseigné si [isWeapon], voir la validation du bouton "Ajouter" de
/// [_CustomItemPickerContent]) + [properties] (texte libre séparé par
/// virgules, déjà parsé en liste). [damageDice]/[damageType]/[properties]
/// restent `null`/vide pour un "Objet simple" ([isWeapon] faux).
class CustomItemPickResult {
  const CustomItemPickResult(
    this.name,
    this.quantity, {
    this.description,
    this.isWeapon = false,
    this.damageDice,
    this.damageType,
    this.properties = const [],
  });

  final String name;
  final int quantity;
  final String? description;
  final bool isWeapon;
  final String? damageDice;
  final String? damageType;
  final List<String> properties;
}

/// Sheet "Objet personnalisé" — gabarit B (`SheetHeaderBar` + contenu
/// scrollable + pied fixe, calque `character_journal_entry_edit_sheet.dart`)
/// plutôt que l'ancien gabarit "léger" (`showModalBottomSheet` à hauteur
/// intrinsèque) : la description + les champs d'arme ajoutés par cette tâche
/// rendent le contenu trop dense pour tenir sans scroll ni gestion clavier.
///
/// Champs dans l'ordre (spec visuelle de la tâche) : nom (requis) ->
/// description (optionnelle) -> type d'objet (`SegmentedToggle`, "Objet
/// simple" par défaut) -> si "Arme" : dé de dégâts (nombre de dés +
/// nombre de faces, construit la notation "NdM") -> type de dégâts (requis
/// si "Arme", aucune valeur par défaut) -> propriétés (texte libre,
/// optionnel) -> quantité (`StepperCounter`, défaut 1, en dernier). Pas de
/// champ portée (hors scope, tranché par le chef de projet). Bouton
/// "Ajouter" désactivé si le nom est vide, ou si "Arme" et qu'aucun type de
/// dégâts n'est choisi.
Future<CustomItemPickResult?> showCustomItemPickerSheet(BuildContext context) {
  return showModalBottomSheet<CustomItemPickResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
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
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _propertiesController = TextEditingController();
  bool _isWeapon = false;
  int _diceCount = 1;
  int _diceSides = 6;
  String? _damageType;
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
    _descriptionController.dispose();
    _propertiesController.dispose();
    super.dispose();
  }

  void _handleChanged() {
    if (mounted) setState(() {});
  }

  /// "Séparez plusieurs propriétés par une virgule." (caption de la tâche) —
  /// mêmes règles de nettoyage que le reste de ce dépôt pour une saisie
  /// libre séparée par virgules (trim + filtrage des segments vides).
  List<String> _parseProperties(String raw) {
    return raw
        .split(',')
        .map((property) => property.trim())
        .where((property) => property.isNotEmpty)
        .toList();
  }

  bool get _canSubmit =>
      _nameController.text.trim().isNotEmpty &&
      (!_isWeapon || _damageType != null);

  void _submit() {
    final name = _nameController.text.trim();
    if (!_canSubmit) return;
    final description = _descriptionController.text.trim();
    Navigator.of(context).pop(
      CustomItemPickResult(
        name,
        _quantity,
        description: description.isEmpty ? null : description,
        isWeapon: _isWeapon,
        damageDice: _isWeapon ? '${_diceCount}d$_diceSides' : null,
        damageType: _isWeapon ? _damageType : null,
        properties: _isWeapon
            ? _parseProperties(_propertiesController.text)
            : const [],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: Container(
          decoration: const BoxDecoration(color: AppColors.parchmentBg),
          child: Column(
            children: [
              const SheetHeaderBar(title: 'OBJET PERSONNALISÉ'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                        key: const Key('customItemNameField'),
                        controller: _nameController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Ex. Amulette de famille',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'DESCRIPTION',
                        style: AppTypography.body(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      TextFormField(
                        key: const Key('customItemDescriptionField'),
                        controller: _descriptionController,
                        minLines: 3,
                        maxLines: null,
                        decoration: const InputDecoration(
                          hintText: 'Ex. Un médaillon gravé aux armes de '
                              'votre famille.',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        "TYPE D'OBJET",
                        style: AppTypography.body(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      SegmentedToggle<bool>(
                        options: const [
                          SegmentedToggleOption(
                            value: false,
                            label: 'Objet simple',
                          ),
                          SegmentedToggleOption(value: true, label: 'Arme'),
                        ],
                        value: _isWeapon,
                        onChanged: (value) =>
                            setState(() => _isWeapon = value),
                      ),
                      if (_isWeapon) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'DÉ DE DÉGÂTS',
                          style: AppTypography.body(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            StepperCounter(
                              value: _diceCount,
                              onIncrement: () =>
                                  setState(() => _diceCount++),
                              onDecrement: _diceCount > 1
                                  ? () => setState(() => _diceCount--)
                                  : null,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'd',
                              style: AppTypography.body(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                key: const Key('customItemDiceSidesField'),
                                initialValue: _diceSides,
                                items: [
                                  for (final sides in _customDiceSidesOptions)
                                    DropdownMenuItem(
                                      value: sides,
                                      child: Text('$sides'),
                                    ),
                                ],
                                onChanged: (value) => setState(
                                  () => _diceSides = value ?? _diceSides,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'TYPE DE DÉGÂTS',
                          style: AppTypography.body(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        DropdownButtonFormField<String>(
                          key: const Key('customItemDamageTypeField'),
                          initialValue: _damageType,
                          isExpanded: true,
                          hint: const Text('Sélectionner'),
                          items: [
                            for (final entry
                                in _customDamageTypeLabels.entries)
                              DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              ),
                          ],
                          onChanged: (value) =>
                              setState(() => _damageType = value),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'PROPRIÉTÉS',
                          style: AppTypography.body(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          key: const Key('customItemPropertiesField'),
                          controller: _propertiesController,
                          decoration: const InputDecoration(
                            hintText: 'Ex. légère, finesse',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Séparez plusieurs propriétés par une virgule.',
                          style: AppTypography.body(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
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
                    ],
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
                child: Row(
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
                        onPressed: _canSubmit ? _submit : null,
                      ),
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
