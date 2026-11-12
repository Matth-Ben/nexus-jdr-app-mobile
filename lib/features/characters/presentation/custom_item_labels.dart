import '../../../l10n/app_localizations.dart';
import '../domain/custom_item_enrichment.dart';

/// Libellés localisés des valeurs stockées d'un objet personnalisé (P7) : le
/// stockage reste en français minuscule (comme `weapon_properties`), seul
/// l'affichage est traduit. Une valeur inconnue est rendue telle quelle.
String customDamageTypeLabel(AppLocalizations l10n, String value) =>
    switch (value) {
      'tranchant' => l10n.addItemFlowDamageTypeSlashingLabel,
      'perforant' => l10n.addItemFlowDamageTypePiercingLabel,
      'contondant' => l10n.addItemFlowDamageTypeBludgeoningLabel,
      'acide' => l10n.customItemDamageTypeAcid,
      'feu' => l10n.customItemDamageTypeFire,
      'foudre' => l10n.customItemDamageTypeLightning,
      'froid' => l10n.customItemDamageTypeCold,
      'force' => l10n.customItemDamageTypeForce,
      'nécrotique' => l10n.customItemDamageTypeNecrotic,
      'poison' => l10n.customItemDamageTypePoison,
      'psychique' => l10n.customItemDamageTypePsychic,
      'radiant' => l10n.customItemDamageTypeRadiant,
      'tonnerre' => l10n.customItemDamageTypeThunder,
      _ => value,
    };

String customWeaponCategoryLabel(AppLocalizations l10n, String value) =>
    switch (value) {
      CustomWeaponCategories.common => l10n.customItemWeaponCategoryCommon,
      CustomWeaponCategories.martial => l10n.customItemWeaponCategoryMartial,
      _ => value,
    };

String customWeaponRangeLabel(AppLocalizations l10n, String value) =>
    switch (value) {
      CustomWeaponRanges.melee => l10n.customItemWeaponRangeMelee,
      CustomWeaponRanges.ranged => l10n.customItemWeaponRangeRanged,
      _ => value,
    };

String customKindLabel(AppLocalizations l10n, String value) => switch (value) {
  CustomItemKinds.weapon => l10n.customItemTypeWeaponTitle,
  CustomItemKinds.other => l10n.customItemTypeOtherTitle,
  _ => value,
};
