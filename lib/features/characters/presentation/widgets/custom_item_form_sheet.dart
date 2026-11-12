import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/accent_icon_badge.dart';
import '../../../../core/widgets/advanced_section.dart';
import '../../../../core/widgets/display_text.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/segmented_toggle.dart';
import '../../../../core/widgets/selectable_option_tile.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../../../core/widgets/stepper_counter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/character_detail.dart';
import '../../domain/custom_item_enrichment.dart';
import '../../domain/inventory_category_rules.dart';
import '../custom_item_labels.dart';

/// Résultat de [showCustomItemFormSheet] : saisie validée d'un objet
/// personnalisé (nom, quantité, description, et pour une arme dé/type de
/// dégâts/propriétés), plus ses colonnes enrichies ([enrichment], toujours
/// renseigné avec au moins le type).
class CustomItemFormResult {
  const CustomItemFormResult({
    required this.name,
    required this.quantity,
    required this.enrichment,
    this.description,
    this.damageDice,
    this.damageType,
    this.properties = const [],
  });

  final String name;
  final int quantity;
  final String? description;
  final String? damageDice;
  final String? damageType;
  final List<String> properties;
  final CustomItemEnrichment enrichment;
}

/// Longueur maximale du nom (identique à la validation de la file hors
/// ligne, `inventoryCustomNameMaxLength`).
const int _nameMaxLength = 200;

/// Faces de dé proposées à l'ajout d'une arme (le d20 n'est plus proposé ; un
/// `1d20` déjà stocké reste affiché tel quel).
const List<int> customItemDiceSidesOptions = [4, 6, 8, 10, 12];

/// Convertit la saisie de poids (virgule ou point décimal) en kg : `null` si
/// vide, [double.nan] si invalide (illisible, négatif ou > 9 999,99).
double? parseCustomItemWeightInput(String raw) {
  final text = raw.trim().replaceAll(',', '.');
  if (text.isEmpty) return null;
  final value = double.tryParse(text);
  if (value == null || !isValidCustomWeight(value)) return double.nan;
  return (value * 100).round() / 100;
}

/// CA de base proposée par catégorie d'armure tant que le joueur n'a pas saisi
/// la sienne (bas de la fourchette indicative : légère 11-12, intermédiaire
/// 12-15, lourde 14-18 ; une aide, jamais une limite).
const Map<String, int> customItemArmorDefaultAc = {
  CustomArmorCategories.light: 11,
  CustomArmorCategories.medium: 14,
  CustomArmorCategories.heavy: 16,
};

/// Bornes de saisie (identiques à la validation de la feuille) : CA de base
/// d'une armure 1..30, bonus de CA d'un bouclier 1..5 (défaut +2).
const int customItemArmorAcMin = 1;
const int customItemShieldBonusMin = 1;
const int customItemShieldBonusMax = 5;
const int customItemShieldDefaultBonus = 2;

/// Entier saisi, `null` si vide ou illisible.
int? parseCustomItemIntInput(String raw) => int.tryParse(raw.trim());

/// Feuille « Objet personnalisé » en deux temps (P7) : étape 1 « TYPE
/// D'OBJET » (Arme, Armure, Bouclier ou Objet magique/autre), étape 2 adaptée
/// au type.
///
/// [attunedCount] : nombre d'objets harmonisés du personnage (si connu) pour
/// « Harmoniser maintenant » ; `null` masque cet interrupteur.
Future<CustomItemFormResult?> showCustomItemFormSheet(
  BuildContext context, {
  int? attunedCount,
}) {
  return showModalBottomSheet<CustomItemFormResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CustomItemFormSheet(attunedCount: attunedCount),
  );
}

class CustomItemFormSheet extends StatefulWidget {
  const CustomItemFormSheet({this.attunedCount, super.key});

  final int? attunedCount;

  @override
  State<CustomItemFormSheet> createState() => _CustomItemFormSheetState();
}

