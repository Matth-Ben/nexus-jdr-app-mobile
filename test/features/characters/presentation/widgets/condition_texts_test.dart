// D195 (a) : longueur des règles résumées des conditions. La limite d'origine
// (90 caractères) a été pensée pour le français ; l'anglais, plus long à
// rendu équivalent, est borné à 100 caractères (le plus long fait 99).

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/condition_type.dart';
import 'package:personnages/features/characters/presentation/widgets/condition_texts.dart';
import 'package:personnages/l10n/app_localizations_en.dart';
import 'package:personnages/l10n/app_localizations_fr.dart';

void main() {
  group('Règles résumées des conditions : longueur', () {
    test('FR : au plus 90 caractères, jamais vide', () {
      final l10n = AppLocalizationsFr();
      for (final type in ConditionType.values) {
        final rule = type.rule(l10n);
        expect(rule, isNotEmpty, reason: type.storageKey);
        expect(
          rule.length,
          lessThanOrEqualTo(90),
          reason: '${type.storageKey} : ${rule.length} caractères',
        );
      }
    });

    test('EN : au plus 100 caractères, jamais vide', () {
      final l10n = AppLocalizationsEn();
      for (final type in ConditionType.values) {
        final rule = type.rule(l10n);
        expect(rule, isNotEmpty, reason: type.storageKey);
        expect(
          rule.length,
          lessThanOrEqualTo(100),
          reason: '${type.storageKey} : ${rule.length} caractères',
        );
      }
    });
  });
}
