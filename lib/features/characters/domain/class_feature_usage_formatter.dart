import 'character_class_feature.dart';

/// Formatte le compteur d'usage d'une aptitude de classe pour la carte
/// "APTITUDES DE CLASSE" de l'onglet Compétences — "X / Y · repos long" ou
/// "X / Y · repos court" pour une aptitude à usage limité. Retourne `null`
/// pour une aptitude passive ([CharacterClassFeature.isPassive]) : c'est à
/// l'appelant d'afficher "Passive" dans ce cas plutôt que de coder ce
/// libellé ici — même séparation affichage/formatage que
/// `signed_modifier_formatter.dart`.
abstract final class ClassFeatureUsageFormatter {
  static String? format(CharacterClassFeature feature) {
    final usesMax = feature.usesMax;
    if (usesMax == null) return null;

    final remaining = feature.usesRemaining ?? usesMax;
    // 'repos_long' est le seul cas qui affiche "repos long" ; toute autre
    // valeur (y compris `null`, ou une valeur inattendue côté donnée
    // serveur) retombe sur "repos court" plutôt que de crasher ou d'afficher
    // une valeur brute non traduite — couvert explicitement par
    // `class_feature_usage_formatter_test.dart`.
    final restLabel = feature.restType == 'repos_long'
        ? 'repos long'
        : 'repos court';
    return '$remaining / $usesMax · $restLabel';
  }
}
