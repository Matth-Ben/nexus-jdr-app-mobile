import '../../../../core/utils/french_text_normalizer.dart';
import '../../../../core/widgets/pixel_icons/condition_pixel_icons.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/condition_type.dart';

/// Textes localisés et icône pixel d'une [ConditionType] (P6). Les textes
/// vivent dans `app_fr.arb`/`app_en.arb` (clés `condition<Nom>Label`/`Rule`) ;
/// les règles sont celles de D&D 5e, édition **2014**.
extension ConditionTypeTexts on ConditionType {
  String label(AppLocalizations l10n) => switch (this) {
    ConditionType.blinded => l10n.conditionBlindedLabel,
    ConditionType.charmed => l10n.conditionCharmedLabel,
    ConditionType.deafened => l10n.conditionDeafenedLabel,
    ConditionType.frightened => l10n.conditionFrightenedLabel,
    ConditionType.grappled => l10n.conditionGrappledLabel,
    ConditionType.incapacitated => l10n.conditionIncapacitatedLabel,
    ConditionType.invisible => l10n.conditionInvisibleLabel,
    ConditionType.paralyzed => l10n.conditionParalyzedLabel,
    ConditionType.petrified => l10n.conditionPetrifiedLabel,
    ConditionType.poisoned => l10n.conditionPoisonedLabel,
    ConditionType.prone => l10n.conditionProneLabel,
    ConditionType.restrained => l10n.conditionRestrainedLabel,
    ConditionType.stunned => l10n.conditionStunnedLabel,
    ConditionType.unconscious => l10n.conditionUnconsciousLabel,
  };

  /// Règle résumée (≤ 90 caractères en français, ≤ 100 en anglais — vérifié par
  /// `condition_texts_test.dart`), purement informative.
  String rule(AppLocalizations l10n) => switch (this) {
    ConditionType.blinded => l10n.conditionBlindedRule,
    ConditionType.charmed => l10n.conditionCharmedRule,
    ConditionType.deafened => l10n.conditionDeafenedRule,
    ConditionType.frightened => l10n.conditionFrightenedRule,
    ConditionType.grappled => l10n.conditionGrappledRule,
    ConditionType.incapacitated => l10n.conditionIncapacitatedRule,
    ConditionType.invisible => l10n.conditionInvisibleRule,
    ConditionType.paralyzed => l10n.conditionParalyzedRule,
    ConditionType.petrified => l10n.conditionPetrifiedRule,
    ConditionType.poisoned => l10n.conditionPoisonedRule,
    ConditionType.prone => l10n.conditionProneRule,
    ConditionType.restrained => l10n.conditionRestrainedRule,
    ConditionType.stunned => l10n.conditionStunnedRule,
    ConditionType.unconscious => l10n.conditionUnconsciousRule,
  };

  /// Matrice 16×16 de l'icône pixel de cette condition.
  List<String> get pixelMatrix => kConditionPixelMatrices[storageKey]!;
}

/// [conditions] triées par ordre alphabétique du **libellé localisé** de la
/// langue active (insensible aux accents et à la casse), jamais sur la clé
/// serveur.
List<ConditionType> sortConditionsForDisplay(
  Iterable<ConditionType> conditions,
  AppLocalizations l10n,
) {
  final sorted = ConditionType.canonical(conditions);
  sorted.sort(
    (a, b) => FrenchTextNormalizer.compare(a.label(l10n), b.label(l10n)),
  );
  return sorted;
}

/// Noms localisés de [conditions] séparés par « , » (ordre d'affichage).
String conditionNamesList(
  Iterable<ConditionType> conditions,
  AppLocalizations l10n,
) => sortConditionsForDisplay(
  conditions,
  l10n,
).map((c) => c.label(l10n)).join(', ');