class _CustomItemFormSheetState extends State<CustomItemFormSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _propertiesController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _armorClassController = TextEditingController(
    text: '${customItemArmorDefaultAc[CustomArmorCategories.light]}',
  );
  final TextEditingController _shieldBonusController = TextEditingController(
    text: '$customItemShieldDefaultBonus',
  );

  /// `null` : étape 1 (choix du type).
  String? _kind;
  String _armorCategory = CustomArmorCategories.light;

  /// `true` dès que le joueur a modifié la CA à la main : un changement de
  /// catégorie ne la remplace alors plus.
  bool _armorClassEdited = false;
  int _diceCount = 1;
  int _diceSides = 6;
  String? _damageType;
  String? _weaponCategory;
  String? _weaponRange;
  int _magicBonus = 0;
  bool _requiresAttunement = false;
  bool _attuneNow = false;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_handleChanged);
    _weightController.addListener(_handleChanged);
    _armorClassController.addListener(_handleChanged);
    _shieldBonusController.addListener(_handleChanged);
  }

  @override
  void dispose() {
    _armorClassController
      ..removeListener(_handleChanged)
      ..dispose();
    _shieldBonusController
      ..removeListener(_handleChanged)
      ..dispose();
    _nameController
      ..removeListener(_handleChanged)
      ..dispose();
    _weightController
      ..removeListener(_handleChanged)
      ..dispose();
    _descriptionController.dispose();
    _propertiesController.dispose();
    super.dispose();
  }

  void _handleChanged() {
    if (mounted) setState(() {});
  }

  bool get _isWeapon => _kind == CustomItemKinds.weapon;

  bool get _isArmor => _kind == CustomItemKinds.armor;

  bool get _isShield => _kind == CustomItemKinds.shield;

  /// Types qui acceptent un bonus magique (arme, armure, bouclier).
  bool get _hasMagicBonus => _isWeapon || _isArmor || _isShield;

  int? get _armorClass => parseCustomItemIntInput(_armorClassController.text);

  int? get _shieldBonus => parseCustomItemIntInput(_shieldBonusController.text);

  bool get _armorClassValid =>
      _armorClass != null &&
      _armorClass! >= customItemArmorAcMin &&
      _armorClass! <= customAcBaseMax;

  bool get _shieldBonusValid =>
      _shieldBonus != null &&
      _shieldBonus! >= customItemShieldBonusMin &&
      _shieldBonus! <= customItemShieldBonusMax;

  String get _trimmedName => _nameController.text.trim();

  bool get _nameTooLong => _nameController.text.length > _nameMaxLength;

  double? get _weight => parseCustomItemWeightInput(_weightController.text);

  bool get _weightInvalid => _weight?.isNaN ?? false;

  bool get _attunementCapReached =>
      widget.attunedCount != null &&
      widget.attunedCount! >= CharacterDetail.attunementCap;

  /// Champs requis manquants (libellés localisés), dans l'ordre du
  /// formulaire.
  List<String> _missing(AppLocalizations l10n) => [
    if (_trimmedName.isEmpty) l10n.customItemMissingName,
    if (_isWeapon && _damageType == null) l10n.customItemMissingDamageType,
    if (_isArmor && !_armorClassValid) l10n.customItemMissingArmorClass,
    if (_isShield && !_shieldBonusValid) l10n.customItemMissingShieldBonus,
  ];

  bool get _canSubmit =>
      _kind != null &&
      _trimmedName.isNotEmpty &&
      !_nameTooLong &&
      !_weightInvalid &&
      (!_isWeapon || _damageType != null) &&
      (!_isArmor || _armorClassValid) &&
      (!_isShield || _shieldBonusValid);

  bool get _hasAdvancedValue =>
      _weightController.text.trim().isNotEmpty ||
      _requiresAttunement ||
      (_hasMagicBonus &&
          (_magicBonus > 0 || _descriptionController.text.trim().isNotEmpty)) ||
      (_isWeapon && _propertiesController.text.trim().isNotEmpty);

  List<String> _parseProperties(String raw) => raw
      .split(',')
      .map((property) => property.trim())
      .where((property) => property.isNotEmpty)
      .toList();

  void _submit() {
    if (!_canSubmit) return;
    final weight = _weight;
    final description = _descriptionController.text.trim();
    final attuneNow =
        _requiresAttunement && _attuneNow && !_attunementCapReached;
    Navigator.of(context).pop(
      CustomItemFormResult(
        name: _trimmedName,
        quantity: _quantity,
        description: description.isEmpty ? null : description,
        damageDice: _isWeapon ? '${_diceCount}d$_diceSides' : null,
        damageType: _isWeapon ? _damageType : null,
        properties: _isWeapon
            ? _parseProperties(_propertiesController.text)
            : const [],
        enrichment: CustomItemEnrichment(
          kind: _kind,
          magicBonus: _hasMagicBonus ? _magicBonus : 0,
          weight: weight,
          requiresAttunement: _requiresAttunement,
          weaponCategory: _isWeapon ? _weaponCategory : null,
          weaponRange: _isWeapon ? _weaponRange : null,
          acBase: _isArmor
              ? _armorClass
              : _isShield
              ? _shieldBonus
              : null,
          // Jamais de catégorie d'armure pour un bouclier (la maîtrise se
          // déduit du type).
          armorCategory: _isArmor ? _armorCategory : null,
          attuneNow: attuneNow,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final missing = _kind == null ? const <String>[] : _missing(l10n);
    final stacked = _isLargeText(context);
    final cancel = SecondaryButton(
      label: l10n.addItemFlowCustomCancelButton,
      surface: SecondaryButtonSurface.parchment,
      onPressed: () => Navigator.of(context).pop(),
    );
    final add = PrimaryButton(
      label: l10n.addItemFlowCustomAddButton,
      onPressed: _canSubmit ? _submit : null,
    );

    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: Container(
          decoration: const BoxDecoration(color: AppColors.parchmentBg),
          child: Column(
            children: [
              SheetHeaderBar(title: l10n.addItemFlowCustomSheetTitle),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: _kind == null
                      ? _buildTypeStep(l10n)
                      : _buildFormStep(l10n, stacked),
                ),
              ),
              if (missing.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      l10n.customItemMissingLine(missing.join(', ')),
                      style: AppTypography.body(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
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
                child: _kind == null
                    ? cancel
                    : stacked
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          add,
                          const SizedBox(height: AppSpacing.sm),
                          cancel,
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: cancel),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: add),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Étape 1 : type d'objet
  // ---------------------------------------------------------------------

  Widget _buildTypeStep(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DisplayText(
          l10n.addItemFlowCustomTypeSectionLabel,
          style: AppTypography.display(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _KindTile(
          key: const Key('customItemKindWeapon'),
          icon: InventoryCategoryRules.iconFor('arme'),
          color: InventoryCategoryRules.colorFor('arme'),
          title: l10n.customItemTypeWeaponTitle,
          subtitle: l10n.customItemTypeWeaponSubtitle,
          onTap: () => setState(() => _kind = CustomItemKinds.weapon),
        ),
        const SizedBox(height: AppSpacing.sm),
        _KindTile(
          key: const Key('customItemKindArmor'),
          icon: InventoryCategoryRules.iconFor('armure'),
          color: InventoryCategoryRules.colorFor('armure'),
          title: l10n.customItemTypeArmorTitle,
          subtitle: l10n.customItemTypeArmorSubtitle,
          onTap: () => setState(() => _kind = CustomItemKinds.armor),
        ),
        const SizedBox(height: AppSpacing.sm),
        _KindTile(
          key: const Key('customItemKindShield'),
          icon: InventoryCategoryRules.iconFor('bouclier'),
          color: InventoryCategoryRules.colorFor('bouclier'),
          title: l10n.customItemTypeShieldTitle,
          subtitle: l10n.customItemTypeShieldSubtitle,
          onTap: () => setState(() => _kind = CustomItemKinds.shield),
        ),
        const SizedBox(height: AppSpacing.sm),
        _KindTile(
          key: const Key('customItemKindOther'),
          icon: InventoryCategoryRules.iconFor('objet_magique'),
          color: InventoryCategoryRules.colorFor('objet_magique'),
          title: l10n.customItemTypeOtherTitle,
          subtitle: l10n.customItemTypeOtherSubtitle,
          onTap: () => setState(() => _kind = CustomItemKinds.other),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Étape 2 : champs du type
  // ---------------------------------------------------------------------

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Text(
      text,
      style: AppTypography.body(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: AppColors.textSecondary,
      ),
    ),
  );

  Widget _caption(String text) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xs),
    child: Text(
      text,
      style: AppTypography.body(fontSize: 12, color: AppColors.textMuted),
    ),
  );

  Widget _buildFormStep(AppLocalizations l10n, bool stacked) {
    final kindLabel = customKindLabel(l10n, _kind!);
    final weightInvalid = _weightInvalid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              l10n.customItemTypeLine(kindLabel),
              style: AppTypography.body(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Semantics(
              button: true,
              label: l10n.customItemChangeTypeSemantics,
              excludeSemantics: true,
              child: TextButton(
                key: const Key('customItemChangeKindButton'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  foregroundColor: AppColors.textSecondary,
                ),
                // Seul le type change : nom, quantité, poids, harmonisation et
                // description restent dans leurs contrôleurs/variables.
                onPressed: () => setState(() => _kind = null),
                child: Text(l10n.customItemChangeTypeButton),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _label(l10n.addItemFlowCustomNameSectionLabel),
        TextFormField(
          key: const Key('customItemNameField'),
          controller: _nameController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.addItemFlowCustomNameHint,
            errorText: _nameTooLong
                ? l10n.customItemNameTooLongError(_nameMaxLength)
                : null,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_isWeapon)
          ..._weaponFields(l10n, stacked)
        else if (_isArmor)
          ..._armorFields(l10n, stacked)
        else if (_isShield)
          ..._shieldFields(l10n)
        else
          ..._otherFields(l10n),
        AdvancedSection(
          key: ValueKey('advanced-$_kind'),
          title: l10n.customItemAdvancedTitle,
          initiallyExpanded: _hasAdvancedValue,
          forceExpanded: weightInvalid,
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_hasMagicBonus) ..._magicBonusFields(l10n, stacked),
                if (_isWeapon) ..._weaponPropertiesFields(l10n),
                ..._weightField(l10n),
                const SizedBox(height: AppSpacing.md),
                ..._attunementFields(l10n),
                if (_hasMagicBonus) ...[
                  const SizedBox(height: AppSpacing.md),
                  ..._descriptionField(l10n),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _label(l10n.addItemFlowCustomQuantitySectionLabel),
        StepperCounter(
          value: _quantity,
          onIncrement: () => setState(() => _quantity++),
          onDecrement: _quantity > 1 ? () => setState(() => _quantity--) : null,
        ),
      ],
    );
  }

  List<Widget> _descriptionField(AppLocalizations l10n) => [
    _label(l10n.addItemFlowCustomDescriptionSectionLabel),
    TextFormField(
      key: const Key('customItemDescriptionField'),
      controller: _descriptionController,
      minLines: 3,
      maxLines: null,
      decoration: InputDecoration(
        hintText: l10n.addItemFlowCustomDescriptionHint,
      ),
    ),
  ];

  List<Widget> _otherFields(AppLocalizations l10n) => [
    ..._descriptionField(l10n),
    const SizedBox(height: AppSpacing.md),
  ];

  List<Widget> _weaponFields(AppLocalizations l10n, bool stacked) => [
    _label(l10n.addItemFlowCustomDiceSectionLabel),
    Row(
      children: [
        StepperCounter(
          value: _diceCount,
          onIncrement: _diceCount < customDiceCountMax
              ? () => setState(() => _diceCount++)
              : null,
          onDecrement: _diceCount > 1
              ? () => setState(() => _diceCount--)
              : null,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          l10n.addItemFlowCustomDiceNotationSeparator,
          style: AppTypography.body(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: DropdownButtonFormField<int>(
            key: const Key('customItemDiceSidesField'),
            initialValue: _diceSides,
            isExpanded: true,
            items: [
              for (final sides in customItemDiceSidesOptions)
                DropdownMenuItem(value: sides, child: Text('$sides')),
            ],
            onChanged: (value) =>
                setState(() => _diceSides = value ?? _diceSides),
          ),
        ),
      ],
    ),
    const SizedBox(height: AppSpacing.md),
    _label(l10n.addItemFlowCustomDamageTypeSectionLabel),
    DropdownButtonFormField<String>(
      key: const Key('customItemDamageTypeField'),
      initialValue: _damageType,
      isExpanded: true,
      hint: Text(l10n.addItemFlowCustomDamageTypeHint),
      items: [
        for (final type in CustomDamageTypes.all)
          DropdownMenuItem(
            value: type,
            child: Text(customDamageTypeLabel(l10n, type)),
          ),
      ],
      onChanged: (value) => setState(() => _damageType = value),
    ),
    const SizedBox(height: AppSpacing.md),
    _label(l10n.customItemWeaponCategorySectionLabel),
    _ChoiceSelector<String>(
      keyPrefix: 'customItemWeaponCategory',
      stacked: stacked,
      options: [
        (CustomWeaponCategories.common, l10n.customItemWeaponCategoryCommon),
        (CustomWeaponCategories.martial, l10n.customItemWeaponCategoryMartial),
      ],
      value: _weaponCategory,
      onChanged: (value) => setState(() => _weaponCategory = value),
    ),
    if (_weaponCategory == null) _caption(l10n.customItemWeaponCategoryHint),
    const SizedBox(height: AppSpacing.md),
    _label(l10n.customItemWeaponRangeSectionLabel),
    _ChoiceSelector<String>(
      keyPrefix: 'customItemWeaponRange',
      stacked: stacked,
      options: [
        (CustomWeaponRanges.melee, l10n.customItemWeaponRangeMelee),
        (CustomWeaponRanges.ranged, l10n.customItemWeaponRangeRanged),
      ],
      value: _weaponRange,
      onChanged: (value) => setState(() => _weaponRange = value),
    ),
    if (_weaponRange == null) _caption(l10n.customItemWeaponRangeHint),
    const SizedBox(height: AppSpacing.md),
  ];

  List<Widget> _armorFields(AppLocalizations l10n, bool stacked) {
    final acInvalid =
        _armorClassController.text.trim().isNotEmpty && !_armorClassValid;
    return [
      _label(l10n.customItemArmorCategorySectionLabel),
      _ChoiceSelector<String>(
        keyPrefix: 'customItemArmorCategory',
        stacked: stacked,
        options: [
          (
            CustomArmorCategories.light,
            customArmorCategoryLabel(l10n, CustomArmorCategories.light),
          ),
          (
            CustomArmorCategories.medium,
            customArmorCategoryLabel(l10n, CustomArmorCategories.medium),
          ),
          (
            CustomArmorCategories.heavy,
            customArmorCategoryLabel(l10n, CustomArmorCategories.heavy),
          ),
        ],
        value: _armorCategory,
        onChanged: (value) {
          // La CA proposée suit la catégorie tant que le joueur n'y a pas
          // touché (affectation hors `setState` : le contrôleur notifie).
          if (!_armorClassEdited) {
            _armorClassController.text = '${customItemArmorDefaultAc[value]}';
          }
          setState(() => _armorCategory = value);
        },
      ),
      const SizedBox(height: AppSpacing.md),
      _label(l10n.customItemArmorClassSectionLabel),
      TextFormField(
        key: const Key('customItemArmorClassField'),
        controller: _armorClassController,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (_) => _armorClassEdited = true,
        decoration: InputDecoration(
          hintText: l10n.customItemArmorClassHint,
          errorText: acInvalid ? l10n.customItemArmorClassError : null,
        ),
      ),
      _caption(l10n.customItemArmorClassLegend),
      const SizedBox(height: AppSpacing.sm),
      Semantics(
        liveRegion: true,
        child: Text(
          l10n.customItemArmorDexLine(
            customArmorDexBonusLabel(l10n, _armorCategory),
          ),
          key: const Key('customItemArmorDexLine'),
          style: AppTypography.body(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
    ];
  }

  List<Widget> _shieldFields(AppLocalizations l10n) {
    final invalid =
        _shieldBonusController.text.trim().isNotEmpty && !_shieldBonusValid;
    return [
      _label(l10n.customItemShieldBonusSectionLabel),
      TextFormField(
        key: const Key('customItemShieldBonusField'),
        controller: _shieldBonusController,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          hintText: l10n.customItemShieldBonusHint,
          errorText: invalid ? l10n.customItemShieldBonusError : null,
        ),
      ),
      _caption(l10n.customItemShieldBonusLegend),
      const SizedBox(height: AppSpacing.md),
    ];
  }

  List<Widget> _magicBonusFields(AppLocalizations l10n, bool stacked) => [
    _label(l10n.customItemMagicBonusSectionLabel),
    _ChoiceSelector<int>(
      keyPrefix: 'customItemMagicBonus',
      stacked: stacked,
      options: [
        (0, l10n.customItemMagicBonusNone),
        for (var bonus = 1; bonus <= customMagicBonusMax; bonus++)
          (bonus, '+$bonus'),
      ],
      value: _magicBonus,
      onChanged: (value) => setState(() => _magicBonus = value),
    ),
    const SizedBox(height: AppSpacing.md),
  ];

  List<Widget> _weaponPropertiesFields(AppLocalizations l10n) => [
    _label(l10n.addItemFlowCustomPropertiesSectionLabel),
    TextFormField(
      key: const Key('customItemPropertiesField'),
      controller: _propertiesController,
      decoration: InputDecoration(
        hintText: l10n.addItemFlowCustomPropertiesHint,
      ),
    ),
    _caption(l10n.addItemFlowCustomPropertiesCaption),
    const SizedBox(height: AppSpacing.md),
  ];

  List<Widget> _weightField(AppLocalizations l10n) => [
    _label(l10n.customItemWeightSectionLabel),
    TextFormField(
      key: const Key('customItemWeightField'),
      controller: _weightController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(
        hintText: l10n.customItemWeightHint,
        errorText: _weightInvalid ? l10n.customItemWeightError : null,
      ),
    ),
  ];

  List<Widget> _attunementFields(AppLocalizations l10n) {
    final showNow = _requiresAttunement && widget.attunedCount != null;
    final capReached = _attunementCapReached;
    return [
      _SwitchRow(
        key: const Key('customItemRequiresAttunementSwitch'),
        label: l10n.customItemRequiresAttunementLabel,
        value: _requiresAttunement,
        onChanged: (value) => setState(() {
          _requiresAttunement = value;
          if (!value) _attuneNow = false;
        }),
      ),
      if (showNow) ...[
        _SwitchRow(
          key: const Key('customItemAttuneNowSwitch'),
          label: l10n.customItemAttuneNowLabel,
          value: _attuneNow && !capReached,
          onChanged: capReached
              ? null
              : (value) => setState(() => _attuneNow = value),
        ),
        if (capReached)
          Semantics(
            liveRegion: true,
            child: _caption(
              l10n.customItemAttunementCapCaption(widget.attunedCount!),
            ),
          ),
      ],
    ];
  }
}

bool _isLargeText(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(14) / 14 >= 1.5;

/// Tuile de l'étape 1 : recette de `_CatalogItemRow` (badge d'icône 40×40, nom,
/// sous-titre, chevron), fond `parchmentCard`, bordure `woodLight`, hauteur
/// minimale 64 ; aucun radio ni choix par défaut.
class _KindTile extends StatelessWidget {
  const _KindTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      container: true,
      excludeSemantics: true,
      label: '$title, $subtitle',
      onTap: onTap,
      child: Material(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: AppColors.woodLight,
                width: AppBorders.card,
              ),
            ),
            child: Row(
              children: [
                AccentIconBadge(icon: icon, color: color),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppTypography.body(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTypography.body(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sélecteur à choix exclusif : bascule segmentée, ou liste verticale de
/// [SelectableOptionTile] dès que la police est très agrandie ([stacked]).
/// Aucune option sélectionnée tant que [value] est `null`.
class _ChoiceSelector<T> extends StatelessWidget {
  const _ChoiceSelector({
    required this.keyPrefix,
    required this.stacked,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final String keyPrefix;
  final bool stacked;
  final List<(T, String)> options;
  final T? value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    if (stacked) {
      return Column(
        children: [
          for (final (optionValue, label) in options) ...[
            SelectableOptionTile(
              key: Key('${keyPrefix}Tile_$optionValue'),
              title: label,
              selected: optionValue == value,
              onTap: () => onChanged(optionValue),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ],
      );
    }
    return SegmentedToggle<T?>(
      key: Key('${keyPrefix}Toggle'),
      options: [
        for (final (optionValue, label) in options)
          SegmentedToggleOption<T?>(value: optionValue, label: label),
      ],
      value: value,
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
    );
  }
}

/// Ligne « libellé + interrupteur » d'au moins 56 dp, interrupteur au style de
/// l'app (piste bois, pastille parchemin, contour `woodDark`).
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final disabled = onChanged == null;
    const disabledAlpha = 0.5;
    // `Material` transparent : le fond parchemin de la feuille est un
    // `DecoratedBox`, qui masquerait l'encre du `ListTile`.
    return Material(
      type: MaterialType.transparency,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            label,
            style: AppTypography.body(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: disabled ? AppColors.textMuted : AppColors.textPrimary,
            ),
          ),
          value: value,
          onChanged: onChanged,
          thumbColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? AppColors.parchmentCard.withValues(alpha: disabledAlpha)
                : AppColors.parchmentCard,
          ),
          trackColor: WidgetStateProperty.resolveWith((states) {
            final base = value ? AppColors.woodMedium : AppColors.woodLight;
            return states.contains(WidgetState.disabled)
                ? base.withValues(alpha: disabledAlpha)
                : base;
          }),
          trackOutlineColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? AppColors.woodDark.withValues(alpha: disabledAlpha)
                : AppColors.woodDark,
          ),
        ),
      ),
    );
  }
}
